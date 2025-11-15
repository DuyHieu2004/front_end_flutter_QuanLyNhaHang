class HinhAnhMonAn {
  final String urlHinhAnh;

  HinhAnhMonAn({required this.urlHinhAnh});

  factory HinhAnhMonAn.fromJson(Map<String, dynamic> json) {
    return HinhAnhMonAn(
      urlHinhAnh: json['urlHinhAnh'],
    );
  }
}