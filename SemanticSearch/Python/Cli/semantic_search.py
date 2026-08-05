import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "Web", "Plain", "src"))

from storage.vector_factory import create_vector_store


def main():
    store = create_vector_store()
    print("Semantic Search CLI")
    print("1. List collections")
    print("2. Search documents")
    print("3. Delete collection")
    print("4. Exit")
    choice = input("Choose an option: ").strip()
    if choice == "1":
        collections = store.list_collections()
        for c in collections:
            print(f"  - {c}")
    elif choice == "2":
        query = input("Search query: ").strip()
        embedding = [0.0] * int(os.getenv("VECTOR_DIMENSION", "1536"))
        results = store.search(embedding, n_results=5)
        for r in results:
            print(f"  [{r.get('distance', 'N/A')}] {r.get('document', '')[:100]}")
    elif choice == "3":
        name = input("Collection name: ").strip()
        store.delete_collection(name)
        print(f"Collection '{name}' deleted")
    elif choice == "4":
        print("Goodbye!")
    store.close()


if __name__ == "__main__":
    main()
