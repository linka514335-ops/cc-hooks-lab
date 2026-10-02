package com.example.cchookslab.service;

import com.example.cchookslab.dto.DivideResult;

public interface DivideService {

  /**
   * 计算 a / b。
   *
   * @throws com.example.cchookslab.exception.DivideByZeroException 当 b 为 0
   */
  DivideResult divide(int a, int b);
}
