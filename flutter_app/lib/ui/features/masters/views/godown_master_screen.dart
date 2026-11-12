import 'package:flutter/material.dart';

import 'package:crackers_erp/core/theme/erp_theme.dart';
import 'package:crackers_erp/ui/core/adaptive_shell.dart';
import 'package:crackers_erp/ui/core/erp_crud_widgets.dart';
import 'package:crackers_erp/ui/core/erp_status_widgets.dart';
import 'package:crackers_erp/ui/features/masters/view_models/godown_master_view_model.dart';
import 'package:crackers_erp/ui/features/masters/views/master_shared_widgets.dart';

class GodownMasterScreen extends StatefulWidget {
  const GodownMasterScreen({required this.viewModel, super.key});

  final GodownMasterViewModel viewModel;

  @override
  State<GodownMasterScreen> createState() => _GodownMasterScreenState();
}

class _GodownMasterScreenState extends State<GodownMasterScreen> {
  final _nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _syncControllers();
    widget.viewModel.addListener(_syncControllers);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.viewModel.initialize();
    });
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_syncControllers);
    _nameCtrl.dispose();
    super.dispose();
  }

  void _syncControllers() {
    syncMasterController(_nameCtrl, widget.viewModel.name);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        return ErpScreenScaffold(
          title: 'Godown Master',
          body: RefreshIndicator(
            onRefresh: vm.initialize,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ErpSectionHeaderBar(
                          accentColor: ErpTheme.godownTeal,
                          title: 'Godown Master',
                          subtitle:
                              'Create and maintain godown / storage location details.',
                          actions: [
                            OutlinedButton.icon(
                              onPressed: vm.isLoading ? null : vm.initialize,
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Refresh'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (vm.errorMessage != null) ...[
                          ErpErrorBanner(
                            message: vm.errorMessage!,
                            onDismiss: vm.clearMessages,
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (vm.successMessage != null) ...[
                          ErpSuccessBanner(
                            message: vm.successMessage!,
                            onDismiss: vm.clearMessages,
                          ),
                          const SizedBox(height: 12),
                        ],
                        MasterFormCard(
                          title: 'Godown Master',
                          accentColor: ErpTheme.godownTeal,
                          child: ErpResponsiveFormGrid(
                            minItemWidth: 260,
                            children: [
                              TextField(
                                controller: _nameCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Godown Name *',
                                  hintText:
                                      'Eg: Main Godown / Fancy Items Godown',
                                ),
                                onChanged: vm.setName,
                              ),
                              Wrap(
                                spacing: 10,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  if (vm.editingId != null)
                                    OutlinedButton(
                                      onPressed:
                                          vm.isSaving ? null : vm.clearForm,
                                      child: const Text('Cancel'),
                                    ),
                                  FilledButton.icon(
                                    onPressed:
                                        vm.isSaving ? null : vm.saveGodown,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: ErpTheme.godownTeal,
                                    ),
                                    icon: vm.isSaving
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.save_rounded),
                                    label: const Text('Save Godown'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        MasterFormCard(
                          title: 'Saved Godowns (${vm.godowns.length})',
                          accentColor: ErpTheme.godownTeal,
                          child: vm.godowns.isEmpty
                              ? const ErpEmptyState(
                                  icon: Icons.warehouse_outlined,
                                  title: 'No godowns added yet',
                                  subtitle:
                                      'Create storage godowns to receive purchases and transfer stock.',
                                )
                              : Column(
                                  children: vm.godowns.map((g) {
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: ErpTheme.slate50,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: ErpTheme.slate200,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.warehouse_rounded,
                                            color: ErpTheme.godownTeal,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              g.name,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800,
                                                color: ErpTheme.slate800,
                                              ),
                                            ),
                                          ),
                                          OutlinedButton(
                                            onPressed: () => vm.editGodown(g),
                                            child: const Text('Edit'),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

