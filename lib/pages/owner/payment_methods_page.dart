import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:my_app/config/api_config.dart';
import 'package:my_app/models/user_model.dart';

class PaymentMethodsPage extends StatefulWidget {
  final User user;
  const PaymentMethodsPage({super.key, required this.user});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<BankAccount> bankAccounts = [];
  List<PaymentTransaction> transactions = [];
  Map<String, dynamic> paymentSummary = {};
  bool isLoading = true;
  // final User user; // Get from session/provider

  // Malaysian banks list
  final List<Map<String, String>> malaysianBanks = [
    {'name': 'Maybank', 'code': 'MBB'},
    {'name': 'CIMB Bank', 'code': 'CIMB'},
    {'name': 'Public Bank', 'code': 'PBB'},
    {'name': 'RHB Bank', 'code': 'RHB'},
    {'name': 'Hong Leong Bank', 'code': 'HLB'},
    {'name': 'AmBank', 'code': 'AMB'},
    {'name': 'Bank Islam', 'code': 'BIMB'},
    {'name': 'Bank Rakyat', 'code': 'BRKB'},
    {'name': 'BSN', 'code': 'BSN'},
    {'name': 'OCBC Bank', 'code': 'OCBC'},
    {'name': 'HSBC Bank', 'code': 'HSBC'},
    {'name': 'Standard Chartered', 'code': 'SCB'},
    {'name': 'Affin Bank', 'code': 'ABB'},
    {'name': 'Alliance Bank', 'code': 'ABMB'},
    {'name': 'UOB Bank', 'code': 'UOB'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Helper function to safely convert to double
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  // Helper function to safely convert to int
  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  // Helper function to format currency
  String _formatCurrency(dynamic value) {
    return 'RM ${_toDouble(value).toStringAsFixed(2)}';
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadBankAccounts(),
      _loadTransactions(),
      _loadPaymentSummary(),
    ]);
  }

  Future<void> _loadBankAccounts() async {
    try {
      final url =
          '${ApiConfig.baseUrl}/owner_bank_accounts.php?user_id=${widget.user.id}';
      print('Making request to: $url'); // Add this for debugging

      final response = await http.get(Uri.parse(url));

      print(
          'Response status: ${response.statusCode}'); // Add this for debugging
      print('Response body: ${response.body}'); // Add this for debugging

      if (response.statusCode == 200) {
        final responseBody = response.body;
        if (responseBody.isNotEmpty) {
          final List<dynamic> data = json.decode(responseBody);
          setState(() {
            bankAccounts = data.map((e) => BankAccount.fromJson(e)).toList();
          });
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading bank accounts: $e');
    }
  }

  Future<void> _loadTransactions() async {
    try {
      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/payment_transactions.php?owner_id=${widget.user.id}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          transactions =
              data.map((e) => PaymentTransaction.fromJson(e)).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading transactions: $e');
    }
  }

  Future<void> _loadPaymentSummary() async {
    try {
      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/payment_summary.php?owner_id=${widget.user.id}'),
      );

      if (response.statusCode == 200) {
        setState(() {
          paymentSummary = json.decode(response.body);
        });
      }
    } catch (e) {
      print('Error loading payment summary: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF190152),
        title: const Text(
          'Payment & Banking',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Bank Accounts'),
            Tab(text: 'Transactions'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildBankAccountsTab(),
                _buildTransactionsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    final currentMonth = paymentSummary['current_month'] ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Income Summary Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [Color(0xFF190152), Color(0xFF2D0B6E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This Month\'s Income',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatCurrency(currentMonth['net_income']),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildIncomeDetail(
                        'Total Rental',
                        _formatCurrency(currentMonth['total_rental']),
                      ),
                      _buildIncomeDetail(
                        'Commission',
                        '- ${_formatCurrency(currentMonth['commission'])}',
                      ),
                      _buildIncomeDetail(
                        'Properties',
                        '${_toInt(currentMonth['active_properties'])}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Quick Stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Pending Transfers',
                  '${_toInt(paymentSummary['pending_transfers'])}',
                  Icons.schedule,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'This Month',
                  '${_toInt(currentMonth['transactions'])} payments',
                  Icons.calendar_today,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Recent Transactions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Transactions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  _tabController.animateTo(2);
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...transactions.take(3).map((transaction) =>
              _buildTransactionItem(transaction, compact: true)),
        ],
      ),
    );
  }

  Widget _buildBankAccountsTab() {
    return Column(
      children: [
        Expanded(
          child: bankAccounts.isEmpty
              ? _buildEmptyBankState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: bankAccounts.length,
                  itemBuilder: (context, index) {
                    final account = bankAccounts[index];
                    return _buildBankAccountCard(account);
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showAddBankAccountDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Bank Account'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF190152),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsTab() {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No transactions yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return _buildTransactionItem(transaction);
      },
    );
  }

  Widget _buildIncomeDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyBankState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No bank accounts added',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a bank account to receive rental payments',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankAccountCard(BankAccount account) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF190152).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.account_balance,
            color: Color(0xFF190152),
            size: 30,
          ),
        ),
        title: Text(
          account.bankName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(account.accountHolderName),
            Text('Account: ${account.accountNumber}'),
            Row(
              children: [
                if (account.isPrimary)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Primary',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                if (account.isVerified)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Verified',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'delete') {
              _deleteBankAccount(account);
            } else if (value == 'primary') {
              _setAsPrimary(account);
            }
          },
          itemBuilder: (context) => [
            if (!account.isPrimary)
              const PopupMenuItem(
                value: 'primary',
                child: Text('Set as primary'),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(PaymentTransaction transaction,
      {bool compact = false}) {
    final statusColor = transaction.paymentStatus == 'completed'
        ? Colors.green
        : transaction.paymentStatus == 'pending'
            ? Colors.orange
            : Colors.red;

    return Card(
      margin: EdgeInsets.only(bottom: compact ? 8 : 12),
      elevation: compact ? 1 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(compact ? 12 : 16),
        leading: Container(
          width: compact ? 40 : 50,
          height: compact ? 40 : 50,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            transaction.paymentStatus == 'completed'
                ? Icons.check_circle
                : transaction.paymentStatus == 'pending'
                    ? Icons.schedule
                    : Icons.error,
            color: statusColor,
            size: compact ? 24 : 30,
          ),
        ),
        title: Text(
          transaction.propertyName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: compact ? 14 : 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tenant: ${transaction.tenantName}',
              style: TextStyle(fontSize: compact ? 12 : 14),
            ),
            Text(
              _formatDate(transaction.paymentDate),
              style: TextStyle(
                fontSize: compact ? 12 : 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatCurrency(transaction.netAmount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: compact ? 14 : 16,
                color: statusColor,
              ),
            ),
            if (!compact) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  transaction.transferStatus.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        onTap: compact ? null : () => _showTransactionDetails(transaction),
      ),
    );
  }

  void _showAddBankAccountDialog() {
    final accountHolderController = TextEditingController();
    final accountNumberController = TextEditingController();
    String selectedBank = malaysianBanks.first['name']!;
    String accountType = 'savings';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Bank Account'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedBank,
                decoration: const InputDecoration(
                  labelText: 'Bank',
                  border: OutlineInputBorder(),
                ),
                items: malaysianBanks
                    .map((bank) => DropdownMenuItem(
                          value: bank['name'],
                          child: Text(bank['name']!),
                        ))
                    .toList(),
                onChanged: (value) {
                  selectedBank = value!;
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: accountHolderController,
                decoration: const InputDecoration(
                  labelText: 'Account Holder Name',
                  hintText: 'As per bank records',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: accountNumberController,
                decoration: const InputDecoration(
                  labelText: 'Account Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: accountType,
                decoration: const InputDecoration(
                  labelText: 'Account Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'savings', child: Text('Savings')),
                  DropdownMenuItem(value: 'current', child: Text('Current')),
                ],
                onChanged: (value) {
                  accountType = value!;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _addBankAccount(
                selectedBank,
                accountHolderController.text,
                accountNumberController.text,
                accountType,
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF190152),
            ),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showTransactionDetails(PaymentTransaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  'Transaction Details',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildDetailRow('Transaction ID', transaction.transactionRef),
                _buildDetailRow('Property', transaction.propertyName),
                _buildDetailRow('Tenant', transaction.tenantName),
                _buildDetailRow(
                    'Payment Date', _formatDate(transaction.paymentDate)),
                _buildDetailRow('Payment Method',
                    _getPaymentMethodName(transaction.paymentMethod)),
                const Divider(height: 32),
                _buildDetailRow(
                    'Rental Amount', _formatCurrency(transaction.amount)),
                _buildDetailRow('Platform Fee (5%)',
                    '- ${_formatCurrency(transaction.commissionAmount)}',
                    valueColor: Colors.red),
                _buildDetailRow(
                    'Net Amount', _formatCurrency(transaction.netAmount),
                    valueStyle: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
                const Divider(height: 32),
                _buildDetailRow(
                    'Payment Status', transaction.paymentStatus.toUpperCase(),
                    valueColor: _getStatusColor(transaction.paymentStatus)),
                _buildDetailRow(
                    'Transfer Status', transaction.transferStatus.toUpperCase(),
                    valueColor: _getStatusColor(transaction.transferStatus)),
                if (transaction.transferDate != null)
                  _buildDetailRow(
                      'Transfer Date', _formatDate(transaction.transferDate!)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {Color? valueColor, TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: valueStyle ??
                TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: valueColor,
                ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'fpx':
        return 'FPX (Online Banking)';
      case 'credit_card':
        return 'Credit Card';
      case 'debit_card':
        return 'Debit Card';
      case 'online_banking':
        return 'Online Banking';
      case 'wallet':
        return 'E-Wallet';
      default:
        return method;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'transferred':
        return Colors.green;
      case 'pending':
      case 'processing':
        return Colors.orange;
      case 'failed':
      case 'refunded':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _addBankAccount(String bankName, String accountHolder,
      String accountNumber, String accountType) async {
    try {
      print('Sending user_id: ${widget.user.id}'); // ADD THIS DEBUG LINE

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/owner_bank_accounts.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.user.id,
          'bank_name': bankName,
          'account_holder_name': accountHolder,
          'account_number': accountNumber,
          'account_type': accountType,
        }),
      );

      print('Response status: ${response.statusCode}'); // Debug
      print('Response body: ${response.body}'); // Debug

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bank account added successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadBankAccounts();
        } else {
          // Handle case where success is false
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to add bank account'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Server error: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error adding bank account: $e'); // Debug
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteBankAccount(BankAccount account) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bank Account'),
        content: Text(
            'Are you sure you want to delete ${account.bankName} account ending with ${account.accountNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await http.delete(
          Uri.parse(
              '${ApiConfig.baseUrl}/owner_bank_accounts.php?user_id=${widget.user.id}&account_id=${account.id}'),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bank account deleted'),
              backgroundColor: Colors.red,
            ),
          );
          _loadBankAccounts();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _setAsPrimary(BankAccount account) async {
    try {
      print(
          'Setting account ${account.id} as primary for user ${widget.user.id}'); // Debug

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/owner_bank_accounts.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.user.id,
          'account_id': account.id,
        }),
      );

      print('Response status: ${response.statusCode}'); // Debug
      print('Response body: ${response.body}'); // Debug

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Primary account updated'),
                backgroundColor: Colors.green,
              ),
            );
            _loadBankAccounts();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text(data['error'] ?? 'Failed to update primary account'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid server response'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Server error: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error setting primary: $e'); // Debug
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Data Models with Safe Type Conversion
class BankAccount {
  final int id;
  final String bankName;
  final String accountHolderName;
  final String accountNumber;
  final String accountType;
  final bool isPrimary;
  final bool isVerified;

  BankAccount({
    required this.id,
    required this.bankName,
    required this.accountHolderName,
    required this.accountNumber,
    required this.accountType,
    required this.isPrimary,
    required this.isVerified,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      bankName: json['bank_name']?.toString() ?? '',
      accountHolderName: json['account_holder_name']?.toString() ?? '',
      accountNumber: json['account_number']?.toString() ?? '',
      accountType: json['account_type']?.toString() ?? 'savings',
      isPrimary: json['is_primary'] == 1 || json['is_primary'] == true,
      isVerified: json['is_verified'] == 1 || json['is_verified'] == true,
    );
  }
}

class PaymentTransaction {
  final int id;
  final String transactionRef;
  final String propertyName;
  final String tenantName;
  final DateTime paymentDate;
  final double amount;
  final double commissionAmount;
  final double netAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String transferStatus;
  final DateTime? transferDate;

  PaymentTransaction({
    required this.id,
    required this.transactionRef,
    required this.propertyName,
    required this.tenantName,
    required this.paymentDate,
    required this.amount,
    required this.commissionAmount,
    required this.netAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.transferStatus,
    this.transferDate,
  });

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      transactionRef: json['transaction_ref']?.toString() ?? '',
      propertyName: json['property_name']?.toString() ?? '',
      tenantName: json['tenant_name']?.toString() ?? '',
      paymentDate: DateTime.tryParse(json['payment_date']?.toString() ?? '') ??
          DateTime.now(),
      amount: _parseDouble(json['amount']),
      commissionAmount: _parseDouble(json['commission_amount']),
      netAmount: _parseDouble(json['net_amount']),
      paymentMethod: json['payment_method']?.toString() ?? '',
      paymentStatus: json['payment_status']?.toString() ?? '',
      transferStatus: json['transfer_status']?.toString() ?? '',
      transferDate: json['transfer_date'] != null
          ? DateTime.tryParse(json['transfer_date'].toString())
          : null,
    );
  }
}
