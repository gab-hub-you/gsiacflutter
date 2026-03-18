import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/beneficiary_program.dart';
import '../providers/beneficiary_provider.dart';
import 'program_details_screen.dart';

class SocialBenefitsScreen extends StatelessWidget {
  const SocialBenefitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BeneficiaryProvider>();
    final programs = provider.programs;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Social Benefits Platform',
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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text(
                    'Available Programs',
                    style: TextStyle(
                      color: Colors.white, 
                      fontSize: 24, 
                      fontWeight: FontWeight.bold, 
                      shadows: [Shadow(color: Colors.black45, blurRadius: 4)]
                    ),
                  ).animate().fadeIn().slideX(),
                  const SizedBox(height: 8),
                  const Text(
                    'Select a program to view eligibility and apply.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 24),
                  if (programs.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 100),
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    )
                  else
                    ...programs.asMap().entries.map((entry) {
                      final index = entry.key;
                      final program = entry.value;
                      return _buildProgramCard(context, program)
                          .animate()
                          .fadeIn(delay: (200 + index * 100).ms)
                          .slideY(begin: 0.2);
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramCard(BuildContext context, BeneficiaryProgram program) {
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

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white.withValues(alpha: 0.95),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => ProgramDetailsScreen(program: program),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          program.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 18,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          program.paymentSchedule,
                          style: TextStyle(
                            color: Colors.grey[600], 
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 16),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                program.description,
                style: TextStyle(
                  color: Colors.grey[800], 
                  fontSize: 14,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
