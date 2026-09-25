/// Feste Phasen eines Segeltörns gemäß PRD.
library;

/// Törnphasen: plan, shopping, storage, underway, conclusion.
enum TripPhase {
  plan('plan'),
  shopping('shopping'),
  storage('storage'),
  underway('underway'),
  conclusion('conclusion');

  final String rawValue;
  const TripPhase(this.rawValue);

  static TripPhase fromString(String val) {
    for (final p in values) {
      if (p.rawValue == val) return p;
    }
    throw FormatException('Unbekannte TripPhase: "$val"');
  }
}
