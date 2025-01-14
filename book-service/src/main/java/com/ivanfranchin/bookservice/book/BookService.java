package com.ivanfranchin.bookservice.book;

import com.ivanfranchin.bookservice.book.exception.BookDuplicateIsbnException;
import com.ivanfranchin.bookservice.book.exception.BookNotFoundException;
import com.ivanfranchin.bookservice.book.model.Book;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;

import java.util.List;

@RequiredArgsConstructor
@Service
public class BookService {

    private final BookRepository bookRepository;

    public List<Book> getBooks() {
        return bookRepository.findAll();
    }

    public Book saveBook(Book book) {
        try {
            return bookRepository.save(book);
        } catch (DuplicateKeyException e) {
            throw new BookDuplicateIsbnException(book.getIsbn());
        }
    }

    public void deleteBook(Book book) {
        bookRepository.delete(book);
    }

    public Book validateAndGetBookByIsbn(String isbn) {
        return bookRepository.findByIsbn(isbn).orElseThrow(() -> new BookNotFoundException(isbn));
    }
}
