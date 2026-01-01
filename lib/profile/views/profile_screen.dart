import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:citk_connect/auth/services/auth_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final TextEditingController _degreeController = TextEditingController(); // <--- NEW
  final TextEditingController _deptController = TextEditingController();
  final TextEditingController _semController = TextEditingController();
  final TextEditingController _hostelController = TextEditingController();
  final TextEditingController _rollController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // 1. Load Data from Local Storage
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _degreeController.text = prefs.getString('degree') ?? 'Diploma'; // <--- NEW DEFAULT
      _deptController.text = prefs.getString('dept') ?? 'CSE';
      _semController.text = prefs.getString('sem') ?? '1st Sem';
      _hostelController.text = prefs.getString('hostel') ?? 'RNB Hostel';
      _rollController.text = prefs.getString('roll') ?? 'CIT/25/CSE/001';
      _isLoading = false;
    });
  }

  // 2. Save Data to Local Storage
  Future<void> _saveUserData() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('degree', _degreeController.text); // <--- SAVE NEW FIELD
      await prefs.setString('dept', _deptController.text);
      await prefs.setString('sem', _semController.text);
      await prefs.setString('hostel', _hostelController.text);
      await prefs.setString('roll', _rollController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile Updated Successfully!'), backgroundColor: Colors.green),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authServiceProvider);
    final user = authState.value;

    return Scaffold(
      appBar: AppBar(
        title: Text("Student Profile", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.blueAccent),
            onPressed: _saveUserData,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // A. Profile Picture
                    Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
                        backgroundImage: (user?.photoURL != null) ? NetworkImage(user!.photoURL!) : null,
                        child: (user?.photoURL == null)
                            ? const Icon(Icons.person, size: 50, color: Colors.blueAccent)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.displayName ?? "Student Name",
                      style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      user?.email ?? "student@cit.ac.in",
                      style: GoogleFonts.inter(color: Colors.grey),
                    ),
                    const SizedBox(height: 30),

                    // B. Editable Fields
                    // --- NEW DEGREE FIELD ---
                    _buildTextField("Degree (e.g. Diploma, B.Tech)", _degreeController, Icons.workspace_premium),
                    
                    _buildTextField("Department", _deptController, Icons.school),
                    _buildTextField("Semester", _semController, Icons.timeline),
                    _buildTextField("Hostel", _hostelController, Icons.home_work),
                    _buildTextField("Roll Number", _rollController, Icons.badge),

                    const SizedBox(height: 30),
                    
                    // C. Logout Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                           ref.read(authServiceProvider.notifier).signOut();
                        },
                        icon: const Icon(Icons.logout, color: Colors.redAccent),
                        label: const Text("Log Out", style: TextStyle(color: Colors.redAccent)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.redAccent),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          prefixIcon: Icon(icon, color: Colors.blueAccent),
          filled: true,
          fillColor: const Color(0xFF1E1E1E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        validator: (value) => value!.isEmpty ? 'Please enter $label' : null,
      ),
    );
  }
}