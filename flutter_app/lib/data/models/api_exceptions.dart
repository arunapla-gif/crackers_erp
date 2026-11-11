class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;

  @override
  String toString() => message;
}

class NetworkUnavailableException extends ApiException {
  const NetworkUnavailableException([
    super.message = 'Unable to reach server. Check your internet connection.',
  ]);
}

