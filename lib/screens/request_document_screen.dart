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
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(title: const Text('New Application'), elevation: 0),
      body: SingleChildScrollView(
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
                      initialValue: _selectedType,
                      decoration: InputDecoration(
                        labelText: 'Select Certificate',
                        prefixIcon: const Icon(Icons.description_outlined),
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
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
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
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
                          : const Text('Review & Submit Application', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormHeader() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0D47A1),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Official Issuance',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ).animate().fadeIn().slideX(),
          Text(
            'Please fill out all fields carefully for faster processing.',
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStepTitle(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Color(0xFF1A237E)),
    );
  }

  Widget _buildFileUploadButton() {
    return InkWell(
      onTap: _pickFile,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!, width: 1.5),
        ),
        child: _attachedFile == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload_outlined, color: Colors.grey[400], size: 32),
                  const SizedBox(height: 8),
                  Text('Upload valid ID or requirement', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.green),
                  const SizedBox(width: 12),
                  Text(_attachedFile!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  IconButton(onPressed: () => setState(() => _attachedFile = null), icon: const Icon(Icons.close, size: 18)),
                ],
              ),
      ),
    );
  }
}
