const { generatePassword, UPPERCASE, LOWERCASE, DIGITS, SYMBOLS } = require('../password_generator');

describe('generatePassword', () => {
  test('default length is 16', () => {
    const pw = generatePassword();
    expect(pw).toHaveLength(16);
  });

  test('custom length', () => {
    const pw = generatePassword(24);
    expect(pw).toHaveLength(24);
  });

  test('min length', () => {
    const pw = generatePassword(1, true, false, false, false);
    expect(pw).toHaveLength(1);
  });

  test('uppercase present', () => {
    const pw = generatePassword(10, true, false, false, false);
    expect(pw).toMatch(/[A-Z]/);
  });

  test('lowercase present', () => {
    const pw = generatePassword(10, false, true, false, false);
    expect(pw).toMatch(/[a-z]/);
  });

  test('digits present', () => {
    const pw = generatePassword(10, false, false, true, false);
    expect(pw).toMatch(/[0-9]/);
  });

  test('symbols present', () => {
    const pw = generatePassword(10, false, false, false, true);
    expect(pw).toMatch(/[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]/);
  });

  test('no uppercase', () => {
    const pw = generatePassword(16, false);
    expect(pw).not.toMatch(/[A-Z]/);
  });

  test('no symbols', () => {
    const pw = generatePassword(16, true, true, true, false);
    expect(pw).not.toMatch(/[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]/);
  });

  test('no lowercase', () => {
    const pw = generatePassword(16, false, false);
    expect(pw).not.toMatch(/[a-z]/);
  });

  test('no digits', () => {
    const pw = generatePassword(16, false, false, false);
    expect(pw).not.toMatch(/[0-9]/);
  });

  test('all disabled throws', () => {
    expect(() => generatePassword(10, false, false, false, false)).toThrow();
  });

  test('length zero throws', () => {
    expect(() => generatePassword(0)).toThrow();
  });

  test('negative length throws', () => {
    expect(() => generatePassword(-5)).toThrow();
  });

  test('length too short for categories throws', () => {
    expect(() => generatePassword(2, true, true, true, true)).toThrow();
  });

  test('at least one from each enabled', () => {
    const pw = generatePassword(20, true, true, true, true);
    expect(pw).toMatch(/[A-Z]/);
    expect(pw).toMatch(/[a-z]/);
    expect(pw).toMatch(/[0-9]/);
    expect(pw).toMatch(/[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]/);
  });

  test('only uppercase and digits', () => {
    const pw = generatePassword(12, true, false, true, false);
    expect(pw).toMatch(/[A-Z]/);
    expect(pw).toMatch(/[0-9]/);
    expect(pw).not.toMatch(/[a-z]/);
    expect(pw).not.toMatch(/[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]/);
  });

  test('shuffled not sequential', () => {
    const passwords = new Set(Array.from({ length: 5 }, () => generatePassword()));
    expect(passwords.size).toBeGreaterThan(1);
  });
});
