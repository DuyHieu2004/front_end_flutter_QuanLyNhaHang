import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ToastUtils {
  ToastUtils._();

  /// Hiển thị toast thành công (màu xanh lá)
  static void showSuccess(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  /// Hiển thị toast lỗi (màu đỏ)
  static void showError(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  /// Hiển thị toast cảnh báo (màu cam)
  static void showWarning(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.orange,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  /// Hiển thị toast thông tin (màu xanh dương)
  static void showInfo(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.blue,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  /// Hiển thị toast mặc định (màu xám)
  static void showDefault(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.grey[600],
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  /// Hiển thị toast tùy chỉnh với nhiều tham số
  static void showCustom({
    required String message,
    Color? backgroundColor,
    Color? textColor,
    double? fontSize,
    Toast? toastLength,
    ToastGravity? gravity,
  }) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: toastLength ?? Toast.LENGTH_SHORT,
      gravity: gravity ?? ToastGravity.BOTTOM,
      backgroundColor: backgroundColor ?? Colors.grey[600],
      textColor: textColor ?? Colors.white,
      fontSize: fontSize ?? 16.0,
    );
  }

  /// Hiển thị toast ở vị trí trên cùng
  static void showTop(String message, {Color? backgroundColor}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      backgroundColor: backgroundColor ?? Colors.grey[600],
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  /// Hiển thị toast ở giữa màn hình
  static void showCenter(String message, {Color? backgroundColor}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      backgroundColor: backgroundColor ?? Colors.grey[600],
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}