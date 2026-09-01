package com.portfolio.semanticsearch.vectorstore;

import java.util.Map;

public class SearchResult {
    private String document;
    private Map<String, Object> metadata;
    private double distance;

    public SearchResult() {
    }

    public SearchResult(String document, Map<String, Object> metadata, double distance) {
        this.document = document;
        this.metadata = metadata;
        this.distance = distance;
    }

    public String getDocument() {
        return document;
    }

    public void setDocument(String document) {
        this.document = document;
    }

    public Map<String, Object> getMetadata() {
        return metadata;
    }

    public void setMetadata(Map<String, Object> metadata) {
        this.metadata = metadata;
    }

    public double getDistance() {
        return distance;
    }

    public void setDistance(double distance) {
        this.distance = distance;
    }
}
