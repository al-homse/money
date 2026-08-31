import 'package:flutter/material.dart';

class AddExpenseModal extends StatefulWidget {
  final Function(String name, double price, String category) onAddExpense;

  const AddExpenseModal({super.key, required this.onAddExpense});

  @override
  State<AddExpenseModal> createState() => _AddExpenseModalState();
}

class _AddExpenseModalState extends State<AddExpenseModal> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  String _selectedCategory = 'مواد غذائية';

  final List<String> _categories = [
    'مواد غذائية',
    'منظفات ومستلزمات',
    'خضار وفواكه',
    'فواتير ومصاريف',
    'أخرى'
  ];

  void _submitData() {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text) ?? 0.0;

    if (name.isEmpty || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال اسم الغرض وسعر صحيح')),
      );
      return;
    }

    widget.onAddExpense(name, price, _selectedCategory);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'تسجيل غرض جديد',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'اسم الغرض (مثلاً: كيلو موز)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'السعر',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.attach_money),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            items: _categories.map((cat) {
              return DropdownMenuItem(value: cat, child: Text(cat));
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedCategory = val);
            },
            decoration: const InputDecoration(
              labelText: 'التصنيف',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _submitData,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.check),
            label: const Text('إضافة للسجل'),
          ),
        ],
      ),
    );
  }
}