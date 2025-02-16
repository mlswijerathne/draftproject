import 'package:draftproject/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  bool isLoading = false;
  File? _imageFile;
  String? profileImageUrl;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nicController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _getProfileImageUrl();
  }

  void _initializeControllers() {
    _nameController.text = widget.user.name;
    _nicController.text = widget.user.nic;
    _addressController.text = widget.user.address;
    _contactController.text = widget.user.contactNumber;
    _emailController.text = widget.user.email;
    _usernameController.text = widget.user.username;
  }

  Future<void> _getProfileImageUrl() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .get();
      if (doc.exists && doc.data()!.containsKey('profileImageUrl')) {
        setState(() {
          profileImageUrl = doc.data()!['profileImageUrl'] as String;
        });
      }
    } catch (e) {
      print('Error getting profile image: $e');
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${widget.user.uid}.jpg');

      await ref.putFile(_imageFile!);
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .update({'profileImageUrl': url});

      setState(() {
        profileImageUrl = url;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_validateFields()) return;

    try {
      setState(() => isLoading = true);

      if (_imageFile != null) {
        await _uploadImage();
      }

      final updatedUser = UserModel(
        uid: widget.user.uid,
        name: _nameController.text.trim(),
        role: widget.user.role,
        username: _usernameController.text.trim(),
        nic: _nicController.text.trim(),
        address: _addressController.text.trim(),
        contactNumber: _contactController.text.trim(),
        email: _emailController.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .update(updatedUser.toMap());

      setState(() => isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    }
  }

  bool _validateFields() {
    if (!RegExp(r'^\d{10}$').hasMatch(_contactController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit contact number')),
      );
      return false;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return false;
    }

    if (!RegExp(r'^([0-9]{9}[vVxX]|[0-9]{12})$').hasMatch(_nicController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid NIC number')),
      );
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!) as ImageProvider
                          : (profileImageUrl != null
                              ? NetworkImage(profileImageUrl!)
                              : const AssetImage('assets/images/resident/default_profile_picture.jpg'))
                              as ImageProvider,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Color(0xFF59A867),
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  
                ),
                color: Color(0xFFFFFFFF), 
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputField("Username", "@sandaruwan", _usernameController),
                      _buildInputField("NIC", "200108300200", _nicController),
                      _buildInputField("Address", "dambulla", _addressController),
                      _buildInputField("Contact Number", "0766298200", _contactController),
                      _buildInputField("Email", "lakshitha@gmail.com", _emailController),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF59A867),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    isLoading ? 'Saving...' : 'Save Changes',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
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

  Widget _buildInputField(
    String label,
    String hintText,
    TextEditingController controller, {
    bool isLast = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF3F3F3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 0,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 16,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.edit,
                  color: Colors.grey[600],
                  size: 20,
                ),
                onPressed: () {
                  // Handle edit button press
                },
              ),
            ],
          ),
        ),
        if (!isLast) const SizedBox(height: 16),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    super.dispose();
  }
}
