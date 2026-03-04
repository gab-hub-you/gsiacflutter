import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  DateTime? _selectedDate;

  void _presentDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0D47A1),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1A237E),
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      setState(() => _selectedDate = pickedDate);
    }
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.register(
        fullName: _nameController.text,
        address: _addressController.text,
        birthdate: _selectedDate!,
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (success && mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Account Recorded'),
            content: const Text('Registration successful. You may now proceed to the secure login gateway.'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1), foregroundColor: Colors.white),
                child: const Text('Proceed to Login'),
              ),
            ],
          ),
        );
      }
    } else if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please verify your birthdate selection'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(title: const Text('Join ULGDSP'), elevation: 0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTextField(_nameController, 'Full Legal Name', Icons.person_outline_rounded),
                      const SizedBox(height: 16),
                      _buildTextField(_addressController, 'Residential Address', Icons.home_outlined),
                      const SizedBox(height: 16),
                      _buildDatePickerField(),
                      const SizedBox(height: 16),
                      _buildTextField(_emailController, 'Official Email', Icons.alternate_email_rounded),
                      const SizedBox(height: 16),
                      _buildTextField(_passwordController, 'Secure Password', Icons.lock_outline_rounded, isPassword: true),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: context.watch<AuthProvider>().isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          backgroundColor: const Color(0xFF0D47A1),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                        ),
                        child: context.watch<AuthProvider>().isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Complete Citizen Registration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0D47A1),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create Account',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ).animate().fadeIn().slideX(),
          Text(
            'Secure your identity in the national local government network.',
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPassword = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF0D47A1)),
        fillColor: Colors.white,
      ),
      validator: (v) => v!.isEmpty ? 'Selection required' : null,
    );
  }

  Widget _buildDatePickerField() {
    return InkWell(
      onTap: _presentDatePicker,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date of Birth', 
          prefixIcon: Icon(Icons.calendar_today_rounded, color: Color(0xFF0D47A1)),
          fillColor: Colors.white,
        ),
        child: Text(
          _selectedDate == null 
            ? 'Select recorded birthdate' 
            : DateFormat('MMMM dd, yyyy').format(_selectedDate!),
          style: TextStyle(color: _selectedDate == null ? Colors.grey[600] : Colors.black87),
        ),
      ),
    );
  }
}
