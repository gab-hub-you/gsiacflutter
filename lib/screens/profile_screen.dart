import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';
import '../models/citizen.dart';
import 'citizen_validation_screen.dart';

import 'package:file_picker/file_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUploading = false;
  Uint8List? _previewBytes;

  Future<void> _pickAndUploadImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (!mounted) return;
    if (file.bytes == null) return;

    setState(() {
      _isUploading = true;
      _previewBytes = file.bytes;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final url = await authProvider.uploadProfilePicture(
      file.bytes!,
      file.name,
    );

    setState(() => _isUploading = false);

    if (url != null) {
      await authProvider.refreshProfile(); // Vital: Pull the latest from DB
      if (mounted) {
        setState(() => _previewBytes = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated and saved!')),
        );
      }
    } else if (mounted) {
      setState(() => _previewBytes = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Upload failed'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

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
        backgroundColor: const Color(0xFF0D47A1),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'My Identity',
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

          // Main Content
          Positioned.fill(
            child: RefreshIndicator(
              onRefresh: () async {
                await context.read<AuthProvider>().refreshProfile();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                              _buildInfoRow('Primary Address', user?.address ?? 'Not set'),
                              _buildInfoRow(
                                'Portal Status', 
                                user?.verificationStatus.name.toUpperCase() ?? 'UNVERIFIED', 
                                isStatus: true,
                                statusColor: user?.verificationStatus == VerificationStatus.verified ? Colors.green[700] : Colors.orange[700],
                              ),
                            ],
                          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                          const SizedBox(height: 16),
                          if (user?.verificationStatus == VerificationStatus.unverified)
                            ElevatedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (ctx) => const CitizenValidationScreen()),
                              ),
                              icon: const Icon(Icons.verified_user_rounded),
                              label: const Text('Verify My Identity Now'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 60),
                                backgroundColor: const Color(0xFF0D47A1),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ).animate().fadeIn(delay: 250.ms).scale()
                          else
                            ElevatedButton.icon(
                              onPressed: () => _showCorrectionDialog(context),
                              icon: const Icon(Icons.edit_document),
                              label: const Text('Request Information Correction'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 60),
                                backgroundColor: Colors.white.withValues(alpha: 0.92),
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
            Colors.black.withValues(alpha: 0.4),
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
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.white30, shape: BoxShape.circle),
                child: CircleAvatar(
                  radius: 54,
                  backgroundColor: Colors.white,
                  backgroundImage: _previewBytes != null
                      ? MemoryImage(_previewBytes!)
                      : (user?.profilePictureUrl != null
                          ? NetworkImage(user!.profilePictureUrl!)
                          : null),
                  child: (_previewBytes == null && user?.profilePictureUrl == null)
                      ? const Icon(Icons.person_rounded, size: 60, color: Color(0xFF0D47A1))
                      : null,
                ),
              ).animate().scale(duration: 500.ms, curve: Curves.bounceOut),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _isUploading ? null : _pickAndUploadImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0D47A1),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                    ),
                    child: _isUploading 
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            user?.displayName ?? 'Juan Dela Cruz',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.black45, blurRadius: 8)],
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
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

  Widget _buildInfoRow(String label, String value, {bool isStatus = false, Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isStatus ? (statusColor ?? Colors.green[700]) : Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}