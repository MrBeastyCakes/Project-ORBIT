sealed class Failure {
  final String message;
  const Failure(this.message);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache failure occurred.']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failure occurred.']);
}

class TierLimitFailure extends Failure {
  const TierLimitFailure([super.message = 'Tier limit reached.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Validation failure occurred.']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Resource not found.']);
}
