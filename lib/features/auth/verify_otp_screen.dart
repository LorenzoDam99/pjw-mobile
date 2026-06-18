import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import 'auth_controller.dart';

class VerifyOtpScreen extends ConsumerStatefulWidget {
  const VerifyOtpScreen({super.key, required this.email});
  final String email;

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  final _otp = TextEditingController();
  bool _submitting = false;
  bool _success = false;
  String? _error;

  @override
  void dispose() {
    _otp.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_otp.text.length < 6) {
      setState(() => _error = 'Inserisci il codice ricevuto');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .verifyOtp(email: widget.email, otpCode: _otp.text.trim().toUpperCase());
      setState(() => _success = true);
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) context.go('/login');
    } catch (e) {
      setState(() => _error = e.toString().contains('OTP non valido')
          ? 'Codice OTP non valido'
          : 'Verifica fallita');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_success) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 64, color: AppTheme.fg),
                const SizedBox(height: 16),
                const Text('Account verificato!',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('Reindirizzamento al login...',
                    style: TextStyle(color: AppTheme.muted)),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Verifica email')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Codice OTP', style: eyebrowStyle()),
              const SizedBox(height: 6),
              const Text(
                'Verifica la tua email',
                style:
                    TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: 1.1),
              ),
              const SizedBox(height: 6),
              Text(
                'Inserisci il codice che abbiamo inviato a ${widget.email}',
                style: TextStyle(color: AppTheme.muted, fontSize: 13),
              ),
              const SizedBox(height: 24),
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.destructive.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.destructive.withOpacity(0.2)),
                  ),
                  child: Text(_error!,
                      style: TextStyle(
                          color: AppTheme.destructive,
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _otp,
                keyboardType: TextInputType.visiblePassword,
                textCapitalization: TextCapitalization.characters,
                autocorrect: false,
                enableSuggestions: false,
                maxLength: 8,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                  TextInputFormatter.withFunction((_, n) =>
                      n.copyWith(text: n.text.toUpperCase())),
                ],
                style: const TextStyle(
                    fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: 'XXXXXXXX',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Verifica OTP'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
