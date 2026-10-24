export const CODE_LENGTH = 6;

/** Ne garde que les chiffres, au plus 6 : gère le collage « 123 456 ». */
export function digitsOnly(text: string, max: number = CODE_LENGTH): string {
  return text.replace(/\D/g, "").slice(0, max);
}

export function isCompleteCode(code: string): boolean {
  return /^\d{6}$/.test(code);
}

export function validateCredentials(email: string, password: string): { readonly email?: string; readonly password?: string } {
  const errors: { email?: string; password?: string } = {};
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim())) errors.email = "Saisissez une adresse e-mail valide.";
  if (password.length === 0) errors.password = "Saisissez votre mot de passe.";
  return errors;
}
