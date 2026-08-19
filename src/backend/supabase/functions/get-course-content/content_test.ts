import { assertEquals } from "@std/assert";
import { z } from "zod";

// Mirrors the shape src/mobile/lib/domain/models/course.dart deserializes
// into — this is the server-side half of the content-quality checks that
// used to run against these files as bundled Flutter assets (see
// content_repository_test.dart, which still covers en.json).
const ExerciseSchema = z
  .discriminatedUnion("type", [
    z.object({
      id: z.string().min(1),
      type: z.literal("multipleChoice"),
      prompt: z.string().min(1),
      correctAnswer: z.string().min(1),
      options: z.array(z.string()).min(1),
    }),
    z.object({
      id: z.string().min(1),
      type: z.literal("fillBlank"),
      prompt: z.string().min(1),
      correctAnswer: z.string().min(1),
    }),
    z.object({
      id: z.string().min(1),
      type: z.literal("matching"),
      prompt: z.string().min(1),
      pairs: z.record(z.string(), z.string()),
    }),
  ])
  .superRefine((e, ctx) => {
    if (e.type === "multipleChoice" && !e.options.includes(e.correctAnswer)) {
      ctx.addIssue({ code: z.ZodIssueCode.custom, message: "correctAnswer must be one of options" });
    }
    if (e.type === "matching" && Object.keys(e.pairs).length === 0) {
      ctx.addIssue({ code: z.ZodIssueCode.custom, message: "matching exercise has no pairs" });
    }
  });

const LessonSchema = z.object({
  id: z.string().min(1),
  title: z.string().min(1),
  exercises: z.array(ExerciseSchema).min(1),
});

const UnitSchema = z.object({
  id: z.string().min(1),
  title: z.string().min(1),
  lessons: z.array(LessonSchema).min(1),
});

const CourseSchema = z.object({
  sourceLanguage: z.string().min(1),
  targetLanguage: z.string().min(1),
  level: z.string().min(1),
  units: z.array(UnitSchema).min(5),
});

async function loadCourse(lang: string) {
  const raw = await Deno.readTextFile(new URL(`./content/${lang}.json`, import.meta.url));
  return CourseSchema.parse(JSON.parse(raw));
}

for (const lang of ["pt", "fr", "ja"] as const) {
  Deno.test(`${lang} course content is well-formed with at least 5 units`, async () => {
    const course = await loadCourse(lang);
    assertEquals(course.sourceLanguage, "es");
    assertEquals(course.targetLanguage, lang);
    assertEquals(course.level, "A1");
  });

  Deno.test(`${lang} course has no duplicate exercise ids`, async () => {
    const course = await loadCourse(lang);
    const ids = course.units.flatMap((u) => u.lessons.flatMap((l) => l.exercises.map((e) => e.id)));
    assertEquals(new Set(ids).size, ids.length, `Duplicate exercise id found in ${lang}.json`);
  });
}
