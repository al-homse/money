import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/expense_item.dart';
import 'widgets/add_expense_modal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CollectionReference _expensesRef =
      FirebaseFirestore.instance.collection('expenses');

  DateTime _selectedDate = DateTime.now();
  double _exchangeRate = 15000; // سعر الصرف الافتراضي (1 دولار = 15000 ل.س)
  double _monthlyLimitSYP = 9000000; // السقف الشهري الافتراضي بالليرة السورية

  Future<void> _addExpense(String name, double price, String category) async {
    final newItem = ExpenseItem(
      id: '',
      name: name,
      price: price,
      category: category,
      date: _selectedDate,
    );
    await _expensesRef.add(newItem.toMap());
  }

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

  void _showSettingsDialog() {
    final rateController =
        TextEditingController(text: _exchangeRate.toStringAsFixed(0));
    final limitController =
        TextEditingController(text: _monthlyLimitSYP.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إعدادات العملة والسقف'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: rateController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'سعر صرف الدولار (ل.س)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: limitController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'السقف الشهري (ل.س)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _exchangeRate =
                    double.tryParse(rateController.text) ?? _exchangeRate;
                _monthlyLimitSYP =
                    double.tryParse(limitController.text) ?? _monthlyLimitSYP;
              });
              Navigator.of(ctx).pop();
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isToday = _selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سجل المشتريات'),
          centerTitle: true,
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _showSettingsDialog,
              tooltip: 'إعدادات الصرف والسقف',
            ),
          ],
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

            // مشتريات اليوم المحدد
            final selectedDayExpenses = allExpenses.where((item) {
              return item.date.year == _selectedDate.year &&
                  item.date.month == _selectedDate.month &&
                  item.date.day == _selectedDate.day;
            }).toList();

            // مشتريات الشهر الحالي لحساب السقف الشهري
            final currentMonthExpenses = allExpenses.where((item) {
              return item.date.year == _selectedDate.year &&
                  item.date.month == _selectedDate.month;
            }).toList();

            final selectedDayTotalUSD = selectedDayExpenses.fold(
                0.0, (sum, item) => sum + item.price);
            final selectedDayTotalSYP = selectedDayTotalUSD * _exchangeRate;

            final monthlyTotalUSD = currentMonthExpenses.fold(
                0.0, (sum, item) => sum + item.price);
            final monthlyTotalSYP = monthlyTotalUSD * _exchangeRate;

            // نسبة الاستهلاك من السقف الشهري
            final progress = (_monthlyLimitSYP > 0)
                ? (monthlyTotalSYP / _monthlyLimitSYP).clamp(0.0, 1.0)
                : 0.0;

            Color progressColor = Colors.green;
            if (progress > 0.85) {
              progressColor = Colors.red;
            } else if (progress > 0.65) {
              progressColor = Colors.orange;
            }

            return Column(
              children: [
                // شريط تحديد التاريخ
                Container(
                  color: Colors.teal.shade100,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.teal),
                          const SizedBox(width: 8),
                          Text(
                            isToday
                                ? 'اليوم (${DateFormat('yyyy-MM-dd').format(_selectedDate)})'
                                : DateFormat('yyyy-MM-dd').format(_selectedDate),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                          }
                        },
                        icon: const Icon(Icons.edit_calendar, size: 18),
                        label: const Text('تغيير اليوم'),
                      )
                    ],
                  ),
                ),

                // بطاقة الإجمالي والميزانية
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'إجمالي المشتريات لـ ${DateFormat('yyyy/MM/dd').format(_selectedDate)}',
                        style: const TextStyle(fontSize: 15, color: Colors.teal),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${selectedDayTotalUSD.toStringAsFixed(2)} \$  |  ${NumberFormat('#,###').format(selectedDayTotalSYP)} ل.س',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('استهلاك السقف الشهري:',
                              style: TextStyle(fontSize: 13)),
                          Text(
                            '${NumberFormat('#,###').format(monthlyTotalSYP)} / ${NumberFormat('#,###').format(_monthlyLimitSYP)} ل.س',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: progressColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          backgroundColor: Colors.grey.shade300,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(progressColor),
                        ),
                      ),
                    ],
                  ),
                ),

                // القائمة
                Expanded(
                  child: selectedDayExpenses.isEmpty
                      ? const Center(
                          child: Text(
                            'لا توجد مشتريات مسجلة في هذا التاريخ.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: selectedDayExpenses.length,
                          itemBuilder: (ctx, index) {
                            final item = selectedDayExpenses[index];
                            final itemSYP = item.price * _exchangeRate;
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
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${item.price.toStringAsFixed(2)} \$',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Colors.teal,
                                          ),
                                        ),
                                        Text(
                                          '${NumberFormat('#,###').format(itemSYP)} ل.س',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 8),
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