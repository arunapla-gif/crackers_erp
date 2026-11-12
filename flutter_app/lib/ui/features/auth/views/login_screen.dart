import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:crackers_erp/core/config/app_config.dart';
import 'package:crackers_erp/core/theme/erp_theme.dart';
import 'package:crackers_erp/ui/core/app_update_dialog.dart';
import 'package:crackers_erp/ui/core/erp_status_widgets.dart';
import 'package:crackers_erp/ui/features/auth/view_models/auth_view_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({required this.viewModel, super.key});

  final AuthViewModel viewModel;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _pinController = TextEditingController();
  bool _obscurePin = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppUpdateScope.maybeOf(context)?.maybeCheckOnStartup(context);
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    await widget.viewModel.login(
      username: _usernameController.text,
      pin: _pinController.text,
    );
  }

  Future<void> _showServerConfigDialog() async {
    final controller = TextEditingController(text: widget.viewModel.apiBaseUrl);
    final updated = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Server API Endpoint'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Default uses the live Railway server. For local LAN backend testing, enter your computer IP (for example http://192.168.1.10:5000/api).',
              style: TextStyle(fontSize: 12, color: ErpTheme.slate500),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'API Base URL',
                hintText: AppConfig.defaultApiBaseUrl,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(''),
            child: const Text('Reset Default'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (updated != null) {
      await widget.viewModel.updateApiBaseUrl(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ErpTheme.slate100,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: ListenableBuilder(
                listenable: widget.viewModel,
                builder: (context, _) {
                  final vm = widget.viewModel;
                  final isCustomServer =
                      vm.apiBaseUrl != AppConfig.defaultApiBaseUrl;

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: const BorderSide(color: ErpTheme.slate200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Column(
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        ErpTheme.salesBlue,
                                        ErpTheme.salesBlueDark,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(
                                        color: ErpTheme.salesBlue
                                            .withValues(alpha: 0.25),
                                        blurRadius: 16,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'ERP',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Crackers ERP',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: ErpTheme.slate900,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Billing, Inventory, Payroll & Factory Portal',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: ErpTheme.slate500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            if (vm.errorMessage != null) ...[
                              ErpErrorBanner(
                                message: vm.errorMessage!,
                                onDismiss: vm.clearError,
                              ),
                              const SizedBox(height: 16),
                            ],
                            TextFormField(
                              controller: _usernameController,
                              enabled: !vm.isSubmitting,
                              textInputAction: TextInputAction.next,
                              autocorrect: false,
                              decoration: const InputDecoration(
                                labelText: 'Username',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Enter username';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _pinController,
                              enabled: !vm.isSubmitting,
                              obscureText: _obscurePin,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onFieldSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                labelText: 'Secure PIN',
                                prefixIcon: const Icon(Icons.pin_outlined),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePin
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePin = !_obscurePin,
                                  ),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Enter your numeric PIN';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 22),
                            FilledButton.icon(
                              onPressed: vm.isSubmitting ? null : _submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: ErpTheme.salesBlueDark,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              icon: vm.isSubmitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.login_rounded),
                              label: Text(
                                vm.isSubmitting ? 'Signing In...' : 'Sign In',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            InkWell(
                              onTap: vm.isSubmitting
                                  ? null
                                  : _showServerConfigDialog,
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 6,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.dns_outlined,
                                      size: 14,
                                      color: isCustomServer
                                          ? ErpTheme.salesBlue
                                          : ErpTheme.slate500,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        isCustomServer
                                            ? 'Custom Server: ${vm.apiBaseUrl}'
                                            : 'Server: Railway Cloud (Tap to switch)',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isCustomServer
                                              ? ErpTheme.salesBlue
                                              : ErpTheme.slate500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (AppUpdateScope.maybeOf(
                                  context,
                                )?.isSupportedPlatform ==
                                true) ...[
                              const SizedBox(height: 6),
                              ListenableBuilder(
                                listenable: AppUpdateScope.maybeOf(context)!,
                                builder: (context, _) {
                                  final updater = AppUpdateScope.maybeOf(
                                    context,
                                  )!;
                                  final ver = updater.installedVersion;
                                  return TextButton.icon(
                                    onPressed:
                                        vm.isSubmitting || updater.isChecking
                                        ? null
                                        : () => updater.checkManually(context),
                                    icon: updater.isChecking
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.system_update_rounded,
                                            size: 15,
                                          ),
                                    label: Text(
                                      ver != null
                                          ? 'App v${ver.versionName} • Check Updates'
                                          : 'Check for App Updates',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
