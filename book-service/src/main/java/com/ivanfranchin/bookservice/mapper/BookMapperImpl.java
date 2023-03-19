package com.ivanfranchin.bookservice.mapper;

import com.ivanfranchin.bookservice.model.Book;
import com.ivanfranchin.bookservice.rest.dto.BookResponse;
import com.ivanfranchin.bookservice.rest.dto.CreateBookRequest;
import org.springframework.stereotype.Service;

@Service
public class BookMapperImpl implements BookMapper {

    @Override
    public Book toBook(CreateBookRequest createBookRequest) {
        if (createBookRequest == null) {
            return null;
        }
        Book book = new Book();
        book.setIsbn(createBookRequest.isbn());
        book.setTitle(createBookRequest.title());
        return book;
    }

    @Override
    public BookResponse toBookResponse(Book book) {
        if (book == null) {
            return null;
        }
        return new BookResponse(book.getId(), book.getIsbn(), book.getTitle());
    }
}
