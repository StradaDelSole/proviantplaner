/// Sheet zur Konfiguration der Lieferdetails eines Stopps (Slice UX-B / UX-Konzept 2.4a).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:proviantplaner/features/shopping_list/data/delivery_order_service.dart';
import 'package:proviantplaner/features/shopping_list/data/supplier_service.dart';

class DeliveryConfigSheet extends ConsumerStatefulWidget {
  final int tripId;
  final int stopId;
  final String stopName;
  final DeliveryOrder? initialOrder;
  final DateTime defaultDate;

  const DeliveryConfigSheet({
    super.key,
    required this.tripId,
    required this.stopId,
    required this.stopName,
    this.initialOrder,
    required this.defaultDate,
  });

  static Future<DeliveryOrder?> show(
    BuildContext context, {
    required int tripId,
    required int stopId,
    required String stopName,
    DeliveryOrder? initialOrder,
    required DateTime defaultDate,
  }) {
    return showModalBottomSheet<DeliveryOrder>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => DeliveryConfigSheet(
        tripId: tripId,
        stopId: stopId,
        stopName: stopName,
        initialOrder: initialOrder,
        defaultDate: defaultDate,
      ),
    );
  }

  @override
  ConsumerState<DeliveryConfigSheet> createState() => _DeliveryConfigSheetState();
}

class _DeliveryConfigSheetState extends ConsumerState<DeliveryConfigSheet> {
  late bool _isDelivery;
  late TextEditingController _supplierNameCtrl;
  late TextEditingController _supplierPhoneCtrl;
  late TextEditingController _supplierEmailCtrl;
  late TextEditingController _marinaCtrl;
  late TextEditingController _berthCtrl;
  late TextEditingController _boatNameCtrl;
  late TextEditingController _contactNameCtrl;
  late TextEditingController _contactPhoneCtrl;
  late TextEditingController _notesCtrl;
  late DateTime _deliveryDateTime;
  bool _saveSupplierForFutureTrips = false;
  SupplierProfile? _selectedSupplier;

  @override
  void initState() {
    super.initState();
    final ord = widget.initialOrder;
    _isDelivery = ord?.isDelivery ?? true;
    _supplierNameCtrl = TextEditingController(text: ord?.supplier?.name ?? '');
    _supplierPhoneCtrl = TextEditingController(text: ord?.supplier?.phone ?? '');
    _supplierEmailCtrl = TextEditingController(text: ord?.supplier?.email ?? '');
    _marinaCtrl = TextEditingController(text: ord?.marina ?? ord?.supplier?.marina ?? '');
    _berthCtrl = TextEditingController(text: ord?.berth ?? '');
    _boatNameCtrl = TextEditingController(text: ord?.boatName ?? '');
    _contactNameCtrl = TextEditingController(text: ord?.contactName ?? '');
    _contactPhoneCtrl = TextEditingController(text: ord?.contactPhone ?? '');
    _notesCtrl = TextEditingController(text: ord?.notes ?? '');
    _deliveryDateTime = ord?.deliveryDateTime ?? widget.defaultDate;
    _selectedSupplier = ord?.supplier;
  }

  @override
  void dispose() {
    _supplierNameCtrl.dispose();
    _supplierPhoneCtrl.dispose();
    _supplierEmailCtrl.dispose();
    _marinaCtrl.dispose();
    _berthCtrl.dispose();
    _boatNameCtrl.dispose();
    _contactNameCtrl.dispose();
    _contactPhoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _deliveryDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deliveryDateTime),
    );
    if (pickedTime == null || !mounted) return;

    setState(() {
      _deliveryDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _save() async {
    final supplierName = _supplierNameCtrl.text.trim();
    SupplierProfile? supplier = _selectedSupplier;

    if (supplierName.isNotEmpty) {
      if (supplier == null || supplier.name != supplierName) {
        supplier = SupplierProfile(
          id: supplier?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          name: supplierName,
          phone: _supplierPhoneCtrl.text.trim().isNotEmpty ? _supplierPhoneCtrl.text.trim() : null,
          email: _supplierEmailCtrl.text.trim().isNotEmpty ? _supplierEmailCtrl.text.trim() : null,
          marina: _marinaCtrl.text.trim().isNotEmpty ? _marinaCtrl.text.trim() : null,
        );
      }
      if (_saveSupplierForFutureTrips) {
        await ref.read(supplierServiceProvider).saveSupplier(supplier);
        ref.invalidate(savedSuppliersProvider);
      }
    }

    final newOrder = (widget.initialOrder ?? DeliveryOrder(stopId: widget.stopId, tripId: widget.tripId)).copyWith(
      isDelivery: _isDelivery,
      supplier: supplier,
      deliveryDateTime: _deliveryDateTime,
      marina: _marinaCtrl.text.trim().isNotEmpty ? _marinaCtrl.text.trim() : null,
      berth: _berthCtrl.text.trim().isNotEmpty ? _berthCtrl.text.trim() : null,
      boatName: _boatNameCtrl.text.trim().isNotEmpty ? _boatNameCtrl.text.trim() : null,
      contactName: _contactNameCtrl.text.trim().isNotEmpty ? _contactNameCtrl.text.trim() : null,
      contactPhone: _contactPhoneCtrl.text.trim().isNotEmpty ? _contactPhoneCtrl.text.trim() : null,
      notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
    );

    await ref.read(deliveryOrderServiceProvider).saveOrder(newOrder);
    ref.invalidate(stopDeliveryOrderProvider(widget.stopId));

    if (mounted) {
      Navigator.of(context).pop(newOrder);
    }
  }

  @override
  Widget build(BuildContext context) {
    final savedSuppliersAsync = ref.watch(savedSuppliersProvider);
    final df = DateFormat('dd.MM.yyyy · HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text('Lieferdetails · ${widget.stopName}'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Speichern', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modus-Wahl: Selbst einkaufen vs. Liefern lassen
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  label: Text('Selbst einkaufen'),
                  icon: Icon(Icons.shopping_cart_outlined),
                ),
                ButtonSegment(
                  value: true,
                  label: Text('Liefern lassen'),
                  icon: Icon(Icons.local_shipping_outlined),
                ),
              ],
              selected: {_isDelivery},
              onSelectionChanged: (val) {
                setState(() => _isDelivery = val.first);
              },
            ),
            const SizedBox(height: 16),

            if (_isDelivery) ...[
              // Gespeicherte Lieferanten Schnellauswahl
              savedSuppliersAsync.maybeWhen(
                data: (suppliers) {
                  if (suppliers.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DropdownButtonFormField<SupplierProfile>(
                      decoration: const InputDecoration(
                        labelText: 'Gespeicherten Lieferanten wählen',
                        prefixIcon: Icon(Icons.storefront_outlined),
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedSupplier,
                      items: suppliers
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text('${s.name}${s.marina != null ? " (${s.marina})" : ""}'),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedSupplier = val;
                            _supplierNameCtrl.text = val.name;
                            if (val.phone != null) _supplierPhoneCtrl.text = val.phone!;
                            if (val.email != null) _supplierEmailCtrl.text = val.email!;
                            if (val.marina != null && _marinaCtrl.text.isEmpty) {
                              _marinaCtrl.text = val.marina!;
                            }
                          });
                        }
                      },
                    ),
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),

              TextField(
                controller: _supplierNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Lieferant / Supermarkt',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _supplierPhoneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Telefon Lieferant',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _supplierEmailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'E-Mail Lieferant',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _saveSupplierForFutureTrips,
                onChanged: (val) => setState(() => _saveSupplierForFutureTrips = val ?? false),
                title: const Text('Lieferant für spätere Törns merken'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const Divider(height: 24),

              // Liefertermin
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule_outlined),
                title: const Text('Liefertermin & Uhrzeit'),
                subtitle: Text('${df.format(_deliveryDateTime)} Uhr'),
                trailing: TextButton(
                  onPressed: _pickDateTime,
                  child: const Text('Ändern'),
                ),
              ),
              const Divider(height: 24),

              // Ort und Liegeplatz
              TextField(
                controller: _marinaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Marina / Hafen',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _berthCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Liegeplatz / Steg',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _boatNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Boot / Schiffsname',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Ansprechpartner
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _contactNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Ansprechpartner',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _contactPhoneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Telefon Ansprechpartner',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Notizen
              TextField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Hinweise für die Lieferung (z. B. Zufahrt, Kühler)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
            ],

            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: _save,
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
  }
}
