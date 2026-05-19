import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ==========================================
// 1. AGROVET / MERCHANT LOGIN SCREEN
// ==========================================
class AgrovetLoginScreen extends StatefulWidget {
  const AgrovetLoginScreen({super.key});

  @override
  State<AgrovetLoginScreen> createState() => _AgrovetLoginScreenState();
}

class _AgrovetLoginScreenState extends State<AgrovetLoginScreen> {
  final TextEditingController _tillController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;

  // --- UNIVERSAL FEEDBACK POP-UP ---
  void _showFeedback(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
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

  Future<void> _loginMerchant() async {
    if (_tillController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);

    String tillNumber = _tillController.text.trim();
    
    try {
      // 1. Send Till Number to Backend to trigger SMS
      final response = await http.post(
        Uri.parse('https://rahisipay-api.onrender.com/api/v1/agrovets/login/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"till_number": tillNumber}),
      );
      
      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          String maskedPhone = data['masked_phone'] ?? "your number";

          // 2. Show OTP Dialog to the user
          if (mounted) {
            _showOTPDialog(tillNumber, maskedPhone);
          }
        } catch (e) {
          _showFeedback('Server response error. Please try again.', isError: true);
        }
      } else if (response.statusCode == 404) {
         _showFeedback('Till not found. Please register first.', isError: true);
      } else {
         _showFeedback('Server Error. Try again.', isError: true);
      }
    } catch (e) {
      _showFeedback('Network Error. Check your connection.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showOTPDialog(String tillNumber, String maskedPhone) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isVerifying = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Verify Login", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF144D2F))),
              content: SingleChildScrollView( // 👇 Fixes RenderFlex if keyboard overlaps dialog
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Enter the 4-digit PIN sent to $maskedPhone", style: TextStyle(color: Colors.grey.shade700)),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: "----",
                        counterText: "",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isVerifying ? null : () {
                    _otpController.clear();
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  // 👇 Notice we removed the style block. It pulls directly from main.dart now!
                  onPressed: isVerifying ? null : () async {
                    if (_otpController.text.length != 4) return;
                    
                    setDialogState(() => isVerifying = true);
                    
                    try {
                      // 3. Send OTP to backend for verification
                      final verifyResponse = await http.post(
                        Uri.parse('https://rahisipay-api.onrender.com/api/v1/agrovets/login/verify-otp'),
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode({
                          "till_number": tillNumber,
                          "otp_code": _otpController.text.trim()
                        }),
                      );

                      if (verifyResponse.statusCode == 200) {
                        final data = jsonDecode(verifyResponse.body);
                        if (mounted) {
                          Navigator.pop(context); // Close Dialog
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => AgrovetDashboardScreen(
                              businessName: data['business_name'] ?? 'Merchant',
                              tillNumber: data['till_number'] ?? tillNumber,
                              location: data['location'] ?? "Kenya", 
                            )),
                          );
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid PIN. Try again.'), backgroundColor: Colors.red));
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network Error. Check connection.'), backgroundColor: Colors.red));
                      }
                    } finally {
                      if (mounted) {
                        setDialogState(() => isVerifying = false);
                      }
                    }
                  },
                  child: isVerifying 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Verify", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        leading: const BackButton(color: Colors.black),
        title: const Text("Merchant Portal", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      // 👇 THE FIX: Center + SingleChildScrollView prevents the keyboard overflow
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                child: const Icon(Icons.storefront, size: 50, color: Color(0xFF144D2F)),
              ),
              const SizedBox(height: 24),
              const Text('Agrovet Login', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF144D2F))),
              const SizedBox(height: 8),
              Text('Manage your business and track payments from farmers.', style: TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.4)),
              const SizedBox(height: 40),
              
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                child: TextField(
                  controller: _tillController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Safaricom Till Number', 
                    prefixIcon: Icon(Icons.numbers, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(20)
                  ),
                ),
              ),
              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity, height: 60,
                // 👇 Removed the style block. Inherits globally.
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _loginMerchant,
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('Access Dashboard', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AgrovetRegistrationScreen()));
                  },
                  child: const Text('Not registered? Apply here', style: TextStyle(color: Color(0xFF144D2F), fontWeight: FontWeight.bold)),
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
// 2. AGROVET DASHBOARD SCREEN
// ==========================================
class AgrovetDashboardScreen extends StatelessWidget {
  final String businessName;
  final String tillNumber;
  final String location;

  const AgrovetDashboardScreen({
    super.key, required this.businessName, required this.tillNumber, required this.location
  });

  @override
  Widget build(BuildContext context) {
    // Mock balance for now (we can wire this to a live backend endpoint later)
    int mockBalance = 24500; 

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6), // Keeping this grey so the white cards pop!
      appBar: AppBar(
        backgroundColor: const Color(0xFF144D2F),
        title: Text(businessName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Card
            Container(
              width: double.infinity, padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(24), 
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Available Balance", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w700)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Text("Till: $tillNumber", style: const TextStyle(color: Color(0xFF144D2F), fontWeight: FontWeight.w900, fontSize: 12)),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text("KES $mockBalance", style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Color(0xFF111111))),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity, height: 50,
                    // 👇 Removed the style block. Inherits globally.
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Settlement request sent to M-Pesa Business!")));
                      },
                      icon: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 20),
                      label: const Text("Withdraw to Bank / M-Pesa", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 40),
            
            // Recent Transactions
            const Text("Recent Farmer Payments", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF111111))),
            const SizedBox(height: 16),
            
            _buildTxnTile("Farmer (+254788***180)", "Top Dressing Fertilizer", 2500, "Today, 10:42 AM"),
            _buildTxnTile("Farmer (+254722***001)", "Avocado Seedlings", 1500, "Yesterday, 3:15 PM"),
            _buildTxnTile("Farmer (+254711***999)", "Pesticide Pack", 3000, "Mar 08, 1:00 PM"),
          ],
        ),
      ),
    );
  }

  Widget _buildTxnTile(String farmer, String item, int amount, String date) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
            child: const Icon(Icons.arrow_downward, color: Colors.green, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(farmer, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 4),
                Text("$item • $date", style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
              ],
            ),
          ),
          Text("+KES $amount", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.green, fontSize: 15)),
        ],
      ),
    );
  }
}

// ==========================================
// 3. AGROVET REGISTRATION SCREEN (Self-Serve)
// ==========================================
class AgrovetRegistrationScreen extends StatefulWidget {
  const AgrovetRegistrationScreen({super.key});

  @override
  State<AgrovetRegistrationScreen> createState() => _AgrovetRegistrationScreenState();
}

class _AgrovetRegistrationScreenState extends State<AgrovetRegistrationScreen> {
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
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
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
          Navigator.pop(context); // Go back to login screen
          _showFeedback("Registration Successful! You can now log in.");
        }
      } else {
        _showFeedback("Failed: Till might already exist.", isError: true);
      }
    } catch (e) {
      _showFeedback("Network Error. Check your connection.", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: const BackButton(color: Colors.black)),
      // 👇 THE FIX: Center + SingleChildScrollView for keyboard safety
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Partner with Us', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF144D2F))),
              const SizedBox(height: 8),
              const Text('Accept RahisiPay credit at your Agrovet and grow your sales instantly.', style: TextStyle(fontSize: 16, color: Colors.grey)),
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
                // 👇 Removed the style block. Inherits globally.
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitAgrovet,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Apply Now', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}