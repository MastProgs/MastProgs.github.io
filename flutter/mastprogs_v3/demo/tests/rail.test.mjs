import assert from "node:assert/strict";
import { test } from "node:test";
import { centeredIndex, scrollLeftToCenter, stepIndex, tiltRatio } from "../src/lib/rail.js";

// 레일 폭 1376, 카드 600, 간격 24, 좌우 여백 388 (첫 카드가 가운데 오도록).
const items = [0, 1, 2, 3].map((index) => ({ left: 388 + index * 624, width: 600 }));
const viewport = (scrollLeft) => ({ scrollLeft, clientWidth: 1376, scrollWidth: 388 * 2 + 4 * 600 + 3 * 24 });

test("centered index follows the card nearest to the rail centre", () => {
  assert.equal(centeredIndex(viewport(0), items), 0);
  assert.equal(centeredIndex(viewport(624), items), 1);
  assert.equal(centeredIndex(viewport(624 * 3), items), 3);
  assert.equal(centeredIndex(viewport(300), items), 0);
  assert.equal(centeredIndex(viewport(330), items), 1);
  assert.equal(centeredIndex(viewport(0), []), -1);
});

test("tilt ratio is zero at the centre, signed by side and clamped", () => {
  assert.equal(tiltRatio(items[0], viewport(0)), 0);
  assert.ok(tiltRatio(items[1], viewport(0)) > 0, "right side is positive");
  assert.ok(tiltRatio(items[0], viewport(624)) < 0, "left side is negative");
  assert.equal(tiltRatio(items[3], viewport(0)), 1, "clamped to 1");
  assert.ok(Object.is(tiltRatio({ left: 388.0001, width: 600 }, viewport(0)), 0), "no negative zero");
  assert.equal(tiltRatio(items[0], { scrollLeft: 0, clientWidth: 0, scrollWidth: 0 }), 0);
});

test("scroll target centres a card and stays within the scroll range", () => {
  const vp = viewport(0);
  assert.equal(scrollLeftToCenter(items[0], vp), 0);
  assert.equal(scrollLeftToCenter(items[2], vp), 1248);
  assert.equal(scrollLeftToCenter(items[3], vp), 1872);
  assert.equal(scrollLeftToCenter({ left: 99999, width: 600 }, vp), vp.scrollWidth - vp.clientWidth);
  assert.equal(scrollLeftToCenter({ left: -500, width: 100 }, vp), 0);
});

test("prev/next targets stop at the ends", () => {
  assert.equal(stepIndex(0, -1, 4), null);
  assert.equal(stepIndex(0, 1, 4), 1);
  assert.equal(stepIndex(3, 1, 4), null);
  assert.equal(stepIndex(3, -1, 4), 2);
});
