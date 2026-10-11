import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book_model.dart';

class BookService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _booksRef => _firestore.collection('books');

  Stream<List<BookModel>> getBooksStream() {
    return _booksRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return BookModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<void> addBook(BookModel book) async {
    await _booksRef.add(book.toMap());
  }

  Future<void> updateBook(BookModel book) async {
    await _booksRef.doc(book.id).update(book.toMap());
  }

  Future<void> deleteBook(String bookId) async {
    final activeLoans = await _firestore
        .collection('loans')
        .where('bookId', isEqualTo: bookId)
        .where('status', whereIn: ['pending', 'approved', 'borrowed'])
        .get();

    if (activeLoans.docs.isNotEmpty) {
      throw Exception('Buku tidak bisa dihapus karena masih ada transaksi aktif.');
    }

    await _booksRef.doc(bookId).delete();
  }
}