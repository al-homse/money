import 'package:flutter/material.dart';
import '../models/expense_item.dart';
import 'widgets/add_expense_modal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<ExpenseItem> _expenses = [];

  double get _todayTotal {
    final now = DateTime.now();
    return _expenses
        .where((item) =>
            item.date.year == now.year &&
            item.date.month == now.month &&
            item.date.day == now.day)
        .fold(0.0, (sum, item) => sum + item.price);
  }

  void _addExpense(String name, double price, String category) {
    setState(() {
      _expenses.insert(
        0,
        ExpenseItem(
          id: DateTime.now().toString(),
          name: name,
          price: price,
          category: category,
          date: DateTime.now(),
        ),
      );
    });
  }

  void _deleteExpense(String id) {
    setState(() {
      _expenses.removeWhere((item) => item.id == id);
    });
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
    final todayExpenses = _expenses.where((item) {
      final now = DateTime.now();
      return item.date.year == now.year &&
          item.date.month == now.month &&
          item.date.day == now.day;
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سجل المشتريات'),
          centerTitle: true,
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
        body: Column(
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
                    '${_todayTotal.toStringAsFixed(2)} \$',
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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