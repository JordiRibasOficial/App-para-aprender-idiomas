export interface SubscriptionExportRow {
  platform: string;
  productId: string;
  status: string;
  verifiedAt: string;
  expiresAt: string | null;
  createdAt: string;
}

export interface VerificationAttemptExportRow {
  createdAt: string;
}

export interface UserDataExport {
  userId: string;
  exportedAt: string;
  subscriptions: SubscriptionExportRow[];
  verificationAttempts: VerificationAttemptExportRow[];
}
