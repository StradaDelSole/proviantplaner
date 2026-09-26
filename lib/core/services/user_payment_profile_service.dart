/// Dienst zur sicheren lokalen Speicherung der Zahlungsdaten des Nutzers (FEEDBACK_R1 Punkt 10).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserPaymentProfile {
  final String name;
  final String? iban;
  final String? paypalLink;
  final String? revolutLink;

  const UserPaymentProfile({
    this.name = '',
    this.iban,
    this.paypalLink,
    this.revolutLink,
  });

  bool get hasAnyPaymentData =>
      (iban != null && iban!.isNotEmpty) ||
      (paypalLink != null && paypalLink!.isNotEmpty) ||
      (revolutLink != null && revolutLink!.isNotEmpty);
}

class UserPaymentProfileService {
  final FlutterSecureStorage _storage;

  static const _keyName = 'user_payment_name';
  static const _keyIban = 'user_payment_iban';
  static const _keyPaypal = 'user_payment_paypal';
  static const _keyRevolut = 'user_payment_revolut';

  UserPaymentProfileService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<UserPaymentProfile> loadProfile() async {
    final name = await _storage.read(key: _keyName) ?? '';
    final iban = await _storage.read(key: _keyIban);
    final paypal = await _storage.read(key: _keyPaypal);
    final revolut = await _storage.read(key: _keyRevolut);

    return UserPaymentProfile(
      name: name,
      iban: iban,
      paypalLink: paypal,
      revolutLink: revolut,
    );
  }

  Future<void> saveProfile(UserPaymentProfile profile) async {
    await _storage.write(key: _keyName, value: profile.name);
    if (profile.iban != null && profile.iban!.isNotEmpty) {
      await _storage.write(key: _keyIban, value: profile.iban);
    } else {
      await _storage.delete(key: _keyIban);
    }

    if (profile.paypalLink != null && profile.paypalLink!.isNotEmpty) {
      await _storage.write(key: _keyPaypal, value: profile.paypalLink);
    } else {
      await _storage.delete(key: _keyPaypal);
    }

    if (profile.revolutLink != null && profile.revolutLink!.isNotEmpty) {
      await _storage.write(key: _keyRevolut, value: profile.revolutLink);
    } else {
      await _storage.delete(key: _keyRevolut);
    }
  }
}

final userPaymentProfileServiceProvider = Provider<UserPaymentProfileService>((ref) {
  return UserPaymentProfileService();
});

final userPaymentProfileProvider = FutureProvider<UserPaymentProfile>((ref) async {
  final service = ref.watch(userPaymentProfileServiceProvider);
  return service.loadProfile();
});
