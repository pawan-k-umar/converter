package com.converter.setup;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.ComponentScan;

@SpringBootApplication
@ComponentScan("com.converter")
public class ConverterApplication {

    public static void main(String[] args) {
        SpringApplication.run(ConverterApplication.class, args);
    }

}
