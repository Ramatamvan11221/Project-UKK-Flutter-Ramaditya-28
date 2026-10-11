import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import 'staff_book_list_screen.dart';
import 'staff_loan_list_screen.dart';
import 'staff_report_screen.dart';
import 'staff_return_screen.dart';

class StaffDashboardScreen extends StatelessWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Petugas'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.logout();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Menu Utama Petugas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),
            _buildMenuItem(
              context,
              title: 'Kelola Data Buku',
              subtitle: 'Tambah, edit, dan hapus koleksi buku',
              icon: Icons.menu_book,
              page: const StaffBookListScreen(),
            ),
            const SizedBox(height: 12),
            _buildMenuItem(
              context,
              title: 'Persetujuan Peminjaman',
              subtitle: 'Setujui atau tolak pengajuan siswa',
              icon: Icons.approval,
              page: const StaffLoanListScreen(),
            ),
            const SizedBox(height: 12),
            _buildMenuItem(
              context,
              title: 'Pengembalian & Denda',
              subtitle: 'Proses buku kembali dan hitung denda',
              icon: Icons.assignment_returned,
              page: const StaffReturnScreen(),
            ),
            const SizedBox(height: 12),
            _buildMenuItem(
              context,
              title: 'Laporan & Rekapitulasi',
              subtitle: 'Buku terfavorit dan ekspor data CSV',
              icon: Icons.bar_chart_rounded,
              page: const StaffReportScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget page,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary, size: 32),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
      ),
    );
  }
}