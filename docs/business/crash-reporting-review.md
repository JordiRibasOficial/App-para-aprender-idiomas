# Monitorización de errores/crashes en producción

## Estado actual — [HECHO]

Sentry está integrado y en funcionamiento en `main` (proyecto Sentry `webapps-jk/flutter-kb`, región UE):

- `src/mobile/lib/data/sentry_config.dart` — el DSN del proyecto (no es secreto, ver el propio comentario del archivo: un DSN solo permite *enviar* eventos, no leer datos existentes).
- `src/mobile/lib/main.dart` — `SentryFlutter.init()` se ejecuta **solo en release** (`kReleaseMode`), antes de instalar los propios manejadores de `FlutterError.onError`/`PlatformDispatcher.instance.onError`. Esos manejadores encadenan con los que instala Sentry (`FlutterErrorIntegration`/`OnErrorIntegration`) en vez de sustituirlos, así que cada error llega a Sentry una sola vez a través de esa cadena — no hace falta ni es posible retirar esas integraciones (no forman parte de la API pública del paquete).
- `src/mobile/lib/error_reporting.dart` — sigue siendo el único funnel para el log local (`debugPrint`, visible con `flutter logs`/`adb logcat`/consola de Xcode); no llama a Sentry directamente, porque ya lo captura la cadena de arriba — llamarlo también desde aquí duplicaría cada evento.
- Builds de debug/profile (incluido `flutter test`, donde `kReleaseMode` siempre es `false`) nunca inicializan Sentry — el desarrollo local y los tests no contaminan el dashboard de producción.

El DSN real del proyecto ya está en `sentry_config.dart` — no queda nada pendiente aquí.

**Lo que ya existía sin ningún SDK adicional (sigue siendo cierto, complementario a Sentry):** Play Console (Android vitals) y App Store Connect ya recogen automáticamente los crashes nativos que tiran el proceso entero.

## Por qué importa para el checklist

El plan de respuesta a incidentes (`data-breach-response-plan.md`) asume que hay una forma de *enterarse* de que algo va mal en producción. Sin un canal real de errores, un fallo de seguridad que se manifieste como una excepción (p. ej. un error al verificar una compra, un fallo al aplicar el rate limiting) podría pasar completamente desapercibido hasta que un usuario se queje — el plan de respuesta nunca llegaría a activarse porque nadie sabría que hay algo que responder.

## Decisión tomada: Sentry

Evaluadas tres opciones (Sentry, Firebase Crashlytics, self-hosted Sentry OSS/GlitchTip) por coste, dónde vive el dato, y encaje con el resto del stack. Se eligió **Sentry, plan gratuito, región UE**, por dos motivos concretos: (a) SDK Flutter de primera clase (`sentry_flutter`), sin necesidad de arrastrar todo el ecosistema Firebase solo para esto; (b) permite fijar la región de almacenamiento en la UE, coherente con la decisión ya tomada de mantener Supabase en `eu-west-3`.

La cuenta y el proyecto (`webapps-jk/flutter-kb`) los creó el propio propietario — eso era la única parte que no podía hacer yo (necesita una cuenta/credenciales que solo el dueño del proyecto puede crear, igual que AdMob o las credenciales de verificación de compra). Con el proyecto creado, la integración en código quedó implementada — ver "Estado actual" arriba.

## Actualizaciones de las etiquetas de privacidad (pendiente de completar)

Añadir Sentry cambia la fila "Diagnóstico" que antes decía "Ninguno — no hay SDK de crash reporting ni analítica de terceros integrado":

- `store-listing.md` (App Privacy de Apple) — actualizada: fila "Diagnóstico" ahora declara Sentry.
- `play-console-setup-guide.md` (Data safety de Play Console) — actualizada: la fila que decía "No hay ningún SDK de analítica integrado" ahora menciona Sentry.
- **Pendiente real, no de código:** cuando envíes el cuestionario real en App Store Connect / Play Console (no solo estos documentos internos), marca la categoría de diagnóstico/crash correspondiente con Sentry como proveedor.
