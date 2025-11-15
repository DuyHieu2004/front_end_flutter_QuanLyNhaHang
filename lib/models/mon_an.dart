import 'hinh_anh.dart';

class MonAn {
  final String maMonAn;
  final String tenMonAn;
  final double gia;
  final String maDanhMuc;
  final List<HinhAnhMonAn> hinhAnhMonAns;

  MonAn({
    required this.maMonAn,
    required this.tenMonAn,
    required this.gia,
    required this.maDanhMuc,
    required this.hinhAnhMonAns,
  });

  factory MonAn.fromJson(Map<String, dynamic> json) {
    var hinhAnhList = json['hinhAnhMonAns'] as List;
    List<HinhAnhMonAn> images = hinhAnhList.map((i) => HinhAnhMonAn.fromJson(i)).toList();

    return MonAn(
      maMonAn: json['maMonAn'],
      tenMonAn: json['tenMonAn'],
      gia: (json['gia'] as num).toDouble(),
      maDanhMuc: json['maDanhMuc'],
      hinhAnhMonAns: images,
    );
  }
}