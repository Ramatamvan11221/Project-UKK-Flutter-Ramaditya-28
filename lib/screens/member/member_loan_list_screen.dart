import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/loan_model.dart';
import '../../services/auth_service.dart';
import '../../services/loan_service.dart';

class MemberLoanListScreen extends StatelessWidget {
  const MemberLoanListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loanService = LoanService();
    final authService = AuthService();
    final user = authService.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Pengguna tidak terautentikasi.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Peminjaman Saya'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<LoanModel>>(
        stream: loanService.getMemberLoansStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Terjadi kesalahan: ${snapshot.error}'),
            );
          }

          final loans = snapshot.data ?? [];

          if (loans.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada riwayat atau pengajuan peminjaman.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final dateFormat = DateFormat('dd MMM yyyy');

          return ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: loans.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final loan = loans[index];
              return Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            loan.bookTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        _buildStatusBadge(loan.status),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'Tgl Pinjam: ${dateFormat.format(loan.borrowDate)}',
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.event_busy_outlined,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'Jatuh Tempo: ${dateFormat.format(loan.dueDate)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: loan.status == 'borrowed' &&
                                    DateTime.now().isAfter(loan.dueDate)
                                ? AppColors.error
                                : Colors.grey,
                            fontWeight: loan.status == 'borrowed' &&
                                    DateTime.now().isAfter(loan.dueDate)
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = 'Menunggu';
        break;
      case 'borrowed':
      case 'approved':
        color = AppColors.primaryLight;
        label = 'Dipinjam';
        break;
      case 'returned':
        color = Colors.blue;
        label = 'Dikembalikan';
        break;
      case 'rejected':
        color = AppColors.error;
        label = 'Ditolak';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}