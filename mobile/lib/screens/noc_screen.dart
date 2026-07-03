import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';

class NocScreen extends StatefulWidget {
  const NocScreen({Key? key}) : super(key: key);

  @override
  State<NocScreen> createState() => _NocScreenState();
}

class _NocScreenState extends State<NocScreen> {
  late Future<List<dynamic>> _nocsFuture;
  final _purposeController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNocs();
  }

  void _loadNocs() {
    setState(() {
      _nocsFuture = ApiService.instance.getNocs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final localization = context.watch<LocalizationService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(localization.t('noc')),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1A5276),
        onPressed: () => _showCreateDialog(context),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _nocsFuture,
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

          final nocs = snapshot.data ?? [];

          if (nocs.isEmpty) {
            return Center(
              child: Text(localization.t('no_data')),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: nocs.length,
            itemBuilder: (context, index) {
              final noc = nocs[index] as Map<String, dynamic>;

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
                        color: _getStatusColor(noc['status']),
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
                            Expanded(
                              child: Text(
                                noc['purpose'] ?? 'N/A',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(noc['status']),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                (noc['status'] ?? 'PENDING')
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
                        Text(
                          noc['description'] ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        if (noc['created_at'] != null) ...[
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            localization.t('date'),
                            noc['created_at'].toString(),
                          ),
                        ],
                        if (noc['reference_no'] != null) ...[
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            'Reference No',
                            noc['reference_no'].toString(),
                          ),
                        ],
                        if (noc['status'] == 'approved' &&
                            noc['document_url'] != null) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.download),
                              label: const Text('Download NOC'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
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

  void _showCreateDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Request NOC',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _purposeController,
                decoration: InputDecoration(
                  labelText: 'Purpose of NOC',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Why do you need this NOC?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _submitNoc(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A5276),
                ),
                child: const Text(
                  'Submit',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitNoc(BuildContext context) async {
    if (_purposeController.text.isEmpty ||
        _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    final result = await ApiService.instance.requestNoc({
      'purpose': _purposeController.text,
      'description': _descriptionController.text,
    });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'NOC request submitted'),
        ),
      );
      _purposeController.clear();
      _descriptionController.clear();
      _loadNocs();
    }
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
    if (statusStr == 'approved') return Colors.green;
    if (statusStr == 'pending') return Colors.orange;
    return Colors.red;
  }

  @override
  void dispose() {
    _purposeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
