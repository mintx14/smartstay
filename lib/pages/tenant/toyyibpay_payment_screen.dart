// toyyibpay_payment_screen.dart
// Updated with mock payment support

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:my_app/config/api_config.dart';
import 'package:my_app/models/booking_status.dart';

class ToyyibPayPaymentScreen extends StatefulWidget {
  final BookingStatus booking;
  final int currentUserId;

  const ToyyibPayPaymentScreen({
    super.key,
    required this.booking,
    required this.currentUserId,
  });

  @override
  State<ToyyibPayPaymentScreen> createState() => _ToyyibPayPaymentScreenState();
}

class _ToyyibPayPaymentScreenState extends State<ToyyibPayPaymentScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  bool _isProcessing = false;
  String _selectedPaymentMethod = 'fpx';
  bool _isMockMode = false; // Will be set based on API response

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Create bill (will use mock or real ToyyibPay based on server config)
      final response = await http.post(
        Uri.parse('http://192.168.0.34/smartstay/toyyibpay/create_bill.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'booking_id': widget.booking.id,
          'tenant_id': widget.currentUserId,
          'property_id': widget.booking.listingId,
          'amount': widget.booking.depositAmount,
          'bill_name': 'Deposit #${widget.booking.id}',
          'bill_description':
              'Security deposit for booking #${widget.booking.id}',
          'bill_email': widget.booking.tenantEmail ?? 'tenant@example.com',
          'bill_phone': widget.booking.tenantPhone ?? '0123456789',
          'payment_method': _selectedPaymentMethod == 'fpx' ? '1' : '2',
        }),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);

        if (result['success'] == true && result['payment_url'] != null) {
          // Check if this is mock mode
          _isMockMode = result['is_mock'] == true;

          // Launch payment page
          final Uri paymentUrl = Uri.parse(result['payment_url']);

          if (await canLaunchUrl(paymentUrl)) {
            await launchUrl(
              paymentUrl,
              mode: LaunchMode.externalApplication,
            );

            // Show appropriate dialog based on mode
            _showPaymentCheckDialog(result['bill_code'], _isMockMode);
          } else {
            throw Exception('Could not launch payment URL');
          }
        } else {
          throw Exception(result['message'] ?? 'Failed to create payment bill');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _showPaymentCheckDialog(String billCode, bool isMockMode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(isMockMode ? 'Mock Payment Mode' : 'Complete Your Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isMockMode ? Icons.code : Icons.launch,
              size: 64,
              color: isMockMode ? Colors.orange : const Color(0xFF667EEA),
            ),
            const SizedBox(height: 16),
            Text(
              isMockMode
                  ? 'This is a development payment system. Choose "Success" or "Failed" to simulate the payment result.'
                  : 'You have been redirected to ToyyibPay to complete your payment.',
              textAlign: TextAlign.center,
            ),
            if (!isMockMode) ...[
              const SizedBox(height: 16),
              const Text(
                'After completing the payment, click the button below to check your payment status.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            if (isMockMode) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Text(
                  '⚠️ Your ToyyibPay account is still under verification. This mock system allows you to test the payment flow.',
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _isProcessing = false;
              });
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _checkPaymentStatus(billCode);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isMockMode ? Colors.orange : const Color(0xFF667EEA),
            ),
            child: Text(
                isMockMode ? 'Check Mock Payment' : 'Check Payment Status'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkPaymentStatus(String billCode) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/toyyibpay/check_payment.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'bill_code': billCode,
          'booking_id': widget.booking.id,
        }),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);

        if (result['success'] == true && result['payment_status'] == 'paid') {
          // Payment successful
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentSuccessScreen(
                  booking: widget.booking,
                  transactionRef: result['transaction_ref'],
                  isMockMode: result['is_mock'] == true,
                ),
              ),
            );
          }
        } else if (result['payment_status'] == 'pending') {
          // Payment still pending
          setState(() {
            _isProcessing = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('Payment is still pending. Please check again later.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } else {
          // Payment failed
          throw Exception('Payment was not successful');
        }
      } else {
        throw Exception('Failed to check payment status');
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Secure Payment',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: child,
            );
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Development notice
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    border: Border.all(color: Colors.orange.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Development Mode',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                            ),
                            Text(
                              'ToyyibPay account is under verification. Using mock payment system.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildBookingSummary(),
                const SizedBox(height: 24),
                _buildPaymentMethods(),
                const SizedBox(height: 32),
                _buildPayButton(),
                const SizedBox(height: 16),
                _buildSecurityBadges(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF667EEA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: Color(0xFF667EEA),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Deposit Payment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSummaryRow('Property', widget.booking.propertyTitle),
          _buildSummaryRow(
              'Check-in',
              DateFormat('d MMM yyyy')
                  .format(DateTime.parse(widget.booking.checkInDate))),
          _buildSummaryRow(
              'Duration', '${widget.booking.durationMonths} months'),
          const Divider(height: 24),
          _buildSummaryRow('Monthly Rent',
              'RM ${widget.booking.monthlyRent.toStringAsFixed(2)}'),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Security Deposit',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF667EEA),
                ),
              ),
              Text(
                'RM ${widget.booking.depositAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF667EEA),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildPaymentOption(
                'fpx',
                Icons.account_balance,
                'FPX',
                'Online Banking',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPaymentOption(
                'card',
                Icons.credit_card,
                'Card',
                'Debit/Credit',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentOption(
    String value,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final isSelected = _selectedPaymentMethod == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF667EEA).withOpacity(0.1)
              : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF667EEA) : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF667EEA) : Colors.grey,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFF667EEA) : Colors.black87,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF667EEA),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: _isProcessing ? 0 : 3,
        ),
        child: _isProcessing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, size: 20, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Pay RM ${widget.booking.depositAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSecurityBadges() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          'Secured by ToyyibPay',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(width: 16),
        Icon(Icons.verified_user, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          'FPX Certified',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

// Updated Payment Success Screen
class PaymentSuccessScreen extends StatefulWidget {
  final BookingStatus booking;
  final String transactionRef;
  final bool isMockMode;

  const PaymentSuccessScreen({
    super.key,
    required this.booking,
    required this.transactionRef,
    this.isMockMode = false,
  });

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7FAFC),
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle,
                          size: 80,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      widget.isMockMode
                          ? 'Mock Payment Successful!'
                          : 'Payment Successful!',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your deposit of RM ${widget.booking.depositAmount.toStringAsFixed(2)} has been ${widget.isMockMode ? 'simulated as ' : ''}paid',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (widget.isMockMode) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Text(
                          'This was a mock payment. Once your ToyyibPay account is approved, you can process real payments.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildReceiptRow(
                              'Transaction Ref', widget.transactionRef),
                          const Divider(height: 24),
                          _buildReceiptRow(
                              'Property', widget.booking.propertyTitle),
                          _buildReceiptRow('Amount Paid',
                              'RM ${widget.booking.depositAmount.toStringAsFixed(2)}'),
                          _buildReceiptRow(
                              'Date',
                              DateFormat('d MMM yyyy, h:mm a')
                                  .format(DateTime.now())),
                          if (widget.isMockMode)
                            _buildReceiptRow(
                                'Mode', 'Mock Payment (Development)'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.popUntil(context, (route) => route.isFirst);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF667EEA),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Back to Home',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
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
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
