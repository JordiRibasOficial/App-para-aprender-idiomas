# Monitorización de errores/crashes en producción

## Estado actual

`src/mobile/lib/error_reporting.dart` ya centraliza **todo** error no capturado de la app (excepciones de widgets vía `FlutterError.onError`, errores async vía `PlatformDispatcher.instance.onError`, y cualquier cosa que escape de la zona raíz vía `runZonedGuarded` en `main.dart`) en un único punto de entrada, `reportError()`. Hoy esa función solo hace `debugPrint` — visible en desarrollo (`flutter logs`/`adb logcat`/consola de Xcode), pero **nada llega a ningún sitio una vez la app está en manos de un usuario real**.

Esto no es un descuido: el propio comentario del archivo ya lo deja dicho — "swap the body of this function for a real reporter's call once one is configured; every call site (this is the only one) stays the same." El enganche estaba deliberadamente preparado para conectar un proveedor real más adelante, sin tocar el resto de la app.

**Lo que sí existe hoy sin ningún SDK adicional:** Play Console (Android vitals) y App Store Connect ya recogen automáticamente los crashes nativos que tiran el proceso entero — pero no las excepciones de Dart que la app captura y sobrevive (una `Exception` no manejada dentro de un `try/catch` ausente, por ejemplo), que es exactamente lo que este funnel existe para cubrir.

## Por qué importa para el checklist

El plan de respuesta a incidentes (`data-breach-response-plan.md`) asume que hay una forma de *enterarse* de que algo va mal en producción. Sin un canal real de errores, un fallo de seguridad que se manifieste como una excepción (p. ej. un error al verificar una compra, un fallo al aplicar el rate limiting) podría pasar completamente desapercibido hasta que un usuario se queje — el plan de respuesta nunca llegaría a activarse porque nadie sabría que hay algo que responder.

## Por qué no lo he implementado directamente

A diferencia de otros huecos cerrados en esta sesión, esto no es solo "escribir código que falta": añadir un SDK de terceros implica una decisión de proveedor, coste y alcance de datos que te corresponde a ti, no a mí:

- Cambia el footprint de dependencias de la app (nueva librería nativa en Android/iOS).
- Cambia la etiqueta de privacidad ya declarada ("Diagnóstico: Ninguno — no hay SDK de crash reporting ni analítica de terceros integrado" en `store-listing.md` y el cuestionario "Data safety" de Play Console) — habría que actualizar ambas.
- Necesita credenciales/cuenta que solo tú puedes crear (mismo caso que AdMob, Play Integrity o las credenciales de verificación de compra).

## Opciones

| Proveedor | Coste | Dónde vive el dato | Notas |
|---|---|---|---|
| **Sentry** | Plan gratuito con límite mensual de eventos, de pago a partir de ahí | Configurable (SaaS de Sentry, EE. UU./UE según plan, o self-hosted) | SDK Flutter oficial (`sentry_flutter`), agnóstico de tienda — funciona igual en Android e iOS. Permite elegir región de almacenamiento en los planes de pago, relevante para mantener el dato en la UE. |
| **Firebase Crashlytics** | Gratuito | Google Cloud (EE. UU. por defecto) | Ya viene integrado si en algún momento se añade Firebase por otro motivo (p. ej. Analytics) — gratis, pero atado al ecosistema Google y a EE. UU. como región por defecto. |
| **Self-hosted (Sentry OSS, GlitchTip)** | Coste de infraestructura propio | El que tú elijas (podría ser la misma región `eu-west-3` que ya usa Supabase) | Máximo control sobre dónde vive el dato, pero es infraestructura adicional que mantener — no encaja con el perfil actual de "sin servidor propio, todo en Supabase managed". |

## Recomendación

**Sentry, plan gratuito para empezar**, por dos motivos concretos: (a) tiene SDK Flutter de primera clase (`sentry_flutter`), sin necesidad de arrastrar todo el ecosistema Firebase solo para esto; (b) los planes de pago (si algún día hace falta más volumen) permiten fijar la región de almacenamiento en la UE, coherente con la decisión ya tomada de mantener Supabase en `eu-west-3`.

## Siguiente paso

Decide el proveedor (o confirma Sentry) y crea la cuenta — en cuanto exista un DSN/clave de proyecto, la integración en código es mínima: añadir el paquete, inicializarlo en `main.dart` antes de `runApp`, y sustituir el cuerpo de `reportError()` por la llamada real (`Sentry.captureException(error, stackTrace: stack)` o equivalente). También habrá que actualizar la fila "Diagnóstico" de la tabla de `store-listing.md` y el cuestionario de Play Console/App Store Connect para declarar el nuevo SDK.
