import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int _step = 0;

  final _sectorCtrl = TextEditingController();
  final _plotCtrl   = TextEditingController();
  Map<String, dynamic>? _property;

  final _mobileCtrl = TextEditingController();
  final _otpCtrl    = TextEditingController();
  bool _otpSent     = false;
  int  _countdown   = 0;

  final _form       = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _cnicCtrl   = TextEditingController();
  final _passCtrl   = TextEditingController();
  final _pass2Ctrl  = TextEditingController();
  String _role      = 'owner';
  bool _obscure     = true;
  bool _loading     = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_sectorCtrl,_plotCtrl,_mobileCtrl,_otpCtrl,_nameCtrl,_cnicCtrl,_passCtrl,_pass2Ctrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _checkPlot() async {
    if (_sectorCtrl.text.isEmpty || _plotCtrl.text.isEmpty) {
      setState(() => _error = 'Enter sector code and plot number');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final res = await context.read<ApiService>().checkPlot(
        _sectorCtrl.text.trim().toUpperCase(), _plotCtrl.text.trim());
      setState(() { _property = res['data']['property']; _step = 1; });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Connection error. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendOtp() async {
    if (_mobileCtrl.text.trim().length < 10) {
      setState(() => _error = 'Enter a valid mobile number');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await context.read<ApiService>().sendOtp(_mobileCtrl.text.trim(), _property!['id']);
      setState(() { _otpSent = true; _countdown = 60; });
      _startCountdown();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Connection error.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _countdown--);
      return _countdown > 0;
    });
  }

  void _verifyOtp() {
    if (_otpCtrl.text.trim().length != 6) {
      setState(() => _error = 'Enter the 6-digit OTP');
      return;
    }
    setState(() { _step = 2; _error = null; });
  }

  Future<void> _register() async {
    if (!_form.currentState!.validate()) return;
    if (_passCtrl.text != _pass2Ctrl.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final res = await context.read<ApiService>().register({
        'property_id': _property!['id'],
        'mobile': _mobileCtrl.text.trim(),
        'otp_code': _otpCtrl.text.trim(),
        'name': _nameCtrl.text.trim(),
        'cnic': _cnicCtrl.text.trim(),
        'password': _passCtrl.text,
        'role': _role,
      });
      if (mounted) {
        await context.read<AuthService>().saveSession(
          res['data']['token'], res['data']['user'], res['data']['property']);
        Navigator.pushAndRemoveUntil(
          context, MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Connection error.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A5276),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Create Account'),
        leading: BackButton(onPressed: () {
          if (_step > 0) setState(() { _step--; _error = null; });
          else Navigator.pop(context);
        }),
      ),
      body: Column(children: [
        _StepIndicator(current: _step),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _step == 0 ? _buildStep1() : _step == 1 ? _buildStep2() : _buildStep3(),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildStep1() {
    return Column(key: const ValueKey(0), crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Find Your Property', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      const Text('Enter your sector and plot number', style: TextStyle(color: Colors.grey, fontSize: 13)),
      const SizedBox(height: 24),
      TextFormField(
        controller: _sectorCtrl,
        textCapitalization: TextCapitalization.characters,
        decoration: const InputDecoration(labelText: 'Sector Code', hintText: 'e.g. 1A, 2, 3'),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _plotCtrl,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Plot Number'),
      ),
      if (_error != null) _errorBox(_error!),
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: _loading ? null : _checkPlot,
        child: _loading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Find Property', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    ]);
  }

  Widget _buildStep2() {
    return Column(key: const ValueKey(1), crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Verify Mobile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      Text('Property: ${_property?['plot_no']} — ${_property?['sector_name']}',
          style: const TextStyle(color: Colors.grey, fontSize: 13)),
      const SizedBox(height: 24),
      TextFormField(
        controller: _mobileCtrl,
        keyboardType: TextInputType.phone,
        enabled: !_otpSent,
        decoration: const InputDecoration(labelText: 'Mobile Number', hintText: '03XXXXXXXXX'),
      ),
      const SizedBox(height: 12),
      if (!_otpSent)
        ElevatedButton(
          onPressed: _loading ? null : _sendOtp,
          child: _loading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Send OTP'),
        ),
      if (_otpSent) ...[  
        const SizedBox(height: 16),
        TextFormField(
          controller: _otpCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
          decoration: const InputDecoration(labelText: '6-Digit OTP'),
          style: const TextStyle(fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          if (_countdown > 0)
            Text('Resend in ${_countdown}s', style: const TextStyle(color: Colors.grey, fontSize: 12))
          else
            TextButton(onPressed: _sendOtp, child: const Text('Resend OTP')),
        ]),
      ],
      if (_error != null) _errorBox(_error!),
      if (_otpSent) ...[  
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _verifyOtp,
          child: const Text('Verify & Continue', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    ]);
  }

  Widget _buildStep3() {
    return Form(
      key: _form,
      child: Column(key: const ValueKey(2), crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Your Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        const Text('Complete your account setup', style: TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 24),
        TextFormField(
          controller: _nameCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _cnicCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(13)],
          decoration: const InputDecoration(labelText: 'CNIC (13 digits)', prefixIcon: Icon(Icons.badge_outlined)),
          validator: (v) => (v == null || v.length != 13) ? 'Enter 13-digit CNIC' : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _role,
          decoration: const InputDecoration(labelText: 'I am a', prefixIcon: Icon(Icons.home_outlined)),
          items: const [
            DropdownMenuItem(value: 'owner',  child: Text('Property Owner')),
            DropdownMenuItem(value: 'tenant', child: Text('Tenant / Resident')),
          ],
          onChanged: (v) => setState(() => _role = v!),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passCtrl,
          obscureText: _obscure,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          validator: (v) => (v == null || v.length < 8) ? 'Min 8 characters' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _pass2Ctrl,
          obscureText: _obscure,
          decoration: const InputDecoration(labelText: 'Confirm Password', prefixIcon: Icon(Icons.lock_outline)),
          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
        ),
        if (_error != null) _errorBox(_error!),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _loading ? null : _register,
          child: _loading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

  Widget _errorBox(String msg) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFFDEDEC), borderRadius: BorderRadius.circular(8)),
      child: Text(msg, style: const TextStyle(color: Color(0xFFC0392B), fontSize: 13)),
    ),
  );
}

class _StepIndicator extends StatelessWidget {
  final int current;
  const _StepIndicator({required this.current});

  @override
  Widget build(BuildContext context) {
    const labels = ['Find Plot', 'Verify OTP', 'Your Details'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 28),
      child: Row(children: List.generate(3, (i) {
        final done   = i < current;
        final active = i == current;
        return Expanded(child: Row(children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: done || active ? Colors.white : Colors.white30,
            child: done
                ? const Icon(Icons.check, size: 16, color: Color(0xFF1A5276))
                : Text('${i+1}', style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: active ? const Color(0xFF1A5276) : Colors.white54)),
          ),
          const SizedBox(width: 6),
          Flexible(child: Text(labels[i],
              style: TextStyle(color: active ? Colors.white : Colors.white60, fontSize: 11, fontWeight: FontWeight.w600))),
          if (i < 2) Expanded(child: Container(margin: const EdgeInsets.symmetric(horizontal: 6), height: 1,
              color: done ? Colors.white : Colors.white30)),
        ]));
      })),
    );
  }
}
