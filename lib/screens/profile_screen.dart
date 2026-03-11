import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showCorrectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Information Correction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('What information needs adjustment?'),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Describe the correction needed...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Discard')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ticket #7721 submitted for review.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1), foregroundColor: Colors.white),
            child: const Text('Submit Ticket'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.15),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'My Identity',
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

          // Main Content
          Positioned.fill(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildProfileHeader(user),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildProfileCard(
                          'PERSONAL RECORDS',
                          Icons.fingerprint_rounded,
                          [
                            _buildInfoRow('Legal Name', user?.fullName ?? 'Juan Dela Cruz'),
                            _buildInfoRow('Birthdate', user != null ? DateFormat('MMM dd, yyyy').format(user.birthdate) : 'May 20, 1990'),
                            _buildInfoRow('Email', user?.email ?? 'citizen@example.com'),
                          ],
                        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                        const SizedBox(height: 16),
                        _buildProfileCard(
                          'RESIDENCE & STATUS',
                          Icons.home_work_rounded,
                          [
                            _buildInfoRow('Primary Address', user?.address ?? '123 Mabini St, Manila'),
                            _buildInfoRow('Portal Status', 'Verified Citizen', isStatus: true),
                          ],
                        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: () => _showCorrectionDialog(context),
                          icon: const Icon(Icons.edit_document),
                          label: const Text('Request Information Correction'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 60),
                            backgroundColor: Colors.white.withOpacity(0.92),
                            foregroundColor: Colors.orange[900],
                            side: BorderSide(color: Colors.orange[200]!),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ).animate().fadeIn(delay: 300.ms).scale(),
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

  Widget _buildProfileHeader(dynamic user) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.4),
            Colors.transparent,
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 110, 24, 40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(color: Colors.white30, shape: BoxShape.circle),
            child: const CircleAvatar(
              radius: 54,
              backgroundColor: Colors.white,
              child: Icon(Icons.person_rounded, size: 60, color: Color(0xFF0D47A1)),
            ),
          ).animate().scale(duration: 500.ms, curve: Curves.bounceOut),
          const SizedBox(height: 16),
          Text(
            user?.fullName ?? 'Juan Dela Cruz',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.black45, blurRadius: 8)],
            ),
          ),
          Text(
            'LGU MEMBER SINCE 2024',
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10, letterSpacing: 2),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(String title, IconData icon, List<Widget> items) {
    return Card(
      elevation: 0,
      color: Colors.white.withOpacity(0.92),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(icon, size: 18, color: const Color(0xFF0D47A1)),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A237E), letterSpacing: 0.5)),
              ],
            ),
          ),
          ...items,
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isStatus ? Colors.green[700] : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}