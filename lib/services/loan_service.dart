import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import '../models/loan_model.dart';

class LoanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _loansRef => _firestore.collection('loans');

  Stream<List<LoanModel>> getMemberLoansStream(String userId) {
    return _loansRef
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return LoanModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
      list.sort((a, b) => b.borrowDate.compareTo(a.borrowDate));
      return list;
    });
  }

  Stream<List<LoanModel>> getAllLoansStream() {
    return _loansRef.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return LoanModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
      list.sort((a, b) => b.borrowDate.compareTo(a.borrowDate));
      return list;
    });
  }

  Future<void> createLoanRequest({
    required String userId,
    required String userName,
    required String bookId,
    required String bookTitle,
  }) async {
    final activeLoanCheck = await _loansRef
        .where('userId', isEqualTo: userId)
        .where('bookId', isEqualTo: bookId)
        .where('status', whereIn: ['pending', 'approved', 'borrowed'])
        .get();

    if (activeLoanCheck.docs.isNotEmpty) {
      throw Exception('Kamu masih punya pengajuan atau transaksi aktif untuk buku ini.');
    }

    final now = DateTime.now();
    final dueDate = now.add(const Duration(days: 7));

    final loanData = {
      'userId': userId,
      'userName': userName,
      'bookId': bookId,
      'bookTitle': bookTitle,
      'borrowDate': now.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'returnDate': null,
      'status': 'pending',
      'fineAmount': 0.0,
    };

    await _loansRef.add(loanData);
  }

  Future<void> approveLoan(String loanId, String bookId) async {
    final bookRef = _firestore.collection('books').doc(bookId);
    final loanRef = _loansRef.doc(loanId);

    await _firestore.runTransaction((transaction) async {
      final bookSnapshot = await transaction.get(bookRef);

      if (!bookSnapshot.exists) {
        throw Exception('Data buku tidak ditemukan.');
      }

      final currentAvailableStock =
          (bookSnapshot.data()?['availableStock'] ?? 0) as int;

      if (currentAvailableStock <= 0) {
        throw Exception('Stok buku sudah habis, tidak bisa menyetujui peminjaman.');
      }

      final now = DateTime.now();
      final dueDate = now.add(const Duration(days: 7));

      transaction.update(bookRef, {
        'availableStock': currentAvailableStock - 1,
      });

      transaction.update(loanRef, {
        'status': 'borrowed',
        'borrowDate': now.toIso8601String(),
        'dueDate': dueDate.toIso8601String(),
      });
    });
  }

  Future<void> rejectLoan(String loanId) async {
    await _loansRef.doc(loanId).update({
      'status': 'rejected',
    });
  }

  Future<double> returnBook({
    required String loanId,
    required String bookId,
    required DateTime dueDate,
    required double finePerDay,
  }) async {
    final bookRef = _firestore.collection('books').doc(bookId);
    final loanRef = _loansRef.doc(loanId);
    final now = DateTime.now();

    final dueNoTime = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final nowNoTime = DateTime(now.year, now.month, now.day);

    double totalFine = 0.0;
    if (nowNoTime.isAfter(dueNoTime)) {
      final daysLate = nowNoTime.difference(dueNoTime).inDays;
      totalFine = daysLate * finePerDay;
    }

    await _firestore.runTransaction((transaction) async {
      final bookSnapshot = await transaction.get(bookRef);

      if (bookSnapshot.exists) {
        final currentAvailableStock =
            (bookSnapshot.data()?['availableStock'] ?? 0) as int;
        transaction.update(bookRef, {
          'availableStock': currentAvailableStock + 1,
        });
      }

      transaction.update(loanRef, {
        'status': 'returned',
        'returnDate': now.toIso8601String(),
        'fineAmount': totalFine,
      });
    });

    return totalFine;
  }

  Future<String> exportReportToCSV(List<LoanModel> loans) async {
    List<List<dynamic>> csvData = [
      [
        'ID Transaksi',
        'Nama Peminjam',
        'Judul Buku',
        'Tgl Pinjam',
        'Jatuh Tempo',
        'Tgl Kembali',
        'Status',
        'Denda (Rp)'
      ],
    ];

    for (var loan in loans) {
      csvData.add([
        loan.id,
        loan.userName,
        loan.bookTitle,
        loan.borrowDate.toIso8601String().split('T')[0],
        loan.dueDate.toIso8601String().split('T')[0],
        loan.returnDate != null
            ? loan.returnDate!.toIso8601String().split('T')[0]
            : '-',
        loan.status,
        loan.fineAmount,
      ]);
    }

    String csvString = const ListToCsvConverter().convert(csvData);

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/laporan_peminjaman_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File(path);

    await file.writeAsString(csvString);
    return path;
  }
}