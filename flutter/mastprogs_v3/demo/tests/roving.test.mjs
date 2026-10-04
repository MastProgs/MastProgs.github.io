import assert from "node:assert/strict";
import { test } from "node:test";
import { nextRovingIndex } from "../src/lib/roving.js";

test("horizontal tabs wrap with arrows and jump with Home/End", () => {
  assert.equal(nextRovingIndex("ArrowRight", 6, 7), 0);
  assert.equal(nextRovingIndex("ArrowLeft", 0, 7), 6);
  assert.equal(nextRovingIndex("Home", 4, 7), 0);
  assert.equal(nextRovingIndex("End", 1, 7), 6);
  assert.equal(nextRovingIndex("ArrowDown", 1, 7), null, "vertical arrows are not tab keys");
  assert.equal(nextRovingIndex("Enter", 1, 7), null, "Enter/Space stay with native button activation");
});

test("radio group also accepts vertical arrows", () => {
  assert.equal(nextRovingIndex("ArrowDown", 2, 3, { orientation: "both" }), 0);
  assert.equal(nextRovingIndex("ArrowUp", 0, 3, { orientation: "both" }), 2);
  assert.equal(nextRovingIndex("ArrowRight", 0, 0), null);
});
