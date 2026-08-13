package com.portfolio.chatai.provider;

public class ProviderNotConfiguredException extends RuntimeException {
    private final String provider;

    public ProviderNotConfiguredException(String provider) {
        super("Provider '" + provider + "' is not configured (missing API key)");
        this.provider = provider;
    }

    public String getProvider() {
        return provider;
    }
}
