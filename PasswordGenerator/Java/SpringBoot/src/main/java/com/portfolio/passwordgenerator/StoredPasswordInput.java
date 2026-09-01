package com.portfolio.passwordgenerator;

import jakarta.validation.constraints.NotBlank;

public class StoredPasswordInput {
    @NotBlank(message = "Password is required")
    private String password;

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }
}
