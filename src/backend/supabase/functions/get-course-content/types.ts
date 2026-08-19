import { z } from "zod";

// English stays bundled client-side (see AssetContentRepository in the
// mobile app) — it's free, so there's nothing to gate. Only the 3
// Premium-gated languages are served here.
export const PremiumLanguageSchema = z.enum(["pt", "fr", "ja"]);
export type PremiumLanguage = z.infer<typeof PremiumLanguageSchema>;

export const GetCourseContentInputSchema = z.object({
  targetLanguage: PremiumLanguageSchema,
});
export type GetCourseContentInput = z.infer<typeof GetCourseContentInputSchema>;
