package com.portfolio.semanticsearch;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration;

@SpringBootApplication(exclude = DataSourceAutoConfiguration.class)
public class SemanticSearchApplication {
    public static void main(String[] args) {
        SpringApplication.run(SemanticSearchApplication.class, args);
    }
}
