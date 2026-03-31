import 'package:dio/dio.dart';

/// Where the error happened — used to pick appropriate copy (e.g. 401 on login vs elsewhere).
enum ErrorUxContext {
  login,
  signup,
  profile,
  kyc,
  generic,
}

/// Maps network/API failures to short, safe messages. Never exposes stack traces or raw Dio dumps.
String userFacingErrorMessage(
  Object error, {
  ErrorUxContext context = ErrorUxContext.generic,
}) {
  if (error is DioException) {
    return _fromDio(error, context);
  }

  final raw = error.toString();
  if (raw == 'Doctor profile not found') {
    return 'Your doctor profile isn\'t set up yet. Complete your profile to continue.';
  }
  final lower = raw.toLowerCase();
  if (lower.contains('socketexception') ||
      lower.contains('failed host lookup') ||
      lower.contains('network is unreachable')) {
    return 'No internet connection. Check your network and try again.';
  }

  return _fallback(context);
}

String _fromDio(DioException e, ErrorUxContext context) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'The connection timed out. Please try again.';
    case DioExceptionType.connectionError:
      return 'Couldn\'t reach the server. Check your internet connection and try again.';
    case DioExceptionType.cancel:
      return 'The request was cancelled.';
    case DioExceptionType.badCertificate:
      return 'A secure connection couldn\'t be established.';
    case DioExceptionType.unknown:
      final inner = e.error;
      if (inner != null) {
        final s = inner.toString().toLowerCase();
        if (s.contains('socketexception') ||
            s.contains('failed host lookup') ||
            s.contains('connection refused')) {
          return 'Couldn\'t reach the server. Check your internet connection and try again.';
        }
      }
      break;
    case DioExceptionType.badResponse:
      break;
  }

  final status = e.response?.statusCode;
  final serverMsg = _extractServerMessage(e.response?.data);

  if (status != null) {
    switch (status) {
      case 400:
        return _messageOrGeneric(
          serverMsg,
          'We couldn\'t process that request. Please check your information and try again.',
        );
      case 401:
        switch (context) {
          case ErrorUxContext.login:
            return 'Incorrect username or password. Please try again.';
          case ErrorUxContext.signup:
            return 'We couldn\'t verify this step. Check your details or request a new code.';
          default:
            return 'Your session has expired. Please sign in again.';
        }
      case 403:
        return 'You don\'t have permission to do that.';
      case 404:
        return context == ErrorUxContext.profile
            ? 'We couldn\'t find your profile. Try again or contact support.'
            : 'We couldn\'t find what you were looking for.';
      case 409:
        return _messageOrGeneric(
          serverMsg,
          'This conflicts with existing information. Please review and try again.',
        );
      case 422:
        return _messageOrGeneric(
          serverMsg,
          'Some information looks invalid. Please review the form and try again.',
        );
      case 429:
        return 'Too many attempts. Please wait a moment and try again.';
      case 500:
      case 502:
      case 503:
      case 504:
        return 'Our servers are having trouble right now. Please try again in a few minutes.';
      default:
        break;
    }
  }

  if (serverMsg != null && _isPresentableServerMessage(serverMsg)) {
    return serverMsg;
  }

  return _fallback(context);
}

String? _extractServerMessage(dynamic data) {
  if (data is Map) {
    final m = data['message'];
    if (m != null) return m.toString().trim();

    final err = data['error'];
    if (err is String) return err.trim();

    final errors = data['errors'];
    if (errors is Map && errors.isNotEmpty) {
      for (final v in errors.values) {
        if (v is List && v.isNotEmpty) {
          return v.first.toString().trim();
        }
        if (v is String) return v.trim();
      }
    }
  }
  return null;
}

bool _isPresentableServerMessage(String s) {
  final t = s.trim();
  if (t.isEmpty || t.length > 280) return false;
  final lower = t.toLowerCase();
  if (lower.contains('dioexception') ||
      lower.contains('stacktrace') ||
      lower.contains('exception:') ||
      lower.contains('.dart:') ||
      lower.contains('null check') ||
      lower.contains('type \'') ||
      lower.contains('is not a subtype')) {
    return false;
  }
  return true;
}

String _messageOrGeneric(String? serverMsg, String generic) {
  if (serverMsg != null && _isPresentableServerMessage(serverMsg)) {
    return serverMsg;
  }
  return generic;
}

String _fallback(ErrorUxContext context) {
  switch (context) {
    case ErrorUxContext.login:
      return 'Sign-in didn\'t work. Please try again.';
    case ErrorUxContext.signup:
      return 'We couldn\'t complete that step. Please try again.';
    case ErrorUxContext.profile:
      return 'We couldn\'t save your profile. Please try again.';
    case ErrorUxContext.kyc:
      return 'Something went wrong. Please try again.';
    case ErrorUxContext.generic:
      return 'Something went wrong. Please try again.';
  }
}
