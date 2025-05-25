import 'package:flutter/material.dart';
import 'package:my_app/models/listing.dart';
import 'package:my_app/pages/owner/add_listing_page.dart';
import 'package:my_app/services/database_service.dart';
import 'package:intl/intl.dart';

class ListingsPage extends StatefulWidget {
  const ListingsPage({super.key});

  @override
  State<ListingsPage> createState() => _ListingsPageState();
}

class _ListingsPageState extends State<ListingsPage> {
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = true;
  String _errorMessage = '';
  List<Listing> _listings = [];
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMorePages = false;

  // Add connection status
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _checkConnectionAndLoadListings();
  }

  @override
  void dispose() {
    _databaseService.dispose();
    super.dispose();
  }

  Future<void> _checkConnectionAndLoadListings() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Test connection first
      print('Testing server connection...');
      _isConnected = await _databaseService.testConnection();
      print('Connection test result: $_isConnected');

      if (!_isConnected) {
        setState(() {
          _errorMessage =
              'Unable to connect to server. Please check your network connection and server configuration.';
          _isLoading = false;
        });
        return;
      }

      await _loadListings();
    } catch (e) {
      print('Error in connection check: $e');
      setState(() {
        _errorMessage = 'Failed to initialize: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadListings({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _listings.clear();
      });
    }

    try {
      setState(() {
        if (!refresh && _listings.isEmpty) {
          _isLoading = true;
        }
        _errorMessage = '';
      });

      print('Loading listings - Page: $_currentPage');
      final result = await _databaseService.getListings(page: _currentPage);
      print('Received listings result: ${result.keys}');

      final listings = (result['listings'] as List)
          .map((json) => Listing.fromJson(json))
          .toList();

      print('Parsed ${listings.length} listings');

      // Debug: Print image URLs for first few listings
      for (int i = 0; i < listings.length && i < 3; i++) {
        print('Listing ${i + 1} (${listings[i].title}):');
        print('  Image URLs count: ${listings[i].imageUrls.length}');
        for (int j = 0; j < listings[i].imageUrls.length; j++) {
          print('  Image $j: ${listings[i].imageUrls[j]}');
        }
      }

      setState(() {
        if (refresh || _currentPage == 1) {
          _listings = listings;
        } else {
          _listings.addAll(listings);
        }
        _totalPages = result['pages'] ?? 1;
        _hasMorePages = _currentPage < _totalPages;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading listings: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _loadMoreListings() {
    if (_hasMorePages && !_isLoading) {
      setState(() {
        _currentPage++;
      });
      _loadListings();
    }
  }

  Widget _buildImageGrid(List<String> imageUrls) {
    print('Building image grid with ${imageUrls.length} URLs');

    // Ensure we have exactly 4 slots, fill with placeholders if needed
    List<String?> displayImages = List.filled(4, null);

    for (int i = 0; i < 4 && i < imageUrls.length; i++) {
      displayImages[i] = imageUrls[i];
      print('Display image $i: ${displayImages[i]}');
    }

    return Container(
      height: 200,
      width: double.infinity,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(4),
        ),
      ),
      child: Stack(
        children: [
          Row(
            children: [
              // Large image on the left (takes 2/3 of width)
              Expanded(
                flex: 2,
                child: Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(4),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                    ),
                    child: _buildNetworkImage(displayImages[0], isLarge: true),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              // Column of 3 smaller images on the right (takes 1/3 of width)
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    // Top right image
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(4),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(4),
                          ),
                          child: _buildNetworkImage(displayImages[1]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Middle right image
                    Expanded(
                      child: SizedBox(
                        width: double.infinity,
                        child: ClipRRect(
                          child: _buildNetworkImage(displayImages[2]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Bottom right image
                    Expanded(
                      child: SizedBox(
                        width: double.infinity,
                        child: ClipRRect(
                          child: _buildNetworkImage(displayImages[3]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Optional: Add image count indicator for additional images
          if (imageUrls.length > 4)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+${imageUrls.length - 4}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          // Photo count indicator
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
                  const Icon(
                    Icons.photo_library,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${imageUrls.length}',
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
    );
  }

  Widget _buildNetworkImage(String? imageUrl, {bool isLarge = false}) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildPlaceholder(isLarge, 'No Image');
    }

    print('Loading image: $imageUrl');

    // Validate URL format before attempting to load
    Uri? uri;
    try {
      uri = Uri.parse(imageUrl);
      if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
        print('Invalid URL scheme for: $imageUrl');
        return _buildPlaceholder(isLarge, 'Invalid URL');
      }
    } catch (e) {
      print('URL parsing error for $imageUrl: $e');
      return _buildPlaceholder(isLarge, 'Invalid URL');
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      height: double.infinity,
      width: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          print('Image loaded successfully: $imageUrl');
          return child;
        }

        print(
            'Loading image: $imageUrl - ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes}');
        return Container(
          color: Colors.grey[200],
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        // Enhanced error logging
        print('═══ IMAGE LOAD ERROR ═══');
        print('URL: $imageUrl');
        print('Error type: ${error.runtimeType}');
        print('Error details: $error');
        print('Stack trace: $stackTrace');
        print('══════════════════════');

        return _buildPlaceholder(isLarge, 'Load Failed', isError: true);
      },
    );
  }

  Widget _buildPlaceholder(bool isLarge, String message,
      {bool isError = false}) {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.image_outlined,
              size: isLarge ? 40 : 20,
              color: isError ? Colors.red[400] : Colors.grey[400],
            ),
            if (isLarge) ...[
              const SizedBox(height: 4),
              Text(
                message,
                style: TextStyle(
                  fontSize: 10,
                  color: isError ? Colors.red[400] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    if (_isConnected) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.orange[100],
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange[800], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Connection issue detected. Some features may not work properly.',
              style: TextStyle(color: Colors.orange[800], fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: _checkConnectionAndLoadListings,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Property Listings'),
        actions: [
          if (_isConnected)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AddListingPage(),
                  ),
                );

                if (result == true) {
                  _loadListings(refresh: true);
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _checkConnectionAndLoadListings(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildConnectionStatus(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadListings(refresh: true),
              child: _isLoading && _listings.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage.isNotEmpty && _listings.isEmpty
                      ? _buildErrorWidget()
                      : _listings.isEmpty
                          ? _buildEmptyWidget()
                          : NotificationListener<ScrollNotification>(
                              onNotification: (ScrollNotification scrollInfo) {
                                if (scrollInfo.metrics.pixels ==
                                    scrollInfo.metrics.maxScrollExtent) {
                                  _loadMoreListings();
                                  return true;
                                }
                                return false;
                              },
                              child: ListView.builder(
                                padding: const EdgeInsets.all(8),
                                itemCount:
                                    _listings.length + (_hasMorePages ? 1 : 0),
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
                                    margin: const EdgeInsets.only(bottom: 16),
                                    elevation: 2,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Updated image grid layout
                                        GestureDetector(
                                          onTap: () {
                                            // Optional: Add image gallery view
                                            _showImageDebugInfo(listing);
                                          },
                                          child: _buildImageGrid(
                                              listing.imageUrls),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
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
                                                      size: 16,
                                                      color: Colors.grey),
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
                                                        fontWeight:
                                                            FontWeight.bold),
                                              ),
                                              if (listing
                                                  .description.isNotEmpty) ...[
                                                const SizedBox(height: 8),
                                                Text(
                                                  listing.description,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium,
                                                  maxLines: 3,
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
                                                  _buildInfoChip(
                                                      Icons.square_foot,
                                                      '${listing.areaSqft} sqft'),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  const Icon(
                                                      Icons.calendar_today,
                                                      size: 16,
                                                      color: Colors.grey),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                      'Available from: ${DateFormat('d MMM y').format(listing.availableFrom)}'),
                                                  const SizedBox(width: 16),
                                                  const Icon(Icons.timelapse,
                                                      size: 16,
                                                      color: Colors.grey),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                      'Min: ${listing.minimumTenure}'),
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
                                                // Navigate to detail page
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
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _checkConnectionAndLoadListings,
              child: const Text('Try Again'),
            ),
          ],
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

  void _showImageDebugInfo(Listing listing) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Debug: ${listing.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Image URLs (${listing.imageUrls.length}):'),
            const SizedBox(height: 8),
            ...listing.imageUrls.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${entry.key + 1}. ${entry.value}',
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              );
            }),
            if (listing.imageUrls.isEmpty)
              const Text('No image URLs found',
                  style: TextStyle(color: Colors.red)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
