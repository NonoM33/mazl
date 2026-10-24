import { describe, expect, test } from "bun:test";
import { fileProblem, moveBy, moveTo, rejectionMessage } from "../../web/src/features/profile/photo-order";
import { answerProblem, freePosition, groupCatalog } from "../../web/src/features/profile/prompt-rules";

describe("photo order", () => {
  test("move left and right swap with the neighbour", () => {
    expect(moveBy([1, 2, 3, 4], 2, -1)).toEqual([2, 1, 3, 4]);
    expect(moveBy([1, 2, 3, 4], 2, 1)).toEqual([1, 3, 2, 4]);
  });
  test("the ends do not move further", () => {
    expect(moveBy([1, 2, 3], 1, -1)).toEqual([1, 2, 3]);
    expect(moveBy([1, 2, 3], 3, 1)).toEqual([1, 2, 3]);
    expect(moveBy([1, 2, 3], 9, 1)).toEqual([1, 2, 3]);
  });
  test("dropping a photo on a position puts it there", () => {
    expect(moveTo([1, 2, 3, 4], 4, 0)).toEqual([4, 1, 2, 3]);
    expect(moveTo([1, 2, 3, 4], 1, 2)).toEqual([2, 3, 1, 4]);
    expect(moveTo([1, 2, 3, 4], 3, 2)).toEqual([1, 2, 3, 4]);
  });
});

describe("photo files and refusals", () => {
  test("accepted formats and the 10 MB limit", () => {
    expect(fileProblem({ name: "a.jpg", type: "image/jpeg", size: 1000 })).toBeNull();
    expect(fileProblem({ name: "a.HEIC", type: "", size: 1000 })).toBeNull();
    expect(fileProblem({ name: "a.gif", type: "image/gif", size: 1000 })).not.toBeNull();
    expect(fileProblem({ name: "a.png", type: "image/png", size: 10 * 1024 * 1024 + 1 })).not.toBeNull();
    expect(fileProblem({ name: "a.png", type: "image/png", size: 0 })).not.toBeNull();
  });
  test("server refusals are translated", () => {
    expect(rejectionMessage(409, undefined)).toContain("6 photos au maximum");
    expect(rejectionMessage(400, "undecodable")).toContain("n'a pas pu être lue");
    expect(rejectionMessage(400, "unsupported_format")).toContain("format");
    expect(rejectionMessage(400, "too_large")).toContain("10 Mo");
    expect(rejectionMessage(400, "empty")).toContain("vide");
    expect(rejectionMessage(429, undefined)).toBeNull();
  });
});

describe("prompts", () => {
  test("answer length 10 to 150", () => {
    expect(answerProblem("court")).not.toBeNull();
    expect(answerProblem("x".repeat(10))).toBeNull();
    expect(answerProblem("x".repeat(150))).toBeNull();
    expect(answerProblem("x".repeat(151))).not.toBeNull();
    expect(answerProblem("   court   ")).not.toBeNull();
  });
  test("catalogue grouped in order, answered prompts left out", () => {
    const groups = groupCatalog([{ id: "a", text: "A", category: "lifestyle" }, { id: "b", text: "B", category: "personality" }, { id: "c", text: "C", category: "personality" }], ["c"]);
    expect(groups.map((group) => group.label)).toEqual(["Personnalité", "Style de vie"]);
    expect(groups[0]?.prompts.map((prompt) => prompt.id)).toEqual(["b"]);
  });
  test("the next free slot", () => {
    expect(freePosition([])).toBe(0);
    expect(freePosition([0, 2])).toBe(1);
  });
});
