import 'package:flutter/material.dart';
import 'citizen_validation_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/app_drawer.dart';
import '../providers/auth_provider.dart';
import '../providers/document_provider.dart';
import 'request_document_screen.dart';
import 'my_requests_screen.dart';
import 'profile_screen.dart';
import 'notification_screen.dart';
import 'social_benefits_screen.dart';
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

  @override
  void dispose() {
    // Clean up Realtime subscriptions
    if (mounted) {
      context.read<NotificationProvider>().unsubscribeFromRealtime();
      context.read<DocumentProvider>().unsubscribeFromRealtime();
      context.read<BeneficiaryProvider>().unsubscribeFromRealtime();
    }
    super.dispose();
  }

  void _fetchInitialData() {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user != null) {
      final citizenId = user.id;
      
      // Fetch initial data
      context.read<BeneficiaryProvider>().fetchApplications(citizenId);
      context.read<DocumentProvider>().fetchRequests(citizenId);
      final notifProvider = context.read<NotificationProvider>();
      notifProvider.fetchNotifications(citizenId);
      
      // Initialize Realtime subscriptions
      notifProvider.subscribeToRealtime(citizenId);
      context.read<DocumentProvider>().subscribeToRequests(citizenId);
      context.read<BeneficiaryProvider>().subscribeToApplications(citizenId);
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
          style: TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
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
                      Colors.black.withValues(alpha: 0.6),
                      Colors.black.withValues(alpha: 0.3),
                      const Color(0xFF0D47A1).withValues(alpha: 0.1),
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Services',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                            shadows: [Shadow(color: Colors.black45, blurRadius: 10)],
                          ),
                        ).animate().fadeIn().slideX(),
                        const SizedBox(height: 8),
                        _buildServiceGrid(context, user, isVerified),
                        const SizedBox(height: 32),
                        
                        const Text(
                          'Recent Activity & Status',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                            shadows: [Shadow(color: Colors.black45, blurRadius: 10)],
                          ),
                        ).animate().fadeIn(delay: 400.ms).slideX(),
                        const SizedBox(height: 8),
                        _buildCombinedStatusCard(context),
                        const SizedBox(height: 48),
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
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.orange.withValues(alpha: 0.95),
              Colors.orange[700]!.withValues(alpha: 0.95),
            ],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.pending_actions_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Application Pending',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    'Verification in progress. Some services are restricted.',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().slideY(begin: 1.0, duration: 500.ms, curve: Curves.easeOutCubic),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context, Citizen? user) {
    final status = user?.verificationStatus ?? VerificationStatus.unverified;
    String statusMsg;
    Color statusColor;

    switch (status) {
      case VerificationStatus.verified:
        statusMsg = 'Verified Resident';
        statusColor = const Color(0xFF00E676);
        break;
      case VerificationStatus.pending:
        statusMsg = 'Pending Review';
        statusColor = const Color(0xFFFFAB40);
        break;
      case VerificationStatus.rejected:
        statusMsg = 'Action Required';
        statusColor = const Color(0xFFFF5252);
        break;
      case VerificationStatus.unverified:
        statusMsg = 'Unverified Account';
        statusColor = Colors.white70;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 120, 24, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  backgroundImage: user?.profilePictureUrl != null
                      ? NetworkImage(user!.profilePictureUrl!)
                      : null,
                  child: user?.profilePictureUrl == null
                      ? const Icon(Icons.person_rounded, color: Colors.white, size: 30)
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Mabuhay!',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                statusMsg,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      children: [
                        Text(
                          user?.displayName ?? 'Citizen',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            shadows: [Shadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 2))],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Verification Banner
          _buildVerificationBanner(context, status),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.05, curve: Curves.easeOut);
  }

  Widget _buildVerificationBanner(BuildContext context, VerificationStatus status) {
    if (status == VerificationStatus.verified) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.15),
              Colors.white.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF00E676).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_rounded, color: Color(0xFF00E676), size: 20),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Account Verified. All government services are now accessible.',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: 400.ms).scale();
    }

    final isRejected = status == VerificationStatus.rejected;
    final isPending = status == VerificationStatus.pending;
    
    final bannerColor = isRejected ? Colors.redAccent : (isPending ? Colors.orangeAccent : Colors.white);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bannerColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bannerColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isRejected ? Icons.error_outline_rounded : (isPending ? Icons.hourglass_empty_rounded : Icons.shield_outlined),
                  color: bannerColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  isPending
                      ? 'Verification in progress. We\'ll notify you once approved.'
                      : isRejected
                          ? 'Verification rejected. Please check and re-submit your documents.'
                          : 'Verify your account to access official document requests.',
                  style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                ),
              ),
            ],
          ),
          if (status == VerificationStatus.unverified || isRejected) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (ctx) => const CitizenValidationScreen()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: isRejected ? Colors.red[900] : const Color(0xFF0D47A1),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(isRejected ? Icons.refresh_rounded : Icons.how_to_reg_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      isRejected ? 'Update Documents' : 'Get Verified Now',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).scale();
  }

  Widget _buildServiceGrid(BuildContext context, Citizen? user, bool isVerified) {
    final services = [
      _ServiceItem(
        label: 'Request',
        icon: Icons.description_rounded,
        sub: 'Documents',
        bg: const Color(0xFFE3F2FD),
        iconColor: const Color(0xFF1976D2),
        gradientColors: [const Color(0xFF1976D2), const Color(0xFF42A5F5)],
        target: const RequestDocumentScreen(),
        delay: 0,
        enabled: isVerified,
      ),
      _ServiceItem(
        label: 'History',
        icon: Icons.history_edu_rounded,
        sub: 'My Requests',
        bg: const Color(0xFFFFF3E0),
        iconColor: const Color(0xFFF57C00),
        gradientColors: [const Color(0xFFF57C00), const Color(0xFFFFB74D)],
        target: const MyRequestsScreen(),
        delay: 100,
        enabled: isVerified,
      ),
      _ServiceItem(
        label: 'Profile',
        icon: Icons.person_pin_rounded,
        sub: 'Account Info',
        bg: const Color(0xFFE8F5E9),
        iconColor: const Color(0xFF388E3C),
        gradientColors: [const Color(0xFF388E3C), const Color(0xFF66BB6A)],
        target: const ProfileScreen(),
        delay: 200,
        enabled: true,
        leadingWidget: user?.profilePictureUrl != null
            ? CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(user!.profilePictureUrl!),
              )
            : null,
      ),
      _ServiceItem(
        label: 'Socials',
        icon: Icons.volunteer_activism_rounded,
        sub: 'Programs',
        bg: const Color(0xFFF1F8E9),
        iconColor: const Color(0xFF43A047),
        gradientColors: [const Color(0xFF43A047), const Color(0xFF81C784)],
        target: const SocialBenefitsScreen(),
        delay: 300,
        enabled: isVerified,
      ),
      _ServiceItem(
        label: 'Status',
        icon: Icons.track_changes_rounded,
        sub: 'Applications',
        bg: const Color(0xFFE0F7FA),
        iconColor: const Color(0xFF00ACC1),
        gradientColors: [const Color(0xFF00ACC1), const Color(0xFF4DD0E1)],
        target: const MyBeneficiaryApplicationsScreen(),
        delay: 400,
        enabled: isVerified,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Responsive: 1 column for narrow, 2 for medium, 3 for wide (tablet)
        final int crossAxisCount = width < 340 ? 1 : (width < 600 ? 2 : 3);
        final double spacing = width < 340 ? 10 : 14;

        // Separate paired tiles and the last (odd) tile
        final pairedCount = (services.length ~/ 2) * 2;
        final hasOddTile = services.length.isOdd;

        return Column(
          children: [
            GridView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: spacing,
                crossAxisSpacing: spacing,
                childAspectRatio: crossAxisCount == 1 ? 3.5 : (crossAxisCount == 3 ? 1.6 : 1.35),
              ),
              itemCount: crossAxisCount == 1 ? services.length : pairedCount,
              itemBuilder: (context, index) {
                final s = services[index];
                return _buildServiceTile(
                  context: context,
                  label: s.label,
                  icon: s.icon,
                  sub: s.sub,
                  bg: s.bg,
                  iconColor: s.iconColor,
                  gradientColors: s.gradientColors,
                  target: s.target,
                  delay: s.delay,
                  enabled: s.enabled,
                  leadingWidget: s.leadingWidget,
                );
              },
            ),
            // Render the last odd tile as a full-width card if in 2-column mode
            if (hasOddTile && crossAxisCount == 2) ...[
              SizedBox(height: spacing),
              _buildServiceTile(
                context: context,
                label: services.last.label,
                icon: services.last.icon,
                sub: services.last.sub,
                bg: services.last.bg,
                iconColor: services.last.iconColor,
                gradientColors: services.last.gradientColors,
                target: services.last.target,
                delay: services.last.delay,
                enabled: services.last.enabled,
                leadingWidget: services.last.leadingWidget,
                fullWidth: true,
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildServiceTile({
    required BuildContext context,
    required String label,
    required IconData icon,
    required String sub,
    required Color bg,
    required Color iconColor,
    required List<Color> gradientColors,
    required Widget? target,
    required int delay,
    bool enabled = true,
    Widget? leadingWidget,
    bool fullWidth = false,
  }) {
    final disabledGradient = [Colors.grey[400]!, Colors.grey[350]!];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (enabled ? iconColor : Colors.grey).withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: enabled
              ? Colors.white.withValues(alpha: 0.95)
              : Colors.white.withValues(alpha: 0.6),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            splashColor: iconColor.withValues(alpha: 0.08),
            highlightColor: iconColor.withValues(alpha: 0.04),
            onTap: (enabled && target != null)
                ? () => Navigator.push(
                    context, MaterialPageRoute(builder: (ctx) => target))
                : (enabled
                    ? null
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Verification required for this service'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }),
            child: Stack(
              children: [
                // Accent gradient strip at the top
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: enabled ? gradientColors : disabledGradient,
                      ),
                    ),
                  ),
                ),
                // Tile content
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    fullWidth ? 20 : 14,
                    fullWidth ? 18 : 16,
                    fullWidth ? 16 : 12,
                    fullWidth ? 18 : 14,
                  ),
                  child: Row(
                    children: [
                      // Icon container with gradient background
                      Container(
                        width: fullWidth ? 52 : 48,
                        height: fullWidth ? 52 : 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: enabled
                                ? [
                                    bg,
                                    bg.withValues(alpha: 0.6),
                                  ]
                                : [Colors.grey[200]!, Colors.grey[100]!],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: enabled
                                ? iconColor.withValues(alpha: 0.15)
                                : Colors.grey.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: leadingWidget ??
                              Icon(
                                icon,
                                color: enabled ? iconColor : Colors.grey[500],
                                size: fullWidth ? 26 : 24,
                              ),
                        ),
                      ),
                      SizedBox(width: fullWidth ? 16 : 12),
                      // Text content
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: fullWidth ? 16 : 15,
                                color:
                                    enabled ? const Color(0xFF1A1A2E) : Colors.black38,
                                letterSpacing: -0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              sub,
                              style: TextStyle(
                                color: enabled
                                    ? Colors.grey[500]
                                    : Colors.grey[400],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      // Arrow indicator
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: enabled
                            ? iconColor.withValues(alpha: 0.4)
                            : Colors.grey[300],
                      ),
                    ],
                  ),
                ),
                // Lock overlay for disabled tiles
                if (!enabled)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.lock_rounded,
                          size: 12, color: Colors.grey[500]),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: delay.ms, duration: 400.ms).scale(
          begin: const Offset(0.92, 0.92),
          duration: 400.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildCombinedStatusCard(BuildContext context) {
    final docProvider = context.watch<DocumentProvider>();
    final benProvider = context.watch<BeneficiaryProvider>();
    final requests = docProvider.requests;
    final applications = benProvider.applications;

    final hasRequests = requests.isNotEmpty;
    final hasApplications = applications.isNotEmpty;

    if (!hasRequests && !hasApplications) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No recent activity or applications.',
              style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Document Request Section ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.description_rounded, color: Color(0xFF1976D2), size: 16),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Document Requests',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2D3436)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (hasRequests) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildDocumentRow(requests.first),
              ),
              const SizedBox(height: 16),
              _buildStatusAction(
                context,
                'View All Requests',
                const Color(0xFF0D47A1),
                () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => const MyRequestsScreen())),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Text('No recent document requests.', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              ),

            Container(height: 1, color: Colors.grey[100]),

            // --- Beneficiary Status Section ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.volunteer_activism_rounded, color: Color(0xFF43A047), size: 16),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Social Benefits',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2D3436)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (hasApplications) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildBeneficiaryRow(applications.first),
              ),
              const SizedBox(height: 16),
              _buildStatusAction(
                context,
                'Track My Benefits',
                const Color(0xFF43A047),
                () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => const MyBeneficiaryApplicationsScreen())),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Text('No active benefit applications.', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1);
  }

  Widget _buildStatusAction(BuildContext context, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.04),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, size: 18, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentRow(dynamic latest) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: latest.statusColor.withValues(alpha: 0.1),
          child: Icon(Icons.description_rounded, color: latest.statusColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(latest.type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
              Text(latest.trackingNumber, style: TextStyle(color: Colors.grey[600], fontSize: 11), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: latest.statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            latest.statusText,
            style: TextStyle(color: latest.statusColor, fontWeight: FontWeight.bold, fontSize: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildBeneficiaryRow(BeneficiaryApplication latest) {
    final isApproved = latest.status == ApplicationStatus.approved;
    final statusColor = isApproved ? const Color(0xFF2E7D32) : Colors.orange;
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFFE8F5E9),
          child: Icon(
            isApproved ? Icons.check_circle_rounded : Icons.pending_rounded,
            color: statusColor,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(latest.programName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
              Text(
                isApproved ? 'Approved Beneficiary' : 'Application in Progress',
                style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            latest.status.name.toUpperCase(),
            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
          ),
        ),
      ],
    );
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

/// Data holder for service tile configuration
class _ServiceItem {
  final String label;
  final IconData icon;
  final String sub;
  final Color bg;
  final Color iconColor;
  final List<Color> gradientColors;
  final Widget? target;
  final int delay;
  final bool enabled;
  final Widget? leadingWidget;

  const _ServiceItem({
    required this.label,
    required this.icon,
    required this.sub,
    required this.bg,
    required this.iconColor,
    required this.gradientColors,
    required this.target,
    required this.delay,
    this.enabled = true,
    this.leadingWidget,
  });
}