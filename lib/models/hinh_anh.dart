import '../services/api_constants.dart';

class HinhAnhMonAn {
  final String urlHinhAnh;

  HinhAnhMonAn({required this.urlHinhAnh});

  factory HinhAnhMonAn.fromJson(Map<String, dynamic> json) {
    final raw = (json['urlHinhAnh'] ?? '').toString();

    // Nếu backend trả về path tương đối: "images/..." hoặc "/images/..."
    // thì ghép với imageBaseUrl để tạo URL đầy đủ.
    String resolvedUrl = raw;

    if (raw.isNotEmpty) {
      final lower = raw.toLowerCase();
      final isHttp = lower.startsWith('http://') || lower.startsWith('https://');
      final isFile = lower.startsWith('file://');

      if (!isHttp && !isFile) {
        // Đảm bảo có dấu / giữa domain và path
        if (raw.startsWith('/')) {
          resolvedUrl = '${ApiConstants.imageBaseUrl}$raw';
        } else {
          resolvedUrl = '${ApiConstants.imageBaseUrl}/$raw';
        }
      }
    }

    return HinhAnhMonAn(
      urlHinhAnh: resolvedUrl,
    );
  }
}