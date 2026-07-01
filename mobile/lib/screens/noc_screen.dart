import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class NocScreen extends StatefulWidget {
  const NocScreen({super.key});
  @override
  State<NocScreen> createState() => _NocScreenState();
}

class _NocScreenState extends State<NocScreen> {
  List _requests = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final res = await context.read<ApiService>().getNocRequests();
      if (mounted) setState(() { _requests = (res['data'] as List?) ?? []; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NOC Requests')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Request NOC'),
        onPressed: _showRequest,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _requests.isEmpty
                  ? ListView(children: const [
                      SizedBox(height: 120),
                      Center(child: Text('No NOC requests', style: TextStyle(color: Colors.grey))),
                    ])
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _requests.length,
                      itemBuilder: (_, i) => _NocTile(r: _requests[i]),
                    ),
            ),
    );
  }

  void _showRequest() {
    final purposeCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Request NOC', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('NOC is required for property sale/transfer, bank loan, or other legal purposes. '
              'All dues must be cleared before NOC is issued.',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 16),
          TextField(controller: purposeCtrl, maxLines: 3,
              decoration: const InputDecoration(labelText: 'Purpose / Reason', alignLabelWithHint: true)),
          const SizedBox(height: 16),
          ElevatedButton(
            child: const Text('Submit Request'),
            onPressed: () async {
              if (purposeCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              try {
                await context.read<ApiService>().requestNoc(purposeCtrl.text.trim());
                _load();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('NOC request submitted')));
              } on ApiException catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.message), backgroundColor: Colors.red));
              } catch (_) {}
            },
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

class _NocTile extends StatelessWidget {
  final Map<String, dynamic> r;
  const _NocTile({required this.r});

  static const _sColors = {
    'pending':  Color(0xFFE67E22),
    'approved': Color(0xFF27AE60),
    'rejected': Color(0xFFC0392B),
  };

  @override
  Widget build(BuildContext context) {
    final status = r['status'] ?? 'pending';
    final color  = _sColors[status] ?? Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(r['purpose'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 8),
          Text('Requested: ${r['created_at']?.toString().substring(0,10) ?? ''}',
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
          if (status == 'approved' && r['noc_number'] != null) ...[
            const Divider(height: 16),
            Row(children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 16),
              const SizedBox(width: 6),
              Text('NOC No: ${r['noc_number']}',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.green)),
            ]),
            if (r['valid_until'] != null)
              Text('Valid until: ${r['valid_until']}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
          if (status == 'rejected' && r['admin_remarks'] != null) ...[
            const Divider(height: 16),
            Text('Reason: ${r['admin_remarks']}',
                style: const TextStyle(color: Colors.red, fontSize: 13)),
          ],
        ]),
      ),
    );
  }
}
