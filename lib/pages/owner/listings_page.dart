import 'package:flutter/material.dart';
import 'package:my_app/models/listing.dart';
import 'package:my_app/pages/owner/add_listing_page.dart';
import 'package:my_app/pages/owner/property_details_page.dart';
import 'package:my_app/services/database_service.dart';
import 'package:intl/intl.dart';

class ListingsPage extends StatefulWidget {
  const ListingsPage({super.key});

  @override
  State<ListingsPage> createState() => _ListingsPageState();
}

class _ListingsPageState extends State<ListingsPage>
    with AutomaticKeepAliveClientMixin {
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = true;
  List<Listing> _listings = [];
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMorePages = false;
  bool _isLoadingMore = false; // Add this flag

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  Future<void> _loadListings({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _listings.clear();
        _isLoading = true;
      });
    }

    if (!refresh && _listings.isEmpty) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final result = await _databaseService.getListings(page: _currentPage);

      if (!mounted) return; // Check if widget is still mounted

      final listings = (result['listings'] as List)
          .map((json) => Listing.fromJson(json))
          .toList();

      setState(() {
        if (refresh || _currentPage == 1) {
          _listings = listings;
        } else {
          _listings.addAll(listings);
        }
        _totalPages = result['pages'] ?? 1;
        _hasMorePages = _currentPage < _totalPages;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
      // Handle error - maybe show a snackbar
      print('Error loading listings: $e');
    }
  }

  void _loadMoreListings() {
    if (_hasMorePages && !_isLoading && !_isLoadingMore) {
      setState(() {
        _currentPage++;
        _isLoadingMore = true;
      });
      _loadListings();
    }
  }

  Widget _buildInlineImageSlider(List<String> imageUrls, String title) {
    if (imageUrls.isEmpty) {
      return Container(
        height: 200,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
        child: _buildPlaceholder('No Images'),
      );
    }

    return SizedBox(
      height: 200,
      child: InlineImageSlider(
        key: ValueKey(
            '${title}_${imageUrls.hashCode}_${imageUrls.length}'), // Better key
        imageUrls: imageUrls,
        title: title,
      ),
    );
  }

  Widget _buildPlaceholder(String message) {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 40,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Property Listings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddListingPage(),
                ),
              );

              if (result == true && mounted) {
                _loadListings(refresh: true);
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadListings(refresh: true),
        child: _isLoading && _listings.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _listings.isEmpty
                ? _buildEmptyWidget()
                : NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification scrollInfo) {
                      if (scrollInfo.metrics.pixels ==
                              scrollInfo.metrics.maxScrollExtent &&
                          !_isLoadingMore) {
                        _loadMoreListings();
                        return true;
                      }
                      return false;
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _listings.length + (_hasMorePages ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _listings.length) {
                          return const Center(
                              child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ));
                        }

                        final listing = _listings[index];
                        return Card(
                          key: ValueKey(
                              listing.id), // Add unique key for each card
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInlineImageSlider(
                                  listing.imageUrls, listing.title),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      listing.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on,
                                            size: 16, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            '${listing.address}, ${listing.postcode}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'RM ${listing.price.toStringAsFixed(2)} / month',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                              color: Theme.of(context)
                                                  .primaryColor,
                                              fontWeight: FontWeight.bold),
                                    ),
                                    if (listing.description.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        listing.description,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        _buildInfoChip(Icons.bed,
                                            '${listing.bedrooms} Bed'),
                                        const SizedBox(width: 8),
                                        _buildInfoChip(Icons.bathroom,
                                            '${listing.bathrooms} Bath'),
                                        const SizedBox(width: 8),
                                        _buildInfoChip(Icons.square_foot,
                                            '${listing.areaSqft} sqft'),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today,
                                            size: 16, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                            'Available from: ${DateFormat('d MMM y').format(listing.availableFrom)}'),
                                        const SizedBox(width: 16),
                                        const Icon(Icons.timelapse,
                                            size: 16, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                            'Min: ${listing.minimumTenure} month'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    right: 12, bottom: 12),
                                child: Align(
                                  alignment: Alignment.bottomRight,
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              PropertyDetailsPage(
                                            listing: listing,
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text('View Details'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Listings Found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'There are no property listings available at the moment.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _loadListings(refresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

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
  bool _isInitialized = false; // Renamed for clarity

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Initialize immediately instead of using postFrameCallback
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

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey[200],
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: isGridItem ? 1 : 2,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildPlaceholder(isGridItem);
      },
    );
  }

  Widget _buildPlaceholder(bool isGridItem) {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: isGridItem ? 20 : 40,
              color: Colors.grey[400],
            ),
            if (!isGridItem) ...[
              const SizedBox(height: 4),
              Text(
                'No Image',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
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
                child: Container(
                  decoration: const BoxDecoration(
                    borderRadius:
                        BorderRadius.only(topLeft: Radius.circular(4)),
                  ),
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.only(topLeft: Radius.circular(4)),
                    child: _buildNetworkImage(displayImages[0] ?? '',
                        isGridItem: true),
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
                      onTap: () => _navigateToPage(2),
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          borderRadius:
                              BorderRadius.only(topRight: Radius.circular(4)),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(4)),
                          child: _buildNetworkImage(displayImages[1] ?? '',
                              isGridItem: true),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _navigateToPage(3),
                      child: SizedBox(
                        width: double.infinity,
                        child: ClipRRect(
                          child: _buildNetworkImage(displayImages[2] ?? '',
                              isGridItem: true),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _navigateToPage(4),
                      child: Stack(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ClipRRect(
                              child: _buildNetworkImage(displayImages[3] ?? '',
                                  isGridItem: true),
                            ),
                          ),
                          if (widget.imageUrls.length > 4)
                            Container(
                              width: double.infinity,
                              color: Colors.black.withOpacity(0.6),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.photo_library,
                                        color: Colors.white, size: 16),
                                    const SizedBox(height: 2),
                                    Text(
                                      '+${widget.imageUrls.length - 4}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold),
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
          bottom: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.photo_library, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${widget.imageUrls.length}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to handle navigation
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
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_outlined, size: 40, color: Colors.grey[400]),
              const SizedBox(height: 4),
              Text(
                'No Images',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    if (widget.imageUrls.length == 1) {
      return ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(4),
        ),
        child: _buildNetworkImage(widget.imageUrls[0]),
      );
    }

    // Always render the UI, but only enable functionality when initialized
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(4),
        topRight: Radius.circular(4),
      ),
      child: Stack(
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
                          return _buildNetworkImage(
                              widget.imageUrls[imageIndex]);
                        }
                        return Container(color: Colors.grey[200]);
                      }
                    },
                  )
                : _buildGridView(), // Show grid view while initializing
          ),
          if (_totalSlides > 1 && _isInitialized)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _totalSlides,
                  (index) => Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 8,
            left: 8,
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
                    _currentIndex == 0 ? Icons.grid_view : Icons.photo_library,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _currentIndex == 0
                        ? 'Grid View'
                        : '$_currentIndex/${widget.imageUrls.length}',
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
          if (_currentIndex == 0 &&
              widget.imageUrls.length > 1 &&
              _isInitialized)
            Positioned(
              bottom: 40,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Swipe for individual photos',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.swipe, color: Colors.white, size: 12),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
