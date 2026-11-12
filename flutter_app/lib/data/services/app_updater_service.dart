import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/models/app_update_info.dart';
import 'app_updater_platform_stub.dart'
    if (dart.library.io) 'app_updater_platform_io.dart';

abstract class AppUpdaterService {
  bool get isSupportedPlatform;

  Future<AppVersionInfo?> getInstalledVersion();

  Future<AppUpdateInfo?> checkForUpdate(String apiBaseUrl);

  Future<String> downloadApk(
    String downloadUrl,
    String fileName, {
    required void Function(AppUpdateDownloadProgress progress) onProgress,
  });

  Future<ApkInstallResult> installApk(String filePath);
}

class NoopAppUpdaterService implements AppUpdaterService {
  const NoopAppUpdaterService();

  @override
  bool get isSupportedPlatform => false;

  @override
  Future<AppVersionInfo?> getInstalledVersion() async => null;

  @override
  Future<AppUpdateInfo?> checkForUpdate(String apiBaseUrl) async => null;

  @override
  Future<String> downloadApk(
    String downloadUrl,
    String fileName, {
    required void Function(AppUpdateDownloadProgress progress) onProgress,
  }) {
    throw UnsupportedError('In-app APK updates are only supported on Android.');
  }

  @override
  Future<ApkInstallResult> installApk(String filePath) {
    throw UnsupportedError('In-app APK updates are only supported on Android.');
  }
}

AppUpdaterService createPlatformAppUpdaterService() =>
    createNativeAppUpdaterService();

Uri buildVersionCheckUri(String apiBaseUrl) {
  var cleaned = apiBaseUrl.trim();
  while (cleaned.endsWith('/')) {
    cleaned = cleaned.substring(0, cleaned.length - 1);
  }
  return Uri.parse('$cleaned/app/version');
}

Future<AppUpdateInfo> fetchUpdateMetadata(
  String apiBaseUrl, {
  http.Client? client,
}) async {
  final httpClient = client ?? http.Client();
  try {
    final uri = buildVersionCheckUri(apiBaseUrl);
    final response = await httpClient
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 12));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Update server returned HTTP ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid update metadata format');
    }
    return AppUpdateInfo.fromJson(decoded);
  } finally {
    if (client == null) {
      httpClient.close();
    }
  }
}
