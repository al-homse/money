import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:money/auth_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // الوصول لمسار المستخدم الخاص
  CollectionReference get _expensesCollection => FirebaseFirestore.instance
      .collection('users')
      .doc(_currentUser?.uid ?? 'unknown')
      .collection('expenses');

  DocumentReference get _settingsDoc => FirebaseFirestore.instance
      .collection('users')
      .doc(_currentUser?.uid ?? 'unknown')
      .collection('settings')
      .doc('config');

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String _selectedCurrency = 'SYP';

  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _exchangeController = TextEditingController();

  Color _getProgressBarColor(double ratio) {
    if (ratio < 0.25) {
      return Colors.green;
    } else if (ratio < 0.50) {
      return Colors.blue;
    } else if (ratio < 0.75) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Future<void> _addTransaction(double exchangeRate) async {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    if (title.isEmpty || amount <= 0) return;

    double amountInSYP = 0.0;
    double amountInUSD = 0.0;

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

  Future<void> _deleteTransaction(String id) async {
    await _expensesCollection.doc(id).delete();
  }

  Future<void> _saveSettingsToFirebase(double budget, double rate) async {
    await _settingsDoc.set({
      'budgetLimitSYP': budget,
      'exchangeRate': rate,
    }, SetOptions(merge: true));
  }

  void _showAddTransactionDialog(double exchangeRate) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
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
              const SizedBox(height: 16),
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
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _addTransaction(exchangeRate),
                child: const Text('حفظ المصروف وتصريفه', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

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

  void _openHistoryScreen(List<QueryDocumentSnapshot> docs) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => HistoryScreen(docs: docs),
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
    final bool isGuest = _currentUser?.isAnonymous ?? false;

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
              backgroundColor: const Color(0xFF1E293B),
              foregroundColor: Colors.white,
              elevation: 2,
              title: const Text('إدارة المصاريف اليومية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'تسجيل الخروج',
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                  },
                ),
              ],
            ),
            body: Stack(
              children: [
                // خلفية متدرجة فخمة كُليّة للتطبيق
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
                    ),
                  ),
                ),

                // ضبط العرض في المنتصف بعرض أقصى مناسب للكمبيوتر (Web Centered Layout)
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: StreamBuilder<QuerySnapshot>(
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

                          final sypValue = (data['amountInSYP'] ?? (isSyp ? origAmount : origAmount * exchangeRate)).toDouble();
                          final usdValue = (data['amountInUSD'] ?? (!isSyp ? origAmount : (exchangeRate > 0 ? origAmount / exchangeRate : 0.0))).toDouble();

                          totalSYPCombined += sypValue;
                          totalUSDCombined += usdValue;
                        }

                        double progressRatio = budgetLimitSYP > 0 ? (totalSYPCombined / budgetLimitSYP) : 0.0;
                        double overBudgetAmount = totalSYPCombined - budgetLimitSYP;
                        double overBudgetRatio = budgetLimitSYP > 0 ? (overBudgetAmount / budgetLimitSYP) : 0.0;

                        return Column(
                          children: [
                            if (isGuest)
                              Container(
                                color: Colors.amber[100],
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Row(
                                  children: [
                                    const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                        'تتصفح حالياً كـ زائر، البيانات قد تضيع عند مسح ذاكرة الجهاز.',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(builder: (ctx) => const AuthScreen()),
                                        );
                                      },
                                      child: const Text('حفظ الحساب', style: TextStyle(fontWeight: FontWeight.bold)),
                                    )
                                  ],
                                ),
                              ),
                            Card(
                              margin: const EdgeInsets.all(16),
                              elevation: 3,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.all(18),
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
                                      value: progressRatio > 1.0 ? 1.0 : progressRatio,
                                      backgroundColor: Colors.grey[200],
                                      color: _getProgressBarColor(progressRatio),
                                      minHeight: 10,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    if (overBudgetAmount > 0) ...[
                                      const SizedBox(height: 14),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'تجاوز الميزانية (+${overBudgetAmount.toStringAsFixed(0)} ل.س):',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red),
                                          ),
                                          Text(
                                            '+${(overBudgetRatio * 100).toStringAsFixed(1)}%',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      LinearProgressIndicator(
                                        value: overBudgetRatio > 1.0 ? 1.0 : overBudgetRatio,
                                        backgroundColor: Colors.red[50],
                                        color: Colors.red[900],
                                        minHeight: 8,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: docs.isEmpty
                                  ? const Center(child: Text('لا توجد مصاريف مسجلة حتى الآن.', style: TextStyle(color: Colors.grey)))
                                  : ListView.builder(
                                      padding: const EdgeInsets.only(bottom: 40),
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
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  ),
                ),

                // العلامة المائية الثابتة أسفل اليسار
                const Positioned(
                  left: 16,
                  bottom: 12,
                  child: IgnorePointer(
                    child: Text(
                      'Powered & Designed by AL-Homse',
                      style: TextStyle(
                        color: Colors.black45,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              onPressed: () => _showAddTransactionDialog(exchangeRate),
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }
}

class HistoryScreen extends StatefulWidget {
  final List<QueryDocumentSnapshot> docs;
  const HistoryScreen({super.key, required this.docs});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'الكل';

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final filteredDocs = widget.docs.where((doc) {
      final tx = doc.data() as Map<String, dynamic>;
      final Timestamp? timestamp = tx['timestamp'] as Timestamp?;
      if (timestamp == null) return _selectedFilter == 'الكل';

      final date = timestamp.toDate();
      final txDate = DateTime(date.year, date.month, date.day);

      if (_selectedFilter == 'اليوم') {
        return txDate.isAtSameMomentAs(today);
      } else if (_selectedFilter == 'الأمس') {
        return txDate.isAtSameMomentAs(yesterday);
      } else if (_selectedFilter == 'أقدم من الأمس') {
        return txDate.isBefore(yesterday);
      }
      return true;
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E293B),
          foregroundColor: Colors.white,
          title: const Text('سجل المصاريف الكامل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('تصفية حسب التاريخ:', style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    value: _selectedFilter,
                    items: const [
                      DropdownMenuItem(value: 'الكل', child: Text('جميع المصاريف')),
                      DropdownMenuItem(value: 'اليوم', child: Text('مصاريف اليوم')),
                      DropdownMenuItem(value: 'الأمس', child: Text('مصاريف الأمس')),
                      DropdownMenuItem(value: 'أقدم من الأمس', child: Text('أيام سابقة')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedFilter = val;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            Container(
              color: const Color(0xFFF1F5F9),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: filteredDocs.isEmpty
                    ? const Center(child: Text('لا توجد مصاريف لهذه الفترة.'))
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 40),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          final tx = filteredDocs[index].data() as Map<String, dynamic>;
                          final isSyp = tx['currency'] == 'SYP';
                          final double origAmount = (tx['originalAmount'] ?? tx['amount'] ?? 0.0).toDouble();
                          final double sypValue = (tx['amountInSYP'] ?? (isSyp ? origAmount : 0.0)).toDouble();
                          final double usdValue = (tx['amountInUSD'] ?? (!isSyp ? origAmount : 0.0)).toDouble();

                          final Timestamp? timestamp = tx['timestamp'] as Timestamp?;
                          final String dateStr = timestamp != null
                              ? "${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year} - ${timestamp.toDate().hour}:${timestamp.toDate().minute}"
                              : "الآن";

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
                              title: Text(tx['title'] ?? ''),
                              subtitle: Text('$dateStr\nمعادل: ${isSyp ? "\$${usdValue.toStringAsFixed(2)}" : "${sypValue.toStringAsFixed(0)} ل.س"}', style: const TextStyle(fontSize: 12)),
                              trailing: Text(
                                '$origAmount ${tx['currency']}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
            const Positioned(
              left: 16,
              bottom: 12,
              child: IgnorePointer(
                child: Text(
                  'Powered & Designed by AL-Homse',
                  style: TextStyle(
                    color: Colors.black45,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}