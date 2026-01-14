# SmartStay Mobile Application - Test Case Document

## Project Information

**Project Title:** SmartStay - Student Hostel & Rental House Booking System  
**Platform:** Flutter Mobile Application  
**User Roles:** Tenant (Student), Property Owner  
**Document Version:** 2.0  
**Last Updated:** January 2026

---

## 1. Introduction

This document presents a comprehensive set of test cases designed to validate the functionality, reliability, and user experience of the SmartStay mobile application. The test cases are derived from the actual implemented code modules and cover both normal operational scenarios and error handling conditions. The test cases are organized by module and written in a formal academic style suitable for Final Year Project (FYP) documentation.

---

## 2. Test Case Tables by Module

### 2.1 User Registration Module

| Test Case ID | Module Name | Test Case | Expected Result |
|--------------|-------------|-----------|-----------------|
| TC-REG-001 | User Registration | Verify that a new user can access the registration page from the login screen by clicking "Sign Up" | The system navigates to the RegisterPage with a slide transition animation from right to left |
| TC-REG-002 | User Registration | Verify that user type selection cards (Tenant/Owner) display correctly with visual feedback | Cards show with icons - Search icon for Tenant ("Looking for a place"), Home Work icon for Owner ("Listing my property"), with selected card highlighted in primary color |
| TC-REG-003 | User Registration | Verify successful registration with valid full name, email, phone number, password, and user type | The system calls ApiService.registerUser(), displays success SnackBar with green background and checkmark icon, and navigates back to login page |
| TC-REG-004 | User Registration | Verify that the system rejects registration when full name field is empty | Form validation displays "Please enter your name" error message below the name field |
| TC-REG-005 | User Registration | Verify that the system rejects registration with empty email field | Form validation displays "Please enter your email" error message |
| TC-REG-006 | User Registration | Verify that the system rejects registration with invalid email format (missing @ symbol) | Form validation displays "Please enter a valid email" error message |
| TC-REG-007 | User Registration | Verify that the system rejects registration with empty phone number | Form validation displays "Please enter your phone number" error message |
| TC-REG-008 | User Registration | Verify that the system rejects phone number with less than 10 digits | Form validation displays "Please enter a valid phone number" error message |
| TC-REG-009 | User Registration | Verify that phone number input only accepts digits and is limited to 15 characters | The system applies FilteringTextInputFormatter.digitsOnly and LengthLimitingTextInputFormatter(15), preventing non-numeric input |
| TC-REG-010 | User Registration | Verify that the system rejects registration with empty password | Form validation displays "Please enter a password" error message |
| TC-REG-011 | User Registration | Verify that the system rejects password with less than 6 characters | Form validation displays "Password must be at least 6 characters" error message |
| TC-REG-012 | User Registration | Verify that the system rejects registration when password and confirm password do not match | Form validation displays "Passwords do not match" error message on confirm password field |
| TC-REG-013 | User Registration | Verify that password visibility toggle works for both password fields | Clicking the visibility icon toggles the obscureText property, showing/hiding password characters with appropriate icon change (visibility/visibility_off) |
| TC-REG-014 | User Registration | Verify that loading indicator displays during registration API call | The Create Account button shows CircularProgressIndicator with white color and 2.5 stroke width while _isLoading is true |
| TC-REG-015 | User Registration | Verify user type selection between Tenant and Owner with visual feedback | Selected card shows primary color background, shadow effect, and white text; unselected card shows grey background with dark text |
| TC-REG-016 | User Registration | Verify that registration failure from API displays appropriate error message | SnackBar displays with red background showing "Registration failed: {message}" from API response |
| TC-REG-017 | User Registration | Verify that network/exception errors during registration are handled gracefully | SnackBar displays with red background showing "An error occurred: {error}" message |

---

### 2.2 User Login Module

| Test Case ID | Module Name | Test Case | Expected Result |
|--------------|-------------|-----------|-----------------|
| TC-LOG-001 | User Login | Verify that the login page loads with proper animations (fade and slide) | The page displays with FadeTransition (0-60% duration) and SlideTransition from bottom (Offset(0, 0.3) to Offset.zero) |
| TC-LOG-002 | User Login | Verify successful login with valid email and password credentials | ApiService.loginUser() returns success, session is saved to SharedPreferences, welcome SnackBar displays, and user is navigated to appropriate dashboard |
| TC-LOG-003 | User Login | Verify that Tenant users are redirected to HomePage after successful login | System checks userType.toLowerCase() == 'tenant' and navigates using pushReplacement to HomePage(user: user) |
| TC-LOG-004 | User Login | Verify that Owner users are redirected to OwnerPage after successful login | System checks userType.toLowerCase() == 'owner' and navigates using pushReplacement to OwnerPage(user: user) |
| TC-LOG-005 | User Login | Verify that the system rejects login with empty email field | Form validation displays "Please enter your email" error message |
| TC-LOG-006 | User Login | Verify that the system rejects login with invalid email format | Form validation displays "Please enter a valid email" error message |
| TC-LOG-007 | User Login | Verify that the system rejects login with empty password | Form validation displays "Please enter your password" error message |
| TC-LOG-008 | User Login | Verify that the system rejects login with password less than 6 characters | Form validation displays "Password must be at least 6 characters" error message |
| TC-LOG-009 | User Login | Verify password visibility toggle functionality | Clicking visibility icon changes icon appearance (visibility_rounded/visibility_off_rounded) and toggles password obscureText property |
| TC-LOG-010 | User Login | Verify that user session is persisted using SharedPreferences after successful login | The system saves isLoggedIn (bool), user_id, fullName, email, userType, phoneNumber, and hasPassword to SharedPreferences |
| TC-LOG-011 | User Login | Verify automatic login when valid session exists on app launch | _checkLoginStatus() retrieves saved session data, creates User object, and calls_navigateBasedOnUserType() to redirect user |
| TC-LOG-012 | User Login | Verify that login button shows loading indicator during authentication | CircularProgressIndicator displays in button with white color and 2.5 strokeWidth while _isLoading is true |
| TC-LOG-013 | User Login | Verify that failed login displays appropriate error message from API | SnackBar displays with red background showing "Login failed: {message}" from API response |
| TC-LOG-014 | User Login | Verify that unknown user type displays appropriate error message | SnackBar displays "Unknown user type. Please contact support." message |
| TC-LOG-015 | User Login | Verify navigation to registration page from login screen | Clicking "Sign Up" TextButton navigates to RegisterPage with PageRouteBuilder and SlideTransition animation |

---

### 2.3 User Profile Management Module

| Test Case ID | Module Name | Test Case | Expected Result |
|--------------|-------------|-----------|-----------------|
| TC-PROF-001 | User Profile Management | Verify that Tenant profile screen (ProfileScreen) displays user information correctly | The screen displays user's full name, email from the User model, along with profile avatar with gradient background |
| TC-PROF-002 | User Profile Management | Verify that Owner profile page (ProfilePage) displays user information correctly | The screen displays user's full name, email, with profile header and menu items for account settings |
| TC-PROF-003 | User Profile Management | Verify navigation to Personal Info page from profile | Clicking "Personal Information" menu item navigates to PersonalInfoPage with user data passed as parameter |
| TC-PROF-004 | User Profile Management | Verify that Personal Info page displays editable fields (name, email, phone) | The page shows _buildEditableField() for each field with current values from User model |
| TC-PROF-005 | User Profile Management | Verify inline editing functionality for profile fields | Clicking edit icon on a field calls _startEditing(), showing text input with save/cancel buttons |
| TC-PROF-006 | User Profile Management | Verify successful update of user name through PersonalInfoPage | _saveField() validates input and calls UserService to update profile, displaying success feedback |
| TC-PROF-007 | User Profile Management | Verify successful update of phone number through PersonalInfoPage | System validates phone format, calls API to update, and reflects changes in UI |
| TC-PROF-008 | User Profile Management | Verify cancel editing restores original field value | _cancelEditing() restores controller text to original value and exits edit mode |
| TC-PROF-009 | User Profile Management | Verify password change functionality in Personal Info | _buildPasswordField() displays password section with change password option, validating current and new password |
| TC-PROF-010 | User Profile Management | Verify user type display (read-only) in Personal Info | _buildUserTypeSelector() shows user type with appropriate icon (search for Tenant, home_work for Owner) in non-editable format |
| TC-PROF-011 | User Profile Management | Verify navigation to Rental History page from profile | Clicking "Rental History" menu item navigates to RentalHistoryPage with user data |
| TC-PROF-012 | User Profile Management | Verify logout confirmation dialog displays | _showLogoutDialog() shows AlertDialog with "Logout" title, confirmation message, and Cancel/Logout buttons |
| TC-PROF-013 | User Profile Management | Verify successful logout clears session and redirects to login | _handleLogout() clears SharedPreferences (isLoggedIn=false), and navigates to LoginPage with pushAndRemoveUntil |

---

### 2.4 Property Listing Module (Add, Edit, Delete, View)

| Test Case ID | Module Name | Test Case | Expected Result |
|--------------|-------------|-----------|-----------------|
| TC-PROP-001 | Property Listing | Verify that Owner can access Add Listing page from dashboard | Tapping "Add Listing" quick action navigates to AddListingPage with proper navigation |
| TC-PROP-002 | Property Listing | Verify Add Listing form displays all required fields | Form displays: title, address, postcode, description, price, deposit, deposit months, bedrooms, bathrooms, area sqft, max tenants, available from date, minimum tenure dropdown |
| TC-PROP-003 | Property Listing | Verify successful property listing creation with images | _submitForm() validates form, uploads images via DatabaseService.uploadImages(), creates Listing object, calls DatabaseService.addListing() |
| TC-PROP-004 | Property Listing | Verify multiple image selection from gallery | _pickImages() uses ImagePicker.pickMultiImage() and adds selected images to_selectedImages list |
| TC-PROP-005 | Property Listing | Verify video selection from gallery | _pickVideos() uses FilePicker.pickFiles() with type: FileType.video, allowMultiple: true, adds to_selectedVideos list |
| TC-PROP-006 | Property Listing | Verify image capture using device camera | _captureImage() uses ImagePicker.pickImage(source: ImageSource.camera) and adds captured image to_selectedImages |
| TC-PROP-007 | Property Listing | Verify video capture using device camera | _captureVideo() uses ImagePicker.pickVideo(source: ImageSource.camera) with 30 second maxDuration |
| TC-PROP-008 | Property Listing | Verify contract/agreement PDF upload | _pickContract() uses FilePicker.pickFiles() with type: FileType.custom and allowedExtensions: ['pdf'], uploads via DatabaseService.uploadContract() |
| TC-PROP-009 | Property Listing | Verify media options bottom sheet displays all upload options | _showMediaOptions() shows bottom sheet with: Gallery Photos, Gallery Videos, Take Photo, Record Video options |
| TC-PROP-010 | Property Listing | Verify Listings page displays Owner's properties with filter tabs | ListingsPage displays filter tabs (All, Active, Inactive) using _buildFilterTabs() with count badges |
| TC-PROP-011 | Property Listing | Verify property card displays correct information | _buildPropertyCard() shows: image slider, title, address, price, bedrooms, bathrooms, status badge |
| TC-PROP-012 | Property Listing | Verify Edit Listing page pre-populates existing property data | EditListingPage._initializeControllers() sets controller values from listing: title, address, postcode, description, price, etc. |
| TC-PROP-013 | Property Listing | Verify successful property update with modified data | _submitForm() in EditListingPage validates changes, uploads new media, calls DatabaseService.updateListing() with updated Listing and deletedMediaUrls |
| TC-PROP-014 | Property Listing | Verify existing media can be removed during edit | _removeExistingMedia() adds URL to_deletedMediaUrls list, removes from _existingMediaUrls, triggers rebuild |
| TC-PROP-015 | Property Listing | Verify property status toggle (Active/Inactive) | _updateListingStatus() calls DatabaseService.updateListingStatus() with new status, refreshes listing |
| TC-PROP-016 | Property Listing | Verify property deactivation confirmation dialog | _showDeactivateConfirmation() displays AlertDialog with warning message and Deactivate/Cancel buttons |
| TC-PROP-017 | Property Listing | Verify property deletion confirmation dialog | _showDeleteConfirmation() displays AlertDialog with "This action cannot be undone" warning and Delete/Cancel buttons |
| TC-PROP-018 | Property Listing | Verify successful property deletion | _deleteListing() calls DatabaseService.deleteListing(), removes from local list, shows success message |
| TC-PROP-019 | Property Listing | Verify date picker for Available From field | _buildDatePicker() shows DatePickerDialog with firstDate: DateTime.now(), allowing future dates only |
| TC-PROP-020 | Property Listing | Verify minimum tenure dropdown options | _buildModernDropdown() displays: 3 months, 6 months, 9 months, 12 months options |
| TC-PROP-021 | Property Listing | Verify empty listings state displays appropriate message | _buildEmptyWidget() shows different messages based on filter: "No properties listed yet" (All), "No active listings" (Active), "No inactive listings" (Inactive) |

---

### 2.5 Property Search & Filter Module

| Test Case ID | Module Name | Test Case | Expected Result |
|--------------|-------------|-----------|-----------------|
| TC-SRCH-001 | Property Search & Filter | Verify search bar displays on HomePage with proper styling | _buildModernSearchBar() renders Container with search icon, hint text "Search by location...", and clear icon when text exists |
| TC-SRCH-002 | Property Search & Filter | Verify location search suggestions appear while typing | _onSearchChanged() implements debounce (300ms), calls PropertySearchService.searchLocationsWithCount(), displays results in_buildSearchSuggestions() |
| TC-SRCH-003 | Property Search & Filter | Verify search suggestions display location name and property count | SearchLocation model shows name and propertyCount in suggestion tiles |
| TC-SRCH-004 | Property Search & Filter | Verify selecting a location loads matching properties | _selectLocation() sets_selectedLocation and calls _loadPropertiesForLocation() with PropertySearchService.searchPropertiesByLocation() |
| TC-SRCH-005 | Property Search & Filter | Verify property cards display correctly in search results | _buildPropertyCard() shows: image slider with InlineImageSlider, property title, address, price formatted as "RM{price}/month", info chips for bedrooms/bathrooms |
| TC-SRCH-006 | Property Search & Filter | Verify pagination of search results | _loadPropertiesForLocation() accepts page parameter, PropertySearchResponse includes totalPages and currentPage for pagination control |
| TC-SRCH-007 | Property Search & Filter | Verify clear search functionality | _clearSearch() clears_searchController, sets _isSearching=false,_selectedLocation=null, restores all listings |
| TC-SRCH-008 | Property Search & Filter | Verify no results state displays appropriately | _buildNoResultsState() shows message when_displayedListings is empty with search active |
| TC-SRCH-009 | Property Search & Filter | Verify PropertyService.getAllListings() loads all active properties | Service builds request with pagination (page, limit) and returns processed listings list |
| TC-SRCH-010 | Property Search & Filter | Verify search with minimum and maximum price filtering | PropertyService.getAllListings() accepts minPrice and maxPrice parameters for filtering |
| TC-SRCH-011 | Property Search & Filter | Verify search with bedroom count filtering | PropertyService.getAllListings() accepts bedrooms parameter for filtering |
| TC-SRCH-012 | Property Search & Filter | Verify search with bathroom count filtering | PropertyService.getAllListings() accepts bathrooms parameter for filtering |
| TC-SRCH-013 | Property Search & Filter | Verify only Active status properties appear in tenant search | Properties with status 'Active' are returned by API, inactive/suspended properties excluded |

---

### 2.6 Property Details View Module

| Test Case ID | Module Name | Test Case | Expected Result |
|--------------|-------------|-----------|-----------------|
| TC-DET-001 | Property Details View | Verify property details page loads with all listing information | PropertyDetailsPage displays all Listing fields: title, address, description, price, deposit, bedrooms, bathrooms, areaSqft, maxTenants, availableFrom |
| TC-DET-002 | Property Details View | Verify image slider displays all property images with pagination | PropertyDetailsImageSlider shows images using PageView with dot indicators for navigation |
| TC-DET-003 | Property Details View | Verify video playback in property media gallery | SliderMediaItem with type==SliderMediaType.video initializes VideoPlayerController, displays play/pause controls |
| TC-DET-004 | Property Details View | Verify full screen image viewer opens on image tap | _openFullScreenMediaViewer() navigates to FullScreenImageViewer with media list and initial index |
| TC-DET-005 | Property Details View | Verify property overview section displays key metrics | _buildOverviewItem() shows: bedrooms with bed icon, bathrooms with bathtub icon, area sqft with square_foot icon, max tenants with group icon |
| TC-DET-006 | Property Details View | Verify price header displays monthly rent and deposit | _buildPriceHeader() shows "RM {price}" with "/month" suffix and deposit amount "Deposit: RM {deposit}" |
| TC-DET-007 | Property Details View | Verify Book Now button is displayed in bottom bar | _buildBottomBar() renders ElevatedButton with "Book Now" text that navigates to BookingRequestPage |
| TC-DET-008 | Property Details View | Verify Contact Owner button opens contact dialog | Tapping Contact button calls _showContactDialog() displaying owner contact options |
| TC-DET-009 | Property Details View | Verify contact dialog shows message option | _showContactDialog() includes option to open chat with OwnerChatScreen passing owner details |
| TC-DET-010 | Property Details View | Verify property description displays full text | Description section shows full listing.description in Text widget with proper styling |
| TC-DET-011 | Property Details View | Verify available from date is formatted correctly | DateTime.availableFrom displayed using DateFormat for user-friendly format |
| TC-DET-012 | Property Details View | Verify minimum tenure information is displayed | minimumTenure field (e.g., "12 months") shown in property details section |

---

### 2.7 Booking Request & Approval Module

| Test Case ID | Module Name | Test Case | Expected Result |
|--------------|-------------|-----------|-----------------|
| TC-BOOK-001 | Booking Request & Approval | Verify BookingRequestPage displays property summary card | _buildPropertySummaryCard() shows property image, title, address, and price from passed Listing object |
| TC-BOOK-002 | Booking Request & Approval | Verify booking details form displays check-in date picker | _buildBookingDetailsCard() includes date selector, calling_selectCheckInDate() with DatePickerDialog |
| TC-BOOK-003 | Booking Request & Approval | Verify rental duration options display (3, 6, 12 months) | _buildDurationOption() renders selectable cards for each duration with visual feedback on selection |
| TC-BOOK-004 | Booking Request & Approval | Verify cost calculation updates based on selected duration | _calculateCosts() computes: monthlyRent, depositAmount (price × depositMonths), totalAmount based on selected duration |
| TC-BOOK-005 | Booking Request & Approval | Verify personal info card displays tenant information | _buildPersonalInfoCard() shows user's fullName, email, phoneNumber from User model |
| TC-BOOK-006 | Booking Request & Approval | Verify cost summary displays breakdown of all charges | _buildCostSummaryCard() shows: Monthly Rent, Deposit, Duration, Total Amount Due with_buildCostRow() formatting |
| TC-BOOK-007 | Booking Request & Approval | Verify terms and conditions checkbox is required | _buildTermsCheckbox() renders Checkbox that must be checked (_acceptedTerms=true) before submission |
| TC-BOOK-008 | Booking Request & Approval | Verify identity verification section for ID upload | _buildIdentityVerificationCard() displays front and back ID capture options using_buildIDCardSection() |
| TC-BOOK-009 | Booking Request & Approval | Verify ID capture using camera opens IdCardCameraPage | _captureIdImage() navigates to IdCardCameraPage with 'front' or 'back' side parameter, returns File on success |
| TC-BOOK-010 | Booking Request & Approval | Verify PDF generation from captured ID images | _generatePdfWithImages() creates PDF with front and back ID images using pdf package, adds watermarks |
| TC-BOOK-011 | Booking Request & Approval | Verify file picker allows PDF/image upload for ID | _pickIdFile() uses FilePicker.pickFiles() with allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'] |
| TC-BOOK-012 | Booking Request & Approval | Verify successful booking submission | _submitBookingRequest() sends HTTP POST to bookings_api.php with all booking data including ID document |
| TC-BOOK-013 | Booking Request & Approval | Verify existing pending booking check | _checkExistingBooking() queries API for existing pending bookings for same user and listing |
| TC-BOOK-014 | Booking Request & Approval | Verify existing booking dialog displays appropriate options | _showExistingBookingDialog() explains existing pending request and offers to proceed or cancel |
| TC-BOOK-015 | Booking Request & Approval | Verify success dialog displays after booking submission | _showSuccessDialog() shows confirmation with checkmark animation and booking details summary |
| TC-BOOK-016 | Booking Request & Approval | Verify Owner receives booking requests in Reservations page | ReservationsPage._loadReservations() fetches pending bookings with tenant and property details |
| TC-BOOK-017 | Booking Request & Approval | Verify Owner can view booking details before approval | _buildReservationCard() displays tenant name, property info, check-in date, duration, amounts |
| TC-BOOK-018 | Booking Request & Approval | Verify Owner can approve booking request | _showAcceptDialog() confirms approval, calls_updateBookingStatus() with 'confirmed' status |
| TC-BOOK-019 | Booking Request & Approval | Verify Owner can decline booking request with reason | _showDeclineDialog() allows entering reason, calls_updateBookingStatus() with 'rejected' status |
| TC-BOOK-020 | Booking Request & Approval | Verify booking status update reflects immediately | _updateBookingStatus() sends HTTP POST to API, reloads reservations on success |
| TC-BOOK-021 | Booking Request & Approval | Verify Reservations page filter tabs (Pending, Confirmed, History) | _buildCustomTabBar() renders three tabs with_buildTabItem() showing count badges |

---

### 2.8 Upload Supporting Documents Module (Image or PDF)

| Test Case ID | Module Name | Test Case | Expected Result |
|--------------|-------------|-----------|-----------------|
| TC-DOC-001 | Upload Supporting Documents | Verify ID camera page loads with camera preview | IdCardCameraPage._initializeCamera() detects available cameras, initializes CameraController with ResolutionPreset.high |
| TC-DOC-002 | Upload Supporting Documents | Verify ID card overlay frame displays on camera | IdCardOverlayPainter draws semi-transparent overlay with clear ID card frame area and corner decorations |
| TC-DOC-003 | Upload Supporting Documents | Verify camera flip between front and rear cameras | _flipCamera() toggles_currentCameraIndex, reinitializes camera with _setupCamera() |
| TC-DOC-004 | Upload Supporting Documents | Verify ID image capture and cropping | _captureAndCrop() takes picture, crops to ID card frame area, returns processed File |
| TC-DOC-005 | Upload Supporting Documents | Verify captured ID preview displays before confirmation | _buildIDCardSection() shows captured image with remove/retake options in Card widget |
| TC-DOC-006 | Upload Supporting Documents | Verify front and back ID images are stored separately | _frontIdImage and_backIdImage File variables maintain both sides of ID document |
| TC-DOC-007 | Upload Supporting Documents | Verify PDF generation creates properly formatted document | _generatePdfWithImages() uses pdf package to create multi-page PDF with ID images, watermarks, and styling |
| TC-DOC-008 | Upload Supporting Documents | Verify PDF preview dialog displays generated document | _showPdfGeneratedDialog() shows generated PDF file with preview and confirm options |
| TC-DOC-009 | Upload Supporting Documents | Verify file picker accepts only valid formats (PDF, JPG, PNG) | _pickIdFile() specifies allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'], rejects other formats |
| TC-DOC-010 | Upload Supporting Documents | Verify uploaded document displays in preview | _showFilePreviewDialog() shows image preview for JPG/PNG or PDF indicator for PDF files |
| TC-DOC-011 | Upload Supporting Documents | Verify document upload progress indication | Upload process shows loading indicator while _isSubmitting is true |
| TC-DOC-012 | Upload Supporting Documents | Verify temporary files are cleaned up after use | _cleanupTempFiles() deletes generated PDF and temporary files after submission or cancellation |
| TC-DOC-013 | Upload Supporting Documents | Verify Owner can view tenant ID documents in reservations | Messages screen _viewIdDocument() retrieves id_document_url from BookingStatus and opens document viewer |
| TC-DOC-014 | Upload Supporting Documents | Verify PDF documents render correctly in viewer | System uses SfPdfViewer or appropriate viewer to display PDF documents from URL |

---

### 2.9 Booking Status Tracking Module

| Test Case ID | Module Name | Test Case | Expected Result |
|--------------|-------------|-----------|-----------------|
| TC-STAT-001 | Booking Status Tracking | Verify Tenant bookings load in Messages screen Bookings tab | _loadBookings() fetches booking data from API, populates_bookings list with BookingStatus objects |
| TC-STAT-002 | Booking Status Tracking | Verify booking card displays property and status information | _buildBookingCard() shows: property image, title, address, status chip, check-in date, duration, total amount |
| TC-STAT-003 | Booking Status Tracking | Verify status chip displays correct color based on status | _buildStatusChip() returns: orange for 'pending', green for 'confirmed'/'paid', red for 'cancelled', blue for others |
| TC-STAT-004 | Booking Status Tracking | Verify booking details dialog displays comprehensive information | _showBookingDetailsDialog() shows full booking info: dates, amounts, owner contact, payment status |
| TC-STAT-005 | Booking Status Tracking | Verify check-out date calculation from check-in and duration | BookingStatus.checkOut getter calculates checkout by adding (durationMonths × 30 days) to checkInDate |
| TC-STAT-006 | Booking Status Tracking | Verify payment status tracking (paid/unpaid) | BookingStatus.isPaymentCompleted checks paymentStatus=='paid' or hasPaymentTransaction |
| TC-STAT-007 | Booking Status Tracking | Verify "Pay Now" button appears for confirmed unpaid bookings | isConfirmedAndNotPaid getter returns true for status=='confirmed' && !isPaymentCompleted, showing payment button |
| TC-STAT-008 | Booking Status Tracking | Verify TenantBookingsPage displays categorized bookings | TabBar shows Pending, Confirmed, Completed tabs; _buildBookingsList() filters by status |
| TC-STAT-009 | Booking Status Tracking | Verify booking cancellation functionality | _cancelBooking() sends cancellation request to API, updates booking status to 'cancelled' |
| TC-STAT-010 | Booking Status Tracking | Verify empty bookings state displays appropriate message | _buildEmptyBookingsState() shows "No bookings yet" message with icon when_bookings is empty |
| TC-STAT-011 | Booking Status Tracking | Verify auto-refresh updates booking status | _startAutoRefresh() sets up Timer.periodic to refresh bookings at regular intervals |
| TC-STAT-012 | Booking Status Tracking | Verify Owner reservation view shows tenant information | ReservationCard displays tenant_name, tenant_email, tenant_phone from booking data |

---

### 2.10 Messaging & Chat Module

| Test Case ID | Module Name | Test Case | Expected Result |
|--------------|-------------|-----------|-----------------|
| TC-MSG-001 | Messaging & Chat | Verify Messages screen loads conversations list | _loadConversations() fetches conversation data from MessageService, populates_messages list |
| TC-MSG-002 | Messaging & Chat | Verify conversation tile displays sender info and preview | _buildMessageTile() shows: avatar with gradient, sender name, last message preview, timestamp, unread indicator |
| TC-MSG-003 | Messaging & Chat | Verify unread message indicator displays count | MessagePreview.unreadCount > 0 shows badge with count on conversation tile |
| TC-MSG-004 | Messaging & Chat | Verify opening chat marks messages as read | _openChat() navigates to chat screen and triggers_markMessagesAsRead() to update read status |
| TC-MSG-005 | Messaging & Chat | Verify OwnerChatScreen loads message history | _loadMessages() fetches chat messages from API using conversationId, displays in ListView |
| TC-MSG-006 | Messaging & Chat | Verify message bubble styling for incoming messages | _buildMessageBubble() renders left-aligned bubble with grey background for received messages |
| TC-MSG-007 | Messaging & Chat | Verify message bubble styling for outgoing messages | _buildMessageBubble() renders right-aligned bubble with primary color gradient for sent messages |
| TC-MSG-008 | Messaging & Chat | Verify date dividers between messages from different days | _isDifferentDay() checks dates,_buildDateDivider() renders date separator between message groups |
| TC-MSG-009 | Messaging & Chat | Verify send message functionality | _sendMessage() validates non-empty input, sends to API, clears input, scrolls to bottom |
| TC-MSG-010 | Messaging & Chat | Verify message input field with send button | _buildMessageInput() renders TextField with send IconButton, disabled when empty |
| TC-MSG-011 | Messaging & Chat | Verify chat auto-scrolls to latest message | _scrollToBottom() animates ScrollController to maxScrollExtent after new message |
| TC-MSG-012 | Messaging & Chat | Verify message timestamp displays correctly | _formatMessageTime() formats DateTime to "HH:mm" or "MMM d, HH:mm" based on date |
| TC-MSG-013 | Messaging & Chat | Verify tab switching between Messages and Bookings | TabBar with two tabs controls display of _buildMessagesTab() and_buildBookingsTab() |

---

### 2.11 Payment Processing Module

| Test Case ID | Module Name | Test Case | Expected Result |
|--------------|-------------|-----------|-----------------|
| TC-PAY-001 | Payment Processing | Verify ToyyibPayPaymentScreen displays booking summary | _buildBookingSummary() shows: property title, check-in date, duration, monthly rent, deposit, total amount |
| TC-PAY-002 | Payment Processing | Verify summary row formatting for payment details | _buildSummaryRow() renders label/value pairs with proper styling and alignment |
| TC-PAY-003 | Payment Processing | Verify Pay Now button initiates payment process | _buildPayButton() calls_processPayment() on tap when not loading |
| TC-PAY-004 | Payment Processing | Verify payment processing with ToyyibPay API | _processPayment() sends HTTP request to create bill, receives billCode and payment URL |
| TC-PAY-005 | Payment Processing | Verify external payment URL opens in browser | url_launcher package opens ToyyibPay payment URL for user to complete transaction |
| TC-PAY-006 | Payment Processing | Verify payment status check dialog displays | _showPaymentCheckDialog() shows dialog with "Check Payment Status" button after payment attempt |
| TC-PAY-007 | Payment Processing | Verify payment status polling | _checkPaymentStatus() queries API with billCode to verify payment completion |
| TC-PAY-008 | Payment Processing | Verify successful payment navigates to success screen | On confirmed payment, system navigates to PaymentSuccessScreen with transaction details |
| TC-PAY-009 | Payment Processing | Verify PaymentSuccessScreen displays confirmation | Screen shows success animation, payment amount, transaction reference, formatted paid date |
| TC-PAY-010 | Payment Processing | Verify receipt row formatting on success screen | _buildReceiptRow() displays transaction details in receipt format |
| TC-PAY-011 | Payment Processing | Verify security badges display on payment screen | _buildSecurityBadges() shows trust indicators for secure payment processing |
| TC-PAY-012 | Payment Processing | Verify mock payment mode for testing | isMockMode flag enables simulated payment without actual transaction |

---

### 2.12 Favorites/Saved Properties Module

| Test Case ID | Module Name | Test Case | Expected Result |
|--------------|-------------|-----------|-----------------|
| TC-FAV-001 | Favorites | Verify FavoritesPage loads user's saved properties | _loadFavoriteListings() loads favorite IDs from SharedPreferences and fetches listing details |
| TC-FAV-002 | Favorites | Verify favorite toggle adds property to favorites | _toggleFavorite() adds listing.id to_favoriteIds Set and saves to SharedPreferences |
| TC-FAV-003 | Favorites | Verify favorite toggle removes property from favorites | _toggleFavorite() removes listing.id when already favorited, updates SharedPreferences |
| TC-FAV-004 | Favorites | Verify favorite property card displays correctly | _buildFavoritePropertyCard() shows: InlineImageSlider, title, address, price, remove favorite button |
| TC-FAV-005 | Favorites | Verify empty favorites state displays appropriate message | _buildEmptyState() shows EmptyState widget with "No favorites yet" message and icon |
| TC-FAV-006 | Favorites | Verify tapping favorite card navigates to property details | Card onTap navigates to PropertyDetailsPage with full Listing object |
| TC-FAV-007 | Favorites | Verify favorites persist across app sessions | _loadFavoriteIds() retrieves from SharedPreferences on init;_saveFavoriteIds() saves changes |
| TC-FAV-008 | Favorites | Verify favorites update when returning from property details | didUpdateWidget() compares favoriteIds and reloads if changed |

---

### 2.13 Navigation & Dashboard Module

| Test Case ID | Module Name | Test Case | Expected Result |
|--------------|-------------|-----------|-----------------|
| TC-NAV-001 | Navigation | Verify HomePage displays LiquidNavBar for Tenant users | Bottom navigation shows: Explore, Favorites, Messages, Profile tabs with liquid animation |
| TC-NAV-002 | Navigation | Verify OwnerPage displays bottom navigation for Owner users | _buildBottomNavBar() shows: Dashboard, Listings, Reservations, Messages, Profile icons |
| TC-NAV-003 | Navigation | Verify Owner dashboard loads statistics | _loadDashboardData() fetches from DashboardService: active listings count, pending reservations, total views |
| TC-NAV-004 | Navigation | Verify Owner stat cards display correctly | _buildStatCard() shows: title, value, icon with color, and optional onTap navigation |
| TC-NAV-005 | Navigation | Verify Owner quick actions navigate correctly | _buildQuickAction() cards navigate to AddListingPage, ListingsPage, ReservationsPage |
| TC-NAV-006 | Navigation | Verify recent activity section displays updates | _buildActivityItem() shows RecentActivity with icon, title, description, timestamp |
| TC-NAV-007 | Navigation | Verify welcome card displays Owner name | _buildWelcomeCard() shows "Welcome, {user.fullName}" with greeting message |
| TC-NAV-008 | Navigation | Verify tab switching updates current screen | _currentIndex state controls which screen widget is displayed (Explore, Favorites, etc.) |
| TC-NAV-009 | Navigation | Verify error state displays retry option | _buildErrorState() shows error message with "Retry" button calling_loadDashboardData() |
| TC-NAV-010 | Navigation | Verify loading state displays shimmer/skeleton | _buildLoadingState() shows SkeletonLoader or CircularProgressIndicator during data fetch |

---

## 3. Test Case Summary

| Module | Total Test Cases | Normal Scenarios | Error Scenarios |
|--------|------------------|------------------|-----------------|
| User Registration | 17 | 11 | 6 |
| User Login | 15 | 10 | 5 |
| User Profile Management | 13 | 10 | 3 |
| Property Listing (Add, Edit, Delete, View) | 21 | 16 | 5 |
| Property Search & Filter | 13 | 11 | 2 |
| Property Details View | 12 | 11 | 1 |
| Booking Request & Approval | 21 | 17 | 4 |
| Upload Supporting Documents | 14 | 11 | 3 |
| Booking Status Tracking | 12 | 10 | 2 |
| Messaging & Chat | 13 | 12 | 1 |
| Payment Processing | 12 | 10 | 2 |
| Favorites/Saved Properties | 8 | 7 | 1 |
| Navigation & Dashboard | 10 | 9 | 1 |
| **Total** | **181** | **145** | **36** |

---

## 4. Test Case Naming Convention

The test case identifiers follow a standardized naming convention for easy reference and traceability:

| Module | Prefix | Example |
|--------|--------|---------|
| User Registration | TC-REG | TC-REG-001 |
| User Login | TC-LOG | TC-LOG-001 |
| User Profile Management | TC-PROF | TC-PROF-001 |
| Property Listing | TC-PROP | TC-PROP-001 |
| Property Search & Filter | TC-SRCH | TC-SRCH-001 |
| Property Details View | TC-DET | TC-DET-001 |
| Booking Request & Approval | TC-BOOK | TC-BOOK-001 |
| Upload Supporting Documents | TC-DOC | TC-DOC-001 |
| Booking Status Tracking | TC-STAT | TC-STAT-001 |
| Messaging & Chat | TC-MSG | TC-MSG-001 |
| Payment Processing | TC-PAY | TC-PAY-001 |
| Favorites/Saved Properties | TC-FAV | TC-FAV-001 |
| Navigation & Dashboard | TC-NAV | TC-NAV-001 |

---

## 5. Technical Reference

### 5.1 Key Files Referenced

| Module | Primary Files |
|--------|--------------|
| Registration | `lib/register.dart` |
| Login | `lib/login.dart` |
| Profile (Tenant) | `lib/pages/tenant/profile_screen.dart`, `lib/pages/tenant/personal_info_page.dart` |
| Profile (Owner) | `lib/pages/owner/profile_page.dart`, `lib/pages/owner/personal_info_page.dart` |
| Property Listing | `lib/pages/owner/add_listing_page.dart`, `lib/pages/owner/edit_listing_page.dart`, `lib/pages/owner/listings_page.dart` |
| Property Search | `lib/pages/tenant/home_page.dart`, `lib/services/property_search_service.dart` |
| Property Details | `lib/pages/tenant/property_details_page.dart`, `lib/pages/owner/property_details_page.dart` |
| Booking | `lib/pages/tenant/booking_request_page.dart`, `lib/pages/owner/reservations_page.dart` |
| Documents | `lib/widgets/id_card_camera.dart`, `lib/pages/tenant/booking_request_page.dart` |
| Status Tracking | `lib/pages/tenant/messages_screen.dart`, `lib/pages/tenant/tenant_booking_page.dart` |
| Messaging | `lib/pages/tenant/messages_screen.dart`, `lib/widgets/chat_screen.dart` |
| Payment | `lib/pages/tenant/toyyibpay_payment_screen.dart` |
| Favorites | `lib/pages/tenant/favorites_page.dart` |
| Navigation | `lib/pages/tenant/home_page.dart`, `lib/pages/owner/owner_page.dart`, `lib/widgets/liquid_nav_bar.dart` |

### 5.2 Key Models

| Model | File | Purpose |
|-------|------|---------|
| User | `lib/models/user_model.dart` | User authentication and profile data |
| Listing | `lib/models/listing.dart` | Property listing information |
| BookingStatus | `lib/models/booking_status.dart` | Booking request and status tracking |
| ChatMessage | `lib/models/chat_message.dart` | Chat message data |
| PropertyListing | `lib/services/property_search_service.dart` | Search result property data |

### 5.3 Key Services

| Service | File | Purpose |
|---------|------|---------|
| ApiService | `lib/services/api_service.dart` | Authentication API calls |
| DatabaseService | `lib/services/database_service.dart` | Property CRUD operations |
| PropertyService | `lib/services/property_service.dart` | Property query operations |
| PropertySearchService | `lib/services/property_search_service.dart` | Location and property search |
| MessageService | `lib/services/message_service.dart` | Chat and messaging operations |
| UserService | `lib/services/user_service.dart` | User profile operations |

---

## 6. Conclusion

This test case document provides a comprehensive framework for validating the SmartStay mobile application's functionality across all implemented modules. The test cases are derived directly from the actual codebase, referencing specific functions, methods, and UI components to ensure accurate and traceable testing.

The 181 test cases cover:

- **User Authentication**: Registration and login flows for both Tenant and Owner roles
- **Profile Management**: Viewing and editing user profile information
- **Property Management**: Complete CRUD operations for property listings
- **Search & Discovery**: Location-based property search with filtering
- **Booking System**: End-to-end booking request, approval, and status tracking
- **Document Handling**: ID capture, PDF generation, and document upload
- **Communication**: In-app messaging between tenants and property owners
- **Payment Processing**: Integration with ToyyibPay payment gateway
- **User Experience**: Favorites, navigation, and dashboard features

Execution of these test cases will ensure the application meets the required quality standards for deployment and provides a reliable experience for both Tenant and Property Owner users.

---

*Document Version: 2.0*  
*Based on Codebase Analysis: January 2026*  
*Project: SmartStay - Student Hostel & Rental House Booking System*
