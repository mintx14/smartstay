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
  bool get wantKeepAlive => false;

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
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: _filterOptions.map((filter) {
          final isSelected = _selectedFilter == filter;

          IconData getFilterIcon() {
            switch (filter) {
              case 'All':
                return Icons.apps_rounded;
              case 'Active':
                return Icons.check_circle;
              case 'Inactive':
                return Icons.pause_circle;
              default:
                return Icons.list;
            }
          }

          Color getFilterColor() {
            switch (filter) {
              case 'All':
                return const Color(0xFF190152);
              case 'Active':
                return const Color(0xFF27AE60);
              case 'Inactive':
                return const Color(0xFFE67E22);
              default:
                return const Color(0xFF190152);
            }
          }

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _onFilterChanged(filter),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? getFilterColor() : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isSelected ? getFilterColor() : Colors.grey[200]!,
                        width: isSelected ? 1.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: getFilterColor().withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          getFilterIcon(),
                          size: 20,
                          color: isSelected ? Colors.white : getFilterColor(),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          filter,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[700],
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
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
      onTap: () async {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PropertyDetailsPage(listing: listing),
          ),
        );

        if (result != null && mounted) {
          _loadListings(refresh: true);
          _loadListingsCount();
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              spreadRadius: 0,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section with status badge
            Stack(
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    color: Colors.grey[100],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: listing.imageUrls.isNotEmpty
                        ? PageView.builder(
                            itemCount: listing.imageUrls.length,
                            itemBuilder: (context, index) {
                              if (listing.imageUrls[index].isEmpty) {
                                return _buildImagePlaceholder();
                              }
                              return Image.network(
                                listing.imageUrls[index],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildImagePlaceholder();
                                },
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                    ),
                                  );
                                },
                              );
                            },
                          )
                        : _buildImagePlaceholder(),
                  ),
                ),
                // Image count badge if multiple images
                if (listing.imageUrls.length > 1)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.image,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${listing.imageUrls.length}',
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

            // Content section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title with status badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          listing.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: listing.isActive
                                ? const Color(0xFF1A1A1A)
                                : Colors.grey[500],
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Status badge next to title
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: listing.isActive
                              ? const Color(0xFF27AE60)
                              : const Color(0xFFE67E22),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              listing.isActive
                                  ? Icons.check_circle
                                  : Icons.pause_circle,
                              size: 11,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              listing.isActive ? 'Active' : 'Inactive',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Address with icon
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: listing.isActive
                            ? Colors.grey[600]
                            : Colors.grey[400],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          listing.address,
                          style: TextStyle(
                            fontSize: 13,
                            color: listing.isActive
                                ? Colors.grey[600]
                                : Colors.grey[400],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Property details
                  Row(
                    children: [
                      _buildDetailChip(
                        Icons.bed_outlined,
                        '${listing.bedrooms} Bed',
                        listing.isActive,
                      ),
                      const SizedBox(width: 10),
                      _buildDetailChip(
                        Icons.bathtub_outlined,
                        '${listing.bathrooms} Bath',
                        listing.isActive,
                      ),
                      const SizedBox(width: 10),
                      _buildDetailChip(
                        Icons.square_foot_outlined,
                        '${listing.areaSqft} sqft',
                        listing.isActive,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Price and action button row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Price
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RM ${NumberFormat('#,###').format(listing.price)}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: listing.isActive
                                  ? const Color(0xFF190152)
                                  : Colors.grey[400],
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'per month',
                            style: TextStyle(
                              fontSize: 12,
                              color: listing.isActive
                                  ? Colors.grey[600]
                                  : Colors.grey[400],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      // More options button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showMoreOptions(listing),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.more_horiz,
                              color: listing.isActive
                                  ? const Color(0xFF190152)
                                  : Colors.grey[400],
                              size: 24,
                            ),
                          ),
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
    );
  }

  Widget _buildDetailChip(IconData icon, String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFF0EDF8) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isActive ? const Color(0xFF190152) : Colors.grey[400],
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? const Color(0xFF190152) : Colors.grey[400],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Container(
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
                  leading: Icon(Icons.visibility,
                      color: Theme.of(context).primaryColor),
                  title: const Text('View Details'),
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            PropertyDetailsPage(listing: listing),
                      ),
                    );

                    // Refresh if data changed
                    if (result != null && mounted) {
                      _loadListings(refresh: true);
                      _loadListingsCount();
                    }
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
                    leading: Icon(Icons.pause_circle_outline,
                        color: Colors.orange[600]),
                    title: const Text('Deactivate Property'),
                    subtitle: const Text('Hide from search results'),
                    onTap: () {
                      Navigator.pop(context);
                      _showDeactivateConfirmation(listing);
                    },
                  ),
                ] else if (listing.isInactive) ...[
                  ListTile(
                    leading: Icon(Icons.play_circle_outline,
                        color: Colors.green[600]),
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
      // If result is not null (it could be 'true' OR a 'Listing' object now)
      if (result != null && mounted) {
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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF190152),
                Color(0xFF2D1B69),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row with title and actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Title
                      const Text(
                        'My Properties',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      // Post New button
                      ElevatedButton.icon(
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
                        icon: const Icon(Icons.add_circle_outline,
                            color: Colors.white, size: 20),
                        label: const Text(
                          'Post New',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                            side: const BorderSide(
                                color: Colors.white, width: 1.5),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Subtitle
                  Text(
                    'Manage and track your property listings',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
              color: const Color(0xFF190152),
              child: _isLoading && _filteredListings.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                      color: Color(0xFF190152),
                    ))
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
                            padding: const EdgeInsets.only(top: 8, bottom: 16),
                            itemCount: _filteredListings.length +
                                (_hasMorePages ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _filteredListings.length) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF190152),
                                    ),
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
    String getMessage() {
      switch (_selectedFilter) {
        case 'Active':
          return 'You don\'t have any active properties yet.';
        case 'Inactive':
          return 'You don\'t have any inactive properties.';
        default:
          return 'You haven\'t posted any properties yet.';
      }
    }

    IconData getIcon() {
      switch (_selectedFilter) {
        case 'Active':
          return Icons.home_work_outlined;
        case 'Inactive':
          return Icons.home_outlined;
        default:
          return Icons.add_home_outlined;
      }
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EDF8),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF190152).withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                getIcon(),
                size: 64,
                color: const Color(0xFF190152),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Properties Found',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              getMessage(),
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (_selectedFilter == 'All')
              ElevatedButton.icon(
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
                icon: const Icon(Icons.add_circle_outline, size: 20),
                label: const Text(
                  'Post Your First Property',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF190152),
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: const Color(0xFF190152).withOpacity(0.4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: () => _onFilterChanged('All'),
                icon: const Icon(Icons.view_list, size: 20),
                label: const Text(
                  'View All Properties',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF190152),
                  side: const BorderSide(
                    color: Color(0xFF190152),
                    width: 2,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
