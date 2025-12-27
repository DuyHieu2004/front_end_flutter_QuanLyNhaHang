import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dat_ban_screen.dart';
import 'menu_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  // --- COLOR PALETTE ---
  final Color _wineRed = const Color(0xFF800020);
  final Color _lightWine = const Color(0xFFA52A2A);
  final Color _bgWhite = const Color(0xFFFAFAFA);
  final Color _darkWine = const Color(0xFF500014); // Màu đỏ tối cho phần trích dẫn

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "GIỚI THIỆU",
          style: TextStyle(
            color: _wineRed,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(color: _wineRed),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Section
            _buildHeroSection(context),
            const SizedBox(height: 24),

            // Stats Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.4,
              children: [
                _buildStatCard("2015", "Năm thành lập", 0),
                _buildStatCard("120+", "Sự kiện / năm", 1),
                _buildStatCard("07", "Giải thưởng", 2),
                _buildStatCard("12k+", "Khách hàng", 3),
              ],
            ),
            const SizedBox(height: 32),

            // Timeline
            _buildSectionTitle("Hành trình phát triển"),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  _buildTimelineItem("2015", "Mở cửa cơ sở đầu tiên",
                      "Khởi đầu với mong muốn tôn vinh ẩm thực Việt hiện đại."),
                  _buildTimelineItem("2018", "Ra mắt thực đơn degustation",
                      "Kết hợp nguyên liệu bản địa với kỹ thuật fine-dining."),
                  _buildTimelineItem("2021", "Không gian rượu vang & lounge",
                      "Tạo trải nghiệm trọn vẹn từ món ăn đến thức uống."),
                  _buildTimelineItem("2024", "Chuỗi sự kiện chef table",
                      "Giới thiệu bộ sưu tập món mới theo mùa.", isLast: true),
                ],
              ),
            ).animate().slideX(begin: 0.1, end: 0, duration: 500.ms).fadeIn(),
            
            const SizedBox(height: 32),

            // Values
            _buildSectionTitle("Giá trị cốt lõi"),
            const SizedBox(height: 16),
            _buildValueCard(Icons.diamond_outlined, "Sự Tinh Tế",
                "Từng chi tiết được chăm chút: từ nhiệt độ món ăn đến âm nhạc, ánh sáng."),
            const SizedBox(height: 12),
            _buildValueCard(Icons.agriculture_outlined, "Tính Bản Địa",
                "Ưu tiên nguyên liệu từ nông trại hữu cơ và làng nghề truyền thống."),
            const SizedBox(height: 12),
            _buildValueCard(Icons.person_outline, "Khách Hàng Là Trung Tâm",
                "Trải nghiệm được cá nhân hóa theo dịp đặc biệt của từng vị khách."),
            
            const SizedBox(height: 32),

            // Experience Packages
            _buildSectionTitle("Gói trải nghiệm"),
            const SizedBox(height: 16),
            _buildExperienceCard(
              "Private Dining",
              "Không gian riêng cho nhóm 8-20 khách.",
              "Bao gồm hoa trang trí, quầy rượu và quản gia riêng.",
              Colors.purple.shade50,
              Colors.purple.shade900,
            ),
            const SizedBox(height: 12),
            _buildExperienceCard(
              "Chef Table",
              "Thực đơn 8 món theo mùa.",
              "Tương tác trực tiếp với bếp trưởng. Phù hợp kỷ niệm, cầu hôn.",
              Colors.orange.shade50,
              Colors.orange.shade900,
            ),
            const SizedBox(height: 12),
            _buildExperienceCard(
              "Corporate Tasting",
              "Tiệc doanh nghiệp (max 120 khách).",
              "Có gói âm thanh, ánh sáng, MC song ngữ trọn gói.",
              Colors.blue.shade50,
              Colors.blue.shade900,
            ),
            const SizedBox(height: 32),

            // Quote Section
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: _darkWine,
                borderRadius: BorderRadius.circular(20),
                image: const DecorationImage(
                  image: NetworkImage("https://www.transparenttextures.com/patterns/cubes.png"), // Pattern nhẹ nếu có
                  opacity: 0.05,
                  fit: BoxFit.cover,
                )
              ),
              child: Column(
                children: [
                  const Icon(Icons.format_quote, color: Colors.white24, size: 40),
                  const SizedBox(height: 16),
                  const Text(
                    "Mỗi thực khách đến Viet Restaurant đều là một câu chuyện. Chúng tôi muốn bạn cảm nhận được hơi thở của Việt Nam, dù bạn là người bản xứ hay đến từ phương xa.",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      height: 1.6,
                      fontStyle: FontStyle.italic,
                      fontFamily: 'Serif', // Nếu có font Serif
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Container(height: 1, width: 40, color: Colors.white30),
                  const SizedBox(height: 16),
                  const Text(
                    "Founder Nguyễn Thảo Vy",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Cố vấn trải nghiệm khách hàng",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 800.ms),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(width: 4, height: 24, decoration: BoxDecoration(color: _wineRed, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 12),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _wineRed,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_wineRed, _lightWine],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _wineRed.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                child: const Icon(Icons.restaurant, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                "VỀ VIET RESTAURANT",
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 2,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            "Nâng tầm ẩm thực Việt bằng trải nghiệm tinh tế.",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              height: 1.2,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Chúng tôi kết hợp nguyên liệu bản địa với kỹ thuật hiện đại để tạo nên hành trình vị giác mới mẻ. Mỗi món ăn là một câu chuyện về văn hóa.",
            style: TextStyle(fontSize: 15, height: 1.5, color: Colors.white70),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DatBanScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _wineRed,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text("Đặt bàn ngay", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MenuScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white54),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Xem thực đơn"),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildStatCard(String value, String label, int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: _wineRed,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 100).ms).scale();
  }

  Widget _buildTimelineItem(String year, String title, String desc, {bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _wineRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _wineRed.withOpacity(0.2)),
                ),
                child: Text(
                  year,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _wineRed,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: Colors.grey.shade200,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueCard(IconData icon, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _bgWhite,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _wineRed, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildExperienceCard(String title, String desc, String detail, Color bgTint, Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: accentColor, width: 6)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}