import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';

class VisitorPassesScreen extends StatefulWidget {
  const VisitorPassesScreen({Key? key}) : super(key: key);

  @override
  State<VisitorPassesScreen> createState() => _VisitorPassesScreenState();
}

class _VisitorPassesScreenState extends State<VisitorPassesScreen> {
  late Future<Map<String, dynamic>> _passesFuture;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _purposeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPasses();
  }

  void _loadPasses() {
    setState(() {
      _passesFuture = ApiService.instance.getVisitorPasses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final localization = context.watch<LocalizationService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(localization.t('visitor_passes')),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1A5276),
        onPressed: () => _showCreateDialog(context),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _passesFuture,
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

          final response = snapshot.data ?? {};
          final passes = (response['success'] == true && response['data'] != null)
              ? (response['data'] is List ? response['data'] as List : [response['data']])
              : [];

          if (passes.isEmpty) {
            return Center(
              child: Text(localization.t('no_data')),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: passes.length,
            itemBuilder: (context, index) {
              final pass = passes[index] as Map<String, dynamic>;

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
                        color: _getStatusColor(pass['status']),
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
                                pass['visitor_name'] ?? 'N/A',
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
                                color: _getStatusColor(pass['status']),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                (pass['status'] ?? 'PENDING')
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
                        _buildDetailRow('Phone', pass['visitor_phone'] ?? 'N/A'),
                        if (pass['purpose'] != null) ...[
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            localization.t('description'),
                            pass['purpose'].toString(),
                          ),
                        ],
                        if (pass['valid_from'] != null) ...[
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            'Valid From',
                            pass['valid_from'].toString(),
                          ),
                        ],
                        if (pass['valid_till'] != null) ...[
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            'Valid Till',
                            pass['valid_till'].toString(),
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
                'Create Visitor Pass',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Visitor Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Visitor Phone',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _purposeController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Purpose',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _submitPass(context),
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

  Future<void> _submitPass(BuildContext context) async {
    if (_nameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _purposeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    final result = await ApiService.instance.createVisitorPass({
      'visitor_name': _nameController.text,
      'visitor_phone': _phoneController.text,
      'purpose': _purposeController.text,
    });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Pass created successfully'),
        ),
      );
      _nameController.clear();
      _phoneController.clear();
      _purposeController.clear();
      _loadPasses();
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
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
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
    _nameController.dispose();
    _phoneController.dispose();
    _purposeController.dispose();
    super.dispose();
  }
}
