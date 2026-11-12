import 'package:flutter/material.dart';

import 'package:crackers_erp/core/theme/erp_theme.dart';
import 'package:crackers_erp/ui/core/adaptive_shell.dart';
import 'package:crackers_erp/ui/features/masters/views/master_shared_widgets.dart';

class MachineMasterScreen extends StatelessWidget {
  const MachineMasterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ErpScreenScaffold(
      title: 'Processing Master',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: MasterFormCard(
                title: 'Machine Master',
                accentColor: ErpTheme.productionAmber,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 36,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: ErpTheme.productionAmberSoft,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: ErpTheme.productionAmber.withValues(
                              alpha: 0.35,
                            ),
                            width: 2.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.settings_suggest_rounded,
                          size: 32,
                          color: ErpTheme.productionAmberDark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Machine Management',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: ErpTheme.slate800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 340),
                        child: const Text(
                          'Configure factory machines, maintenance schedules, and processing capacity.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: ErpTheme.slate500,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

