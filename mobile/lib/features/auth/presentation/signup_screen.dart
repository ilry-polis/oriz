import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/auth_provider.dart';
import 'widgets/auth_text_field.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _generalError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _generalError = null;
    });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    var valid = true;

    if (name.isEmpty) {
      setState(() => _nameError = 'Informe seu nome');
      valid = false;
    }
    if (email.isEmpty) {
      setState(() => _emailError = 'Informe seu email');
      valid = false;
    } else if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _emailError = 'Email invalido');
      valid = false;
    }
    if (password.length < 8) {
      setState(() => _passwordError = 'Minimo 8 caracteres');
      valid = false;
    }

    return valid;
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    HapticFeedback.lightImpact();

    await ref.read(authNotifierProvider.notifier).signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _nameController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading;

    ref.listen(authNotifierProvider, (prev, next) {
      if (next is AuthError) {
        setState(() {
          _generalError = next.message.contains('already registered')
              ? 'Email ja cadastrado'
              : next.message;
        });
      }
      if (next is AuthAuthenticated) {
        context.go('/agenda');
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
        title: const Text('Criar conta'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.lg),

              if (_generalError != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.errorSoft,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    _generalError!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              AuthTextField(
                label: 'Nome completo',
                controller: _nameController,
                errorText: _nameError,
                textInputAction: TextInputAction.next,
                enabled: !isLoading,
              ),
              const SizedBox(height: AppSpacing.md),

              AuthTextField(
                label: 'Email',
                controller: _emailController,
                errorText: _emailError,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                enabled: !isLoading,
              ),
              const SizedBox(height: AppSpacing.md),

              AuthTextField(
                label: 'Senha',
                controller: _passwordController,
                errorText: _passwordError,
                obscureText: true,
                textInputAction: TextInputAction.done,
                enabled: !isLoading,
              ),
              const SizedBox(height: AppSpacing.lg),

              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primary.withAlpha(102),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accent,
                          ),
                        )
                      : Text('Criar conta',
                          style: AppTypography.bodySemibold.copyWith(
                            color: Colors.white,
                          )),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              Center(
                child: GestureDetector(
                  onTap: isLoading ? null : () => context.go('/login'),
                  child: Text(
                    'Ja tem conta? Entrar',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.neutral600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
