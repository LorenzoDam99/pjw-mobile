import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import 'auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _username = TextEditingController();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _hidden = true;
  bool _hiddenC = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_email, _username, _first, _last, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).register(
            email: _email.text.trim(),
            username: _username.text.trim(),
            firstName: _first.text.trim(),
            lastName: _last.text.trim(),
            password: _password.text,
            confirmPassword: _confirm.text,
          );
      if (mounted) {
        context.go('/verify-otp', extra: _email.text.trim());
      }
    } catch (e) {
      setState(() => _error = e.toString().contains('ApiException')
          ? e.toString().split(': ').last
          : 'Registrazione fallita');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Crea account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Registrazione', style: eyebrowStyle()),
                const SizedBox(height: 6),
                const Text(
                  'Crea il tuo account',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: 1.1),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ti invieremo un codice OTP per verificare la tua email.',
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
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: AppTheme.destructive, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_error!,
                              style: TextStyle(
                                  color: AppTheme.destructive,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email richiesta';
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
                      return 'Email non valida';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _username,
                  decoration: const InputDecoration(labelText: 'Username'),
                  validator: (v) => (v == null || v.trim().length < 8)
                      ? 'Almeno 8 caratteri'
                      : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _first,
                        decoration: const InputDecoration(labelText: 'Nome'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Richiesto' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _last,
                        decoration: const InputDecoration(labelText: 'Cognome'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Richiesto' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: _hidden,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(_hidden ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _hidden = !_hidden),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 8)
                      ? 'Almeno 8 caratteri'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirm,
                  obscureText: _hiddenC,
                  decoration: InputDecoration(
                    labelText: 'Conferma password',
                    suffixIcon: IconButton(
                      icon: Icon(_hiddenC ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _hiddenC = !_hiddenC),
                    ),
                  ),
                  validator: (v) =>
                      (v != _password.text) ? 'Le password non coincidono' : null,
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
                      : const Text('Registrati'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
