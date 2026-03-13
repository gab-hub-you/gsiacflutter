import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/beneficiary_provider.dart';
import '../providers/auth_provider.dart';
import '../models/beneficiary_application.dart';
import '../models/citizen.dart';

class StaffBeneficiaryDashboardScreen extends StatefulWidget {
  const StaffBeneficiaryDashboardScreen({super.key});

  @override
  State<StaffBeneficiaryDashboardScreen> createState() => _StaffBeneficiaryDashboardScreenState();
}

class _StaffBeneficiaryDashboardScreenState extends State<StaffBeneficiaryDashboardScreen> {
  ApplicationStatus _filterStatus = ApplicationStatus.pendingBarangay;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user?.role == UserRole.municipalStaff) {
      _filterStatus = ApplicationStatus.pendingMunicipal;
    }
  }

  void _showProcessDialog(BuildContext context, BeneficiaryApplication app, UserRole role) {
    String? remarks;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Process Application ${app.trackingId}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Program: ${app.programName}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Submitted: ${DateFormat('yyyy-MM-dd').format(app.dateSubmitted)}'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Remarks (Optional)',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => remarks = v,
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = Provider.of<BeneficiaryProvider>(context, listen: false);
              await provider.updateApplicationStatus(
                app.id,
                ApplicationStatus.rejected,
                remarks: remarks,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Application Rejected')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Reject'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = Provider.of<BeneficiaryProvider>(context, listen: false);
              
              ApplicationStatus nextStatus;
              if (role == UserRole.barangayStaff) {
                nextStatus = ApplicationStatus.pendingMunicipal;
              } else {
                nextStatus = ApplicationStatus.approved;
              }

              await provider.updateApplicationStatus(
                app.id,
                nextStatus,
                remarks: remarks,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(role == UserRole.barangayStaff ? 'Forwarded to Municipal' : 'Application Approved'))
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: Text(role == UserRole.barangayStaff ? 'Approve & Forward' : 'Approve'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final provider = context.watch<BeneficiaryProvider>();
    final isBarangay = user?.role == UserRole.barangayStaff;
    final isMunicipal = user?.role == UserRole.municipalStaff;

    if (user == null || (!isBarangay && !isMunicipal)) {
      return const Scaffold(body: Center(child: Text('Unauthorized Access')));
    }

    final filteredApps = provider.applications.where((app) => app.status == _filterStatus).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beneficiary Apps Dashboard'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SegmentedButton<ApplicationStatus>(
              segments: [
                if (isBarangay)
                  const ButtonSegment(value: ApplicationStatus.pendingBarangay, label: Text('Pending Review')),
                if (isBarangay)
                  const ButtonSegment(value: ApplicationStatus.pendingMunicipal, label: Text('Forwarded')),
                if (isMunicipal)
                  const ButtonSegment(value: ApplicationStatus.pendingMunicipal, label: Text('Pending Final Review')),
                
                const ButtonSegment(value: ApplicationStatus.approved, label: Text('Approved')),
                const ButtonSegment(value: ApplicationStatus.rejected, label: Text('Rejected')),
              ],
              selected: {_filterStatus},
              onSelectionChanged: (Set<ApplicationStatus> newSelection) {
                setState(() => _filterStatus = newSelection.first);
              },
            ),
          ),
          Expanded(
            child: filteredApps.isEmpty
                ? const Center(child: Text('No applications found in this category.'))
                : ListView.builder(
                    itemCount: filteredApps.length,
                    itemBuilder: (ctx, i) {
                      final app = filteredApps[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          title: Text('${app.programName} - ${app.trackingId}'),
                          subtitle: Text('Submitted: ${DateFormat('yyyy-MM-dd').format(app.dateSubmitted)} | Citizen: ${app.citizenId}'),
                          trailing: ((isBarangay && app.status == ApplicationStatus.pendingBarangay) ||
                                     (isMunicipal && app.status == ApplicationStatus.pendingMunicipal))
                              ? ElevatedButton(
                                  onPressed: () => _showProcessDialog(context, app, user.role),
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1), foregroundColor: Colors.white),
                                  child: const Text('Process'),
                                )
                              : const Icon(Icons.info_outline),
                        ),
                      ).animate().fadeIn(delay: (50 * i).ms);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
