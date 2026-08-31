import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // قائمة المصاريف (تأخذ القيمة والمقدار مع العملة المحدد)
  final List<Map<String, dynamic>> _transactions = [];

  // حد الميزانية الافتراضي لشريط التقدم
  final double _budgetLimitSYP = 100000.0; 

  // متحكمات النصوص
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String _selectedCurrency = 'SYP'; // العملة الافتراضية

  void _addTransaction() {
    final title = _titleController.text;
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    if (title.isEmpty || amount <= 0) return;

    setState(() {
      _transactions.add({
        'id': DateTime.now().toString(),
        'title': title,
        'amount': amount,
        'currency': _selectedCurrency,
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
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
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
                  labelText: 'الوصف / العنوان',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'المبلغ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedCurrency,
                    items: const [
                      DropdownMenuItem(value: 'SYP', child: Text('ل.س')),
                      DropdownMenuItem(value: 'USD', child: Text('\$ USD')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          _selectedCurrency = val;
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _addTransaction,
                child: const Text('حفظ المصروف'),
              ),
            ],
          ),
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
    // حساب المجموع لكل عملة على حدة
    double totalSYP = 0.0;
    double totalUSD = 0.0;

    for (var tx in _transactions) {
      if (tx['currency'] == 'SYP') {
        totalSYP += tx['amount'];
      } else if (tx['currency'] == 'USD') {
        totalUSD += tx['amount'];
      }
    }

    // نسبة استهلاك الميزانية لشريط التقدم (بناءً على الليرة كمثال)
    double progressRatio = totalSYP / _budgetLimitSYP;
    if (progressRatio > 1.0) progressRatio = 1.0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة المصاريف'),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // كارد إجمالي المصاريف والعملتين
            Card(
              margin: const EdgeInsets.all(16),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('إجمالي (ل.س):', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        Text('${totalSYP.toStringAsFixed(0)} ل.س', style: const TextStyle(fontSize: 16, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('إجمالي (USD):', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        Text('\$${totalUSD.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 24),
                    // شريط التقدم (Progress Bar)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('نسبة استهلاك الميزانية (SYP):', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        Text('${(progressRatio * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progressRatio,
                      backgroundColor: Colors.grey[200],
                      color: progressRatio > 0.85 ? Colors.red : Colors.blue,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ],
                ),
              ),
            ),
            // قائمة المصاريف
            Expanded(
              child: _transactions.isEmpty
                  ? const Center(
                      child: Text('لا توجد مصاريف مسجلة حتى الآن.'),
                    )
                  : ListView.builder(
                      itemCount: _transactions.length,
                      itemBuilder: (ctx, index) {
                        final tx = _transactions[index];
                        final isSyp = tx['currency'] == 'SYP';
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isSyp ? Colors.blue[100] : Colors.green[100],
                              child: Text(
                                isSyp ? 'ل.س' : '\$',
                                style: TextStyle(color: isSyp ? Colors.blue[900] : Colors.green[900], fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(tx['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${(tx['date'] as DateTime).day}/${(tx['date'] as DateTime).month}/${(tx['date'] as DateTime).year}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${tx['amount']} ${tx['currency']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _transactions.removeAt(index);
                                    });
                                  },
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
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddTransactionDialog,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}