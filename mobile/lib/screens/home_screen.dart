import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'challans_screen.dart';
import 'profile_screen.dart';
import 'complaints_screen.dart';
import 'visitor_screen.dart';
import 'noc_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  final _pages = const [
    _DashboardTab(),
    ChallansScreen(),
    ComplaintsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tab, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Challans'),
          NavigationDestination(icon: Icon(Icons.report_outlined), selectedIcon: Icon(Icons.report), label: 'Complaints'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatefulWidget {
  const _DashboardTab();
  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await context.read<ApiService>().getDashboard();
      if (mounted) setState(() { _data = res['data']; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.user;
    final prop = auth.property;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(slivers: [
                SliverAppBar(
                  expandedHeight: 160,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      color: const Color(0xFF1A5276),
                      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Welcome, ${user?['name']?.toString().split(' ').first ?? 'Resident'}',
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        if (prop != null)
                          Text('Plot ${prop['plot_no']} — ${prop['sector_name']}',
                              style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ]),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      onPressed: () async {
                        await context.read<AuthService>().logout();
                        if (mounted) Navigator.pushAndRemoveUntil(context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
                      },
                    ),
                  ],
                ),

                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(delegate: SliverChildListDelegate([
                    if (_data != null) _OutstandingCard(data: _data!),
                    const SizedBox(height: 16),

                    const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      children: [
                        _QuickAction(icon: Icons.receipt_long, label: 'Challans',
                            onTap: () => _navigateTo(const ChallansScreen())),
                        _QuickAction(icon: Icons.supervisor_account, label: 'Visitors',
                            onTap: () => _navigateTo(const VisitorScreen())),
                        _QuickAction(icon: Icons.article_outlined, label: 'NOC',
                            onTap: () => _navigateTo(const NocScreen())),
                        _QuickAction(icon: Icons.report_problem_outlined, label: 'Complaints',
                            onTap: () => _navigateTo(const ComplaintsScreen())),
                        _QuickAction(icon: Icons.person_outline, label: 'Profile',
                            onTap: () => _navigateTo(const ProfileScreen())),
                        _QuickAction(icon: Icons.notifications_outlined, label: 'Alerts',
                            onTap: () {}),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (_data?['announcements'] != null && (_data!['announcements'] as List).isNotEmpty) ...[
                      const Text('Announcements', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      ...(_data!['announcements'] as List).map((a) => _AnnouncementCard(a: a)),
                    ],

                    if (_data?['recent_challans'] != null && (_data!['recent_challans'] as List).isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text('Recent Challans', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      ...(_data!['recent_challans'] as List).map((c) => _ChallanTile(challan: c)),
                    ],

                    const SizedBox(height: 80),
                  ])),
                ),
              ]),
            ),
    );
  }

  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

class _OutstandingCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _OutstandingCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final outstanding = data['outstanding_amount'] ?? 0;
    final paid = data['paid_this_month'] ?? 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1A5276), Color(0xFF2E86C1)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Outstanding Balance', style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 4),
        Text('PKR ${_fmt(outstanding)}',
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Row(children: [
          const Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
          const SizedBox(width: 6),
          Text('PKR ${_fmt(paid)} paid this month',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ]),
      ]),
    );
  }

  String _fmt(dynamic v) {
    final n = (v is num) ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0;
    return n.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0,2))]),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: const Color(0xFF1A5276), size: 28),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final Map<String, dynamic> a;
  const _AnnouncementCard({required this.a});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: a['is_pinned'] == 1 ? Colors.orange : const Color(0xFF1A5276), width: 4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(a['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
          if (a['is_pinned'] == 1) const Icon(Icons.push_pin, size: 16, color: Colors.orange),
        ]),
        const SizedBox(height: 4),
        Text(a['content'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

class _ChallanTile extends StatelessWidget {
  final Map<String, dynamic> challan;
  const _ChallanTile({required this.challan});

  @override
  Widget build(BuildContext context) {
    final status = challan['status'] ?? 'unpaid';
    final colors = {
      'paid': Colors.green, 'unpaid': Colors.orange,
      'overdue': Colors.red, 'partial': Colors.blue,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(challan['account_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 2),
          Text(challan['challan_no'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('PKR ${challan['net_amount'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: (colors[status] ?? Colors.grey).withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
            child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: colors[status] ?? Colors.grey)),
          ),
        ]),
      ]),
    );
  }
}
