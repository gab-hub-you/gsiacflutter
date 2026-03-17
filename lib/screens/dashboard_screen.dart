import 'package:flutter/material.dart';
import 'citizen_validation_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/app_drawer.dart';
import '../providers/auth_provider.dart';
import '../providers/document_provider.dart'; // Moved up
import 'request_document_screen.dart';
import 'my_requests_screen.dart';
import 'profile_screen.dart';
import 'notification_screen.dart';
import 'apply_beneficiary_screen.dart';
import 'my_beneficiary_applications_screen.dart';
import '../providers/notification_provider.dart';
import '../providers/beneficiary_provider.dart';
import '../models/citizen.dart';
import '../models/beneficiary_application.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialData();
    });
  }

  void _fetchInitialData() {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user != null) {
      context.read<BeneficiaryProvider>().fetchApplications(user.id);
      context.read<DocumentProvider>().fetchRequests(user.id);
      context.read<NotificationProvider>().fetchNotifications(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isVerified = user?.verificationStatus == VerificationStatus.verified;
    final isPending = user?.verificationStatus == VerificationStatus.pending;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
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
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<AuthProvider>().refreshProfile();
          _fetchInitialData();
        },
        child: Stack(
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
            SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildWelcomeHeader(context, user),
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
                        _buildServiceGrid(context, user, isVerified),
                        const SizedBox(height: 32),
                        
                        const Text(
                          'Recent Activity',
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
                        const Text(
                          'Social Beneficiary Status',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [Shadow(color: Colors.black38, blurRadius: 6)],
                          ),
                        ).animate().fadeIn(delay: 500.ms).slideX(),
                        const SizedBox(height: 16),
                        _buildBeneficiaryStatusCard(context),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (isPending) _buildPendingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orangeAccent.withValues(alpha: 0.9),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.pending_actions_rounded, color: Colors.white),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Verification Pending. Some services are restricted until approved by your Barangay.',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ).animate().slideY(begin: 1.0, duration: 500.ms),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context, Citizen? user) {
    final status = user?.verificationStatus ?? VerificationStatus.unverified;
    String statusMsg;
    Color statusColor;

    switch (status) {
      case VerificationStatus.verified:
        statusMsg = 'Verified Resident';
        statusColor = Colors.greenAccent;
        break;
      case VerificationStatus.pending:
        statusMsg = 'Verification Pending';
        statusColor = Colors.orangeAccent;
        break;
      case VerificationStatus.rejected:
        statusMsg = 'Verification Rejected';
        statusColor = Colors.redAccent;
        break;
      case VerificationStatus.unverified:
        statusMsg = 'Unverified Citizen';
        statusColor = Colors.white70;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 110, 24, 28),
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
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white24,
                backgroundImage: user?.profilePictureUrl != null
                    ? NetworkImage(user!.profilePictureUrl!)
                    : null,
                child: user?.profilePictureUrl == null
                    ? const Icon(Icons.person, color: Colors.white, size: 20)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Welcome back,',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  statusMsg,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            user?.displayName ?? 'Citizen',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.black45, blurRadius: 8)],
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 16),
          if (status == VerificationStatus.verified)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_rounded, color: Colors.greenAccent, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Your account is verified. You can now request official documents.',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms).scale()
          else
             Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          status == VerificationStatus.pending 
                            ? 'Verification in progress. Please wait for staff approval.'
                            : 'Please complete your profile validation to access document requests.',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  if (status == VerificationStatus.unverified) ...[
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (ctx) => const CitizenValidationScreen()),
                      ),
                      icon: const Icon(Icons.verified_rounded, size: 18),
                      label: const Text('Start Verification Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0D47A1),
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ],
              ),
            ).animate().fadeIn(delay: 200.ms).scale(),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildServiceGrid(BuildContext context, Citizen? user, bool isVerified) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 360;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isNarrow ? 1 : 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: isNarrow ? 3.0 : 1.1,
          children: [
            _buildServiceTile(
              context: context, 
              label: 'Request', 
              icon: Icons.description_rounded, 
              sub: 'Documents',
              bg: const Color(0xFFE3F2FD), 
              iconColor: const Color(0xFF1976D2), 
              target: const RequestDocumentScreen(), 
              delay: 0,
              enabled: true,
            ),
            _buildServiceTile(
              context: context,
              label: 'History', 
              icon: Icons.history_edu_rounded, 
              sub: 'My Requests',
              bg: const Color(0xFFFFF3E0), 
              iconColor: const Color(0xFFF57C00), 
              target: const MyRequestsScreen(), 
              delay: 100,
            ),
            _buildServiceTile(
              context: context,
              label: 'Profile', 
              icon: Icons.person_pin_rounded, 
              sub: 'Account Info',
              bg: const Color(0xFFE8F5E9), 
              iconColor: const Color(0xFF388E3C), 
              target: const ProfileScreen(), 
              delay: 200,
              leadingWidget: user?.profilePictureUrl != null 
                ? CircleAvatar(
                    radius: 14,
                    backgroundImage: NetworkImage(user!.profilePictureUrl!),
                  )
                : null,
            ),
            _buildServiceTile(
              context: context,
              label: 'Apply', 
              icon: Icons.volunteer_activism_rounded, 
              sub: 'Social Benefits',
              bg: const Color(0xFFF1F8E9), 
              iconColor: const Color(0xFF43A047), 
              target: const ApplyBeneficiaryScreen(),
              delay: 300,
            ),
            _buildServiceTile(
              context: context,
              label: 'Status', 
              icon: Icons.track_changes_rounded, 
              sub: 'Benefit Tracking',
              bg: const Color(0xFFE0F7FA), 
              iconColor: const Color(0xFF00ACC1), 
              target: const MyBeneficiaryApplicationsScreen(),
              delay: 400,
            ),
          ],
        );
      }
    );
  }

  Widget _buildServiceTile({
    required BuildContext context, 
    required String label, 
    required IconData icon, 
    required String sub,
    required Color bg, 
    required Color iconColor, 
    required Widget? target, 
    required int delay,
    bool enabled = true,
    Widget? leadingWidget,
  }) {
    return Card(
      elevation: 0,
      color: enabled ? Colors.white.withValues(alpha: 0.92) : Colors.white.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: (enabled && target != null)
            ? () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => target))
            : (enabled ? null : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Verification required for this service')),
                );
              }),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: enabled ? bg : Colors.grey[300], 
                  borderRadius: BorderRadius.circular(16),
                ),
                child: leadingWidget ?? Icon(icon, color: enabled ? iconColor : Colors.grey[600], size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label, 
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 16,
                        color: enabled ? Colors.black : Colors.black45,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      sub, 
                      style: TextStyle(
                        color: enabled ? Colors.grey[600] : Colors.grey[400], 
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildRecentStatusCard(BuildContext context) {
    final docProvider = context.watch<DocumentProvider>();
    final requests = docProvider.requests;
    
    if (requests.isEmpty) {
      return Card(
        elevation: 0,
        color: Colors.white.withValues(alpha: 0.92),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: const Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(child: Text('No recent document requests.', style: TextStyle(color: Colors.grey))),
        ),
      );
    }

    final latest = requests.first;

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
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: latest.statusColor.withValues(alpha: 0.1),
                  child: Icon(Icons.description_rounded, color: latest.statusColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        latest.type, 
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        latest.trackingNumber, 
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: latest.statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    latest.statusText,
                    style: TextStyle(color: latest.statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => const MyRequestsScreen())),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: const Color(0xFF0D47A1),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text('View All Tracking History'),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1);
  }

  Widget _buildBeneficiaryStatusCard(BuildContext context) {
    final benProvider = context.watch<BeneficiaryProvider>();
    final applications = benProvider.applications;

    if (applications.isEmpty) {
      return Card(
        elevation: 0,
        color: Colors.white.withValues(alpha: 0.92),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: const Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(child: Text('No active benefit applications.', style: TextStyle(color: Colors.grey))),
        ),
      );
    }

    final latest = applications.first;

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
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFE8F5E9),
                  child: Icon(
                    latest.status == ApplicationStatus.approved ? Icons.check_circle_rounded : Icons.pending_rounded,
                    color: latest.status == ApplicationStatus.approved ? const Color(0xFF2E7D32) : Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        latest.programName, 
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        latest.status == ApplicationStatus.approved ? 'Approved Beneficiary' : 'Application in Progress',
                        style: TextStyle(
                          color: latest.status == ApplicationStatus.approved ? Colors.green : Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (latest.status == ApplicationStatus.approved ? Colors.green : Colors.orange).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    latest.status.name.toUpperCase(),
                    style: TextStyle(
                      color: latest.status == ApplicationStatus.approved ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold, 
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => const MyBeneficiaryApplicationsScreen())),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: const Color(0xFF0D47A1),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text('Track My Benefits'),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1);
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