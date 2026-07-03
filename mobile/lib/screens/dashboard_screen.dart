import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import 'profile_screen.dart';
import 'challans_screen.dart';
import 'visitor_passes_screen.dart';
import 'complaints_screen.dart';
import 'noc_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<Map<String, dynamic>> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = ApiService.instance.getDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final localization = context.watch<LocalizationService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(localization.t('dashboard')),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1A5276),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(localization.t('connection_error')),
            );
          }

          final data = snapshot.data ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Property Info
                if (data['property'] != null)
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${data['property']['plot_no']}, ${data['property']['sector_name']}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A5276),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Outstanding Dues
                if (data['total_outstanding'] != null &&
                    data['total_outstanding'] > 0)
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Colors.red, width: 2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localization.t('dues'),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Rs. ${data['total_outstanding'].toString().replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',')}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // Quick Links
                Text(
                  localization.t('home'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _buildQuickLink(
                      context,
                      Icons.receipt,
                      localization.t('challans'),
                      () => _navigateTo(context, const ChallansScreen()),
                    ),
                    _buildQuickLink(
                      context,
                      Icons.badge,
                      localization.t('visitor_passes'),
                      () =>
                          _navigateTo(context, const VisitorPassesScreen()),
                    ),
                    _buildQuickLink(
                      context,
                      Icons.description,
                      localization.t('noc'),
                      () => _navigateTo(context, const NocScreen()),
                    ),
                    _buildQuickLink(
                      context,
                      Icons.warning,
                      localization.t('complaints'),
                      () => _navigateTo(context, const ComplaintsScreen()),
                    ),
                    _buildQuickLink(
                      context,
                      Icons.person,
                      localization.t('profile'),
                      () => _navigateTo(context, const ProfileScreen()),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Announcements
                if (data['announcements'] != null &&
                    (data['announcements'] as List).isNotEmpty) ...[
                  Text(
                    localization.t('announcements'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...(data['announcements'] as List)
                      .map<Widget>((announcement) {
                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              announcement['title'] ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              announcement['body'] ?? '',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickLink(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: const Color(0xFF1A5276)),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.read<LocalizationService>().t('logout')),
        content:
            Text(context.read<LocalizationService>().t('connection_error')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.read<LocalizationService>().t('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthService>().logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(context.read<LocalizationService>().t('logout')),
          ),
        ],
      ),
    );
  }
}
