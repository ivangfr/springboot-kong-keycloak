package com.ivanfranchin.bookservice.service;

import com.ivanfranchin.bookservice.exception.BookDuplicateIsbnException;
import com.ivanfranchin.bookservice.exception.BookNotFoundException;
import com.ivanfranchin.bookservice.repository.BookRepository;
import com.ivanfranchin.bookservice.model.Book;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;

import java.util.List;

@RequiredArgsConstructor
@Service
public class BookServiceImpl implements BookService {

    private final BookRepository bookRepository;

    @Override
    public List<Book> getBooks() {
        return bookRepository.findAll();
    }

    @Override
    public Book saveBook(Book book) {
        try {
            return bookRepository.save(book);
        } catch (DuplicateKeyException e) {
            throw new BookDuplicateIsbnException(book.getIsbn());
        }
    }

    @Override
    public void deleteBook(Book book) {
        bookRepository.delete(book);
    }

    @Override
    public Book validateAndGetBookByIsbn(String isbn) {
        return bookRepository.findByIsbn(isbn).orElseThrow(() -> new BookNotFoundException(isbn));
    }
}
