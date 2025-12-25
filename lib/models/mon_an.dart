import 'hinh_anh.dart';
import 'phien_ban_mon_an.dart';

class MonAn {
  final String maMonAn;
  final String tenMonAn;
  final double gia; // Giá mặc định (giá nhỏ nhất từ các phiên bản)
  final String maDanhMuc;
  final String? tenDanhMuc;
  final bool isShow;
  final List<HinhAnhMonAn> hinhAnhMonAns;
  final List<PhienBanMonAn> phienBanMonAns; // Danh sách các phiên bản (size) với giá

  MonAn({
    required this.maMonAn,
    required this.tenMonAn,
    required this.gia,
    required this.maDanhMuc,
    this.tenDanhMuc,
    this.isShow = true,
    required this.hinhAnhMonAns,
    required this.phienBanMonAns,
  });

  factory MonAn.fromJson(Map<String, dynamic> json) {
    // Xử lý cả PascalCase và camelCase cho tất cả fields
    final maMonAnValue = json['maMonAn'] ?? json['MaMonAn'];
    final tenMonAnValue = json['tenMonAn'] ?? json['TenMonAn'];
    final maDanhMucValue = json['maDanhMuc'] ?? json['MaDanhMuc'];
    final tenDanhMucValue = json['tenDanhMuc'] ?? json['TenDanhMuc'];
    final isShowValue = json['isShow'] ?? json['IsShow'] ?? true;
    
    // Parse hình ảnh - xử lý cả PascalCase và camelCase
    final hinhAnhList = json['hinhAnhMonAns'] ?? json['HinhAnhMonAns'] ?? [];
    final List<dynamic> hinhAnhListNormalized = hinhAnhList is List ? hinhAnhList : [];
    
    final images = hinhAnhListNormalized.map((i) {
      // Backend trả về HinhAnhDTO với URLHinhAnh hoặc urlHinhAnh
      if (i is Map) {
        final map = Map<String, dynamic>.from(i);
        return HinhAnhMonAn.fromJson({
          'urlHinhAnh': map['urlHinhAnh'] ?? map['URLHinhAnh'] ?? map['UrlHinhAnh'] ?? '',
        });
      }
      return HinhAnhMonAn.fromJson({});
    }).toList();

    // Parse phiên bản món ăn - xử lý cả PascalCase và camelCase
    final phienBanList = json['phienBanMonAns'] ?? json['PhienBanMonAns'] ?? [];
    final List<dynamic> phienBanListNormalized = phienBanList is List ? phienBanList : [];
    final phienBans = phienBanListNormalized.map((pb) {
      if (pb is Map) {
        return PhienBanMonAn.fromJson(Map<String, dynamic>.from(pb));
      }
      return PhienBanMonAn.fromJson({});
    }).toList();

    // Tính giá mặc định (giá nhỏ nhất từ các phiên bản)
    double defaultGia = 0.0;
    if (phienBans.isNotEmpty) {
      final prices = phienBans.map((pb) => pb.gia).where((p) => p > 0);
      if (prices.isNotEmpty) {
        defaultGia = prices.reduce((a, b) => a < b ? a : b);
      }
    }
    
    // Nếu không có phiên bản, lấy giá trực tiếp từ JSON
    if (defaultGia == 0.0) {
      final giaValue = json['gia'] ?? json['Gia'];
      if (giaValue != null) {
        defaultGia = (giaValue is num) ? giaValue.toDouble() : (double.tryParse(giaValue.toString()) ?? 0.0);
      }
    }

    // Validate required fields
    if (maMonAnValue == null || maMonAnValue.toString().isEmpty) {
      throw Exception('maMonAn is required but was null or empty. JSON: $json');
    }
    if (tenMonAnValue == null || tenMonAnValue.toString().isEmpty) {
      throw Exception('tenMonAn is required but was null or empty. JSON: $json');
    }

    return MonAn(
      maMonAn: maMonAnValue.toString(),
      tenMonAn: tenMonAnValue.toString(),
      gia: defaultGia,
      maDanhMuc: maDanhMucValue?.toString() ?? '',
      tenDanhMuc: tenDanhMucValue?.toString(),
      isShow: isShowValue is bool ? isShowValue : (isShowValue.toString().toLowerCase() == 'true'),
      hinhAnhMonAns: images,
      phienBanMonAns: phienBans,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maMonAn': maMonAn,
      'tenMonAn': tenMonAn,
      'gia': gia,
      'maDanhMuc': maDanhMuc,
      'tenDanhMuc': tenDanhMuc,
      'isShow': isShow,
      'hinhAnhMonAns': hinhAnhMonAns.map((h) => h.toJson()).toList(),
      'phienBanMonAns': phienBanMonAns.map((pb) => pb.toJson()).toList(),
    };
  }
}