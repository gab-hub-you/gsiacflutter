import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/document_request.dart';
import '../providers/document_provider.dart';
import 'request_details_screen.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<DocumentProvider>().fetchRequests());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DocumentProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.15),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'My Applications',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'lib/assets/image/bg.webp',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
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
          Positioned.fill(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 80, 20, 16),
                    itemCount: provider.requests.length,
                    itemBuilder: (context, index) {
                      final req = provider.requests[index];
                      return _buildRequestCard(req, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(DocumentRequest req, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: Colors.white.withOpacity(0.92),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withOpacity(0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (ctx) => RequestDetailsScreen(request: req)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              _buildTypeIcon(req.type),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req.type,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A237E)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'TRACKING: ${req.trackingNumber}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 10, letterSpacing: 1),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Submitted ${DateFormat('MMM dd').format(req.dateSubmitted)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildStatusBadge(req.status),
                  const SizedBox(height: 8),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1);
  }

  Widget _buildTypeIcon(String type) {
    IconData icon;
    Color color;
    if (type.contains('Clearance')) {
      icon = Icons.verified_user_rounded;
      color = const Color(0xFF1976D2);
    } else if (type.contains('Residency')) {
      icon = Icons.home_work_rounded;
      color = const Color(0xFFF57C00);
    } else {
      icon = Icons.article_rounded;
      color = const Color(0xFF388E3C);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }

  Widget _buildStatusBadge(RequestStatus status) {
    Color color;
    String text;
    switch (status) {
      case RequestStatus.pending:
        color = Colors.amber[700]!;
        text = 'Pending';
        break;
      case RequestStatus.underReview:
        color = const Color(0xFF0288D1);
        text = 'Reviewing';
        break;
      case RequestStatus.approved:
        color = const Color(0xFF43A047);
        text = 'Ready';
        break;
      case RequestStatus.rejected:
        color = Colors.redAccent;
        text = 'Declined';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }
}