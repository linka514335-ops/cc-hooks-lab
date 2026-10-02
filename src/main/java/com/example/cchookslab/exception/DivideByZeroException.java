package com.example.cchookslab.exception;

/** 除数为零时抛出的业务异常，由全局异常处理器转为 400。 */
public class DivideByZeroException extends RuntimeException {

  public DivideByZeroException(String message) {
    super(message);
  }
}
