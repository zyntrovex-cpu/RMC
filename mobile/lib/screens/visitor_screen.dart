import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class VisitorScreen extends StatefulWidget {
  const VisitorScreen({super.key});
  @override
  State<VisitorScreen> createState() => _VisitorScreenState();
}

class _VisitorScreenState extends State<VisitorScreen> {
  List _passes = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final res = await context.read<ApiService>().getVisitorPasses();
      if (mounted) setState(() { _passes = (res['data'] as List?) ?? []; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visitor Passes')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Invite Visitor'),
        onPressed: _showNewPass,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _passes.isEmpty
                  ? ListView(children: const [
                      SizedBox(height: 120),
                      Center(child: Text('No visitor passes created', style: TextStyle(color: Colors.grey))),
                    ])
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _passes.length,
                      itemBuilder: (_, i) => _PassCard(pass: _passes[i], onCancel: _load),
                    ),
            ),
    );
  }

  void _showNewPass() {
    final nameCtrl  = TextEditingController();
    final cnicCtrl  = TextEditingController();
    final vehicleCtrl = TextEditingController();
    DateTime? visitDate = DateTime.now().add(const Duration(days: 1));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, ss) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Create Visitor Pass', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Visitor Name')),
          const SizedBox(height: 12),
          TextField(controller: cnicCtrl, keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(13)],
              decoration: const InputDecoration(labelText: 'Visitor CNIC (optional)')),
          const SizedBox(height: 12),
          TextField(controller: vehicleCtrl, decoration: const InputDecoration(labelText: 'Vehicle No (optional)')),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today, color: Color(0xFF1A5276)),
            title: Text(visitDate != null
                ? '${visitDate!.day}/${visitDate!.month}/${visitDate!.year}'
                : 'Select Visit Date'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final d = await showDatePicker(context: ctx,
                  initialDate: visitDate ?? DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30)));
              if (d != null) ss(() => visitDate = d);
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            child: const Text('Generate Pass'),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              try {
                await context.read<ApiService>().createVisitorPass({
                  'visitor_name': nameCtrl.text.trim(),
                  if (cnicCtrl.text.trim().isNotEmpty) 'visitor_cnic': cnicCtrl.text.trim(),
                  if (vehicleCtrl.text.trim().isNotEmpty) 'vehicle_no': vehicleCtrl.text.trim(),
                  if (visitDate != null) 'valid_date': visitDate!.toIso8601String().substring(0, 10),
                });
                _load();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Visitor pass created')));
              } catch (_) {}
            },
          ),
          const SizedBox(height: 24),
        ])),
      )),
    );
  }
}

class _PassCard extends StatelessWidget {
  final Map<String, dynamic> pass;
  final VoidCallback onCancel;
  const _PassCard({required this.pass, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final status = pass['status'] ?? 'active';
    final isActive = status == 'active';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              backgroundColor: isActive ? const Color(0xFF1A5276).withOpacity(0.1) : Colors.grey.withOpacity(0.1),
              child: Icon(Icons.person, color: isActive ? const Color(0xFF1A5276) : Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(pass['visitor_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              if (pass['vehicle_no'] != null)
                Text('Vehicle: ${pass['vehicle_no']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ])),
            if (isActive && pass['status'] != 'used')
              TextButton(
                onPressed: () async {
                  try {
                    await context.read<ApiService>().cancelVisitorPass(pass['id']);
                    onCancel();
                  } catch (_) {}
                },
                child: const Text('Cancel', style: TextStyle(color: Colors.red)),
              ),
          ]),
          const Divider(height: 16),
          Row(children: [
            const Icon(Icons.vpn_key, size: 14, color: Color(0xFF1A5276)),
            const SizedBox(width: 6),
            const Text('Pass Code: ', style: TextStyle(color: Colors.grey, fontSize: 13)),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: pass['pass_code'] ?? ''));
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pass code copied')));
              },
              child: Text(pass['pass_code'] ?? '',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                      letterSpacing: 4, color: Color(0xFF1A5276))),
            ),
            const Icon(Icons.copy, size: 14, color: Colors.grey),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.calendar_today, size: 13, color: Colors.grey),
            const SizedBox(width: 4),
            Text('Valid: ${pass['valid_date'] ?? 'Any time'}',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(status.toUpperCase(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                      color: isActive ? Colors.green : Colors.grey)),
            ),
          ]),
        ]),
      ),
    );
  }
}
