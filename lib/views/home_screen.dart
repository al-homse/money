import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense_item.dart';
import 'widgets/add_expense_modal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // مرجع مجموعة المصاريف في Firestore
  final CollectionReference _expensesRef =
      FirebaseFirestore.instance.collection('expenses');

  // إضافة غرض جديد إلى Firestore
  Future<void> _addExpense(String name, double price, String category) async {
    final newItem = ExpenseItem(
      id: '',
      name: name,
      price: price,
      category: category,
      date: DateTime.now(),
    );
    await _expensesRef.add(newItem.toMap());
  }

  // حذف غرض من Firestore
  Future<void> _deleteExpense(String id) async {
    await _expensesRef.doc(id).delete();
  }

  void _openAddExpenseModal(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      builder: (_) => AddExpenseModal(onAddExpense: _addExpense),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سجل المشتريات'),
          centerTitle: true,
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _expensesRef.orderBy('date', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('حدث خطأ في جلب البيانات'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data?.docs ?? [];
            final allExpenses =
                docs.map((doc) => ExpenseItem.fromFirestore(doc)).toList();

            // تصفية مشتريات اليوم فقط
            final todayExpenses = allExpenses.where((item) {
              return item.date.year == now.year &&
                  item.date.month == now.month &&
                  item.date.day == now.day;
            }).toList();

            // حساب المجموع لليوم
            final todayTotal = todayExpenses.fold(
                0.0, (sum, item) => sum + item.price);

            return Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'إجمالي مشتريات اليوم',
                        style: TextStyle(fontSize: 16, color: Colors.teal),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${todayTotal.toStringAsFixed(2)} \$',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        'قائمة اليوم',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: todayExpenses.isEmpty
                      ? const Center(
                          child: Text(
                            'لم تسجل أي مشتريات اليوم بعد.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: todayExpenses.length,
                          itemBuilder: (ctx, index) {
                            final item = todayExpenses[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.teal.shade100,
                                  child: const Icon(Icons.shopping_bag,
                                      color: Colors.teal),
                                ),
                                title: Text(item.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle: Text(item.category),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${item.price.toStringAsFixed(2)} \$',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.teal,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.redAccent),
                                      onPressed: () => _deleteExpense(item.id),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openAddExpenseModal(context),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('إضافة غرض'),
        ),
      ),
    );
  }
}