import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:my_app/models/listing.dart';
import 'package:my_app/services/database_service.dart';
import 'package:file_picker/file_picker.dart'; // 1. ADD IMPORT

class EditListingPage extends StatefulWidget {
  final Listing listing;

  const EditListingPage({super.key, required this.listing});

  @override
  State<EditListingPage> createState() => _EditListingPageState();
}

class _EditListingPageState extends State<EditListingPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _propertyNameController;
  late TextEditingController _addressController;
  late TextEditingController _postcodeController;
  late TextEditingController _priceController;
  late TextEditingController _bedroomsController;
  late TextEditingController _bathroomsController;
  late TextEditingController _areaSqftController;
  late TextEditingController
      _maxTenantsController; // <--- NEW: Max tenants controller
  late TextEditingController _descriptionController;
  late DateTime _availableFrom;
  late String _minimumTenure;
  int? _selectedDepositMonth;

  // Existing media from database
  List<String> _existingMediaUrls = [];
  final List<String> _deletedMediaUrls = [];

  // New media to upload
  final List<File> _newImages = [];
  final List<File> _newVideos = [];
  final Map<String, VideoPlayerController> _videoControllers = {};

  // Contract Variables
  File? _newContractFile;
  String? _newContractFileName;
  String? _existingContractUrl;
  bool _deleteContract =
      false; // Flag to track if user removed existing contract

  final DatabaseService _databaseService = DatabaseService();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _propertyNameController = TextEditingController(text: widget.listing.title);
    _addressController = TextEditingController(text: widget.listing.address);
    _postcodeController = TextEditingController(text: widget.listing.postcode);
    _priceController =
        TextEditingController(text: widget.listing.price.toStringAsFixed(0));
    _bedroomsController =
        TextEditingController(text: widget.listing.bedrooms.toString());
    _bathroomsController =
        TextEditingController(text: widget.listing.bathrooms.toString());
    _areaSqftController =
        TextEditingController(text: widget.listing.areaSqft.toString());
    _maxTenantsController = // <--- NEW: Initialize max tenants controller
        TextEditingController(text: widget.listing.maxTenants.toString());
    _descriptionController =
        TextEditingController(text: widget.listing.description);
    _availableFrom = widget.listing.availableFrom;
    _minimumTenure =
        _transformTenureToDropdownFormat(widget.listing.minimumTenure);

    // Calculate deposit month logic
    final double monthlyRent = widget.listing.price;
    if (monthlyRent > 0 && widget.listing.deposit > 0) {
      int calculatedMonths = (widget.listing.deposit / monthlyRent).round();
      if (calculatedMonths >= 1 && calculatedMonths <= 12) {
        _selectedDepositMonth = calculatedMonths;
      } else {
        _selectedDepositMonth = calculatedMonths > 12 ? 12 : 1;
      }
    } else if (widget.listing.deposit == 0) {
      _selectedDepositMonth = null;
    }

    // Copy existing media URLs
    _existingMediaUrls = List<String>.from(widget.listing.imageUrls);

    // 2. Initialize Contract
    _existingContractUrl = widget.listing.contractUrl;
  }

  String _transformTenureToDropdownFormat(String tenure) {
    switch (tenure.toLowerCase().trim()) {
      case '3':
      case '3 month':
      case '3 months':
        return '3 months';
      case '6':
      case '6 month':
      case '6 months':
        return '6 months';
      case '12':
      case '12 month':
      case '12 months':
        return '12 months';
      case '24':
      case '24 month':
      case '24 months':
        return '24 months';
      default:
        return '12 months';
    }
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _newImages.addAll(images.map((image) => File(image.path)));
      });
    }
  }

  Future<void> _pickVideos() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      final videoFile = File(video.path);
      final controller = VideoPlayerController.file(videoFile);
      await controller.initialize();
      setState(() {
        _newVideos.add(videoFile);
        _videoControllers[video.path] = controller;
      });
    }
  }

  Future<void> _captureImage() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _newImages.add(File(photo.path));
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
        _newVideos.add(videoFile);
        _videoControllers[video.path] = controller;
      });
    }
  }

  // 3. NEW: Contract Picker Logic
  Future<void> _pickContract() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _newContractFile = File(result.files.single.path!);
        _newContractFileName = result.files.single.name;
        _deleteContract = false; // Reset delete flag if new file picked
      });
    }
  }

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow full height control
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom, // Keyboard padding
        ),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ... (Same styling as before)
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
        ),
      ),
    );
  }

  Widget _buildMediaOption(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
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

  void _removeExistingMedia(String url) {
    setState(() {
      _existingMediaUrls.remove(url);
      _deletedMediaUrls.add(url);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  void _removeNewVideo(int index) {
    setState(() {
      final videoPath = _newVideos[index].path;
      _videoControllers[videoPath]?.dispose();
      _videoControllers.remove(videoPath);
      _newVideos.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final totalMedia =
          _existingMediaUrls.length + _newImages.length + _newVideos.length;
      if (totalMedia < 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please keep at least 4 images or videos.'),
              backgroundColor: Colors.red),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        String? userId = await _databaseService.currentUserId;
        if (userId == null) {
          throw Exception("You must be logged in to edit a listing");
        }

        // 4. Handle Contract Upload Logic
        String? finalContractUrl = _existingContractUrl;

        // If user selected a NEW file, upload it
        if (_newContractFile != null) {
          finalContractUrl =
              await _databaseService.uploadContract(_newContractFile!, userId);
        }
        // If user specifically deleted the old one and didn't add a new one
        else if (_deleteContract) {
          finalContractUrl = null; // This will clear it in DB
        }

        List<String> newMediaUrls = [];
        if (_newImages.isNotEmpty) {
          List<String> imagePaths =
              _newImages.map((file) => file.path).toList();
          newMediaUrls
              .addAll(await _databaseService.uploadImages(imagePaths, userId));
        }
        if (_newVideos.isNotEmpty) {
          List<String> videoPaths =
              _newVideos.map((file) => file.path).toList();
          newMediaUrls
              .addAll(await _databaseService.uploadVideos(videoPaths, userId));
        }

        List<String> allMediaUrls = [..._existingMediaUrls, ...newMediaUrls];
        final double monthlyRent =
            double.tryParse(_priceController.text) ?? 0.0;
        final double calculatedDeposit =
            (_selectedDepositMonth ?? 0) * monthlyRent;

        final updatedListing = Listing(
          id: widget.listing.id,
          title: _propertyNameController.text,
          address: _addressController.text,
          postcode: _postcodeController.text,
          description: _descriptionController.text,
          imageUrls: allMediaUrls,
          price: double.parse(_priceController.text),
          deposit: calculatedDeposit,
          depositMonths: _selectedDepositMonth ?? 0,
          bedrooms: int.parse(_bedroomsController.text),
          bathrooms: int.parse(_bathroomsController.text),
          areaSqft: int.parse(_areaSqftController.text),
          maxTenants: int.parse(
              _maxTenantsController.text), // <--- NEW: Include max tenants
          availableFrom: _availableFrom,
          minimumTenure: _minimumTenure,
          status: widget.listing.status,
          createdAt: widget.listing.createdAt,
          updatedAt: DateTime.now(),
          contractUrl: finalContractUrl, // 5. Pass updated contract URL
        );

        await _databaseService.updateListing(updatedListing, _deletedMediaUrls);

        if (mounted) {
          Navigator.pop(context, updatedListing);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Property listing updated successfully'),
                backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error updating listing: $e'),
                backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // 6. Widget to build the Contract Card
  Widget _buildContractCard() {
    String displayText = 'Upload Rental Agreement (PDF)';
    IconData icon = Icons.picture_as_pdf_rounded;
    Color? iconBgColor;
    Color? containerBgColor;
    Color? borderColor;
    bool showDelete = false;
    bool isBold = false;

    if (_newContractFile != null) {
      displayText = _newContractFileName!;
      iconBgColor = Colors.green.withOpacity(0.1);
      containerBgColor = Colors.green.withOpacity(0.05);
      borderColor = Colors.green.withOpacity(0.3);
      showDelete = true;
      isBold = true;
    } else if (_existingContractUrl != null && !_deleteContract) {
      displayText = 'Current Contract (PDF)';
      iconBgColor = Colors.green.withOpacity(0.1);
      containerBgColor = Colors.green.withOpacity(0.05);
      borderColor = Colors.green.withOpacity(0.3);
      showDelete = true;
      isBold = true;
    } else {
      iconBgColor = Colors.red.withOpacity(0.1);
      containerBgColor = Colors.grey[50];
      borderColor = Colors.grey[200];
    }

    return _buildSectionCard(
      title: 'Rental Agreement',
      icon: Icons.assignment_outlined,
      children: [
        InkWell(
          onTap: _pickContract,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: containerBgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor!),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: _newContractFile != null ||
                            (_existingContractUrl != null && !_deleteContract)
                        ? Colors.green
                        : Colors.red[400],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayText,
                        style: TextStyle(
                          fontWeight:
                              isBold ? FontWeight.w600 : FontWeight.w500,
                          color: isBold ? Colors.black87 : Colors.grey[700],
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!isBold)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Optional',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (showDelete)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.grey),
                    onPressed: () {
                      setState(() {
                        if (_newContractFile != null) {
                          _newContractFile = null;
                          _newContractFileName = null;
                        } else {
                          _deleteContract = true;
                        }
                      });
                    },
                  )
                else
                  Icon(Icons.upload_file_rounded, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ],
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
            Colors.grey[50]!,
            Colors.white,
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'Edit Property Listing',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 0.5,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context)
                      .primaryColor
                      .withBlue(Theme.of(context).primaryColor.blue + 20),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.arrow_back, size: 20, color: Colors.white),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        extendBodyBehindAppBar: false,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Property Details Card
                      _buildSectionCard(
                        title: 'Property Details',
                        icon: Icons.home_rounded,
                        children: [
                          _buildModernTextField(
                            controller: _propertyNameController,
                            label: 'Property Name',
                            hint: 'e.g. Sunset Villa, Cozy Apartment',
                            prefixIcon: Icons.home_work_outlined,
                            validator: (value) =>
                                value!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 20),
                          _buildModernTextField(
                            controller: _addressController,
                            label: 'Address',
                            hint: 'Full street address',
                            prefixIcon: Icons.location_on_outlined,
                            maxLines: 2,
                            validator: (value) =>
                                value!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 20),
                          _buildModernTextField(
                            controller: _postcodeController,
                            label: 'Postcode',
                            hint: 'e.g. 50480',
                            prefixIcon: Icons.map_outlined,
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
                        icon: Icons.grid_view_rounded,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildFeatureField(
                                  controller: _bedroomsController,
                                  label: 'Bedrooms',
                                  icon: Icons.bed_rounded,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildFeatureField(
                                  controller: _bathroomsController,
                                  label: 'Bathrooms',
                                  icon: Icons.bathtub_outlined,
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
                                  icon: Icons.square_foot_rounded,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildFeatureField(
                                  controller: _maxTenantsController,
                                  label: 'Max Tenants',
                                  icon: Icons.people_outline_rounded,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildModernTextField(
                            controller: _priceController,
                            label: 'Monthly Rent',
                            prefixIcon: Icons.attach_money_rounded,
                            prefixText: 'RM ',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            validator: (value) =>
                                value!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 20),
                          _buildDepositField(),
                        ],
                      ),

                      // Description Card
                      _buildSectionCard(
                        title: 'Description',
                        icon: Icons.description_outlined,
                        children: [
                          _buildModernTextField(
                            controller: _descriptionController,
                            label: 'Property Description',
                            hint:
                                'Tell potential tenants what makes your property special...',
                            maxLines: 6,
                            validator: (value) =>
                                value!.isEmpty ? 'Required' : null,
                          ),
                        ],
                      ),

                      // Availability Card
                      _buildSectionCard(
                        title: 'Availability',
                        icon: Icons.event_available_rounded,
                        children: [
                          _buildDatePicker(),
                          const SizedBox(height: 20),
                          _buildModernDropdown(),
                        ],
                      ),

                      // Media Upload Card
                      _buildSectionCard(
                        title: 'Photos & Videos',
                        icon: Icons.perm_media_outlined,
                        children: [
                          if (_existingMediaUrls.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                'Existing Media (${_existingMediaUrls.length})',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 100,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _existingMediaUrls.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(width: 12),
                                itemBuilder: (context, index) {
                                  return _buildExistingMediaThumbnail(
                                    url: _existingMediaUrls[index],
                                    onRemove: () => _removeExistingMedia(
                                        _existingMediaUrls[index]),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                          InkWell(
                            onTap: _showMediaOptions,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 32),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.05),
                                    Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.02),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.2),
                                  width: 2,
                                  strokeAlign: BorderSide.strokeAlignInside,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.add_photo_alternate_rounded,
                                      size: 40,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Add More Photos & Videos',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Keep at least 4 media files',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_newImages.isNotEmpty ||
                              _newVideos.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            _buildNewMediaPreview(),
                          ],
                        ],
                      ),

                      // Contract Card
                      _buildContractCard(),

                      const SizedBox(height: 20),

                      // Submit Button
                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).primaryColor,
                              Theme.of(context).primaryColor.withBlue(
                                  Theme.of(context).primaryColor.blue + 20),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Update Property Listing',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // Helper widgets (TextField, FeatureField, DepositField, etc.) remain exactly the same as your original file
  // I am omitting them for brevity, but in your actual file, keep them exactly as they were.

  // ... [KEEP _buildDepositField, _buildSectionCard, _buildModernTextField, etc.] ...
  // ... [KEEP _buildExistingMediaThumbnail, _buildNewMediaPreview, _buildMediaThumbnail, dispose] ...

  // Copy these helpers back from your original file if you are copy-pasting this whole block.
  Widget _buildDepositField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Deposit',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedDepositMonth,
              isExpanded: true,
              hint: Text(
                'Select deposit months',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
              icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
              items: List.generate(12, (index) {
                int month = index + 1;
                return DropdownMenuItem<int>(
                  value: month,
                  child: Text(
                    '$month month${month > 1 ? 's' : ''}',
                  ),
                );
              }).toList(),
              onChanged: (int? newValue) {
                setState(() {
                  _selectedDepositMonth = newValue;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor.withOpacity(0.15),
                        Theme.of(context).primaryColor.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            validator: validator,
            style: const TextStyle(fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, color: Colors.grey[400], size: 20)
                  : null,
              prefixText: prefixText,
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                    color: Theme.of(context).primaryColor, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.red[400]!),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: '0',
              hintStyle: TextStyle(color: Colors.black12),
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            validator: (value) => value!.isEmpty ? '' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available From',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _availableFrom,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: Theme.of(context).primaryColor,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (date != null) {
              setState(() {
                _availableFrom = date;
              });
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 20, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Text(
                  '${_availableFrom.day}/${_availableFrom.month}/${_availableFrom.year}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Minimum Tenure',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _minimumTenure,
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
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
          ),
        ),
      ],
    );
  }

  Widget _buildExistingMediaThumbnail({
    required String url,
    required VoidCallback onRemove,
  }) {
    final isVideo = url.toLowerCase().endsWith('.mp4') ||
        url.toLowerCase().endsWith('.mov') ||
        url.toLowerCase().endsWith('.avi');

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
                        Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(
                              Icons.videocam,
                              size: 40,
                              color: Colors.grey,
                            ),
                          ),
                        ),
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
                  : Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        );
                      },
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

  Widget _buildNewMediaPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_newImages.isNotEmpty) ...[
          Text(
            'New Photos (${_newImages.length})',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _newImages.length,
              itemBuilder: (context, index) {
                return _buildMediaThumbnail(
                  file: _newImages[index],
                  isVideo: false,
                  onRemove: () => _removeNewImage(index),
                );
              },
            ),
          ),
        ],
        if (_newVideos.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'New Videos (${_newVideos.length})',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _newVideos.length,
              itemBuilder: (context, index) {
                return _buildMediaThumbnail(
                  file: _newVideos[index],
                  isVideo: true,
                  onRemove: () => _removeNewVideo(index),
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
    _maxTenantsController.dispose(); // <--- NEW: Dispose max tenants controller
    _descriptionController.dispose();
    for (var controller in _videoControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
