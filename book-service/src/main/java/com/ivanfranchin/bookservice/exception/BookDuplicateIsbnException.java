package com.ivanfranchin.bookservice.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.CONFLICT)
public class BookDuplicateIsbnException extends RuntimeException {

    public BookDuplicateIsbnException(String isbn) {
        super(String.format("Book with isbn '%s' already exists.", isbn));
    }
}
