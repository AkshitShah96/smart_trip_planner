abstract class ItineraryError {
  final String message;
  final String? details;

  const ItineraryError(this.message, [this.details]);

  @override
  String toString() => message;
}

class NetworkError extends ItineraryError {
  const NetworkError([String? details]) : super('Network connection failed', details);
}

class AuthenticationError extends ItineraryError {
  const AuthenticationError([String? details]) : super('Invalid API key or authentication failed', details);
}

class RateLimitError extends ItineraryError {
  const RateLimitError([String? details]) : super('Rate limit exceeded. Please try again later', details);
}

class InvalidJsonError extends ItineraryError {
  const InvalidJsonError([String? details]) : super('Invalid JSON response from API', details);
}

class InvalidItineraryError extends ItineraryError {
  const InvalidItineraryError([String? details]) : super('Invalid itinerary data structure', details);
}

class ServerError extends ItineraryError {
  final int statusCode;
  
  const ServerError(this.statusCode, [String? details]) 
      : super('Server error (${statusCode})', details);
}

class UnknownError extends ItineraryError {
  const UnknownError([String? details]) : super('An unknown error occurred', details);
}

















