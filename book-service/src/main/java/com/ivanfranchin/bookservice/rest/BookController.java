package com.ivanfranchin.bookservice.rest;

import com.ivanfranchin.bookservice.mapper.BookMapper;
import com.ivanfranchin.bookservice.model.Book;
import com.ivanfranchin.bookservice.rest.dto.BookResponse;
import com.ivanfranchin.bookservice.rest.dto.CreateBookRequest;
import com.ivanfranchin.bookservice.service.BookService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import javax.servlet.http.HttpServletRequest;
import javax.validation.Valid;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@RequiredArgsConstructor
@RestController
@RequestMapping("/api/books")
public class BookController {

    private final BookService bookService;
    private final BookMapper bookMapper;

    @GetMapping
    public List<BookResponse> getBooks(HttpServletRequest request) {
        log.info("Get books made by {}", request.getHeader("x-username"));
        List<Book> books = bookService.getBooks();
        return books.stream().map(bookMapper::toBookResponse).collect(Collectors.toList());
    }

    @GetMapping("/{isbn}")
    public BookResponse getBookByIsbn(@PathVariable String isbn, HttpServletRequest request) {
        log.info("Get books with isbn equals to {} made by {}", isbn, request.getHeader("x-username"));
        Book book = bookService.validateAndGetBookByIsbn(isbn);
        return bookMapper.toBookResponse(book);
    }

    @ResponseStatus(HttpStatus.CREATED)
    @PostMapping
    public BookResponse createBook(@Valid @RequestBody CreateBookRequest createBookRequest, HttpServletRequest request) {
        log.info("Request to create a book {} made by {}", createBookRequest, request.getHeader("x-username"));
        Book book = bookMapper.toBook(createBookRequest);
        book = bookService.saveBook(book);
        return bookMapper.toBookResponse(book);
    }

    @DeleteMapping("/{isbn}")
    public BookResponse deleteBook(@PathVariable String isbn, HttpServletRequest request) {
        log.info("Request to remove book with isbn {} made by {}", isbn, request.getHeader("x-username"));
        Book book = bookService.validateAndGetBookByIsbn(isbn);
        bookService.deleteBook(book);
        return bookMapper.toBookResponse(book);
    }
}
