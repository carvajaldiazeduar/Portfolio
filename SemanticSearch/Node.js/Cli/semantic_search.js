const { createVectorStore } = require("../Web/Plain/src/storage/VectorFactory");

function main() {
  const store = createVectorStore();
  console.log("Semantic Search CLI");
  console.log("1. List collections");
  console.log("2. Search documents");
  console.log("3. Delete collection");
  console.log("4. Exit");
  const readline = require("readline");
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  rl.question("Choose an option: ", (choice) => {
    if (choice === "1") {
      const collections = store.listCollections();
      collections.forEach((c) => console.log(`  - ${c}`));
    } else if (choice === "2") {
      rl.question("Search query: ", (query) => {
        const embedding = new Array(parseInt(process.env.VECTOR_DIMENSION || "1536")).fill(0.0);
        const results = store.search(embedding, 5);
        results.forEach((r) => console.log(`  [${r.distance}] ${(r.document || "").substring(0, 100)}`));
      });
    } else if (choice === "3") {
      rl.question("Collection name: ", (name) => {
        store.deleteCollection(name);
        console.log(`Collection '${name}' deleted`);
      });
    } else if (choice === "4") {
      console.log("Goodbye!");
    }
    rl.close();
    store.close();
  });
}

if (require.main === module) {
  main();
}

module.exports = { main };
