import 'package:flutter/material.dart';
import 'package:draftproject/services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _agreedToTerms = false;
  String _selectedEnrollType = 'Resident';
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // Controllers
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _nicController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _nicController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Convert enrollment type to role
  String _getRole(String enrollType) {
    switch (enrollType) {
      case 'Resident':
        return 'resident';
      case 'Truck Driver':
        return 'driver';
      case 'City Management':
        return 'cityManagement';
      default:
        return 'resident';
    }
  }

  void _handleSignUp() async {
    if (_formKey.currentState!.validate() && _agreedToTerms) {
      try {
        setState(() {
          _isLoading = true;
        });

        final user = await _authService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          role: _getRole(_selectedEnrollType),
          name: _nameController.text.trim(),
          username: _usernameController.text.trim(),
          nic: _nicController.text.trim(),
          address: _addressController.text.trim(),
          contactNumber: _contactController.text.trim(),
        );

        setState(() {
          _isLoading = false;
        });

        if (user != null && mounted) {
          // Registration successful
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration successful!')),
          );
          
          // Navigate based on role
          if (user.role == 'resident') {
            Navigator.pushReplacementNamed(context, '/resident_location');
          } else if (user.role == 'driver') {
            Navigator.pushReplacementNamed(context, '/driver_home');
          } else if (user.role == 'cityManagement') {
            Navigator.pushReplacementNamed(context, '/city_management_home');
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Registration failed. Please try again.')),
            );
          }
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    } else if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the terms and conditions')),
      );
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'This field is required';
            }
            if (label == 'Email Address' && !_isValidEmail(value)) {
              return 'Please enter a valid email';
            }
            if (label == 'Contact Number' && !_isValidPhone(value)) {
              return 'Please enter a valid 10-digit phone number';
            }
            if (label == 'Password' && value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            if (label == 'Re-enter Password' && value != _passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            items: items.map((String item) {
              return DropdownMenuItem(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
            decoration: const InputDecoration(
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    return RegExp(r'^\d{10}$').hasMatch(phone);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                elevation: 4,
                color: const Color(0xFFFFFFFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            'Sign up',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        _buildTextField(
                          controller: _nameController,
                          label: 'Name',
                          hintText: 'Enter your name',
                        ),
                        
                        _buildDropdownField(
                          label: 'Enroll Type',
                          value: _selectedEnrollType,
                          items: ['Resident', 'Truck Driver', 'City Management'],
                          onChanged: (value) {
                            setState(() {
                              _selectedEnrollType = value!;
                            });
                          },
                        ),
                        
                        _buildTextField(
                          controller: _usernameController,
                          label: 'Username',
                          hintText: 'Enter your username',
                        ),
                        
                        _buildTextField(
                          controller: _nicController,
                          label: 'NIC',
                          hintText: 'Enter your NIC number',
                        ),
                        
                        _buildTextField(
                          controller: _addressController,
                          label: 'Address',
                          hintText: 'Enter your address',
                        ),
                        
                        _buildTextField(
                          controller: _contactController,
                          label: 'Contact Number',
                          hintText: 'Enter your contact number',
                          keyboardType: TextInputType.phone,
                        ),
                        
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email Address',
                          hintText: 'Enter your email address',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        
                        _buildTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hintText: 'Enter your password',
                          isPassword: true,
                        ),
                        
                        _buildTextField(
                          controller: _confirmPasswordController,
                          label: 'Re-enter Password',
                          hintText: 'Re-enter your password',
                          isPassword: true,
                        ),
                        
                        Row(
                          children: [
                            Checkbox(
                              value: _agreedToTerms,
                              onChanged: (value) {
                                setState(() {
                                  _agreedToTerms = value!;
                                });
                              },
                            ),
                            Expanded(
                              child: Text(
                                'I agree to the terms of use, Privacy policy and Data Processing agreement',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleSignUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    'Continue',
                                    style: TextStyle(
                                      color: Color(0xFFFFFFFF),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Already have an account? ',
                              style: TextStyle(color: Colors.grey),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacementNamed(context, '/login');
                              },
                              child: const Text(
                                'Sign in',
                                style: TextStyle(
                                  color: Color(0xFF005FFF),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}