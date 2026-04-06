import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/document_provider.dart';
import '../providers/auth_provider.dart';
import '../models/citizen.dart';
import '../models/document_request.dart';
import 'citizen_validation_screen.dart';

class RequestDocumentScreen extends StatefulWidget {
  const RequestDocumentScreen({super.key});

  @override
  State<RequestDocumentScreen> createState() => _RequestDocumentScreenState();
}

class _RequestDocumentScreenState extends State<RequestDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<IssuingOffice, List<String>> _categorizedDocs = {
    IssuingOffice.barangay: [
      'Barangay Clearance',
      'Certificate of Residency',
      'Certificate of Indigency',
      'Barangay Business Clearance',
      'Certificate of No Objection',
      'Barangay ID',
    ],
    IssuingOffice.municipal: [
      'Community Tax Certificate (Cedula)',
      'Business Permit',
      'Birth Certificate',
      'Marriage Certificate',
      'Death Certificate',
      'Real Property Tax Clearance',
      'Maps and Planning Documents',
    ],
  };

  IssuingOffice? _selectedOffice;
  String? _selectedType;
  final _purposeController = TextEditingController();
  PlatformFile? _attachedFile;

  @override
  void dispose() {
    _purposeController.dispose();
    super.dispose();
  }

  void _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() => _attachedFile = result.files.first);
    }
  }

  void _submit() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    final status = user?.verificationStatus ?? VerificationStatus.unverified;

    if (status != VerificationStatus.verified) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(status == VerificationStatus.unverified ? 'Verification Required' : 'Verification Pending'),
          content: Text(
            status == VerificationStatus.unverified 
              ? 'You must be a verified citizen to submit document requests. Please complete your profile validation first.'
              : 'Your verification is currently under review. Please wait for staff approval before submitting requests.',
            style: const TextStyle(color: Color(0xFF0D47A1)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            if (status == VerificationStatus.unverified)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CitizenValidationScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Verify Now'),
              )
          ],
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      try {
        final provider = Provider.of<DocumentProvider>(context, listen: false);
        final trk = await provider.submitRequest(
          citizenId: user?.id ?? '',
          type: _selectedType!,
          purpose: _purposeController.text,
          office: _selectedOffice!,
          attachmentPath: _attachedFile?.path,
          attachmentBytes: _attachedFile?.bytes,
          attachmentFileName: _attachedFile?.name,
        );

        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text('Success'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 64),
                  const SizedBox(height: 16),
                  const Text('Application Submitted', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('Your tracking number is $trk', textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  const Text(
                    'Note: Municipal requests are first validated by the Barangay.',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  child: const Text('Back to Dashboard'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Submission failed: ${e.toString()}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isVerified = user?.verificationStatus == VerificationStatus.verified;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'New Application',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'lib/assets/image/bg.webp',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),

          // Dark overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.45),
                    Colors.black.withValues(alpha: 0.25),
                  ],
                ),
              ),
            ),
          ),

          // Main Content
          Positioned.fill(
            child: SingleChildScrollView(
              child: Column(
                children: [
                   _buildFormHeader(),
                  if (!isVerified)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: Colors.orangeAccent),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Verification Required: You can fill out this form, but submission requires a verified account.',
                                style: TextStyle(color: Colors.white70, fontSize: 11), // Slightly smaller font
                                overflow: TextOverflow.clip, // Prevent push
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn().slideY(begin: -0.2),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildStepTitle('1. Issuing Office'),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildOfficeTab(IssuingOffice.barangay, 'Barangay Office', Icons.home_work_rounded),
                              const SizedBox(width: 8), // Reduced from 12
                              _buildOfficeTab(IssuingOffice.municipal, 'Municipal Hall', Icons.location_city_rounded),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildStepTitle('2. Document Type'),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            isExpanded: true, // Force expansion to prevent overflow
                            value: _selectedType, // Changed from initialValue to value for better sync
                            decoration: InputDecoration(
                              hintText: _selectedOffice == null ? 'Select Office First' : 'Select Document',
                              prefixIcon: const Icon(Icons.description_outlined),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.92),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: _selectedOffice == null 
                              ? [] 
                              : _categorizedDocs[_selectedOffice!]!.map((type) => DropdownMenuItem(
                                  value: type, 
                                  child: Text(
                                    type,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )).toList(),
                            onChanged: (v) => setState(() => _selectedType = v!),
                            validator: (v) => v == null ? 'Please select a document' : null,
                          ),
                          const SizedBox(height: 24),
                          _buildStepTitle('3. Purpose'),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _purposeController,
                            decoration: InputDecoration(
                              hintText: 'e.g. For employment, ID application, etc.',
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.92),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            maxLines: 4,
                            validator: (v) => v!.isEmpty ? 'Please specify your purpose' : null,
                          ),
                          const SizedBox(height: 24),
                          _buildStepTitle('4. Supporting Evidence'),
                          const SizedBox(height: 12),
                          _buildFileUploadButton(),
                          const SizedBox(height: 48),
                          ElevatedButton(
                            onPressed: context.watch<DocumentProvider>().isSubmitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D47A1),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 60),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 4,
                              shadowColor: const Color(0xFF0D47A1).withValues(alpha: 0.4),
                            ),
                            child: context.watch<DocumentProvider>().isSubmitting
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    isVerified ? 'Review & Submit Application' : 'Submit (Requires Verification)',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 100, 24, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.35),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Official Issuance',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black45, blurRadius: 8)]),
          ).animate().fadeIn().slideX(),
          Text(
            'Please fill out all fields carefully for faster processing.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStepTitle(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
        color: Colors.white,
        shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
      ),
    );
  }

  Widget _buildFileUploadButton() {
    return InkWell(
      onTap: _pickFile,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
        ),
        child: _attachedFile == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload_outlined, color: Colors.grey[400], size: 32),
                  const SizedBox(height: 8),
                  Text('Upload valid ID or requirement',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _attachedFile!.name, 
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                      onPressed: () => setState(() => _attachedFile = null),
                      icon: const Icon(Icons.close, size: 18)),
                ],
              ),
      ),
    );
  }

  Widget _buildOfficeTab(IssuingOffice office, String label, IconData icon) {
    bool isSelected = _selectedOffice == office;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() {
          _selectedOffice = office;
          _selectedType = null;
        }),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0D47A1) : Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected ? [
              BoxShadow(
                color: const Color(0xFF0D47A1).withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ] : [],
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 28,
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[800],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis, // Added ellipsis
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}