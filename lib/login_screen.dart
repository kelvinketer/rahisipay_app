import 'screens/farmer_screens.dart';
import 'screens/partner_screens.dart';
import 'screens/agent_screens.dart'; 
import 'services/api_service.dart'; // OUR NEW MULTI-CLOUD API SERVICE
import 'package:flutter/material.dart';
import 'dart:async'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  
  bool _isLoading = false;
  bool _isOtpSent = false; 

  // --- TIMER STATE ---
  Timer? _timer;
  int _secondsRemaining = 59;
  bool _canResend = false;

  void _startResendTimer() {
    setState(() {
      _secondsRemaining = 59;
      _canResend = false;
    });
    _timer?.cancel(); 
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _canResend = true;
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); 
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // --- NEW: UNIVERSAL FEEDBACK POP-UP ---
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

  // --- 1. SEND OTP LOGIC (NOW WITH RENDER -> RAILWAY FALLBACK) ---
  Future<void> _sendOtp() async {
    String userNumber = _phoneController.text.trim();
    
    if (userNumber.length != 9) {
      _showFeedback('Please enter a valid 9-digit number after +254', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    String fullNumber = "+254$userNumber";
    
    try {
      // 👇 Automatically attempts Render first, then falls back to Railway
      await ApiService.post('/auth/send-otp', {"phone_number": fullNumber});
      
      if (mounted) {
        setState(() => _isOtpSent = true); 
        _startResendTimer(); 
        _showFeedback('Secure PIN sent via SMS');
      }
    } catch (e) {
      // 👇 Network Failure or Server Crash Catch
      if (mounted) {
        setState(() => _isOtpSent = false); 
        _showFeedback('Network Error. Check your internet connection and try again.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 2. VERIFY OTP LOGIC (NOW WITH RENDER -> RAILWAY FALLBACK) ---
  Future<void> _verifyOtp() async {
    if (_otpController.text.isEmpty) {
      _showFeedback('Please enter the 4-digit PIN.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    String fullNumber = "+254${_phoneController.text.trim()}";
    
    try {
      final data = await ApiService.post('/auth/verify-otp', {
        "phone_number": fullNumber, 
        "otp_code": _otpController.text
      });
      
      if (mounted) {
        _showFeedback('Identity Verified!');
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DashboardScreen(
          farmerPhone: fullNumber, 
          trustScore: (data['score'] ?? 0).toDouble(), 
          creditLimit: data['limit'] ?? 0,
          isProfileComplete: data['is_new_user'] == false, 
        )));
      }
    } catch (e) {
      if (mounted) {
        _showFeedback('Invalid PIN or Network Error. Please check your connection.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0A2E1A), Color(0xFF144D2F), Color(0xFF082012)],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ), 

          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  padding: const EdgeInsets.all(32.0),
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 40, offset: const Offset(0, 15)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- OLETAI LOGO ---
                      Container(
                        height: 85.0, 
                        width: 85.0, 
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipOval( 
                          child: Image.asset(
                            'assets/images/app_logo_leaf.png', 
                            fit: BoxFit.cover, 
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.0, 0.05),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: !_isOtpSent ? _buildPhoneInputPhase() : _buildOtpInputPhase(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneInputPhase() {
    return Column(
      key: const ValueKey('phone_phase'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text("Welcome Back", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF111111), letterSpacing: -0.5)),
        const SizedBox(height: 8),
        Text("Enter your M-Pesa number to access your account.", textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4)),
        const SizedBox(height: 32),

        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50, 
            borderRadius: BorderRadius.circular(16), 
            border: Border.all(color: Colors.grey.shade200)
          ),
          child: TextField(
            controller: _phoneController,
            keyboardType: TextInputType.number,
            maxLength: 9, 
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 1.2),
            decoration: InputDecoration(
              counterText: "", 
              prefixIcon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("🇰🇪", style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    const Text("+254", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87)),
                    const SizedBox(width: 12),
                    Container(height: 20, width: 2, color: Colors.grey.shade300), 
                    const SizedBox(width: 4),
                  ],
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 20),
              hintText: "7XX XXX XXX",
              hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500, letterSpacing: 1.2),
            ),
          ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity, height: 60,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF144D2F), 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
              elevation: 0,
            ),
            onPressed: _isLoading ? null : _sendOtp,
            child: _isLoading 
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) 
              : const Text("Secure Login", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ),
        
        // --- NEW: Create Account Link ---
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Don't have an account? ",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            GestureDetector(
              onTap: () {
                // TODO: Route to the Farmer KYC Registration Screen
                print("Create Account Clicked!"); 
              },
              child: const Text(
                "Create Account",
                style: TextStyle(
                  color: Color(0xFF144D2F), 
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),

        // --- NEW PARTNER ACCESS SECTION ---
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.shade300)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text("PARTNER ACCESS", style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
            ),
            Expanded(child: Divider(color: Colors.grey.shade300)),
          ],
        ),
        const SizedBox(height: 20),
        
        Row(
          children: [
            // Merchant (Agrovet) Button
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                ),
                icon: const Icon(Icons.storefront, color: Color(0xFF144D2F), size: 18),
                label: const Text("Merchants", style: TextStyle(color: Color(0xFF144D2F), fontWeight: FontWeight.w700, fontSize: 13)),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AgrovetLoginScreen())),
              ),
            ),
            const SizedBox(width: 12),
            // Agent Button
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                ),
                icon: const Icon(Icons.support_agent, color: Color(0xFF144D2F), size: 18),
                label: const Text("Agents", style: TextStyle(color: Color(0xFF144D2F), fontWeight: FontWeight.w700, fontSize: 13)),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AgentLoginScreen())),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOtpInputPhase() {
    return Column(
      key: const ValueKey('otp_phase'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text("Verify Identity", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF111111), letterSpacing: -0.5)),
        const SizedBox(height: 8),
        Text("We've sent a secure 4-digit PIN to\n+254 ${_phoneController.text}", textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4)),
        const SizedBox(height: 32),

        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50, 
            borderRadius: BorderRadius.circular(16), 
            border: Border.all(color: Colors.grey.shade200)
          ),
          child: TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 4, 
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 24, color: Color(0xFF144D2F)),
            decoration: InputDecoration(
              counterText: "", 
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 20),
              hintText: "----",
              hintStyle: TextStyle(color: Colors.grey.shade300, letterSpacing: 24),
            ),
          ),
        ),
        const SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _canResend ? "Didn't receive the PIN? " : "Resend PIN in ",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
            ),
            if (!_canResend)
              Text(
                "0:${_secondsRemaining.toString().padLeft(2, '0')}",
                style: const TextStyle(color: Color(0xFF144D2F), fontWeight: FontWeight.w900, fontSize: 13),
              ),
            if (_canResend)
              GestureDetector(
                onTap: _isLoading ? null : _sendOtp,
                child: const Text(
                  "Resend Now",
                  style: TextStyle(color: Color(0xFF144D2F), fontWeight: FontWeight.w900, fontSize: 13, decoration: TextDecoration.underline),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity, height: 60,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF144D2F), 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
              elevation: 0
            ),
            onPressed: _isLoading ? null : _verifyOtp,
            child: _isLoading 
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) 
              : const Text("Confirm & Enter", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() {
            _isOtpSent = false;
            _otpController.clear();
            _timer?.cancel(); 
          }),
          child: Text("Change Phone Number", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}