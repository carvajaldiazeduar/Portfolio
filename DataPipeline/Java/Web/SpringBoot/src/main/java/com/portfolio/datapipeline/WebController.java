package com.portfolio.datapipeline;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class WebController {
    @GetMapping("/swagger")
    public String swagger() {
        return "redirect:/swagger.html";
    }
}
