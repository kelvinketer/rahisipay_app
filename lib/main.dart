import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; 
import 'dart:convert';                   

void main() {
  runApp(const RahisiAgroPayApp());
}

class RahisiAgroPayApp extends StatelessWidget {
  const RahisiAgroPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Oletai Agri Finance',
      theme: ThemeData(
        primaryColor: const Color(0xFF0C462B), 
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0C462B)),
        fontFamily: 'Roboto', 
        scaffoldBackgroundColor: const Color(0xFFF4F7F6), // Premium cool off-white
      ),
      home: const FrictionlessLoginScreen(), 
      debugShowCheckedModeBanner: false,
    );
  }
}

// ==========================================
// 1. FRICTIONLESS LOGIN SCREEN 
// ==========================================
class FrictionlessLoginScreen extends StatefulWidget {
  const FrictionlessLoginScreen({super.key});

  @override
  State<FrictionlessLoginScreen> createState() => _FrictionlessLoginScreenState();
}

class _FrictionlessLoginScreenState extends State<FrictionlessLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  
  bool _isLoading = false;
  bool _isOtpSent = false; 

  Future<void> _sendOtp() async {
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your M-Pesa number'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('https://rahisipay-api.onrender.com/api/v1/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"phone_number": _phoneController.text}),
      );
      if (response.statusCode == 200) {
        setState(() => _isOtpSent = true); 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SMS PIN sent!'), backgroundColor: Color(0xFF0C462B)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send SMS.'), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network Error: Check Server'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('https://rahisipay-api.onrender.com/api/v1/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"phone_number": _phoneController.text, "otp_code": _otpController.text}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DashboardScreen(
            farmerPhone: _phoneController.text, 
            trustScore: (data['score'] ?? 0).toDouble(), 
            creditLimit: data['limit'] ?? 0,
            isProfileComplete: data['is_new_user'] == false, 
          )));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid PIN.'), backgroundColor: Colors.red));
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Center(child: Image.asset('assets/images/oletai_logo.png', height: 80, errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_balance, size: 80, color: Color(0xFF0C462B)))),
              const SizedBox(height: 60),
              
              if (!_isOtpSent) ...[
                const Text('Sign In', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Color(0xFF0C462B), letterSpacing: -1)),
                const SizedBox(height: 8),
                const Text('Enter your M-Pesa number to continue.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 40),
                
                TextField(
                  controller: _phoneController, 
                  keyboardType: TextInputType.phone, 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '0712 345 678', 
                    prefixIcon: Icon(Icons.phone_android, color: Colors.grey[400]), 
                    filled: true, 
                    fillColor: const Color(0xFFF4F7F6), 
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none)
                  )
                ),
                const SizedBox(height: 40),
                
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0C462B), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32))),
                    onPressed: _isLoading ? null : _sendOtp,
                    child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Continue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ] else ...[
                const Text('Verify', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Color(0xFF0C462B), letterSpacing: -1)),
                const SizedBox(height: 8),
                Text('We sent a secure code to\n${_phoneController.text}', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 40),
                
                TextField(
                  controller: _otpController, 
                  keyboardType: TextInputType.number, 
                  maxLength: 4, 
                  textAlign: TextAlign.center, 
                  style: const TextStyle(fontSize: 36, letterSpacing: 24, fontWeight: FontWeight.w900), 
                  decoration: InputDecoration(
                    counterText: "", 
                    filled: true, 
                    fillColor: const Color(0xFFF4F7F6), 
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none)
                  )
                ),
                const SizedBox(height: 40),
                
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0C462B), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32))),
                    onPressed: _isLoading ? null : _verifyOtp,
                    child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Verify PIN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 20),
                Center(child: TextButton(onPressed: () { setState(() { _isOtpSent = false; }); }, child: const Text('Change Phone Number', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)))),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. COMPLIANT PROFILE COMPLETION (KYC)
// ==========================================
class ProfileCompletionScreen extends StatefulWidget {
  final String phoneNumber;
  const ProfileCompletionScreen({super.key, required this.phoneNumber});

  @override
  State<ProfileCompletionScreen> createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  String _userSegment = 'Farmer'; 
  final TextEditingController _idController = TextEditingController(); 
  final TextEditingController _nameController = TextEditingController(); 
  final TextEditingController _segmentDetailController = TextEditingController(); 
  final TextEditingController _segmentUnitController = TextEditingController();   
  
  bool _isLoading = false;
  bool _agreedToTerms = false; // The Play Store Checkbox

  Future<void> _submitProfile() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You must agree to the Terms & Conditions'), backgroundColor: Colors.orange));
      return;
    }
    if (_idController.text.isEmpty || _nameController.text.isEmpty || _segmentDetailController.text.isEmpty || _segmentUnitController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields to unlock credit.'), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('https://rahisipay-api.onrender.com/api/v1/apply-loan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "phone_number": widget.phoneNumber,
          "user_segment": _userSegment,
          "identifier": _segmentDetailController.text,
          "farm_size_acres": double.tryParse(_segmentUnitController.text) ?? 0.0,
          "repayment_history_multiplier": 1.0 
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final decision = data['decision'];
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context, 
            MaterialPageRoute(builder: (context) => DashboardScreen(
              farmerPhone: widget.phoneNumber, 
              trustScore: (decision['score'] as num).toDouble(), 
              creditLimit: decision['amount'],
              isProfileComplete: true,
            )),
            (route) => false 
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network Error. Please try again.'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildSegmentSelector() {
    return Container(
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: ['Farmer', 'Student', 'Professional'].map((type) {
          bool isSelected = _userSegment == type;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _userSegment = type;
                _segmentDetailController.clear();
                _segmentUnitController.clear();
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(color: isSelected ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(12), boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : []),
                child: Center(child: Text(type, style: TextStyle(color: isSelected ? const Color(0xFF0C462B) : Colors.grey[600], fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500))),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String detailLabel = "Primary Crop (e.g., Avocado)";
    String unitLabel = "Farm Size (Acres)";
    if (_userSegment == 'Student') { detailLabel = "University Name"; unitLabel = "Year of Study (1-4)"; } 
    else if (_userSegment == 'Professional') { detailLabel = "Employer / Business Name"; unitLabel = "Estimated Monthly Income"; }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, leading: const BackButton(color: Colors.black)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Unlock Your Limit', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF0C462B), letterSpacing: -1)),
              const SizedBox(height: 8),
              const Text('Complete your KYC profile to instantly calculate your trust score and access funds.', style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 40),
              
              const Text("1. Personal Details", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF0C462B))),
              const SizedBox(height: 16),
              TextField(controller: _nameController, decoration: InputDecoration(labelText: 'Full Legal Name', filled: true, fillColor: const Color(0xFFF4F7F6), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
              const SizedBox(height: 16),
              TextField(controller: _idController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'National ID Number', filled: true, fillColor: const Color(0xFFF4F7F6), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
              
              const SizedBox(height: 40),
              
              const Text("2. Financial Profile", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF0C462B))),
              const SizedBox(height: 16),
              _buildSegmentSelector(),
              const SizedBox(height: 24),
              TextField(controller: _segmentDetailController, decoration: InputDecoration(labelText: detailLabel, filled: true, fillColor: const Color(0xFFF4F7F6), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
              const SizedBox(height: 16),
              TextField(controller: _segmentUnitController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: unitLabel, filled: true, fillColor: const Color(0xFFF4F7F6), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
              
              const SizedBox(height: 30),

              // THE COMPLIANCE CHECKBOX
              Row(
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    activeColor: const Color(0xFF0C462B),
                    onChanged: (val) => setState(() => _agreedToTerms = val!),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
                      child: const Text(
                        "I agree to Oletai's Data Privacy Policy and Credit Terms.",
                        style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity, height: 64,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0C462B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32))),
                  onPressed: _isLoading ? null : _submitProfile,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Submit & Unlock', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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
// 3. PREMIUM DASHBOARD (V2.0 Overhaul)
// ==========================================
class DashboardScreen extends StatefulWidget {
  final String farmerPhone;
  final double trustScore;
  final int creditLimit;
  final bool isProfileComplete;

  const DashboardScreen({super.key, required this.farmerPhone, required this.trustScore, required this.creditLimit, required this.isProfileComplete});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<dynamic> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.isProfileComplete) {
      _fetchTransactions();
    } else {
      setState(() => _isLoading = false); 
    }
  }

  Future<void> _fetchTransactions() async {
    try {
      final url = Uri.parse('https://rahisipay-api.onrender.com/api/v1/transactions/${widget.farmerPhone}');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          _transactions = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showRepayDialog(BuildContext context) {
    final TextEditingController amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Repay Balance", style: TextStyle(color: Color(0xFF0C462B), fontWeight: FontWeight.w900)),
        content: TextField(controller: amountController, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: "Enter amount", prefixText: "KES ", filled: true, fillColor: const Color(0xFFF4F7F6), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
          ElevatedButton(
            onPressed: () async {
              final response = await http.post(
                Uri.parse('https://rahisipay-api.onrender.com/api/v1/repay'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({"phone_number": widget.farmerPhone, "amount": int.parse(amountController.text)}),
              );
              if (response.statusCode == 200) {
                Navigator.pop(context);
                _fetchTransactions(); 
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Repayment successful!"), backgroundColor: Color(0xFF0C462B)));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0C462B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
            child: const Text("Confirm", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6), 
      body: Stack(
        children: [
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _fetchTransactions,
              color: const Color(0xFF0C462B),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 120), 
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- HEADER GREETING ---
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(backgroundColor: Color(0xFF0C462B), radius: 24, child: Icon(Icons.person, color: Colors.white)),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start, 
                                children: [
                                  const Text("Good Morning,", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)), 
                                  Text(widget.farmerPhone, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 18))
                                ]
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(10), 
                            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), 
                            child: const Icon(Icons.notifications_none, color: Colors.black87)
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // --- THE VIRTUAL CARD ---
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF0C462B), Color(0xFF147446)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [BoxShadow(color: const Color(0xFF0C462B).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(Icons.wifi, color: Colors.white70),
                              Text("VISA", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Text("Total Credit Limit", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text("KES ${widget.creditLimit}", style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: -1)),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Oletai Agri Finance", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                                child: Text("Score: ${widget.trustScore.toInt()}/100", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- CIRCULAR QUICK ACTIONS ---
                    if (widget.isProfileComplete) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildQuickAction(Icons.arrow_downward, "Receive", () {}),
                            _buildQuickAction(Icons.arrow_upward, "Repay", () => _showRepayDialog(context)),
                            _buildQuickAction(Icons.shopping_bag_outlined, "Market", () => Navigator.push(context, MaterialPageRoute(builder: (context) => MarketplaceScreen(farmerPhone: widget.farmerPhone)))),
                            _buildQuickAction(Icons.more_horiz, "More", () {}),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 35),

                    // --- PROGRESSIVE PROFILING INSIGHT BANNER ---
                    if (!widget.isProfileComplete) ...[
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileCompletionScreen(phoneNumber: widget.farmerPhone))),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)]),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: Colors.orangeAccent, shape: BoxShape.circle), child: const Icon(Icons.lock_open, color: Colors.white, size: 20)),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Complete Profile", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black87, fontSize: 15)),
                                    const SizedBox(height: 2),
                                    Text("Unlock your premium KES 50k limit.", style: TextStyle(color: Colors.grey[800], fontSize: 13, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.orangeAccent),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      // FULL DASHBOARD CONTENT 
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Your Facilities", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.black87, letterSpacing: -0.5)),
                            const SizedBox(height: 16),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildFacilityCard("Agri-Input", "KES ${(widget.creditLimit * 0.60).toInt()}", Icons.agriculture, Colors.green),
                                  const SizedBox(width: 16),
                                  _buildFacilityCard("Elimu", "KES ${(widget.creditLimit * 0.25).toInt()}", Icons.school, Colors.blue),
                                  const SizedBox(width: 16),
                                  _buildFacilityCard("Maisha", "KES ${(widget.creditLimit * 0.15).toInt()}", Icons.phone_android, Colors.orange),
                                ],
                              ),
                            ),
                            const SizedBox(height: 40),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Recent Transactions", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.black87, letterSpacing: -0.5)),
                                GestureDetector(
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TransactionHistoryScreen(farmerPhone: widget.farmerPhone))),
                                  child: const Text("See all", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            if (_isLoading)
                              const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator(color: Color(0xFF0C462B))))
                            else if (_transactions.isEmpty)
                              const Center(child: Padding(padding: EdgeInsets.all(40.0), child: Text("No transactions yet.", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500))))
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _transactions.length > 5 ? 5 : _transactions.length, 
                                itemBuilder: (context, index) {
                                  final tx = _transactions[index];
                                  return _buildPremiumTransactionTile(title: tx['title'], date: tx['date'], amount: tx['amount'], isCredit: tx['is_credit']);
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          
          // --- FLOATING PILL NAV BAR ---
          Positioned(
            bottom: 24, left: 24, right: 24,
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFF0C462B), 
                borderRadius: BorderRadius.circular(35), 
                boxShadow: [BoxShadow(color: const Color(0xFF0C462B).withOpacity(0.3), blurRadius: 25, offset: const Offset(0, 10))]
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(Icons.grid_view_rounded, true),
                  _buildNavItem(Icons.account_balance_wallet_outlined, false),
                  
                  // Prominent Center Action
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MarketplaceScreen(farmerPhone: widget.farmerPhone))),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(color: Colors.lightGreenAccent.shade400, borderRadius: BorderRadius.circular(24)),
                      child: const Row(
                        children: [
                          Icon(Icons.qr_code_scanner, color: Color(0xFF0C462B), size: 20),
                          SizedBox(width: 6),
                          Text("Pay", style: TextStyle(color: Color(0xFF0C462B), fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ),
                  
                  _buildNavItem(Icons.bar_chart_rounded, false),
                  _buildNavItem(Icons.person_outline, false),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- PREMIUM UI HELPERS ---

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 60, width: 60,
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
            child: Icon(icon, color: const Color(0xFF0C462B), size: 26),
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildFacilityCard(String title, String amount, IconData icon, MaterialColor color) {
    return Container(
      width: 140, height: 150, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.shade50, shape: BoxShape.circle), child: Icon(icon, color: color, size: 24)),
          const Spacer(),
          Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black87, letterSpacing: -0.5)),
        ],
      ),
    );
  }

  Widget _buildPremiumTransactionTile({required String title, required String date, required String amount, required bool isCredit}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(height: 52, width: 52, decoration: BoxDecoration(color: isCredit ? Colors.green.shade50 : Colors.grey.shade200, shape: BoxShape.circle), child: Icon(isCredit ? Icons.arrow_downward : Icons.shopping_bag, color: isCredit ? Colors.green[700] : const Color(0xFF0C462B), size: 22)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.black87)), const SizedBox(height: 4), Text(date, style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500))])),
          Text(amount, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.5, color: isCredit ? Colors.green[700] : Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, bool isSelected) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: isSelected ? Colors.white : Colors.white54, size: 26),
        if (isSelected) const SizedBox(height: 6),
        if (isSelected) Container(width: 5, height: 5, decoration: const BoxDecoration(color: Colors.lightGreenAccent, shape: BoxShape.circle)),
      ],
    );
  }
}

// ==========================================
// 4. MARKETPLACE SCREEN
// ==========================================
class MarketplaceScreen extends StatelessWidget {
  final String farmerPhone;
  const MarketplaceScreen({super.key, required this.farmerPhone});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(backgroundColor: const Color(0xFF0C462B), title: const Text('Select Farm Inputs', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), iconTheme: const IconThemeData(color: Colors.white), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          const Text('Available Categories', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black87, letterSpacing: -0.5)),
          const SizedBox(height: 20),
          _buildProductCard(context, 'Top Dressing Fertilizer', 'CAN / Urea - 50kg Bag', 2500, Icons.grass),
          _buildProductCard(context, 'Certified Seeds', 'Hass Avocado Seedlings', 1500, Icons.nature),
          _buildProductCard(context, 'Crop Protection', 'Fungicide & Pesticide Pack', 3000, Icons.shield),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, String title, String subtitle, int price, IconData icon) {
    return Card(
      elevation: 0, color: Colors.white, margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.green[50], shape: BoxShape.circle), child: Icon(icon, color: Colors.green[700])),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.black87)),
        subtitle: Padding(padding: const EdgeInsets.only(top: 4.0), child: Text(subtitle, style: const TextStyle(fontWeight: FontWeight.w500))),
        trailing: Text('KES $price', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0C462B), fontSize: 16, letterSpacing: -0.5)),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CheckoutScreen(farmerPhone: farmerPhone, productName: title, price: price))),
      ),
    );
  }
}

// ==========================================
// 5. CHECKOUT SCREEN
// ==========================================
class CheckoutScreen extends StatefulWidget {
  final String farmerPhone;
  final String productName;
  final int price;
  const CheckoutScreen({super.key, required this.farmerPhone, required this.productName, required this.price});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _tillController = TextEditingController();
  bool _isProcessing = false;

  Future<void> _disburseFunds() async {
    if (_tillController.text.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid Merchant Till Number'), backgroundColor: Colors.red));
      return;
    }
    setState(() { _isProcessing = true; });

    try {
      final url = Uri.parse('https://rahisipay-api.onrender.com/api/v1/disburse');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"phone_number": widget.farmerPhone, "till_number": _tillController.text, "amount_kes": widget.price}),
      );

      if (response.statusCode == 200) {
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction Failed'), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network Error'), backgroundColor: Colors.red));
    } finally {
      setState(() { _isProcessing = false; });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Center(child: Icon(Icons.check_circle, color: Color(0xFF0C462B), size: 60)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Payment Successful!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87, letterSpacing: -0.5)),
            const SizedBox(height: 16),
            Text('KES ${widget.price} sent to Till ${_tillController.text}.', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey)),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0C462B), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int facilityFee = (widget.price * 0.08).round();
    final int totalRepayment = widget.price + facilityFee;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(backgroundColor: const Color(0xFF0C462B), title: const Text('Confirm Payment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), iconTheme: const IconThemeData(color: Colors.white), elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
              child: Row(
                children: [
                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.blueGrey[50], shape: BoxShape.circle), child: const Icon(Icons.shopping_bag, color: Color(0xFF0C462B))),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Purchasing', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)), const SizedBox(height: 4), Text(widget.productName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black87))])),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Text('Agrovet Till / Paybill', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.black87)),
            const SizedBox(height: 12),
            TextField(controller: _tillController, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: 'e.g. 123456', prefixIcon: Icon(Icons.store, color: Colors.grey[400]), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none))),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
              child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Principal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)), Text('KES ${widget.price}', style: const TextStyle(fontWeight: FontWeight.w800))]),
                  const SizedBox(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Facility Fee (8%)', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)), Text('KES $facilityFee', style: const TextStyle(fontWeight: FontWeight.w800))]),
                  const Divider(height: 40),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total Due', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)), Text('KES $totalRepayment', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0C462B), letterSpacing: -0.5))]),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity, height: 64,
              child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0C462B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32))), onPressed: _isProcessing ? null : _disburseFunds, child: const Text('Pay Merchant', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 6. FULL TRANSACTION LEDGER SCREEN
// ==========================================
class TransactionHistoryScreen extends StatefulWidget {
  final String farmerPhone;
  const TransactionHistoryScreen({super.key, required this.farmerPhone});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  List<dynamic> _transactions = [];
  bool _isLoading = true;
  int _totalSpent = 0;
  int _totalRepaid = 0;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    try {
      final url = Uri.parse('https://rahisipay-api.onrender.com/api/v1/transactions/${widget.farmerPhone}');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        int spent = 0;
        int repaid = 0;
        
        for (var tx in data) {
          String rawAmount = tx['amount'].toString().replaceAll(RegExp(r'[^0-9]'), '');
          int amount = int.tryParse(rawAmount) ?? 0;
          if (tx['is_credit'] == true) { repaid += amount; } else { spent += amount; }
        }

        setState(() {
          _transactions = data;
          _totalSpent = spent;
          _totalRepaid = repaid;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C462B),
        title: const Text('Ledger', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF0C462B)))
        : RefreshIndicator(
            onRefresh: _fetchTransactions,
            color: const Color(0xFF0C462B),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildSummaryCard("Utilized", "KES $_totalSpent", Colors.red[700]!, Icons.arrow_upward)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildSummaryCard("Repaid", "KES $_totalRepaid", Colors.green[700]!, Icons.arrow_downward)),
                    ],
                  ),
                  const SizedBox(height: 40),
                  const Text("All Transactions", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.black87, letterSpacing: -0.5)),
                  const SizedBox(height: 20),
                  
                  if (_transactions.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(40.0), child: Text("No transactions found.", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500))))
                  else
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _transactions.length,
                        itemBuilder: (context, index) {
                          final tx = _transactions[index];
                          return _buildPremiumTransactionTile(title: tx['title'], date: tx['date'], amount: tx['amount'], isCredit: tx['is_credit']);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildSummaryCard(String title, String amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
          const SizedBox(height: 24),
          Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black87, letterSpacing: -0.5)),
        ],
      ),
    );
  }

  Widget _buildPremiumTransactionTile({required String title, required String date, required String amount, required bool isCredit}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            height: 52, width: 52,
            decoration: BoxDecoration(color: isCredit ? Colors.green.shade50 : Colors.grey.shade200, shape: BoxShape.circle),
            child: Icon(isCredit ? Icons.arrow_downward : Icons.shopping_bag, color: isCredit ? Colors.green[700] : const Color(0xFF0C462B), size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.black87)), const SizedBox(height: 4), Text(date, style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500))])),
          Text(amount, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.5, color: isCredit ? Colors.green[700] : Colors.black87)),
        ],
      ),
    );
  }
}