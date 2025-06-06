import 'package:flutter/material.dart';
import 'package:my_app/models/listing.dart';
import 'package:intl/intl.dart';
// import 'package:my_app/widgets/fullscreen_image_viewer.dart'; // Updated import path
import 'package:video_player/video_player.dart';
import 'package:my_app/pages/owner/edit_listing_page.dart';
import 'package:my_app/services/database_service.dart';

class PropertyDetailsPage extends StatefulWidget {
  final Listing listing;

  const PropertyDetailsPage({super.key, required this.listing});

  @override
  State<PropertyDetailsPage> createState() => _PropertyDetailsPageState();
}

class _PropertyDetailsPageState extends State<PropertyDetailsPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isFavorited = false;
  bool _isUpdatingStatus = false;
  late Listing _currentListing;

  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _currentListing = widget.listing;
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // EDIT FUNCTION
  Future<void> _editListing(Listing listing) async {
    try {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => EditListingPage(
              listing: listing), // You'll need to create this page
        ),
      );

      if (result == true && mounted) {
        // Refresh the current listing data
        _showSuccessMessage('Property updated successfully');
        // You might want to refresh the listing data here
        // await _refreshListingData();
      }
    } catch (e) {
      _showErrorMessage('Failed to edit property: $e');
    }
  }

  // UPDATE LISTING STATUS
  Future<void> _updateListingStatus(Listing listing, String newStatus) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final listingId = listing.id;
      if (listingId.isEmpty) {
        throw Exception('Invalid listing ID');
      }

      // ✅ ACTUALLY CALL THE DATABASE SERVICE
      final success = await _databaseService.updateListingStatus(
        int.parse(listingId),
        newStatus,
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (success && mounted) {
        // Update local state
        setState(() {
          _currentListing = listing.copyWith(status: newStatus);
        });

        // Show success message
        final message = newStatus == 'active'
            ? 'Property activated successfully'
            : 'Property deactivated successfully';

        _showSuccessMessage(message);

        // Optional: Return result to previous page to refresh listings
        Navigator.pop(context, true);
      } else {
        if (mounted) {
          _showErrorMessage('Failed to update property status');
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (mounted) {
        _showErrorMessage('Error updating property: $e');
      }
    }
  }

  // DEACTIVATE CONFIRMATION
  void _showDeactivateConfirmation(Listing listing) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.pause_circle_outline, color: Colors.orange[600]),
            const SizedBox(width: 8),
            const Text('Deactivate Property'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to deactivate "${listing.title}"?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will hide the property from search results. You can reactivate it later.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateListingStatus(listing, 'inactive');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }

  // REACTIVATE CONFIRMATION
  void _showReactivateConfirmation(Listing listing) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.play_circle_outline, color: Colors.green[600]),
            const SizedBox(width: 8),
            const Text('Reactivate Property'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to reactivate "${listing.title}"?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will make the property visible in search results again.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateListingStatus(listing, 'active');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Reactivate'),
          ),
        ],
      ),
    );
  }

  // HELPER FUNCTIONS
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[600],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Widget _buildImageSlider() {
    if (_currentListing.imageUrls.isEmpty ?? true) {
      return Container(
        height: 300,
        margin: const EdgeInsets.only(top: 20), // Added top space
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey[300]!, Colors.grey[100]!],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.image_outlined,
                  size: 40,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No Images Available',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 300,
      margin: const EdgeInsets.only(top: 50), // Added top space
      child: PropertyDetailsImageSlider(
        imageUrls: _currentListing.imageUrls,
        title: _currentListing.title,
      ),
    );
  }

  Widget _buildActionButtons() {
    final isActive = _currentListing.status?.toLowerCase() == 'active';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isUpdatingStatus
                  ? null
                  : () {
                      if (isActive) {
                        _showDeactivateConfirmation(_currentListing);
                      } else {
                        _showReactivateConfirmation(_currentListing);
                      }
                    },
              icon: _isUpdatingStatus
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(
                      isActive
                          ? Icons.pause_circle_outline
                          : Icons.play_circle_outline,
                    ),
              label: Text(_isUpdatingStatus
                  ? 'Updating...'
                  : (isActive ? 'Deactivate' : 'Reactivate')),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor:
                    isActive ? Colors.orange[600] : Colors.green[600],
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                _editListing(_currentListing);
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final isActive = _currentListing.status?.toLowerCase() == 'active';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isActive ? Colors.green[100] : Colors.orange[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive ? Colors.green[300]! : Colors.orange[300]!,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green[600] : Colors.orange[600],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: isActive ? Colors.green[700] : Colors.orange[700],
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 32),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Monthly Rent',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'RM ${_currentListing.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.trending_up, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320, // Increased to accommodate top space
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  _buildImageSlider(),
                  // Gradient overlay for better text visibility
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 120, // Increased to cover the top space area
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: const Icon(Icons.share),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.9),
                    foregroundColor: Colors.black87,
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Share feature coming soon'),
                        backgroundColor: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 16),
                child: IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      _isFavorited ? Icons.favorite : Icons.favorite_border,
                      key: ValueKey(_isFavorited),
                      color: _isFavorited ? Colors.red : Colors.black87,
                    ),
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.9),
                  ),
                  onPressed: () {
                    setState(() {
                      _isFavorited = !_isFavorited;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _isFavorited
                              ? 'Added to favorites'
                              : 'Removed from favorites',
                        ),
                        backgroundColor: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Badge
                _buildStatusBadge(),

                // Action Buttons (Reactive/Deactivate and Edit)
                _buildActionButtons(),

                // Title and Location
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          spreadRadius: 0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentListing.title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.red[600],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${_currentListing.address}, ${_currentListing.postcode}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Price Card
                _buildPriceCard(),

                // Property Overview
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildInfoSection('Property Overview', [
                    Row(
                      children: [
                        Expanded(
                          child: _buildOverviewCard(
                            Icons.bed,
                            '${_currentListing.bedrooms}',
                            'Bedrooms',
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildOverviewCard(
                            Icons.bathroom,
                            '${_currentListing.bathrooms}',
                            'Bathrooms',
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildOverviewCard(
                            Icons.square_foot,
                            '${_currentListing.areaSqft}',
                            'sqft',
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ]),
                ),

                // Description
                if (_currentListing.description.isNotEmpty ?? false)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildInfoSection('Description', [
                      Text(
                        _currentListing.description ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: Colors.black87,
                        ),
                      ),
                    ]),
                  ),

                // Property Details
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildInfoSection('Property Details', [
                    _buildDetailRow(
                      'Bedrooms',
                      '${_currentListing.bedrooms}',
                      icon: Icons.bed,
                    ),
                    _buildDetailRow(
                      'Bathrooms',
                      '${_currentListing.bathrooms}',
                      icon: Icons.bathroom,
                    ),
                    _buildDetailRow(
                      'Area',
                      '${_currentListing.areaSqft} sqft',
                      icon: Icons.square_foot,
                    ),
                    _buildDetailRow(
                      'Available From',
                      DateFormat(
                        'd MMMM y',
                      ).format(_currentListing.availableFrom),
                      icon: Icons.calendar_today,
                    ),
                    _buildDetailRow(
                      'Minimum Tenure',
                      '${_currentListing.minimumTenure} month',
                      icon: Icons.timelapse,
                    ),
                  ]),
                ),

                // Location
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildInfoSection('Location', [
                    _buildDetailRow(
                      'Address',
                      _currentListing.address,
                      icon: Icons.location_on,
                    ),
                    _buildDetailRow(
                      'Postcode',
                      _currentListing.postcode,
                      icon: Icons.mail,
                    ),
                  ]),
                ),

                const SizedBox(height: 120), // Space for floating button
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.contact_phone,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Contact Owner'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Interested in "${_currentListing.title}"?'),
              const SizedBox(height: 16),
              const Text('Choose how you\'d like to contact the owner:'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Opening phone app...'),
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.phone),
              label: const Text('Call'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Opening messaging app...'),
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.message),
              label: const Text('Message'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Placeholder for EditListingPage - you'll need to create this
// class EditListingPage extends StatelessWidget {
//   final Listing listing;

//   const EditListingPage({super.key, required this.listing});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Edit Property'),
//       ),
//       body: const Center(
//         child: Text('Edit Listing Page - To be implemented'),
//       ),
//     );
//   }
// }

// Enhanced Property Details Image Slider Widget with Video Support
class PropertyDetailsImageSlider extends StatefulWidget {
  final List<String> imageUrls;
  final String title;

  const PropertyDetailsImageSlider({
    super.key,
    required this.imageUrls,
    required this.title,
  });

  @override
  State<PropertyDetailsImageSlider> createState() =>
      _PropertyDetailsImageSliderState();
}

// Media type detection for slider
enum SliderMediaType { image, video }

class SliderMediaItem {
  final String url;
  final SliderMediaType type;

  SliderMediaItem({required this.url, required this.type});

  factory SliderMediaItem.fromUrl(String url) {
    final lowerUrl = url.toLowerCase();
    if (lowerUrl.endsWith('.mp4') ||
        lowerUrl.endsWith('.mov') ||
        lowerUrl.endsWith('.avi') ||
        lowerUrl.endsWith('.mkv') ||
        lowerUrl.endsWith('.webm')) {
      return SliderMediaItem(url: url, type: SliderMediaType.video);
    }
    return SliderMediaItem(url: url, type: SliderMediaType.image);
  }
}

class _PropertyDetailsImageSliderState extends State<PropertyDetailsImageSlider>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentIndex = 0;
  late int _totalSlides;
  late AnimationController _indicatorController;
  late List<SliderMediaItem> _mediaItems;
  Map<int, VideoPlayerController> _videoControllers = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Convert URLs to MediaItems
    _mediaItems =
        widget.imageUrls.map((url) => SliderMediaItem.fromUrl(url)).toList();

    _totalSlides = _mediaItems.isNotEmpty ? _mediaItems.length + 1 : 0;
    _indicatorController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Initialize first video if needed
    _initializeVideoForIndex(1); // Index 1 because 0 is grid view
  }

  void _initializeVideoForIndex(int pageIndex) {
    if (pageIndex > 0 && pageIndex <= _mediaItems.length) {
      final mediaIndex = pageIndex - 1;
      final mediaItem = _mediaItems[mediaIndex];

      if (mediaItem.type == SliderMediaType.video &&
          !_videoControllers.containsKey(mediaIndex)) {
        final controller =
            VideoPlayerController.networkUrl(Uri.parse(mediaItem.url));
        _videoControllers[mediaIndex] = controller;
        controller.initialize().then((_) {
          if (mounted) setState(() {});
        });
      }
    }
  }

  void _pauseAllVideos() {
    for (final controller in _videoControllers.values) {
      if (controller.value.isInitialized && controller.value.isPlaying) {
        controller.pause();
      }
    }
  }

  void _toggleVideoPlayback(int mediaIndex) {
    final controller = _videoControllers[mediaIndex];
    if (controller != null && controller.value.isInitialized) {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        _pauseAllVideos(); // Pause other videos
        controller.play();
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _indicatorController.dispose();

    // Dispose all video controllers
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  Widget _buildNetworkImage(String imageUrl, {bool isGridItem = false}) {
    if (imageUrl.isEmpty) {
      return _buildPlaceholder(isGridItem);
    }

    return Hero(
      tag: imageUrl,
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[200]!, Colors.grey[100]!],
              ),
            ),
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: isGridItem ? 2 : 3,
                color: Theme.of(context).primaryColor,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder(isGridItem, isError: true);
        },
      ),
    );
  }

  Widget _buildVideoPlayer(SliderMediaItem mediaItem, int mediaIndex,
      {bool isGridItem = false}) {
    final controller = _videoControllers[mediaIndex];

    if (controller == null || !controller.value.isInitialized) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey[800]!, Colors.grey[700]!],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: isGridItem ? 2 : 3,
              ),
              if (!isGridItem) ...[
                const SizedBox(height: 16),
                const Text(
                  'Loading video...',
                  style: TextStyle(color: Colors.white70),
                ),
              ]
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          ),
        ),

        // Video controls overlay
        if (!isGridItem)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => _toggleVideoPlayback(mediaIndex),
              child: Container(
                color: Colors.transparent,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: controller.value.isPlaying ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Icon(
                        controller.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Video indicator
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.videocam,
                  color: Colors.white,
                  size: isGridItem ? 12 : 16,
                ),
                if (!isGridItem) ...[
                  const SizedBox(width: 4),
                  Text(
                    _formatDuration(controller.value.duration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),

        // Progress bar for non-grid items
        if (!isGridItem && controller.value.isPlaying)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
              child: VideoProgressIndicator(
                controller,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Colors.white,
                  bufferedColor: Colors.white30,
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _buildPlaceholder(bool isGridItem, {bool isError = false}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[300]!, Colors.grey[200]!],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isGridItem ? 8 : 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isError ? Icons.error_outline : Icons.image_outlined,
                size: isGridItem ? 16 : 32,
                color: isError ? Colors.red[400] : Colors.grey[500],
              ),
            ),
            if (!isGridItem) ...[
              const SizedBox(height: 8),
              Text(
                isError ? 'Load Failed' : 'No Image',
                style: TextStyle(
                  fontSize: 12,
                  color: isError ? Colors.red[400] : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGridView() {
    List<SliderMediaItem?> displayItems = List.filled(4, null);
    for (int i = 0; i < 4 && i < _mediaItems.length; i++) {
      displayItems[i] = _mediaItems[i];
    }

    return Stack(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: () {
                  openFullScreenMediaViewer(
                    context,
                    widget.imageUrls,
                    0,
                    widget.title,
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(2, 0),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(0),
                    ),
                    child: displayItems[0] != null
                        ? (displayItems[0]!.type == SliderMediaType.video
                            ? _buildVideoPlayer(displayItems[0]!, 0,
                                isGridItem: true)
                            : _buildNetworkImage(displayItems[0]!.url,
                                isGridItem: true))
                        : _buildPlaceholder(true),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 2),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        openFullScreenMediaViewer(
                          context,
                          widget.imageUrls,
                          1,
                          widget.title,
                        );
                      },
                      child: SizedBox(
                        width: double.infinity,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(0),
                          ),
                          child: displayItems[1] != null
                              ? (displayItems[1]!.type == SliderMediaType.video
                                  ? _buildVideoPlayer(displayItems[1]!, 1,
                                      isGridItem: true)
                                  : _buildNetworkImage(displayItems[1]!.url,
                                      isGridItem: true))
                              : _buildPlaceholder(true),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        openFullScreenMediaViewer(
                          context,
                          widget.imageUrls,
                          2,
                          widget.title,
                        );
                      },
                      child: SizedBox(
                        width: double.infinity,
                        child: ClipRRect(
                          child: displayItems[2] != null
                              ? (displayItems[2]!.type == SliderMediaType.video
                                  ? _buildVideoPlayer(displayItems[2]!, 2,
                                      isGridItem: true)
                                  : _buildNetworkImage(displayItems[2]!.url,
                                      isGridItem: true))
                              : _buildPlaceholder(true),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        openFullScreenMediaViewer(
                          context,
                          widget.imageUrls,
                          3,
                          widget.title,
                        );
                      },
                      child: Stack(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ClipRRect(
                              child: displayItems[3] != null
                                  ? (displayItems[3]!.type ==
                                          SliderMediaType.video
                                      ? _buildVideoPlayer(displayItems[3]!, 3,
                                          isGridItem: true)
                                      : _buildNetworkImage(displayItems[3]!.url,
                                          isGridItem: true))
                                  : _buildPlaceholder(true),
                            ),
                          ),
                          if (_mediaItems.length > 4)
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withOpacity(0.7),
                                    Colors.black.withOpacity(0.5),
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.photo_library,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '+${_mediaItems.length - 4}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          bottom: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _mediaItems.any((item) => item.type == SliderMediaType.video)
                      ? Icons.photo_library
                      : Icons.photo_library,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  '${_mediaItems.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_mediaItems.isEmpty) {
      return _buildPlaceholder(false);
    }

    if (_mediaItems.length == 1) {
      final mediaItem = _mediaItems[0];
      return GestureDetector(
        onTap: () {
          openFullScreenMediaViewer(
            context,
            widget.imageUrls,
            0,
            widget.title,
          );
        },
        child: ClipRRect(
          child: mediaItem.type == SliderMediaType.video
              ? _buildVideoPlayer(mediaItem, 0)
              : _buildNetworkImage(mediaItem.url),
        ),
      );
    }

    return Stack(
      children: [
        SizedBox(
          height: double.infinity,
          width: double.infinity,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
              _indicatorController.forward(from: 0);

              // Pause all videos when changing pages
              _pauseAllVideos();

              // Initialize video for new page if needed
              _initializeVideoForIndex(index);
            },
            itemCount: _totalSlides,
            allowImplicitScrolling: true,
            pageSnapping: true,
            physics: const PageScrollPhysics(),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildGridView();
              } else {
                final mediaIndex = index - 1;
                final mediaItem = _mediaItems[mediaIndex];
                return GestureDetector(
                  onTap: () {
                    openFullScreenMediaViewer(
                      context,
                      widget.imageUrls,
                      mediaIndex,
                      widget.title,
                    );
                  },
                  child: mediaItem.type == SliderMediaType.video
                      ? _buildVideoPlayer(mediaItem, mediaIndex)
                      : _buildNetworkImage(mediaItem.url),
                );
              }
            },
          ),
        ),

        // Enhanced page indicators
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _totalSlides,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _currentIndex == index ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: _currentIndex == index
                      ? Colors.white
                      : Colors.white.withOpacity(0.4),
                  boxShadow: _currentIndex == index
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ),
        ),

        // Navigation hint with animation
        if (_currentIndex == 0 && _mediaItems.length > 1)
          Positioned(
            bottom: 50,
            right: 16,
            child: AnimatedBuilder(
              animation: _indicatorController,
              builder: (context, child) {
                return AnimatedOpacity(
                  opacity: _indicatorController.value,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

// Placeholder function for opening fullscreen viewer
void openFullScreenMediaViewer(BuildContext context, List<String> imageUrls,
    int initialIndex, String title) {
  // Implement your fullscreen image viewer here
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: Text(title),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Fullscreen viewer for image $initialIndex\n(To be implemented)',
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );
}
