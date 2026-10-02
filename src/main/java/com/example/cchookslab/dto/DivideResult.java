package com.example.cchookslab.dto;

/**
 * /divide 接口返回体。
 *
 * @param quotient 整除结果
 * @param tooBig 结果是否超过阈值
 */
public record DivideResult(int quotient, boolean tooBig) {}
