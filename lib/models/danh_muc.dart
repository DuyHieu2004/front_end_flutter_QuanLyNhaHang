class DanhMuc {
  final String maDanhMuc;
  final String tenDanhMuc;

  DanhMuc({required this.maDanhMuc, required this.tenDanhMuc});

  factory DanhMuc.fromJson(Map<String, dynamic> json) {
    return DanhMuc(
      maDanhMuc: json['maDanhMuc'],
      tenDanhMuc: json['tenDanhMuc'],
    );
  }
}