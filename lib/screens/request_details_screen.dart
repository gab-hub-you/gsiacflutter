import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../models/document_request.dart';

class RequestDetailsScreen extends StatelessWidget {
  final DocumentRequest request;

  const RequestDetailsScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    int currentStep = 0;
    if (request.status == RequestStatus.underReview) currentStep = 1;
    if (request.status == RequestStatus.approved || request.status == RequestStatus.rejected) currentStep = 2;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.15),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Track Application',
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

          // Content
          SingleChildScrollView(
            child: Column(
              children: [
                _buildStickyHeader(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    children: [
                      _buildInfoCard(),
                      const SizedBox(height: 24),
                      _buildTrackingStepper(context, currentStep),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 110, 24, 32),
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
          Text(
            request.trackingNumber,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              shadows: [Shadow(color: Colors.black45, blurRadius: 8)],
            ),
          ).animate().fadeIn().slideX(),
          Text(
            'Application ID for ${request.type}',
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 0,
      color: Colors.white.withOpacity(0.92),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildDetailRow('Purpose', request.purpose),
            const Divider(height: 32),
            _buildDetailRow('Date Filed', DateFormat('MMMM dd, yyyy').format(request.dateSubmitted)),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildTrackingStepper(BuildContext context, int currentStep) {
    return Card(
      elevation: 0,
      color: Colors.white.withOpacity(0.92),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Stepper(
          physics: const NeverScrollableScrollPhysics(),
          currentStep: currentStep,
          controlsBuilder: (context, details) => const SizedBox.shrink(),
          steps: [
            Step(
              title: const Text('Application Received', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Portal recorded submission'),
              content: const SizedBox.shrink(),
              isActive: currentStep >= 0,
              state: StepState.complete,
            ),
            Step(
              title: const Text('LGU Internal Review', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Barangay staff verifying data'),
              content: const SizedBox.shrink(),
              isActive: currentStep >= 1,
              state: currentStep >= 1 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: Text(
                request.status == RequestStatus.rejected ? 'Application Declined' : 'Ready for Issuance',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(request.status == RequestStatus.rejected
                  ? 'Review complete with issues'
                  : 'Final stage processing'),
              content: _buildTerminalContent(context),
              isActive: currentStep >= 2,
              state: request.status == RequestStatus.rejected ? StepState.error : StepState.complete,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildTerminalContent(BuildContext context) {
    if (request.status == RequestStatus.approved) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your document is authorized. Please present your ID at the Barangay Hall for release.'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.file_download_outlined),
            label: const Text('Download Soft Copy'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF43A047),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      );
    } else if (request.status == RequestStatus.rejected) {
      return Container(
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red[100]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Action Required:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(height: 4),
            Text(
              request.rejectionReason ?? "Supporting documents are blurry or incomplete. Please resubmit.",
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}