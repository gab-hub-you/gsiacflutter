import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../widgets/glass_card.dart';
import '../services/location_service.dart';
import 'dashboard_screen.dart';
import '../widgets/error_dialog.dart';

class CitizenValidationScreen extends StatefulWidget {
  const CitizenValidationScreen({super.key});

  @override
  State<CitizenValidationScreen> createState() => _CitizenValidationScreenState();
}

class _CitizenValidationScreenState extends State<CitizenValidationScreen> {
  int _currentStep = 1;
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _suffixController = TextEditingController();
  final _addressController = TextEditingController();
  
  String? _selectedSex;
  String? _selectedStatus;
  String? _selectedTown;
  String? _selectedTownCode;
  String? _selectedBarangay;
  DateTime? _selectedDate;

  XFile? _govIdImage;
  XFile? _selfieImage;
  final ImagePicker _picker = ImagePicker();

  final LocationService _locationService = LocationService();
  List<Map<String, String>> _municipalities = [];
  List<String> _barangays = [];
  bool _isLoadingLocations = false;

  final List<String> _sexOptions = ['Male', 'Female'];
  final List<String> _statusOptions = ['Single', 'Married', 'Widowed', 'Separated', 'Divorced'];

  @override
  void initState() {
    super.initState();
    _loadMunicipalities();
  }

  Future<void> _loadMunicipalities() async {
    setState(() => _isLoadingLocations = true);
    final towns = await _locationService.getMunicipalities();
    setState(() {
      _municipalities = towns;
      _isLoadingLocations = false;
    });
  }

  Future<void> _loadBarangays(String code) async {
    setState(() {
      _isLoadingLocations = true;
      _barangays = [];
      _selectedBarangay = null;
    });
    final brgys = await _locationService.getBarangays(code);
    setState(() {
      _barangays = brgys;
      _isLoadingLocations = false;
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _middleNameController.dispose();
    _suffixController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _presentDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0D47A1),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1A237E),
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      setState(() => _selectedDate = pickedDate);
    }
  }

  Future<void> _pickImage(bool isSelfie) async {
    final XFile? image = await _picker.pickImage(
      source: isSelfie ? ImageSource.camera : ImageSource.gallery,
      preferredCameraDevice: isSelfie ? CameraDevice.front : CameraDevice.rear,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        if (isSelfie) {
          _selfieImage = image;
        } else {
          _govIdImage = image;
        }
      });
    }
  }

  void _clearAll() {
    setState(() {
      _firstNameController.clear();
      _lastNameController.clear();
      _middleNameController.clear();
      _suffixController.clear();
      _addressController.clear();
      _selectedSex = null;
      _selectedStatus = null;
      _selectedTown = null;
      _selectedTownCode = null;
      _selectedBarangay = null;
      _selectedDate = null;
      _barangays = [];
      _govIdImage = null;
      _selfieImage = null;
      _currentStep = 1;
    });
  }

  void _handleSubmit() async {
    // Step 1: Personal Details Validation
    if (_currentStep == 1) {
      if (_formKey.currentState!.validate() && 
          _selectedDate != null && 
          _selectedTown != null && 
          _selectedBarangay != null) {
        setState(() => _currentStep = 2);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please complete all fields in Step 1')),
        );
      }
      return;
    }

    // Step 2: Documents Validation & Submission
    if (_currentStep == 2) {
      if (_govIdImage == null || _selfieImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please provide both your Valid ID and a Selfie')),
        );
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Start Submission Flow
      String? govIdUrl;
      String? selfieUrl;

      try {
        // Upload ID
        govIdUrl = await authProvider.uploadVerificationDocument(
          await _govIdImage!.readAsBytes(),
          'gov_id_${DateTime.now().millisecondsSinceEpoch}.jpg'
        );
        
        if (govIdUrl == null) throw Exception(authProvider.errorMessage ?? 'Failed to upload Government ID');

        // Upload Selfie
        selfieUrl = await authProvider.uploadVerificationDocument(
          await _selfieImage!.readAsBytes(),
          'selfie_${DateTime.now().millisecondsSinceEpoch}.jpg'
        );

        if (selfieUrl == null) throw Exception(authProvider.errorMessage ?? 'Failed to upload Selfie');

        // Finalize Citizen Validation
        final success = await authProvider.validateCitizen(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          middleName: _middleNameController.text,
          suffix: _suffixController.text,
          sex: _selectedSex,
          status: _selectedStatus,
          address: _addressController.text,
          birthdate: _selectedDate!,
          town: _selectedTown!,
          barangay: _selectedBarangay!,
          govIdUrl: govIdUrl,
          selfieUrl: selfieUrl,
        );

        if (success && mounted) {
          _showSuccessDialog();
        } else if (!success && mounted) {
          final error = authProvider.errorMessage ?? 'Submission failed';
          if (error == "No Internet Connection") {
            ErrorDialog.show(
              context,
              title: "No Internet Connection",
              message: "Please check your connectivity and try again.",
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          final error = e.toString();
          if (error.contains('SocketException') || error.contains('ClientException')) {
            ErrorDialog.show(
              context,
              title: "No Internet Connection",
              message: "Please check your connectivity and try again.",
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
            );
          }
        }
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Verification Submitted'),
        content: const Text(
          'Your profile and documents have been submitted for review. Our staff will verify your identity shortly.',
          style: TextStyle(color: Color(0xFF0D47A1)),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const DashboardScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D47A1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Back to Dashboard'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'lib/assets/image/bg.webp',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: GlassCard(
                  opacity: 0.15,
                  blur: 20,
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
                                  onPressed: () {
                                    if (_currentStep > 1) {
                                      setState(() => _currentStep = 1);
                                    } else {
                                      Navigator.pop(context);
                                    }
                                  },
                                ),
                              ),
                              Center(
                                child: Text(
                                  _currentStep == 1 ? 'Citizen Validation' : 'Identity Verification',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ).animate().fadeIn().slideY(begin: 0.2),
                          Text(
                            _currentStep == 1 ? 'Step 1: Personal Details' : 'Step 2: ID & Selfie Capture',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
                          const SizedBox(height: 16),
                          
                          if (_currentStep == 1) ...[
                             Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: _clearAll,
                                icon: const Icon(Icons.refresh_rounded, size: 18, color: Colors.white70),
                                label: const Text('Clear All', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ).animate().fadeIn(delay: 150.ms),
                            
                            const SizedBox(height: 16),
                            
                            // Province (Locked)
                            _buildLockedField(
                              label: 'Province',
                              value: 'Pangasinan',
                              icon: Icons.map_rounded,
                            ).animate().fadeIn(delay: 150.ms).slideX(),
                            
                            const SizedBox(height: 16),
                            
                            _buildMunicipalityDropdown().animate().fadeIn(delay: 200.ms).slideX(),
                            
                            const SizedBox(height: 16),
                            
                            _buildBarangayDropdown().animate().fadeIn(delay: 250.ms).slideX(),
                            
                            const SizedBox(height: 24),
                            const Divider(color: Colors.white24),
                            const SizedBox(height: 24),

                            _buildTextField(
                              controller: _firstNameController,
                              label: 'First Name',
                              hintText: 'Juan',
                              icon: Icons.person_outline_rounded,
                            ).animate().fadeIn(delay: 300.ms).slideX(),
                            
                            const SizedBox(height: 16),
                            
                            _buildTextField(
                              controller: _lastNameController,
                              label: 'Last Name',
                              hintText: 'Dela Cruz',
                              icon: Icons.person_outline_rounded,
                            ).animate().fadeIn(delay: 350.ms).slideX(),
                            
                            const SizedBox(height: 16),
                            
                            _buildTextField(
                              controller: _middleNameController,
                              label: 'Middle Name (Optional)',
                              icon: Icons.person_outline_rounded,
                              required: false,
                            ).animate().fadeIn(delay: 400.ms).slideX(),
                            
                            const SizedBox(height: 16),
                            
                            _buildTextField(
                              controller: _suffixController,
                              label: 'Suffix (e.g. Jr, III) (Optional)',
                              icon: Icons.badge_outlined,
                              required: false,
                            ).animate().fadeIn(delay: 450.ms).slideX(),
                            
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: _buildDropdown(
                                    label: 'Sex',
                                    value: _selectedSex,
                                    items: _sexOptions,
                                    onChanged: (val) => setState(() => _selectedSex = val),
                                    icon: Icons.wc_rounded,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildDropdown(
                                    label: 'Civil Status',
                                    value: _selectedStatus,
                                    items: _statusOptions,
                                    onChanged: (val) => setState(() => _selectedStatus = val),
                                    icon: Icons.favorite_border_rounded,
                                  ),
                                ),
                              ],
                            ).animate().fadeIn(delay: 500.ms).slideX(),

                            const SizedBox(height: 16),
                            
                            _buildTextField(
                              controller: _addressController,
                              label: 'Exact Home Address',
                              icon: Icons.home_rounded,
                            ).animate().fadeIn(delay: 550.ms).slideX(),
                            
                            const SizedBox(height: 16),
                            
                            _buildDatePickerField().animate().fadeIn(delay: 600.ms).slideX(),
                          ] else ...[
                            const SizedBox(height: 16),
                            _buildImageUploadSection(
                              label: 'Selfie (Face Capture)',
                              description: 'Take a clear selfie showing your face for verification.',
                              icon: Icons.face_rounded,
                              imageFile: _selfieImage,
                              onTap: () => _pickImage(true),
                            ).animate().fadeIn(delay: 200.ms).slideX(),
                            const SizedBox(height: 24),
                            _buildImageUploadSection(
                              label: 'Government Issued ID',
                              description: 'Upload a photo of your valid ID (Postal, Voter, Driver, etc.) from your gallery.',
                              icon: Icons.badge_rounded,
                              imageFile: _govIdImage,
                              onTap: () => _pickImage(false),
                            ).animate().fadeIn(delay: 400.ms).slideX(),
                            const SizedBox(height: 24),
                             const Text(
                              'Make sure the information on your ID is legible and your face is well-lit for the selfie.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white60, fontSize: 12),
                            ).animate().fadeIn(delay: 600.ms),
                          ],
                          
                          const SizedBox(height: 32),
                          
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: context.watch<AuthProvider>().isLoading ? null : _handleSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF0D47A1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: context.watch<AuthProvider>().isLoading
                                  ? const CircularProgressIndicator()
                                  : Text(
                                      _currentStep == 1 ? 'Continue to Step 2' : 'Finalize & Submit', 
                                      style: const TextStyle(fontWeight: FontWeight.bold)
                                    ),
                            ),
                          ).animate().fadeIn(delay: 700.ms).scale(),
                          
                          const SizedBox(height: 16),
                          
                          TextButton(
                            onPressed: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const DashboardScreen()),
                            ),
                            child: Text(
                              'Later, go to Dashboard',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ).animate().fadeIn(delay: 800.ms),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    required IconData icon,
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
        prefixIcon: Icon(icon, color: Colors.white70, size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: required ? (value) => value == null || value.isEmpty ? 'Required' : null : null,
    );
  }

  Widget _buildLockedField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
          children: [
            Icon(icon, color: Colors.white38, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                  Text(
                    value, 
                    style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildMunicipalityDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedTownCode,
      items: _municipalities.map((m) => DropdownMenuItem(value: m['code'], child: Text(m['name']!))).toList(),
      onChanged: (val) {
        setState(() {
          _selectedTownCode = val;
          _selectedTown = _municipalities.firstWhere((m) => m['code'] == val)['name'];
        });
        if (val != null) _loadBarangays(val);
      },
      dropdownColor: const Color(0xFF1A237E),
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: 'Town / Municipality',
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
        prefixIcon: const Icon(Icons.location_city_rounded, color: Colors.white70, size: 20),
        suffixIcon: _isLoadingLocations ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70))) : null,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
      validator: (v) => v == null ? 'Required' : null,
    );
  }

  Widget _buildBarangayDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedBarangay,
      items: _barangays.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: (val) => setState(() => _selectedBarangay = val),
      dropdownColor: const Color(0xFF1A237E),
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: 'Barangay',
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
        prefixIcon: const Icon(Icons.map_rounded, color: Colors.white70, size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
      validator: (v) => v == null ? 'Required' : null,
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    return DropdownButtonFormField<String>(
      isExpanded: true, // Added to prevent overflow
      initialValue: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
      onChanged: onChanged,
      dropdownColor: const Color(0xFF1A237E),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 13), // Slightly smaller font
        prefixIcon: Icon(icon, color: Colors.white70, size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildDatePickerField() {
    return InkWell(
      onTap: _presentDatePicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, color: Colors.white70),
            const SizedBox(width: 12),
            Text(
              _selectedDate == null ? 'Date of Birth' : DateFormat('MMMM dd, yyyy').format(_selectedDate!),
              style: TextStyle(color: _selectedDate == null ? Colors.white70 : Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploadSection({
    required String label,
    required String description,
    required IconData icon,
    required XFile? imageFile,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Text(description, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 12),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: imageFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        kIsWeb 
                          ? Image.network(imageFile.path, fit: BoxFit.cover)
                          : Image.file(File(imageFile.path), fit: BoxFit.cover),
                        Container(color: Colors.black26),
                        const Center(child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 40)),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: Colors.white38, size: 48),
                      const SizedBox(height: 12),
                      const Text('Tap to capture', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
