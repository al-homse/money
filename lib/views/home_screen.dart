import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // قائمة تجريبية للمعاملات/المصاريف
  final List<Map<String, dynamic>> _transactions = [];

  // متحكمات النصوص لإضافة مصروف جديد
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  void _addTransaction() {
    final title = _titleController.text;
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    if (title.isEmpty || amount <= 0) {
      return;
    }

    setState(() {
      _transactions.add({
        'id': DateTime.now().toString(),
        'title': title,
        'amount': amount,
        'date': DateTime.now(),
      });
    });

    _titleController.clear();
    _amountController.clear();
    Navigator.of(context).pop();
  }

  void _showAddTransactionDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          top: 16,
          left: 16,
          right: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'إضافة مصروف جديد',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'العنوان / الوصف',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'المبلغ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addTransaction,
              child: const Text('حفظ المصروف'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // حساب إجمالي المصاريف
    final totalExpenses = _transactions.fold<double>(
      0.0,
      (sum, item) => sum + (item['amount'] as double),
    );

    return Directionality(
      textDirection: TextDirection.rtl, // الاتجاه الصحيح للغة العربية
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة المصاريف'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showAddTransactionDialog,
            ),
          ],
        ),
        body: Column(
          children: [
            // كارد ملخص الحساب
            Card(
              margin: const EdgeInsets.all(16),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'إجمالي المصاريف:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${totalExpenses.toStringAsFixed(2)} ل.س',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // قائمة المصاريف
            Expanded(
              child: _transactions.isEmpty
                  ? const Center(
                      child: Text(
                        'لا توجد مصاريف مسجلة حتى الآن.',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _transactions.length,
                      itemBuilder: (ctx, index) {
                        final tx = _transactions[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 25,
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: FittedBox(
                                  child: Text('${tx['amount']}'),
                                ),
                              ),
                            ),
                            title: Text(
                              tx['title'],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${(tx['date'] as DateTime).day}/${(tx['date'] as DateTime).month}/${(tx['date'] as DateTime).year}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _transactions.removeAt(index);
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddTransactionDialog,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}