/// Dienst und Modell für Lieferbestellungen (Slice UX-B / UX-Konzept 2.4a).
library;

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:proviantplaner/features/shopping_list/data/supplier_service.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/shopping_list_models.dart';

/// Modell für eine Lieferbestellung eines Stopps.
class DeliveryOrder {
  final int stopId;
  final int tripId;
  final bool isDelivery;
  final SupplierProfile? supplier;
  final DateTime? deliveryDateTime;
  final String? marina;
  final String? berth;
  final String? boatName;
  final String? contactName;
  final String? contactPhone;
  final String? notes;
  final DateTime? orderedAt;
  final bool isDelivered;
  final int lastOrderedItemCount;

  const DeliveryOrder({
    required this.stopId,
    required this.tripId,
    this.isDelivery = true,
    this.supplier,
    this.deliveryDateTime,
    this.marina,
    this.berth,
    this.boatName,
    this.contactName,
    this.contactPhone,
    this.notes,
    this.orderedAt,
    this.isDelivered = false,
    this.lastOrderedItemCount = 0,
  });

  bool get isOrdered => orderedAt != null;
  String get formattedOrderedAt => orderedAt != null
      ? 'Bestellt am ${DateFormat('dd.MM.yyyy HH:mm').format(orderedAt!)} Uhr'
      : '';

  DeliveryOrder copyWith({
    int? stopId,
    int? tripId,
    bool? isDelivery,
    SupplierProfile? supplier,
    DateTime? deliveryDateTime,
    String? marina,
    String? berth,
    String? boatName,
    String? contactName,
    String? contactPhone,
    String? notes,
    DateTime? orderedAt,
    bool? isDelivered,
    int? lastOrderedItemCount,
  }) {
    return DeliveryOrder(
      stopId: stopId ?? this.stopId,
      tripId: tripId ?? this.tripId,
      isDelivery: isDelivery ?? this.isDelivery,
      supplier: supplier ?? this.supplier,
      deliveryDateTime: deliveryDateTime ?? this.deliveryDateTime,
      marina: marina ?? this.marina,
      berth: berth ?? this.berth,
      boatName: boatName ?? this.boatName,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      notes: notes ?? this.notes,
      orderedAt: orderedAt ?? this.orderedAt,
      isDelivered: isDelivered ?? this.isDelivered,
      lastOrderedItemCount: lastOrderedItemCount ?? this.lastOrderedItemCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'stopId': stopId,
        'tripId': tripId,
        'isDelivery': isDelivery,
        'supplier': supplier?.toJson(),
        'deliveryDateTime': deliveryDateTime?.toIso8601String(),
        'marina': marina,
        'berth': berth,
        'boatName': boatName,
        'contactName': contactName,
        'contactPhone': contactPhone,
        'notes': notes,
        'orderedAt': orderedAt?.toIso8601String(),
        'isDelivered': isDelivered,
        'lastOrderedItemCount': lastOrderedItemCount,
      };

  factory DeliveryOrder.fromJson(Map<String, dynamic> json) => DeliveryOrder(
        stopId: json['stopId'] as int,
        tripId: json['tripId'] as int,
        isDelivery: json['isDelivery'] as bool? ?? true,
        supplier: json['supplier'] != null
            ? SupplierProfile.fromJson(json['supplier'] as Map<String, dynamic>)
            : null,
        deliveryDateTime: json['deliveryDateTime'] != null
            ? DateTime.tryParse(json['deliveryDateTime'] as String)
            : null,
        marina: json['marina'] as String?,
        berth: json['berth'] as String?,
        boatName: json['boatName'] as String?,
        contactName: json['contactName'] as String?,
        contactPhone: json['contactPhone'] as String?,
        notes: json['notes'] as String?,
        orderedAt: json['orderedAt'] != null
            ? DateTime.tryParse(json['orderedAt'] as String)
            : null,
        isDelivered: json['isDelivered'] as bool? ?? false,
        lastOrderedItemCount: json['lastOrderedItemCount'] as int? ?? 0,
      );

  /// Erzeugt den formatierten Text für WhatsApp, E-Mail oder Zwischenablage.
  String formatOrderText({
    required String tripName,
    required List<ShoppingListItemView> items,
    bool isSupplement = false,
  }) {
    final buffer = StringBuffer();
    final title = isSupplement ? 'Bestellung (Nachtrag)' : 'Proviantbestellung';
    buffer.writeln('$title: $tripName');

    if (deliveryDateTime != null) {
      final df = DateFormat('dd.MM.yyyy HH:mm');
      buffer.writeln('Liefertermin: ${df.format(deliveryDateTime!)} Uhr');
    }
    if (supplier != null) {
      buffer.writeln('Lieferant: ${supplier!.name}');
    }
    if (marina != null && marina!.isNotEmpty) {
      buffer.writeln('Marina: $marina');
    }
    if (berth != null && berth!.isNotEmpty) {
      buffer.writeln('Liegeplatz: $berth');
    }
    if (boatName != null && boatName!.isNotEmpty) {
      buffer.writeln('Boot: $boatName');
    }
    if (contactName != null && contactName!.isNotEmpty) {
      final phoneStr = contactPhone != null && contactPhone!.isNotEmpty ? ' ($contactPhone)' : '';
      buffer.writeln('Ansprechpartner: $contactName$phoneStr');
    }
    if (notes != null && notes!.isNotEmpty) {
      buffer.writeln('Hinweise: $notes');
    }

    buffer.writeln();
    buffer.writeln('--- ARTIKELLISTE ---');

    // Gruppierung nach Abteilungen
    final byDept = <String, List<ShoppingListItemView>>{};
    for (final it in items) {
      byDept.putIfAbsent(it.department.displayName, () => []).add(it);
    }

    for (final entry in byDept.entries) {
      buffer.writeln('${entry.key}:');
      for (final it in entry.value) {
        final size = it.effectivePackSize;
        final sizeFormatted = (size % 1 == 0) ? size.toInt().toString() : size.toStringAsFixed(1);
        final packUnit = it.variant?.pack.unit ?? it.unit;
        buffer.writeln('  • ${it.name} · ${it.effectivePackages} × $sizeFormatted $packUnit');
      }
      buffer.writeln();
    }

    return buffer.toString().trimRight();
  }
}

/// Service zur Speicherung und Verwaltung von Lieferaufträgen.
class DeliveryOrderService {
  final FlutterSecureStorage _storage;
  static const _storageKey = 'delivery_orders_json';

  Map<int, DeliveryOrder>? _cache;

  DeliveryOrderService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<Map<int, DeliveryOrder>> _loadAll() async {
    if (_cache != null) return _cache!;
    try {
      final jsonStr = await _storage.read(key: _storageKey);
      if (jsonStr == null || jsonStr.trim().isEmpty) {
        _cache = {};
        return _cache!;
      }
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      _cache = map.map(
        (key, value) => MapEntry(
          int.parse(key),
          DeliveryOrder.fromJson(value as Map<String, dynamic>),
        ),
      );
      return _cache!;
    } catch (_) {
      _cache = {};
      return _cache!;
    }
  }

  Future<void> _persist() async {
    if (_cache == null) return;
    final map = _cache!.map((key, value) => MapEntry(key.toString(), value.toJson()));
    await _storage.write(key: _storageKey, value: jsonEncode(map));
  }

  Future<DeliveryOrder?> getOrder(int stopId) async {
    final all = await _loadAll();
    return all[stopId];
  }

  Future<Map<int, DeliveryOrder>> getOrdersForTrip(int tripId) async {
    final all = await _loadAll();
    return Map.fromEntries(all.entries.where((e) => e.value.tripId == tripId));
  }

  Future<void> saveOrder(DeliveryOrder order) async {
    final all = await _loadAll();
    all[order.stopId] = order;
    await _persist();
  }

  Future<void> markAsOrdered(int stopId, {int? itemCount}) async {
    final all = await _loadAll();
    final existing = all[stopId];
    if (existing != null) {
      all[stopId] = existing.copyWith(
        orderedAt: DateTime.now(),
        lastOrderedItemCount: itemCount ?? existing.lastOrderedItemCount,
      );
      await _persist();
    }
  }

  Future<void> markAsDelivered(int stopId) async {
    final all = await _loadAll();
    final existing = all[stopId];
    if (existing != null) {
      all[stopId] = existing.copyWith(isDelivered: true);
      await _persist();
    }
  }

  Future<void> deleteOrder(int stopId) async {
    final all = await _loadAll();
    all.remove(stopId);
    await _persist();
  }
}

final deliveryOrderServiceProvider = Provider<DeliveryOrderService>((ref) {
  return DeliveryOrderService();
});

final stopDeliveryOrderProvider = FutureProvider.family<DeliveryOrder?, int>((ref, stopId) async {
  final service = ref.watch(deliveryOrderServiceProvider);
  return service.getOrder(stopId);
});
