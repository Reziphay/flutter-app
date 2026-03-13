enum EmailLinkResultStatus { success, expired, invalid, alreadyUsed }

extension EmailLinkResultStatusX on EmailLinkResultStatus {
  static EmailLinkResultStatus fromQuery(String? rawValue) {
    switch (rawValue) {
      case 'expired':
        return EmailLinkResultStatus.expired;
      case 'invalid':
        return EmailLinkResultStatus.invalid;
      case 'used':
      case 'already-used':
      case 'already_used':
      case 'conflict':
        return EmailLinkResultStatus.alreadyUsed;
      default:
        return EmailLinkResultStatus.success;
    }
  }

  static EmailLinkResultStatus fromBackendValue(String? rawValue) {
    if (rawValue == null || rawValue.trim().isEmpty) {
      return EmailLinkResultStatus.success;
    }

    final normalized = rawValue.trim().toLowerCase();
    if (normalized.contains('expired')) {
      return EmailLinkResultStatus.expired;
    }
    if (normalized.contains('invalid') || normalized.contains('failed')) {
      return EmailLinkResultStatus.invalid;
    }
    if (normalized.contains('used') || normalized.contains('already')) {
      return EmailLinkResultStatus.alreadyUsed;
    }
    return EmailLinkResultStatus.success;
  }
}
