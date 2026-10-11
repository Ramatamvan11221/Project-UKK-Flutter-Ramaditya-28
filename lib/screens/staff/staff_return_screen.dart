import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/loan_model.dart';
import '../../services/loan_service.dart';

class StaffReturnScreen extends StatefulWidget {
  const StaffReturnScreen({super.key});

  @override
  State<StaffReturnScreen> createState() => _StaffReturnScreenState();
}

class _StaffReturnScreenState extends State<StaffReturnScreen> {
  final _loanService = LoanService();
  final double _finePerDay = 1000.0;

  void _processReturn(LoanModel loan) async {
    final now = DateTime.now();
    final dueNoTime = DateTime(loan.dueDate.year, loan.dueDate.month, loan.dueDate.day);
    final nowNoTime = DateTime(now.year, now.month, now.day);

    int daysLate = 0;
    if (nowNoTime.isAfter(dueNoTime)) {
      daysLate = nowNoTime.difference(dueNoTime).inDays;
    }
    final calculatedFine = daysLate * _finePerDay;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi Pengembalian'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Peminjam: ${loan.userName}'),
            Text('Buku: ${loan.bookTitle}'),
            const SizedBox(height: 8),
            Text('Keterlambatan: $daysLate hari'),
            Text(
              'Total Denda: Rp ${calculatedFine.toStringAsFixed(0)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: calculatedFine > 0 ? AppColors.error : AppColors.primary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await _loanService.returnBook(
                  loanId: loan.id,
                  bookId: loan.bookId,
                  dueDate: loan.dueDate,
                  finePerDay: _finePerDay,
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        calculatedFine > 0
                            ? 'Pengembalian diproses. Denda: Rp ${calculatedFine.toStringAsFixed(0)}'
                            : 'Buku berhasil dikembalikan tepat waktu!',
                      ),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal memproses: ${e.toString()}'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Proses Kembali'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengembalian Buku'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<LoanModel>>(
        stream: _loanService.getAllLoansStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Terjadi kesalahan: ${snapshot.error}'),
            );
          }

          final allLoans = snapshot.data ?? [];
          final activeLoans =
              allLoans.where((l) => l.status == 'borrowed').toList();

          if (activeLoans.isEmpty) {
            return const Center(
              child: Text(
                'Tidak ada buku yang sedang dipinjam.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: activeLoans.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final loan = activeLoans[index];
              final isOverdue = DateTime.now().isAfter(loan.dueDate);

              return Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isOverdue ? AppColors.error : Colors.grey.shade300,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loan.bookTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Peminjam: ${loan.userName}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Jatuh Tempo: ${dateFormat.format(loan.dueDate)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isOverdue ? AppColors.error : Colors.grey,
                        fontWeight:
                            isOverdue ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: () => _processReturn(loan),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.assignment_turned_in_outlined),
                        label: const Text('Proses Pengembalian'),
                      ),
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
}