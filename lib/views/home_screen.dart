import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // الإعدادات المحلية المبدئية
  double _budgetLimitSYP = 1000000.0; // حد الميزانية
  double _exchangeRate = 15000.0;    // سعر صرف 1 دولار بالليرة

  // متحكمات النصوص لنموذج إضافة مصروف
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String _selectedCurrency = 'SYP';

  // متحكمات الإعدادات
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _exchangeController = TextEditingController();

  // المرجع لمجموعة المصاريف في Firebase
  final CollectionReference _expensesCollection =
      FirebaseFirestore.instance.collection('expenses');

  // إضافة مصروف جديد إلى Firebase
  Future<void> _addTransaction() async {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    if (title.isEmpty || amount <= 0) return;

    await _expensesCollection.add({
      'title': title,
      'amount': amount,
      'currency': _selectedCurrency,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _titleController.clear();
    _amountController.clear();
    if (mounted) Navigator.of(context).pop();
  }

  // حذف مصروف من Firebase
  Future<void> _deleteTransaction(String id) async {
    await _expensesCollection.doc(id).delete();
  }

  // حوار إضافة مصروف
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
                        setModalState(() => _selectedCurrency = val);
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

  // حوار تعديل سعر الصرف وحد الميزانية
  void _showSettingsDialog() {
    _budgetController.text = _budgetLimitSYP.toStringAsFixed(0);
    _exchangeController.text = _exchangeRate.toStringAsFixed(0);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إعدادات الميزانية وسعر الصرف', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'حد الميزانية الإجمالي (ل.س)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _exchangeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'سعر صرف 1 دولار بالليرة (SYP)',
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
                _budgetLimitSYP = double.tryParse(_budgetController.text) ?? _budgetLimitSYP;
                _exchangeRate = double.tryParse(_exchangeController.text) ?? _exchangeRate;
              });
              Navigator.of(ctx).pop();
            },
            child: const Text('حفظ الإعدادات'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _budgetController.dispose();
    _exchangeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة المصاريف اليومية'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'تعديل سعر الصرف والميزانية',
              onPressed: _showSettingsDialog,
            ),
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _expensesCollection.orderBy('timestamp', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data?.docs ?? [];
            double totalSYP = 0.0;
            double totalUSD = 0.0;

            for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              final amount = (data['amount'] as num).toDouble();
              if (data['currency'] == 'SYP') {
                totalSYP += amount;
              } else if (data['currency'] == 'USD') {
                totalUSD += amount;
              }
            }

            // تحويل الكل إلى قيمة مكافئة بالليرة لحساب شريط التقدم
            double totalInSYP = totalSYP + (totalUSD * _exchangeRate);
            double progressRatio = _budgetLimitSYP > 0 ? (totalInSYP / _budgetLimitSYP) : 0.0;
            if (progressRatio > 1.0) progressRatio = 1.0;

            return Column(
              children: [
                // كارد ملخص الحساب وشريط التقدم
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
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('إجمالي (USD):', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            Text('\$${totalUSD.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('سعر الصرف: 1\$ = ${_exchangeRate.toStringAsFixed(0)} ل.س', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            Text('حد الميزانية: ${_budgetLimitSYP.toStringAsFixed(0)} ل.س', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('نسبة استهلاك الميزانية:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            Text('${(progressRatio * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
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
                // سجل المصاريف المخزن في Firebase
                Expanded(
                  child: docs.isEmpty
                      ? const Center(child: Text('لا توجد مصاريف مسجلة حتى الآن.'))
                      : ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (ctx, index) {
                            final doc = docs[index];
                            final tx = doc.data() as Map<String, dynamic>;
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
                                title: Text(tx['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${tx['amount']} ${tx['currency']}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                      onPressed: () => _deleteTransaction(doc.id),
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
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddTransactionDialog,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}