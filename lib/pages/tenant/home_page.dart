import 'dart:async';

import 'package:flutter/material.dart';
import 'package:my_app/models/user_model.dart';
import 'package:my_app/models/listing.dart';
import 'package:my_app/services/property_service.dart';
//import 'package:my_app/services/search_service.dart';
import 'package:my_app/services/property_search_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
// Import your screen classes
import 'favorites_page.dart';
import 'messages_screen.dart' as messaging;
import 'profile_screen.dart';
import 'property_details_page.dart';

class HomePage extends StatefulWidget {
  final User user;

  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _currentIndex = 0;
  final PropertyService _propertyService = PropertyService();
  bool _isLoading = true;
  List<Listing> _allListings = [];
  int _currentPage = 1;
  String? _errorMessage;
  final List<String> _debugLog = [];

  // Favorites management
  Set<String> _favoriteIds = {};

  // Search and filter variables
  final TextEditingController _searchController = TextEditingController();
  final String _searchQuery = '';

  // Animation controllers
  late AnimationController _animationController;
  late AnimationController _searchAnimationController;
  late AnimationController _heartAnimationController;

  // Enhanced search variables
  final PropertySearchService _searchService = PropertySearchService();
  List<SearchLocation> _searchSuggestions = [];
  List<PropertyListing> _searchResults = [];
  SearchLocation? _selectedLocation;
  bool _showSuggestions = false;
  bool _isSearching = false;
  bool _isLoadingProperties = false;
  Timer? _searchDebounceTimer;
  final FocusNode _searchFocusNode = FocusNode();
  //int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadFavoriteIds();
    _loadInitialData();

    // Add search initialization
    _initializeSearch();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _heartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  void _initializeSearch() {
    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus) {
        _loadPopularLocations();
        setState(() {
          _showSuggestions = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    _searchAnimationController.dispose();
    _heartAnimationController.dispose();
    _searchFocusNode.dispose(); // Add this
    _searchDebounceTimer?.cancel(); // Add this
    super.dispose();
  }

  // Method to convert PropertyListing to Listing
  Listing _convertPropertyListingToListing(PropertyListing property) {
    return Listing(
      id: property.id.toString(),
      // userId: property.userId,
      title: property.title,
      address: property.address,
      postcode: property.postcode,
      description: property.description ?? '',
      price: property.price,
      bedrooms: property.bedrooms,
      bathrooms: property.bathrooms,
      areaSqft: property.areaSqft,
      availableFrom:
          DateTime.tryParse(property.availableFrom) ?? DateTime.now(),
      minimumTenure: property.minimumTenure,
      status: property.status,
      createdAt: DateTime.now(), // Default value since not in PropertyListing
      updatedAt: DateTime.now(), // Default value since not in PropertyListing
      imageUrls: [], // You'll need to fetch these separately or add to PropertyListing model
    );
  }

  // Load favorite IDs from SharedPreferences
  Future<void> _loadFavoriteIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesList = prefs.getStringList('favorite_listings') ?? [];
      setState(() {
        _favoriteIds = favoritesList.toSet();
      });
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  // Save favorite IDs to SharedPreferences
  Future<void> _saveFavoriteIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('favorite_listings', _favoriteIds.toList());
    } catch (e) {
      print('Error saving favorites: $e');
    }
  }

  // Toggle favorite status
  Future<void> _toggleFavorite(Listing listing) async {
    final listingId = listing.id.toString();

    setState(() {
      if (_favoriteIds.contains(listingId)) {
        _favoriteIds.remove(listingId);
      } else {
        _favoriteIds.add(listingId);
      }
    });

    // Save to persistent storage
    await _saveFavoriteIds();

    // Animate heart
    _heartAnimationController.forward().then((_) {
      _heartAnimationController.reverse();
    });

    // Show feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _favoriteIds.contains(listingId)
                ? 'Added to favorites'
                : 'Removed from favorites',
          ),
          backgroundColor: _favoriteIds.contains(listingId)
              ? const Color(0xFF48BB78)
              : const Color(0xFFED8936),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _loadInitialData() async {
    _addDebugLog('🔄 Starting to load initial data...');
    await _loadAllListings();
  }

  Future<void> _loadAllListings() async {
    _addDebugLog('📋 Loading all listings...');

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _allListings.clear();
      });

      _addDebugLog('🌐 Making API call through PropertyService...');
      final result = await _propertyService.getAllListings(
        page: _currentPage,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      _addDebugLog('✅ PropertyService call successful');
      _addDebugLog(
          '📊 Received ${(result['listings'] as List).length} listings');

      if (!mounted) return;

      final rawListings = result['listings'] as List;
      final parsedListings = <Listing>[];

      for (int i = 0; i < rawListings.length; i++) {
        try {
          final listing = Listing.fromJson(rawListings[i]);
          parsedListings.add(listing);
          _addDebugLog('✅ Parsed listing $i: ${listing.title}');
        } catch (e) {
          _addDebugLog('❌ Failed to parse listing $i: $e');
        }
      }

      setState(() {
        _allListings = parsedListings;
        _isLoading = false;
        _errorMessage = null;
      });

      // Start animations
      _animationController.forward();
      _searchAnimationController.forward();

      _addDebugLog(
          '🏠 UI updated successfully with ${_allListings.length} listings');
    } catch (e) {
      _addDebugLog('❌ Error: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _addDebugLog(String message) {
    print(message);
    _debugLog.add(message);
    if (_debugLog.length > 10) {
      _debugLog.removeAt(0);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();

      // Get all keys that need to be preserved
      final favoritesToPreserve =
          prefs.getStringList('favorite_listings') ?? [];

      // Remove only user-related data, not favorites
      await prefs.remove('user_data');
      await prefs.remove('auth_token');
      await prefs.remove('user_id');
      // Add any other user-specific keys you want to remove

      // Make sure favorites are still saved
      await prefs.setStringList('favorite_listings', favoritesToPreserve);

      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  Future<void> _loadPopularLocations() async {
    try {
      final suggestions = await _searchService.searchLocationsWithCount(
        query: '',
        limit: 5,
      );
      if (mounted) {
        setState(() {
          _searchSuggestions = suggestions;
        });
      }
    } catch (e) {
      print('Error loading popular locations: $e');
    }
  }

  void _onSearchChanged(String query) {
    _searchDebounceTimer?.cancel();

    if (_selectedLocation != null && _selectedLocation!.name != query) {
      setState(() {
        _selectedLocation = null;
        _searchResults = [];
      });
    }

    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (query.isNotEmpty) {
        _performLocationSearch(query);
      } else {
        setState(() {
          _searchSuggestions = [];
          _isSearching = false;
        });
        _loadPopularLocations();
      }
    });
  }

  Future<void> _performLocationSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final suggestions = await _searchService.searchLocationsWithCount(
        query: query,
        limit: 5,
      );

      if (mounted) {
        setState(() {
          _searchSuggestions = suggestions;
          _isSearching = false;
        });
      }
    } catch (e) {
      print('Search error: $e');
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _selectLocation(SearchLocation location) async {
    _searchController.text = location.name;
    setState(() {
      _showSuggestions = false;
      _selectedLocation = location;
      _currentPage = 1;
    });
    _searchFocusNode.unfocus();

    // Load properties for this location
    await _loadPropertiesForLocation(location);
  }

  // Let's fix the _loadPropertiesForLocation method with debugging
  Future<void> _loadPropertiesForLocation(SearchLocation location,
      {int page = 1}) async {
    setState(() {
      _isLoadingProperties = true;
    });

    try {
      final response = await _searchService.searchPropertiesByLocation(
        locationId: location.id,
        locationName: location.name,
        page: page,
        limit: 10,
      );

      if (mounted) {
        setState(() {
          if (page == 1) {
            _searchResults = response.properties;
          } else {
            _searchResults.addAll(response.properties);
          }
          _currentPage = response.page;
          _totalPages = response.totalPages;
          _isLoadingProperties = false;
        });

        // Show result count
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Found ${response.total} properties in ${location.name}'),
            backgroundColor: const Color(0xFF48BB78),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error loading properties: $e');
      if (mounted) {
        setState(() {
          _isLoadingProperties = false;
        });
      }
    }
  }

  // 4. Update _clearSearch to properly reset state
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _showSuggestions = false;
      _searchSuggestions = [];
      _searchResults = []; // Clear search results
      _selectedLocation = null;
    });
    _searchFocusNode.unfocus();
    // Reload all listings
    _loadAllListings();
  }

  // Enhanced search bar widget
  Widget _buildModernSearchBar() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _searchAnimationController,
        curve: Curves.easeOutBack,
      )),
      child: FadeTransition(
        opacity: _searchAnimationController,
        child: Container(
          margin: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Search Input
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Search locations (e.g., Taman Bukit Tambun)...',
                    hintStyle: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 16,
                    ),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF667EEA).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _isSearching
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF667EEA)),
                              ),
                            )
                          : const Icon(
                              Icons.search,
                              color: Color(0xFF667EEA),
                              size: 24,
                            ),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: _clearSearch,
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: const BorderSide(
                        color: Color(0xFF667EEA),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  style: const TextStyle(fontSize: 16),
                  onChanged: _onSearchChanged,
                  onSubmitted: (value) {
                    if (value.isNotEmpty && _searchSuggestions.isNotEmpty) {
                      _selectLocation(_searchSuggestions.first);
                    }
                  },
                ),
              ),

              // Selected location indicator
              if (_selectedLocation != null)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667EEA).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Color(0xFF667EEA),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Showing properties in ${_selectedLocation!.name}',
                        style: const TextStyle(
                          color: Color(0xFF667EEA),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

              // Search Suggestions
              if (_showSuggestions) _buildSearchSuggestions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    if (_searchSuggestions.isEmpty && !_isSearching) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_searchController.text.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.trending_up, color: Colors.grey[600], size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Popular Locations',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: _searchSuggestions.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: Colors.grey[200],
              indent: 16,
              endIndent: 16,
            ),
            itemBuilder: (context, index) {
              final suggestion = _searchSuggestions[index];
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667EEA).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    suggestion.name.startsWith('Taman')
                        ? Icons.home_work
                        : Icons.location_city,
                    color: const Color(0xFF667EEA),
                    size: 20,
                  ),
                ),
                title: Text(
                  suggestion.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: suggestion.subtitle != null
                    ? Text(
                        suggestion.subtitle!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      )
                    : null,
                trailing: const Icon(
                  Icons.north_west,
                  color: Colors.grey,
                  size: 16,
                ),
                onTap: () => _selectLocation(suggestion),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // Property card widget for search results
  Widget _buildSearchResultCard(PropertyListing property, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Navigate to property details
            print('View property: ${property.title}');
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Location Match
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            property.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3748),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (property.locationMatch != null)
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF667EEA).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                property.locationMatch!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF667EEA),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        property.formattedPrice ?? 'RM ${property.price}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Address
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.grey[600], size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${property.address}, ${property.postcode}',
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

                const SizedBox(height: 16),

                // Property Details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildPropertyDetail(
                      icon: Icons.bed,
                      value: '${property.bedrooms}',
                      label: 'Beds',
                    ),
                    _buildPropertyDetail(
                      icon: Icons.bathtub,
                      value: '${property.bathrooms}',
                      label: 'Baths',
                    ),
                    _buildPropertyDetail(
                      icon: Icons.square_foot,
                      value: '${property.areaSqft}',
                      label: 'sqft',
                    ),
                    _buildPropertyDetail(
                      icon: Icons.calendar_today,
                      value: property.formattedDate ?? property.availableFrom,
                      label: 'Available',
                    ),
                  ],
                ),

                if (property.description != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    property.description!,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyDetail({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF667EEA), size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // Update _buildPropertyCard to show location match badge
  Widget _buildPropertyCard(Listing listing, int index) {
    final isFavorite = _favoriteIds.contains(listing.id.toString());

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
                    isFavorite: _favoriteIds.contains(listing.id.toString()),
                    onFavoriteToggle: _toggleFavorite,
                    user: widget.user,
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
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color:
                                    isFavorite ? Colors.red : Colors.grey[600],
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Location match badge (only show if searching by location)
                      if (_selectedLocation != null)
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF667EEA).withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _selectedLocation!.name,
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

  Widget _buildErrorDisplay() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red[50]!,
            Colors.red[25] ?? Colors.red[50]!,
          ],
        ),
        border: Border.all(color: Colors.red[300]!),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.error_outline, color: Colors.red[700], size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Error Loading Properties',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _errorMessage ?? 'Unknown error occurred',
                  style: TextStyle(
                    color: Colors.red[600],
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

  // Update the explore screen to show search results
  Widget _buildExploreScreen() {
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
        onRefresh: () async {
          if (_selectedLocation != null) {
            await _loadPropertiesForLocation(_selectedLocation!);
          } else {
            await _loadAllListings();
          }
        },
        color: const Color(0xFF667EEA),
        child: GestureDetector(
          onTap: () {
            if (_showSuggestions) {
              setState(() {
                _showSuggestions = false;
              });
              _searchFocusNode.unfocus();
            }
          },
          child: Column(
            children: [
              // Enhanced Search Bar
              _buildModernSearchBar(),

              // Error Display
              if (_errorMessage != null) _buildErrorDisplay(),

              // Content Area
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Replace your _buildContent method with this:
  // 3. Simplified _buildContent method
  Widget _buildContent() {
    // If loading
    if (_isLoadingProperties || _isLoading) {
      return _buildLoadingState();
    }

    // Determine which data to show
    final bool showingSearchResults =
        _selectedLocation != null && _searchResults.isNotEmpty;
    final itemCount =
        showingSearchResults ? _searchResults.length : _allListings.length;

    // If no data
    if (itemCount == 0) {
      if (_selectedLocation != null) {
        return _buildNoResultsState();
      }
      return _buildEmptyState();
    }

    // Build the list
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (showingSearchResults) {
          // For search results, convert on the fly
          final property = _searchResults[index];
          final listing = _createListingFromProperty(property);
          return _buildPropertyCard(listing, index);
        } else {
          // For regular listings, use as is
          return _buildPropertyCard(_allListings[index], index);
        }
      },
    );
  }

  // 2. Add this helper method to create a Listing from PropertyListing
  Listing _createListingFromProperty(PropertyListing property) {
    // Use default images if none provided
    final images = property.imageUrls.isNotEmpty
        ? property.imageUrls
        : [
            'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800',
            'https://images.unsplash.com/photo-1560449752-8d7085b7b162?w=800',
            'https://images.unsplash.com/photo-1560448075-cbc16bb4af8e?w=800',
          ];

    return Listing(
      id: property.id.toString(), // Convert to String
      title: property.title,
      address: property.address,
      postcode: property.postcode,
      description: property.description ?? '',
      price: property.price,
      bedrooms: property.bedrooms,
      bathrooms: property.bathrooms,
      areaSqft: property.areaSqft,
      availableFrom:
          DateTime.tryParse(property.availableFrom) ?? DateTime.now(),
      minimumTenure: property.minimumTenure,
      status: property.status,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      imageUrls: images,
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No properties found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No properties available in ${_selectedLocation?.name}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _clearSearch,
            icon: const Icon(Icons.clear),
            label: const Text('Clear Search'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
            'Finding your perfect home...',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF4A5568),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we load the best properties',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
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
                    const Color(0xFF667EEA).withOpacity(0.1),
                    const Color(0xFF764BA2).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.home_work_outlined,
                size: 80,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'No Properties Found',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'We couldn\'t find any properties matching your search.\nTry adjusting your filters or search terms.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
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
              child: ElevatedButton.icon(
                onPressed: _loadAllListings,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667EEA),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return _buildExploreScreen();
      case 1:
        return FavoritesPage(
          user: widget.user,
          favoriteIds: _favoriteIds,
          onFavoriteToggle: _toggleFavorite,
          onFavoritesChanged: () {
            // Callback to refresh when favorites change in FavoritesPage
            setState(() {
              // This will refresh the HomePage to reflect changes
            });
          },
        );
      // case 2:
      //   return MapPage(user: widget.user);
      case 2:
        // Convert string ID to int for MessagesScreen with error handling
        try {
          return messaging.MessagesScreen(
            currentUserId: int.parse(widget.user.id),
          );
        } catch (e) {
          // Handle case where user ID is not a valid integer
          print('Error parsing user ID: ${widget.user.id}');
          return const Center(
            child: Text(
              'Error: Invalid user ID format',
              style: TextStyle(color: Colors.red),
            ),
          );
        }
      case 3:
        return ProfileScreen(user: widget.user);
      default:
        return _buildExploreScreen();
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
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.home,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'SmartStay',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: _logout,
              tooltip: 'Logout',
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _getCurrentScreen(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF667EEA),
            unselectedItemColor: Colors.grey[400],
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.explore_outlined),
                activeIcon: Icon(Icons.explore),
                label: 'Explore',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite_border),
                activeIcon: Icon(Icons.favorite),
                label: 'Favorites',
              ),
              // BottomNavigationBarItem(
              //   icon: Icon(Icons.map_outlined),
              //   activeIcon: Icon(Icons.map),
              //   label: 'Map',
              // ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline),
                activeIcon: Icon(Icons.chat_bubble),
                label: 'Messages',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Enhanced InlineImageSlider (same as in ListingsPage)
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

    return ClipRRect(
      borderRadius: isGridItem
          ? BorderRadius.circular(12)
          : const BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
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
