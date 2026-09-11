import { test } from 'node:test';
import assert from 'node:assert/strict';
import { chooseDiagrams } from '../assets/js/diagram-gallery.mjs';

const items = [
  { id: 'a', year: 2025 }, { id: 'b', year: 2025 },
  { id: 'c', year: 2021 }, { id: 'off-page', year: 2020 }
];
test('one diagram per matching year, in publication order, without changing the catalogue', () => {
  const original = structuredClone(items);
  const selected = chooseDiagrams(items, [2026, 2025, 2024, 2021], () => 0);
  assert.deepEqual(selected.map(item => item.id), ['a', 'c']);
  assert.deepEqual(items, original);
});
test('random choice can select any candidate within its year', () => {
  assert.equal(chooseDiagrams(items, [2025], () => 0)[0].id, 'a');
  assert.equal(chooseDiagrams(items, [2025], () => 0.99)[0].id, 'b');
});
test('empty collections and unmatched years select nothing', () => {
  assert.deepEqual(chooseDiagrams([], [2025]), []);
  assert.deepEqual(chooseDiagrams(items, []), []);
  assert.deepEqual(chooseDiagrams(items, [2026]), []);
});
