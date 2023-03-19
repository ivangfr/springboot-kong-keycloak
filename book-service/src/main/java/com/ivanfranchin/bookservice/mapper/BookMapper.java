package com.ivanfranchin.bookservice.mapper;

import com.ivanfranchin.bookservice.model.Book;
import com.ivanfranchin.bookservice.rest.dto.BookResponse;
import com.ivanfranchin.bookservice.rest.dto.CreateBookRequest;

public interface BookMapper {

    Book toBook(CreateBookRequest createBookRequest);

    BookResponse toBookResponse(Book book);
}
