import 'package:flutter/material.dart';

// ==========================================
// 1. ACADEMY DASHBOARD SCREEN
// ==========================================
class AcademyScreen extends StatelessWidget {
  final String farmerPhone;

  const AcademyScreen({super.key, required this.farmerPhone});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C462B),
        title: const Text('Agri-Academy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Learn & Earn', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0C462B), letterSpacing: -1)),
            const SizedBox(height: 8),
            const Text('Complete modules to increase your Agri-Trust Score and unlock higher Smart Capital limits.', style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.4)),
            const SizedBox(height: 32),
            
            const Text('Recommended for Kiambu County', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 16),
            
            // --- THE COURSE CARD ---
            _buildCourseCard(
              context,
              title: 'Hass Avocado High-Yield Guide',
              duration: '5 Min Read',
              rewardScore: '+2%',
              rewardLimit: '+ KES 5,000',
              icon: Icons.eco,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => LessonPlayerScreen(farmerPhone: farmerPhone)));
              }
            ),
            
            const SizedBox(height: 16),
            
            // A locked future course
            Opacity(
              opacity: 0.6,
              child: _buildCourseCard(
                context,
                title: 'Soil Ph & Top Dressing Basics',
                duration: '8 Min Read',
                rewardScore: '+3%',
                rewardLimit: '+ KES 10,000',
                icon: Icons.water_drop,
                isLocked: true,
                onTap: () {}
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, {required String title, required String duration, required String rewardScore, required String rewardLimit, required IconData icon, required VoidCallback onTap, bool isLocked = false}) {
    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: isLocked ? Border.all(color: Colors.grey.shade300) : null,
          boxShadow: isLocked ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: isLocked ? Colors.grey.shade100 : Colors.green.shade50, shape: BoxShape.circle),
                  child: Icon(isLocked ? Icons.lock : icon, color: isLocked ? Colors.grey : Colors.green.shade700),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFFF4F7F6), borderRadius: BorderRadius.circular(12)),
                  child: Text(duration, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.grey)),
                )
              ],
            ),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87)),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Reward for Completion:', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
                Row(
                  children: [
                    const Icon(Icons.trending_up, color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    Text(rewardScore, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.orange)),
                    const SizedBox(width: 12),
                    Text(rewardLimit, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0C462B))),
                  ],
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. THE LESSON PLAYER (SWIPEABLE CARDS)
// ==========================================
class LessonPlayerScreen extends StatefulWidget {
  final String farmerPhone;

  const LessonPlayerScreen({super.key, required this.farmerPhone});

  @override
  State<LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends State<LessonPlayerScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _isClaiming = false;

  final List<Map<String, String>> _lessonSteps = [
    {
      "title": "Site Selection & Spacing",
      "content": "Hass avocados need well-drained soil to prevent root rot. Ensure you plant them in an area with good sunlight. Space your trees at least 5x5 meters apart to allow for canopy growth.",
      "imageIcon": "🌞"
    },
    {
      "title": "The Planting Hole",
      "content": "Dig a hole 2 feet wide and 2 feet deep. Mix the topsoil with well-rotted manure before returning it to the hole. Never bury the graft union (the swollen part of the stem) below the soil line.",
      "imageIcon": "🌱"
    },
    {
      "title": "Watering & Mulching",
      "content": "Young trees require 10-15 liters of water twice a week during dry seasons. Apply thick mulch around the base to retain moisture, but keep the mulch 10cm away from the trunk to prevent fungal diseases.",
      "imageIcon": "💧"
    }
  ];

  void _claimReward() async {
    setState(() => _isClaiming = true);
    
    // We will connect this to your FastAPI backend shortly!
    await Future.delayed(const Duration(seconds: 2)); 
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🎉 +2% Trust Score added! Limit increased.'), backgroundColor: Colors.orange));
      Navigator.pop(context); // Go back to Academy Dashboard
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C462B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
              child: Row(
                children: List.generate(
                  _lessonSteps.length,
                  (index) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 6,
                      decoration: BoxDecoration(
                        color: index <= _currentIndex ? Colors.lightGreenAccent : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Swipable Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemCount: _lessonSteps.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_lessonSteps[index]["imageIcon"]!, style: const TextStyle(fontSize: 100)),
                        const SizedBox(height: 40),
                        Text(_lessonSteps[index]["title"]!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 24),
                        Text(_lessonSteps[index]["content"]!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 18, height: 1.5)),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Navigation Controls
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0C462B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32))
                  ),
                  onPressed: () {
                    if (_currentIndex < _lessonSteps.length - 1) {
                      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                    } else {
                      _claimReward();
                    }
                  },
                  child: _isClaiming 
                    ? const CircularProgressIndicator(color: Color(0xFF0C462B))
                    : Text(_currentIndex < _lessonSteps.length - 1 ? 'Next Tip' : 'Claim Smart Capital Reward', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}