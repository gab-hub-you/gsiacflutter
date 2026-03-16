import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/document_request.dart';

class RequestDetailsScreen extends StatelessWidget {
  final DocumentRequest request;

  const RequestDetailsScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    bool isMunicipal = request.issuingOffice == IssuingOffice.municipal;
    int currentStep = 0;
    if (request.status == RequestStatus.verifiedByBarangay) currentStep = 1;
    if (request.status == RequestStatus.sentToMunicipal || request.status == RequestStatus.processing) {
      currentStep = isMunicipal ? 2 : 1;
    }
    if (request.status == RequestStatus.completed || request.status == RequestStatus.rejected) {
      currentStep = isMunicipal ? 3 : 2;
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Track Application',
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
          Positioned.fill(
            child: SingleChildScrollView(
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
            Colors.black.withValues(alpha: 0.35),
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
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 0,
      color: Colors.white.withValues(alpha: 0.92),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildDetailRow('Issuing Office', request.issuingOffice == IssuingOffice.barangay ? 'Barangay Office' : 'Municipal Hall'),
            const Divider(height: 32),
            _buildDetailRow('Current Location', request.currentOffice == IssuingOffice.barangay ? 'Barangay Office' : 'Municipal Hall'),
            const Divider(height: 32),
            _buildDetailRow('Status', request.statusText),
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
    bool isMunicipal = request.issuingOffice == IssuingOffice.municipal;
    int finalIndex = isMunicipal ? 3 : 2;
    
    return Card(
      elevation: 0,
      color: Colors.white.withValues(alpha: 0.92),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
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
              subtitle: const Text('Submitted via Citizen Portal'),
              content: const SizedBox.shrink(),
              isActive: currentStep >= 0,
              state: currentStep > 0 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text('Barangay Validation', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(currentStep > 1 ? 'Validated by Barangay' : 'Pending Barangay Review'),
              content: const SizedBox.shrink(),
              isActive: currentStep >= 1,
              state: currentStep > 1 ? StepState.complete : (currentStep == 1 ? StepState.editing : StepState.indexed),
            ),
            if (isMunicipal)
              Step(
                title: const Text('Municipal Processing', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(currentStep > 2 ? 'Processed by Municipal' : 'Pending Municipal Hall'),
                content: const SizedBox.shrink(),
                isActive: currentStep >= 2,
                state: currentStep > 2 ? StepState.complete : (currentStep == 2 ? StepState.editing : StepState.indexed),
              ),
            Step(
              title: Text(
                request.status == RequestStatus.rejected ? 'Application Declined' : 'Document Issued',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(request.status == RequestStatus.rejected
                  ? 'Review complete with issues'
                  : 'Ready for pickup/delivery'),
              content: _buildTerminalContent(context),
              isActive: currentStep >= finalIndex,
              state: request.status == RequestStatus.rejected ? StepState.error : (currentStep == finalIndex ? StepState.complete : StepState.indexed),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildTerminalContent(BuildContext context) {
    if (request.status == RequestStatus.completed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your requested ${request.type} is ready. Please proceed to the ${request.issuingOffice == IssuingOffice.barangay ? 'Barangay Hall' : 'Municipal Hall'} with your valid ID.'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: const Text('Show Release QR'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D47A1),
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
            const Text('Rejection Reason:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(height: 4),
            Text(
              request.rejectionReason ?? "Information provided could not be verified. Please contact your Barangay office.",
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}