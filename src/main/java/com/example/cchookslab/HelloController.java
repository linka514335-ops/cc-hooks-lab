package com.example.cchookslab;

import com.example.cchookslab.common.Result;
import com.example.cchookslab.dto.DivideResult;
import com.example.cchookslab.service.DivideService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {

  private final DivideService divideService;

  public HelloController(DivideService divideService) {
    this.divideService = divideService;
  }

  @GetMapping("/hello")
  public String hello(@RequestParam(defaultValue = "World") String name) {
    return "Hello, " + name + "!";
  }

  @GetMapping("/divide")
  public Result<DivideResult> divide(@RequestParam int a, @RequestParam int b) {
    return Result.success(divideService.divide(a, b));
  }
}
