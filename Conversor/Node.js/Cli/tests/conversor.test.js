const { convert, listCategories } = require('../conversor');

test('length conversion', () => {
  const result = convert(1, 'm', 'cm');
  expect(Math.abs(result - 100)).toBeLessThan(0.001);
});

test('weight conversion', () => {
  const result = convert(1, 'kg', 'g');
  expect(Math.abs(result - 1000)).toBeLessThan(0.001);
});

test('temperature C to F', () => {
  const result = convert(0, 'C', 'F');
  expect(Math.abs(result - 32)).toBeLessThan(0.001);
});

test('temperature C to K', () => {
  const result = convert(0, 'C', 'K');
  expect(Math.abs(result - 273.15)).toBeLessThan(0.001);
});

test('temperature F to C', () => {
  const result = convert(32, 'F', 'C');
  expect(Math.abs(result - 0)).toBeLessThan(0.001);
});

test('temperature F to K', () => {
  const result = convert(32, 'F', 'K');
  expect(Math.abs(result - 273.15)).toBeLessThan(0.001);
});

test('temperature K to C', () => {
  const result = convert(273.15, 'K', 'C');
  expect(Math.abs(result - 0)).toBeLessThan(0.001);
});

test('temperature K to F', () => {
  const result = convert(273.15, 'K', 'F');
  expect(Math.abs(result - 32)).toBeLessThan(0.001);
});

test('invalid unit throws', () => {
  expect(() => convert(1, 'm', 'kg')).toThrow();
});

test('incompatible categories throws', () => {
  expect(() => convert(1, 'm', 'kg')).toThrow();
});

test('list categories', () => {
  const cats = listCategories();
  expect(cats).toContain('length');
  expect(cats).toContain('weight');
  expect(cats).toContain('temperature');
});

test('km to mi', () => {
  const result = convert(1, 'km', 'mi');
  expect(Math.abs(result - 0.621371)).toBeLessThan(0.001);
});

test('ft to in', () => {
  const result = convert(1, 'ft', 'in');
  expect(Math.abs(result - 12)).toBeLessThan(0.001);
});

test('lb to oz', () => {
  const result = convert(1, 'lb', 'oz');
  expect(Math.abs(result - 16)).toBeLessThan(0.001);
});

test('identity conversion', () => {
  const result = convert(100, 'cm', 'cm');
  expect(Math.abs(result - 100)).toBeLessThan(0.001);
});
