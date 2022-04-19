package com.mycompany.bookservice.mapper;

import com.mycompany.bookservice.model.Book;
import com.mycompany.bookservice.rest.dto.BookResponse;
import com.mycompany.bookservice.rest.dto.CreateBookRequest;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public interface BookMapper {

    @Mapping(target = "id", ignore = true)
    Book toBook(CreateBookRequest createBookRequest);

    BookResponse toBookResponse(Book book);
}
