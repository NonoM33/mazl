// What the admin routes need from the features that store user files, without
// importing them (the dependency points inward, src/index.ts wires it).
export interface UserErasure {
  // Runs the deletion of a user. Files that belong to the user are removed only
  // after `deletion` has succeeded, and left alone when it throws.
  around<T>(userId: number, deletion: () => Promise<T>): Promise<T>;
}
