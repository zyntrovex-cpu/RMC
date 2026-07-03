import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = ApiService.instance.getProfile();
  }

  @override
  Widget build(BuildContext context) {
    final localization = context.watch<LocalizationService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(localization.t('profile')),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1A5276),
              ),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text(localization.t('connection_error')),
            );
          }

          final data = snapshot.data ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      localization.t('name'),
                      data['name'] ?? 'N/A',
                    ),
                    _buildDivider(),
                    _buildInfoRow(
                      'Email',
                      data['email'] ?? 'N/A',
                    ),
                    _buildDivider(),
                    _buildInfoRow(
                      localization.t('mobile'),
                      data['mobile'] ?? 'N/A',
                    ),
                    _buildDivider(),
                    _buildInfoRow(
                      localization.t('property'),
                      data['property'] != null
                          ? '${data['property']['plot_no']}, ${data['property']['sector_name']}'
                          : 'N/A',
                    ),
                    _buildDivider(),
                    _buildInfoRow(
                      localization.t('address'),
                      data['address'] ?? 'N/A',
                    ),
                    if (data['cnic'] != null) ...[
                      _buildDivider(),
                      _buildInfoRow('CNIC', data['cnic'] ?? 'N/A'),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.grey[300],
      height: 1,
    );
  }
}
