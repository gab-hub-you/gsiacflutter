import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/beneficiary_application.dart';

class BeneficiaryApplicationDetailsScreen extends StatelessWidget {
  final BeneficiaryApplication application;

  const BeneficiaryApplicationDetailsScreen({super.key, required this.application});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Application Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildStatusCard(),
                  const SizedBox(height: 24),
                  _buildInfoSection(context),
                  const SizedBox(height: 24),
                  _buildDocumentsSection(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          application.programName,
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black45, blurRadius: 4)]),
        ).animate().fadeIn().slideX(),
        const SizedBox(height: 8),
        Text(
          'Tracking ID: ${application.trackingId}',
          style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
        ).animate().fadeIn(delay: 100.ms),
      ],
    );
  }

  Widget _buildStatusCard() {
    Color statusColor;
    String statusTitle;
    IconData statusIcon;
    String description;

    switch (application.status) {
      case ApplicationStatus.pendingBarangay:
        statusColor = Colors.orange;
        statusTitle = 'Pending Barangay Review';
        statusIcon = Icons.home_work_rounded;
        description = 'Your application is currently being reviewed by your Barangay officials.';
        break;
      case ApplicationStatus.pendingMunicipal:
        statusColor = Colors.blue;
        statusTitle = 'Under Municipal Review';
        statusIcon = Icons.location_city_rounded;
        description = 'The Barangay has forwarded your application to the Municipal Hall for final approval.';
        break;
      case ApplicationStatus.approved:
        statusColor = Colors.green;
        statusTitle = 'Application Approved';
        statusIcon = Icons.check_circle_rounded;
        description = 'Congratulations! Your application has been approved. You can now use your Beneficiary ID.';
        break;
      case ApplicationStatus.rejected:
        statusColor = Colors.red;
        statusTitle = 'Application Rejected';
        statusIcon = Icons.cancel_rounded;
        description = 'Unfortunately, your application was not approved. Review the remarks for details.';
        break;
      case ApplicationStatus.suspended:
        statusColor = Colors.grey;
        statusTitle = 'Benefits Suspended';
        statusIcon = Icons.block_rounded;
        description = 'Your benefits have been temporarily suspended. Please contact the Municipal Social Welfare office.';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(statusTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(
                      'Submitted on ${DateFormat('MMMM dd, yyyy').format(application.dateSubmitted)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: TextStyle(color: Colors.grey[800], fontSize: 13, height: 1.4),
          ),
          if (application.remarks != null && application.remarks!.isNotEmpty) ...[
            const Divider(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Remarks from Staff:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.orange)),
                  const SizedBox(height: 4),
                  Text(application.remarks!, style: TextStyle(color: Colors.grey[800], fontSize: 13, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildInfoSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tracking History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0D47A1))),
          const SizedBox(height: 24),
          _buildMilestone(
            title: 'Application Submitted',
            subtitle: 'Initial filing received by the system.',
            date: DateFormat('MMM dd, yyyy').format(application.dateSubmitted),
            isCompleted: true,
            isLast: false,
          ),
          _buildMilestone(
            title: 'Barangay Validation',
            subtitle: application.status == ApplicationStatus.pendingBarangay 
                ? 'Reviewing eligibility at the local level.'
                : 'Verified by Barangay staff.',
            date: application.status == ApplicationStatus.pendingBarangay ? null : 'Completed',
            isCompleted: application.status != ApplicationStatus.pendingBarangay,
            isLast: false,
          ),
          _buildMilestone(
            title: 'Municipal Approval',
            subtitle: application.status == ApplicationStatus.approved 
                ? 'Final approval granted.'
                : (application.status == ApplicationStatus.rejected ? 'Rejected by Municipal Hall.' : 'Pending final executive approval.'),
            date: application.approvalDate != null ? DateFormat('MMM dd, yyyy').format(application.approvalDate!) : null,
            isCompleted: application.status == ApplicationStatus.approved,
            isLast: true,
            isError: application.status == ApplicationStatus.rejected,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildMilestone({
    required String title,
    required String subtitle,
    String? date,
    required bool isCompleted,
    required bool isLast,
    bool isError = false,
  }) {
    final color = isError ? Colors.red : (isCompleted ? Colors.green : Colors.grey[300]!);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(isError ? Icons.close : Icons.check, size: 14, color: isCompleted || isError ? Colors.white : Colors.transparent),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted ? Colors.green : Colors.grey[300],
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isCompleted ? Colors.black87 : Colors.grey[600])),
                    if (date != null)
                      Text(date, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                  ],
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection() {
    if (application.supportingDocs.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Submitted Documents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0D47A1))),
          const SizedBox(height: 16),
          ...application.supportingDocs.asMap().entries.map((entry) {
            final index = entry.key;
            final url = entry.value;
            final fileName = url.split('/').last;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.file_present_rounded, color: Colors.blue),
              ),
              title: Text('Document ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text(fileName, style: TextStyle(fontSize: 11, color: Colors.grey[600]), overflow: TextOverflow.ellipsis),
              trailing: const Icon(Icons.download_rounded, color: Colors.grey, size: 20),
              onTap: () {
                // Future: Open URL
              },
            );
          }),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }
}
