import 'package:crackers_erp/core/theme/erp_theme.dart';
import 'package:crackers_erp/data/services/app_updater_service.dart';
import 'package:crackers_erp/domain/models/app_update_info.dart';
import 'package:crackers_erp/ui/core/app_update_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAppUpdaterService implements AppUpdaterService {
  _FakeAppUpdaterService({
    this.installed = const AppVersionInfo(versionCode: 2, versionName: '1.0.1'),
    this.remoteUpdate,
    this.installResult = ApkInstallResult.started,
  });

  final AppVersionInfo installed;
  AppUpdateInfo? remoteUpdate;
  ApkInstallResult installResult;

  int checkCount = 0;
  int downloadCount = 0;
  int installCount = 0;

  @override
  bool get isSupportedPlatform => true;

  @override
  Future<AppVersionInfo?> getInstalledVersion() async => installed;

  @override
  Future<AppUpdateInfo?> checkForUpdate(String apiBaseUrl) async {
    checkCount += 1;
    return remoteUpdate;
  }

  @override
  Future<String> downloadApk(
    String downloadUrl,
    String fileName, {
    required void Function(AppUpdateDownloadProgress progress) onProgress,
  }) async {
    downloadCount += 1;
    onProgress(
      const AppUpdateDownloadProgress(
        receivedBytes: 10 * 1024 * 1024,
        totalBytes: 20 * 1024 * 1024,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    onProgress(
      const AppUpdateDownloadProgress(
        receivedBytes: 20 * 1024 * 1024,
        totalBytes: 20 * 1024 * 1024,
      ),
    );
    return '/cache/updates/$fileName';
  }

  @override
  Future<ApkInstallResult> installApk(String filePath) async {
    installCount += 1;
    return installResult;
  }
}

class _TestHostPage extends StatefulWidget {
  const _TestHostPage({required this.autoCheck});

  final bool autoCheck;

  @override
  State<_TestHostPage> createState() => _TestHostPageState();
}

class _TestHostPageState extends State<_TestHostPage> {
  @override
  void initState() {
    super.initState();
    if (widget.autoCheck) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        AppUpdateScope.maybeOf(context)?.maybeCheckOnStartup(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final updater = AppUpdateScope.maybeOf(context)!;
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () => updater.checkManually(context),
          child: const Text('Check Updates'),
        ),
      ),
    );
  }
}

void main() {
  test('AppUpdateInfo parses metadata and compares version codes accurately', () {
    const current = AppVersionInfo(versionCode: 2, versionName: '1.0.1');

    final newer = AppUpdateInfo.fromJson({
      'versionCode': 3,
      'versionName': '1.0.2',
      'mandatory': true,
      'releaseNotes': 'Bug fixes',
      'downloadAvailable': true,
      'downloadUrl': 'https://example.com/api/app/download',
    });
    expect(newer.isNewerThan(current), isTrue);
    expect(newer.mandatory, isTrue);

    final sameVersion = AppUpdateInfo.fromJson({
      'versionCode': 2,
      'versionName': '1.0.1',
      'downloadAvailable': true,
      'downloadUrl': 'https://example.com/api/app/download',
    });
    expect(sameVersion.isNewerThan(current), isFalse);

    final unavailable = AppUpdateInfo.fromJson({
      'versionCode': 5,
      'versionName': '2.0.0',
      'downloadAvailable': false,
      'downloadUrl': null,
    });
    expect(unavailable.isNewerThan(current), isFalse);

    expect(
      buildVersionCheckUri('https://example.com/api/').toString(),
      'https://example.com/api/app/version',
    );
  });

  testWidgets('Startup auto-check opens optional update dialog and installs', (
    WidgetTester tester,
  ) async {
    final fakeUpdater = _FakeAppUpdaterService(
      installed: const AppVersionInfo(versionCode: 2, versionName: '1.0.1'),
      remoteUpdate: const AppUpdateInfo(
        versionCode: 3,
        versionName: '1.0.2',
        mandatory: false,
        releaseNotes: 'Faster production sync',
        downloadAvailable: true,
        downloadUrl: 'https://example.com/api/app/download',
      ),
    );
    final controller = AppUpdateController(
      updaterService: fakeUpdater,
      apiBaseUrlProvider: () => 'https://example.com/api',
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      AppUpdateScope(
        controller: controller,
        child: MaterialApp(
          theme: ErpTheme.buildLightTheme(),
          home: const _TestHostPage(autoCheck: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(fakeUpdater.checkCount, 1);
    expect(find.text('Update Available'), findsOneWidget);
    expect(find.text('v1.0.1 (2)'), findsOneWidget);
    expect(find.text('v1.0.2 (3)'), findsOneWidget);
    expect(find.text('Faster production sync'), findsOneWidget);
    expect(find.text('Later'), findsOneWidget);

    await tester.tap(find.text('Update Now'));
    await tester.pumpAndSettle();

    expect(fakeUpdater.downloadCount, 1);
    expect(fakeUpdater.installCount, 1);
    expect(
      find.textContaining('APK downloaded. Tap "Install"'),
      findsOneWidget,
    );

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Update Available'), findsNothing);
  });

  testWidgets(
    'Mandatory update hides Later and supports retry after permission grant',
    (WidgetTester tester) async {
      final fakeUpdater = _FakeAppUpdaterService(
        installed: const AppVersionInfo(versionCode: 2, versionName: '1.0.1'),
        installResult: ApkInstallResult.permissionRequired,
        remoteUpdate: const AppUpdateInfo(
          versionCode: 4,
          versionName: '1.1.0',
          mandatory: true,
          releaseNotes: 'Security update',
          downloadAvailable: true,
          downloadUrl: 'https://example.com/api/app/download',
        ),
      );
      final controller = AppUpdateController(
        updaterService: fakeUpdater,
        apiBaseUrlProvider: () => 'https://example.com/api',
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        AppUpdateScope(
          controller: controller,
          child: MaterialApp(
            theme: ErpTheme.buildLightTheme(),
            home: const _TestHostPage(autoCheck: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Required App Update'), findsOneWidget);
      expect(find.text('Later'), findsNothing);

      await tester.tap(find.text('Update Now'));
      await tester.pumpAndSettle();

      expect(fakeUpdater.downloadCount, 1);
      expect(fakeUpdater.installCount, 1);
      expect(
        find.textContaining('Allow from this source'),
        findsOneWidget,
      );

      fakeUpdater.installResult = ApkInstallResult.started;
      await tester.tap(find.text('Install Downloaded Update'));
      await tester.pumpAndSettle();

      // Re-invokes install without re-downloading
      expect(fakeUpdater.downloadCount, 1);
      expect(fakeUpdater.installCount, 2);
      expect(
        find.textContaining('APK downloaded. Tap "Install"'),
        findsOneWidget,
      );
    },
  );

  testWidgets('Manual update check reports up-to-date SnackBar', (
    WidgetTester tester,
  ) async {
    final fakeUpdater = _FakeAppUpdaterService(
      installed: const AppVersionInfo(versionCode: 2, versionName: '1.0.1'),
      remoteUpdate: const AppUpdateInfo(
        versionCode: 2,
        versionName: '1.0.1',
        mandatory: false,
        releaseNotes: '',
        downloadAvailable: true,
        downloadUrl: 'https://example.com/api/app/download',
      ),
    );
    final controller = AppUpdateController(
      updaterService: fakeUpdater,
      apiBaseUrlProvider: () => 'https://example.com/api',
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      AppUpdateScope(
        controller: controller,
        child: MaterialApp(
          theme: ErpTheme.buildLightTheme(),
          home: const _TestHostPage(autoCheck: false),
        ),
      ),
    );

    await tester.tap(find.text('Check Updates'));
    await tester.pumpAndSettle();

    expect(find.text('App is up to date (v1.0.1 (2)).'), findsOneWidget);
  });
}
