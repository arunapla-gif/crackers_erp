class AppVersionInfo {
  const AppVersionInfo({
    required this.versionCode,
    required this.versionName,
  });

  final int versionCode;
  final String versionName;

  String get label => 'v$versionName ($versionCode)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppVersionInfo &&
          runtimeType == other.runtimeType &&
          versionCode == other.versionCode &&
          versionName == other.versionName;

  @override
  int get hashCode => Object.hash(versionCode, versionName);
}

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.versionCode,
    required this.versionName,
    required this.mandatory,
    required this.releaseNotes,
    required this.downloadAvailable,
    this.downloadUrl,
  });

  final int versionCode;
  final String versionName;
  final bool mandatory;
  final String releaseNotes;
  final bool downloadAvailable;
  final String? downloadUrl;

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    final rawCode = json['versionCode'];
    final versionCode = rawCode is num
        ? rawCode.toInt()
        : int.tryParse('${rawCode ?? ''}') ?? 1;
    final rawName = (json['versionName'] ?? '1.0.0').toString().trim();
    final rawUrl = json['downloadUrl']?.toString().trim();
    final downloadAvailable = json['downloadAvailable'] == true &&
        rawUrl != null &&
        rawUrl.isNotEmpty;

    return AppUpdateInfo(
      versionCode: versionCode > 0 ? versionCode : 1,
      versionName: rawName.isEmpty ? '1.0.0' : rawName,
      mandatory: json['mandatory'] == true,
      releaseNotes: (json['releaseNotes'] ?? '').toString().trim(),
      downloadAvailable: downloadAvailable,
      downloadUrl: downloadAvailable ? rawUrl : null,
    );
  }

  bool isNewerThan(AppVersionInfo installed) {
    return downloadAvailable &&
        downloadUrl != null &&
        downloadUrl!.isNotEmpty &&
        versionCode > installed.versionCode;
  }

  String get label => 'v$versionName ($versionCode)';
}

class AppUpdateDownloadProgress {
  const AppUpdateDownloadProgress({
    required this.receivedBytes,
    this.totalBytes,
  });

  final int receivedBytes;
  final int? totalBytes;

  double? get fraction {
    final total = totalBytes;
    if (total == null || total <= 0) return null;
    return (receivedBytes / total).clamp(0.0, 1.0);
  }
}

enum ApkInstallResult {
  started,
  permissionRequired,
}
