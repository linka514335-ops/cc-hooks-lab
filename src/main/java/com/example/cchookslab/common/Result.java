package com.example.cchookslab.common;

/** 团队统一响应包装。code=0 表示成功，非 0 表示错误（对应 HTTP 状态码）。 */
public record Result<T>(int code, String message, T data) {

  public static <T> Result<T> success(T data) {
    return new Result<>(0, "OK", data);
  }

  public static <T> Result<T> error(int code, String message) {
    return new Result<>(code, message, null);
  }
}
