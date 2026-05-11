import 'package:flutter/material.dart';

void main() {
  runApp(const InvoiceTrackerApp());
}

class Invoice {
  final String id;
  final String customerName;
  final double totalAmount;
  double amountPaid;
  final DateTime dueDate;

  Invoice({
    required this.id,
    required this.customerName,
    required this.totalAmount,
    this.amountPaid = 0.0,
    required this.dueDate,
  });

  double get balanceDue => totalAmount - amountPaid;
  bool get isPaid => balanceDue <= 0;
}

class Payment {
  final String id;
  final String invoiceId;
  final double amount;
  final DateTime date;

  Payment({
    required this.id,
    required this.invoiceId,
    required this.amount,
    required this.date,
  });
}

class InvoiceTrackerApp extends StatelessWidget {
  const InvoiceTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Invoice Payment Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const DashboardScreen(),
      },
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final List<Invoice> _invoices = [
    Invoice(id: 'INV-001', customerName: 'Acme Corp', totalAmount: 1500.0, amountPaid: 500.0, dueDate: DateTime.now().add(const Duration(days: 15))),
    Invoice(id: 'INV-002', customerName: 'Globex Inc', totalAmount: 2400.0, amountPaid: 2400.0, dueDate: DateTime.now().subtract(const Duration(days: 5))),
    Invoice(id: 'INV-003', customerName: 'Soylent Corp', totalAmount: 850.0, amountPaid: 0.0, dueDate: DateTime.now().add(const Duration(days: 3))),
  ];
  final List<Payment> _payments = [
    Payment(id: 'PAY-101', invoiceId: 'INV-001', amount: 500.0, date: DateTime.now().subtract(const Duration(days: 2))),
    Payment(id: 'PAY-102', invoiceId: 'INV-002', amount: 2400.0, date: DateTime.now().subtract(const Duration(days: 1))),
  ];

  void _addInvoice(Invoice invoice) {
    setState(() {
      _invoices.add(invoice);
    });
  }

  void _addPayment(Payment payment) {
    setState(() {
      _payments.add(payment);
      final invoice = _invoices.firstWhere((inv) => inv.id == payment.invoiceId);
      invoice.amountPaid += payment.amount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Tracker'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return Row(
              children: [
                Expanded(flex: 2, child: _buildInvoiceList()),
                const VerticalDivider(width: 1),
                Expanded(flex: 1, child: _buildPaymentHistory()),
              ],
            );
          } else {
            return _buildInvoiceList();
          }
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddInvoiceDialog(context),
        label: const Text('New Invoice'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildInvoiceList() {
    return ListView.builder(
      itemCount: _invoices.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final invoice = _invoices[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            title: Text('${invoice.id} - ${invoice.customerName}'),
            subtitle: Text('Total: \$${invoice.totalAmount.toStringAsFixed(2)} | Balance: \$${invoice.balanceDue.toStringAsFixed(2)}'),
            trailing: Chip(
              label: Text(invoice.isPaid ? 'Paid' : (invoice.amountPaid > 0 ? 'Partial' : 'Unpaid')),
              backgroundColor: invoice.isPaid ? Colors.green.shade100 : (invoice.amountPaid > 0 ? Colors.orange.shade100 : Colors.red.shade100),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Due: ${invoice.dueDate.toLocal().toString().split(' ')[0]}'),
                    if (!invoice.isPaid)
                      ElevatedButton(
                        onPressed: () => _showAddPaymentDialog(context, invoice),
                        child: const Text('Record Payment'),
                      ),
                  ],
                ),
              ),
              const Divider(),
              ..._payments.where((p) => p.invoiceId == invoice.id).map((p) => ListTile(
                dense: true,
                leading: const Icon(Icons.payment, size: 20),
                title: Text('Payment: \$${p.amount.toStringAsFixed(2)}'),
                subtitle: Text(p.date.toLocal().toString().split(' ')[0]),
              )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentHistory() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Recent Payments', style: Theme.of(context).textTheme.titleLarge),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _payments.length,
            itemBuilder: (context, index) {
              final payment = _payments.reversed.toList()[index];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.attach_money)),
                title: Text('\$${payment.amount.toStringAsFixed(2)}'),
                subtitle: Text('Invoice: ${payment.invoiceId}'),
                trailing: Text(payment.date.toLocal().toString().split(' ')[0]),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddInvoiceDialog(BuildContext context) {
    final idController = TextEditingController(text: 'INV-${(_invoices.length + 1).toString().padLeft(3, '0')}');
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Invoice'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: idController, decoration: const InputDecoration(labelText: 'Invoice ID')),
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Customer Name')),
                TextField(controller: amountController, decoration: const InputDecoration(labelText: 'Total Amount'), keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text) ?? 0.0;
                if (nameController.text.isNotEmpty && amount > 0) {
                  _addInvoice(Invoice(
                    id: idController.text,
                    customerName: nameController.text,
                    totalAmount: amount,
                    dueDate: selectedDate,
                  ));
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showAddPaymentDialog(BuildContext context, Invoice invoice) {
    final amountController = TextEditingController(text: invoice.balanceDue.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Record Payment for ${invoice.id}'),
          content: TextField(
            controller: amountController,
            decoration: const InputDecoration(labelText: 'Payment Amount'),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text) ?? 0.0;
                if (amount > 0 && amount <= invoice.balanceDue) {
                  _addPayment(Payment(
                    id: 'PAY-${DateTime.now().millisecondsSinceEpoch}',
                    invoiceId: invoice.id,
                    amount: amount,
                    date: DateTime.now(),
                  ));
                  Navigator.pop(context);
                }
              },
              child: const Text('Record'),
            ),
          ],
        );
      },
    );
  }
}
