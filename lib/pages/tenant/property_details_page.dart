import 'package:flutter/material.dart';
import 'package:my_app/models/listing.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:my_app/config/api_config.dart';
import 'booking_request_page.dart';
import 'package:my_app/models/user_model.dart' as UserModel;
import 'package:video_player/video_player.dart';
import 'package:my_app/pages/tenant/messages_screen.dart' as chat_screen;

class PropertyDetailsPage extends StatefulWidget {
  final Listing listing;
  final bool isFavorite;
  final Function(Listing) onFavoriteToggle;
  final UserModel.User user;

  const PropertyDetailsPage({
    super.key,
    required this.listing,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.user,
  });

  @override
  State<PropertyDetailsPage> createState() => _PropertyDetailsPageState();
}

class _PropertyDetailsPageState extends State<PropertyDetailsPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _heartAnimationController;
  late Animation<double> _fadeAnimation;
  late bool _isFavorite;
  final ScrollController _scrollController = ScrollController();

  // Color constants derived from your existing theme
  final Color _backgroundColor = const Color(0xFFF8F9FA); // Very light grey
  final Color _cardColor = Colors.white;
  final double _sectionSpacing = 24.0;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _heartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _heartAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- WIDGET BUILDERS ---

  Widget _buildImageSlider() {
    if (widget.listing.imageUrls.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported_outlined,
                  size: 50, color: Colors.grey[400]),
              const SizedBox(height: 10),
              Text('No images', style: TextStyle(color: Colors.grey[500]))
            ],
          ),
        ),
      );
    }
    return PropertyDetailsImageSlider(
      imageUrls: widget.listing.imageUrls,
      title: widget.listing.title,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildSectionContainer({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03), // Much softer shadow
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 22, color: Theme.of(context).primaryColor),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewItem(
      IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08), // Very subtle background
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 26, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monthly Rent',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: 'RM ',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    TextSpan(
                      text: widget.listing.price.toStringAsFixed(0),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Container(
            height: 50,
            width: 1,
            color: Colors.white.withOpacity(0.3),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Deposit',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'RM ${widget.listing.deposit.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Contact Button (Square-ish)
            InkWell(
              onTap: _showContactDialog,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.phone_outlined,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Book Now Button (Expanded)
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookingRequestPage(
                          listing: widget.listing,
                          currentUser: widget.user,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF48BB78),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Book Now',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      bottomNavigationBar:
          _buildBottomBar(), // Fixed bottom bar for cleanliness
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            stretch: true,
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            // Custom Leading button for better visibility
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                child: ScaleTransition(
                  scale: Tween<double>(begin: 1.0, end: 1.3).animate(
                    CurvedAnimation(
                        parent: _heartAnimationController,
                        curve: Curves.elasticOut),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite ? Colors.red : Colors.black87,
                      ),
                      onPressed: () {
                        setState(() {
                          _isFavorite = !_isFavorite;
                        });
                        widget.onFavoriteToggle(widget.listing);
                        _heartAnimationController
                            .forward()
                            .then((_) => _heartAnimationController.reverse());
                      },
                    ),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImageSlider(),
                  // Subtle gradient at bottom of image for smooth transition
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 80,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            _backgroundColor,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Title & Address Section (Clean, no card)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.listing.title,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 20,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${widget.listing.address}, ${widget.listing.postcode}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: _sectionSpacing),

                  // 2. Price Header Card
                  _buildPriceHeader(),

                  // 3. Overview Section (Bed/Bath/Sqft)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _buildOverviewItem(
                            Icons.bed_rounded,
                            '${widget.listing.bedrooms}',
                            'Bedrooms',
                            Colors.blueAccent),
                        const SizedBox(width: 12),
                        _buildOverviewItem(
                            Icons.bathtub_outlined,
                            '${widget.listing.bathrooms}',
                            'Bathrooms',
                            Colors.teal),
                        const SizedBox(width: 12),
                        _buildOverviewItem(
                            Icons.square_foot_rounded,
                            '${widget.listing.areaSqft}',
                            'Sqft',
                            Colors.orangeAccent),
                      ],
                    ),
                  ),

                  SizedBox(height: _sectionSpacing),

                  // 4. Description
                  if (widget.listing.description.isNotEmpty)
                    _buildSectionContainer(
                      children: [
                        _buildSectionTitle('Description'),
                        Text(
                          widget.listing.description,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),

                  if (widget.listing.description.isNotEmpty)
                    SizedBox(height: _sectionSpacing),

                  // 5. Property Details
                  _buildSectionContainer(
                    children: [
                      _buildSectionTitle('Property Details'),
                      _buildDetailRow(
                        'Available From',
                        DateFormat('d MMMM y')
                            .format(widget.listing.availableFrom),
                        icon: Icons.calendar_today_outlined,
                      ),
                      const Divider(height: 1),
                      _buildDetailRow(
                        'Minimum Tenure',
                        widget.listing.minimumTenure,
                        icon: Icons.timer_outlined,
                      ),
                      const Divider(height: 1),
                      _buildDetailRow(
                        'Area Size',
                        '${widget.listing.areaSqft} sqft',
                        icon: Icons.crop_square,
                      ),
                      const Divider(height: 1),
                      // _buildDetailRow(
                      //   'Furnishing',
                      //   'Fully Furnished', // Example: You might want to add this to your model
                      //   icon: Icons.chair_outlined,
                      // ),
                    ],
                  ),

                  SizedBox(height: _sectionSpacing),

                  // 6. Location Details
                  _buildSectionContainer(
                    children: [
                      _buildSectionTitle('Location'),
                      _buildDetailRow(
                        'Full Address',
                        widget.listing.address,
                        icon: Icons.map_outlined,
                      ),
                      const Divider(height: 1),
                      _buildDetailRow(
                        'Postcode',
                        widget.listing.postcode,
                        icon: Icons.markunread_mailbox_outlined,
                      ),
                    ],
                  ),

                  const SizedBox(height: 40), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- LOGIC METHODS (Kept same as your original code) ---

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
      int listingId;
      listingId = int.parse(widget.listing.id);

      final response = await http.get(
        Uri.parse(ApiConfig.getListingOwnerUrlWithId(listingId)),
      );

      if (mounted) Navigator.of(context).pop();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['owner'] != null) {
          final owner = data['owner'];

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

                        final ownerIdRaw = owner['owner_id'] ??
                            owner['id'] ??
                            owner['user_id'];
                        final ownerName =
                            owner['full_name'] ?? owner['name'] ?? 'Unknown';
                        final ownerEmail = owner['email'] ?? '';

                        int ownerIdInt;
                        if (ownerIdRaw == null ||
                            ownerIdRaw.toString().isEmpty) {
                          throw Exception('Owner ID is missing or empty');
                        }

                        if (ownerIdRaw is int) {
                          ownerIdInt = ownerIdRaw;
                        } else if (ownerIdRaw is String) {
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

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => chat_screen.OwnerChatScreen(
                              currentUserId: getCurrentUserId(),
                              otherUser: UserModel.User(
                                id: ownerIdInt.toString(),
                                fullName: ownerName,
                                email: ownerEmail,
                                userType: 'Owner',
                                phoneNumber: '',
                              ),
                            ),
                          ),
                        );
                      } catch (e) {
                        print('Error in message button: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString()}'),
                            backgroundColor: Colors.red,
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
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
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

  String getCurrentUserId() {
    try {
      final userIdValue = widget.user.id;
      if (userIdValue.trim().isNotEmpty) {
        return userIdValue.trim();
      } else {
        return '0';
      }
    } catch (e) {
      return '0';
    }
  }
}

// ... COPY THE REST OF YOUR CLASSES HERE ...
// enum SliderMediaType
// class SliderMediaItem
// class PropertyDetailsImageSlider
// class FullScreenImageViewer
// (These should remain mostly unchanged as they handle internal logic well)

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

    // --- FIX START: Convert raw paths to full URLs ---
    _mediaItems = widget.imageUrls.map((url) {
      // This helper ensures we get 'http://IP/path' instead of just '/path'
      final fullUrl = ApiConfig.generateFullImageUrl(url);
      return SliderMediaItem.fromUrl(fullUrl);
    }).toList();
    // --- FIX END ---

    _totalSlides = _mediaItems.isNotEmpty ? _mediaItems.length + 1 : 0;
    _indicatorController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _initializeVideoForIndex(1);
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
        _pauseAllVideos();
        controller.play();
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _indicatorController.dispose();

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

              _pauseAllVideos();

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

    // --- FIX START: Convert raw paths to full URLs ---
    _mediaItems = widget.imageUrls.map((url) {
      // Apply the same fix here so full screen images load correctly too
      final fullUrl = ApiConfig.generateFullImageUrl(url);
      return SliderMediaItem.fromUrl(fullUrl);
    }).toList();
    // --- FIX END ---

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
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });

              _pauseAllVideos();

              _initializeVideoForIndex(index);
            },
            itemCount: _mediaItems.length,
            itemBuilder: (context, index) {
              return Center(
                child: _buildMediaContent(index),
              );
            },
          ),
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
