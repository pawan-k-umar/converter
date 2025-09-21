package com.converter.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;

@Controller
public class HomePage {
    @RequestMapping("/")
    public String showHome() {
        return "home";  // Returns the front-end UI
    }
}
