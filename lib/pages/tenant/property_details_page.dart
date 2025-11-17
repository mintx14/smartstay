import 'package:flutter/material.dart';
import 'package:my_app/models/listing.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:my_app/config/api_config.dart'; // Adjust path as needed
import 'booking_request_page.dart';
import 'package:my_app/models/user_model.dart' as UserModel;
import 'package:video_player/video_player.dart';
// Import the messages screen to use OwnerChatScreen and User class with alias
import 'package:my_app/pages/tenant/messages_screen.dart' as chat_screen;

class PropertyDetailsPage extends StatefulWidget {
  final Listing listing;
  final bool isFavorite;
  final Function(Listing) onFavoriteToggle;
  final UserModel.User user; // ADD THIS LINE

  const PropertyDetailsPage({
    super.key,
    required this.listing,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.user, // ADD THIS LINE
  });

  @override
  State<PropertyDetailsPage> createState() => _PropertyDetailsPageState();
}

class _PropertyDetailsPageState extends State<PropertyDetailsPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _heartAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Add this to track local favorite state
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();

    // Initialize the local favorite state
    _isFavorite = widget.isFavorite;

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _heartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
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

  // Add this method to update the widget when props change
  @override
  void didUpdateWidget(PropertyDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFavorite != widget.isFavorite) {
      setState(() {
        _isFavorite = widget.isFavorite;
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _heartAnimationController.dispose();
    super.dispose();
  }

  Widget _buildImageSlider() {
    if (widget.listing.imageUrls.isEmpty) {
      return Container(
        height: 300,
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
                child: Icon(Icons.image_outlined,
                    size: 40, color: Colors.grey[400]),
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

    return SizedBox(
      height: 300,
      child: PropertyDetailsImageSlider(
        imageUrls: widget.listing.imageUrls,
        title: widget.listing.title,
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
              child:
                  Icon(icon, size: 20, color: Theme.of(context).primaryColor),
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
            Theme.of(context).primaryColor.withOpacity(0.8)
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
                'RM ${widget.listing.price.toStringAsFixed(2)}',
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
            child: const Icon(
              Icons.trending_up,
              color: Colors.white,
              size: 24,
            ),
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
            expandedHeight: 300,
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
                    height: 100,
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
                margin: const EdgeInsets.only(right: 16),
                child: ScaleTransition(
                  scale: Tween<double>(begin: 1.0, end: 1.3).animate(
                    CurvedAnimation(
                      parent: _heartAnimationController,
                      curve: Curves.elasticOut,
                    ),
                  ),
                  child: IconButton(
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        key: ValueKey(_isFavorite),
                        color: _isFavorite ? Colors.red : Colors.black87,
                      ),
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.9),
                    ),
                    onPressed: () {
                      // Update local state immediately for instant feedback
                      setState(() {
                        _isFavorite = !_isFavorite;
                      });

                      // Call the parent's toggle function
                      widget.onFavoriteToggle(widget.listing);

                      // Animate the heart
                      _heartAnimationController.forward().then((_) {
                        _heartAnimationController.reverse();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                          widget.listing.title,
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
                                '${widget.listing.address}, ${widget.listing.postcode}',
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
                  child: _buildInfoSection(
                    'Property Overview',
                    [
                      Row(
                        children: [
                          Expanded(
                            child: _buildOverviewCard(
                              Icons.bed,
                              '${widget.listing.bedrooms}',
                              'Bedrooms',
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildOverviewCard(
                              Icons.bathroom,
                              '${widget.listing.bathrooms}',
                              'Bathrooms',
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildOverviewCard(
                              Icons.square_foot,
                              '${widget.listing.areaSqft}',
                              'sqft',
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Description
                if (widget.listing.description.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildInfoSection(
                      'Description',
                      [
                        Text(
                          widget.listing.description,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Property Details
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildInfoSection(
                    'Property Details',
                    [
                      _buildDetailRow(
                        'Bedrooms',
                        '${widget.listing.bedrooms}',
                        icon: Icons.bed,
                      ),
                      _buildDetailRow(
                        'Bathrooms',
                        '${widget.listing.bathrooms}',
                        icon: Icons.bathroom,
                      ),
                      _buildDetailRow(
                        'Area',
                        '${widget.listing.areaSqft} sqft',
                        icon: Icons.square_foot,
                      ),
                      _buildDetailRow(
                        'Available From',
                        DateFormat('d MMMM y')
                            .format(widget.listing.availableFrom),
                        icon: Icons.calendar_today,
                      ),
                      _buildDetailRow(
                        'Minimum Tenure',
                        '${widget.listing.minimumTenure} month',
                        icon: Icons.timelapse,
                      ),
                    ],
                  ),
                ),

                // Location
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildInfoSection(
                    'Location',
                    [
                      _buildDetailRow(
                        'Address',
                        widget.listing.address,
                        icon: Icons.location_on,
                      ),
                      _buildDetailRow(
                        'Postcode',
                        widget.listing.postcode,
                        icon: Icons.mail,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 120), // Space for floating button
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        height: 120,
        child: Column(
          children: [
            // Book Now Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FloatingActionButton.extended(
                heroTag: "bookNow",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingRequestPage(
                        listing: widget.listing,
                        currentUser: widget.user, // Just pass the user directly
                      ),
                    ),
                  );
                },
                backgroundColor: const Color(0xFF48BB78),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                label: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Book Now',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Contact Owner Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FloatingActionButton.extended(
                heroTag: "contactOwner",
                onPressed: () {
                  _showContactDialog();
                },
                backgroundColor: Theme.of(context).primaryColor,
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                label: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phone, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Contact Owner',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildOverviewCard(
      IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        // ignore: deprecated_member_use
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
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

  // Updated _showContactDialog method in PropertyDetailsPage

  // Updated _showContactDialog method with better error handling and debugging
  void _showContactDialog() async {
    // Show loading indicator while fetching owner data
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      // Convert listing.id to int if it's a String
      int listingId;
      listingId = int.parse(widget.listing.id);

      print('Fetching owner for listing ID: $listingId'); // Debug log

      // UPDATED: Use API config instead of hardcoded URL
      final response = await http.get(
        Uri.parse(ApiConfig.getListingOwnerUrlWithId(listingId)),
      );

      print('API Response Status: ${response.statusCode}'); // Debug log
      print('API Response Body: ${response.body}'); // Debug log

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['owner'] != null) {
          final owner = data['owner'];

          print('Owner data: $owner'); // Debug log

          if (!mounted) return;

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
                    Text('Owner: ${owner['full_name'] ?? 'Unknown'}'),
                    const SizedBox(height: 8),
                    Text('Property: ${widget.listing.title}'),
                    const SizedBox(height: 16),
                    const Text('Choose how you\'d like to contact the owner:'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  if (owner['phone'] != null &&
                      owner['phone'].toString().isNotEmpty)
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // TODO: Implement actual phone call functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Calling ${owner['phone']}...'),
                            backgroundColor: Theme.of(context).primaryColor,
                          ),
                        );
                      },
                      icon: const Icon(Icons.phone),
                      label: const Text('Call'),
                    ),
                  ElevatedButton.icon(
                    onPressed: () {
                      try {
                        Navigator.of(context).pop();

                        // Debug: Check if all required data is present
                        final ownerIdRaw = owner['owner_id'] ??
                            owner['id'] ??
                            owner['user_id'];
                        final ownerName =
                            owner['full_name'] ?? owner['name'] ?? 'Unknown';
                        final ownerEmail = owner['email'] ?? '';

                        print('Navigating to chat with:'); // Debug log
                        print(
                            'Owner ID Raw: $ownerIdRaw (Type: ${ownerIdRaw.runtimeType})');
                        print('Owner Name: $ownerName');
                        print('Owner Email: $ownerEmail');
                        print('Current User ID: ${getCurrentUserId()}');

                        // Safely parse owner ID
                        int ownerIdInt;
                        if (ownerIdRaw == null ||
                            ownerIdRaw.toString().isEmpty) {
                          throw Exception('Owner ID is missing or empty');
                        }

                        // Handle different types of owner ID
                        if (ownerIdRaw is int) {
                          ownerIdInt = ownerIdRaw;
                        } else if (ownerIdRaw is String) {
                          // Trim whitespace and check if valid
                          final trimmedId = ownerIdRaw.trim();
                          if (trimmedId.isEmpty) {
                            throw Exception('Owner ID is empty');
                          }
                          try {
                            ownerIdInt = int.parse(trimmedId);
                          } catch (e) {
                            throw Exception(
                                'Owner ID "$trimmedId" is not a valid number');
                          }
                        } else {
                          throw Exception(
                              'Owner ID has unexpected type: ${ownerIdRaw.runtimeType}');
                        }

                        print('Parsed Owner ID: $ownerIdInt');

                        // Navigate to chat screen (same as in messages screen)
                        // In the _showContactDialog method, update this part:
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => chat_screen.OwnerChatScreen(
                              currentUserId:
                                  getCurrentUserId(), // Convert String to int here
                              otherUser: UserModel.User(
                                id: ownerIdInt.toString(),
                                fullName: ownerName,
                                email: ownerEmail,
                                userType: 'Owner',
                                phoneNumber: '',
                              ),
                            ),
                          ),
                        ).then((value) {
                          print('Returned from chat screen'); // Debug log
                          // Optionally reload data if needed
                        }).catchError((error) {
                          print(
                              'Error navigating to chat: $error'); // Debug log
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Error opening chat: ${error.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        });
                      } catch (e) {
                        print('Error in message button: $e'); // Debug log
                        print(
                            'Full owner data: $owner'); // Debug log to see full structure
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString()}'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      }
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
        } else {
          throw Exception('Owner data not found in response');
        }
      } else {
        throw Exception(
            'Failed to load owner information. Status: ${response.statusCode}');
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      print('Error in _showContactDialog: $e'); // Debug log

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // Helper function to get current user ID with error handling
  String getCurrentUserId() {
    try {
      // Get the user ID from widget.user
      final userIdValue = widget.user.id;

      // Return the string ID directly
      if (userIdValue.trim().isNotEmpty) {
        return userIdValue.trim();
      } else {
        print('Error: Current user ID is null or empty');
        return '0'; // Return default string value
      }
    } catch (e) {
      print('Error getting current user ID: $e');
      print('User object: ${widget.user}');
      return '0'; // Return default string value
    }
  }
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

class _PropertyDetailsImageSliderState extends State<PropertyDetailsImageSlider>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentIndex = 0;
  late int _totalSlides;
  late AnimationController _indicatorController;
  late List<SliderMediaItem> _mediaItems;
  final Map<int, VideoPlayerController> _videoControllers = {};

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

  void _openFullScreenMediaViewer(int index) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            FullScreenImageViewer(
          imageUrls: widget.imageUrls,
          initialIndex: index,
          title: widget.title,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 300),
      ),
    );
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
                onTap: () => _openFullScreenMediaViewer(0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.only(topLeft: Radius.circular(0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(2, 0),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.only(topLeft: Radius.circular(0)),
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
                      onTap: () => _openFullScreenMediaViewer(1),
                      child: SizedBox(
                        width: double.infinity,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(0)),
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
                      onTap: () => _openFullScreenMediaViewer(2),
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
                      onTap: () => _openFullScreenMediaViewer(3),
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
                                    const Icon(Icons.photo_library,
                                        color: Colors.white, size: 16),
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
        onTap: () => _openFullScreenMediaViewer(0),
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
                  onTap: () => _openFullScreenMediaViewer(mediaIndex),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Swipe for more',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.swipe,
                          color: Colors.white,
                          size: 14,
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
  }
}

// Enhanced FullScreenImageViewer with video support
class FullScreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String title;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrls,
    required this.initialIndex,
    required this.title,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;
  late List<SliderMediaItem> _mediaItems;
  final Map<int, VideoPlayerController> _videoControllers = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    // Convert URLs to MediaItems
    _mediaItems =
        widget.imageUrls.map((url) => SliderMediaItem.fromUrl(url)).toList();

    // Initialize first video if needed
    _initializeVideoForIndex(widget.initialIndex);
  }

  void _initializeVideoForIndex(int index) {
    if (index >= 0 && index < _mediaItems.length) {
      final mediaItem = _mediaItems[index];

      if (mediaItem.type == SliderMediaType.video &&
          !_videoControllers.containsKey(index)) {
        final controller =
            VideoPlayerController.networkUrl(Uri.parse(mediaItem.url));
        _videoControllers[index] = controller;
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

  void _toggleVideoPlayback(int index) {
    final controller = _videoControllers[index];
    if (controller != null && controller.value.isInitialized) {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        _pauseAllVideos();
        controller.play();
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    _pageController.dispose();

    // Dispose all video controllers
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  Widget _buildMediaContent(int index) {
    final mediaItem = _mediaItems[index];

    if (mediaItem.type == SliderMediaType.video) {
      final controller = _videoControllers[index];
      if (controller == null || !controller.value.isInitialized) {
        return const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        );
      }

      return Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
          // Play/Pause overlay
          GestureDetector(
            onTap: () => _toggleVideoPlayback(index),
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
                    padding: const EdgeInsets.all(20),
                    child: Icon(
                      controller.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Video progress indicator
          if (controller.value.isPlaying)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: VideoProgressIndicator(
                controller,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Colors.white,
                  bufferedColor: Colors.white30,
                  backgroundColor: Colors.white24,
                ),
              ),
            ),
        ],
      );
    } else {
      // Image viewer
      return Hero(
        tag: mediaItem.url,
        child: InteractiveViewer(
          panEnabled: true,
          boundaryMargin: const EdgeInsets.all(20),
          minScale: 0.5,
          maxScale: 3.0,
          child: Image.network(
            mediaItem.url,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  color: Colors.white,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 64,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Failed to load media',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full screen media viewer
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });

              // Pause all videos when changing pages
              _pauseAllVideos();

              // Initialize video for new page if needed
              _initializeVideoForIndex(index);
            },
            itemCount: _mediaItems.length,
            itemBuilder: (context, index) {
              return Center(
                child: _buildMediaContent(index),
              );
            },
          ),

          // Top bar with close button and title
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).padding.top + 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom bar with indicators and media counter
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Media counter
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _mediaItems[_currentIndex].type ==
                                    SliderMediaType.video
                                ? Icons.videocam
                                : Icons.photo,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${_currentIndex + 1} of ${_mediaItems.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Page indicators
                    if (_mediaItems.length > 1)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _mediaItems.length,
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
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
