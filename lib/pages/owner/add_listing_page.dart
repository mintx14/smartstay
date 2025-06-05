import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:my_app/models/listing.dart';
import 'package:my_app/services/database_service.dart';

class AddListingPage extends StatefulWidget {
  const AddListingPage({super.key});

  @override
  State<AddListingPage> createState() => _AddListingPageState();
}

class _AddListingPageState extends State<AddListingPage> {
  final _formKey = GlobalKey<FormState>();
  final _propertyNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _postcodeController = TextEditingController();
  final _priceController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _areaSqftController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _availableFrom = DateTime.now();
  String _minimumTenure = '12 months';
  final List<File> _selectedImages = [];
  final List<File> _selectedVideos = [];
  final Map<String, VideoPlayerController> _videoControllers = {};
  final DatabaseService _databaseService = DatabaseService();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((image) => File(image.path)));
      });
    }
  }

  Future<void> _pickVideos() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      final videoFile = File(video.path);
      // Initialize video controller
      final controller = VideoPlayerController.file(videoFile);
      await controller.initialize();

      setState(() {
        _selectedVideos.add(videoFile);
        _videoControllers[video.path] = controller;
      });
    }
  }

  Future<void> _captureImage() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _selectedImages.add(File(photo.path));
      });
    }
  }

  Future<void> _captureVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
    if (video != null) {
      final videoFile = File(video.path);
      final controller = VideoPlayerController.file(videoFile);
      await controller.initialize();

      setState(() {
        _selectedVideos.add(videoFile);
        _videoControllers[video.path] = controller;
      });
    }
  }

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Add Media',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMediaOption(
                  icon: Icons.photo_library,
                  label: 'Gallery Photos',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImages();
                  },
                ),
                _buildMediaOption(
                  icon: Icons.camera_alt,
                  label: 'Take Photo',
                  onTap: () {
                    Navigator.pop(context);
                    _captureImage();
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMediaOption(
                  icon: Icons.video_library,
                  label: 'Gallery Videos',
                  onTap: () {
                    Navigator.pop(context);
                    _pickVideos();
                  },
                ),
                _buildMediaOption(
                  icon: Icons.videocam,
                  label: 'Record Video',
                  onTap: () {
                    Navigator.pop(context);
                    _captureVideo();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Check if at least 4 media files are selected
      final totalMedia = _selectedImages.length + _selectedVideos.length;
      if (totalMedia < 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Please upload at least 4 images or videos of the property.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        String? userId = await _databaseService.currentUserId;
        if (userId == null) {
          throw Exception("You must be logged in to add a listing");
        }

        // Upload images and videos
        List<String> allMediaUrls = [];

        if (_selectedImages.isNotEmpty) {
          List<String> imagePaths =
              _selectedImages.map((file) => file.path).toList();
          List<String> imageUrls =
              await _databaseService.uploadImages(imagePaths, userId);
          allMediaUrls.addAll(imageUrls);
        }

        if (_selectedVideos.isNotEmpty) {
          List<String> videoPaths =
              _selectedVideos.map((file) => file.path).toList();
          List<String> videoUrls =
              await _databaseService.uploadVideos(videoPaths, userId);
          allMediaUrls.addAll(videoUrls);
        }

        // Create and save the listing with all media URLs in imageUrls field
        final listing = Listing(
          id: '',
          title: _propertyNameController.text,
          address: _addressController.text,
          postcode: _postcodeController.text,
          description: _descriptionController.text,
          imageUrls: allMediaUrls, // All media URLs go here
          price: double.parse(_priceController.text),
          bedrooms: int.parse(_bedroomsController.text),
          bathrooms: int.parse(_bathroomsController.text),
          areaSqft: int.parse(_areaSqftController.text),
          availableFrom: _availableFrom,
          minimumTenure: _minimumTenure,
          status: 'Active',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _databaseService.addListing(listing);

        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Property listing added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding listing: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Add Property Listing'),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Property Details Card
                    _buildSectionCard(
                      title: 'Property Details',
                      icon: Icons.home,
                      children: [
                        _buildModernTextField(
                          controller: _propertyNameController,
                          label: 'Property Name',
                          hint: 'e.g., Cozy Apartment, Modern Townhouse',
                          prefixIcon: Icons.home_work,
                          validator: (value) =>
                              value!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        _buildModernTextField(
                          controller: _addressController,
                          label: 'Address',
                          hint: 'Street address, unit number, etc.',
                          prefixIcon: Icons.location_on,
                          maxLines: 2,
                          validator: (value) =>
                              value!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        _buildModernTextField(
                          controller: _postcodeController,
                          label: 'Postcode',
                          hint: 'Enter postcode',
                          prefixIcon: Icons.pin_drop,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (value) =>
                              value!.isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),

                    // Property Features Card
                    _buildSectionCard(
                      title: 'Property Features',
                      icon: Icons.featured_play_list,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildFeatureField(
                                controller: _bedroomsController,
                                label: 'Bedrooms',
                                icon: Icons.bed,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildFeatureField(
                                controller: _bathroomsController,
                                label: 'Bathrooms',
                                icon: Icons.bathroom,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildFeatureField(
                                controller: _areaSqftController,
                                label: 'Size (sqft)',
                                icon: Icons.square_foot,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildModernTextField(
                                controller: _priceController,
                                label: 'Monthly Rent',
                                prefixIcon: Icons.attach_money,
                                prefixText: 'RM ',
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                validator: (value) =>
                                    value!.isEmpty ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Description Card
                    _buildSectionCard(
                      title: 'Property Description',
                      icon: Icons.description,
                      children: [
                        _buildModernTextField(
                          controller: _descriptionController,
                          label: 'Description',
                          hint:
                              'Describe the property, features, amenities, nearby facilities, etc.',
                          maxLines: 5,
                          validator: (value) =>
                              value!.isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),

                    // Availability Card
                    _buildSectionCard(
                      title: 'Availability',
                      icon: Icons.calendar_today,
                      children: [
                        _buildDatePicker(),
                        const SizedBox(height: 16),
                        _buildModernDropdown(),
                      ],
                    ),

                    // Media Upload Card
                    _buildSectionCard(
                      title: 'Property Media',
                      icon: Icons.photo_library,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey[50],
                          ),
                          child: InkWell(
                            onTap: _showMediaOptions,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    size: 48,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap to add photos or videos',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Minimum 4 files required',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (_selectedImages.isNotEmpty ||
                            _selectedVideos.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildMediaPreview(),
                        ],
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Save Property Listing',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? prefixIcon,
    String? prefixText,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        prefixText: prefixText,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Theme.of(context).primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildFeatureField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '0',
              ),
              validator: (value) => value!.isEmpty ? 'Required' : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[50],
      ),
      child: ListTile(
        leading:
            Icon(Icons.calendar_today, color: Theme.of(context).primaryColor),
        title: const Text('Available From'),
        subtitle: Text(
          '${_availableFrom.day}/${_availableFrom.month}/${_availableFrom.year}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(Icons.edit_calendar),
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: _availableFrom,
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (date != null) {
            setState(() {
              _availableFrom = date;
            });
          }
        },
      ),
    );
  }

  Widget _buildModernDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[50],
      ),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: 'Minimum Tenure',
          border: InputBorder.none,
          prefixIcon:
              Icon(Icons.access_time, color: Theme.of(context).primaryColor),
        ),
        value: _minimumTenure,
        items: const [
          DropdownMenuItem(value: '3 months', child: Text('3 months')),
          DropdownMenuItem(value: '6 months', child: Text('6 months')),
          DropdownMenuItem(value: '12 months', child: Text('12 months')),
          DropdownMenuItem(value: '24 months', child: Text('24 months')),
        ],
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _minimumTenure = value;
            });
          }
        },
      ),
    );
  }

  Widget _buildMediaPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedImages.isNotEmpty) ...[
          Text(
            'Photos (${_selectedImages.length})',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return _buildMediaThumbnail(
                  file: _selectedImages[index],
                  isVideo: false,
                  onRemove: () {
                    setState(() {
                      _selectedImages.removeAt(index);
                    });
                  },
                );
              },
            ),
          ),
        ],
        if (_selectedVideos.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Videos (${_selectedVideos.length})',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedVideos.length,
              itemBuilder: (context, index) {
                return _buildMediaThumbnail(
                  file: _selectedVideos[index],
                  isVideo: true,
                  onRemove: () {
                    setState(() {
                      final videoPath = _selectedVideos[index].path;
                      _videoControllers[videoPath]?.dispose();
                      _videoControllers.remove(videoPath);
                      _selectedVideos.removeAt(index);
                    });
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMediaThumbnail({
    required File file,
    required bool isVideo,
    required VoidCallback onRemove,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 120,
              height: 120,
              color: Colors.grey[200],
              child: isVideo
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        if (_videoControllers[file.path] != null &&
                            _videoControllers[file.path]!.value.isInitialized)
                          FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: _videoControllers[file.path]!
                                  .value
                                  .size
                                  .width,
                              height: _videoControllers[file.path]!
                                  .value
                                  .size
                                  .height,
                              child: VideoPlayer(_videoControllers[file.path]!),
                            ),
                          )
                        else
                          const Center(child: CircularProgressIndicator()),
                        Container(
                          color: Colors.black.withOpacity(0.3),
                          child: const Center(
                            child: Icon(
                              Icons.play_circle_filled,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Image.file(
                      file,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          Positioned(
            top: 5,
            right: 5,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(4),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _propertyNameController.dispose();
    _addressController.dispose();
    _postcodeController.dispose();
    _priceController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _areaSqftController.dispose();
    _descriptionController.dispose();

    // Dispose video controllers
    for (var controller in _videoControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }
}
