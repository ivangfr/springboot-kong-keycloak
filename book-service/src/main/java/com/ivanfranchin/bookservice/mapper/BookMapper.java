package com.ivanfranchin.bookservice.mapper;

import com.ivanfranchin.bookservice.model.Book;
import com.ivanfranchin.bookservice.rest.dto.BookResponse;
import com.ivanfranchin.bookservice.rest.dto.CreateBookRequest;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public interface BookMapper {

    @Mapping(target = "id", ignore = true)
    Book toBook(CreateBookRequest createBookRequest);

    BookResponse toBookResponse(Book book);
}
