class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Cache exception occurred.']);

  @override
  String toString() => 'CacheException: $message';
}

class AuthException implements Exception {
  final String message;
  const AuthException([this.message = 'Authentication exception occurred.']);

  @override
  String toString() => 'AuthException: $message';
}

class ValidationException implements Exception {
  final String message;
  const ValidationException([this.message = 'Validation exception occurred.']);

  @override
  String toString() => 'ValidationException: $message';
}
