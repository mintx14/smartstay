import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:my_app/models/listing.dart';
import 'package:my_app/models/user_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:my_app/config/api_config.dart';
//import 'package:my_app/pages/tenant/messages_screen.dart' as messages;
import 'package:my_app/pages/tenant/home_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:io';
import 'dart:ui';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:my_app/widgets/id_card_camera.dart';
import 'package:image/image.dart' as img;

class BookingRequestPage extends StatefulWidget {
  final Listing listing;
  final User currentUser;

  const BookingRequestPage({
    super.key,
    required this.listing,
    required this.currentUser,
  });

  @override
  State<BookingRequestPage> createState() => _BookingRequestPageState();
}

class _BookingRequestPageState extends State<BookingRequestPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _hasExistingBooking = false;
  Map<String, dynamic>? _existingBookingDetails;

  // Tab index
  int _currentStep = 0;

  // Form fields
  DateTime? _selectedCheckInDate;
  int _selectedDuration = 6;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _emergencyContactController =
      TextEditingController();
  final TextEditingController _emergencyPhoneController =
      TextEditingController();

  // ID Upload - Front and Back
  File? _selectedIdFrontImage;
  File? _selectedIdBackImage;
  final ImagePicker _picker = ImagePicker();

  // Upload mode: 'camera' or 'file'
  String _uploadMode = 'camera';
  File? _uploadedFile; // For PDF/Image file upload
  File? _generatedPdf; // Final PDF with both images
  bool _isPdfGenerating = false;
  bool _pdfPreviewed = false; // Track if user has previewed the PDF

  bool _isLoading = false;
  bool _agreedToTerms = false;

  // Calculated values
  double _totalAmount = 0;
  double _depositAmount = 0;
  double _monthlyRent = 0;

  int get _minimumTenure {
    try {
      return int.parse(widget.listing.minimumTenure);
    } catch (e) {
      return 1;
    }
  }

  // Helper method to get the current active file (single source of truth)
  // Returns the most recently selected file, whether from camera or file upload
  File? get _currentActiveFile {
    // Priority: generated PDF (from camera) takes precedence if both exist
    // But since we clear one when the other is set, only one should exist at a time
    if (_generatedPdf != null && _generatedPdf!.existsSync()) {
      return _generatedPdf;
    }
    if (_uploadedFile != null && _uploadedFile!.existsSync()) {
      return _uploadedFile;
    }
    return null;
  }

  // Helper method to check if there's an active file
  bool get _hasActiveFile => _currentActiveFile != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentStep = _tabController.index;
      });
    });

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();

    _selectedCheckInDate = widget.listing.availableFrom;
    _selectedDuration = _selectedDuration >= _minimumTenure
        ? _selectedDuration
        : _minimumTenure;

    _calculateCosts();
    _checkExistingBooking();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _messageController.dispose();
    _emergencyContactController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  void _calculateCosts() {
    _monthlyRent = widget.listing.price;
    _depositAmount = widget.listing.deposit;
    _totalAmount = (_monthlyRent * _selectedDuration) + _depositAmount;
    setState(() {});
  }

  Future<void> _selectCheckInDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedCheckInDate ?? widget.listing.availableFrom,
      firstDate: widget.listing.availableFrom,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E3A5F),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedCheckInDate) {
      setState(() {
        _selectedCheckInDate = picked;
      });
    }
  }

  Future<void> _captureIdImage(String side) async {
    // side will be either 'front' or 'back'
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Capture ID $side',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A5F),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Take a clear photo of your ID card ${side}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: _buildUploadOption(
                          icon: Icons.camera_alt_rounded,
                          label: 'Camera',
                          onTap: () async {
                            Navigator.pop(context);
                            // Use custom ID card camera with frame overlay
                            final File? capturedImage = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    IdCardCameraPage(side: side),
                              ),
                            );
                            if (capturedImage != null) {
                              setState(() {
                                if (side == 'Front') {
                                  _selectedIdFrontImage = capturedImage;
                                } else {
                                  _selectedIdBackImage = capturedImage;
                                }
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildUploadOption(
                          icon: Icons.photo_library_rounded,
                          label: 'Gallery',
                          onTap: () async {
                            Navigator.pop(context);
                            final XFile? image = await _picker.pickImage(
                              source: ImageSource.gallery,
                              maxWidth: 1600,
                              imageQuality: 90,
                            );
                            if (image != null) {
                              final file = File(image.path);
                              setState(() {
                                if (side == 'Front') {
                                  _selectedIdFrontImage = file;
                                } else {
                                  _selectedIdBackImage = file;
                                }
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _cleanupTempFiles() {
    try {
      // Clean up temporary image files
      if (_selectedIdFrontImage != null &&
          (_selectedIdFrontImage!.path.contains('image_picker') ||
              _selectedIdFrontImage!.path.contains('cache'))) {
        _selectedIdFrontImage!.delete().catchError((e) {
          print('Error deleting front image: $e');
          return _selectedIdFrontImage!;
        });
      }
      if (_selectedIdBackImage != null &&
          (_selectedIdBackImage!.path.contains('image_picker') ||
              _selectedIdBackImage!.path.contains('cache'))) {
        _selectedIdBackImage!.delete().catchError((e) {
          print('Error deleting back image: $e');
          return _selectedIdBackImage!;
        });
      }
    } catch (e) {
      print('Error during cleanup: $e');
    }
  }

  Future<void> _pickIdFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);

        // Validate file size (max 10MB)
        final fileSize = await file.length();
        if (fileSize > 10 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File size must be less than 10MB'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Validate file type
        final extension = result.files.single.extension?.toLowerCase();
        if (extension == null ||
            !['pdf', 'jpg', 'jpeg', 'png'].contains(extension)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please upload a PDF, JPG, or PNG file'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          // Clear camera-generated PDF and images when file is uploaded
          _generatedPdf = null;
          _selectedIdFrontImage = null;
          _selectedIdBackImage = null;
          _pdfPreviewed = false;
          // Set the uploaded file
          _uploadedFile = file;
        });

        // Show preview dialog
        if (mounted) {
          _showFilePreviewDialog(file, extension);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showFilePreviewDialog(File file, String extension) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'File Preview',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A5F),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (extension == 'pdf')
                  Container(
                    height: 300,
                    width: double.maxFinite,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.picture_as_pdf,
                              size: 64, color: Colors.red),
                          SizedBox(height: 12),
                          Text('PDF File Selected',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  )
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      file,
                      fit: BoxFit.contain,
                      height: 300,
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  'File size: ${(file.lengthSync() / 1024).toStringAsFixed(2)} KB',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _uploadedFile = null;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('File uploaded successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A5F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child:
                  const Text('Confirm', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<File?> _generatePdfWithImages() async {
    if (_selectedIdFrontImage == null || _selectedIdBackImage == null) {
      return null;
    }

    setState(() {
      _isPdfGenerating = true;
    });

    try {
      final pdf = pw.Document();

      // Read and crop images to remove background edges
      final frontImageBytes = await _selectedIdFrontImage!.readAsBytes();
      final backImageBytes = await _selectedIdBackImage!.readAsBytes();

      // Decode images for cropping
      var frontImg = img.decodeImage(frontImageBytes);
      var backImg = img.decodeImage(backImageBytes);

      // Crop based on camera overlay frame (85% width, 0.63 aspect ratio)
      if (frontImg != null) {
        // Calculate crop dimensions based on the overlay in IdCardCameraPage
        // frameWidth = size.width * 0.85
        // frameHeight = frameWidth * 0.63
        final double cropWidthRatio = 0.85;
        final double aspectRatio = 0.63; // ID card height/width

        final targetWidth = (frontImg.width * cropWidthRatio).round();
        final targetHeight = (targetWidth * aspectRatio).round();

        // Ensure we don't exceed image dimensions
        final finalWidth =
            targetWidth > frontImg.width ? frontImg.width : targetWidth;
        final finalHeight =
            targetHeight > frontImg.height ? frontImg.height : targetHeight;

        final cropX = ((frontImg.width - finalWidth) / 2).round();
        final cropY = ((frontImg.height - finalHeight) / 2).round();

        frontImg = img.copyCrop(
          frontImg,
          x: cropX,
          y: cropY,
          width: finalWidth,
          height: finalHeight,
        );
      }

      if (backImg != null) {
        final double cropWidthRatio = 0.85;
        final double aspectRatio = 0.63;

        final targetWidth = (backImg.width * cropWidthRatio).round();
        final targetHeight = (targetWidth * aspectRatio).round();

        final finalWidth =
            targetWidth > backImg.width ? backImg.width : targetWidth;
        final finalHeight =
            targetHeight > backImg.height ? backImg.height : targetHeight;

        final cropX = ((backImg.width - finalWidth) / 2).round();
        final cropY = ((backImg.height - finalHeight) / 2).round();

        backImg = img.copyCrop(
          backImg,
          x: cropX,
          y: cropY,
          width: finalWidth,
          height: finalHeight,
        );
      }

      // Convert back to bytes for PDF
      final croppedFrontBytes =
          frontImg != null ? img.encodeJpg(frontImg) : frontImageBytes;
      final croppedBackBytes =
          backImg != null ? img.encodeJpg(backImg) : backImageBytes;

      final frontImage = pw.MemoryImage(croppedFrontBytes);
      final backImage = pw.MemoryImage(croppedBackBytes);

      // Add page with background watermark pattern
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Stack(
              children: [
                // Main content
                // Main content - Just images
                pw.Center(
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      // Front ID
                      pw.Container(
                        height: 200,
                        width: 320,
                        child: pw.ClipRRect(
                          horizontalRadius: 8,
                          verticalRadius: 8,
                          child: pw.Image(
                            frontImage,
                            fit: pw.BoxFit.fill,
                          ),
                        ),
                      ),

                      pw.SizedBox(height: 40),

                      // Back ID
                      pw.Container(
                        height: 200,
                        width: 320,
                        child: pw.ClipRRect(
                          horizontalRadius: 8,
                          verticalRadius: 8,
                          child: pw.Image(
                            backImage,
                            fit: pw.BoxFit.fill,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Overlay: Repeating "Confidential" watermark pattern
                // Placed later in Stack to ensure it is ON TOP of the images
                ...List.generate(12, (row) {
                  return pw.Positioned(
                    top: row * 80.0 - 100,
                    left: -100,
                    right: -100,
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                      children: List.generate(5, (col) {
                        return pw.Transform.rotate(
                          angle: -0.785, // -45 degrees
                          child: pw.Opacity(
                            opacity: 0.2,
                            child: pw.Text(
                              'Confidential',
                              style: pw.TextStyle(
                                fontSize: 26,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.black,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      );

      // Save PDF to app storage
      final outputDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputFile =
          File('${outputDir.path}/id_verification_$timestamp.pdf');

      await outputFile.writeAsBytes(await pdf.save());

      // DON'T delete temp files yet - we might need them for submission
      // They will be cleaned up after successful booking submission

      setState(() {
        _isPdfGenerating = false;
        // Clear uploaded file when PDF is generated from camera
        _uploadedFile = null;
        // Set the generated PDF
        _generatedPdf = outputFile;
      });

      if (mounted) {
        // Show success dialog with preview option
        _showPdfGeneratedDialog(outputFile);
      }

      return outputFile;
    } catch (e) {
      setState(() {
        _isPdfGenerating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  void _showPdfGeneratedDialog(File pdfFile) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'PDF Generated!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A5F),
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your ID verification document has been created successfully.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf,
                        color: Colors.red, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        pdfFile.path.split('/').last,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                _pdfPreviewed ? 'Done' : 'Close',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _pdfPreviewed = true;
                });
                Navigator.of(context).pop();
                // Open PDF viewer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ContractViewerPage(
                      contractUrl: pdfFile.path,
                      title: 'ID Verification Document',
                      isLocalFile: true,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A5F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.visibility, color: Colors.white),
              label: Text(
                _pdfPreviewed ? 'View Again' : 'Preview PDF',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUploadOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A5F).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF1E3A5F), size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E3A5F),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentityVerificationCard() {
    bool hasFront = _selectedIdFrontImage != null;
    bool hasBack = _selectedIdBackImage != null;
    bool hasUploadedFile = _uploadedFile != null;
    bool hasPdf = _generatedPdf != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A5F).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.badge_outlined,
                  color: Color(0xFF1E3A5F),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ID Card Verification',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A5F),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Choose your upload method',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              if (_hasActiveFile)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          size: 14, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        'Complete',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Upload Mode Selection
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _uploadMode = 'camera'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _uploadMode == 'camera'
                            ? const Color(0xFF1E3A5F)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt_rounded,
                            size: 18,
                            color: _uploadMode == 'camera'
                                ? Colors.white
                                : Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Camera',
                            style: TextStyle(
                              color: _uploadMode == 'camera'
                                  ? Colors.white
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _uploadMode = 'file'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _uploadMode == 'file'
                            ? const Color(0xFF1E3A5F)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.upload_file_rounded,
                            size: 18,
                            color: _uploadMode == 'file'
                                ? Colors.white
                                : Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Upload File',
                            style: TextStyle(
                              color: _uploadMode == 'file'
                                  ? Colors.white
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Camera Mode - Two Card Capture
          if (_uploadMode == 'camera') ...[
            // Front ID Card
            _buildIDCardSection(
              title: 'Front Side',
              image: _selectedIdFrontImage,
              onCapture: () => _captureIdImage('Front'),
              onRemove: () {
                setState(() {
                  _selectedIdFrontImage = null;
                  _generatedPdf = null; // Clear PDF when images change
                });
              },
            ),

            const SizedBox(height: 16),

            // Back ID Card
            _buildIDCardSection(
              title: 'Back Side',
              image: _selectedIdBackImage,
              onCapture: () => _captureIdImage('Back'),
              onRemove: () {
                setState(() {
                  _selectedIdBackImage = null;
                  _generatedPdf = null; // Clear PDF when images change
                });
              },
            ),

            const SizedBox(height: 16),

            // Generate PDF Button
            if (hasFront && hasBack && !hasPdf)
              ElevatedButton(
                onPressed: _isPdfGenerating
                    ? null
                    : () async {
                        await _generatePdfWithImages();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A5F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: _isPdfGenerating
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text('Generating PDF...'),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.picture_as_pdf, size: 20),
                          const SizedBox(width: 8),
                          const Text('Generate PDF'),
                        ],
                      ),
              ),

            // PDF Generated Confirmation with View Button
            if (hasPdf)
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: Colors.green, size: 24),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PDF Generated Successfully',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Your ID verification document is ready',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.green),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // View PDF Button (persistent) - uses current active file
                  OutlinedButton.icon(
                    onPressed: () {
                      final activeFile = _currentActiveFile;
                      if (activeFile != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ContractViewerPage(
                              contractUrl: activeFile.path,
                              title: 'ID Verification Document',
                              isLocalFile: true,
                            ),
                          ),
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1E3A5F),
                      side: const BorderSide(color: Color(0xFF1E3A5F)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    icon: const Icon(Icons.visibility_outlined, size: 20),
                    label: const Text(
                      'View PDF',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
          ],

          // File Upload Mode
          if (_uploadMode == 'file') ...[
            InkWell(
              onTap: _pickIdFile,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A5F).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cloud_upload_outlined,
                        size: 48,
                        color: Color(0xFF1E3A5F),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Upload ID Document',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A5F),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'PDF, JPG, or PNG (Max 10MB)',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A5F),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Choose File',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (hasUploadedFile) ...[
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.insert_drive_file,
                        color: Colors.green, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'File Uploaded',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _uploadedFile!.path.split('/').last,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _uploadedFile = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // View File Button - uses current active file
              OutlinedButton.icon(
                onPressed: () {
                  final activeFile = _currentActiveFile;
                  if (activeFile != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ContractViewerPage(
                          contractUrl: activeFile.path,
                          title: 'ID Verification Document',
                          isLocalFile: true,
                        ),
                      ),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1E3A5F),
                  side: const BorderSide(color: Color(0xFF1E3A5F)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 48),
                ),
                icon: const Icon(Icons.visibility_outlined, size: 20),
                label: const Text(
                  'View File',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildIDCardSection({
    required String title,
    required File? image,
    required VoidCallback onCapture,
    required VoidCallback onRemove,
  }) {
    if (image != null) {
      return Stack(
        children: [
          // Tapable image with zoom functionality
          GestureDetector(
            onTap: () {
              // Show zoomable image dialog
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: const EdgeInsets.all(10),
                  child: Stack(
                    children: [
                      // Zoomable image
                      InteractiveViewer(
                        minScale: 1.0,
                        maxScale: 4.0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Image.file(
                            image,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      // Close button
                      Positioned(
                        top: 10,
                        right: 10,
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.black),
                          ),
                        ),
                      ),
                      // Zoom instruction
                      Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Pinch to zoom • Drag to pan',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                image,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Title label
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          // Action buttons (Recapture and Delete)
          Positioned(
            top: 12,
            right: 12,
            child: Row(
              children: [
                // Recapture button
                InkWell(
                  onTap: onCapture,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                        )
                      ],
                    ),
                    child: const Icon(Icons.refresh_rounded,
                        size: 20, color: Color(0xFF1E3A5F)),
                  ),
                ),
                const SizedBox(width: 8),
                // Delete button
                InkWell(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                        )
                      ],
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        size: 20, color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
          // Tap to zoom hint
          Positioned(
            bottom: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.zoom_in, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Tap to zoom',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      return InkWell(
        onTap: onCapture,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 2,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A5F).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: 48,
                  color: Color(0xFF1E3A5F),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Capture $title',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A5F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap to take a photo',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A5F),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Capture',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF10B981),
                  size: 64,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Request Sent!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A5F),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your booking request has been sent to the property owner. You will be notified once they respond.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close dialog
                Navigator.of(context).pop(); // Close Booking Request Page
              },
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close dialog

                // Navigate to HomePage with Messages tab (index 2) and Bookings sub-tab (index 1) selected
                // Use pushAndRemoveUntil to clear the back stack and ensure the nav bar is present
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => HomePage(
                      user: widget.currentUser,
                      initialIndex: 2, // Messages Tab
                      initialMessageTabIndex: 1, // Bookings Sub-tab
                    ),
                  ),
                  (route) => false, // Remove all previous routes
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A5F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'View Booking',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openContractViewer() {
    final urlString =
        ApiConfig.generateFullImageUrl(widget.listing.contractUrl);
    if (urlString.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No contract available for this property.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContractViewerPage(
          contractUrl: urlString,
          title: 'Rental Agreement - ${widget.listing.title}',
        ),
      ),
    );
  }

  Widget _buildContractCard() {
    if (widget.listing.contractUrl == null ||
        widget.listing.contractUrl!.isEmpty) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: _openContractViewer,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF0EA5E9).withOpacity(0.1),
              const Color(0xFF3B82F6).withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF0EA5E9).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.description_outlined,
                  color: Color(0xFF0EA5E9), size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'View Rental Agreement',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A5F),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Review terms before booking',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 18, color: Color(0xFF0EA5E9)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A5F)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Booking Request',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Property Summary Card
                    _buildPropertySummaryCard(),
                    const SizedBox(height: 24),

                    // Booking Details Section
                    _buildSectionTitle('Booking Details'),
                    const SizedBox(height: 16),
                    _buildBookingDetailsCard(),
                    const SizedBox(height: 24),

                    // Personal Information Section
                    _buildSectionTitle('Personal Information'),
                    const SizedBox(height: 16),
                    _buildPersonalInfoCard(),
                    const SizedBox(height: 24),

                    // Identity Verification Section
                    _buildSectionTitle('Identity Verification'),
                    const SizedBox(height: 16),
                    _buildIdentityVerificationCard(),
                    const SizedBox(height: 24),

                    // Cost Summary Section
                    _buildSectionTitle('Cost Summary'),
                    const SizedBox(height: 16),
                    _buildCostSummaryCard(),
                    const SizedBox(height: 24),

                    // --- Contract Section (only show if contract exists) ---
                    if (widget.listing.contractUrl != null &&
                        widget.listing.contractUrl!.isNotEmpty) ...[
                      _buildSectionTitle('Contract'),
                      const SizedBox(height: 12),
                      _buildContractCard(),
                      const SizedBox(height: 24),
                    ],
                    // --------------------------------------

                    // Terms and Conditions
                    _buildTermsCheckbox(),
                    const SizedBox(height: 32),

                    // Submit Button
                    _buildSubmitButton(),
                    const SizedBox(height: 40),

                    if (_hasExistingBooking)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'You have an existing ${_existingBookingDetails?['status']} booking for this property',
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPropertySummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Property Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              widget.listing.imageUrls.isNotEmpty
                  ? ApiConfig.generateFullImageUrl(widget.listing.imageUrls[0])
                  : 'https://via.placeholder.com/100',
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image, color: Colors.grey),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          // Property Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.listing.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.listing.address,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A5F).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'RM ${widget.listing.price.toStringAsFixed(0)}/month',
                    style: const TextStyle(
                      color: Color(0xFF1E3A5F),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2D3748),
      ),
    );
  }

  Widget _buildBookingDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // Check-in Date
          InkWell(
            onTap: _selectCheckInDate,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A5F).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.calendar_today,
                      color: Color(0xFF1E3A5F),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Check-in Date',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedCheckInDate != null
                              ? DateFormat('MMMM d, yyyy')
                                  .format(_selectedCheckInDate!)
                              : 'Select Date',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Duration
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A5F).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.access_time,
                        color: Color(0xFF1E3A5F),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Rental Duration',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildDurationOption(3),
                    const SizedBox(width: 8),
                    _buildDurationOption(6),
                    const SizedBox(width: 8),
                    _buildDurationOption(12),
                  ],
                ),
                if (_selectedDuration < _minimumTenure)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Minimum tenure: ${widget.listing.minimumTenure} months',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Message to Owner
          TextFormField(
            controller: _messageController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Message to Owner (Optional)',
              hintText: 'Introduce yourself or ask any questions...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF1E3A5F)),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationOption(int months) {
    final isSelected = _selectedDuration == months;
    final isValid = months >= _minimumTenure;

    return Expanded(
      child: InkWell(
        onTap: isValid
            ? () {
                setState(() {
                  _selectedDuration = months;
                  _calculateCosts();
                });
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF1E3A5F)
                : isValid
                    ? Colors.grey[100]
                    : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF1E3A5F)
                  : isValid
                      ? Colors.grey[300]!
                      : Colors.grey[200]!,
            ),
          ),
          child: Column(
            children: [
              Text(
                '$months',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Colors.white
                      : isValid
                          ? Colors.black87
                          : Colors.grey[400],
                ),
              ),
              Text(
                'months',
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? Colors.white
                      : isValid
                          ? Colors.grey[600]
                          : Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // Emergency Contact Name
          TextFormField(
            controller: _emergencyContactController,
            decoration: InputDecoration(
              labelText: 'Emergency Contact Name',
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A5F).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFF1E3A5F),
                    size: 20,
                  ),
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF1E3A5F)),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter emergency contact name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Emergency Contact Phone
          TextFormField(
            controller: _emergencyPhoneController,
            keyboardType: TextInputType.phone,
            maxLength: 11,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              labelText: 'Emergency Contact Phone',
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A5F).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.phone,
                    color: Color(0xFF1E3A5F),
                    size: 20,
                  ),
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF1E3A5F)),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter emergency contact phone';
              }
              if (value.length < 10) {
                return 'Phone number must be at least 10 digits';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCostSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, // No gradient, clean white
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!, // Subtle border
        ),
      ),
      child: Column(
        children: [
          // Rental Details Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rental Details',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                _buildCostRow(
                  'Monthly Rent',
                  'RM ${_monthlyRent.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 8),
                _buildCostRow('Duration', '$_selectedDuration months'),
                const SizedBox(height: 8),
                _buildCostRow(
                  'Total Rental Cost',
                  'RM ${(_monthlyRent * _selectedDuration).toStringAsFixed(2)}',
                  subtitle: '(Paid monthly)',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Payment Due Now Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A5F).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF1E3A5F).withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.payment,
                      size: 20,
                      color: Color(0xFF1E3A5F),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Payment Due Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A5F),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildCostRow(
                  'Security Deposit',
                  'RM ${_depositAmount.toStringAsFixed(2)}',
                  subtitle: '(2 months rent - Refundable)',
                  isHighlighted: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Payment Schedule Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Payment Schedule',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildPaymentInfo(
                  '• Pay only deposit now: RM ${_depositAmount.toStringAsFixed(2)}',
                ),
                _buildPaymentInfo(
                  '• Monthly rent of RM ${_monthlyRent.toStringAsFixed(2)} starts from check-in date',
                ),
                _buildPaymentInfo(
                  '• Deposit will be refunded after check-out (subject to terms)',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Total Overview
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _buildCostRow(
              'Total Contract Value',
              'RM ${_totalAmount.toStringAsFixed(2)}',
              subtitle: '(Deposit + $_selectedDuration months rent)',
              isSubdued: true,
            ),
          ),
        ],
      ),
    );
  }

  // Updated helper method with new parameters
  Widget _buildCostRow(String label, String value,
      {String? subtitle,
      bool isTotal = false,
      bool isHighlighted = false,
      bool isSubdued = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isHighlighted ? 15 : (isTotal ? 16 : 14),
                  fontWeight: isHighlighted || isTotal
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: isSubdued
                      ? Colors.grey[600]
                      : (isHighlighted
                          ? const Color(0xFF1E3A5F)
                          : (isTotal
                              ? const Color(0xFF2D3748)
                              : Colors.grey[700])),
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlighted ? 20 : (isTotal ? 18 : 16),
            fontWeight: isHighlighted
                ? FontWeight.bold
                : (isTotal ? FontWeight.bold : FontWeight.w500),
            color: isSubdued
                ? Colors.grey[600]
                : (isHighlighted
                    ? const Color(0xFF1E3A5F)
                    : (isTotal ? const Color(0xFF1E3A5F) : Colors.black87)),
          ),
        ),
      ],
    );
  }

  // Helper method for payment info text
  Widget _buildPaymentInfo(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[900],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _agreedToTerms,
          onChanged: (value) {
            setState(() {
              _agreedToTerms = value ?? false;
            });
          },
          activeColor: const Color(0xFF1E3A5F),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _agreedToTerms = !_agreedToTerms;
              });
            },
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                children: const [
                  TextSpan(text: 'I agree to the '),
                  TextSpan(
                    text: 'Terms and Conditions',
                    style: TextStyle(
                      color: Color(0xFF1E3A5F),
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Rental Agreement',
                    style: TextStyle(
                      color: Color(0xFF1E3A5F),
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Payment summary above button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A5F).withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF1E3A5F).withOpacity(0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Amount to Pay Now:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                'RM ${_depositAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A5F),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Submit button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitBookingRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A5F),
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Confirm Booking',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 8),

        // Security note
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.security,
              size: 14,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              'Secure payment powered by Stripe',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _submitBookingRequest() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate minimum tenure
    if (_selectedDuration < _minimumTenure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Duration must be at least ${widget.listing.minimumTenure} months'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the terms and conditions'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate ID document upload - use current active file
    final activeFile = _currentActiveFile;
    if (activeFile == null || !activeFile.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload or scan your ID document'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_hasExistingBooking) {
      _showExistingBookingDialog();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create MultipartRequest
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig
            .createBooking), // Make sure this endpoint handles multipart
      );

      // Add text fields
      request.fields.addAll({
        'listing_id': widget.listing.id.toString(),
        'tenant_id': widget.currentUser.id.toString(),
        'check_in_date': DateFormat('yyyy-MM-dd').format(_selectedCheckInDate!),
        'duration_months': _selectedDuration.toString(),
        'monthly_rent': _monthlyRent.toString(),
        'deposit_amount': _depositAmount.toString(),
        'total_amount': _totalAmount.toString(),
        'message': _messageController.text.trim(),
        'emergency_contact_name': _emergencyContactController.text.trim(),
        'emergency_contact_phone': _emergencyPhoneController.text.trim(),
        'status': 'pending',
      });

      // Handle ID document upload - use current active file
      final activeFile = _currentActiveFile;
      if (activeFile != null && activeFile.existsSync()) {
        final extension = activeFile.path.split('.').last.toLowerCase();
        request.files.add(await http.MultipartFile.fromPath(
          extension == 'pdf' ? 'id_document_pdf' : 'id_document_image',
          activeFile.path,
        ));
      } else {
        throw Exception('Please upload or scan your ID document');
      }

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = json.decode(response.body);

          if (responseData['success'] == true) {
            // Clean up temporary files after successful submission
            _cleanupTempFiles();

            // Show success dialog
            _showSuccessDialog();
          } else {
            throw Exception(
                responseData['message'] ?? 'Failed to create booking');
          }
        } catch (jsonError) {
          // If JSON parsing fails, show the raw response
          print('JSON Parse Error: $jsonError');
          print('Raw Server Response: ${response.body}');
          throw Exception(
              'Server returned invalid JSON. Raw response: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');
        }
      } else {
        throw Exception(
            'Server error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Submit Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Add this new method

  Future<void> _checkExistingBooking() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.checkExistingBooking(
          widget.currentUser.id.toString(),
          widget.listing.id.toString(),
        )),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] && data['has_existing_booking']) {
          setState(() {
            _hasExistingBooking = true;
            _existingBookingDetails = data['booking'];
          });

          // Show warning dialog
          _showExistingBookingDialog();
        }
      }
    } catch (e) {
      print('Error checking existing booking: $e');
    }
  }

  // Add this method to show warning dialog
  void _showExistingBookingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final bookingDate =
            DateTime.parse(_existingBookingDetails!['check_in_date']);
        final status = _existingBookingDetails!['status'];

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding:
              const EdgeInsets.fromLTRB(20, 16, 20, 0), // Reduced top padding
          titlePadding: const EdgeInsets.fromLTRB(
              20, 16, 20, 8), // Reduced bottom padding
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 24, // Reduced from 28
              ),
              SizedBox(width: 6), // Reduced from 8
              Expanded(
                child: Text(
                  'Existing Booking Found',
                  style: TextStyle(fontSize: 16), // Added explicit font size
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height *
                  0.6, // Limit height to 60% of screen
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You already have a $status booking for this property.',
                    style: const TextStyle(fontSize: 14), // Reduced from 16
                  ),
                  const SizedBox(height: 10), // Reduced from 12
                  Container(
                    padding: const EdgeInsets.all(10), // Reduced from 12
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Booking Details:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13, // Reduced from 14
                          ),
                        ),
                        const SizedBox(height: 6), // Reduced from 8
                        Text(
                          'Check-in: ${DateFormat('MMM d, yyyy').format(bookingDate)}',
                          style:
                              const TextStyle(fontSize: 12), // Reduced from 13
                        ),
                        const SizedBox(height: 2), // Added small spacing
                        Text(
                          'Duration: ${_existingBookingDetails!['duration_months']} months',
                          style:
                              const TextStyle(fontSize: 12), // Reduced from 13
                        ),
                        const SizedBox(height: 2), // Added small spacing
                        Text(
                          'Status: ${status.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 12, // Reduced from 13
                            color: status == 'confirmed'
                                ? Colors.green
                                : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12), // Added spacing before buttons
                ],
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(
                  bottom: 8), // Add bottom padding to actions
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.of(context)
                          .pop(); // Go back to property details
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8), // Compact padding
                    ),
                    child: const Text(
                      'Go Back',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                  if (status == 'pending') ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // Navigate to HomePage with Messages tab (index 2) and Bookings sub-tab (index 1) selected
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => HomePage(
                              user: widget.currentUser,
                              initialIndex: 2, // Messages Tab
                              initialMessageTabIndex: 1, // Bookings Sub-tab
                            ),
                          ),
                          (route) => false, // Remove all previous routes
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8), // Compact padding
                      ),
                      child: const Text(
                        'View Booking',
                        style:
                            TextStyle(color: Color(0xFF1E3A5F), fontSize: 14),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class ContractViewerPage extends StatelessWidget {
  final String contractUrl;
  final String title;
  final bool isLocalFile;

  const ContractViewerPage({
    super.key,
    required this.contractUrl,
    required this.title,
    this.isLocalFile = false,
  });

  Future<void> _downloadFile() async {
    if (!isLocalFile) {
      final Uri url = Uri.parse(contractUrl);
      // Opens in external browser/downloader
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        debugPrint('Could not launch contract URL');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          // Download Button in AppBar (only for network files)
          if (!isLocalFile)
            IconButton(
              onPressed: _downloadFile,
              icon: const Icon(Icons.download_rounded),
              tooltip: 'Download PDF',
            ),
        ],
      ),
      // View PDF internally
      body: isLocalFile
          ? SfPdfViewer.file(
              File(contractUrl),
              canShowScrollHead: false,
              canShowScrollStatus: false,
              onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Failed to load PDF: ${details.error}')),
                );
              },
            )
          : SfPdfViewer.network(
              contractUrl,
              canShowScrollHead: false,
              canShowScrollStatus: false,
              onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Failed to load PDF: ${details.error}')),
                );
              },
            ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  DashedBorderPainter(
      {this.color = Colors.black, this.strokeWidth = 1.0, this.gap = 5.0});
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final Path path = Path();
    path.addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(16)));
    final PathMetrics pathMetrics = path.computeMetrics();
    for (PathMetric pathMetric in pathMetrics) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        canvas.drawPath(
            pathMetric.extractPath(distance, distance + gap), paint);
        distance += gap * 2;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
