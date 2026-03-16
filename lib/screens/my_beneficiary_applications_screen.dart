import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../providers/beneficiary_provider.dart';
import '../models/beneficiary_application.dart';
import '../widgets/app_drawer.dart';
import '../providers/auth_provider.dart';
import 'beneficiary_details_screen.dart';

class MyBeneficiaryApplicationsScreen extends StatefulWidget {
  const MyBeneficiaryApplicationsScreen({super.key});

  @override
  State<MyBeneficiaryApplicationsScreen> createState() => _MyBeneficiaryApplicationsScreenState();
}

class _MyBeneficiaryApplicationsScreenState extends State<MyBeneficiaryApplicationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<BeneficiaryProvider>().fetchApplications(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BeneficiaryProvider>();
    final applications = provider.applications;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('My Benefits', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D47A1),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          final user = context.read<AuthProvider>().user;
          if (user != null) {
            await provider.fetchApplications(user.id);
          }
        },
        child: Stack(
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
            provider.isLoading && applications.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : applications.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
                        itemCount: applications.length,
                        itemBuilder: (context, index) {
                          final app = applications[index];
                          return _buildApplicationCard(app, context).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.2);
                        },
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.volunteer_activism_outlined, size: 80, color: Colors.white.withValues(alpha: 0.7)),
          const SizedBox(height: 16),
          const Text('No Applications Found', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('You have not applied for any social benefits yet.', style: TextStyle(color: Colors.white70)),
        ],
      ).animate().fadeIn(delay: 200.ms),
    );
  }

  Widget _buildApplicationCard(BeneficiaryApplication app, BuildContext context) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (app.status) {
      case ApplicationStatus.pendingBarangay:
        statusColor = Colors.orange;
        statusText = 'Pending Barangay';
        statusIcon = Icons.hourglass_top_rounded;
        break;
      case ApplicationStatus.pendingMunicipal:
        statusColor = Colors.blue;
        statusText = 'Municipal Review';
        statusIcon = Icons.loop_rounded;
        break;
      case ApplicationStatus.approved:
        statusColor = Colors.green;
        statusText = 'Approved';
        statusIcon = Icons.check_circle_rounded;
        break;
      case ApplicationStatus.rejected:
        statusColor = Colors.red;
        statusText = 'Rejected';
        statusIcon = Icons.cancel_rounded;
        break;
      case ApplicationStatus.suspended:
        statusColor = Colors.grey;
        statusText = 'Suspended';
        statusIcon = Icons.block_rounded;
        break;
    }

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BeneficiaryApplicationDetailsScreen(application: app)),
      ),
      borderRadius: BorderRadius.circular(20),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        color: Colors.white.withValues(alpha: 0.95),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.white.withValues(alpha: 0.5))),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      app.programName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, color: statusColor, size: 14),
                        const SizedBox(width: 4),
                        Text(statusText, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('TRK: ${app.trackingId}', style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text('Submitted: ${DateFormat('MMM dd, yyyy').format(app.dateSubmitted)}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              
              if (app.remarks != null && app.remarks!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                  child: Text('Remarks: ${app.remarks!}', style: TextStyle(color: Colors.grey[800], fontSize: 13, fontStyle: FontStyle.italic)),
                ),
              ],
    
              if (app.status == ApplicationStatus.approved && app.qrCode != null) ...[
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Beneficiary ID', style: TextStyle(fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      onPressed: () => _showQRCode(context, app),
                      icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                      label: const Text('View ID'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D47A1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: Size.zero,
                      ),
                    ),
                  ],
                ),
              ],
              
              const Divider(height: 24),
              _buildTrackingStepper(app),
            ],
          ),
        ),
      ),
    );
  }

  void _showQRCode(BuildContext context, BeneficiaryApplication app) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(app.programName, textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Icon(Icons.qr_code_2_rounded, size: 150, color: Colors.black87), // Mock QR
            ),
            const SizedBox(height: 16),
            const Text('Present this QR Code to partner establishments or municipal staff.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Text('Valid since: ${DateFormat('MMM dd, yyyy').format(app.approvalDate!)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingStepper(BeneficiaryApplication app) {
    int currentStep = 0;
    if (app.status == ApplicationStatus.pendingMunicipal) currentStep = 1;
    if (app.status == ApplicationStatus.approved) currentStep = 2;
    if (app.status == ApplicationStatus.rejected || app.status == ApplicationStatus.suspended) currentStep = 2; // End of line

    return Row(
      children: [
        _buildStepIndicator('Submitted', true),
        _buildStepLine(currentStep >= 1),
        _buildStepIndicator('Barangay', currentStep >= 1),
        _buildStepLine(currentStep >= 2),
        _buildStepIndicator('Municipal', currentStep >= 2, isError: app.status == ApplicationStatus.rejected || app.status == ApplicationStatus.suspended),
      ],
    );
  }

  Widget _buildStepIndicator(String label, bool isActive, {bool isError = false}) {
    final color = isError ? Colors.red : (isActive ? Colors.green : Colors.grey[300]!);
    final iconColor = isActive ? Colors.white : Colors.transparent;

    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Icon(isError ? Icons.close : Icons.check, size: 16, color: iconColor),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: isActive ? Colors.black87 : Colors.grey, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _buildStepLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 16, left: 4, right: 4),
        color: isActive ? Colors.green : Colors.grey[300],
      ),
    );
  }
}
