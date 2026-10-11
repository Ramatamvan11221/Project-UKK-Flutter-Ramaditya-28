class BookModel {
  final String id;
  final String title;
  final String author;
  final String publisher;
  final String category;
  final int totalStock;
  final int availableStock;
  final String rackLocation;

  BookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.publisher,
    required this.category,
    required this.totalStock,
    required this.availableStock,
    required this.rackLocation,
  });

  factory BookModel.fromMap(Map<String, dynamic> map, String id) {
    return BookModel(
      id: id,
      title: map['title'] ?? '',
      author: map['author'] ?? '',
      publisher: map['publisher'] ?? '',
      category: map['category'] ?? '',
      totalStock: map['totalStock'] ?? 0,
      availableStock: map['availableStock'] ?? 0,
      rackLocation: map['rackLocation'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'publisher': publisher,
      'category': category,
      'totalStock': totalStock,
      'availableStock': availableStock,
      'rackLocation': rackLocation,
    };
  }
}