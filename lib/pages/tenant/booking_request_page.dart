import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/models/listing.dart';
import 'package:my_app/models/user_model.dart'; // This has User class
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:my_app/config/api_config.dart';
import 'package:my_app/pages/tenant/messages_screen.dart'
    as messages; // Add alias here
import 'package:url_launcher/url_launcher.dart'; // Add this for opening the PDF
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class BookingRequestPage extends StatefulWidget {
  final Listing listing;
  final User currentUser;

  const BookingRequestPage({
    super.key,
    required this.listing,
    required this.currentUser,
  });

  @override
  State<BookingRequestPage> createState() => _BookingRequestPageState();
}

class _BookingRequestPageState extends State<BookingRequestPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _hasExistingBooking = false;
  Map<String, dynamic>? _existingBookingDetails;

  // Form fields
  DateTime? _selectedCheckInDate;
  int _selectedDuration = 6; // Default 6 months
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _emergencyContactController =
      TextEditingController();
  final TextEditingController _emergencyPhoneController =
      TextEditingController();

  bool _isLoading = false;
  bool _agreedToTerms = false;

  // Calculated values
  double _totalAmount = 0;
  double _depositAmount = 0;
  double _monthlyRent = 0;

  // Helper method to safely parse minimum tenure
  int get _minimumTenure {
    try {
      return int.parse(widget.listing.minimumTenure);
    } catch (e) {
      // Default to 1 month if parsing fails
      return 1;
    }
  }

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
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();

    // Set default check-in date to listing's available date
    _selectedCheckInDate = widget.listing.availableFrom;

    // Ensure default duration respects minimum tenure
    _selectedDuration = _selectedDuration >= _minimumTenure
        ? _selectedDuration
        : _minimumTenure;

    _calculateCosts();
    _checkExistingBooking();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _messageController.dispose();
    _emergencyContactController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  void _calculateCosts() {
    _monthlyRent = widget.listing.price;

    // OLD: _depositAmount = _monthlyRent * 2;
    // NEW: Get the actual deposit value directly from the Listing model
    _depositAmount = widget.listing.deposit;

    _totalAmount = (_monthlyRent * _selectedDuration) + _depositAmount;
    setState(() {});
  }

  Future<void> _selectCheckInDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedCheckInDate ?? widget.listing.availableFrom,
      firstDate: widget.listing.availableFrom,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF667EEA),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedCheckInDate) {
      setState(() {
        _selectedCheckInDate = picked;
      });
    }
  }

  Future<void> _launchContract() async {
    final urlString = widget.listing.contractUrl;
    if (urlString != null && urlString.isNotEmpty) {
      final Uri url = Uri.parse(urlString);
      try {
        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open contract file')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening contract: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No contract document available for this property')),
      );
    }
  }

  Future<void> _submitBookingRequest() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate minimum tenure
    if (_selectedDuration < _minimumTenure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Duration must be at least ${widget.listing.minimumTenure} months'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the terms and conditions'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_hasExistingBooking) {
      _showExistingBookingDialog();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare booking data
      final bookingData = {
        'listing_id': widget.listing.id,
        'tenant_id': widget.currentUser.id,
        'check_in_date': DateFormat('yyyy-MM-dd').format(_selectedCheckInDate!),
        'duration_months': _selectedDuration,
        'monthly_rent': _monthlyRent,
        'deposit_amount': _depositAmount,
        'total_amount': _totalAmount,
        'message': _messageController.text.trim(),
        'emergency_contact_name': _emergencyContactController.text.trim(),
        'emergency_contact_phone': _emergencyPhoneController.text.trim(),
        'status': 'pending',
      };

      // Make API call to create booking
      // In your BookingRequestPage, update this line:
      final response = await http.post(
        Uri.parse(ApiConfig.createBooking), // Use the constant from ApiConfig
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(bookingData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          // Show success dialog
          _showSuccessDialog();
        } else {
          throw Exception(
              responseData['message'] ?? 'Failed to create booking');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 60,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Booking Request Sent!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your booking request has been sent to the property owner. You will receive a notification once they respond.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to property details
              },
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to property details

                // Navigate to messages screen with alias
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => messages.MessagesScreen(
                      // Use the alias here
                      currentUserId: widget.currentUser.id,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'View My Bookings',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // 1. Function to Open Viewer
  void _openContractViewer() {
    final urlString = widget.listing.contractUrl;
    if (urlString == null || urlString.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No contract available for this property.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContractViewerPage(
          contractUrl: urlString,
          title: 'Rental Agreement - ${widget.listing.title}',
        ),
      ),
    );
  }

  // 2. UI Widget (Matches PropertyDetailsPage style)
  Widget _buildContractCard() {
    if (widget.listing.contractUrl == null ||
        widget.listing.contractUrl!.isEmpty) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: _openContractViewer,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue[100]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.visibility_outlined,
                  color: Colors.blue, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'View Rental Agreement',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to read the agreement now',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.blue[300]),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Booking Request',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Property Summary Card
                    _buildPropertySummaryCard(),
                    const SizedBox(height: 24),

                    // Booking Details Section
                    _buildSectionTitle('Booking Details'),
                    const SizedBox(height: 16),
                    _buildBookingDetailsCard(),
                    const SizedBox(height: 24),

                    // Personal Information Section
                    _buildSectionTitle('Personal Information'),
                    const SizedBox(height: 16),
                    _buildPersonalInfoCard(),
                    const SizedBox(height: 24),

                    // Cost Summary Section
                    _buildSectionTitle('Cost Summary'),
                    const SizedBox(height: 16),
                    _buildCostSummaryCard(),
                    const SizedBox(height: 24),

                    // --- NEW: INSERT CONTRACT CARD HERE ---
                    _buildSectionTitle('Contract'),
                    const SizedBox(height: 12),
                    _buildContractCard(),
                    const SizedBox(height: 24),
                    // --------------------------------------

                    // Terms and Conditions
                    _buildTermsCheckbox(),
                    const SizedBox(height: 32),

                    // Submit Button
                    _buildSubmitButton(),
                    const SizedBox(height: 40),

                    if (_hasExistingBooking)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'You have an existing ${_existingBookingDetails?['status']} booking for this property',
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
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

  Widget _buildPropertySummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Property Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              widget.listing.imageUrls.isNotEmpty
                  ? widget.listing.imageUrls[0]
                  : 'https://via.placeholder.com/100',
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image, color: Colors.grey),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          // Property Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.listing.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.listing.address,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667EEA).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'RM ${widget.listing.price.toStringAsFixed(0)}/month',
                    style: const TextStyle(
                      color: Color(0xFF667EEA),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2D3748),
      ),
    );
  }

  Widget _buildBookingDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Check-in Date
          InkWell(
            onTap: _selectCheckInDate,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667EEA).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.calendar_today,
                      color: Color(0xFF667EEA),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Check-in Date',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedCheckInDate != null
                              ? DateFormat('MMMM d, yyyy')
                                  .format(_selectedCheckInDate!)
                              : 'Select Date',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Duration
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF667EEA).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.access_time,
                        color: Color(0xFF667EEA),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Rental Duration',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildDurationOption(3),
                    const SizedBox(width: 8),
                    _buildDurationOption(6),
                    const SizedBox(width: 8),
                    _buildDurationOption(12),
                  ],
                ),
                if (_selectedDuration < _minimumTenure)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Minimum tenure: ${widget.listing.minimumTenure} months',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Message to Owner
          TextFormField(
            controller: _messageController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Message to Owner (Optional)',
              hintText: 'Introduce yourself or ask any questions...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF667EEA)),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationOption(int months) {
    final isSelected = _selectedDuration == months;
    final isValid = months >= _minimumTenure;

    return Expanded(
      child: InkWell(
        onTap: isValid
            ? () {
                setState(() {
                  _selectedDuration = months;
                  _calculateCosts();
                });
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF667EEA)
                : isValid
                    ? Colors.grey[100]
                    : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF667EEA)
                  : isValid
                      ? Colors.grey[300]!
                      : Colors.grey[200]!,
            ),
          ),
          child: Column(
            children: [
              Text(
                '$months',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Colors.white
                      : isValid
                          ? Colors.black87
                          : Colors.grey[400],
                ),
              ),
              Text(
                'months',
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? Colors.white
                      : isValid
                          ? Colors.grey[600]
                          : Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Emergency Contact Name
          TextFormField(
            controller: _emergencyContactController,
            decoration: InputDecoration(
              labelText: 'Emergency Contact Name',
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667EEA).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFF667EEA),
                    size: 20,
                  ),
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF667EEA)),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter emergency contact name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Emergency Contact Phone
          TextFormField(
            controller: _emergencyPhoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Emergency Contact Phone',
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667EEA).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.phone,
                    color: Color(0xFF667EEA),
                    size: 20,
                  ),
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF667EEA)),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter emergency contact phone';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCostSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF667EEA).withOpacity(0.05),
            const Color(0xFF764BA2).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF667EEA).withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          // Rental Details Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rental Details',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                _buildCostRow(
                  'Monthly Rent',
                  'RM ${_monthlyRent.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 8),
                _buildCostRow('Duration', '$_selectedDuration months'),
                const SizedBox(height: 8),
                _buildCostRow(
                  'Total Rental Cost',
                  'RM ${(_monthlyRent * _selectedDuration).toStringAsFixed(2)}',
                  subtitle: '(Paid monthly)',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Payment Due Now Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF667EEA).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF667EEA).withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.payment,
                      size: 20,
                      color: Color(0xFF667EEA),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Payment Due Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF667EEA),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildCostRow(
                  'Security Deposit',
                  'RM ${_depositAmount.toStringAsFixed(2)}',
                  subtitle: '(2 months rent - Refundable)',
                  isHighlighted: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Payment Schedule Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Payment Schedule',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildPaymentInfo(
                  '• Pay only deposit now: RM ${_depositAmount.toStringAsFixed(2)}',
                ),
                _buildPaymentInfo(
                  '• Monthly rent of RM ${_monthlyRent.toStringAsFixed(2)} starts from check-in date',
                ),
                _buildPaymentInfo(
                  '• Deposit will be refunded after check-out (subject to terms)',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Total Overview
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _buildCostRow(
              'Total Contract Value',
              'RM ${_totalAmount.toStringAsFixed(2)}',
              subtitle: '(Deposit + $_selectedDuration months rent)',
              isSubdued: true,
            ),
          ),
        ],
      ),
    );
  }

  // Updated helper method with new parameters
  Widget _buildCostRow(String label, String value,
      {String? subtitle,
      bool isTotal = false,
      bool isHighlighted = false,
      bool isSubdued = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isHighlighted ? 15 : (isTotal ? 16 : 14),
                  fontWeight: isHighlighted || isTotal
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: isSubdued
                      ? Colors.grey[600]
                      : (isHighlighted
                          ? const Color(0xFF667EEA)
                          : (isTotal
                              ? const Color(0xFF2D3748)
                              : Colors.grey[700])),
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlighted ? 20 : (isTotal ? 18 : 16),
            fontWeight: isHighlighted
                ? FontWeight.bold
                : (isTotal ? FontWeight.bold : FontWeight.w500),
            color: isSubdued
                ? Colors.grey[600]
                : (isHighlighted
                    ? const Color(0xFF667EEA)
                    : (isTotal ? const Color(0xFF667EEA) : Colors.black87)),
          ),
        ),
      ],
    );
  }

  // Helper method for payment info text
  Widget _buildPaymentInfo(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.blue[700],
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _agreedToTerms,
          onChanged: (value) {
            setState(() {
              _agreedToTerms = value ?? false;
            });
          },
          activeColor: const Color(0xFF667EEA),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _agreedToTerms = !_agreedToTerms;
              });
            },
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                children: const [
                  TextSpan(text: 'I agree to the '),
                  TextSpan(
                    text: 'Terms and Conditions',
                    style: TextStyle(
                      color: Color(0xFF667EEA),
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Rental Agreement',
                    style: TextStyle(
                      color: Color(0xFF667EEA),
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Payment summary above button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF667EEA).withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF667EEA).withOpacity(0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Amount to Pay Now:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                'RM ${_depositAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF667EEA),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Submit button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitBookingRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Confirm Booking',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 8),

        // Security note
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.security,
              size: 14,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              'Secure payment powered by Stripe',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Add this new method
  Future<void> _checkExistingBooking() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.checkExistingBooking(
          widget.currentUser.id.toString(),
          widget.listing.id.toString(),
        )),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] && data['has_existing_booking']) {
          setState(() {
            _hasExistingBooking = true;
            _existingBookingDetails = data['booking'];
          });

          // Show warning dialog
          _showExistingBookingDialog();
        }
      }
    } catch (e) {
      print('Error checking existing booking: $e');
    }
  }

  // Add this method to show warning dialog
  void _showExistingBookingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final bookingDate =
            DateTime.parse(_existingBookingDetails!['check_in_date']);
        final status = _existingBookingDetails!['status'];

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding:
              const EdgeInsets.fromLTRB(20, 16, 20, 0), // Reduced top padding
          titlePadding: const EdgeInsets.fromLTRB(
              20, 16, 20, 8), // Reduced bottom padding
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 24, // Reduced from 28
              ),
              SizedBox(width: 6), // Reduced from 8
              Expanded(
                child: Text(
                  'Existing Booking Found',
                  style: TextStyle(fontSize: 16), // Added explicit font size
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height *
                  0.6, // Limit height to 60% of screen
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You already have a $status booking for this property.',
                    style: const TextStyle(fontSize: 14), // Reduced from 16
                  ),
                  const SizedBox(height: 10), // Reduced from 12
                  Container(
                    padding: const EdgeInsets.all(10), // Reduced from 12
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Booking Details:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13, // Reduced from 14
                          ),
                        ),
                        const SizedBox(height: 6), // Reduced from 8
                        Text(
                          'Check-in: ${DateFormat('MMM d, yyyy').format(bookingDate)}',
                          style:
                              const TextStyle(fontSize: 12), // Reduced from 13
                        ),
                        const SizedBox(height: 2), // Added small spacing
                        Text(
                          'Duration: ${_existingBookingDetails!['duration_months']} months',
                          style:
                              const TextStyle(fontSize: 12), // Reduced from 13
                        ),
                        const SizedBox(height: 2), // Added small spacing
                        Text(
                          'Status: ${status.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 12, // Reduced from 13
                            color: status == 'confirmed'
                                ? Colors.green
                                : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12), // Added spacing before buttons
                ],
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(
                  bottom: 8), // Add bottom padding to actions
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.of(context)
                          .pop(); // Go back to property details
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8), // Compact padding
                    ),
                    child: const Text(
                      'Go Back',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                  if (status == 'pending') ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // Optionally navigate to bookings page
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8), // Compact padding
                      ),
                      child: const Text(
                        'View Booking',
                        style:
                            TextStyle(color: Color(0xFF667EEA), fontSize: 14),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class ContractViewerPage extends StatelessWidget {
  final String contractUrl;
  final String title;

  const ContractViewerPage({
    super.key,
    required this.contractUrl,
    required this.title,
  });

  Future<void> _downloadFile() async {
    final Uri url = Uri.parse(contractUrl);
    // Opens in external browser/downloader
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch contract URL');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          // Download Button in AppBar
          IconButton(
            onPressed: _downloadFile,
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Download PDF',
          ),
        ],
      ),
      // View PDF internally
      body: SfPdfViewer.network(
        contractUrl,
        canShowScrollHead: false,
        canShowScrollStatus: false,
        onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load PDF: ${details.error}')),
          );
        },
      ),
    );
  }
}
