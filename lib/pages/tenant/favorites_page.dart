import 'package:flutter/material.dart';
import 'package:my_app/config/api_config.dart';
import 'package:my_app/models/user_model.dart';
import 'package:my_app/models/listing.dart';
import 'package:my_app/services/property_service.dart';
import 'package:intl/intl.dart';
import 'property_details_page.dart';

class FavoritesPage extends StatefulWidget {
  final User user;
  final Set<String> favoriteIds;
  final Function(Listing) onFavoriteToggle;
  final VoidCallback onFavoritesChanged;

  const FavoritesPage({
    super.key,
    required this.user,
    required this.favoriteIds,
    required this.onFavoriteToggle,
    required this.onFavoritesChanged,
  });

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage>
    with TickerProviderStateMixin {
  final PropertyService _propertyService = PropertyService();
  bool _isLoading = true;
  List<Listing> _favoriteListings = [];
  String? _errorMessage;

  late AnimationController _animationController;
  late AnimationController _heartAnimationController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadFavoriteListings();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _heartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _heartAnimationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(FavoritesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload favorites if favoriteIds changed
    if (oldWidget.favoriteIds != widget.favoriteIds) {
      _loadFavoriteListings();
    }
  }

  Future<void> _loadFavoriteListings() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Load all listings first
      final result = await _propertyService.getAllListings();
      final allListings = (result['listings'] as List)
          .map((json) => Listing.fromJson(json))
          .toList();

      // Filter to show only favorites
      final favoriteListings = allListings
          .where(
              (listing) => widget.favoriteIds.contains(listing.id.toString()))
          .toList();

      setState(() {
        _favoriteListings = favoriteListings;
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _toggleFavorite(Listing listing) async {
    // Use the callback from HomePage to handle favorite toggle
    widget.onFavoriteToggle(listing);

    // Animate heart
    _heartAnimationController.forward().then((_) {
      _heartAnimationController.reverse();
    });

    // Remove from local list immediately for better UX
    if (!widget.favoriteIds.contains(listing.id.toString())) {
      setState(() {
        _favoriteListings.removeWhere((item) => item.id == listing.id);
      });
    }

    // Notify parent that favorites changed
    widget.onFavoritesChanged();
  }

  Widget _buildFavoritePropertyCard(Listing listing, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(
          bottom: 20,
          left: 16,
          right: 16,
          top: index == 0 ? 8 : 0,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      PropertyDetailsPage(
                    listing: listing,
                    isFavorite:
                        widget.favoriteIds.contains(listing.id.toString()),
                    onFavoriteToggle: (updatedListing) {
                      _toggleFavorite(updatedListing);
                    },
                    user: widget
                        .user, // ADD THIS LINE - pass the user from widget
                  ),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position: animation.drive(
                        Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                            .chain(CurveTween(curve: Curves.easeOutCubic)),
                      ),
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 400),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section with Favorite Button
                SizedBox(
                  height: 200,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        child: InlineImageSlider(
                          key: ValueKey(
                              '${listing.title}_${listing.imageUrls.hashCode}_${listing.imageUrls.length}_${listing.id}'),
                          imageUrls: listing.imageUrls.isNotEmpty
                              ? listing.imageUrls
                              : [
                                  'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800',
                                  'https://images.unsplash.com/photo-1560449752-8d7085b7b162?w=800',
                                  'https://images.unsplash.com/photo-1560448075-cbc16bb4af8e?w=800',
                                ],
                          title: listing.title,
                        ),
                      ),
                      // Favorite Button
                      Positioned(
                        top: 12,
                        right: 12,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 1.0, end: 1.3).animate(
                            CurvedAnimation(
                              parent: _heartAnimationController,
                              curve: Curves.elasticOut,
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed: () => _toggleFavorite(listing),
                              icon: Icon(
                                widget.favoriteIds
                                        .contains(listing.id.toString())
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: widget.favoriteIds
                                        .contains(listing.id.toString())
                                    ? Colors.red
                                    : Colors.grey[600],
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        listing.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      // Location
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${listing.address}, ${listing.postcode}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Price
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'RM ${listing.price.toStringAsFixed(0)} / month',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Property Details
                      Row(
                        children: [
                          _buildSimpleInfoChip(
                              Icons.bed, '${listing.bedrooms}'),
                          const SizedBox(width: 8),
                          _buildSimpleInfoChip(
                              Icons.bathroom, '${listing.bathrooms}'),
                          const SizedBox(width: 8),
                          _buildSimpleInfoChip(
                              Icons.square_foot, '${listing.areaSqft} sqft'),
                          const Spacer(),
                          Text(
                            'Available: ${DateFormat('MMM d').format(listing.availableFrom)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Loading your favorites...',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF4A5568),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red.withOpacity(0.1),
                    Colors.pink.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.favorite_border,
                size: 80,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'No Favorites Yet',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Save your favorite properties to view them here.\nTap the heart icon on any property to add it to favorites.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Error Loading Favorites',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadFavoriteListings,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFF7FAFC),
            Colors.grey[50]!,
          ],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _loadFavoriteListings,
        color: const Color(0xFF667EEA),
        child: _isLoading
            ? _buildLoadingState()
            : _errorMessage != null
                ? _buildErrorState()
                : _favoriteListings.isEmpty
                    ? _buildEmptyState()
                    : Column(
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Colors.red, Colors.pink],
                                    ),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: const Icon(
                                    Icons.favorite,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Your Favorites',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2D3748),
                                      ),
                                    ),
                                    Text(
                                      '${_favoriteListings.length} ${_favoriteListings.length == 1 ? 'property' : 'properties'}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Favorites List
                          Expanded(
                            child: ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 20),
                              itemCount: _favoriteListings.length,
                              itemBuilder: (context, index) {
                                return _buildFavoritePropertyCard(
                                  _favoriteListings[index],
                                  index,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
      ),
    );
  }
}

// Same InlineImageSlider from HomePage
class InlineImageSlider extends StatefulWidget {
  final List<String> imageUrls;
  final String title;

  const InlineImageSlider({
    super.key,
    required this.imageUrls,
    required this.title,
  });

  @override
  State<InlineImageSlider> createState() => _InlineImageSliderState();
}

class _InlineImageSliderState extends State<InlineImageSlider>
    with AutomaticKeepAliveClientMixin {
  PageController? _pageController;
  int _currentIndex = 0;
  int _totalSlides = 0;
  bool _isInitialized = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeSlider();
  }

  @override
  void didUpdateWidget(InlineImageSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrls != widget.imageUrls) {
      _disposeController();
      _initializeSlider();
    }
  }

  void _initializeSlider() {
    _totalSlides =
        widget.imageUrls.isNotEmpty ? widget.imageUrls.length + 1 : 0;

    if (_totalSlides > 0) {
      _pageController = PageController(initialPage: 0, keepPage: false);
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } else {
      _pageController = null;
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }
    }
  }

  void _disposeController() {
    if (_pageController != null) {
      _pageController!.dispose();
      _pageController = null;
    }
    _isInitialized = false;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  Widget _buildNetworkImage(String imageUrl, {bool isGridItem = false}) {
    if (imageUrl.isEmpty) {
      return _buildPlaceholder(isGridItem);
    }

    // --- FIX START: Convert relative path to full URL ---
    final fullUrl = ApiConfig.generateFullImageUrl(imageUrl);
    // --- FIX END ---

    return ClipRRect(
      borderRadius: isGridItem
          ? BorderRadius.circular(12)
          : const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
      child: Image.network(
        fullUrl, // <--- Use fullUrl instead of imageUrl
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey[200]!,
                  Colors.grey[100]!,
                ],
              ),
            ),
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: isGridItem ? 2 : 3,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          // Optional: Print error for debugging
          // print("Error loading favorite image ($fullUrl): $error");
          return _buildPlaceholder(isGridItem);
        },
      ),
    );
  }

  Widget _buildPlaceholder(bool isGridItem) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey[300]!,
            Colors.grey[200]!,
          ],
        ),
        borderRadius: isGridItem ? BorderRadius.circular(12) : null,
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: isGridItem ? 28 : 48,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildGridView() {
    List<String?> displayImages = List.filled(4, null);

    for (int i = 0; i < 4 && i < widget.imageUrls.length; i++) {
      displayImages[i] = widget.imageUrls[i];
    }

    return Stack(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: () => _navigateToPage(1),
                child: _buildNetworkImage(displayImages[0] ?? '',
                    isGridItem: true),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _navigateToPage(2),
                      child: _buildNetworkImage(displayImages[1] ?? '',
                          isGridItem: true),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _navigateToPage(3),
                      child: _buildNetworkImage(displayImages[2] ?? '',
                          isGridItem: true),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _navigateToPage(4),
                      child: Stack(
                        children: [
                          _buildNetworkImage(displayImages[3] ?? '',
                              isGridItem: true),
                          if (widget.imageUrls.length > 4)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.photo_library,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '+${widget.imageUrls.length - 4}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
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
          bottom: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.photo_library, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  '${widget.imageUrls.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToPage(int page) {
    if (_pageController != null && _isInitialized && mounted) {
      _pageController!.animateToPage(
        page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.imageUrls.isEmpty) {
      return _buildPlaceholder(false);
    }

    if (widget.imageUrls.length == 1) {
      return _buildNetworkImage(widget.imageUrls[0]);
    }

    return Stack(
      children: [
        SizedBox(
          height: double.infinity,
          width: double.infinity,
          child: _isInitialized && _pageController != null
              ? PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    if (mounted) {
                      setState(() {
                        _currentIndex = index;
                      });
                    }
                  },
                  itemCount: _totalSlides,
                  physics: const ClampingScrollPhysics(),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildGridView();
                    } else {
                      final imageIndex = index - 1;
                      if (imageIndex < widget.imageUrls.length) {
                        return _buildNetworkImage(widget.imageUrls[imageIndex]);
                      }
                      return _buildPlaceholder(false);
                    }
                  },
                )
              : _buildGridView(),
        ),
        if (_totalSlides > 1 && _isInitialized)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _totalSlides,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
