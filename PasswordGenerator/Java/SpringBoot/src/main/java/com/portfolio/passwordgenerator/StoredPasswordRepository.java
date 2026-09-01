package com.portfolio.passwordgenerator;

import org.springframework.data.jpa.repository.JpaRepository;

public interface StoredPasswordRepository extends JpaRepository<StoredPassword, Long> {
}
