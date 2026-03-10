import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/app_drawer.dart';
import '../providers/auth_provider.dart';
import 'request_document_screen.dart';
import 'my_requests_screen.dart';
import 'profile_screen.dart';
import 'notification_screen.dart';
import '../providers/notification_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
          'Citizen Portal',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          _buildNotificationIcon(context),
          const SizedBox(width: 8),
        ],
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
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'lib/assets/image/bg.webp',
              fit: BoxFit.cover,
            ),
          ),
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
          SingleChildScrollView(
            child: Column(
              children: [
                _buildWelcomeHeader(context, user?.fullName ?? 'Citizen'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Services',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [Shadow(color: Colors.black38, blurRadius: 6)],
                        ),
                      ).animate().fadeIn().slideX(),
                      const SizedBox(height: 16),
                      _buildServiceGrid(context),
                      const SizedBox(height: 32),
                      const Text(
                        'Ongoing Requests',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [Shadow(color: Colors.black38, blurRadius: 6)],
                        ),
                      ).animate().fadeIn(delay: 400.ms).slideX(),
                      const SizedBox(height: 16),
                      _buildRecentStatusCard(context),
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

  Widget _buildWelcomeHeader(BuildContext context, String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 110, 24, 28),
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
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back,',
            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.black45, blurRadius: 8)],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You have 2 pending document requests awaiting review.',
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms).scale(),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildServiceGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildServiceTile(context, 'Request', Icons.description_rounded, 'Documents',
            const Color(0xFFE3F2FD), const Color(0xFF1976D2), const RequestDocumentScreen(), 0),
        _buildServiceTile(context, 'History', Icons.history_edu_rounded, 'My Requests',
            const Color(0xFFFFF3E0), const Color(0xFFF57C00), const MyRequestsScreen(), 100),
        _buildServiceTile(context, 'Profile', Icons.person_pin_rounded, 'Account Info',
            const Color(0xFFE8F5E9), const Color(0xFF388E3C), const ProfileScreen(), 200),
        _buildServiceTile(context, 'Notifications', Icons.notifications_active_rounded, 'System News',
            const Color(0xFFF3E5F5), const Color(0xFF7B1FA2), const NotificationScreen(), 300),
      ],
    );
  }

  Widget _buildServiceTile(BuildContext context, String label, IconData icon, String sub,
      Color bg, Color iconColor, Widget? target, int delay) {
    return Card(
      elevation: 0,
      color: Colors.white.withOpacity(0.92),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withOpacity(0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: target != null
            ? () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => target))
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(height: 16),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(sub, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildRecentStatusCard(BuildContext context) {
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
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFE1F5FE),
                  child: Icon(Icons.access_time_filled, color: Color(0xFF0288D1)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Barangay Clearance',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('TRK-100201',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration:
                      BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
                  child: const Text('Under Review',
                      style: TextStyle(
                          color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 10)),
                ),
              ],
            ),
            const Divider(height: 32),
            OutlinedButton(
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (ctx) => const MyRequestsScreen())),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: const BorderSide(color: Color(0xFF0D47A1)),
                foregroundColor: const Color(0xFF0D47A1),
              ),
              child: const Text('View All Tracking History'),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1);
  }

  Widget _buildNotificationIcon(BuildContext context) {
    final unreadCount = context.watch<NotificationProvider>().unreadCount;
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (ctx) => const NotificationScreen())),
          icon: const Icon(Icons.notifications_none_rounded, size: 28, color: Colors.white),
        ),
        if (unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '$unreadCount',
                style: const TextStyle(
                    color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}