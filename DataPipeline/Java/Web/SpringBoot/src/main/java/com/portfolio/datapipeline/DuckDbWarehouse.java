package com.portfolio.datapipeline;

import java.sql.*;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class DuckDbWarehouse implements DataWarehouseAdapter {
    private Connection conn;

    public DuckDbWarehouse(String jdbcUrl) {
        this.jdbcUrl = jdbcUrl;
    }

    private final String jdbcUrl;

    @Override
    public void connect() {
        if (conn != null) return;
        try {
            Class.forName("org.duckdb.DuckDBDriver");
            conn = DriverManager.getConnection(jdbcUrl);
            conn.setAutoCommit(false);
        } catch (Exception e) {
            throw new RuntimeException("Cannot connect to DuckDB at " + jdbcUrl, e);
        }
    }

    @Override
    public List<Map<String, Object>> execute(String query, Object[] params) {
        ensureConnected();
        try (PreparedStatement ps = params != null && params.length > 0 ? conn.prepareStatement(query) : conn.prepareStatement(query)) {
            if (params != null) {
                for (int i = 0; i < params.length; i++) {
                    ps.setObject(i + 1, params[i]);
                }
            }
            boolean hasResults = ps.execute();
            if (hasResults) {
                ResultSet rs = ps.getResultSet();
                return toRows(rs);
            }
            return new ArrayList<>();
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }

    @Override
    public void bulkInsert(String table, List<Map<String, Object>> records) {
        if (records == null || records.isEmpty()) return;
        ensureConnected();
        List<String> cols = new ArrayList<>(records.get(0).keySet());
        String colList = String.join(", ", cols);
        String placeholders = String.join(", ", java.util.Collections.nCopies(cols.size(), "?"));
        String sql = "INSERT INTO " + table + " (" + colList + ") VALUES (" + placeholders + ")";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            for (Map<String, Object> rec : records) {
                int i = 1;
                for (String col : cols) {
                    ps.setObject(i++, rec.get(col));
                }
                ps.addBatch();
            }
            ps.executeBatch();
            conn.commit();
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }

    @Override
    public void createTable(String table, Map<String, String> schema) {
        ensureConnected();
        StringBuilder sb = new StringBuilder();
        sb.append("CREATE TABLE IF NOT EXISTS ").append(table).append(" (");
        boolean first = true;
        for (Map.Entry<String, String> e : schema.entrySet()) {
            if (!first) sb.append(", ");
            first = false;
            sb.append(e.getKey()).append(" ").append(e.getValue());
        }
        sb.append(")");
        try (Statement st = conn.createStatement()) {
            st.execute(sb.toString());
            conn.commit();
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }

    @Override
    public List<String> listTables() {
        ensureConnected();
        try (ResultSet rs = conn.createStatement().executeQuery("SHOW TABLES")) {
            List<String> tables = new ArrayList<>();
            while (rs.next()) {
                tables.add(rs.getString(1));
            }
            return tables;
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }

    @Override
    public void close() {
        if (conn != null) {
            try { conn.close(); } catch (SQLException ignored) {}
            conn = null;
        }
    }

    private void ensureConnected() {
        if (conn == null) connect();
    }

    private List<Map<String, Object>> toRows(ResultSet rs) throws SQLException {
        List<Map<String, Object>> rows = new ArrayList<>();
        ResultSetMetaData md = rs.getMetaData();
        int cols = md.getColumnCount();
        while (rs.next()) {
            Map<String, Object> row = new LinkedHashMap<>();
            for (int i = 1; i <= cols; i++) {
                row.put(md.getColumnName(i), rs.getObject(i));
            }
            rows.add(row);
        }
        return rows;
    }
}
