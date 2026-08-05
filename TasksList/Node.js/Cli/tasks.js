const readline = require("readline");

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

function nextId(tasks) {
  if (tasks.length === 0) return 1;
  return Math.max(...tasks.map((t) => t.id)) + 1;
}

function addTask(tasks, title, description) {
  const task = {
    id: nextId(tasks),
    title,
    description,
    completed: false,
    created_at: new Date().toISOString(),
  };
  tasks.push(task);
  return task.id;
}

function listTasks(tasks) {
  if (tasks.length === 0) {
    console.log("No tasks found.");
    return;
  }
  for (const t of tasks) {
    const status = t.completed ? "[x]" : "[ ]";
    console.log(`${status} ${t.id}. ${t.title} — ${t.created_at}`);
  }
}

function completeTask(tasks, id) {
  const task = tasks.find((t) => t.id === id);
  if (!task) return false;
  task.completed = true;
  return true;
}

function deleteTask(tasks, id) {
  const index = tasks.findIndex((t) => t.id === id);
  if (index === -1) return false;
  tasks.splice(index, 1);
  return true;
}

async function main() {
  const tasks = [];

  const prompt = (q) => new Promise((r) => rl.question(q, r));

  while (true) {
    console.log("\n=== Tasks List ===");
    console.log("1. Add Task");
    console.log("2. List Tasks");
    console.log("3. Complete Task");
    console.log("4. Delete Task");
    console.log("5. Exit");

    const choice = (await prompt("Choose an option: ")).trim();

    if (choice === "1") {
      const title = (await prompt("Title: ")).trim();
      const description = (await prompt("Description: ")).trim();
      addTask(tasks, title, description);
      console.log("Task added.");
    } else if (choice === "2") {
      listTasks(tasks);
    } else if (choice === "3") {
      const id = parseInt((await prompt("Task ID to complete: ")).trim());
      if (completeTask(tasks, id)) console.log("Task completed.");
      else console.log("Task not found.");
    } else if (choice === "4") {
      const id = parseInt((await prompt("Task ID to delete: ")).trim());
      if (deleteTask(tasks, id)) console.log("Task deleted.");
      else console.log("Task not found.");
    } else if (choice === "5") {
      console.log("Goodbye!");
      rl.close();
      break;
    } else {
      console.log("Invalid option.");
    }
  }
}

if (require.main === module) {
  main();
}

module.exports = { addTask, listTasks, completeTask, deleteTask };
