import 'package:flutter/material.dart';

class DealerRegistrationScreen extends StatefulWidget {
  const DealerRegistrationScreen({Key? key}) : super(key: key);

  @override
  State<DealerRegistrationScreen> createState() => _DealerRegistrationScreenState();
}

class _DealerRegistrationScreenState extends State<DealerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers to capture the data for your backend database
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _stakLicenseController = TextEditingController();
  final TextEditingController _tillNumberController = TextEditingController();

  // Oletai Brand Color
  final Color oletaiGreen = const Color(0xFF0C462B);

  @override
  void dispose() {
    _ownerNameController.dispose();
    _businessNameController.dispose();
    _phoneController.dispose();
    _stakLicenseController.dispose();
    _tillNumberController.dispose();
    super.dispose();
  }

  void _submitRegistration() {
    if (_formKey.currentState!.validate()) {
      // TODO: Connect to your backend database here
      // 1. Show loading indicator
      // 2. Upload photo to cloud storage (Firebase/AWS)
      // 3. Post text data to your 'agro_dealers' and 'dealer_verifications' tables
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Registration submitted for Oletai Admin review!'),
          backgroundColor: oletaiGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Register as a Dealer',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: oletaiGreen,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- SECTION 1: BUSINESS PROFILE ---
              const Text(
                '1. Business Profile',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _ownerNameController,
                label: 'Owner Full Name',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _businessNameController,
                label: 'Agro-Vet Business Name',
                icon: Icons.storefront,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                icon: Icons.phone_outlined,
                isNumber: true,
              ),
              const Divider(height: 48, thickness: 1),

              // --- SECTION 2: VERIFICATION ---
              const Text(
                '2. Licensing & Verification',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'To protect our farmers, we require valid STAK/KEPHIS certification.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _stakLicenseController,
                label: 'STAK License Number',
                icon: Icons.verified_user_outlined,
              ),
              const SizedBox(height: 16),
              // Mock Photo Upload Button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade50,
                ),
                child: Column(
                  children: [
                    Icon(Icons.camera_alt_outlined, color: oletaiGreen, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'Upload KEPHIS Certificate Photo',
                      style: TextStyle(color: oletaiGreen, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Divider(height: 48, thickness: 1),

              // --- SECTION 3: PAYOUT DETAILS ---
              const Text(
                '3. M-Pesa Payout Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Where should Rahisi Agro Pay disburse your funds?',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _tillNumberController,
                label: 'M-Pesa Buy Goods Till Number',
                icon: Icons.account_balance_wallet_outlined,
                isNumber: true,
              ),
              const SizedBox(height: 32),

              // --- SUBMIT BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _submitRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: oletaiGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Submit for Verification',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to keep the code clean and uniform
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'This field is required';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: oletaiGreen),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: oletaiGreen, width: 2),
        ),
      ),
    );
  }
}