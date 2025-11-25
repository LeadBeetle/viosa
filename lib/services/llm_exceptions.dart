/// Exception for LLM provider errors
class LLMProviderException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  LLMProviderException(this.message, {this.code, this.statusCode});

  @override
  String toString() => message;
}

/// Authentication error (invalid API key)
class LLMAuthException extends LLMProviderException {
  LLMAuthException([super.message = 'Invalid API key'])
      : super(code: 'auth_error', statusCode: 401);
}

/// Rate limit exceeded
class LLMRateLimitException extends LLMProviderException {
  LLMRateLimitException([super.message = 'Rate limit exceeded. Please try again later.'])
      : super(code: 'rate_limit', statusCode: 429);
}

/// Network/connection error
class LLMNetworkException extends LLMProviderException {
  LLMNetworkException([super.message = 'Network error. Please check your internet connection.'])
      : super(code: 'network_error');
}

/// Timeout error
class LLMTimeoutException extends LLMProviderException {
  LLMTimeoutException([super.message = 'Request timed out. Please try again.'])
      : super(code: 'timeout');
}

/// Server error
class LLMServerException extends LLMProviderException {
  LLMServerException(int statusCode, [String? message])
      : super(
          message ?? 'Server error ($statusCode). Please try again later.',
          code: 'server_error',
          statusCode: statusCode,
        );
}
