import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/beneficiary_program.dart';
import '../models/citizen.dart';
import '../providers/auth_provider.dart';
import '../providers/beneficiary_provider.dart';
import 'citizen_validation_screen.dart';

class ApplyBeneficiaryScreen extends StatefulWidget {
  final BeneficiaryProgram program;
  const ApplyBeneficiaryScreen({super.key, required this.program});

  @override
  State<ApplyBeneficiaryScreen> createState() => _ApplyBeneficiaryScreenState();
}

class _ApplyBeneficiaryScreenState extends State<ApplyBeneficiaryScreen> {
  final Map<String, PlatformFile> _attachedFiles = {}; // Maps requirement name to file

  void _pickFile(String requirement) async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _attachedFiles[requirement] = result.files.first;
      });
    }
  }

  void _submitApplication() async {
    // Check if all requirements have a file
    for (var req in widget.program.requirements) {
      if (!_attachedFiles.containsKey(req)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please upload: $req')),
        );
        return;
      }
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    
    if (user == null || user.verificationStatus == VerificationStatus.unverified) {
       _showVerificationDialog();
       return;
    } else if (user.verificationStatus == VerificationStatus.pending) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your account verification is currently pending. Please wait for approval before applying.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    } else if (user.verificationStatus == VerificationStatus.rejected) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your account verification was rejected. Please update your profile and re-verify to apply.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      final provider = Provider.of<BeneficiaryProvider>(context, listen: false);
      final trackingId = await provider.submitApplication(
        citizenId: user.id,
        program: widget.program,
        docs: _attachedFiles.values.map((f) => {
          'name': f.name,
          'bytes': f.bytes,
          'path': f.path,
        }).toList(),
      );

      if (mounted) {
        _showSuccessDialog(trackingId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e')),
        );
      }
    }
  }

  // ... (Dialog methods remain same)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Benefit Application',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
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
          SafeArea(
            child: _buildApplicationForm(),
          ),
        ],
      ),
    );
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Verification Required'),
        content: const Text(
          'You must be a verified citizen to apply for social welfare programs. Please complete your profile validation first.',
          style: TextStyle(color: Color(0xFF0D47A1)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
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
  }

  void _showSuccessDialog(String trk) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Application Submitted'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text('Your application has been received!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Tracking ID: $trk', textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text(
              'Your application is pending Barangay review.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Go back to details
              Navigator.pop(context); // Go back to list
            },
            child: const Text('Back to Programs'),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationForm() {
    final auth = context.read<AuthProvider>();
    final user = auth.user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Applying for ${widget.program.name}',
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ).animate().fadeIn().slideX(),
          if (user?.verificationStatus != VerificationStatus.verified) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      user?.verificationStatus == VerificationStatus.pending 
                        ? 'Your verification is pending approval.' 
                        : user?.verificationStatus == VerificationStatus.rejected 
                          ? 'Your verification was rejected.' 
                          : 'You must be verified to apply.',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ).animate().shake(),
          ],
          const SizedBox(height: 24),
          _buildFormSection(
            title: 'Program Eligibility & Benefits',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.program.description, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 12),
                if (widget.program.amount != null) ...[
                  Text('Benefit Amount: PHP ${widget.program.amount}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                ],
                Text('Schedule: ${widget.program.paymentSchedule}', style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ).animate().fadeIn().slideY(),
          const SizedBox(height: 16),
          _buildFormSection(
            title: 'Applicant Information',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Name', user?.displayName ?? ''),
                const Divider(),
                _buildInfoRow('Address', user?.address ?? ''),
                const Divider(),
                _buildInfoRow('Contact', user?.phoneNumber ?? ''),
                const SizedBox(height: 8),
                const Text('Prefilled from your verified profile.', style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms).slideY(),
          const SizedBox(height: 16),
          _buildFormSection(
            title: 'Requirements Checklist',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Please upload a clear copy of each required document.',
                  style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 16),
                ...widget.program.requirements.map((req) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.description_outlined, color: Color(0xFF0D47A1), size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(req, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _pickFile(req),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: _attachedFiles.containsKey(req) ? Colors.green.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _attachedFiles.containsKey(req) ? Colors.green.withValues(alpha: 0.5) : Colors.blue.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _attachedFiles.containsKey(req) ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                                color: _attachedFiles.containsKey(req) ? Colors.green : Colors.blue,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _attachedFiles.containsKey(req) ? _attachedFiles[req]!.name : 'Upload Document',
                                  style: TextStyle(
                                    color: _attachedFiles.containsKey(req) ? Colors.green[700] : Colors.blue[700],
                                    fontWeight: _attachedFiles.containsKey(req) ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_attachedFiles.containsKey(req))
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => setState(() => _attachedFiles.remove(req)),
                                  icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: context.watch<BeneficiaryProvider>().isSubmitting ? null : _submitApplication,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: context.watch<BeneficiaryProvider>().isSubmitting 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Submit Application', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ).animate().fadeIn(delay: 300.ms).scale(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildFormSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
          Expanded(child: Text(value.isEmpty ? 'Not specified' : value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
