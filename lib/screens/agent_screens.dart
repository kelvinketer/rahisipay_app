import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ==========================================
// 1. AGENT LOGIN & REGISTRATION
// ==========================================
class AgentLoginScreen extends StatefulWidget {
  const AgentLoginScreen({super.key});

  @override
  State<AgentLoginScreen> createState() => _AgentLoginScreenState();
}

class _AgentLoginScreenState extends State<AgentLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;
  bool _isRegistering = false; // Toggle between Login and Register

  // --- UNIVERSAL FEEDBACK POP-UP ---
  void _showFeedback(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade800 : const Color(0xFF144D2F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _authenticateAgent() async {
    if (_phoneController.text.isEmpty) return;
    setState(() => _isLoading = true);

    final phone = _phoneController.text.trim();
    final url = Uri.parse('https://rahisipay-api.onrender.com/api/v1/agent/stats/$phone');

    try {
      if (_isRegistering) {
        // --- REGISTER NEW AGENT ---
        final regUrl = Uri.parse('https://rahisipay-api.onrender.com/api/v1/agents/register');
        final response = await http.post(
          regUrl,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({"agent_name": _nameController.text, "phone_number": phone}),
        );

        if (response.statusCode == 200) {
          _navigateToDashboard(phone, _nameController.text, 0, 0);
        } else {
          _showFeedback("Registration failed. Phone might already be registered.", isError: true);
        }
      } else {
        // --- LOGIN EXISTING AGENT ---
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          _navigateToDashboard(phone, data['name'], data['balance'], data['sales']);
        } else {
          _showFeedback("Agent not found. Please register first.", isError: true);
        }
      }
    } catch (e) {
      _showFeedback("Network error. Check your connection.", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToDashboard(String phone, String name, int balance, int sales) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => AgentDashboardScreen(
        agentPhone: phone, agentName: name, balance: balance, salesCount: sales,
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        leading: const BackButton(color: Colors.black),
        title: const Text("Agent Portal", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      // 👇 RenderFlex Protection added
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.admin_panel_settings, size: 60, color: Color(0xFF144D2F)),
              const SizedBox(height: 16),
              Text(_isRegistering ? 'Become an Agent' : 'Agent Login', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF144D2F))),
              const SizedBox(height: 8),
              Text('Manage farmers and earn commissions.', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              const SizedBox(height: 40),
              
              if (_isRegistering) ...[
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Full Name', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 16),
              ],
              
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: 'Phone Number (e.g., +254...)', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
              ),
              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity, height: 60,
                // 👇 Button style removed to inherit globally
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _authenticateAgent,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(_isRegistering ? 'Register & Enter' : 'Secure Login', style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _isRegistering = !_isRegistering),
                  child: Text(_isRegistering ? 'Already an agent? Log in' : 'New here? Register as Agent', style: const TextStyle(color: Color(0xFF144D2F), fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. AGENT DASHBOARD
// ==========================================
class AgentDashboardScreen extends StatefulWidget {
  final String agentPhone;
  final String agentName;
  final int balance;
  final int salesCount;

  const AgentDashboardScreen({super.key, required this.agentPhone, required this.agentName, required this.balance, required this.salesCount});

  @override
  State<AgentDashboardScreen> createState() => _AgentDashboardScreenState();
}

class _AgentDashboardScreenState extends State<AgentDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF144D2F),
        title: Text("Hi, ${widget.agentName.split(' ')[0]}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Commission Card
            Container(
              width: double.infinity, padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF0A2E1A), Color(0xFF144D2F)]), borderRadius: BorderRadius.circular(32), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Commission Balance", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text("KES ${widget.balance}", style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white)),
                  const Divider(color: Colors.white24, height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Total Sales", style: TextStyle(color: Colors.white70)), Text("${widget.salesCount} Farmers", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))]),
                      ElevatedButton(
                        // 👇 Kept specific style for the inverted white button on dark card
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF144D2F), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Withdrawal requested!")));
                        },
                        child: const Text("Cash Out"),
                      )
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Text("Field Actions", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF144D2F))),
            const SizedBox(height: 16),
            
            // Action Tiles
            _buildActionTile(context, Icons.storefront, "Register Agrovet", "Add a new merchant to the network", () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterAgrovetScreen()));
            }),
            _buildActionTile(context, Icons.person_add_alt_1, "Onboard Farmer", "Register a new farmer for credit", () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Farmer onboarding coming soon!")));
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      elevation: 0, margin: const EdgeInsets.only(bottom: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle), child: Icon(icon, color: const Color(0xFF144D2F))),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        subtitle: Padding(padding: const EdgeInsets.only(top: 4.0), child: Text(subtitle, style: const TextStyle(color: Colors.grey))),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

// ==========================================
// 3. AGROVET REGISTRATION FORM
// ==========================================
class RegisterAgrovetScreen extends StatefulWidget {
  const RegisterAgrovetScreen({super.key});

  @override
  State<RegisterAgrovetScreen> createState() => _RegisterAgrovetScreenState();
}

class _RegisterAgrovetScreenState extends State<RegisterAgrovetScreen> {
  final _businessNameCtrl = TextEditingController();
  final _tillNumberCtrl = TextEditingController();
  final _ownerPhoneCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  bool _isLoading = false;

  // --- UNIVERSAL FEEDBACK POP-UP ---
  void _showFeedback(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade800 : const Color(0xFF144D2F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _submitAgrovet() async {
    if (_businessNameCtrl.text.isEmpty || _tillNumberCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('https://rahisipay-api.onrender.com/api/v1/agrovets/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "business_name": _businessNameCtrl.text,
          "till_number": _tillNumberCtrl.text,
          "owner_phone": _ownerPhoneCtrl.text,
          "location": _locationCtrl.text,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pop(context);
          _showFeedback("Agrovet Registered Successfully!");
        }
      } else {
        _showFeedback("Failed: Till might already exist.", isError: true);
      }
    } catch (e) {
      _showFeedback("Network Error. Check connection.", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, leading: const BackButton(color: Colors.black), title: const Text("New Merchant", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
      // 👇 RenderFlex Protection added
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Add Agrovet', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF144D2F))),
              const SizedBox(height: 8),
              const Text('Expand the RahisiPay network by registering a local supplier.', style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 40),
              TextField(controller: _businessNameCtrl, decoration: InputDecoration(labelText: 'Business Name', filled: true, fillColor: const Color(0xFFF4F7F6), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
              const SizedBox(height: 16),
              TextField(controller: _tillNumberCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Safaricom Till Number', filled: true, fillColor: const Color(0xFFF4F7F6), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
              const SizedBox(height: 16),
              TextField(controller: _ownerPhoneCtrl, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: 'Owner Phone Number', filled: true, fillColor: const Color(0xFFF4F7F6), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
              const SizedBox(height: 16),
              TextField(controller: _locationCtrl, decoration: InputDecoration(labelText: 'Location / Town', filled: true, fillColor: const Color(0xFFF4F7F6), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity, height: 60,
                // 👇 Button style removed to inherit globally
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitAgrovet,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Submit Merchant', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}