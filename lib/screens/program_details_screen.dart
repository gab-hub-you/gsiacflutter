import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/beneficiary_program.dart';
import 'apply_beneficiary_screen.dart';

class ProgramDetailsScreen extends StatelessWidget {
  final BeneficiaryProgram program;

  const ProgramDetailsScreen({super.key, required this.program});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    switch (program.type) {
      case BenefitType.financial:
        icon = Icons.attach_money_rounded;
        color = Colors.green;
        break;
      case BenefitType.medical:
        icon = Icons.medical_services_rounded;
        color = Colors.redAccent;
        break;
      case BenefitType.scholarship:
        icon = Icons.school_rounded;
        color = Colors.blue;
        break;
      default:
        icon = Icons.card_giftcard_rounded;
        color = Colors.orange;
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Program Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
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
                  // Program Header Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: color, size: 48),
                        ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                        const SizedBox(height: 20),
                        Text(
                          program.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D47A1),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Benefit Type: ${program.type.name.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: color,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: 0.1),
                  
                  const SizedBox(height: 32),
                  
                  // Description Section
                  _buildSection(
                    'Description',
                    program.description,
                    Icons.info_outline_rounded,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Schedule & Amount
                  Row(
                    children: [
                      Expanded(
                        child: _buildSection(
                          'Schedule',
                          program.paymentSchedule,
                          Icons.calendar_today_rounded,
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (program.amount != null)
                        Expanded(
                          child: _buildSection(
                            'Amount',
                            'PHP ${program.amount}',
                            Icons.payments_outlined,
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Requirements Section
                  _buildRequirementsSection(program.requirements),
                  
                  const SizedBox(height: 40),
                  
                  // Apply Button
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => ApplyBeneficiaryScreen(program: program),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D47A1),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Apply for this Program',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 500.ms).scale(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF0D47A1)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D47A1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildRequirementsSection(List<String> requirements) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.checklist_rounded, size: 18, color: Color(0xFF0D47A1)),
              const SizedBox(width: 8),
              Text(
                'Required Documents',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D47A1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...requirements.map((req) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.description_outlined, size: 18, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    req,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[850],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }
}
