import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // المراجع في Firebase
  final CollectionReference _expensesCollection =
      FirebaseFirestore.instance.collection('expenses');
  final DocumentReference _settingsDoc =
      FirebaseFirestore.instance.collection('app_settings').doc('config');

  // متحكمات النصوص لنموذج إضافة مصروف
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String _selectedCurrency = 'SYP';

  // متحكمات الإعدادات
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _exchangeController = TextEditingController();

  // إضافة مصروف جديد إلى Firebase مع حساب التصريف التلقائي
  Future<void> _addTransaction(double exchangeRate) async {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    if (title.isEmpty || amount <= 0) return;

    double amountInSYP = 0.0;
    double amountInUSD = 0.0;

    // إجراء التصريف التلقائي بناءً على العملة المختارة وسعر الصرف الحالي
    if (_selectedCurrency == 'SYP') {
      amountInSYP = amount;
      amountInUSD = exchangeRate > 0 ? (amount / exchangeRate) : 0.0;
    } else {
      amountInUSD = amount;
      amountInSYP = amount * exchangeRate;
    }

    await _expensesCollection.add({
      'title': title,
      'originalAmount': amount,
      'currency': _selectedCurrency,
      'amountInSYP': amountInSYP,
      'amountInUSD': amountInUSD,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _titleController.clear();
    _amountController.clear();
    if (mounted) Navigator.of(context).pop();
  }

  // حذف مصروف
  Future<void> _deleteTransaction(String id) async {
    await _expensesCollection.doc(id).delete();
  }

  // حفظ سعر الصرف والميزانية في Firebase
  Future<void> _saveSettingsToFirebase(double budget, double rate) async {
    await _settingsDoc.set({
      'budgetLimitSYP': budget,
      'exchangeRate': rate,
    }, SetOptions(merge: true));
  }

  // حوار إضافة مصروف
  void _showAddTransactionDialog(double exchangeRate) {
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
                onPressed: () => _addTransaction(exchangeRate),
                child: const Text('حفظ المصروف وتصريفه'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // حوار تعديل سعر الصرف وحد الميزانية
  void _showSettingsDialog(double currentBudget, double currentRate) {
    _budgetController.text = currentBudget.toStringAsFixed(0);
    _exchangeController.text = currentRate.toStringAsFixed(0);

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
            onPressed: () async {
              double newBudget = double.tryParse(_budgetController.text) ?? currentBudget;
              double newRate = double.tryParse(_exchangeController.text) ?? currentRate;
              await _saveSettingsToFirebase(newBudget, newRate);
              if (mounted) Navigator.of(ctx).pop();
            },
            child: const Text('حفظ التعديلات'),
          ),
        ],
      ),
    );
  }

  // شاشة السجل التاريخي للمصاريف
  void _openHistoryScreen(List<QueryDocumentSnapshot> docs) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('سجل المصاريف الكامل'),
            ),
            body: docs.isEmpty
                ? const Center(child: Text('لا يوجد سجل مصاريف بعد.'))
                : ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final tx = docs[index].data() as Map<String, dynamic>;
                      final isSyp = tx['currency'] == 'SYP';
                      final double origAmount = (tx['originalAmount'] ?? tx['amount'] ?? 0.0).toDouble();
                      final double sypValue = (tx['amountInSYP'] ?? (isSyp ? origAmount : 0.0)).toDouble();
                      final double usdValue = (tx['amountInUSD'] ?? (!isSyp ? origAmount : 0.0)).toDouble();

                      final Timestamp? timestamp = tx['timestamp'] as Timestamp?;
                      final String dateStr = timestamp != null
                          ? "${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year} - ${timestamp.toDate().hour}:${timestamp.toDate().minute}"
                          : "الآن";

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSyp ? Colors.blue[100] : Colors.green[100],
                          child: Text(
                            isSyp ? 'ل.س' : '\$',
                            style: TextStyle(color: isSyp ? Colors.blue[900] : Colors.green[900], fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(tx['title'] ?? ''),
                        subtitle: Text('$dateStr\nمعادل: ${isSyp ? "\$${usdValue.toStringAsFixed(2)}" : "${sypValue.toStringAsFixed(0)} ل.س"}', style: const TextStyle(fontSize: 12)),
                        trailing: Text(
                          '$origAmount ${tx['currency']}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      );
                    },
                  ),
          ),
        ),
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
      child: StreamBuilder<DocumentSnapshot>(
        stream: _settingsDoc.snapshots(),
        builder: (context, settingsSnapshot) {
          double budgetLimitSYP = 1000000.0;
          double exchangeRate = 15000.0;

          if (settingsSnapshot.hasData && settingsSnapshot.data!.exists) {
            final settingsData = settingsSnapshot.data!.data() as Map<String, dynamic>;
            budgetLimitSYP = (settingsData['budgetLimitSYP'] ?? 1000000.0).toDouble();
            exchangeRate = (settingsData['exchangeRate'] ?? 15000.0).toDouble();
          }

          return Scaffold(
            appBar: AppBar(
              title: const Text('إدارة المصاريف اليومية'),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.history),
                  tooltip: 'سجل المصاريف',
                  onPressed: () async {
                    final snapshot = await _expensesCollection.orderBy('timestamp', descending: true).get();
                    if (context.mounted) _openHistoryScreen(snapshot.docs);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip: 'تعديل سعر الصرف والميزانية',
                  onPressed: () => _showSettingsDialog(budgetLimitSYP, exchangeRate),
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
                double totalSYPCombined = 0.0;
                double totalUSDCombined = 0.0;

                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final isSyp = data['currency'] == 'SYP';
                  final origAmount = (data['originalAmount'] ?? data['amount'] ?? 0.0).toDouble();

                  // حساب القيم المعروضة والتصريف التلقائي
                  final sypValue = (data['amountInSYP'] ?? (isSyp ? origAmount : origAmount * exchangeRate)).toDouble();
                  final usdValue = (data['amountInUSD'] ?? (!isSyp ? origAmount : (exchangeRate > 0 ? origAmount / exchangeRate : 0.0))).toDouble();

                  totalSYPCombined += sypValue;
                  totalUSDCombined += usdValue;
                }

                double progressRatio = budgetLimitSYP > 0 ? (totalSYPCombined / budgetLimitSYP) : 0.0;
                if (progressRatio > 1.0) progressRatio = 1.0;

                return Column(
                  children: [
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
                                const Text('إجمالي المصاريف (ل.س):', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                Text('${totalSYPCombined.toStringAsFixed(0)} ل.س', style: const TextStyle(fontSize: 16, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('المعادل الشامل (USD):', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                Text('\$${totalUSDCombined.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('سعر الصرف: 1\$ = ${exchangeRate.toStringAsFixed(0)} ل.س', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                Text('حد الميزانية: ${budgetLimitSYP.toStringAsFixed(0)} ل.س', style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
                    Expanded(
                      child: docs.isEmpty
                          ? const Center(child: Text('لا توجد مصاريف مسجلة حتى الآن.'))
                          : ListView.builder(
                              itemCount: docs.length,
                              itemBuilder: (ctx, index) {
                                final doc = docs[index];
                                final tx = doc.data() as Map<String, dynamic>;
                                final isSyp = tx['currency'] == 'SYP';
                                final origAmount = (tx['originalAmount'] ?? tx['amount'] ?? 0.0).toDouble();

                                final sypValue = (tx['amountInSYP'] ?? (isSyp ? origAmount : origAmount * exchangeRate)).toDouble();
                                final usdValue = (tx['amountInUSD'] ?? (!isSyp ? origAmount : (exchangeRate > 0 ? origAmount / exchangeRate : 0.0))).toDouble();

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
                                    subtitle: Text(
                                      isSyp
                                          ? 'المعادل: \$${usdValue.toStringAsFixed(2)}'
                                          : 'المعادل: ${sypValue.toStringAsFixed(0)} ل.س',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '$origAmount ${tx['currency']}',
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
              onPressed: () => _showAddTransactionDialog(exchangeRate),
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }
}