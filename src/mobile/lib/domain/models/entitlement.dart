enum EntitlementStatus { none, active }

/// Whether the user currently has an active subscription. Receipt
/// verification and the source-of-truth question ("active per which store")
/// land in Paso 9 — this is just the shape the UI reacts to.
class Entitlement {
  const Entitlement({
    this.status = EntitlementStatus.none,
    this.activeProductId,
  });

  final EntitlementStatus status;
  final String? activeProductId;

  bool get isActive => status == EntitlementStatus.active;
}
