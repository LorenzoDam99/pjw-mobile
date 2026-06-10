import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hidden = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .login(_email.text.trim(), _password.text);
      if (mounted) context.go('/bookings');
    } catch (e) {
      setState(() => _error = 'Credenziali non valide');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.fg.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: const Icon(Icons.directions_bike, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text('CICLO',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3,
                        )),
                  ],
                ),
                const SizedBox(height: 40),
                Text('Accedi', style: eyebrowStyle()),
                const SizedBox(height: 6),
                const Text(
                  'Bentornato',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, height: 1.1),
                ),
                const SizedBox(height: 6),
                Text(
                  "Inserisci la tua email per entrare nell'app.",
                  style: TextStyle(color: AppTheme.muted, fontSize: 14),
                ),
                const SizedBox(height: 28),
                if (_error != null) ...[
                  _ErrorBox(message: _error!),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'clienti@gmail.com',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Inserisci la tua email'
                      : null,
                ),
                const SizedBox(height: 14),
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
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Inserisci la password'
                      : null,
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
                      : const Text('Accedi'),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Non hai un account?',
                        style: TextStyle(color: AppTheme.muted, fontSize: 13)),
                    TextButton(
                      onPressed: () => context.push('/register'),
                      child: const Text('Registrati'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.destructive.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.destructive.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: AppTheme.destructive, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                    color: AppTheme.destructive, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
}
