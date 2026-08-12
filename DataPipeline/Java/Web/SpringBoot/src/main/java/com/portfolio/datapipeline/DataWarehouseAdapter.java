package com.portfolio.datapipeline;

public interface DataWarehouseAdapter {
    void connect();
    java.util.List<java.util.Map<String, Object>> execute(String query, Object[] params);
    void bulkInsert(String table, java.util.List<java.util.Map<String, Object>> records);
    void createTable(String table, java.util.Map<String, String> schema);
    java.util.List<String> listTables();
    void close();
}
