package com.portfolio.chatai.provider;

import com.portfolio.chatai.model.ChatRequest;
import com.portfolio.chatai.model.ChatResponse;

public interface IChatProvider {
    ChatResponse completeChat(ChatRequest request);
}
