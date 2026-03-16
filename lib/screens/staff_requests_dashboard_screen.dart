import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/document_request.dart';
import '../models/citizen.dart';
import '../providers/document_provider.dart';
import '../providers/auth_provider.dart';

class StaffRequestsDashboardScreen extends StatefulWidget {
  const StaffRequestsDashboardScreen({super.key});

  @override
  State<StaffRequestsDashboardScreen> createState() => _StaffRequestsDashboardScreenState();
}

class _StaffRequestsDashboardScreenState extends State<StaffRequestsDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DocumentProvider>().fetchAllRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final docProvider = context.watch<DocumentProvider>();
    final requests = docProvider.requests;

    // Filter requests based on office and role
    final filteredRequests = requests.where((r) {
      if (user?.role == UserRole.barangayStaff) {
        // Barangay staff sees all requests currently at Barangay
        return r.currentOffice == IssuingOffice.barangay;
      } else if (user?.role == UserRole.municipalStaff) {
        // Municipal staff sees requests forwarded to Municipal
        return r.currentOffice == IssuingOffice.municipal;
      }
      return false;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('${user?.role == UserRole.barangayStaff ? 'Barangay' : 'Municipal'} Dashboard'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () => docProvider.fetchAllRequests(),
        child: docProvider.isLoading && filteredRequests.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : filteredRequests.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.4),
                      const Center(child: Text('No pending requests for your office.')),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredRequests.length,
                    itemBuilder: (context, index) {
                      final request = filteredRequests[index];
                      return _buildRequestCard(request, user!);
                    },
                  ),
      ),
    );
  }

  Widget _buildRequestCard(DocumentRequest request, Citizen user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    request.type,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: request.statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    request.statusText,
                    style: TextStyle(color: request.statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Purpose: ${request.purpose}', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text('Date: ${DateFormat('MMM dd, yyyy HH:mm').format(request.dateSubmitted)}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (user.role == UserRole.barangayStaff) ...[
                  if (request.status == RequestStatus.pending)
                    TextButton(
                      onPressed: () => context.read<DocumentProvider>().updateRequestStatus(request.trackingNumber, RequestStatus.completed),
                      child: const Text('Approve & Issue'),
                    ),
                  if (request.issuingOffice == IssuingOffice.municipal && request.status == RequestStatus.pending)
                    ElevatedButton(
                      onPressed: () => context.read<DocumentProvider>().forwardToMunicipal(request.trackingNumber),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], foregroundColor: Colors.white),
                      child: const Text('Validate & Forward to Municipal'),
                    ),
                ],
                if (user.role == UserRole.municipalStaff) ...[
                  if (request.status == RequestStatus.sentToMunicipal)
                    TextButton(
                      onPressed: () => context.read<DocumentProvider>().updateRequestStatus(request.trackingNumber, RequestStatus.processing),
                      child: const Text('Start Processing'),
                    ),
                  if (request.status == RequestStatus.processing)
                    ElevatedButton(
                      onPressed: () => context.read<DocumentProvider>().updateRequestStatus(request.trackingNumber, RequestStatus.completed),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800], foregroundColor: Colors.white),
                      child: const Text('Mark as Completed'),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
