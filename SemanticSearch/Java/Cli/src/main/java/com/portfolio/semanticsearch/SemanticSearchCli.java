package com.portfolio.semanticsearch;

import com.portfolio.semanticsearch.vectorstore.SearchResult;
import com.portfolio.semanticsearch.vectorstore.VectorStoreAdapter;
import com.portfolio.semanticsearch.vectorstore.VectorStoreFactory;

import java.util.List;
import java.util.Scanner;

public class SemanticSearchCli {

    public static void main(String[] args) {
        VectorStoreAdapter store = VectorStoreFactory.create();
        store.connect();
        Scanner scanner = new Scanner(System.in);
        try {
            while (true) {
                printMenu();
                String choice = scanner.nextLine().trim();
                switch (choice) {
                    case "1":
                        listCollections(store);
                        break;
                    case "2":
                        searchDocuments(store, scanner);
                        break;
                    case "3":
                        deleteCollection(store, scanner);
                        break;
                    case "4":
                        System.out.println("Goodbye!");
                        return;
                    default:
                        System.out.println("Invalid option.");
                }
            }
        } finally {
            store.close();
            scanner.close();
        }
    }

    private static void printMenu() {
        System.out.println("Semantic Search CLI");
        System.out.println("1. List collections");
        System.out.println("2. Search documents");
        System.out.println("3. Delete collection");
        System.out.println("4. Exit");
    }

    private static void listCollections(VectorStoreAdapter store) {
        List<String> collections = store.listCollections();
        if (collections.isEmpty()) {
            System.out.println("  (no collections)");
            return;
        }
        for (String c : collections) {
            System.out.println("  - " + c);
        }
    }

    private static void searchDocuments(VectorStoreAdapter store, Scanner scanner) {
        System.out.print("Search query: ");
        String query = scanner.nextLine().trim();
        if (query.isEmpty()) {
            System.out.println("  Empty query.");
            return;
        }
        int dimension = Integer.parseInt(System.getenv().getOrDefault("VECTOR_DIMENSION", "1536"));
        float[] embedding = new float[dimension];
        List<SearchResult> results = store.search(embedding, 5);
        if (results.isEmpty()) {
            System.out.println("  (no results)");
            return;
        }
        for (SearchResult r : results) {
            System.out.println("  [" + r.getDistance() + "] " + truncate(r.getDocument(), 100));
        }
    }

    private static void deleteCollection(VectorStoreAdapter store, Scanner scanner) {
        System.out.print("Collection name: ");
        String name = scanner.nextLine().trim();
        store.deleteCollection(name);
        System.out.println("Collection '" + name + "' deleted");
    }

    private static String truncate(String s, int max) {
        if (s == null) return "";
        return s.length() <= max ? s : s.substring(0, max);
    }
}
