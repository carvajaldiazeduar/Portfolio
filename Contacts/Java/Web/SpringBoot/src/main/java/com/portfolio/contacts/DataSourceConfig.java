package com.portfolio.contacts;

import org.hibernate.community.dialect.SQLiteDialect;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.jdbc.DataSourceProperties;
import org.springframework.boot.orm.jpa.EntityManagerFactoryBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.orm.jpa.JpaTransactionManager;
import org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean;
import org.springframework.transaction.PlatformTransactionManager;

import javax.sql.DataSource;

import com.zaxxer.hikari.HikariDataSource;

@Configuration
public class DataSourceConfig {

    @Bean
    public DataSource dataSource(
            @Value("${app.db.driver:pgsql}") String driver,
            @Value("${app.db.host:localhost}") String host,
            @Value("${app.db.port:5432}") String port,
            @Value("${app.db.name:contacts}") String dbName,
            @Value("${app.db.user:postgres}") String user,
            @Value("${app.db.password:postgres}") String password,
            @Value("${app.db.file:contacts.db}") String dbFile) {
        String url;
        String className;
        switch (driver.toLowerCase()) {
            case "sqlite":
                url = "jdbc:sqlite:" + dbFile;
                className = "org.sqlite.JDBC";
                break;
            case "mysql":
                url = "jdbc:mysql://" + host + ":" + port + "/" + dbName + "?useSSL=false&serverTimezone=UTC";
                className = "com.mysql.cj.jdbc.Driver";
                break;
            case "sqlserver":
                url = "jdbc:sqlserver://" + host + ":" + port + ";databaseName=" + dbName + ";encrypt=false;trustServerCertificate=true";
                className = "com.microsoft.sqlserver.jdbc.SQLServerDriver";
                break;
            default:
                url = "jdbc:postgresql://" + host + ":" + port + "/" + dbName;
                className = "org.postgresql.Driver";
                break;
        }

        HikariDataSource ds = new HikariDataSource();
        if (url != null) {
            ds.setJdbcUrl(url);
            ds.setDriverClassName(className);
            ds.setUsername(user);
            ds.setPassword(password);
            ds.setMaximumPoolSize(10);
        }
        return ds;
    }

    @Bean
    public LocalContainerEntityManagerFactoryBean entityManagerFactory(
            EntityManagerFactoryBuilder builder, DataSource dataSource,
            @Value("${app.db.driver:pgsql}") String driver) {
        var props = new java.util.HashMap<String, Object>();
        props.put("hibernate.hbm2ddl.auto", "update");
        if ("sqlite".equalsIgnoreCase(driver)) {
            props.put("hibernate.dialect", SQLiteDialect.class.getName());
        }
        return builder
                .dataSource(dataSource)
                .packages(Contact.class)
                .properties(props)
                .build();
    }

    @Bean
    public PlatformTransactionManager transactionManager(LocalContainerEntityManagerFactoryBean emf) {
        return new JpaTransactionManager(emf.getObject());
    }
}
