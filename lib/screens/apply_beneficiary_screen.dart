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
  const ApplyBeneficiaryScreen({super.key});

  @override
  State<ApplyBeneficiaryScreen> createState() => _ApplyBeneficiaryScreenState();
}

class _ApplyBeneficiaryScreenState extends State<ApplyBeneficiaryScreen> {
  BeneficiaryProgram? _selectedProgram;
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
    if (_selectedProgram == null) return;
    
    // Check if all requirements have a file
    for (var req in _selectedProgram!.requirements) {
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
        const SnackBar(content: Text('Your account verification is currently pending. Please wait for approval.')),
      );
      return;
    }

    try {
      final provider = Provider.of<BeneficiaryProvider>(context, listen: false);
      final trackingId = await provider.submitApplication(
        citizenId: user.id,
        program: _selectedProgram!,
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
              Navigator.pop(context); // Go back to dashboard
            },
            child: const Text('Back to Dashboard'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BeneficiaryProvider>();
    final programs = provider.programs;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Social Benefits Platform',
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
            child: _selectedProgram == null 
                ? _buildProgramList(programs) 
                : _buildApplicationForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramList(List<BeneficiaryProgram> programs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available Programs',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black45, blurRadius: 4)]),
          ).animate().fadeIn().slideX(),
          const SizedBox(height: 8),
          const Text(
            'Select a program to view eligibility and apply.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 24),
          ...programs.asMap().entries.map((entry) {
            final index = entry.key;
            final program = entry.value;
            return _buildProgramCard(program).animate().fadeIn(delay: (200 + index * 100).ms).slideY(begin: 0.2);
          }),
        ],
      ),
    );
  }

  Widget _buildProgramCard(BeneficiaryProgram program) {
    IconData icon;
    Color color;
    switch (program.type) {
      case BenefitType.financial:
        icon = Icons.attach_money_rounded;
        color = Colors.green;
        break;
      case BenefitType.medical:
        icon = Icons.medical_services_rounded;
        color = Colors.redAccent;
        break;
      case BenefitType.scholarship:
        icon = Icons.school_rounded;
        color = Colors.blue;
        break;
      default:
        icon = Icons.card_giftcard_rounded;
        color = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white.withValues(alpha: 0.95),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.white.withValues(alpha: 0.5))),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => setState(() => _selectedProgram = program),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(program.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(program.paymentSchedule, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 16),
                ],
              ),
              const SizedBox(height: 12),
              Text(program.description, style: TextStyle(color: Colors.grey[800], fontSize: 13)),
            ],
          ),
        ),
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
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() {
                  _selectedProgram = null;
                  _attachedFiles.clear();
                }),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              Expanded(
                child: Text(
                  'Apply for ${_selectedProgram!.name}',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildFormSection(
            title: 'Program Eligibility & Benefits',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_selectedProgram!.description, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 12),
                if (_selectedProgram!.amount != null) ...[
                  Text('Benefit Amount: PHP ${_selectedProgram!.amount}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                ],
                Text('Schedule: ${_selectedProgram!.paymentSchedule}', style: const TextStyle(fontWeight: FontWeight.w500)),
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
                ..._selectedProgram!.requirements.map((req) => Padding(
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
