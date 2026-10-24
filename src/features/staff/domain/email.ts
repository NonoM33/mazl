// Same rule as the admin console's normalizeEmail (admin.auth.ts).
export const normalizeStaffEmail = (email: string): string => email.trim().toLowerCase();
