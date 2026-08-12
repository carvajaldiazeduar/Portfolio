package com.portfolio.contacts;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public class ContactInput {
    @NotBlank(message = "Name is required")
    @Size(min = 2, max = 100, message = "Name must be 2-100 characters (letters, spaces, apostrophes, hyphens, dots)")
    @Pattern(regexp = "^[A-Za-zÀ-ÿ' .-]+$", message = "Name must be 2-100 characters (letters, spaces, apostrophes, hyphens, dots)")
    private String name;

    @NotBlank(message = "Phone is required")
    @Pattern(regexp = "^[0-9 +().-]{7,20}$", message = "Phone must be 7-20 characters (digits, spaces, +, parentheses, dashes)")
    private String phone;

    @NotBlank(message = "Email is required")
    @Pattern(regexp = "^[^\\s@]+@[^\\s@]+\\.[^\\s@]{2,}$", message = "Invalid email format")
    private String email;

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }
}
