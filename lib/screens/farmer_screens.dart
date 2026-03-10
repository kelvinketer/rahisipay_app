import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; 
import 'dart:convert';
import 'package:mobile_scanner/mobile_scanner.dart'; // For scanning Agrovet QR Codes
import 'advisor_screen.dart'; // <-- 1. ADDED ADVISOR IMPORT

// ==========================================
// 1. COMPLIANT PROFILE COMPLETION (KYC)
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
  bool _agreedToTerms = false; 

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
              const Text('Complete KYC to instantly calculate your trust score.', style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 40),
              const Text("1. Personal Details", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF0C462B))),
              const SizedBox(height: 16),
              TextField(controller: _nameController, decoration: InputDecoration(labelText: 'Full Legal Name', filled: true, fillColor: const Color(0xFFF4F7F6), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
              const SizedBox(height: 16),
              TextField(controller: _idController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'National ID', filled: true, fillColor: const Color(0xFFF4F7F6), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
              const SizedBox(height: 40),
              const Text("2. Financial Profile", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF0C462B))),
              const SizedBox(height: 16),
              _buildSegmentSelector(),
              const SizedBox(height: 24),
              TextField(controller: _segmentDetailController, decoration: InputDecoration(labelText: detailLabel, filled: true, fillColor: const Color(0xFFF4F7F6), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
              const SizedBox(height: 16),
              TextField(controller: _segmentUnitController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: unitLabel, filled: true, fillColor: const Color(0xFFF4F7F6), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
              const SizedBox(height: 30),
              Row(
                children: [
                  Checkbox(value: _agreedToTerms, activeColor: const Color(0xFF0C462B), onChanged: (val) => setState(() => _agreedToTerms = val!)),
                  const Expanded(child: Text("I agree to Oletai's Data Privacy Policy and Credit Terms.", style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500))),
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
// 2. PREMIUM DASHBOARD (V2.0 ROI & SLIVERS)
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
        content: TextField(controller: amountController, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: "Amount", prefixText: "KES ", filled: true, fillColor: const Color(0xFFF4F7F6), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
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
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Success!"), backgroundColor: Color(0xFF0C462B)));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0C462B)),
            child: const Text("Confirm", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String projectedYield = (widget.creditLimit * 3.5).toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6), 
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200, pinned: true, stretch: true, backgroundColor: const Color(0xFF0C462B),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(widget.isProfileComplete ? "Portfolio Overview" : "Welcome", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
              background: Container(
                decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0A2E1A), Color(0xFF144D2F)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Text("${widget.trustScore.toInt()}%", style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w900, letterSpacing: -2)),
                    const Text("AGRI-TRUST SCORE", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 1.5)),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildROICard(projectedYield),
                  const SizedBox(height: 32),
                  if (!widget.isProfileComplete) _buildKYCPrompt(),
                  if (widget.isProfileComplete) ...[
                    const Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0C462B))),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildActionCircle(Icons.add_chart, "Invest", () => Navigator.push(context, MaterialPageRoute(builder: (context) => MarketplaceScreen(farmerPhone: widget.farmerPhone)))),
                        _buildActionCircle(Icons.payments_outlined, "Repay", () => _showRepayDialog(context)),
                        _buildActionCircle(Icons.history_edu, "Ledger", () => Navigator.push(context, MaterialPageRoute(builder: (context) => TransactionHistoryScreen(farmerPhone: widget.farmerPhone)))),
                        
                        // --- 2. WIRED UP THE ADVISOR BUTTON ---
                        _buildActionCircle(Icons.support_agent, "Advisor", () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => FarmAdvisorScreen(farmerPhone: widget.farmerPhone)));
                        }),
                        
                      ],
                    ),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Recent Activity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0C462B))),
                        TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TransactionHistoryScreen(farmerPhone: widget.farmerPhone))), child: const Text("View All")),
                      ],
                    ),
                    _buildTransactionList(),
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: widget.isProfileComplete ? Container(
        height: 70, margin: const EdgeInsets.symmetric(horizontal: 24),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0C462B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)), elevation: 10),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => QRScannerScreen(farmerPhone: widget.farmerPhone))),
          icon: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
          label: const Text("SCAN TO PAY AGROVET", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
        ),
      ) : null,
    );
  }

  // --- UPDATED ROI CARD WITH FL_CHART INTEGRATION ---
  Widget _buildROICard(String yieldAmtString) {
    // 1. Calculate the raw numbers for the graph
    double limit = widget.creditLimit.toDouble();
    double yieldAmt = limit * 3.5; 

    return Container(
      width: double.infinity, padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(32), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 30, offset: const Offset(0, 10))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, 
            children: [
              const Text("Buying Power", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w700)), 
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)), child: Text("+250% ROI", style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w900, fontSize: 10)))
            ]
          ),
          const SizedBox(height: 4),
          Text("KES ${limit.toInt()}", style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Color(0xFF0C462B))),
          const SizedBox(height: 30),

          // --- THE NEW FL_CHART GRAPH ---
          SizedBox(
            height: 120, // Keeps the card from getting too tall
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false), // Clean background
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        // Custom labels for the crop cycle
                        switch (value.toInt()) {
                          case 0: return const Text('Plant', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold));
                          case 3: return const Text('Grow', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold));
                          case 6: return const Text('Harvest', style: TextStyle(color: Color(0xFF0C462B), fontSize: 10, fontWeight: FontWeight.w900));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0, maxX: 6,
                minY: 0, maxY: yieldAmt * 1.2, // Leaves breathing room at the top
                lineBarsData: [
                  // Line 1: The flat Principal Investment (Baseline)
                  LineChartBarData(
                    spots: [FlSpot(0, limit), FlSpot(6, limit)],
                    isCurved: false,
                    color: Colors.grey.withOpacity(0.4),
                    barWidth: 2,
                    dashArray: [5, 5], // Dashed line
                    dotData: FlDotData(show: false),
                  ),
                  // Line 2: The sweeping Growth Curve
                  LineChartBarData(
                    spots: [
                      FlSpot(0, limit),
                      FlSpot(3, limit + ((yieldAmt - limit) * 0.25)), // Dips slightly before shooting up
                      FlSpot(6, yieldAmt),
                    ],
                    isCurved: true,
                    curveSmoothness: 0.4,
                    color: const Color(0xFF0C462B),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        // Only show the dot at the final harvest peak
                        if (index == 2) {
                          return FlDotCirclePainter(radius: 6, color: Colors.greenAccent, strokeWidth: 2, strokeColor: const Color(0xFF0C462B));
                        }
                        return FlDotCirclePainter(radius: 0, color: Colors.transparent);
                      }
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [const Color(0xFF0C462B).withOpacity(0.2), Colors.transparent],
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ------------------------------

          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),
          
          // Footer
          Row(
            children: [
              const Icon(Icons.auto_graph_rounded, color: Colors.green), 
              const SizedBox(width: 8), 
              Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  const Text("Projected Yield", style: TextStyle(color: Colors.grey, fontSize: 11)), 
                  Text("KES $yieldAmtString", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))
                ]
              )
            ]
          ),
        ],
      ),
    );
  }

  Widget _buildKYCPrompt() => GestureDetector(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileCompletionScreen(phoneNumber: widget.farmerPhone))),
    child: Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)]), borderRadius: BorderRadius.circular(24)), child: const Row(children: [Icon(Icons.stars, color: Colors.orange, size: 40), SizedBox(width: 20), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Verify Profile", style: TextStyle(fontWeight: FontWeight.w900)), Text("Unlock KES 50k instantly.")])), Icon(Icons.arrow_forward_ios, size: 14)])),
  );

  Widget _buildActionCircle(IconData icon, String label, VoidCallback onTap) => GestureDetector(onTap: onTap, child: Column(children: [Container(height: 64, width: 64, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15)]), child: Icon(icon, color: const Color(0xFF0C462B))), const SizedBox(height: 10), Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))]));

  Widget _buildTransactionList() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_transactions.isEmpty) return const Center(child: Text("No investments yet."));
    return ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _transactions.length > 3 ? 3 : _transactions.length, itemBuilder: (context, index) {
      final tx = _transactions[index];
      return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Row(children: [Icon(tx['is_credit'] ? Icons.add_circle_outline : Icons.shopping_cart_checkout, color: tx['is_credit'] ? Colors.green : const Color(0xFF0C462B)), const SizedBox(width: 16), Expanded(child: Text(tx['title'], style: const TextStyle(fontWeight: FontWeight.w700))), Text(tx['amount'], style: const TextStyle(fontWeight: FontWeight.w900))]));
    });
  }
}

// ==========================================
// 3. MARKETPLACE SCREEN
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
// 4. CHECKOUT SCREEN (WITH PRE-FILL SUPPORT)
// ==========================================
class CheckoutScreen extends StatefulWidget {
  final String farmerPhone;
  final String productName;
  final int price;
  final String? prefilledTill; 

  const CheckoutScreen({super.key, required this.farmerPhone, required this.productName, required this.price, this.prefilledTill});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String? _selectedTill;
  bool _isProcessing = false;
  bool _isLoadingAgrovets = true;
  List<Map<String, dynamic>> _agrovets = [];

  @override
  void initState() {
    super.initState();
    _selectedTill = widget.prefilledTill; // Uses the scanned till if provided
    _fetchAgrovets();
  }

  Future<void> _fetchAgrovets() async {
    try {
      final response = await http.get(Uri.parse('https://rahisipay-api.onrender.com/api/v1/agrovets'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _agrovets = List<Map<String, dynamic>>.from(data);
          _isLoadingAgrovets = false;
        });
      } else {
        _loadFallbackAgrovets();
      }
    } catch (e) {
      _loadFallbackAgrovets();
    }
  }

  void _loadFallbackAgrovets() {
    setState(() {
      _agrovets = [
        {"name": "Oletai Farm Inputs", "till_number": "888222", "location": "Nairobi"},
        {"name": "Central Seed Co.", "till_number": "112233", "location": "Kiambu"},
        {"name": "Rift Valley Agrovet", "till_number": "999888", "location": "Nakuru"},
      ];
      _isLoadingAgrovets = false;
    });
  }

  Future<void> _disburseFunds() async {
    if (_selectedTill == null || _selectedTill!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an Agrovet'), backgroundColor: Colors.red));
      return;
    }
    setState(() { _isProcessing = true; });

    try {
      final url = Uri.parse('https://rahisipay-api.onrender.com/api/v1/disburse');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"phone_number": widget.farmerPhone, "till_number": _selectedTill, "amount_kes": widget.price}),
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
            const Text('Payment Successful!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87)),
            const SizedBox(height: 16),
            Text('KES ${widget.price} sent to Till $_selectedTill.', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0C462B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      appBar: AppBar(backgroundColor: const Color(0xFF0C462B), title: const Text('Confirm Payment', style: TextStyle(color: Colors.white)), iconTheme: const IconThemeData(color: Colors.white)),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
              child: Row(children: [Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(color: Color(0xFFF4F7F6), shape: BoxShape.circle), child: const Icon(Icons.shopping_bag, color: Color(0xFF0C462B))), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Purchasing', style: TextStyle(color: Colors.grey)), Text(widget.productName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900))]))]),
            ),
            const SizedBox(height: 40),
            
            if (_selectedTill != null) ...[
              const Text('Paying To Till', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity, padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.green.shade200)),
                child: Text(_selectedTill!, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0C462B), letterSpacing: 2)),
              ),
            ] else ...[
              const Text('Search Agrovet Till / Name', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 12),
              _isLoadingAgrovets ? const Center(child: CircularProgressIndicator()) : 
              LayoutBuilder(builder: (context, constraints) => Autocomplete<Map<String, dynamic>>(
                  displayStringForOption: (option) => option['till_number'],
                  optionsBuilder: (textValue) => textValue.text.isEmpty ? const Iterable.empty() : _agrovets.where((a) => a['till_number'].toString().contains(textValue.text) || a['name'].toString().toLowerCase().contains(textValue.text.toLowerCase())),
                  onSelected: (selection) => setState(() => _selectedTill = selection['till_number']),
                  fieldViewBuilder: (context, ctrl, node, onSub) => TextField(controller: ctrl, focusNode: node, decoration: InputDecoration(hintText: 'e.g. 888222', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none))),
              )),
            ],

            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Principal'), Text('KES ${widget.price}', style: const TextStyle(fontWeight: FontWeight.w800))]),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Fee (8%)'), Text('KES $facilityFee', style: const TextStyle(fontWeight: FontWeight.w800))]),
                const Divider(height: 40),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total Due', style: TextStyle(fontWeight: FontWeight.w900)), Text('KES $totalRepayment', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0C462B)))]),
              ]),
            ),
            const Spacer(),
            SizedBox(width: double.infinity, height: 64, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0C462B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32))), onPressed: _isProcessing ? null : _disburseFunds, child: const Text('Pay Merchant', style: TextStyle(fontSize: 18, color: Colors.white)))),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 5. FULL TRANSACTION LEDGER SCREEN
// ==========================================
class TransactionHistoryScreen extends StatefulWidget {
  final String farmerPhone;
  const TransactionHistoryScreen({super.key, required this.farmerPhone});
  @override State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}
class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  List<dynamic> _transactions = [];
  bool _isLoading = true;

  @override void initState() { super.initState(); _fetchTransactions(); }

  Future<void> _fetchTransactions() async {
    try {
      final response = await http.get(Uri.parse('https://rahisipay-api.onrender.com/api/v1/transactions/${widget.farmerPhone}'));
      if (response.statusCode == 200) setState(() { _transactions = jsonDecode(response.body); _isLoading = false; });
    } catch (e) { setState(() => _isLoading = false); }
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Ledger", style: TextStyle(color: Colors.white)), backgroundColor: const Color(0xFF0C462B), iconTheme: const IconThemeData(color: Colors.white)),
    body: _isLoading ? const Center(child: CircularProgressIndicator()) : ListView.builder(itemCount: _transactions.length, itemBuilder: (context, i) => ListTile(title: Text(_transactions[i]['title']), trailing: Text(_transactions[i]['amount']))),
  );
}
// ==========================================
// 6. QR SCANNER SCREEN FOR FARMERS
// ==========================================
class QRScannerScreen extends StatefulWidget {
  final String farmerPhone;
  const QRScannerScreen({super.key, required this.farmerPhone});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isScanned = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Agrovet QR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0C462B),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // --- UPDATED: MOBILE SCANNER V6 FLASH FIX ---
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController, // Listen to the entire controller
              builder: (context, state, child) {
                // Safely handle all 4 possible torch states
                switch (state.torchState) {
                  case TorchState.on: 
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                  case TorchState.auto:
                    return const Icon(Icons.flash_auto, color: Colors.yellow);
                  case TorchState.off:
                  case TorchState.unavailable:
                  default:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                }
              },
            ),
            onPressed: () => cameraController.toggleTorch(),
          ),
          // ---------------------------------------------
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              if (_isScanned) return;
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  // Only accept valid Oletai generated QR codes for security
                  if (barcode.rawValue!.startsWith("oletai:till:")) {
                    setState(() => _isScanned = true);
                    String extractedTill = barcode.rawValue!.replaceAll("oletai:till:", "");
                    _handleScannedTill(extractedTill);
                  }
                }
              }
            },
          ),
          Center(
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.lightGreenAccent, width: 4),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          const Positioned(
            bottom: 80, left: 0, right: 0,
            child: Text("Point camera at the Agrovet's QR Code", 
              textAlign: TextAlign.center, 
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, backgroundColor: Colors.black45)),
          )
        ],
      ),
    );
  }

  void _handleScannedTill(String tillNumber) {
    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (context) => CheckoutScreen(
        farmerPhone: widget.farmerPhone, 
        productName: "Direct Shop Purchase", 
        price: 5000, // You can make this dynamic later
        prefilledTill: tillNumber,
      ))
    );
  }
}