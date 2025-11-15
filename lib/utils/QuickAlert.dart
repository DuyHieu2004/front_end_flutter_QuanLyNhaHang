import 'package:flutter/material.dart';
import 'package:quickalert/quickalert.dart';

class QuickAlertService {
  static void showAlertSuccess(BuildContext context, String message) {
    QuickAlert.show(
      context: context,
      barrierDismissible: false,
      type: QuickAlertType.success,
      title: 'Thành công!',
      text: message,
      confirmBtnText: "OK",
      confirmBtnTextStyle: TextStyle(color: Colors.white),
      autoCloseDuration: Duration(seconds: 2),
    );
  }

  static void showAlertFailure(BuildContext context, String message) {
    QuickAlert.show(
      context: context,
      barrierDismissible: false,
      type: QuickAlertType.error,
      title: 'Lỗi!',
      text: message,
      confirmBtnText: 'Đóng',
      confirmBtnColor: Colors.red,
    );
  }

  static void showAlertWarning(BuildContext context, String message) {
    QuickAlert.show(
      context: context,
      barrierDismissible: false,
      type: QuickAlertType.warning,
      title: 'Cảnh báo!',
      text: message,
      confirmBtnText: 'OK',
      confirmBtnColor: Colors.orange,
      autoCloseDuration: Duration(seconds: 2),
    );
  }

  static void showAlertInfo(BuildContext context, String message) {
    QuickAlert.show(
      context: context,
      barrierDismissible: false,
      type: QuickAlertType.info,
      title: 'Thông tin',
      text: message,
      confirmBtnText: 'OK',
      confirmBtnColor: Colors.blue,
      autoCloseDuration: Duration(seconds: 2),
    );
  }

  // Alert với confirm/cancel
  static void showAlertConfirm(
    BuildContext context,
    String message,
    VoidCallback onConfirm,
  ) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.confirm,
      title: 'Xác nhận',
      text: message,
      confirmBtnText: 'Đồng ý',
      cancelBtnText: 'Hủy',
      confirmBtnColor: Colors.green,
      onConfirmBtnTap: () {
        Navigator.of(context).pop();
        onConfirm();
      },
    );
  }

  // Alert loading
  static void showAlertLoading(BuildContext context, String message) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.loading,
      title: 'Đang xử lý...',
      text: message,
      barrierDismissible: false,
    );
  }

  // Alert custom với nhiều options
  static void showAlertCustom({
    required BuildContext context,
    required String title,
    required String message,
    QuickAlertType type = QuickAlertType.info,
    String confirmText = 'OK',
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool dismissible = true,
  }) {
    QuickAlert.show(
      context: context,
      type: type,
      title: title,
      text: message,
      confirmBtnText: confirmText,
      cancelBtnText: cancelText ?? 'Hủy',
      barrierDismissible: dismissible,
      onConfirmBtnTap:
          onConfirm != null
              ? () {
                Navigator.of(context).pop();
                onConfirm();
              }
              : null,
      onCancelBtnTap:
          cancelText != null && onCancel != null
              ? () {
                Navigator.of(context).pop();
                onCancel();
              }
              : null,
    );
  }
}
