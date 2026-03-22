import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/auth_provider.dart';
import 'widgets/auth_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _emailError;
  String? _passwordError;
  String? _generalError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() { _emailError = null; _passwordError = null; _generalError = null; });
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    var valid = true;
    if (email.isEmpty) { setState(() => _emailError = 'Informe seu email'); valid = false; }
    else if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) { setState(() => _emailError = 'Email invalido'); valid = false; }
    if (password.length < 8) { setState(() => _passwordError = 'Minimo 8 caracteres'); valid = false; }
    return valid;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    HapticFeedback.lightImpact();
    await ref.read(authNotifierProvider.notifier).signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading;

    ref.listen(authNotifierProvider, (prev, next) {
      if (next is AuthError) {
        setState(() {
          _generalError = next.rateLimited
              ? 'Muitas tentativas. Aguarde antes de tentar novamente.'
              : 'Email ou senha incorretos';
        });
      }
      if (next is AuthAuthenticated) { context.go('/agenda'); }
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xxl * 2),
              Text('Oriz', style: AppTypography.display.copyWith(fontSize: 40, color: AppColors.primary), textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xxl),
              if (_generalError != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(color: AppColors.errorSoft, borderRadius: BorderRadius.circular(AppRadius.md)),
                  child: Text(_generalError!, style: AppTypography.caption.copyWith(color: AppColors.error), textAlign: TextAlign.center),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              AuthTextField(label: 'Email', controller: _emailController, errorText: _emailError, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, enabled: !isLoading),
              const SizedBox(height: AppSpacing.md),
              AuthTextField(label: 'Senha', controller: _passwordController, errorText: _passwordError, obscureText: true, textInputAction: TextInputAction.done, enabled: !isLoading),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, disabledBackgroundColor: AppColors.primary.withAlpha(102), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md))),
                  child: isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent))
                      : Text('Entrar', style: AppTypography.bodySemibold.copyWith(color: Colors.white)),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(onTap: isLoading ? null : () => context.go('/signup'), child: Text('Criar conta', style: AppTypography.caption.copyWith(color: AppColors.neutral600))),
                  GestureDetector(onTap: isLoading ? null : () => context.go('/forgot-password'), child: Text('Esqueci senha', style: AppTypography.caption.copyWith(color: AppColors.neutral600))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
