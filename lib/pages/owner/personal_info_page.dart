// lib/pages/personal_info_page.dart

import 'package:flutter/material.dart';
import 'package:my_app/models/user_model.dart';
import 'package:my_app/services/user_service.dart';

class PersonalInfoPage extends StatefulWidget {
  final User user;

  const PersonalInfoPage({super.key, required this.user});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;
  late String _userType;
  String? _editingField;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _fullNameController = TextEditingController(text: widget.user.fullName);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phoneNumber);
    _passwordController = TextEditingController(text: '');
    _userType = widget.user.userType;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _startEditing(String fieldName) {
    // Don't allow editing userType
    if (fieldName == 'userType') return;

    setState(() {
      _editingField = fieldName;
      if (fieldName == 'password') {
        _passwordController.clear(); // Clear password field when editing starts
      }
    });
  }

  void _cancelEditing() {
    // Reset controller to original value
    switch (_editingField) {
      case 'fullName':
        _fullNameController.text = widget.user.fullName;
        break;
      case 'email':
        _emailController.text = widget.user.email;
        break;
      case 'phone':
        _phoneController.text = widget.user.phoneNumber;
        break;
      case 'password':
        _passwordController.clear();
        break;
      case 'userType':
        _userType = widget.user.userType;
        break;
    }

    setState(() {
      _editingField = null;
    });
  }

  Future<void> _saveField() async {
    if (_editingField == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Create a copy of the current user
      final updatedUser = User(
        id: widget.user.id,
        fullName: widget.user.fullName,
        email: widget.user.email,
        phoneNumber: widget.user.phoneNumber,
        userType: widget.user.userType, // User type remains unchanged
        hasPassword: widget.user.hasPassword,
      );

      // Update only the specific field being edited
      String? newPassword;

      switch (_editingField) {
        case 'fullName':
          updatedUser.fullName = _fullNameController.text;
          break;
        case 'email':
          updatedUser.email = _emailController.text;
          break;
        case 'phone':
          updatedUser.phoneNumber = _phoneController.text;
          break;
        case 'password':
          if (_passwordController.text.isNotEmpty) {
            newPassword = _passwordController.text;
            updatedUser.hasPassword = true;
          }
          break;
      }

      // Use UserService to save the changes
      final userService = UserService();
      final User result = await userService.updateUser(
        updatedUser,
        newPassword: newPassword,
        // Only update the specific field
        updateField: _editingField == 'password' ? null : _editingField,
      );

      // Update the local user object with returned data
      setState(() {
        widget.user.fullName = result.fullName;
        widget.user.email = result.email;
        widget.user.phoneNumber = result.phoneNumber;
        // User type remains unchanged
        widget.user.hasPassword = result.hasPassword;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('${_getFieldLabel(_editingField!)} updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _editingField = null; // Exit editing mode
      });
    }
  }

  String _getFieldLabel(String fieldName) {
    switch (fieldName) {
      case 'fullName':
        return 'Full Name';
      case 'email':
        return 'Email';
      case 'phone':
        return 'Phone Number';
      case 'password':
        return 'Password';
      case 'userType':
        return 'Account Type';
      default:
        return 'Information';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Personal Information'),
        backgroundColor: const Color(0xFF190152),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Basic Information'),
                  const SizedBox(height: 16),
                  _buildEditableField(
                    label: 'Full Name',
                    value: widget.user.fullName,
                    fieldName: 'fullName',
                    controller: _fullNameController,
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 16),
                  _buildEditableField(
                    label: 'Email',
                    value: widget.user.email,
                    fieldName: 'email',
                    controller: _emailController,
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  _buildEditableField(
                    label: 'Phone Number',
                    value: widget.user.phoneNumber,
                    fieldName: 'phone',
                    controller: _phoneController,
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Security'),
                  const SizedBox(height: 16),
                  _buildPasswordField(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Account Type'),
                  const SizedBox(height: 16),
                  _buildUserTypeSelector(),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF190152),
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required String value,
    required String fieldName,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final bool isEditing = _editingField == fieldName;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isEditing ? const Color(0xFF190152) : Colors.grey[300]!,
          width: isEditing ? 2 : 1,
        ),
      ),
      child: isEditing
          ? Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    keyboardType: keyboardType,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: label,
                      prefixIcon: Icon(icon, color: const Color(0xFF190152)),
                      border: InputBorder.none,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _cancelEditing,
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: _saveField,
                        child: const Text('Save',
                            style: TextStyle(color: Color(0xFF190152))),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : ListTile(
              leading: Icon(icon, color: const Color(0xFF190152)),
              title: Text(label),
              subtitle: Text(value),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _startEditing(fieldName),
                color: const Color(0xFF190152),
              ),
            ),
    );
  }

  Widget _buildPasswordField() {
    final bool isEditing = _editingField == 'password';

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isEditing ? const Color(0xFF190152) : Colors.grey[300]!,
          width: isEditing ? 2 : 1,
        ),
      ),
      child: isEditing
          ? Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon:
                          const Icon(Icons.lock, color: Color(0xFF190152)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: const Color(0xFF190152),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _cancelEditing,
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: _saveField,
                        child: const Text('Save',
                            style: TextStyle(color: Color(0xFF190152))),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : ListTile(
              leading: const Icon(Icons.lock, color: Color(0xFF190152)),
              title: const Text('Password'),
              subtitle: Text(widget.user.hasPassword
                  ? '•••••••• (Password hidden for security)'
                  : 'No password set'),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _startEditing('password'),
                color: const Color(0xFF190152),
              ),
            ),
    );
  }

  Widget _buildUserTypeSelector() {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Icon(_userTypeIcon(), color: const Color(0xFF190152)),
        title: const Text('Account Type'),
        subtitle: Text(_userTypeText()),
        trailing: const Tooltip(
          message: 'Account type cannot be changed',
          child: Icon(Icons.lock_outline, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildRadioTile(String title, String value) {
    return RadioListTile<String>(
      title: Text(title),
      value: value,
      groupValue: _userType,
      activeColor: const Color(0xFF190152),
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _userType = newValue;
          });
        }
      },
    );
  }

  IconData _userTypeIcon() {
    switch (_userType) {
      case 'tenant':
        return Icons.home;
      case 'owner':
        return Icons.apartment;
      default:
        return Icons.person;
    }
  }

  String _userTypeText() {
    switch (_userType) {
      case 'tenant':
        return 'Tenant';
      case 'owner':
        return 'Owner';
      default:
        return _userType.isNotEmpty ? _userType : 'Unknown';
    }
  }
}
