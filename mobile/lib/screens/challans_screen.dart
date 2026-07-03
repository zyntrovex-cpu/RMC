import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';

class ChallansScreen extends StatefulWidget {
  const ChallansScreen({Key? key}) : super(key: key);

  @override
  State<ChallansScreen> createState() => _ChallansScreenState();
}

class _ChallansScreenState extends State<ChallansScreen> {
  late Future<List<dynamic>> _challansFuture;

  @override
  void initState() {
    super.initState();
    _challansFuture = ApiService.instance.getChallans();
  }

  @override
  Widget build(BuildContext context) {
    final localization = context.watch<LocalizationService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(localization.t('challans')),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _challansFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1A5276),
              ),
            );
          }

          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Text(localization.t('connection_error')),
            );
          }

          final challans = snapshot.data ?? [];

          if (challans.isEmpty) {
            return Center(
              child: Text(localization.t('no_data')),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: challans.length,
            itemBuilder: (context, index) {
              final challan = challans[index] as Map<String, dynamic>;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border(
                      left: BorderSide(
                        color: _getStatusColor(challan['status']),
                        width: 4,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Bill #${challan['bill_no'] ?? challan['id']}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(challan['status']),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                (challan['status'] ?? 'PENDING')
                                    .toString()
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          localization.t('amount'),
                          'Rs. ${challan['amount']}',
                        ),
                        if (challan['due_date'] != null) ...[
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            localization.t('date'),
                            challan['due_date'].toString(),
                          ),
                        ],
                        if (challan['description'] != null) ...[
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            localization.t('description'),
                            challan['description'].toString(),
                          ),
                        ],
                        if (challan['status'] != 'paid') ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A5276),
                              ),
                              child: const Text(
                                'Pay Now',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(dynamic status) {
    final statusStr = status?.toString().toLowerCase() ?? '';
    if (statusStr == 'paid') return Colors.green;
    if (statusStr == 'pending') return Colors.orange;
    return Colors.red;
  }
}
