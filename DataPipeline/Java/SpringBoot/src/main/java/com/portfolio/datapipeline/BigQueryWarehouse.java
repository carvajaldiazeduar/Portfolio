package com.portfolio.datapipeline;

public class BigQueryWarehouse implements DataWarehouseAdapter {
    @Override
    public void connect() {
        throw new UnsupportedOperationException("BigQuery not configured");
    }

    @Override
    public java.util.List<java.util.Map<String, Object>> execute(String query, Object[] params) {
        return new java.util.ArrayList<>();
    }

    @Override
    public void bulkInsert(String table, java.util.List<java.util.Map<String, Object>> records) {
    }

    @Override
    public void createTable(String table, java.util.Map<String, String> schema) {
    }

    @Override
    public java.util.List<String> listTables() {
        return new java.util.ArrayList<>();
    }

    @Override
    public void close() {
    }
}
