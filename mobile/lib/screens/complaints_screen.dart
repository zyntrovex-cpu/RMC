import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});
  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  List _complaints = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final res = await context.read<ApiService>().getComplaints();
      if (mounted) setState(() { _complaints = (res['data'] as List?) ?? []; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Complaints')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New Complaint'),
        onPressed: _showNewComplaint,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _complaints.isEmpty
                  ? ListView(children: const [
                      SizedBox(height: 120),
                      Center(child: Text('No complaints filed', style: TextStyle(color: Colors.grey))),
                    ])
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _complaints.length,
                      itemBuilder: (_, i) => _ComplaintTile(c: _complaints[i]),
                    ),
            ),
    );
  }

  void _showNewComplaint() {
    final titleCtrl = TextEditingController();
    final descCtrl  = TextEditingController();
    String type = 'maintenance';
    String priority = 'medium';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, ss) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('File a Complaint', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Title / Subject')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: type,
            decoration: const InputDecoration(labelText: 'Type'),
            items: ['maintenance','water','electricity','security','garbage','noise','other']
                .map((t) => DropdownMenuItem(value: t, child: Text(t[0].toUpperCase()+t.substring(1))))
                .toList(),
            onChanged: (v) => ss(() => type = v!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: priority,
            decoration: const InputDecoration(labelText: 'Priority'),
            items: const [
              DropdownMenuItem(value: 'low',    child: Text('Low')),
              DropdownMenuItem(value: 'medium', child: Text('Medium')),
              DropdownMenuItem(value: 'high',   child: Text('High — Urgent')),
            ],
            onChanged: (v) => ss(() => priority = v!),
          ),
          const SizedBox(height: 12),
          TextField(controller: descCtrl, maxLines: 4,
              decoration: const InputDecoration(labelText: 'Description', alignLabelWithHint: true)),
          const SizedBox(height: 16),
          ElevatedButton(
            child: const Text('Submit Complaint'),
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty || descCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              try {
                await context.read<ApiService>().submitComplaint({
                  'title': titleCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                  'complaint_type': type,
                  'priority': priority,
                });
                _load();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Complaint submitted successfully')));
              } catch (_) {}
            },
          ),
          const SizedBox(height: 24),
        ])),
      )),
    );
  }
}

class _ComplaintTile extends StatelessWidget {
  final Map<String, dynamic> c;
  const _ComplaintTile({required this.c});

  static const _pColors = {'high': Colors.red, 'medium': Colors.orange, 'low': Colors.green};
  static const _sColors = {
    'open': Color(0xFFE67E22), 'in_progress': Color(0xFF2980B9),
    'resolved': Color(0xFF27AE60), 'closed': Colors.grey,
  };

  @override
  Widget build(BuildContext context) {
    final status   = c['status'] ?? 'open';
    final priority = c['priority'] ?? 'medium';
    final sColor   = _sColors[status] ?? Colors.grey;
    final pColor   = _pColors[priority] ?? Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(backgroundColor: pColor.withOpacity(0.15),
            child: Icon(Icons.report_problem_outlined, color: pColor)),
        title: Text(c['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text('${c['complaint_type']?.toString().toUpperCase() ?? ''} · ${c['created_at']?.toString().substring(0,10) ?? ''}',
            style: const TextStyle(fontSize: 12)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: sColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
          child: Text(status.replaceAll('_', ' ').toUpperCase(),
              style: TextStyle(color: sColor, fontSize: 10, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}
