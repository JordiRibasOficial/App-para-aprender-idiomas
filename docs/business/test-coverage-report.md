# Cobertura real de tests

> **Medido, no asumido.** Hasta ahora en el checklist solo habíamos confirmado que los tests pasan (105 en móvil, 36 en backend) — nunca habíamos medido qué porcentaje del código ejecutan de verdad. Objetivo de referencia: 80%.

**Fecha de medición: 19 de agosto de 2026.**

## Mobile (Flutter) — `flutter test --coverage`

**88.1% de líneas cubiertas (1329/1509)** — por encima del objetivo del 80%.

14 de los 55 archivos con código ejecutable quedan por debajo del 80% individualmente. Todos son el mismo patrón, ya documentado en el propio código con sus propios comentarios: clases que tocan un canal de plataforma real (Supabase, Google Mobile Ads, App Tracking Transparency) y que, por diseño, **no se testean directamente en host** — se testean a través de una abstracción con un fake (mismo patrón que `SupabasePremiumCourseFetcher`/`PremiumCourseFetcher`, ver `supabase_content_repository_test.dart`), y la cobertura real de esas clases concretas solo la da `integration_test/` contra un emulador/simulador real, no `flutter test`.

| Archivo | Cobertura | Por qué es el patrón esperado |
|---|---|---|
| `lib/main.dart` | 30.4% | Composition root — arranca la app entera, solo se ejercita de verdad en `integration_test/app_test.dart`. |
| `lib/data/ads/ads_consent_manager.dart`, `att_tracking_manager.dart`, `ad_unit_ids.dart` | 0% | Tocan el SDK real de Google Mobile Ads / ATT — sin canal de plataforma en tests host. |
| `lib/presentation/widgets/premium_gated_banner_ad.dart`, `presentation/providers/ads_providers.dart` | 36.8% / 14.3% | Mismo motivo — las ramas que sí se testean en host (anuncios desactivados, usuario Premium) están cubiertas; la ruta real de anuncios no. |
| `lib/data/supabase_purchase_verifier.dart`, `supabase_content_repository.dart`, `supabase_user_data_export_repository.dart`, `supabase_session.dart`, `data/supabase_config.dart` | 5.6%–45.8% | Tocan `Supabase.instance.client` real — mismo patrón que `SupabasePremiumCourseFetcher`, testeadas vía fake, no directamente. |
| `lib/data/secure_supabase_local_storage.dart` | 58.8% | Toca `flutter_secure_storage` (Keychain/EncryptedSharedPreferences reales); las ramas puramente lógicas ya están cubiertas (`secure_supabase_local_storage_test.dart`), las que requieren el canal de plataforma no. |
| `lib/presentation/providers/subscription_providers.dart`, `presentation/providers/user_data_export_providers.dart` | 63.6% / 50.0% | Construyen el repositorio real por defecto (`InAppPurchaseSubscriptionRepository`/`SupabaseUserDataExportRepository`) — la rama de test siempre inyecta un fake en su lugar. |

Ninguno de estos 14 es un hueco de calidad real — es la frontera deliberada entre lo que `flutter test` puede ejercitar y lo que necesita un dispositivo/emulador real, ya así desde el principio de esta sesión.

## Backend (Deno) — `deno coverage`

Los archivos que de verdad importan (`handler.ts`, la lógica de negocio testeada contra deps falsas) están en 94–100%:

| Función | Líneas |
|---|---|
| `verify-purchase/handler.ts` | 96.8% |
| `get-course-content/handler.ts` | 94.4% |
| `export-user-data/handler.ts` | 100% |

`index.ts` de cada función (el "composition root" que conecta con Supabase real) queda fuera de esta medición a propósito — mismo motivo que `main.dart` en móvil: es la capa de wiring, no de lógica, y no tiene sentido unit-testearla contra un backend real.

## Conclusión

**Se cumple el objetivo del 80% en ambos lados**, con margen. Los huecos que existen son la frontera arquitectónica ya documentada (canal de plataforma real / composition root), no lógica de negocio sin probar.
