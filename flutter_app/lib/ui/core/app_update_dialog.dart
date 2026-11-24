import 'package:flutter/material.dart';

import '../../core/theme/erp_theme.dart';
import '../../data/services/app_updater_service.dart';
import '../../domain/models/app_update_info.dart';

class AppUpdateController extends ChangeNotifier {
  AppUpdateController({
    required AppUpdaterService updaterService,
    required String Function() apiBaseUrlProvider,
  }) : _updaterService = updaterService,
       _apiBaseUrlProvider = apiBaseUrlProvider;

  final AppUpdaterService _updaterService;
  final String Function() _apiBaseUrlProvider;

  AppVersionInfo? _installedVersion;
  AppUpdateInfo? _availableUpdate;
  bool _hasLoadedVersion = false;
  bool _hasCheckedOnStartup = false;
  bool _isChecking = false;
  bool _isDialogOpen = false;

  bool get isSupportedPlatform => _updaterService.isSupportedPlatform;
  bool get isWebReloadUpdater => _updaterService.isWebReloadUpdater;
  AppVersionInfo? get installedVersion => _installedVersion;
  AppUpdateInfo? get availableUpdate => _availableUpdate;
  bool get hasAvailableUpdate {
    final installed = _installedVersion;
    final update = _availableUpdate;
    return installed != null && update != null && update.isNewerThan(installed);
  }

  bool get isChecking => _isChecking;

  Future<AppVersionInfo?> loadInstalledVersion() async {
    if (!isSupportedPlatform) return null;
    if (_hasLoadedVersion) return _installedVersion;
    _hasLoadedVersion = true;
    try {
      _installedVersion = await _updaterService.getInstalledVersion();
      notifyListeners();
    } catch (_) {
      // Ignore version probe errors on startup
    }
    return _installedVersion;
  }

  Future<void> maybeCheckOnStartup(BuildContext context) async {
    if (!isSupportedPlatform || _hasCheckedOnStartup || _isDialogOpen) {
      return;
    }
    _hasCheckedOnStartup = true;
    try {
      final installed = await loadInstalledVersion();
      if (installed == null) return;
      final update = await _updaterService.checkForUpdate(
        _apiBaseUrlProvider(),
      );
      if (update == null || !update.isNewerThan(installed)) {
        if (_availableUpdate != null) {
          _availableUpdate = null;
          notifyListeners();
        }
        return;
      }
      _availableUpdate = update;
      notifyListeners();
      if (!context.mounted || _isDialogOpen) return;
      await _presentUpdateDialog(
        context,
        installed: installed,
        update: update,
      );
    } catch (_) {
      // Stay silent on background startup check failures (e.g. offline mode)
    }
  }

  Future<void> openAvailableUpdateDialog(BuildContext context) async {
    final installed = _installedVersion;
    final update = _availableUpdate;
    if (installed == null || update == null || !update.isNewerThan(installed)) {
      await checkManually(context);
      return;
    }
    await _presentUpdateDialog(context, installed: installed, update: update);
  }

  Future<void> checkManually(BuildContext context) async {
    if (!isSupportedPlatform || _isChecking || _isDialogOpen) return;
    _isChecking = true;
    notifyListeners();
    try {
      final installed = await loadInstalledVersion() ??
          const AppVersionInfo(versionCode: 1, versionName: '1.0.0');
      final update = await _updaterService.checkForUpdate(
        _apiBaseUrlProvider(),
      );
      _isChecking = false;
      if (!context.mounted) {
        notifyListeners();
        return;
      }

      if (update != null && update.isNewerThan(installed)) {
        _availableUpdate = update;
        notifyListeners();
        await _presentUpdateDialog(
          context,
          installed: installed,
          update: update,
        );
      } else {
        _availableUpdate = null;
        notifyListeners();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'App is up to date (${installed.label}).',
            ),
            backgroundColor: ErpTheme.ordersEmerald,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Update check failed: $e'),
          backgroundColor: ErpTheme.dangerRose,
        ),
      );
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  Future<void> _presentUpdateDialog(
    BuildContext context, {
    required AppVersionInfo installed,
    required AppUpdateInfo update,
  }) async {
    if (_isDialogOpen) return;
    _isDialogOpen = true;
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: !update.mandatory,
        builder: (ctx) => AppUpdateDialog(
          updaterService: _updaterService,
          installedVersion: installed,
          updateInfo: update,
        ),
      );
    } finally {
      _isDialogOpen = false;
    }
  }
}

class AppUpdateScope extends InheritedNotifier<AppUpdateController> {
  const AppUpdateScope({
    required AppUpdateController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static AppUpdateController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppUpdateScope>()
        ?.notifier;
  }
}

enum _UpdateDialogStage {
  prompt,
  downloading,
  permissionRequired,
  installerStarted,
  error,
}

class AppUpdateDialog extends StatefulWidget {
  const AppUpdateDialog({
    required this.updaterService,
    required this.installedVersion,
    required this.updateInfo,
    super.key,
  });

  final AppUpdaterService updaterService;
  final AppVersionInfo installedVersion;
  final AppUpdateInfo updateInfo;

  @override
  State<AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<AppUpdateDialog> {
  _UpdateDialogStage _stage = _UpdateDialogStage.prompt;
  AppUpdateDownloadProgress _progress = const AppUpdateDownloadProgress(
    receivedBytes: 0,
  );
  String? _downloadedFilePath;
  String? _errorMessage;

  Future<void> _startDownloadAndInstall() async {
    if (widget.updaterService.isWebReloadUpdater) {
      setState(() {
        _stage = _UpdateDialogStage.downloading;
        _errorMessage = null;
      });
      try {
        await widget.updaterService.applyWebUpdate();
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _stage = _UpdateDialogStage.error;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
      return;
    }

    final downloadUrl = widget.updateInfo.downloadUrl;
    if (downloadUrl == null || downloadUrl.isEmpty) {
      setState(() {
        _stage = _UpdateDialogStage.error;
        _errorMessage = 'Download URL missing from server response.';
      });
      return;
    }

    setState(() {
      _stage = _UpdateDialogStage.downloading;
      _progress = const AppUpdateDownloadProgress(receivedBytes: 0);
      _errorMessage = null;
    });

    try {
      final fileName =
          'crackers-erp-${widget.updateInfo.versionName}+${widget.updateInfo.versionCode}.apk';
      final path = await widget.updaterService.downloadApk(
        downloadUrl,
        fileName,
        onProgress: (progress) {
          if (!mounted) return;
          setState(() {
            _progress = progress;
          });
        },
      );
      if (!mounted) return;
      _downloadedFilePath = path;
      await _triggerInstall();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = _UpdateDialogStage.error;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _triggerInstall() async {
    final path = _downloadedFilePath;
    if (path == null) {
      await _startDownloadAndInstall();
      return;
    }
    try {
      final result = await widget.updaterService.installApk(path);
      if (!mounted) return;
      setState(() {
        _stage = result == ApkInstallResult.permissionRequired
            ? _UpdateDialogStage.permissionRequired
            : _UpdateDialogStage.installerStarted;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = _UpdateDialogStage.error;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _formatBytes(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final update = widget.updateInfo;
    final canDismiss =
        !update.mandatory && _stage != _UpdateDialogStage.downloading;

    return PopScope(
      canPop: canDismiss,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ErpTheme.salesBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.system_update_rounded,
                color: ErpTheme.salesBlueDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                update.mandatory ? 'Required App Update' : 'Update Available',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: ErpTheme.slate100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ErpTheme.slate200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Installed',
                          style: TextStyle(
                            fontSize: 11,
                            color: ErpTheme.slate500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          widget.installedVersion.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: ErpTheme.slate700,
                          ),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: ErpTheme.slate500,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Latest',
                          style: TextStyle(
                            fontSize: 11,
                            color: ErpTheme.slate500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          update.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: ErpTheme.salesBlueDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (update.releaseNotes.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'What\'s New',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: ErpTheme.slate700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  update.releaseNotes,
                  style: const TextStyle(
                    fontSize: 13,
                    color: ErpTheme.slate700,
                    height: 1.4,
                  ),
                ),
              ],
              if (_stage == _UpdateDialogStage.downloading) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: widget.updaterService.isWebReloadUpdater
                      ? null
                      : _progress.fraction,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(999),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.updaterService.isWebReloadUpdater
                      ? 'Clearing cached web files and reloading to ${update.label}...'
                      : _progress.totalBytes != null && _progress.totalBytes! > 0
                      ? 'Downloading APK: ${_formatBytes(_progress.receivedBytes)} / ${_formatBytes(_progress.totalBytes!)} (${((_progress.fraction ?? 0) * 100).round()}%)'
                      : 'Downloading APK: ${_formatBytes(_progress.receivedBytes)}...',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: ErpTheme.slate700,
                  ),
                ),
              ],
              if (_stage == _UpdateDialogStage.permissionRequired) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Text(
                    'Android requires permission to install app updates. Turn on "Allow from this source" in the Settings page that just opened, then tap Install Downloaded Update below.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
              if (_stage == _UpdateDialogStage.installerStarted) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: const Text(
                    'APK downloaded. Tap "Install" (or "Update") on the Android system prompt to finish updating.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF065F46),
                    ),
                  ),
                ),
              ],
              if (_stage == _UpdateDialogStage.error &&
                  _errorMessage != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFECDD3)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ErpTheme.dangerRose,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (canDismiss)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                _stage == _UpdateDialogStage.installerStarted ? 'Close' : 'Later',
              ),
            ),
          if (_stage == _UpdateDialogStage.prompt)
            FilledButton.icon(
              onPressed: _startDownloadAndInstall,
              icon: Icon(
                widget.updaterService.isWebReloadUpdater
                    ? Icons.refresh_rounded
                    : Icons.download_rounded,
                size: 18,
              ),
              label: Text(
                widget.updaterService.isWebReloadUpdater
                    ? 'Reload & Update'
                    : 'Update Now',
              ),
            ),
          if (_stage == _UpdateDialogStage.downloading)
            FilledButton(
              onPressed: null,
              child: Text(
                widget.updaterService.isWebReloadUpdater
                    ? 'Reloading...'
                    : 'Downloading...',
              ),
            ),
          if (_stage == _UpdateDialogStage.permissionRequired ||
              _stage == _UpdateDialogStage.installerStarted)
            FilledButton.icon(
              onPressed: _triggerInstall,
              icon: const Icon(Icons.install_mobile_rounded, size: 18),
              label: const Text('Install Downloaded Update'),
            ),
          if (_stage == _UpdateDialogStage.error)
            FilledButton.icon(
              onPressed: _downloadedFilePath != null
                  ? _triggerInstall
                  : _startDownloadAndInstall,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}

/// Displays the currently running app version and highlights when a newer
/// version is available. Tapping checks for updates or opens the update dialog.
class AppVersionUpdatePill extends StatelessWidget {
  const AppVersionUpdatePill({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final controller = AppUpdateScope.maybeOf(context);
    if (controller == null || !controller.isSupportedPlatform) {
      return const SizedBox.shrink();
    }

    final hasUpdate = controller.hasAvailableUpdate;
    final available = controller.availableUpdate;
    final installed = controller.installedVersion;
    final isChecking = controller.isChecking;

    final String label;
    if (hasUpdate && available != null) {
      label = compact
          ? 'Update v${available.versionName}'
          : 'Update Available • v${available.versionName}';
    } else if (installed != null) {
      label = compact ? 'v${installed.versionName}' : installed.label;
    } else {
      label = 'Updates';
    }

    final bgColor = hasUpdate
        ? ErpTheme.ordersEmeraldSoft
        : Colors.white;
    final fgColor = hasUpdate
        ? ErpTheme.godownTealDark
        : ErpTheme.slate700;
    final borderColor = hasUpdate
        ? ErpTheme.ordersEmerald.withValues(alpha: 0.45)
        : ErpTheme.slate200;

    return Tooltip(
      message: hasUpdate && available != null
          ? 'New version ${available.label} available — click to update'
          : 'Current version ${installed?.label ?? ''} — click to check for updates',
      child: InkWell(
        key: const ValueKey('app-version-update-pill'),
        onTap: isChecking
            ? null
            : () {
                if (hasUpdate) {
                  controller.openAvailableUpdateDialog(context);
                } else {
                  controller.checkManually(context);
                }
              },
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 6 : 8,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isChecking)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: fgColor,
                  ),
                )
              else
                Icon(
                  hasUpdate
                      ? Icons.system_update_alt_rounded
                      : Icons.system_update_rounded,
                  size: compact ? 14 : 16,
                  color: hasUpdate
                      ? ErpTheme.ordersEmerald
                      : ErpTheme.salesBlueDark,
                ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: compact ? 11.5 : 12,
                  fontWeight: FontWeight.w800,
                  color: fgColor,
                ),
              ),
              if (hasUpdate) ...[
                const SizedBox(width: 5),
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: ErpTheme.ordersEmerald,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

