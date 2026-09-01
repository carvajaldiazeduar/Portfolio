package com.portfolio.chatai.provider;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestTemplate;

@Configuration
public class ChatProviderConfig {
    @Bean
    public RestTemplate restTemplate() {
        return new RestTemplate();
    }
}
