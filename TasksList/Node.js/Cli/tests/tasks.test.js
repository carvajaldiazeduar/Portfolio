const { addTask, listTasks, completeTask, deleteTask } = require("../tasks");

describe("TasksList", () => {
  let tasks;

  beforeEach(() => {
    tasks = [];
  });

  test("addTask adds a task and returns id", () => {
    const id = addTask(tasks, "Test", "A task");
    expect(id).toBe(1);
    expect(tasks).toHaveLength(1);
    expect(tasks[0].title).toBe("Test");
    expect(tasks[0].completed).toBe(false);
  });

  test("addTask auto-increments id", () => {
    addTask(tasks, "a", "");
    const id = addTask(tasks, "b", "");
    expect(id).toBe(2);
  });

  test("completeTask marks as completed", () => {
    addTask(tasks, "a", "");
    const result = completeTask(tasks, 1);
    expect(result).toBe(true);
    expect(tasks[0].completed).toBe(true);
  });

  test("completeTask not found returns false", () => {
    expect(completeTask(tasks, 99)).toBe(false);
  });

  test("deleteTask removes task", () => {
    addTask(tasks, "a", "");
    const result = deleteTask(tasks, 1);
    expect(result).toBe(true);
    expect(tasks).toHaveLength(0);
  });

  test("deleteTask not found returns false", () => {
    addTask(tasks, "a", "");
    expect(deleteTask(tasks, 99)).toBe(false);
    expect(tasks).toHaveLength(1);
  });
});
