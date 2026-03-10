import 'package:flutter/material.dart';
import '../login_screen.dart'; // To navigate to the login screen after onboarding

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;

  // The strategic messaging for our Social Enterprise
  final List<Map<String, dynamic>> onboardingData = [
    {
      "icon": Icons.psychology_alt,
      "title": "We Invest In Your Soil",
      "description": "You are not taking a loan; you are unlocking capital. We provide the leverage you need to turn idle land into a profitable business.",
    },
    {
      "icon": Icons.storefront,
      "title": "Smart Capital Network",
      "description": "No risky cash handling. Instantly access quality seeds and fertilizers directly from our verified Oletai Agrovet partners.",
    },
    {
      "icon": Icons.trending_up,
      "title": "Your Farm Advisor",
      "description": "Your success is our return. Get real-time, data-driven agronomic advice to protect your crops and maximize your harvest yield.",
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip Button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (context) => const LoginScreen()),
                ),
                child: const Text("Skip", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            
            // Sliding Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemCount: onboardingData.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon / Illustration Placeholder
                        Container(
                          height: 150,
                          width: 150,
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            onboardingData[index]["icon"], 
                            size: 80, 
                            color: const Color(0xFF144D2F) // Oletai Green
                          ),
                        ),
                        const SizedBox(height: 60),
                        
                        // Title
                        Text(
                          onboardingData[index]["title"],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF111111),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Description
                        Text(
                          onboardingData[index]["description"],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation Area (Dots & Button)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 30.0),
              child: Column(
                children: [
                  // Animated Dot Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      onboardingData.length,
                      (index) => buildDot(index, context),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Get Started / Next Button
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF144D2F),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        if (_currentPage == onboardingData.length - 1) {
                          // Last page, go to login
                          Navigator.pushReplacement(
                            context, MaterialPageRoute(builder: (context) => const LoginScreen()),
                          );
                        } else {
                          // Next page
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      child: Text(
                        _currentPage == onboardingData.length - 1 ? "Enter Oletai" : "Next",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to build the animated dots
  Widget buildDot(int index, BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 8),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? const Color(0xFF144D2F) : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}