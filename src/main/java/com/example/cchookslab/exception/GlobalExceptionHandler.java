package com.example.cchookslab.exception;

import com.example.cchookslab.common.Result;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

@RestControllerAdvice
public class GlobalExceptionHandler {

  @ExceptionHandler(DivideByZeroException.class)
  @ResponseStatus(HttpStatus.BAD_REQUEST)
  public Result<Void> handleDivideByZero(DivideByZeroException e) {
    return Result.error(HttpStatus.BAD_REQUEST.value(), e.getMessage());
  }

  @ExceptionHandler({
    MethodArgumentTypeMismatchException.class,
    MissingServletRequestParameterException.class
  })
  @ResponseStatus(HttpStatus.BAD_REQUEST)
  public Result<Void> handleBadParameter(Exception e) {
    return Result.error(HttpStatus.BAD_REQUEST.value(), "invalid request parameter");
  }
}
