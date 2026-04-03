import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

bool _parseBoolFlag(String? value, {required bool fallback}) {
  if (value == null) return fallback;
  final normalized = value.trim().toLowerCase();
  if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
    return true;
  }
  if (normalized == 'false' || normalized == '0' || normalized == 'no') {
    return false;
  }
  return fallback;
}

/// Feature toggle for the end-to-end KYC flow.
/// Default is disabled until the backend and UX flow are fully ready.
final kycFeatureEnabledProvider = Provider<bool>((ref) {
  return _parseBoolFlag(dotenv.env['FEATURE_KYC_ENABLED'], fallback: false);
});
