import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import '../../domain/models/app_update_info.dart';
import 'app_updater_service.dart';

AppUpdaterService createNativeAppUpdaterService() {
  if (!Platform.isAndroid) {
    return const NoopAppUpdaterService();
  }
  return AndroidMethodChannelAppUpdaterService();
}

class AndroidMethodChannelAppUpdaterService implements AppUpdaterService {
  AndroidMethodChannelAppUpdaterService({MethodChannel? channel})
      : _channel = channel ??
            const MethodChannel('com.crackerserp.crackers_erp/updater');

  final MethodChannel _channel;

  @override
  bool get isSupportedPlatform => true;

  @override
  Future<AppVersionInfo?> getInstalledVersion() async {
    final raw = await _channel.invokeMapMethod<String, dynamic>('getAppInfo');
    if (raw == null) return null;
    final versionName = (raw['versionName'] ?? '1.0.0').toString();
    final rawCode = raw['versionCode'];
    final versionCode = rawCode is num
        ? rawCode.toInt()
        : int.tryParse('${rawCode ?? ''}') ?? 1;
    return AppVersionInfo(
      versionCode: versionCode > 0 ? versionCode : 1,
      versionName: versionName,
    );
  }

  @override
  Future<AppUpdateInfo?> checkForUpdate(String apiBaseUrl) {
    return fetchUpdateMetadata(apiBaseUrl);
  }

  @override
  Future<String> downloadApk(
    String downloadUrl,
    String fileName, {
    required void Function(AppUpdateDownloadProgress progress) onProgress,
  }) async {
    final updatesDirPath =
        await _channel.invokeMethod<String>('getUpdatesDir');
    if (updatesDirPath == null || updatesDirPath.trim().isEmpty) {
      throw Exception('Unable to access Android cache directory for updates.');
    }

    final updatesDir = Directory(updatesDirPath);
    if (!await updatesDir.exists()) {
      await updatesDir.create(recursive: true);
    }

    // Remove older cached APKs so repeated updates do not fill device storage.
    await for (final entity in updatesDir.list()) {
      if (entity is File &&
          (entity.path.endsWith('.apk') || entity.path.endsWith('.part'))) {
        try {
          await entity.delete();
        } catch (_) {}
      }
    }

    final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._+-]'), '_');
    final finalPath = '${updatesDir.path}/$safeName';
    final partFile = File('$finalPath.part');
    final finalFile = File(finalPath);

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20);
    IOSink? sink;
    try {
      final request = await client.getUrl(Uri.parse(downloadUrl));
      request.followRedirects = true;
      request.maxRedirects = 5;
      final response = await request.close().timeout(
        const Duration(minutes: 5),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'APK download failed with HTTP ${response.statusCode}',
        );
      }

      final totalBytes =
          response.contentLength > 0 ? response.contentLength : null;
      var receivedBytes = 0;
      sink = partFile.openWrite();

      await for (final chunk in response) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        onProgress(
          AppUpdateDownloadProgress(
            receivedBytes: receivedBytes,
            totalBytes: totalBytes,
          ),
        );
      }

      await sink.flush();
      await sink.close();
      sink = null;

      if (receivedBytes <= 0) {
        throw Exception('Downloaded APK file is empty.');
      }

      if (await finalFile.exists()) {
        await finalFile.delete();
      }
      await partFile.rename(finalPath);
      return finalPath;
    } catch (e) {
      await sink?.close();
      if (await partFile.exists()) {
        try {
          await partFile.delete();
        } catch (_) {}
      }
      rethrow;
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<ApkInstallResult> installApk(String filePath) async {
    final result = await _channel.invokeMethod<String>(
      'installApk',
      <String, dynamic>{'filePath': filePath},
    );
    if (result == 'PERMISSION_REQUIRED') {
      return ApkInstallResult.permissionRequired;
    }
    return ApkInstallResult.started;
  }
}
