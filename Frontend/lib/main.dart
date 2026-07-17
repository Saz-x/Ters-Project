import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(const AlinmaSafePayApp());
}

class AlinmaSafePayApp extends StatelessWidget {
  const AlinmaSafePayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title:  'مصرف الإنماء - تِرس',
      theme: ThemeData(
      
        primaryColor: const Color(0xFF002134), 
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFF002134),
          secondary: const Color(0xFFCD907E), 
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F9FB), 
        fontFamily: 'Tajawal', 
      ),
      home: const AlinmaDashboardScreen(), 
    );
  }
}

//Dashboard screen for displaying services
class AlinmaDashboardScreen extends StatelessWidget {
  const AlinmaDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFCD907E),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.trending_up, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            const Text(
              'مصرف الإنماء',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF002134),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            //A welcoming banner that simulates the actual Alinma Bank app
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF002134),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("مرحباً بك، شريك الإنماء", style: TextStyle(color: Colors.white70, fontSize: 14)),
                  SizedBox(height: 5),
                  Text("الحساب الجاري: 450000******3452", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            
            const Padding(
              padding: EdgeInsets.only(top: 24, right: 16, left: 16, bottom: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text("الخدمات والمنتجات المصرفية", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF002134))),
              ),
            ),

            //List of banking services
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  _buildServiceCard(context, "التحويل المالي", Icons.swap_horiz, Colors.grey),
                  _buildServiceCard(context, "التمويل الشخصي", Icons.account_balance_wallet, Colors.grey),
                  _buildServiceCard(context, "سداد الفواتير", Icons.receipt_long, Colors.grey),
                  
                  //Our innovative service option is integrated as an active core option
                  _buildServiceCard(
                    context, 
                    "بطاقات الاستعمال لمرة واحدة", 
                    Icons.security, 
                    const Color(0xFFCD907E), 
                    isActive: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, String title, IconData icon, Color color, {bool isActive = false}) {
    return GestureDetector(
      onTap: () {
        if (isActive) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AlinmaSafePayScreen()));
        }
      },
      child: Card(
        color: Colors.white,
        elevation: isActive ? 6 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isActive ? const BorderSide(color: Color(0xFFCD907E), width: 1.5) : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: color),
              const SizedBox(height: 12),
              Text(
                title, 
                style: TextStyle(
                  fontSize: 13, 
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? const Color(0xFF002134) : Colors.black54
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//The screen dedicated to the team's innovative service
class AlinmaSafePayScreen extends StatefulWidget {
  const AlinmaSafePayScreen({super.key});

  @override
  _AlinmaSafePayScreenState createState() => _AlinmaSafePayScreenState();
}

class _AlinmaSafePayScreenState extends State<AlinmaSafePayScreen> {
  final String backendUrl = "http://127.0.0.1:8000"; 
  Map<String, dynamic>? activeCard;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _payAmountController = TextEditingController();
  Timer? _timer;
  int _secondsLeft = 30;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (activeCard != null && activeCard!['is_active'] == true) {
        setState(() {
          _secondsLeft = 30 - (DateTime.now().second % 30);
          if (_secondsLeft == 30) {
            _fetchCardStatus(activeCard!['card_number']);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _amountController.dispose();
    _payAmountController.dispose();
    super.dispose();
  }

  Future<void> _createNewCard(double limit) async {
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/create-card/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"limit_amount": limit}),
      );

      if (response.statusCode == 200) {
        setState(() {
          activeCard = jsonDecode(response.body);
        });
      }
    } catch (e) {
      _showSnackBar("فشل الاتصال بالسيرفر. تأكد من تشغيل الـ Backend!");
    }
  }

  Future<void> _fetchCardStatus(String cardNumber) async {
    try {
      final response = await http.get(Uri.parse('$backendUrl/card/$cardNumber'));
      if (response.statusCode == 200) {
        setState(() {
          activeCard = jsonDecode(response.body);
        });
      }
    } catch (e) {}
  }

  Future<void> _pay(double amount) async {
    if (activeCard == null) return;
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/pay/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "card_number": activeCard!['card_number'],
          "cvv": activeCard!['cvv'],
          "amount": amount
        }),
      );

      final result = jsonDecode(response.body);
      if (response.statusCode == 200) {
        _showSnackBar(result['message'], isSuccess: true);
      } else {
        _showSnackBar(result['detail'], isSuccess: false);
      }
      _fetchCardStatus(activeCard!['card_number']);
    } catch (e) {
      _showSnackBar("خطأ في عملية الدفع");
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Tajawal'), textAlign: TextAlign.right),
        backgroundColor: isSuccess ? Colors.green : const Color(0xFF002134),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('بطاقات الاستعمال لمرة واحدة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        backgroundColor: const Color(0xFF002134),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildAlinmaVirtualCard(),
            const SizedBox(height: 24),
            if (activeCard == null || activeCard!['is_active'] == false)
              _buildCreateCardSection()
            else
              _buildPaymentSimulationSection(),
            
            const SizedBox(height: 40),
            
            
            _buildTeamFooter(),
          ],
        ),
      ),
    );
  }

  //Card design
  Widget _buildAlinmaVirtualCard() {
    bool isActive = activeCard != null && activeCard!['is_active'] == true;
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive 
              ? [const Color(0xFF002134), const Color(0xFF0F3A53)] 
              : [Colors.grey.shade400, Colors.grey.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: isActive ? Border.all(color: const Color(0xFFCD907E), width: 1.5) : null, 
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Alinma SafePay", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFCD907E))),
              
              Container(
                width: 40,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFCD907E).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(6),
                ),
              )
            ],
          ),
          Text(
            isActive ? _formatCardNumber(activeCard!['card_number']) : "••••  ••••  ••••  ••••",
            style: const TextStyle(fontSize: 20, letterSpacing: 2, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("الحد الأقصى", style: TextStyle(color: Colors.white70, fontSize: 11)),
                  Text(
                    isActive ? "${activeCard!['limit_amount']} SAR" : "0.0 SAR",
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("Dynamic CVV", style: TextStyle(color: Colors.white70, fontSize: 11)),
                  Row(
                    children: [
                      if (isActive)
                        Text(
                          "🕒 $_secondsLeftث ",
                          style: const TextStyle(color: Color(0xFFCD907E), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      const SizedBox(width: 5),
                      Text(
                        isActive ? "${activeCard!['cvv']}" : "•••",
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCreateCardSection() {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text("أصدر بطاقتك المؤقتة الفورية الآن", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF002134))),
            const SizedBox(height: 15),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                labelText: "الحد المالي الأقصى للعملية (ريال)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.payments, color: Color(0xFFCD907E)),
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF002134), 
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                double? limit = double.tryParse(_amountController.text);
                if (limit != null && limit > 0) {
                  _createNewCard(limit);
                  _amountController.clear();
                } else {
                  _showSnackBar("الرجاء إدخال مبلغ صحيح!");
                }
              },
              child: const Text("إصدار بطاقة أحادية الاستعمال", style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSimulationSection() {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.orangeAccent)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text("محاكاة بوابة الدفع الآمن للتاجر", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange)),
            const SizedBox(height: 15),
            TextField(
              controller: _payAmountController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                labelText: "المبلغ المراد سحبه من البطاقة (ريال)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.shopping_cart, color: Colors.orange),
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                double? amount = double.tryParse(_payAmountController.text);
                if (amount != null && amount > 0) {
                  _pay(amount);
                  _payAmountController.clear();
                } else {
                  _showSnackBar("أدخل قيمة شراء صحيحة!");
                }
              },
              child: const Text("محاكاة الدفع الآن", style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  
  Widget _buildTeamFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      width: double.infinity,
      child: Column(
        children: [
          const Divider(color: Colors.black12, thickness: 1),
          const SizedBox(height: 8),
          Text(
            "Ters | تِرس Project Made by SecuPulse All Rights Reserved @ 2026",
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
           "تم تطوير هذا النظام لمشروع تِرس للمشاركة في هاكاثون امد",
            style: TextStyle(fontSize: 9, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatCardNumber(String number) {
    if (number.length != 16) return number;
    return "${number.substring(0, 4)}  ${number.substring(4, 8)}  ${number.substring(8, 12)}  ${number.substring(12, 16)}";
  }
}
