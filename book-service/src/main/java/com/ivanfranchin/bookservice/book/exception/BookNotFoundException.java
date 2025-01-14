package com.ivanfranchin.bookservice.book.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.NOT_FOUND)
public class BookNotFoundException extends RuntimeException {

    public BookNotFoundException(String isbn) {
        super(String.format("Book with isbn '%s' not found.", isbn));
    }
}
