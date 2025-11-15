class BanAn {
  final String maBan;
  final String tenBan;
  final String? tenTrangThai;
  final int sucChua;
  String? tenTang;

  BanAn({
    required this.maBan,
    required this.tenBan,
    this.tenTrangThai,
    required this.sucChua,
    this.tenTang,
  });

  factory BanAn.fromJson(Map<String, dynamic> json) {
    return BanAn(
      maBan: json['maBan'] as String,
      tenBan: json['tenBan'] as String,
      tenTrangThai: json['tenTrangThai'] as String?,
      sucChua: json['sucChua'] as int,
      tenTang: json['tenTang'],
    );
  }
}