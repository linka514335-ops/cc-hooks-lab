package com.example.cchookslab.service;

import com.example.cchookslab.dto.DivideResult;
import com.example.cchookslab.exception.DivideByZeroException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

@Service
public class DivideServiceImpl implements DivideService {

  private static final Logger log = LoggerFactory.getLogger(DivideServiceImpl.class);

  private static final int BIG_RESULT_THRESHOLD = 100;

  @Override
  public DivideResult divide(int a, int b) {
    if (b == 0) {
      throw new DivideByZeroException("divisor must not be zero");
    }
    int quotient = a / b;
    boolean tooBig = quotient > BIG_RESULT_THRESHOLD;
    if (tooBig) {
      log.warn("result too big: {}", quotient);
    }
    return new DivideResult(quotient, tooBig);
  }
}
