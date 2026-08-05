import sys
from datetime import datetime


def _next_id(tasks):
    if not tasks:
        return 1
    return max(t["id"] for t in tasks) + 1


def add_task(tasks, title, description):
    task = {
        "id": _next_id(tasks),
        "title": title,
        "description": description,
        "completed": False,
        "created_at": datetime.now().isoformat(),
    }
    tasks.append(task)
    return task["id"]


def list_tasks(tasks):
    if not tasks:
        print("No tasks found.")
        return
    for t in tasks:
        status = "[x]" if t["completed"] else "[ ]"
        print(f"{status} {t['id']}. {t['title']} — {t['created_at']}")


def complete_task(tasks, id):
    for t in tasks:
        if t["id"] == id:
            t["completed"] = True
            return True
    return False


def delete_task(tasks, id):
    for i, t in enumerate(tasks):
        if t["id"] == id:
            tasks.pop(i)
            return True
    return False


def main():
    tasks = []
    while True:
        print("\n=== Tasks List ===")
        print("1. Add Task")
        print("2. List Tasks")
        print("3. Complete Task")
        print("4. Delete Task")
        print("5. Exit")
        choice = input("Choose an option: ").strip()

        if choice == "1":
            title = input("Title: ").strip()
            description = input("Description: ").strip()
            add_task(tasks, title, description)
            print("Task added.")
        elif choice == "2":
            list_tasks(tasks)
        elif choice == "3":
            try:
                tid = int(input("Task ID to complete: ").strip())
                if complete_task(tasks, tid):
                    print("Task completed.")
                else:
                    print("Task not found.")
            except ValueError:
                print("Invalid ID.")
        elif choice == "4":
            try:
                tid = int(input("Task ID to delete: ").strip())
                if delete_task(tasks, tid):
                    print("Task deleted.")
                else:
                    print("Task not found.")
            except ValueError:
                print("Invalid ID.")
        elif choice == "5":
            print("Goodbye!")
            break
        else:
            print("Invalid option.")


if __name__ == "__main__":
    main()
