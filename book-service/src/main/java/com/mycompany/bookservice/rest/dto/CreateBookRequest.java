package com.mycompany.bookservice.rest.dto;

import lombok.Data;

import javax.validation.constraints.NotBlank;

@Data
public class CreateBookRequest {

    @NotBlank
    private String title;
}
