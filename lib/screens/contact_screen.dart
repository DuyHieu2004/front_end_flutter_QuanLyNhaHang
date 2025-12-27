import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  _ContactScreenState createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _topicController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSubmitting = false;

  // --- COLOR PALETTE ---
  final Color _wineRed = const Color(0xFF800020);
  final Color _lightWine = const Color(0xFFA52A2A);
  final Color _bgWhite = const Color(0xFFFAFAFA);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _topicController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // --- LOGIC (GIỮ NGUYÊN) ---

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text("Đã gửi yêu cầu! Chúng tôi sẽ liên hệ sớm.")),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      _nameController.clear();
      _emailController.clear();
      _topicController.clear();
      _messageController.clear();
    }

    setState(() {
      _isSubmitting = false;
    });
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Không thể gọi số $phone")),
        );
      }
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Không thể mở email $email")),
        );
      }
    }
  }

  Future<void> _openMap() async {
    const address = "140 Lê Trọng Tấn, Q. Tân Phú, TP.HCM";
    // Fix: Correct Google Maps URL format
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Ignore error
    }
  }

  // --- UI BUILDER ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "LIÊN HỆ",
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
            // Header Section
            _buildHeaderSection(),
            const SizedBox(height: 24),

            // Contact Info Cards
            Row(
              children: [
                Expanded(
                  child: _buildContactCard(
                    "Hotline & Zalo",
                    "1900 1234",
                    "9:00 - 22:00 hằng ngày",
                    Icons.phone_in_talk,
                    () => _callPhone("19001234"),
                    0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildContactCard(
                    "Email Hỗ Trợ",
                    "hello@viet.vn",
                    "Phản hồi trong 24h",
                    Icons.mark_email_unread,
                    () => _sendEmail("hello@vietrestaurant.vn"),
                    1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Location & Hours
            _buildSectionTitle("Địa điểm & Giờ mở cửa"),
            const SizedBox(height: 16),
            _buildLocationSection(),
            const SizedBox(height: 32),

            // Contact Form
            _buildSectionTitle("Gửi tin nhắn"),
            const SizedBox(height: 16),
            _buildContactForm(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

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

  Widget _buildHeaderSection() {
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                child: const Icon(Icons.support_agent, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                "KẾT NỐI VỚI CHÚNG TÔI",
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 2,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            "Chúng tôi luôn lắng nghe mọi phản hồi từ bạn.",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.3,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Dù bạn muốn đặt tiệc riêng, hợp tác sự kiện hay góp ý dịch vụ, đội ngũ CSKH sẽ hỗ trợ ngay lập tức.",
            style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildContactCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
    int index,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _wineRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: _wineRed, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16, // Giảm font size một chút để không bị tràn
                fontWeight: FontWeight.w800,
                color: _wineRed,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 100).ms).scale();
  }

  Widget _buildLocationSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(Icons.store, "NHÀ HÀNG FLAGSHIP", "140 Lê Trọng Tấn, Tân Phú, TP.HCM"),
                      const SizedBox(height: 16),
                      _buildInfoRow(Icons.access_time_filled, "GIỜ HOẠT ĐỘNG", "10:30 - 22:30 (Nhận order cuối 21:45)"),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Map Placeholder Area
          Stack(
            children: [
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  image: const DecorationImage(
                    // Sử dụng ảnh map giả lập hoặc gradient
                    image: NetworkImage("https://mt0.google.com/vt/lyrs=m&x=0&y=0&z=15"), // Placeholder
                    fit: BoxFit.cover,
                    opacity: 0.6,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white, Colors.grey.shade100],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on, size: 40, color: _wineRed),
                      const SizedBox(height: 8),
                      Text(
                        "Xem trên Google Maps",
                        style: TextStyle(color: _wineRed, fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _openMap,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildInfoRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade400),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactForm() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Điền thông tin bên dưới, chúng tôi sẽ phản hồi trong 24h.",
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              _buildTextField(controller: _nameController, label: "Họ và tên", icon: Icons.person_outline, required: true),
              const SizedBox(height: 16),
              _buildTextField(controller: _emailController, label: "Email liên hệ", icon: Icons.email_outlined, required: true, isEmail: true),
              const SizedBox(height: 16),
              _buildTextField(controller: _topicController, label: "Chủ đề / Dịp đặc biệt", icon: Icons.celebration_outlined),
              const SizedBox(height: 16),
              _buildTextField(controller: _messageController, label: "Nội dung lời nhắn", icon: Icons.chat_bubble_outline, maxLines: 4, required: true),
              
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _wineRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                    shadowColor: _wineRed.withOpacity(0.4),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          "GỬI YÊU CẦU",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    bool required = false,
    bool isEmail = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: required ? "$label *" : label,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        prefixIcon: Icon(icon, color: _wineRed.withOpacity(0.7)),
        alignLabelWithHint: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _wineRed, width: 2),
        ),
        filled: true,
        fillColor: _bgWhite,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      validator: (value) {
        if (required && (value == null || value.isEmpty)) {
          return "Vui lòng nhập $label";
        }
        if (isEmail && value != null && value.isNotEmpty && !value.contains('@')) {
          return "Email không hợp lệ";
        }
        return null;
      },
    );
  }
}