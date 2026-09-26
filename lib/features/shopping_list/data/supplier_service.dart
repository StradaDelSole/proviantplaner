/// Dienst und Modell für gespeicherte Lieferanten (Slice UX-B / UX-Konzept 2.4a).
library;

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Gespeichertes Profil eines Lieferanten.
class SupplierProfile {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? marina;

  const SupplierProfile({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.marina,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'marina': marina,
      };

  factory SupplierProfile.fromJson(Map<String, dynamic> json) => SupplierProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        marina: json['marina'] as String?,
      );

  SupplierProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? marina,
  }) {
    return SupplierProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      marina: marina ?? this.marina,
    );
  }
}

/// Service zur Verwaltung gespeicherter Lieferanten über alle Törns hinweg.
class SupplierService {
  final FlutterSecureStorage _storage;
  static const _storageKey = 'saved_suppliers_json';

  // In-Memory-Cache
  List<SupplierProfile>? _cache;

  SupplierService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<List<SupplierProfile>> getSuppliers() async {
    if (_cache != null) return List.unmodifiable(_cache!);
    try {
      final jsonStr = await _storage.read(key: _storageKey);
      if (jsonStr == null || jsonStr.trim().isEmpty) {
        _cache = [];
        return [];
      }
      final list = jsonDecode(jsonStr) as List<dynamic>;
      _cache = list.map((e) => SupplierProfile.fromJson(e as Map<String, dynamic>)).toList();
      return List.unmodifiable(_cache!);
    } catch (_) {
      _cache = [];
      return [];
    }
  }

  Future<void> saveSupplier(SupplierProfile supplier) async {
    final list = (await getSuppliers()).toList();
    final idx = list.indexWhere((s) => s.id == supplier.id || s.name.toLowerCase() == supplier.name.toLowerCase());
    if (idx >= 0) {
      list[idx] = supplier;
    } else {
      list.add(supplier);
    }
    _cache = list;
    await _storage.write(key: _storageKey, value: jsonEncode(list.map((s) => s.toJson()).toList()));
  }

  Future<void> deleteSupplier(String id) async {
    final list = (await getSuppliers()).toList();
    list.removeWhere((s) => s.id == id);
    _cache = list;
    await _storage.write(key: _storageKey, value: jsonEncode(list.map((s) => s.toJson()).toList()));
  }
}

final supplierServiceProvider = Provider<SupplierService>((ref) {
  return SupplierService();
});

final savedSuppliersProvider = FutureProvider<List<SupplierProfile>>((ref) async {
  final service = ref.watch(supplierServiceProvider);
  return service.getSuppliers();
});
