package com.mycompany.bookservice.rest;

import com.mycompany.bookservice.mapper.BookMapper;
import com.mycompany.bookservice.model.Book;
import com.mycompany.bookservice.rest.dto.BookResponse;
import com.mycompany.bookservice.rest.dto.CreateBookRequest;
import com.mycompany.bookservice.service.BookService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

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
    public List<BookResponse> getBooks() {
        log.info("Get books");
        List<Book> books = bookService.getBooks();
        return books.stream().map(bookMapper::toBookResponse).collect(Collectors.toList());
    }

    @GetMapping("/{isbn}")
    public BookResponse getBookByIsbn(@PathVariable String isbn) {
        log.info("Get books with isbn equals to {}", isbn);
        Book book = bookService.validateAndGetBookByIsbn(isbn);
        return bookMapper.toBookResponse(book);
    }

    @ResponseStatus(HttpStatus.CREATED)
    @PostMapping
    public BookResponse createBook(@Valid @RequestBody CreateBookRequest createBookRequest, HttpServletRequest request) {
        log.info("Post request made by {} to create a book {}", request.getHeader("X-Credential-Username"), createBookRequest);
        Book book = bookMapper.toBook(createBookRequest);
        book = bookService.saveBook(book);
        return bookMapper.toBookResponse(book);
    }

    @DeleteMapping("/{isbn}")
    public BookResponse deleteBook(@PathVariable String isbn, HttpServletRequest request) {
        log.info("Delete request made by {} to remove book with isbn {}", request.getHeader("X-Credential-Username"), isbn);
        Book book = bookService.validateAndGetBookByIsbn(isbn);
        bookService.deleteBook(book);
        return bookMapper.toBookResponse(book);
    }
}
