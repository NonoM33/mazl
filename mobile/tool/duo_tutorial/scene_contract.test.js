// The scene (tutorial.js) and its maths (pose_math.js) are two classic
// scripts sharing ONE global. They once disagreed on its name: the page loaded
// without the maths, threw on its first line, and the 3D scene stayed blank.
const { test, expect } = require('bun:test');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const dir = path.join(__dirname, '../../assets/duo_tutorial');
const read = (name) => fs.readFileSync(path.join(dir, name), 'utf8');

test('pose_math.js, loaded as a classic script, publishes the global tutorial.js reads', () => {
  const window = {};
  vm.runInNewContext(read('pose_math.js'), { window, globalThis: window, Math });
  const used = read('tutorial.js').match(/const M = window\.([A-Za-z_$][\w$]*);/);
  expect(used).not.toBeNull();
  const api = window[used[1]];
  expect(api).toBeDefined();
  // Every helper the scene calls exists in the maths it loads.
  const called = [...new Set(read('tutorial.js').match(/\bM\.[A-Za-z_$][\w$]*/g).map((m) => m.slice(2)))];
  expect(called.length).toBeGreaterThan(5);
  for (const fn of called) expect(typeof api[fn]).toBe('function');
});

test('index.html loads three.js, then the maths, then the scene', () => {
  const html = read('index.html');
  const order = ['three.min.js', 'pose_math.js', 'tutorial.js'].map((f) => html.indexOf(`src="${f}"`));
  expect(order.every((i) => i >= 0)).toBe(true);
  expect([...order].sort((a, b) => a - b)).toEqual(order);
});
