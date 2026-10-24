import ts from "typescript";

// Static scanner behind tests/unit/admin-xss-guard.test.ts.
//
// The admin console builds HTML in the browser from data that strangers control
// (public subscribe form, member profiles, reports). The rule that keeps it safe:
//
//   R1  A template literal that contains markup and an interpolation must be
//       tagged with html`` (public/admin-escape.js), which escapes every value.
//   R2  Markup is never glued with `+` to a non-literal value.
//   R3  innerHTML / outerHTML / insertAdjacentHTML / document.write only receive
//       a literal or an html`` fragment, never a variable or a plain template.
//   R4  No interpolation inside an inline event handler attribute (on*="...").
//   R5  An interpolation that starts a src/href/action/... attribute goes through
//       safeUrl(); a fixed prefix is only accepted if it is a relative path, an
//       anchor or https://.
//
// Anything else is a violation. The scanner knows nothing about the admin pages:
// it is exercised on hostile snippets in the test so that it cannot be decorative.

export interface Violation {
  rule: "R1" | "R2" | "R3" | "R4" | "R5";
  line: number;
  message: string;
  snippet: string;
}

const SINK_PROPERTIES = new Set(["innerHTML", "outerHTML"]);
const SINK_CALLS = new Set(["insertAdjacentHTML", "write", "writeln"]);
const URL_ATTRIBUTE = /\b(?:src|href|action|formaction|poster|srcset|xlink:href|background)\s*=\s*(["']?)([^"']*)$/i;
const HANDLER_ATTRIBUTE = /\son[a-z]+\s*=\s*["']?[^"']*$/i;
const PLACEHOLDER = "\u0000";
const SAFE_URL_PREFIX = /^(?:\/(?!\/)|#|https:\/\/)/;

function isHtmlTag(node: ts.Node): boolean {
  const parent = node.parent;
  return (
    ts.isTaggedTemplateExpression(parent) &&
    parent.template === node &&
    ts.isIdentifier(parent.tag) &&
    parent.tag.text === "html"
  );
}

function isStaticString(node: ts.Node): boolean {
  return ts.isStringLiteral(node) || ts.isNoSubstitutionTemplateLiteral(node);
}

function isSafeUrlCall(node: ts.Expression): boolean {
  return ts.isCallExpression(node) && ts.isIdentifier(node.expression) && node.expression.text === "safeUrl";
}

function flattenPlus(node: ts.Expression): ts.Expression[] {
  if (ts.isParenthesizedExpression(node)) return flattenPlus(node.expression);
  if (ts.isBinaryExpression(node) && node.operatorToken.kind === ts.SyntaxKind.PlusToken) {
    return [...flattenPlus(node.left), ...flattenPlus(node.right)];
  }
  return [node];
}

function templateParts(node: ts.TemplateExpression): Array<{ before: string; expression: ts.Expression }> {
  const parts: Array<{ before: string; expression: ts.Expression }> = [];
  let text = node.head.text;
  for (const span of node.templateSpans) {
    parts.push({ before: text, expression: span.expression });
    text += PLACEHOLDER + span.literal.text;
  }
  return parts;
}

function staticText(node: ts.TemplateExpression): string {
  return node.head.text + node.templateSpans.map((s) => s.literal.text).join("");
}

export function scanScript(code: string, fileName = "inline.js"): Violation[] {
  const source = ts.createSourceFile(fileName, code, ts.ScriptTarget.Latest, true, ts.ScriptKind.JS);
  const violations: Violation[] = [];

  const report = (rule: Violation["rule"], node: ts.Node, message: string): void => {
    const { line } = source.getLineAndCharacterOfPosition(node.getStart(source));
    violations.push({ rule, line: line + 1, message, snippet: node.getText(source).slice(0, 120).replace(/\s+/g, " ") });
  };

  const checkSink = (value: ts.Expression, at: ts.Node): void => {
    if (isStaticString(value)) return;
    if (ts.isTaggedTemplateExpression(value) && ts.isIdentifier(value.tag) && value.tag.text === "html") return;
    report("R3", at, "HTML sink fed with something other than a literal or an html`` fragment");
  };

  const visit = (node: ts.Node): void => {
    if (ts.isTemplateExpression(node)) {
      if (isHtmlTag(node)) {
        for (const { before, expression } of templateParts(node)) {
          if (HANDLER_ATTRIBUTE.test(before)) {
            report("R4", expression, "interpolation inside an inline event handler attribute");
          }
          const urlAttr = URL_ATTRIBUTE.exec(before);
          if (urlAttr) {
            const prefix = urlAttr[2] ?? "";
            if (prefix === "" && !isSafeUrlCall(expression)) {
              report("R5", expression, "URL attribute value must come from safeUrl()");
            } else if (prefix !== "" && !prefix.includes(PLACEHOLDER) && !SAFE_URL_PREFIX.test(prefix)) {
              report("R5", expression, "URL attribute prefix is not a relative path, anchor or https://");
            }
          }
        }
      } else if (staticText(node).includes("<")) {
        report("R1", node, "markup template with interpolation is not tagged with html``");
      }
    }

    if (ts.isBinaryExpression(node) && node.operatorToken.kind === ts.SyntaxKind.PlusToken) {
      const parent = node.parent;
      const isOuter = !(ts.isBinaryExpression(parent) && parent.operatorToken.kind === ts.SyntaxKind.PlusToken);
      if (isOuter) {
        const operands = flattenPlus(node);
        const hasMarkup = operands.some((o) => isStaticString(o) && (o as ts.StringLiteral).text.includes("<"));
        const hasDynamic = operands.some((o) => !isStaticString(o));
        if (hasMarkup && hasDynamic) report("R2", node, "markup concatenated with a dynamic value");
      }
    }

    if (
      ts.isBinaryExpression(node) &&
      node.operatorToken.kind === ts.SyntaxKind.EqualsToken &&
      ts.isPropertyAccessExpression(node.left) &&
      SINK_PROPERTIES.has(node.left.name.text)
    ) {
      checkSink(node.right, node);
    }

    if (ts.isCallExpression(node) && ts.isPropertyAccessExpression(node.expression)) {
      const name = node.expression.name.text;
      if (SINK_CALLS.has(name)) {
        const last = node.arguments[node.arguments.length - 1];
        if (last) checkSink(last, node);
      }
    }

    ts.forEachChild(node, visit);
  };

  visit(source);
  return violations;
}

// Text of every string / template chunk of a script, to forbid secrets in URLs.
export function stringChunks(code: string): string[] {
  const source = ts.createSourceFile("chunks.js", code, ts.ScriptTarget.Latest, true, ts.ScriptKind.JS);
  const chunks: string[] = [];
  const visit = (node: ts.Node): void => {
    if (ts.isStringLiteral(node) || ts.isNoSubstitutionTemplateLiteral(node)) chunks.push(node.text);
    if (ts.isTemplateExpression(node)) {
      chunks.push(node.head.text, ...node.templateSpans.map((s) => s.literal.text));
    }
    ts.forEachChild(node, visit);
  };
  visit(source);
  return chunks;
}
