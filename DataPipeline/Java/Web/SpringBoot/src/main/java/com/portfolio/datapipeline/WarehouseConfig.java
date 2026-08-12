package com.portfolio.datapipeline;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class WarehouseConfig {

    @Bean
    public DataWarehouseAdapter dataWarehouseAdapter(
            @Value("${app.warehouse.driver:duckdb}") String driver,
            @Value("${app.warehouse.path:}") String warehousePath) {
        String jdbcUrl;
        if (warehousePath == null || warehousePath.isBlank()) {
            jdbcUrl = "jdbc:duckdb:";
        } else {
            jdbcUrl = "jdbc:duckdb:" + warehousePath;
        }
        return switch (driver) {
            case "postgresql" -> new PostgresqlWarehouse();
            case "bigquery" -> new BigQueryWarehouse();
            default -> new DuckDbWarehouse(jdbcUrl);
        };
    }
}
