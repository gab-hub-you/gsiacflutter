import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/document_provider.dart';

class RequestDocumentScreen extends StatefulWidget {
  const RequestDocumentScreen({super.key});

  @override
  State<RequestDocumentScreen> createState() => _RequestDocumentScreenState();
}

class _RequestDocumentScreenState extends State<RequestDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedType = 'Barangay Clearance';
  final _purposeController = TextEditingController();
  PlatformFile? _attachedFile;

  final List<String> _docTypes = [
    'Barangay Clearance',
    'Certificate of Residency',
    'Indigency Certificate',
  ];

  void _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() => _attachedFile = result.files.first);
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<DocumentProvider>(context, listen: false);
      final trk = await provider.submitRequest(
        type: _selectedType,
        purpose: _purposeController.text,
        attachmentPath: _attachedFile?.path,
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.15),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'New Application',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        flexibleSpace: ClipRect(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'lib/assets/image/bg.webp',
              fit: BoxFit.cover,
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
                    Colors.black.withOpacity(0.45),
                    Colors.black.withOpacity(0.25),
                  ],
                ),
              ),
            ),
          ),

          // Main Content
          SingleChildScrollView(
            child: Column(
              children: [
                _buildFormHeader(),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildStepTitle('1. Document Selection'),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _selectedType,
                          decoration: InputDecoration(
                            labelText: 'Select Certificate',
                            prefixIcon: const Icon(Icons.description_outlined),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.92),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: _docTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                          onChanged: (v) => setState(() => _selectedType = v!),
                        ),
                        const SizedBox(height: 24),
                        _buildStepTitle('2. State Your Purpose'),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _purposeController,
                          decoration: InputDecoration(
                            hintText: 'e.g. For employment, ID application, etc.',
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.92),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          maxLines: 4,
                          validator: (v) => v!.isEmpty ? 'Please specify your purpose' : null,
                        ),
                        const SizedBox(height: 24),
                        _buildStepTitle('3. Supporting Evidence'),
                        const SizedBox(height: 12),
                        _buildFileUploadButton(),
                        const SizedBox(height: 48),
                        ElevatedButton(
                          onPressed: context.watch<DocumentProvider>().isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D47A1),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 60),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                            shadowColor: const Color(0xFF0D47A1).withOpacity(0.4),
                          ),
                          child: context.watch<DocumentProvider>().isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Review & Submit Application',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ],
                    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1),
                  ),
                ),
              ],
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
            Colors.black.withOpacity(0.35),
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
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
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
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
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
                  Text(_attachedFile!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  IconButton(
                      onPressed: () => setState(() => _attachedFile = null),
                      icon: const Icon(Icons.close, size: 18)),
                ],
              ),
      ),
    );
  }
}