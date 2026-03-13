import 'package:flutter/material.dart';
import '../screens/dashboard_screen.dart';
import '../screens/my_requests_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/request_document_screen.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../screens/login_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/citizen_validation_screen.dart';
import '../models/citizen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topRight: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: Column(
        children: [
          _buildHeader(user),
          const SizedBox(height: 12),
          _buildItem(context, Icons.dashboard_rounded, 'Overview Dashboard', const DashboardScreen(), true),
          _buildItem(context, Icons.note_add_rounded, 'Request Documents', const RequestDocumentScreen(), false),
          _buildItem(context, Icons.list_alt_rounded, 'Tracking History', const MyRequestsScreen(), false),
          _buildItem(context, Icons.account_circle_rounded, 'Personal Profile', const ProfileScreen(), false),
          if (user?.verificationStatus == VerificationStatus.unverified)
            _buildItem(context, Icons.verified_user_rounded, 'Verify Account', const CitizenValidationScreen(), false),
          const Spacer(),
          _buildLogout(context),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader(dynamic user) {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 24, bottom: 30, right: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0D47A1),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white,
            backgroundImage: user?.profilePictureUrl != null
                ? NetworkImage(user!.profilePictureUrl!)
                : null,
            child: user?.profilePictureUrl == null
                ? const Icon(Icons.person, color: Color(0xFF0D47A1), size: 40)
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            user?.displayName ?? 'Citizen User',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            user?.email ?? 'citizen.portal@lgu.gov',
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, IconData icon, String title, Widget target, bool isReplace) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Icon(icon, color: const Color(0xFF0D47A1), size: 22),
      title: Text(
        title,
        style: GoogleFonts.outfit(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w500),
      ),
      onTap: () {
        Navigator.pop(context);
        if (isReplace) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (ctx) => target));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (ctx) => target));
        }
      },
    );
  }

  Widget _buildLogout(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
      title: Text(
        'Sign Out',
        style: GoogleFonts.outfit(fontSize: 15, color: Colors.redAccent, fontWeight: FontWeight.bold),
      ),
      onTap: () {
        Provider.of<AuthProvider>(context, listen: false).logout();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (ctx) => const LoginScreen()),
          (route) => false,
        );
      },
    );
  }
}
