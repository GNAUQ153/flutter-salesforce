import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/fee.dart';
import '../services/fee_service.dart';

class FeePage extends StatefulWidget {
  const FeePage({super.key});

  @override
  State<FeePage> createState() => _FeePageState();
}

class _FeePageState extends State<FeePage> with SingleTickerProviderStateMixin {
  List<Fee> fees = [];
  Fee? selectedFee;
  bool agree = false;
  String paymentMethod = "ZaloPay";
  late TabController tabController;
  bool isLoading = true;
  String? errorMessage;

  final currencyFormatter = NumberFormat("#,###", "vi_VN");

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    tabController.addListener(() => setState(() {}));
    loadFees();
  }

  Future<void> loadFees() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await FeeService.getFees();
      setState(() {
        fees = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  Future<void> pay() async {
    if (selectedFee == null || !agree) return;

    try {
      await FeeService.payFee(selectedFee!.sfId);
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Thanh toán thành công")));

      setState(() {
        selectedFee = null;
        agree = false;
      });

      await loadFees();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Thanh toán thất bại: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingFees = fees
        .where((f) => f.status.trim() == "Pending")
        .toList();
    final paidFees = fees.where((f) => f.status.trim() == "Paid").toList();
    final displayFees = tabController.index == 0 ? pendingFees : paidFees;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FB),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          "Học phí",
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w700,
            fontSize: 28,
          ),
        ),
        actions: [
          IconButton(
            onPressed: loadFees,
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF111827)),
          ),
          _buildUserBadge(),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryHeader(pendingFees, paidFees),
          const SizedBox(height: 8),
          _buildTabs(),
          const SizedBox(height: 8),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                ? _buildErrorState()
                : RefreshIndicator(
                    onRefresh: loadFees,
                    child: _buildFeeList(displayFees),
                  ),
          ),
          if (tabController.index == 0) _buildBottomPaymentSection(),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(List<Fee> pendingFees, List<Fee> paidFees) {
    final pendingTotal = pendingFees.fold<int>(
      0,
      (sum, item) => sum + item.amount,
    );
    final paidTotal = paidFees.fold<int>(0, (sum, item) => sum + item.amount);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tổng quan học phí",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Quản lý thanh toán dễ dàng",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _summaryItem(
                  label: "Chờ thanh toán",
                  value: currencyFormatter.format(pendingTotal),
                  icon: Icons.schedule_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryItem(
                  label: "Đã thanh toán",
                  value: currencyFormatter.format(paidTotal),
                  icon: Icons.check_circle_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            "$value VNĐ",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserBadge() {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Color(0xFF94A3B8),
            child: Icon(Icons.person, size: 16, color: Colors.white),
          ),
          SizedBox(width: 8),
          Text(
            "Vũ Mạnh Đức",
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 2),
          Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF111827)),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TabBar(
        controller: tabController,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: const Color(0xFF2563EB),
        unselectedLabelColor: const Color(0xFF6B7280),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: "Chưa thanh toán"),
          Tab(text: "Đã thanh toán"),
        ],
      ),
    );
  }

  Widget _buildFeeList(List<Fee> displayFees) {
    if (displayFees.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Icon(Icons.receipt_long_rounded, size: 72, color: Color(0xFFCBD5E1)),
          SizedBox(height: 16),
          Center(
            child: Text(
              "Không có dữ liệu",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
          ),
          SizedBox(height: 8),
          Center(
            child: Text(
              "Kéo xuống để tải lại hoặc kiểm tra đăng nhập Salesforce.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: displayFees.length,
      itemBuilder: (context, index) {
        final fee = displayFees[index];
        final isSelected = selectedFee?.sfId == fee.sfId;
        final isPending = fee.status.trim() == "Pending";

        return GestureDetector(
          onTap: tabController.index == 0
              ? () => setState(() => selectedFee = fee)
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFE5E7EB),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 18,
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
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: isPending
                            ? const Color(0xFFFFF7ED)
                            : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isPending
                            ? Icons.account_balance_wallet_rounded
                            : Icons.verified_rounded,
                        color: isPending
                            ? const Color(0xFFEA580C)
                            : const Color(0xFF16A34A),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        fee.courseName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                    _statusBadge(fee.status),
                  ],
                ),
                const SizedBox(height: 16),
                _detailRow("Mã học phí", fee.id),
                const SizedBox(height: 8),
                _detailRow("Hạn thanh toán", fee.dueDate),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Tổng tiền",
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        "${currencyFormatter.format(fee.amount)} VNĐ",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      children: [
        Text(
          "$label: ",
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(String status) {
    final isPending = status.trim() == "Pending";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isPending ? const Color(0xFFFFF7ED) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isPending ? "Chờ thanh toán" : "Đã thanh toán",
        style: TextStyle(
          color: isPending ? const Color(0xFFEA580C) : const Color(0xFF16A34A),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 100),
        const Icon(Icons.cloud_off_rounded, size: 72, color: Color(0xFFCBD5E1)),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            "Không tải được dữ liệu",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            errorMessage ?? "Đã có lỗi xảy ra",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton.icon(
            onPressed: loadFees,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text("Thử lại"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomPaymentSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Row(
              children: [
                Checkbox(
                  value: agree,
                  activeColor: const Color(0xFF2563EB),
                  onChanged: (v) => setState(() => agree = v ?? false),
                ),
                const Expanded(
                  child: Text(
                    "Đồng ý với các điều khoản, điều kiện và chính sách đổi trả.",
                    style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Phương thức",
                    style: TextStyle(
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  DropdownButton<String>(
                    value: paymentMethod,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                        value: "ZaloPay",
                        child: Text("ZaloPay"),
                      ),
                    ],
                    onChanged: (v) => setState(() => paymentMethod = v!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Tổng cộng",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  Text(
                    "${currencyFormatter.format(selectedFee?.amount ?? 0)} VNĐ",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (selectedFee != null && agree) ? pay : null,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE5E7EB),
                  disabledForegroundColor: const Color(0xFF94A3B8),
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  "THANH TOÁN NGAY",
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
