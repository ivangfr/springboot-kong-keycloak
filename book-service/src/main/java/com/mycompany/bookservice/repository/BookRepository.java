package com.mycompany.bookservice.repository;

import com.mycompany.bookservice.model.Book;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface BookRepository extends MongoRepository<Book, String> {

    Optional<Book> findByIsbn(String isbn);
}
