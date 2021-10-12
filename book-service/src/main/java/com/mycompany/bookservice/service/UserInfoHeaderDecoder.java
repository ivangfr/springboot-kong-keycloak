package com.mycompany.bookservice.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import javax.servlet.http.HttpServletRequest;
import java.util.Base64;
import java.util.Optional;

@Slf4j
@RequiredArgsConstructor
@Service
public class UserInfoHeaderDecoder {

    private final ObjectMapper objectMapper;

    public Optional<UserInfo> decode(HttpServletRequest request) {
        String xUserinfo = request.getHeader("X-Userinfo");
        if (xUserinfo == null) {
            return Optional.empty();
        }
        byte[] decodedBytes = Base64.getDecoder().decode(xUserinfo);
        return deserialize(new String(decodedBytes));
    }

    public Optional<UserInfo> deserialize(String decodedString) {
        try {
            return Optional.of(objectMapper.readValue(decodedString, UserInfo.class));
        } catch (JsonProcessingException e) {
            log.error("Unable to deserialize the string: {}", decodedString);
            return Optional.empty();
        }
    }

    @Data
    public static class UserInfo {
        private String username;
    }
}
