import '../../../../core/models/couple_models.dart';
import '../../../../l10n/l10n.dart';

extension RelationshipStatusLabel on RelationshipStatus {
  String label(AppLocalizations l10n) => switch (this) {
    RelationshipStatus.single => l10n.coupleSpaceStatusSingle,
    RelationshipStatus.dating => l10n.coupleSpaceStatusDating,
    RelationshipStatus.inRelationship => l10n.coupleSpaceStatusInRelationship,
    RelationshipStatus.engaged => l10n.coupleSpaceStatusEngaged,
    RelationshipStatus.married => l10n.coupleSpaceStatusMarried,
  };
}
