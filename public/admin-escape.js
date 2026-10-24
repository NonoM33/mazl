// HTML escaping for the admin console.
//
// Names, e-mails, bios, report reasons and error messages are written by strangers
// (the public subscribe form, members, reporters). They must never reach the page as
// markup: the admin JWT sits in localStorage, so one injected <img onerror> is an
// admin session theft. Every dynamic value goes through this module:
//
//   el.innerHTML = html`<td>${user.email}</td>`;     // escaped automatically
//   html`<img src="${safeUrl(user.picture)}">`        // URLs are filtered too
//
// tests/unit/admin-xss-guard.test.ts fails the build if a page interpolates a value
// into markup any other way.

const HTML_ESCAPES = {
  '&': '&amp;',
  '<': '&lt;',
  '>': '&gt;',
  '"': '&quot;',
  "'": '&#39;',
};

export function escapeHtml(value) {
  if (value === null || value === undefined) return '';
  return String(value).replace(/[&<>"']/g, (ch) => HTML_ESCAPES[ch]);
}

// A fragment that is already safe markup. Only html`` creates one; a string that
// merely looks like markup is escaped like any other string.
class SafeHtml {
  #markup;

  constructor(markup) {
    this.#markup = markup;
  }

  static isSafeHtml(value) {
    return value instanceof SafeHtml;
  }

  toString() {
    return this.#markup;
  }
}

function renderValue(value) {
  if (value === null || value === undefined || value === false) return '';
  if (SafeHtml.isSafeHtml(value)) return value.toString();
  if (Array.isArray(value)) return value.map(renderValue).join('');
  return escapeHtml(value);
}

export function html(strings, ...values) {
  let markup = strings[0];
  for (let i = 0; i < values.length; i++) {
    markup += renderValue(values[i]) + strings[i + 1];
  }
  return new SafeHtml(markup);
}

const SCHEME = /^([a-z][a-z0-9+.-]*):/i;
const SAFE_DATA_IMAGE = /^data:image\/(?:png|jpe?g|gif|webp|avif);base64,[a-z0-9+/=]*$/i;
const CONTROL_CHARACTERS = /[\u0000-\u001f\u007f-\u009f]/;

// A URL that can go in src/href: https:, a relative path, a raster data:image or
// blob:. Anything else (javascript:, data:text/html, http:, //host, file:) -> ''.
export function safeUrl(value) {
  if (typeof value !== 'string') return '';
  const url = value.trim();
  if (url === '' || CONTROL_CHARACTERS.test(url)) return '';
  if (url.startsWith('//') || url.startsWith('\\')) return '';

  const scheme = SCHEME.exec(url);
  if (!scheme) return url;

  switch (scheme[1].toLowerCase()) {
    case 'https':
      return url;
    case 'blob':
      return url;
    case 'data':
      return SAFE_DATA_IMAGE.test(url) ? url : '';
    default:
      return '';
  }
}
