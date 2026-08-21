# Revisión consolidada de preparación para lanzamiento

Documento de referencia único que resume el trabajo de seguridad, privacidad,
cumplimiento legal y calidad realizado a lo largo de esta serie de PRs
(#5–#39 en `main`), qué queda pendiente de una decisión o acción del
propietario del proyecto, y qué se ha dejado deliberadamente en pausa hasta
que una funcionalidad concreta se active. No sustituye a los documentos
individuales en `docs/business/` — enlaza a ellos como fuente de detalle.

## Cómo leer este documento

- ✅ **Hecho** — implementado, verificado (test automático, smoke test real,
  o revisión manual documentada) y ya en `main`.
- 🔲 **Pendiente de ti** — requiere una credencial, cuenta, decisión de
  negocio o clic en un dashboard que solo el propietario del proyecto puede
  dar. Documentado con los pasos exactos.
- ⏸️ **Diferido a propósito** — el trabajo (código o texto legal) ya existe,
  pero permanece inactivo hasta que otra funcionalidad lo active.

## Backend de verificación de compras (Supabase)

✅ Las cuatro Edge Functions (`verify-purchase`, `get-course-content`,
`export-user-data`, `delete-user-data`) y todas las migraciones están
desplegadas en producción (proyecto `nfkhnrwyekqbjxwxmctu`) y verificadas
mediante un smoke test real end-to-end — ver `src/backend/README.md`
sección "Status" para el detalle completo, incluido un bug real de orden de
despliegue que se encontró y se corrigió durante ese smoke test.

🔲 **Credenciales de verificación de compras** (PR #39,
`src/backend/README.md` sección "Store credentials setup"):
- ✅ Google Play: `GOOGLE_SERVICE_ACCOUNT_JSON`/`GOOGLE_PLAY_PACKAGE_NAME`
  configurados y confirmados en producción — un smoke test real con un
  token inventado ahora devuelve `502` (la función llama de verdad a la API
  de Google Play, que rechaza el token falso), no ya el `503` de "no
  configurado".
- Apple App Store: pendiente de generar la In-App Purchase key en App Store
  Connect → Users and Access → Integrations. Pasos detallados en la misma
  sección del README.
- Hasta que iOS también esté configurado, `verify-purchase` sigue
  respondiendo `503` de forma segura (fail-closed) solo para esa
  plataforma — no bloquea el resto del lanzamiento.

✅ **Purga programada de logs de rate-limiting** (`pg_cron`): habilitado y
programado — confirmado con `select * from cron.job;` (`jobid 1`, schedule
`0 3 * * *`, `active = true`). Las cuatro tablas de rate-limit se purgan
automáticamente cada día a las 03:00; ver `src/backend/README.md` sección
"Data retention".

## Seguridad backend

✅ CORS explícitamente denegado en `verify-purchase` (#7). ✅ Cabecera
`nosniff`, sesión de Supabase cifrada en el cliente, auditoría de
dependencias (#8). ✅ Contenido Premium servido desde el backend en vez de
empaquetado en el cliente, cerrando la vía de "parchear el booleano
`isPremium`" (#9). ✅ CI/CD endurecido — permisos explícitos, Actions
fijadas por SHA completo (#11). ✅ Rate limiting en las cuatro Edge
Functions (#31). ✅ Derecho de supresión RGPD vía `delete-user-data`, con
cascada de borrado verificada con un usuario real (#32). ✅ Dependabot
extendido a `pub` (Flutter) y Deno, no solo npm (#21).

## Seguridad móvil (Flutter)

✅ Token de refresco de Supabase atado al dispositivo físico
(`KeychainAccessibility.unlocked_this_device`), cerrando la vía de
migración vía backup cifrado de iCloud/iTunes (#37). ✅ IDs de anuncios
AdMob reales solo en `kReleaseMode`; desarrollo/debug usa los IDs de prueba
oficiales de Google, cerrando un riesgo de "invalid traffic" con AdMob
(#36). ✅ Prompt de App Tracking Transparency antes de inicializar AdMob en
iOS (#16). ✅ Manejo global de errores (`error_reporting.dart`) — nota: es
un scaffold `debugPrint`-only a propósito, ver "Crash reporting" abajo.

## Privacidad y RGPD

✅ Registro de actividades de tratamiento RGPD art. 30
(`records-of-processing-activities.md`), verificación del DPA de Supabase,
auditoría de licencias de dependencias (#19). ✅ Aceptación explícita de
términos, portabilidad de datos RGPD (#29). ✅ Derecho de supresión (#32).
✅ Apple Privacy Manifest (`PrivacyInfo.xcprivacy`) declarado y
efectivamente empaquetado en el build de iOS, verificado con un build real
en CI (#33).

🔲 **Confirmación en soporte duradero** (TRLGDCU arts. 98.7/99.2,
documentado en `terms-of-service-draft.md` sección 4): el texto legal ya
reconoce que el recibo de la tienda no basta por sí solo; falta configurar
un servidor SMTP de producción para poder enviar el email de confirmación
real. Sin SMTP, esto queda como gap legal de bajo riesgo mientras el
volumen de usuarios sea bajo, pero conviene resolverlo antes de escalar.

## Legal — Términos, privacidad, DSA

✅ Cláusula de jurisdicción del ToS corregida y verificada contra las
condiciones reales de Apple/Google (#15, #36) — sin conflicto: ambas
respetan la jurisdicción del residente UE/Suiza/Noruega/Islandia. ✅ Enlace
a la plataforma ODR de la UE añadido (#34). ✅ Punto de contacto DSA
(arts. 11/12) estructurado en el ToS, publicado como buena práctica
voluntaria antes de que el art. 3.g) DSA aplique realmente (#34). ✅
Investigación del representante DSA (art. 13) completada con fuentes
primarias — sin exención de tamaño en el art. 13 en sí, pero la obligación
solo se activa si/cuando la función de subida de contenido (hoy inactiva)
se active (#35).

⏸️ **Cláusulas DMCA/LSSI de retirada de contenido** (#17): redactadas y
listas, pero dormidas — solo aplican cuando exista subida de contenido de
usuarios, que hoy no existe en la app.

⏸️ **Obligación de representante DSA (art. 13)**: por la misma razón que
arriba — se activa junto con la función de subida de contenido.

## Accesibilidad (WCAG 2.2 AA)

✅ Correcciones de contraste y tamaño de objetivo táctil (#18). ✅ Tests
automatizados de regresión con los matchers propios de `flutter_test`
(`textContrastGuideline`, `androidTapTargetGuideline`,
`iOSTapTargetGuideline`, `labeledTapTargetGuideline`) sobre la pantalla de
bienvenida y el paywall (#37) — convierten la revisión manual anterior en
un test que falla si alguien rompe la accesibilidad sin darse cuenta.

## Tiendas de aplicaciones (Play Console / App Store Connect)

✅ Cumplimiento de exportación de iOS documentado (#20). ✅ Manifiesto de
privacidad de Apple + términos mínimos de EULA (#33). ✅ Auditoría de
permisos de `AndroidManifest.xml` y `compileSdk`/`targetSdk` — sin cambios
necesarios, ya correctos (#33). ✅ Atribución de licencias OSS vía
`LicensePage` de Flutter, accesible desde una nueva pantalla "Acerca de"
(#34). ✅ Guía de "Audiencia objetivo" para Play Console — marcar solo
"18 y mayores" (#34). ✅ IDs de AdMob de prueba/producción correctamente
separados (#36).

## Testing y CI/CD

✅ CI endurecido: permisos explícitos, Actions fijadas por SHA (#11). ✅
Cobertura de tests medida y documentada (#30). ✅ SBOM generado (#30). ✅
Regresión real en el test de integración de iOS (carrera de gestos entre
dos `pump()` consecutivos) diagnosticada con un run de control en `main`
sin modificar, y corregida con `pumpAndSettle()`. ✅ Tests de accesibilidad
automatizados (#37).

## Documentación de negocio y cumplimiento normativo general

✅ Aplicabilidad de la CRA (Cyber Resilience Act) de la UE revisada — no
aplica en el estado actual del producto (#30). ✅ Guía de seguros y marca
registrada (#21). ✅ Plan de respuesta a brechas de datos y política de
divulgación de vulnerabilidades (#18). ✅ Runbook de backup/restore
(#20). ✅ Revisión de proveedores de crash reporting — comparativa
Sentry/Firebase Crashlytics/self-hosted con recomendación (Sentry, capa
gratuita), documentada en `crash-reporting-review.md` (#35).

🔲 **Elegir e implementar un proveedor de crash reporting**: decisión de
cuenta/coste/residencia de datos que solo tú puedes tomar. Hasta entonces,
`error_reporting.dart` sigue siendo un `debugPrint`-only scaffold — el plan
de respuesta a incidentes no tiene datos reales que consumir en producción.

## Checklist de acciones pendientes del propietario

| # | Acción | Dónde está documentado |
|---|--------|-------------------------|
| 1 | ~~Configurar `GOOGLE_SERVICE_ACCOUNT_JSON` / `GOOGLE_PLAY_PACKAGE_NAME` como secretos de Supabase~~ — ✅ hecho, confirmado con una llamada real a la API de Google Play | `src/backend/README.md` § Store credentials setup |
| 2 | Generar y configurar la In-App Purchase key de Apple (`APPLE_KEY_ID`, `APPLE_ISSUER_ID`, `APPLE_PRIVATE_KEY`, `APPLE_BUNDLE_ID`) | ídem |
| 3 | ~~Habilitar `pg_cron` desde el Dashboard de Supabase y ejecutar el `cron.schedule(...)` ya escrito~~ — ✅ hecho, job activo confirmado con `select * from cron.job;` | `src/backend/README.md` § Data retention |
| 4 | Elegir proveedor de crash reporting e implementarlo | `docs/business/crash-reporting-review.md` |
| 5 | Configurar SMTP de producción para el email de confirmación en soporte duradero | `docs/business/terms-of-service-draft.md` § 4 |

Ninguno de los dos puntos restantes bloquea el lanzamiento por sí solo —
cada uno falla de forma segura (fail-closed o documentado como riesgo bajo)
mientras no se resuelva.
