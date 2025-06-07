import 'package:flutter/material.dart';
import 'package:my_app/models/listing.dart';
import 'package:my_app/pages/owner/add_listing_page.dart';
import 'package:my_app/pages/owner/property_details_page.dart';
import 'package:my_app/services/database_service.dart';
import 'package:intl/intl.dart';
import 'package:my_app/pages/owner/edit_listing_page.dart';
// Remove duplicate import: import 'package:my_app/pages/owner/edit_listing_page.dart';

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
  List<Listing> _filteredListings = [];
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMorePages = false;
  bool _isLoadingMore = false;

  // Add this variable to store current user ID
  String? _currentUserId;

  // Filter state
  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'Active', 'Inactive'];
  Map<String, int> _listingsCount = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  // Get current user ID
  Future<void> _initializeUser() async {
    _currentUserId = await _databaseService.currentUserId;
    print('🔑 Current User ID: $_currentUserId');

    if (_currentUserId != null) {
      _loadListings();
      _loadListingsCount();
    } else {
      print('❌ No user ID found - user not logged in');
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  Future<void> _loadListingsCount() async {
    if (_currentUserId == null) {
      print('❌ Cannot load listings count - no user ID');
      return;
    }

    try {
      final count = await _databaseService.getListingsCount(
        int.parse(_currentUserId!),
      );
      if (mounted) {
        setState(() {
          _listingsCount = count;
        });
      }
    } catch (e) {
      print('Error loading listings count: $e');
    }
  }

  Future<void> _loadListings({bool refresh = false}) async {
    if (_currentUserId == null) {
      print('❌ Cannot load listings - no user ID');
      return;
    }

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
      print(
          '🔄 Loading listings - Page: $_currentPage, Filter: $_selectedFilter, UserID: $_currentUserId');

      final result = await _databaseService.getListings(
        page: _currentPage,
        status: _selectedFilter,
        userId: int.parse(_currentUserId!),
      );

      print('📱 API Response: $result');

      if (!mounted) return;

      final listingsData = result['listings'];
      final listings = (listingsData != null && listingsData is List)
          ? listingsData.map((json) => Listing.fromJson(json)).toList()
          : <Listing>[];

      print('📋 Parsed ${listings.length} listings');

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
        _applyFilter();
      });
    } catch (e) {
      print('❌ Error loading listings: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _applyFilter() {
    setState(() {
      if (_selectedFilter == 'All') {
        _filteredListings = _listings;
      } else {
        final filterStatus = _selectedFilter.toLowerCase();
        _filteredListings = _listings
            .where((listing) => listing.status.toLowerCase() == filterStatus)
            .toList();
      }
    });
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
      _currentPage = 1;
    });
    _loadListings(refresh: true);
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

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filterOptions.map((filter) {
            final isSelected = _selectedFilter == filter;
            final count = _getFilterCount(filter);

            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => _onFilterChanged(filter),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.black : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Colors.black : Colors.grey[400]!,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        filter,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                      if (count > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            count.toString(),
                            style: TextStyle(
                              color:
                                  isSelected ? Colors.black : Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  int _getFilterCount(String filter) {
    switch (filter) {
      case 'All':
        return _listingsCount['total'] ?? 0;
      case 'Active':
        return _listingsCount['active'] ?? 0;
      case 'Inactive':
        return _listingsCount['inactive'] ?? 0;
      default:
        return 0;
    }
  }

  Widget _buildPropertyCard(Listing listing) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PropertyDetailsPage(listing: listing),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                child: (listing.imageUrls.isNotEmpty &&
                        listing.imageUrls[0].isNotEmpty)
                    ? Image.network(
                        listing.imageUrls[0],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildImagePlaceholder();
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return _buildImagePlaceholder();
                        },
                      )
                    : _buildImagePlaceholder(),
              ),
            ),

            // Content section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      listing.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: listing.isActive ? Colors.black : Colors.grey,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Address
                    Text(
                      listing.address,
                      style: TextStyle(
                        fontSize: 12,
                        color: listing.isActive
                            ? Colors.grey[600]
                            : Colors.grey[400],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Price
                    Text(
                      'RM ${NumberFormat('#,###').format(listing.price)}/month',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: listing.isActive
                            ? Colors.green[600]
                            : Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Property details
                    Row(
                      children: [
                        _buildDetailIcon(
                          Icons.bed_outlined,
                          listing.bedrooms.toString(),
                          listing.isActive,
                        ),
                        const SizedBox(width: 12),
                        _buildDetailIcon(
                          Icons.bathtub_outlined,
                          listing.bathrooms.toString(),
                          listing.isActive,
                        ),
                        const SizedBox(width: 12),
                        _buildDetailIcon(
                          Icons.square_foot,
                          '${listing.areaSqft}',
                          listing.isActive,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // More options button
            Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => _showMoreOptions(listing),
                child: Icon(
                  Icons.more_horiz,
                  color: listing.isActive ? Colors.grey : Colors.grey[400],
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailIcon(IconData icon, String count, bool isActive) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: isActive ? Colors.grey[600] : Colors.grey[400],
        ),
        const SizedBox(width: 4),
        Text(
          count,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Colors.grey[600] : Colors.grey[400],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(Icons.image_outlined, size: 30, color: Colors.grey[400]),
      ),
    );
  }

  void _showMoreOptions(Listing listing) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // View Details
            ListTile(
              leading:
                  Icon(Icons.visibility, color: Theme.of(context).primaryColor),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PropertyDetailsPage(listing: listing),
                  ),
                );
              },
            ),

            // Edit
            ListTile(
              leading: Icon(Icons.edit, color: Colors.blue[600]),
              title: const Text('Edit Property'),
              onTap: () {
                Navigator.pop(context);
                _editListing(listing);
              },
            ),

            // Activation/Deactivation toggle
            if (listing.isActive) ...[
              ListTile(
                leading:
                    Icon(Icons.pause_circle_outline, color: Colors.orange[600]),
                title: const Text('Deactivate Property'),
                subtitle: const Text('Hide from search results'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeactivateConfirmation(listing);
                },
              ),
            ] else if (listing.isInactive) ...[
              ListTile(
                leading:
                    Icon(Icons.play_circle_outline, color: Colors.green[600]),
                title: const Text('Activate Property'),
                subtitle: const Text('Show in search results'),
                onTap: () {
                  Navigator.pop(context);
                  _updateListingStatus(listing, 'active');
                },
              ),
            ],

            const Divider(),

            // Delete
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete Property',
                  style: TextStyle(color: Colors.red)),
              subtitle: const Text('Permanently remove this property'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(listing);
              },
            ),
          ],
        ),
      ),
    );
  }

  // EDIT FUNCTION - Updated to navigate to PropertyDetailsPage for editing
  Future<void> _editListing(Listing listing) async {
    try {
      // Navigate to PropertyDetailsPage and let it handle editing
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          // builder: (context) => PropertyDetailsPage(listing: listing),
          builder: (context) => EditListingPage(listing: listing),
        ),
      );

      // If the property was updated, refresh the listings
      if (result == true && mounted) {
        _showSuccessMessage('Property updated successfully');
        await _loadListings(refresh: true);
        await _loadListingsCount();
      }
    } catch (e) {
      _showErrorMessage('Failed to edit property: $e');
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

  // DELETE CONFIRMATION
  void _showDeleteConfirmation(Listing listing) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_outlined, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Property'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Are you sure you want to permanently delete "${listing.title}"?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone. All property data, images, and videos will be permanently removed.',
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
              _deleteListing(listing);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // UPDATE LISTING STATUS (ACTIVATE/DEACTIVATE)
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

      final success = await _databaseService.updateListingStatus(
        int.parse(listingId),
        newStatus,
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (success && mounted) {
        final message = newStatus == 'active'
            ? 'Property activated successfully'
            : 'Property deactivated successfully';

        _showSuccessMessage(message);
        await _loadListings(refresh: true);
        await _loadListingsCount();
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

  // DELETE LISTING
  Future<void> _deleteListing(Listing listing) async {
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

      final success = await _databaseService.deleteListing(
        int.parse(listingId),
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (success && mounted) {
        _showSuccessMessage('Property deleted successfully');
        await _loadListings(refresh: true);
        await _loadListingsCount();
      } else {
        if (mounted) {
          _showErrorMessage('Failed to delete property');
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (mounted) {
        _showErrorMessage('Error deleting property: $e');
      }
    }
  }

  // Helper methods for showing messages
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Show loading while getting user ID
    if (_currentUserId == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My properties',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AddListingPage(),
                  ),
                );

                if (result == true && mounted) {
                  _loadListings(refresh: true);
                  _loadListingsCount();
                }
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Post',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF140052),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterTabs(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _loadListings(refresh: true);
                await _loadListingsCount();
              },
              child: _isLoading && _filteredListings.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredListings.isEmpty
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
                            itemCount: _filteredListings.length +
                                (_hasMorePages ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _filteredListings.length) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              final listing = _filteredListings[index];
                              return _buildPropertyCard(listing);
                            },
                          ),
                        ),
            ),
          ),
        ],
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
              'No Properties Found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'There are no ${_selectedFilter.toLowerCase()} properties available.',
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
}
