import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentScreen extends StatefulWidget {
  final String paymentUrl;
  const PaymentScreen({Key? key, required this.paymentUrl}) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            // --- BẮT LINK DEEP LINK TỪ NÚT CLOSE HOẶC REDIRECT ---
            if (request.url.startsWith('quanlynhahang://')) {
              final uri = Uri.parse(request.url);
              final status = uri.queryParameters['status']; // success hoặc fail

              // Đóng WebView và trả kết quả về cho màn hình trước (DatBanForm hoặc Provider)
              Navigator.pop(context, status == 'success');
              return NavigationDecision.prevent; // Chặn không cho load link này
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thanh toán VNPay"),
        backgroundColor: Colors.deepPurple,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            // Nếu người dùng chủ động tắt nút X trên AppBar -> Coi như thất bại/hủy
            Navigator.pop(context, false);
          },
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}