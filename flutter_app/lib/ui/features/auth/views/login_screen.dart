import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:crackers_erp/core/config/app_config.dart';
import 'package:crackers_erp/core/theme/erp_theme.dart';
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
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: ErpTheme.productionAmberSoft,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.local_fire_department_rounded,
                                    size: 28,
                                    color: ErpTheme.productionAmber,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Crackers ERP',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: ErpTheme.slate900,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Factory Supervisor App',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: ErpTheme.slate500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: ErpTheme.slate50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: ErpTheme.slate200),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.verified_user_outlined,
                                    size: 16,
                                    color: ErpTheme.productionAmber,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Daily Production, Workers, Cash Advances & Factory Packing Orders',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: ErpTheme.slate700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
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
                                labelText: 'PIN',
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
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              onPressed: vm.isSubmitting ? null : _submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: ErpTheme.productionAmber,
                                foregroundColor: Colors.white,
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
                                vm.isSubmitting
                                    ? 'Signing In...'
                                    : 'Sign In to Factory Portal',
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
                                          ? ErpTheme.productionAmber
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
                                              ? ErpTheme.productionAmber
                                              : ErpTheme.slate500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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
