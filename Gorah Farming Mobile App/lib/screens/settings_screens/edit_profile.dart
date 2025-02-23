import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/user_controller.dart';
import '../../widgets/widgets.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final goraUser = UserController().currentUser;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();



  User? user;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    if (user != null) {
      _nameController.text = goraUser?.displayName ?? "";
      _lastNameController.text = goraUser?.lastName ?? "";
      _emailController.text = goraUser?.email ?? "";
      _phoneNumberController.text = goraUser?.phoneNumber ?? "";
    }
  }

  Future<void> _updateProfile() async {
    bool reauthenticated = await _reauthenticateUser();
    if (!reauthenticated) {
      if (mounted) showSnackBar(context, "Wrong password");
      return;
    }

    try {
      if (_nameController.text != user!.displayName) {
        await user!.updateDisplayName(_nameController.text);
      }
      if (_emailController.text != user!.email) {
        await user!.verifyBeforeUpdateEmail(_emailController.text);
      }

      await db.collection('users').doc(user!.uid).set({
        'displayName': _nameController.text + _lastNameController.text,
        'firstName': _nameController.text,
        'lastName': _lastNameController.text,
        'email': _emailController.text,
        'phoneNumber': _phoneNumberController.text,
      }, SetOptions(merge: true));

      // Optionally reload user data
      UserController().reloadUser();
      await user!.reload();
      setState(() {
        user = _auth.currentUser;
      });

      if (mounted) showSnackBar(context, "Profile updated successfully");
    } catch (e) {
      if (mounted) showSnackBar(context, "Error updating profile: $e");
    }
  }

  Future<void> _updatePassword() async {
    bool reauthenticated = await _reauthenticateUser();

    if (!reauthenticated) {
      if (mounted) showSnackBar(context, "Wrong password");
      return;
    }

    try {
      await user!.updatePassword(_newPasswordController.text);
      if (mounted) showSnackBar(context, "Password updated successfully");
    } catch (e) {
      if (mounted) showSnackBar(context, "Error updating password: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (goraUser == null) {
      return const Scaffold(
        body: Center(child: CustomLoadingScreen(message: "Loading")),
      );
    } else {
      return Scaffold(
        appBar: AppBar(title: const Text("Edit Profile")),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 90,
                      backgroundColor: const Color(0x00087a22),
                      backgroundImage: _getProfileImage(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  buildTextField(context, _nameController, "First Name"),
                  const SizedBox(height: 16),
                  buildTextField(
                    context,
                    _lastNameController,
                    "Last Name",
                    validator: (value) => null,
                  ),
                  const SizedBox(height: 16),
                  buildTextField(
                    context,
                    _phoneNumberController,
                    "Phone Number",
                    validator: (value) => null,
                  ),
                  const SizedBox(height: 16),
                  buildTextField(
                    context,
                    _emailController,
                    "Email",
                    validator: _emailValidator,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _showUpdatePasswordDialog,
                          child: Text(
                            "Change Password",
                            style: theme.textTheme.labelMedium,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (!_formKey.currentState!.validate()) {
                              return;
                            } else {
                              _showUpdateProfileDialog();
                            }
                          },
                          child: Text(
                            "Apply Changes",
                            style: theme.textTheme.labelMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  void _showUpdateProfileDialog() => showDialog(
    context: context,
    builder:
        (context) => Theme(
          data: Theme.of(context),
          child: Dialog(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  const Text("Type your password to apply changes"),
                  const SizedBox(height: 16),
                  buildTextField(
                    context,
                    _passwordController,
                    "Password",
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _updateProfile();
                      Navigator.of(context).pop();
                    },
                    child: const Text("Apply Changes"),
                  ),
                ],
              ),
            ),
          ),
        ),
  );

  Future<void> _pickImage() async {
    final source = await _showImageSourceDialog();
    if (source != null) {
      final pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Choose an image source"),
            content: const Text(
              "Would you like to take a picture or choose from gallery?",
            ),
            actions: [
              TextButton(
                child: const Text("Camera"),
                onPressed: () {
                  Navigator.of(context).pop(ImageSource.camera);
                },
              ),
              TextButton(
                child: const Text("Gallery"),
                onPressed: () {
                  Navigator.of(context).pop(ImageSource.gallery);
                },
              ),
            ],
          ),
    );
  }

  Future<bool> _reauthenticateUser() async {
    String currentPassword = _passwordController.text;

    AuthCredential credential = EmailAuthProvider.credential(
      email: user!.email!,
      password: currentPassword,
    );
    try {
      await user!.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      if (mounted) showSnackBar(context, "Error reauthenticating user: $e");
      return false;
    }
  }

  void _showUpdatePasswordDialog() => showDialog(
    context: context,
    builder:
        (context) => Theme(
          data: Theme.of(context),
          child: Dialog(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    "Type your old password and the new one to apply changes",
                  ),
                  const SizedBox(height: 16),
                  buildTextField(
                    context,
                    _passwordController,
                    "Old Password",
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  buildTextField(
                    context,
                    _newPasswordController,
                    "New Password",
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  buildTextField(
                    context,
                    _confirmPasswordController,
                    "Confirm Password",
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      // Validate the passwords
                      if (_newPasswordController.text !=
                          _confirmPasswordController.text) {
                        showSnackBar(context, "Passwords do not match");
                        return;
                      }
                      try {
                        _updatePassword();
                        Navigator.of(context).pop();
                        showSnackBar(context, "Password updated successfully");
                      } catch (e) {
                        showSnackBar(context, "Error updating password: $e");
                      }
                    },
                    child: const Text("Apply Changes"),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      _showRecoverPasswordDialog();
                    },
                    child: const Text("Forgot Password?"),
                  ),
                ],
              ),
            ),
          ),
        ),
  );

  void _showRecoverPasswordDialog() => showDialog(
    context: context,
    builder:
        (dialogContext) => Theme(
          data: Theme.of(context),
          child: Dialog(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  const Text("Enter your email to recover your password"),
                  const SizedBox(height: 16),
                  buildTextField(
                    dialogContext,
                    _emailController,
                    "Email",
                    obscureText: false,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await FirebaseAuth.instance.sendPasswordResetEmail(
                          email: _emailController.text,
                        );

                        if (mounted) {
                          Navigator.of(dialogContext).pop();
                          showSnackBar(
                            context,
                            'Password recovery email sent to ${_emailController.text}',
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          showSnackBar(
                            context,
                            'Error sending password recovery email: $e',
                          );
                        }
                      }
                    },
                    child: const Text("Recover Password"),
                  ),
                ],
              ),
            ),
          ),
        ),
  );

  String? _emailValidator(String? value) {
    if (value == null || !value.contains('@')) {
      return "Please enter a valid email address";
    }
    return null;
  }

  ImageProvider _getProfileImage() {
    if (_imageFile != null) {
      return FileImage(_imageFile!);
    } else if (goraUser?.profileImage != null &&
        goraUser!.profileImage.isNotEmpty) {
      return NetworkImage(goraUser!.profileImage);
    } else {
      return const AssetImage('assets/icons/default_profile_pic_man.png');
    }
  }
}
