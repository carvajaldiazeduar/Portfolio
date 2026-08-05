#!/usr/bin/env node

const readline = require('readline');

const UPPERCASE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
const LOWERCASE = 'abcdefghijklmnopqrstuvwxyz';
const DIGITS = '0123456789';
const SYMBOLS = '!@#$%^&*()_+-=[]{}|;:,.<>?';

function generatePassword(length = 16, useUpper = true, useLower = true, useDigits = true, useSymbols = true) {
  if (length < 1) {
    throw new Error('Password length must be at least 1');
  }

  const categories = [];
  if (useUpper) categories.push(UPPERCASE);
  if (useLower) categories.push(LOWERCASE);
  if (useDigits) categories.push(DIGITS);
  if (useSymbols) categories.push(SYMBOLS);

  if (categories.length === 0) {
    throw new Error('At least one character category must be enabled');
  }

  if (length < categories.length) {
    throw new Error(
      `Password length must be at least ${categories.length} ` +
      `when ${categories.length} categories are enabled`
    );
  }

  const passwordChars = [];
  for (const cat of categories) {
    passwordChars.push(cat[Math.floor(Math.random() * cat.length)]);
  }

  const allChars = categories.join('');
  while (passwordChars.length < length) {
    passwordChars.push(allChars[Math.floor(Math.random() * allChars.length)]);
  }

  for (let i = passwordChars.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [passwordChars[i], passwordChars[j]] = [passwordChars[j], passwordChars[i]];
  }

  return passwordChars.join('');
}

function showMenu() {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });

  console.log('=== Password Generator ===');

  rl.question('Length (default 16): ', (lengthInput) => {
    const length = parseInt(lengthInput) || 16;

    rl.question('Include uppercase? (Y/n): ', (up) => {
      const useUpper = up.trim().toLowerCase() !== 'n';

      rl.question('Include lowercase? (Y/n): ', (lo) => {
        const useLower = lo.trim().toLowerCase() !== 'n';

        rl.question('Include digits? (Y/n): ', (di) => {
          const useDigits = di.trim().toLowerCase() !== 'n';

          rl.question('Include symbols? (Y/n): ', (sy) => {
            const useSymbols = sy.trim().toLowerCase() !== 'n';

            try {
              const password = generatePassword(length, useUpper, useLower, useDigits, useSymbols);
              console.log(`\nGenerated password: ${password}`);
            } catch (e) {
              console.log(`Error: ${e.message}`);
            }

            rl.close();
          });
        });
      });
    });
  });
}

if (require.main === module) {
  const args = process.argv.slice(2);
  if (args.length > 0) {
    let length = 16;
    let useUpper = true, useLower = true, useDigits = true, useSymbols = true;

    for (let i = 0; i < args.length; i++) {
      switch (args[i]) {
        case '-l':
        case '--length':
          length = parseInt(args[++i]) || 16;
          break;
        case '--no-upper':
          useUpper = false;
          break;
        case '--no-lower':
          useLower = false;
          break;
        case '--no-digits':
          useDigits = false;
          break;
        case '--no-symbols':
          useSymbols = false;
          break;
      }
    }

    try {
      console.log(generatePassword(length, useUpper, useLower, useDigits, useSymbols));
    } catch (e) {
      console.error(`Error: ${e.message}`);
      process.exit(1);
    }
  } else {
    showMenu();
  }
}

module.exports = { generatePassword, UPPERCASE, LOWERCASE, DIGITS, SYMBOLS };
