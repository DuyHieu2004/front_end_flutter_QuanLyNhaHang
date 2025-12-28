class Menu {
  final String maMenu;
  final String tenMenu;
  final String? loaiMenu;
  final double? giaMenu;
  final double? giaGoc;
  final double? phanTramGiamGia;
  final String? moTa;
  final String? hinhAnh;
  final DateTime? ngayBatDau;
  final DateTime? ngayKetThuc;
  final List<ChiTietMenu>? chiTietMenus;

  Menu({
    required this.maMenu,
    required this.tenMenu,
    this.loaiMenu,
    this.giaMenu,
    this.giaGoc,
    this.phanTramGiamGia,
    this.moTa,
    this.hinhAnh,
    this.ngayBatDau,
    this.ngayKetThuc,
    this.chiTietMenus,
  });

  // Helper method để parse giá từ JSON
  static double? _parsePrice(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed;
    }
    return null;
  }

  factory Menu.fromJson(Map<String, dynamic> json) {
    // Helper để parse DateTime an toàn
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      try {
        if (value is String && value.isNotEmpty) {
          return DateTime.parse(value);
        }
        return null;
      } catch (e) {
        print('Warning: Failed to parse DateTime: $value - $e');
        return null;
      }
    }

    return Menu(
      maMenu: json['maMenu'] ?? json['MaMenu'] ?? '',
      tenMenu: json['tenMenu'] ?? json['TenMenu'] ?? '',
      loaiMenu: json['loaiMenu'] ?? json['LoaiMenu'],
      giaMenu: _parsePrice(json['giaMenu'] ?? json['GiaMenu']),
      giaGoc: _parsePrice(json['giaGoc'] ?? json['GiaGoc']),
      phanTramGiamGia: json['phanTramGiamGia'] != null
          ? (json['phanTramGiamGia'] is int ? json['phanTramGiamGia'].toDouble() : json['phanTramGiamGia'])
          : (json['PhanTramGiamGia'] != null
              ? (json['PhanTramGiamGia'] is int ? json['PhanTramGiamGia'].toDouble() : json['PhanTramGiamGia'])
              : null),
      moTa: json['moTa'] ?? json['MoTa'],
      hinhAnh: json['hinhAnh'] ?? json['HinhAnh'],
      ngayBatDau: parseDateTime(json['ngayBatDau'] ?? json['NgayBatDau']),
      ngayKetThuc: parseDateTime(json['ngayKetThuc'] ?? json['NgayKetThuc']),
      chiTietMenus: json['chiTietMenus'] != null
          ? (json['chiTietMenus'] as List).map((e) => ChiTietMenu.fromJson(e)).toList()
          : (json['ChiTietMenus'] != null
              ? (json['ChiTietMenus'] as List).map((e) => ChiTietMenu.fromJson(e)).toList()
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maMenu': maMenu,
      'tenMenu': tenMenu,
      'loaiMenu': loaiMenu,
      'giaMenu': giaMenu,
      'giaGoc': giaGoc,
      'phanTramGiamGia': phanTramGiamGia,
      'moTa': moTa,
      'hinhAnh': hinhAnh,
      'ngayBatDau': ngayBatDau?.toIso8601String(),
      'ngayKetThuc': ngayKetThuc?.toIso8601String(),
      'chiTietMenus': chiTietMenus?.map((e) => e.toJson()).toList(),
    };
  }
}

class ChiTietMenu {
  final int? soLuong;
  final String? ghiChu;
  final MonAnTrongMenu? monAn;

  ChiTietMenu({
    this.soLuong,
    this.ghiChu,
    this.monAn,
  });

  factory ChiTietMenu.fromJson(Map<String, dynamic> json) {
    return ChiTietMenu(
      soLuong: json['soLuong'] ?? json['SoLuong'],
      ghiChu: json['ghiChu'] ?? json['GhiChu'],
      monAn: json['monAn'] != null
          ? MonAnTrongMenu.fromJson(json['monAn'])
          : (json['MonAn'] != null ? MonAnTrongMenu.fromJson(json['MonAn']) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'soLuong': soLuong,
      'ghiChu': ghiChu,
      'monAn': monAn?.toJson(),
    };
  }
}

class MonAnTrongMenu {
  final String? tenMonAn;
  final String? hinhAnh;
  final double? gia;

  MonAnTrongMenu({
    this.tenMonAn,
    this.hinhAnh,
    this.gia,
  });

  factory MonAnTrongMenu.fromJson(Map<String, dynamic> json) {
    return MonAnTrongMenu(
      tenMonAn: json['tenMonAn'] ?? json['TenMonAn'],
      hinhAnh: json['hinhAnh'] ?? json['HinhAnh'],
      gia: json['gia'] != null
          ? (json['gia'] is int ? json['gia'].toDouble() : json['gia'])
          : (json['Gia'] != null
              ? (json['Gia'] is int ? json['Gia'].toDouble() : json['Gia'])
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenMonAn': tenMonAn,
      'hinhAnh': hinhAnh,
      'gia': gia,
    };
  }
}

