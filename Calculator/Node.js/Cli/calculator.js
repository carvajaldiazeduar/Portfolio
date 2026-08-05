const readline = require("readline");

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

function add(a, b) {
  return a + b;
}

function subtract(a, b) {
  return a - b;
}

function multiply(a, b) {
  return a * b;
}

function divide(a, b) {
  if (b === 0) return "Error: Cannot divide by zero";
  return a / b;
}

function getNumber(prompt) {
  return new Promise((resolve) => {
    rl.question(prompt, (input) => {
      const num = parseFloat(input);
      if (isNaN(num)) {
        console.log("Invalid input. Please enter a number.");
        resolve(getNumber(prompt));
      } else {
        resolve(num);
      }
    });
  });
}

async function main() {
  const operations = {
    1: { name: "add", fn: add, symbol: "+" },
    2: { name: "subtract", fn: subtract, symbol: "-" },
    3: { name: "multiply", fn: multiply, symbol: "*" },
    4: { name: "divide", fn: divide, symbol: "/" },
  };

  while (true) {
    console.log("\n=== Simple Calculator ===");
    console.log("1. Add");
    console.log("2. Subtract");
    console.log("3. Multiply");
    console.log("4. Divide");
    console.log("5. Exit");

    const choice = await new Promise((resolve) => {
      rl.question("Choose an option (1-5): ", resolve);
    });

    if (choice === "5") {
      console.log("Goodbye!");
      rl.close();
      break;
    }

    const op = operations[choice];
    if (!op) {
      console.log("Invalid option. Please try again.");
      continue;
    }

    const num1 = await getNumber("Enter first number: ");
    const num2 = await getNumber("Enter second number: ");
    const result = op.fn(num1, num2);

    console.log(`\n${num1} ${op.symbol} ${num2} = ${result}`);
  }
}

if (require.main === module) {
  main();
}

module.exports = { add, subtract, multiply, divide };
