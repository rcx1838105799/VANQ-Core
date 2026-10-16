import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/vanq/vanq_api.dart';

/// Sign-in page for the VANQ Core airport account.
class VanqLoginView extends ConsumerStatefulWidget {
  const VanqLoginView({super.key});

  @override
  ConsumerState<VanqLoginView> createState() => _VanqLoginViewState();
}

class _VanqLoginViewState extends ConsumerState<VanqLoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final appLocalizations = context.appLocalizations;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await ref
          .read(vanqAccountProvider.notifier)
          .signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );
      final account = ref.read(vanqAccountProvider).value;
      if (account == null) {
        // The provider records the error in its state; surface it here.
        final error = ref.read(vanqAccountProvider).error;
        if (error is VanqApiException) {
          throw error;
        }
        throw VanqApiException(
          appLocalizations.vanqLoginFailed(compactError(error ?? '')),
        );
      }
      await _importSubscription(account);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on VanqApiException catch (error) {
      setState(() => _error = error.message);
    } catch (error) {
      setState(
        () => _error = appLocalizations.vanqLoginFailed(compactError(error)),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Imports the panel subscription URL as a profile, once per URL.
  Future<void> _importSubscription(dynamic account) async {
    final url = account.info.subscribeUrl as String?;
    if (url == null || url.isEmpty) return;
    final profiles = ref.read(profilesProvider);
    if (profiles.any((profile) => profile.url == url)) return;
    try {
      await ref
          .read(profilesActionProvider.notifier)
          .addProfileFromLink(url, label: 'VANQ Core');
    } catch (error) {
      commonPrint.log(
        'vanq subscription auto-import failed: ${compactError(error)}',
        logLevel: LogLevel.warning,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final textTheme = context.textTheme;
    return CommonScaffold(
      title: appLocalizations.vanqLogin,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(
          24,
        ).copyWith(top: context.contentTopPadding + 8),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C5CE7), Color(0xFFFD79A8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: AppShape.all(AppCorner.fit(96)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Image.asset(
                      'assets/images/vanq-logo-anime.webp',
                      width: 76,
                      height: 76,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'VANQ Core',
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                appLocalizations.vanqLoginSubtitle,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: InputDecoration(labelText: appLocalizations.email),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return appLocalizations.vanqEmailRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SecretTextFormField(
                controller: _passwordController,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _signIn(),
                decoration: InputDecoration(
                  labelText: appLocalizations.password,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return appLocalizations.vanqPasswordRequired;
                  }
                  return null;
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _GradientButton(
                onPressed: _isLoading ? null : _signIn,
                label: _isLoading
                    ? appLocalizations.vanqLoggingIn
                    : appLocalizations.vanqLogin,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;

  const _GradientButton({required this.onPressed, required this.label});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.6 : 1,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C5CE7), Color(0xFFFD79A8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: AppShape.all(AppCorner.lg),
        ),
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            foregroundColor: Colors.white,
            shape: AppShape.all(AppCorner.lg),
          ),
          child: Text(
            label,
            style: context.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
