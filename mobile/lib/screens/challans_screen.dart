import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class ChallansScreen extends StatefulWidget {
  const ChallansScreen({super.key});
  @override
  State<ChallansScreen> createState() => _ChallansScreenState();
}

class _ChallansScreenState extends State<ChallansScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List _unpaid = [], _paid = [], _all = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _load() async {
    try {
      final res = await context.read<ApiService>().getChallans();
      final list = (res['data'] as List?) ?? [];
      if (mounted) setState(() {
        _all    = list;
        _unpaid = list.where((c) => ['unpaid','overdue','partial'].contains(c['status'])).toList();
        _paid   = list.where((c) => c['status'] == 'paid').toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Challans'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Due (${_unpaid.length})'),
            Tab(text: 'Paid (${_paid.length})'),
            Tab(text: 'All (${_all.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(controller: _tabs, children: [
              _ChallanList(challans: _unpaid, onRefresh: _load),
              _ChallanList(challans: _paid, onRefresh: _load),
              _ChallanList(challans: _all, onRefresh: _load),
            ]),
    );
  }
}

class _ChallanList extends StatelessWidget {
  final List challans;
  final Future<void> Function() onRefresh;
  const _ChallanList({required this.challans, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (challans.isEmpty) return const Center(child: Text('No challans found'));
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: challans.length,
        itemBuilder: (_, i) => _ChallanCard(challan: challans[i]),
      ),
    );
  }
}

class _ChallanCard extends StatelessWidget {
  final Map<String, dynamic> challan;
  const _ChallanCard({required this.challan});

  static const _statusColors = {
    'paid':    Color(0xFF27AE60),
    'unpaid':  Color(0xFFE67E22),
    'overdue': Color(0xFFC0392B),
    'partial': Color(0xFF2980B9),
    'waived':  Color(0xFF8E44AD),
  };

  @override
  Widget build(BuildContext context) {
    final status = challan['status'] ?? 'unpaid';
    final color  = _statusColors[status] ?? Colors.grey;
    final amount = double.tryParse(challan['net_amount']?.toString() ?? '0') ?? 0;
    final arrears= double.tryParse(challan['arrears']?.toString()   ?? '0') ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.receipt_long, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(challan['account_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              Text(challan['challan_no'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ]),
          const Divider(height: 20),
          Row(children: [
            _infoChip(Icons.calendar_today, challan['due_date'] ?? ''),
            const Spacer(),
            if (arrears > 0)
              Text('Arrears: PKR ${arrears.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.red, fontSize: 11)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            const Text('Net Payable:', style: TextStyle(color: Colors.grey)),
            const Spacer(),
            Text('PKR ${amount.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A5276))),
          ]),
          if (status == 'unpaid' || status == 'overdue' || status == 'partial') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.payment, size: 18),
                label: const Text('Pay Online'),
                onPressed: () => _showPayInfo(context),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 13, color: Colors.grey),
    const SizedBox(width: 4),
    Text(text, style: const TextStyle(color: Colors.grey, fontSize: 12)),
  ]);

  void _showPayInfo(BuildContext context) {
    showModalBottomSheet(context: context, builder: (_) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Payment Options', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        const Text('Visit the RMC office or pay via bank transfer:', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 12),
        _payRow('Bank', 'Habib Bank Limited (HBL)'),
        _payRow('Account Title', 'PNWHS bin Qasim'),
        _payRow('Account No', 'XX-XXXX-XXXXX-XXX'),
        _payRow('IBAN', 'PKXXXXXXXXXXXXXXXXXXXXXXXX'),
        const SizedBox(height: 16),
        const Text('Use your Challan Number as payment reference.',
            style: TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 20),
      ]),
    ));
  }

  Widget _payRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
      Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
    ]),
  );
}
