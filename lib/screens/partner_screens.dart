import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; 
import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart'; // For Agrovet QR Generation

// ==========================================
// 1. AGROVET REGISTRATION
// ==========================================
class AgrovetRegistrationScreen extends StatefulWidget {
  const AgrovetRegistrationScreen({super.key});

  @override
  State<AgrovetRegistrationScreen> createState() => _AgrovetRegistrationScreenState();
}

class _AgrovetRegistrationScreenState extends State<AgrovetRegistrationScreen> {
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _tillController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  bool _isLoading = false;

  Future<void> _registerAgrovet() async {
    if (_businessNameController.text.isEmpty || _tillController.text.isEmpty || _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('https://rahisipay-api.onrender.com/api/v1/agrovets/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "business_name": _businessNameController.text,
          "till_number": _tillController.text,
          "owner_phone": _phoneController.text,
          "location": _locationController.text,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          // Send them directly to their new QR Code Display
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AgrovetDisplayQRScreen(
            businessName: _businessNameController.text, 
            tillNumber: _tillController.text
          )));
        }
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${errorData['detail'] ?? "Backend rejected"}'), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network Error: Check if Render is awake'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, leading: const BackButton(color: Colors.black)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Partner with Us', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF0C462B), letterSpacing: -1)),
              const SizedBox(height: 8),
              const Text('Register your Agrovet to start receiving direct payments from RahisiPay farmers.', style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 40),
              TextField(controller: _businessNameController, decoration: InputDecoration(labelText: 'Registered Business Name', filled: true, fillColor: const Color(0xFFF4F7F6), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
              const SizedBox(height: 16),
              TextField(controller: _tillController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'M-Pesa Till / Paybill Number', filled: true, fillColor: const Color(0xFFF4F7F6), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
              const SizedBox(height: 16),
              TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: 'Owner Phone Number', filled: true, fillColor: const Color(0xFFF4F7F6), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
              const SizedBox(height: 16),
              TextField(controller: _locationController, decoration: InputDecoration(labelText: 'Location / Town (e.g., Nairobi)', filled: true, fillColor: const Color(0xFFF4F7F6), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity, height: 64,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0C462B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32))),
                  onPressed: _isLoading ? null : _registerAgrovet,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Register Agrovet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. AGROVET QR DISPLAY SCREEN (NEW)
// ==========================================
class AgrovetDisplayQRScreen extends StatelessWidget {
  final String businessName;
  final String tillNumber;

  const AgrovetDisplayQRScreen({super.key, required this.businessName, required this.tillNumber});

  @override
  Widget build(BuildContext context) {
    final String qrData = "oletai:till:$tillNumber";

    return Scaffold(
      backgroundColor: const Color(0xFF0C462B), 
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(32), margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.storefront, color: Color(0xFF0C462B), size: 40),
              const SizedBox(height: 12),
              Text(businessName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87)),
              Text("Till Number: $tillNumber", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey)),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16), decoration: BoxDecoration(border: Border.all(color: Colors.green.shade100, width: 2), borderRadius: BorderRadius.circular(16)),
                child: QrImageView(data: qrData, version: QrVersions.auto, size: 200.0, eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF0C462B)), dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black87)),
              ),
              const SizedBox(height: 32),
              const Text("Ask the farmer to scan this code\nusing their RahisiPay App.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4)),
              const SizedBox(height: 24),
              TextButton(onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst), child: const Text("Back to Main Menu", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0C462B))))
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 3. AGENT PORTAL (ROUTER)
// ==========================================
class AgentPortalScreen extends StatefulWidget {
  const AgentPortalScreen({super.key});
  @override State<AgentPortalScreen> createState() => _AgentPortalScreenState();
}

class _AgentPortalScreenState extends State<AgentPortalScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  Future<void> _checkAgentStatus() async {
    if (_phoneController.text.isEmpty) return;
    String rawPhone = _phoneController.text.trim().replaceAll(' ', '');
    String formattedPhone = rawPhone;
    if (rawPhone.startsWith('0')) formattedPhone = '+254${rawPhone.substring(1)}';
    else if (rawPhone.startsWith('254')) formattedPhone = '+$rawPhone';
    else if (rawPhone.startsWith('7') || rawPhone.startsWith('1')) formattedPhone = '+254$rawPhone';

    setState(() => _isLoading = true);

    try {
      final String encodedPhone = Uri.encodeComponent(formattedPhone);
      final response = await http.get(Uri.parse('https://rahisipay-api.onrender.com/api/v1/agent/stats/$encodedPhone')).timeout(const Duration(seconds: 30)); 
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AgentDashboardScreen(agentPhone: formattedPhone, agentName: data['name'], balance: data['balance'], sales: data['sales'])));
      } else if (response.statusCode == 404) {
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AgentRegistrationScreen(phoneNumber: formattedPhone)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Server Status: ${response.statusCode}'), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Network Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, leading: const BackButton(color: Colors.black)),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Agent Portal', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.deepOrange)),
            const SizedBox(height: 8),
            const Text('Enter your phone number to access your commission dashboard.', style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 40),
            TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: 'Phone Number', filled: true, fillColor: const Color(0xFFF4F7F6), border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none))),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity, height: 64,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32))),
                onPressed: _isLoading ? null : _checkAgentStatus,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Continue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 4. AGENT REGISTRATION
// ==========================================
class AgentRegistrationScreen extends StatefulWidget {
  final String phoneNumber;
  const AgentRegistrationScreen({super.key, required this.phoneNumber});
  @override State<AgentRegistrationScreen> createState() => _AgentRegistrationScreenState();
}

class _AgentRegistrationScreenState extends State<AgentRegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    if (_nameController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('https://rahisipay-api.onrender.com/api/v1/agents/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"agent_name": _nameController.text, "phone_number": widget.phoneNumber}),
      );
      if (response.statusCode == 200) {
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AgentDashboardScreen(agentPhone: widget.phoneNumber, agentName: _nameController.text, balance: 0, sales: 0)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration Failed'), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network Error'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, leading: const BackButton(color: Colors.black)),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Welcome Agent', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.deepOrange)),
            const SizedBox(height: 8),
            Text('Setting up profile for ${widget.phoneNumber}', style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 40),
            TextField(controller: _nameController, decoration: InputDecoration(labelText: 'Full Name', filled: true, fillColor: const Color(0xFFF4F7F6), border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none))),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity, height: 64,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32))),
                onPressed: _isLoading ? null : _register,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Complete Registration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 5. AGENT DASHBOARD
// ==========================================
class AgentDashboardScreen extends StatelessWidget {
  final String agentPhone; final String agentName; final int balance; final int sales;
  const AgentDashboardScreen({super.key, required this.agentPhone, required this.agentName, required this.balance, required this.sales});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(backgroundColor: Colors.deepOrange, title: Text(agentName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity, padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
              child: Column(
                children: [
                  const Text("Pending Commission", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text("KES $balance", style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.deepOrange)),
                  const Divider(height: 40),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Total Seed Bags Sold", style: TextStyle(fontWeight: FontWeight.w600)), Text("$sales", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18))])
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity, height: 64,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32))),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AgentPosScreen(agentPhone: agentPhone))),
                child: const Text('New Seed Sale (POS)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 6. AGENT POS SCREEN
// ==========================================
class AgentPosScreen extends StatefulWidget {
  final String agentPhone;
  const AgentPosScreen({super.key, required this.agentPhone});
  @override State<AgentPosScreen> createState() => _AgentPosScreenState();
}

class _AgentPosScreenState extends State<AgentPosScreen> {
  final TextEditingController _farmerPhoneController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(text: "1");
  
  final List<Map<String, dynamic>> _seeds = [
    {"name": "Agrico Markies (50kg)", "price": 3500},
    {"name": "Agrico Manitou (50kg)", "price": 3500},
    {"name": "Agrico Arizona (50kg)", "price": 3200},
  ];
  Map<String, dynamic>? _selectedSeed;
  bool _isProcessing = false;

  Future<void> _processSale() async {
    if (_selectedSeed == null || _farmerPhoneController.text.isEmpty) return;

    String rawPhone = _farmerPhoneController.text.trim().replaceAll(' ', '');
    String formattedFarmer = rawPhone;
    if (rawPhone.startsWith('0')) formattedFarmer = '+254${rawPhone.substring(1)}';
    else if (rawPhone.startsWith('254')) formattedFarmer = '+$rawPhone';
    else if (rawPhone.startsWith('7') || rawPhone.startsWith('1')) formattedFarmer = '+254$rawPhone';

    int qty = int.tryParse(_quantityController.text) ?? 1;
    int totalAmount = _selectedSeed!['price'] * qty;

    setState(() => _isProcessing = true);

    try {
      final response = await http.post(
        Uri.parse('https://rahisipay-api.onrender.com/api/v1/agent/log-sale'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"agent_phone": widget.agentPhone, "farmer_phone": formattedFarmer, "amount_kes": totalAmount, "product_name": "${qty}x ${_selectedSeed!['name']}"}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _showSuccessDialog(data['commission_earned']);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sale Failed. Ensure Farmer is registered.'), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network Error'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showSuccessDialog(int commission) {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Sale Confirmed', style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold)),
        content: Text('You earned KES $commission from this sale! The farmer has received an SMS.'),
        actions: [
          TextButton(onPressed: () {
            Navigator.pop(context); Navigator.pop(context); 
          }, child: const Text('Done', style: TextStyle(color: Colors.deepOrange)))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int currentQty = int.tryParse(_quantityController.text) ?? 1;
    int total = _selectedSeed != null ? _selectedSeed!['price'] * currentQty : 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.deepOrange, title: const Text('Point of Sale', style: TextStyle(color: Colors.white)), elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<Map<String, dynamic>>(
              decoration: InputDecoration(labelText: 'Select AgriCo Seed Variety', filled: true, fillColor: const Color(0xFFF4F7F6), border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none)),
              items: _seeds.map((seed) => DropdownMenuItem(value: seed, child: Text("${seed['name']} - KES ${seed['price']}"))).toList(),
              onChanged: (val) => setState(() => _selectedSeed = val),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: TextField(controller: _quantityController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Quantity (Bags)', filled: true, fillColor: const Color(0xFFF4F7F6), border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none)), onChanged: (v) => setState((){}))),
                const SizedBox(width: 16),
                Expanded(child: Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.deepOrange.shade50, borderRadius: BorderRadius.circular(20)), child: Text("KES $total", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.deepOrange)))),
              ],
            ),
            const SizedBox(height: 40),
            const Text("Farmer Payment Details", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(controller: _farmerPhoneController, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: 'Farmer Phone Number', prefixIcon: const Icon(Icons.phone_android), filled: true, fillColor: const Color(0xFFF4F7F6), border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none))),
            const Spacer(),
            SizedBox(
              width: double.infinity, height: 64,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32))),
                onPressed: _isProcessing || _selectedSeed == null ? null : _processSale,
                child: _isProcessing ? const CircularProgressIndicator(color: Colors.white) : const Text('Charge Farmer Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}