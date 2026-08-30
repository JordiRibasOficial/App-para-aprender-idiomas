import { z } from "zod";

export const SaveMarketingContactInputSchema = z.object({
  email: z.string().email().max(320),
});

export type SaveMarketingContactInput = z.infer<
  typeof SaveMarketingContactInputSchema
>;
