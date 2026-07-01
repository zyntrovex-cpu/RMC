import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final res = await context.read<ApiService>().getProfile();
      if (mounted) setState(() { _profile = res['data']; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.user;
    final prop = auth.property;

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile'), actions: [
        IconButton(icon: const Icon(Icons.edit_outlined), onPressed: _showEdit),
      ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(padding: const EdgeInsets.all(16), children: [
                Center(child: Column(children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: const Color(0xFF1A5276),
                    child: Text((user?['name'] ?? 'R')[0].toUpperCase(),
                        style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 12),
                  Text(user?['name'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF1A5276).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text((user?['role'] ?? '').toUpperCase(),
                        style: const TextStyle(color: Color(0xFF1A5276), fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ])),
                const SizedBox(height: 24),

                if (prop != null) _sectionCard('My Property', [
                  _row(Icons.location_on_outlined, 'Plot', prop['plot_no']?.toString() ?? ''),
                  _row(Icons.map_outlined, 'Sector', prop['sector_name']?.toString() ?? ''),
                  _row(Icons.home_outlined, 'Street', prop['street_name']?.toString() ?? ''),
                  _row(Icons.square_foot_outlined, 'Size', prop['plot_size']?.toString() ?? ''),
                ]),
                const SizedBox(height: 12),

                _sectionCard('Contact Info', [
                  _row(Icons.phone_outlined, 'Mobile', user?['mobile'] ?? ''),
                  if (user?['cnic'] != null) _row(Icons.badge_outlined, 'CNIC', user!['cnic']),
                  if (user?['email'] != null) _row(Icons.email_outlined, 'Email', user!['email']),
                ]),
                const SizedBox(height: 12),

                _sectionCard('Account', [
                  _actionTile(Icons.lock_outline, 'Change Password', _showChangePassword),
                  _actionTile(Icons.logout, 'Logout', _logout, color: Colors.red),
                ]),
                const SizedBox(height: 80),
              ]),
            ),
    );
  }

  Widget _sectionCard(String title, List<Widget> children) => Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 1,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A5276))),
        const SizedBox(height: 12),
        ...children,
      ]),
    ),
  );

  Widget _row(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Icon(icon, size: 18, color: Colors.grey),
      const SizedBox(width: 10),
      SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
      Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
    ]),
  );

  Widget _actionTile(IconData icon, String label, VoidCallback onTap, {Color? color}) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Icon(icon, size: 20, color: color ?? const Color(0xFF1A5276)),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(fontSize: 14, color: color ?? Colors.black87, fontWeight: FontWeight.w500)),
        const Spacer(),
        const Icon(Icons.chevron_right, color: Colors.grey),
      ]),
    ),
  );

  void _showEdit() {
    final auth = context.read<AuthService>();
    final nameCtrl  = TextEditingController(text: auth.user?['name'] ?? '');
    final emailCtrl = TextEditingController(text: auth.user?['email'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Edit Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
          const SizedBox(height: 12),
          TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email (optional)')),
          const SizedBox(height: 16),
          ElevatedButton(
            child: const Text('Save Changes'),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final res = await context.read<ApiService>().post('/resident?action=update-profile', {
                  'name': nameCtrl.text.trim(),
                  'email': emailCtrl.text.trim(),
                });
                final newUser = Map<String, dynamic>.from(auth.user ?? {});
                newUser['name']  = nameCtrl.text.trim();
                newUser['email'] = emailCtrl.text.trim();
                await auth.saveSession(res['data']['token'] ?? '', newUser, auth.property);
                _load();
              } catch (_) {}
            },
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  void _showChangePassword() {
    final oldCtrl  = TextEditingController();
    final newCtrl  = TextEditingController();
    final new2Ctrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Change Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(controller: oldCtrl, obscureText: true,
              decoration: const InputDecoration(labelText: 'Current Password')),
          const SizedBox(height: 12),
          TextField(controller: newCtrl, obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password (min 8 chars)')),
          const SizedBox(height: 12),
          TextField(controller: new2Ctrl, obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm New Password')),
          const SizedBox(height: 16),
          ElevatedButton(
            child: const Text('Change Password'),
            onPressed: () async {
              if (newCtrl.text != new2Ctrl.text) return;
              Navigator.pop(ctx);
              try {
                await context.read<ApiService>().post('/resident-auth?action=change-password', {
                  'old_password': oldCtrl.text,
                  'new_password': newCtrl.text,
                });
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password changed successfully')));
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

  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Logout', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<AuthService>().logout();
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    }
  }
}
