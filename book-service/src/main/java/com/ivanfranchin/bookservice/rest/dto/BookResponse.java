package com.ivanfranchin.bookservice.rest.dto;

import com.ivanfranchin.bookservice.model.Book;

public record BookResponse(String id, String isbn, String title) {

    public static BookResponse from(Book book) {
        return new BookResponse(book.getId(), book.getIsbn(), book.getTitle());
    }
}
