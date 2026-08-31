import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseItem {
  final String id;
  final String name;
  final double price;
  final String category;
  final DateTime date;

  ExpenseItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.date,
  });

  // تحويل البيانات إلى Map للحفظ في Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'category': category,
      'date': Timestamp.fromDate(date),
    };
  }

  // إنشاء العنصر من البيانات القادمة من Firestore
  factory ExpenseItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExpenseItem(
      id: doc.id,
      name: data['name'] ?? '',
      price: (data['price'] as num).toDouble(),
      category: data['category'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
    );
  }
}