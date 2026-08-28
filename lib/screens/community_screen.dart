import 'package:flutter/material.dart';
import '../services/api_service.dart'; // NEW: Imported our multi-cloud service

class CommunityScreen extends StatefulWidget {
  final String farmerPhone;

  const CommunityScreen({super.key, required this.farmerPhone});

  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  bool _isLoading = true;
  bool _isMember = false;
  bool _isJoining = false;
  
  Map<String, dynamic>? _groupData;
  final TextEditingController _inviteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkCommunityStatus();
  }

  // --- 1. UPDATED: CHECK STATUS WITH FALLBACK ---
  Future<void> _checkCommunityStatus() async {
    try {
      // ApiService automatically tries Render, then Railway, and returns the JSON payload
      final data = await ApiService.get('/community/status/${widget.farmerPhone}');
      
      if (mounted) {
        setState(() {
          _isMember = data['has_group'] ?? false;
          if (_isMember) {
            _groupData = data;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- 2. UPDATED: JOIN COOPERATIVE WITH FALLBACK ---
  Future<void> _joinCommunity() async {
    if (_inviteController.text.trim().isEmpty) return;
    
    setState(() => _isJoining = true);
    
    try {
      // ApiService automatically routes the POST request to the healthy server
      await ApiService.post('/community/join', {
        "phone_number": widget.farmerPhone,
        "invite_code": _inviteController.text.trim()
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Successfully joined the cooperative!'), 
          backgroundColor: Color(0xFF0C462B)
        ));
        _checkCommunityStatus(); // Refresh the screen to show the active group view
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Invalid code or Network Error. Please try again.'), 
          backgroundColor: Colors.red
        ));
        setState(() => _isJoining = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C462B),
        elevation: 0,
        title: const Text("Digital Cooperatives", style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF0C462B)))
        : (_isMember ? _buildActiveGroupView() : _buildJoinGroupView()),
    );
  }

  Widget _buildJoinGroupView() {
    return Center(
      // 👇 THE FIX: SingleChildScrollView allows the column to scroll on short screens
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 100, width: 100,
              decoration: BoxDecoration(color: const Color(0xFF0C462B).withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.people_alt_outlined, size: 50, color: Color(0xFF0C462B)),
            ),
            const SizedBox(height: 32),
            const Text("Farm Together, Grow Together", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF111111)), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(
              "Join a local Rahisi Pay cooperative to unlock higher Smart Capital limits, lower Agrovet rates, and localized agronomy training.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 40),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
              child: TextField(
                controller: _inviteController,
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2.0),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 20),
                  hintText: "ENTER INVITE CODE",
                  hintStyle: TextStyle(color: Colors.grey.shade400, letterSpacing: 2.0, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0C462B), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
                  elevation: 0,
                ),
                onPressed: _isJoining ? null : _joinCommunity,
                child: _isJoining 
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Text("Join Cooperative", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveGroupView() {
    if (_groupData == null) return const SizedBox.shrink();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group Header Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0A2E1A), Color(0xFF144D2F)]),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.green.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                      child: const Text("Verified Co-Op", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const Icon(Icons.verified, color: Colors.white, size: 20),
                  ],
                ),
                const SizedBox(height: 20),
                Text(_groupData!['group_name'] ?? "", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.white70, size: 16),
                    const SizedBox(width: 4),
                    Text(_groupData!['region'] ?? "", style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    const Spacer(),
                    const Icon(Icons.group, color: Colors.white70, size: 16),
                    const SizedBox(width: 4),
                    Text("${_groupData!['member_count']} Members", style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Collective Stats
          const Text("Group Performance", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF111111))),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.trending_up, color: Colors.green, size: 28),
                      const SizedBox(height: 12),
                      Text("${_groupData!['collective_trust_score']}%", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                      Text("Collective Trust", style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.discount, color: Colors.orange, size: 28),
                      const SizedBox(height: 12),
                      const Text("-2.5%", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                      Text("Agrovet Discount", style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Announcements
          const Text("Leader Announcements", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF111111))),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.blue.shade100)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.campaign, color: Colors.blue, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Upcoming Hub Training", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blue)),
                      const SizedBox(height: 4),
                      Text("We have a physical session on feed management this Friday at the Nairobi Hub. Attendance boosts our group score!", style: TextStyle(color: Colors.blue.shade900, fontSize: 13, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}