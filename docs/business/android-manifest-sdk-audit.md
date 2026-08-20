# Auditoría de permisos de Android y nivel de API

> Dos comprobaciones del checklist, ambas con el mismo resultado: ya cumplen, sin cambios de código necesarios.

## Permisos declarados en `AndroidManifest.xml`

Principio de mínimo privilegio: revisar que solo estén declarados los permisos realmente necesarios.

**`src/mobile/android/app/src/main/AndroidManifest.xml` no declara ningún `<uses-permission>` propio** — solo la actividad principal, el `meta-data` del App ID de AdMob y un `<queries>` para `ACTION_PROCESS_TEXT` (usado por el propio motor de Flutter, no algo que este proyecto haya añadido). Permisos como `INTERNET` o `ACCESS_NETWORK_STATE` no aparecen aquí porque los añaden automáticamente, vía manifest merge, los propios plugins que los necesitan (`google_mobile_ads`, `in_app_purchase`, `supabase_flutter`) — es el comportamiento correcto: declarar un permiso explícitamente en el manifiesto de la app cuando ya lo aporta una dependencia sería redundante, no más seguro.

**No hay ningún permiso de más** (cámara, ubicación, contactos, almacenamiento, etc.) — ninguna de las funciones de la app los necesita y ninguno aparece declarado ni heredado. Sin cambios.

## Nivel de API de Android (`compileSdk`/`targetSdk`)

Google Play exige apuntar a un nivel de API reciente para poder publicar o actualizar.

**`src/mobile/android/app/build.gradle.kts` usa `flutter.compileSdkVersion`/`flutter.targetSdkVersion`/`flutter.minSdkVersion`** — no un número fijo escrito a mano. Esto es la práctica recomendada, no una laguna: esos valores los define el propio SDK de Flutter instalado (3.44.8 en CI, una versión reciente), así que el proyecto sigue automáticamente el nivel de API que Flutter considera vigente en cada versión, sin que nadie tenga que acordarse de subir un número a mano cada año — el riesgo real (un `targetSdk` fijado hace tiempo y nunca actualizado) no existe aquí por construcción. Sin cambios.
