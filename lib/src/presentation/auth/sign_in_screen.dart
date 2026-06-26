import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';

/// Sign-in gate. Offers anonymous ("guest") sign-in for a frictionless demo,
/// plus email/password. On success, [authStateProvider] emits a user and the
/// router redirect (see app_router.dart) moves on to the app automatically —
/// this screen never navigates manually.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      setState(() => _error = _friendly(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _friendly(Object e) {
    final s = e.toString();
    if (s.contains('invalid-credential') || s.contains('wrong-password')) {
      return 'Incorrect email or password.';
    }
    if (s.contains('email-already-in-use')) return 'That email is already registered.';
    if (s.contains('weak-password')) return 'Password should be at least 6 characters.';
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.read(authControllerProvider);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.show_chart, size: 56, color: context.colors.primary),
                const SizedBox(height: AppSpacing.md),
                Text('Tickr',
                    textAlign: TextAlign.center,
                    style: context.text.headlineMedium),
                Text(
                  'Paper-trade crypto, risk-free.',
                  textAlign: TextAlign.center,
                  style: context.text.bodyMedium
                      ?.copyWith(color: context.colors.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.xl),
                TextField(
                  controller: _email,
                  enabled: !_busy,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _password,
                  enabled: !_busy,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(_error!,
                      style: context.text.bodySmall
                          ?.copyWith(color: context.colors.error)),
                ],
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: _busy
                      ? null
                      : () => _run(() => _register
                          ? auth.registerWithEmail(_email.text.trim(), _password.text)
                          : auth.signInWithEmail(_email.text.trim(), _password.text)),
                  child: _busy
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_register ? 'Create account' : 'Sign in'),
                ),
                TextButton(
                  onPressed: _busy ? null : () => setState(() => _register = !_register),
                  child: Text(_register
                      ? 'Have an account? Sign in'
                      : 'New here? Create an account'),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      child: Text('or'),
                    ),
                    Expanded(child: Divider()),
                  ]),
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _run(auth.signInAnonymously),
                  icon: const Icon(Icons.person_outline),
                  label: const Text('Continue as guest'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
