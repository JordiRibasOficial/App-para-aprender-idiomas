# Plan: App para Aprender Idiomas — MVP móvil (Android + iOS, Flutter)

**v3 — sustituye a `mobile-mvp-android-ios.MAUI-SUPERSEDED.md` tras decidir Flutter en vez de .NET MAUI (más calidad/consistencia visual, mejor para una app gamificada, coste de reescritura aceptado explícitamente por el usuario).**

**Objetivo:** app móvil publicable en Google Play y App Store, arquitectura preparada desde el día uno para 12 idiomas de destino, lanzamiento (MVP) con inglés + 3 idiomas adicionales, progreso persistente, y suscripción (mensual / anual con descuento) real en ambas tiendas.

**Decisiones tomadas:**
- Stack: **Flutter** (Dart), un solo código para Android + iOS. El scaffold Blazor Web anterior (`src/AppParaAprenderIdiomas.Web`) queda aparte, no se reutiliza como base de la app móvil — puede servir de landing page si se decide más adelante.
- Arquitectura de contenido: agnóstica de idioma, escalable a **12 idiomas de destino** (inglés, japonés, coreano, mandarín, español, portugués, francés, holandés, italiano, alemán, catalán, ruso) sin necesidad de rehacer el motor cuando se añadan.
- **Idiomas de lanzamiento (MVP) [CONFIRMADO]: inglés + portugués + francés + japonés** (portugués/francés por cercanía lingüística y coste de contenido más bajo; japonés por crecimiento de demanda). Inglés se implementa primero para validar el esquema; los otros 3 son iteraciones del mismo Paso 3 una vez validado.
- Agentes de "legal/financiero/gestoría" (ECC): se usan para **borradores y análisis únicamente** — checklist, proyecciones estimadas, plantillas de política de privacidad/términos/contratos. No sustituyen a un profesional real; el usuario buscará asesor real antes de publicar.
- Modo: direct (sin `gh` CLI; commit + push directo a la rama `claude/obra-superpowers-marketplace-mwtr1t`, PR #1 vía GitHub MCP).
- Modelo: Sonnet 5 por defecto, Opus 5 / esfuerzo alto donde se indica (arquitectura, facturación, diseño de tests, revisión adversarial) — subir de modelo/esfuerzo bajo criterio propio, sin necesidad de pedir permiso cada vez.

**Bloqueo externo aceptado:** cuentas de Apple Developer Program (99$/año) y Google Play Console (25$ pago único) las crea y paga el usuario — no las tiene todavía, se sigue desarrollando mientras tanto. El desarrollo llega a "listo para publicar" sin depender de tenerlas ya creadas.

---

## Estado ya verificado y ejecutado en esta sesión de planificación (no repetir)

- **Flutter 3.44.8** (canal stable) instalado en `~/flutter`.
- **Android SDK nativo** en `~/android-sdk`: `platform-tools`, `platforms;android-34`, `platforms;android-36`, `build-tools;34.0.0`, `build-tools;28.0.3` (34 quedó de la exploración MAUI, 36+28.0.3 son los que Flutter exige de verdad — `flutter doctor` en verde en Android toolchain). Licencias aceptadas.
- **Proyecto Flutter real creado**: `src/mobile` (`flutter create --org com.TODO.appparaaprenderidiomas --project-name app_para_aprender_idiomas --platforms android,ios src/mobile`).
- **Build de verificación**: `flutter build apk --debug --target-platform android-arm64` lanzado — confirmar resultado real antes de dar el Paso 1 por cerrado (puede seguir corriendo en segundo plano; el primer build de Gradle tarda varios minutos en descargar dependencias, es normal, no es un fallo).
- **`ApplicationId`/bundle id son placeholder** (`com.TODO.appparaaprenderidiomas`) — confirmar el nombre real con el usuario antes del Paso de publicación.

Persistencia entre sesiones: si se abre una sesión nueva de Claude Code on the web y `~/flutter` / `~/android-sdk` no existen, hay que rehacer esta instalación (~10-15 min) — considerar añadirlo a `.claude/hooks/session-start.sh` (mismo patrón que `superpowers`/`napkin`/`markitdown`/ECC) si el ritmo de trabajo lo justifica.

---

## Grafo de dependencias

```
0 (entorno Flutter+Android SDK) [HECHO]
 └─1 (flutter create) [HECHO, pendiente confirmar build]
    └─2 (arquitectura de paquetes: state mgmt, rutas, capa de dominio)
       ├─3 (modelo de contenido multi-idioma + curso inglés completo) ──┐
       ├─4 (UI de lecciones, con mocks) ───────────────────────────────┤
       ├─5 (identidad Android: applicationId, iconos, manifest)
       ├─6 (identidad iOS: bundle id, iconos, Info.plist)
       │
       ├──────────┬─────────────────────────────────────────┘
       │     7 (persistencia/progreso local — sqflite/Hive)
       │           │
       │           ├─8 (paywall + entitlements vía `in_app_purchase`)
       │           │   └─9 (configuración de productos + verificación de recibos, ambas plataformas a la vez — `in_app_purchase` unifica la API, no hace falta separar 9a/9b como en el plan MAUI)
       │           │
       │           └─10 (onboarding/auth mínimo)
       │
14 (marketing/legal/negocio — paralelo a TODO desde el Paso 0)
       │
  11 (tests + cobertura)
       │
  12 (CI: build Android real + iOS en runner macOS)
       │
  13 (assets de tienda + submission) ⚠️ requiere cuentas de tienda del usuario
```

**Parejas paralelizables (sin colisión de archivos):** `{3, 4}` (4 con mocks hasta que 3 converja), `{5, 6}` (carpetas `android/` e `ios/` nativas, distintas entre sí — a diferencia de MAUI, Flutter ya separa esto por estructura de proyecto, no hace falta un paso "4.5" para evitar colisión), `14` en paralelo a todo el árbol técnico.

**Ventaja real de Flutter frente al plan MAUI anterior:** el paquete oficial `in_app_purchase` (mantenido por el equipo de Flutter) ya abstrae Google Play Billing y StoreKit bajo una sola API Dart — no hace falta escribir dos implementaciones completas por separado como en el plan MAUI (`GooglePlayBillingService`/`AppleStoreKitService`); se reduce a un paso de integración (9) en vez de dos.

---

## Paso 2 — Arquitectura de paquetes y estructura del proyecto [HECHO]

**Modelo:** Opus 5 / esfuerzo alto (decisión de arquitectura).
**Depende de:** Paso 1. **Bloquea:** 3, 4, 5, 6.

**Ejecutado:** `flutter_riverpod` 3.4.2, `go_router` 17.4.0, `intl` 0.20.3 añadidos vía `flutter pub add`. Carpetas `lib/domain/{models,repositories}/`, `lib/data/`, `lib/presentation/{home,router}/` creadas. `main.dart` reescrito con `ProviderScope` + `MaterialApp.router`; `HomeScreen` + `GoRouter` mínimos en su lugar del contador de demo. `test/widget_test.dart` actualizado para el nuevo home screen. `flutter analyze`: sin issues. `flutter test`: 1/1 en verde.

### Contexto autocontenido
Definir en `src/mobile/pubspec.yaml` y la estructura de carpetas (`lib/domain/`, `lib/data/`, `lib/presentation/`, `lib/l10n/` si aplica para la UI del propio app, no confundir con el contenido de los cursos) las dependencias base:
- Gestión de estado: **Riverpod** (recomendado sobre Provider/Bloc para este tamaño de proyecto — buena relación potencia/curva de aprendizaje, testeable).
- Enrutamiento: `go_router`.
- Persistencia local: **sqflite** (relacional, encaja bien con el modelo de progreso/lecciones) o **Isar**/**Hive** si se prefiere NoSQL — decidir en el Paso 7, no aquí; este paso solo deja la carpeta `lib/data/` lista.
- Localización de la propia interfaz de la app (botones, menús — no el contenido de los cursos): `flutter_localizations` + `intl`.

### Tareas
1. `pubspec.yaml`: añadir `flutter_riverpod`, `go_router`, `intl`.
2. Estructura de carpetas `lib/domain/`, `lib/data/`, `lib/presentation/`.
3. `main.dart` mínimo con `ProviderScope` + `MaterialApp.router`.

### Verificación
```bash
cd src/mobile && ~/flutter/bin/flutter analyze
```

### Criterio de salida
`flutter analyze` sin errores (warnings del template por defecto aceptables, se limpian en pasos posteriores).

### Rollback
`git checkout -- src/mobile/pubspec.yaml src/mobile/lib`.

---

## Paso 3 — Modelo de contenido multi-idioma y curso de inglés completo [HECHO — inglés; PT/FR/JA pendientes]

**Modelo:** Sonnet 5 (Opus para el diseño del esquema de datos, dado que debe soportar 12 idiomas sin rehacerse).
**Depende de:** Paso 2. **Bloquea:** 7. **Paralelizable con:** Paso 4 (mocks).

**Ejecutado:** modelos Dart inmutables en `lib/domain/models/` (`Exercise`/`ExerciseType`, `Lesson`, `CourseUnit`, `Course`, `UserProgress`) con `fromJson`/`toJson` manuales — se optó por clases inmutables escritas a mano en vez de `freezed`/`json_serializable` para evitar añadir codegen (`build_runner`) como riesgo de toolchain adicional en este entorno; se puede migrar a `freezed` más adelante sin romper la API pública. `ContentRepository` (interfaz) + `AssetContentRepository` (implementación) en `lib/data/`, carga `assets/content/courses/<targetLanguage>.json`. Curso de inglés real y completo en `assets/content/courses/en.json`: 5 unidades × 4 lecciones × 6 ejercicios = 120 ejercicios A1 CEFR genuinos (saludos, números/hora, familia/personas, comida/bebida, rutina diaria — vocabulario y gramática real, sin relleno), para un hablante de español (`sourceLanguage: "es"`). Tamaño por lección (6 ejercicios) reducido respecto al rango orientativo del plan (8-12) para priorizar velocidad de la primera iteración real; ampliable sin tocar el esquema. Test `content_repository_test.dart` verifica carga real del asset, `units.length >= 5`, y todos los campos obligatorios de cada tipo de ejercicio.

**Trío de idiomas de lanzamiento [HECHO]:** portugués, francés y japonés añadidos como iteraciones de este mismo paso, mismo esquema y misma estructura (5 unidades × 4 lecciones × 6 ejercicios) que el curso de inglés, sin cambios en el modelo de datos ni en `ContentRepository` — exactamente la promesa del diseño "agnóstico de idioma" del Paso 3.

- `assets/content/courses/pt.json` — portugués, con atención a los mismos puntos gramaticales adaptados (p. ej. sin auxiliar "do/does" en preguntas, a diferencia del inglés).
- `assets/content/courses/fr.json` — francés, incluye partitivos (du/de la/pas de) en vez de "some/any".
- `assets/content/courses/ja.json` — japonés, con un rediseño deliberado de los puntos gramaticales de las Unidades 3 y 5: en vez de forzar "pronombres + verbo to be" y "presente simple" al estilo inglés (que no existen así en japonés), se usan puntos gramaticales japoneses reales — cópula です/だ y partícula posesiva の en vez de adjetivos posesivos, forma ます (afirmativo/negativo/pregunta) en vez de conjugación por persona. Contenido en escritura japonesa real (hiragana/katakana/kanji), no en rōmaji, con prompts en español.

Test `content_repository_test.dart` generalizado a los 4 idiomas (bucle parametrizado, ya no solo inglés) + test añadido de unicidad de IDs de ejercicio dentro de cada curso (detecta colisiones de copiar-pegar). Los 4 cursos cargan y validan correctamente: 20 unidades, 80 lecciones, 480 ejercicios en total entre los 4 idiomas.

**Fuera de alcance deliberado de esta iteración:** selección de idioma de destino en la UI (`LessonListScreen`/`englishCourseProvider` siguen fijos a inglés) — esta iteración era específicamente de contenido (Paso 3), no de la función de cambiar de idioma en la app, que es una pieza de UI separada para una iteración futura antes de publicar los 4 idiomas.

### Contexto autocontenido
Modelo de datos en `lib/domain/models/`: `Course` (con `sourceLanguage`, `targetLanguage` como campos desde el inicio, aunque el MVP solo cargue 4 combinaciones), `Unit`, `Lesson`, `Exercise` (opción múltiple, rellenar hueco, emparejar), `UserProgress`. Contenido como JSON en `assets/content/courses/<lang-code>.json` (uno por idioma, no un único archivo gigante — así añadir un idioma nuevo no toca los existentes).

**Primer idioma a implementar completo: inglés** (5-8 unidades, 4-6 lecciones/unidad, 8-12 ejercicios/lección, nivel A1 CEFR real y verificado). Los otros 2-3 idiomas de lanzamiento se ejecutan como iteraciones de este mismo paso una vez validado el esquema con inglés — no se paralelizan entre sí en la primera pasada, para no descubrir un problema de esquema replicado en 4 idiomas a la vez.

### Tareas
1. Modelos Dart (`freezed`/`json_serializable` recomendado para inmutabilidad + parsing, añadir a `pubspec.yaml`).
2. `ContentRepository` que carga el JSON del idioma activo desde `assets/`.
3. `assets/content/courses/en.json` con el curso completo de inglés.
4. Test committeado que carga el JSON y verifica `course.units.length >= 5` y campos obligatorios de cada ejercicio.

### Verificación
```bash
cd src/mobile && ~/flutter/bin/flutter test test/content_repository_test.dart
```

### Criterio de salida
Test en verde contra el curso de inglés real.

### Rollback
`git checkout -- src/mobile/lib/domain/models src/mobile/assets/content src/mobile/test/content_repository_test.dart`.

---

## Paso 4 — UI de lecciones [HECHO]

**Modelo:** Sonnet 5. **Paralelizable con:** Paso 3 (mocks hasta converger).
**Depende de:** Paso 2. **Bloquea:** 7, 10.

**Ejecutado:** conectado directamente al contenido real del Paso 3 (no hicieron falta mocks, el curso de inglés ya existía). `LessonListScreen` (lista de unidades/lecciones desde `Course` vía Riverpod), `ExerciseScreen` (renderiza los 3 tipos de ejercicio — opción múltiple con `RadioGroup`, rellenar hueco con `TextField`, emparejar con `DropdownButtonFormField` por par, opciones barajadas de forma determinista por `Exercise.id`), `LessonSummaryScreen` (puntuación + `ProgressBar`), rutas en `go_router` (`/`, `/lesson/:unitId/:lessonId`, `/lesson/:unitId/:lessonId/summary`). Theming Material 3 con paleta semilla provisional (`AppTheme`, light/dark). Progreso de la lección es solo en memoria de momento (persistencia real llega en el Paso 7). `flutter analyze`: sin issues. 7 tests en verde (unitarios de `Exercise.isCorrect` para los 3 tipos, boot del árbol de widgets, navegación lista→ejercicio con calificación real). Build de verificación: `flutter build apk --debug` — `app-debug.apk` generado (92.8MB).

**Simplificación conocida:** la UI de emparejar no impide seleccionar el mismo valor en dos pares distintos (no hay eliminación de opciones ya usadas) — aceptable para el MVP, revisar en una iteración de pulido de UX si hace falta.

### Contexto autocontenido
Widgets en `lib/presentation/lessons/`: lista de unidades/lecciones, pantalla de ejercicio (según `Exercise.type`), resumen de lección, barra de progreso. Rutas registradas en `go_router`.

### Tareas
1. `LessonListScreen`, `ExerciseScreen`, `LessonSummaryScreen`, `ProgressBar` widget.
2. Theming coherente con una identidad visual propia (no genérica) — usar Material 3, definir una paleta de marca aunque sea provisional.

### Verificación
```bash
cd src/mobile && ~/flutter/bin/flutter build apk --debug --target-platform android-arm64
```

### Criterio de salida
APK debug instalable, navegación entre las 4 pantallas funcional (verificación visual manual necesaria; sin emulador gráfico en este contenedor, confirmar con `flutter build` + revisión de widget tests).

### Rollback
`git checkout -- src/mobile/lib/presentation/lessons`.

---

## Paso 5 — Identidad Android [HECHO]

**Modelo:** Sonnet 5. **Paralelizable con:** Paso 6.
**Depende de:** Paso 2. **Bloquea:** 9, 12.

**Ejecutado:** `applicationId`/`namespace` placeholder (`com.TODO.appparaaprenderidiomas.app_para_aprender_idiomas`) confirmado consistente en `build.gradle.kts`, iconos adaptativos por defecto del scaffold (pendientes de logo real). `flutter build appbundle --release` verificado: `app-release.aab` generado (46.2MB, firmado con debug key — firma real pendiente del Paso 13).

### Contexto autocontenido
`src/mobile/android/app/build.gradle` (`applicationId`, `versionCode`/`versionName`), iconos adaptativos en `android/app/src/main/res/`, `AndroidManifest.xml` (permisos mínimos).

### Tareas
1. `applicationId "com.TODO.appparaaprenderidiomas"` (placeholder, confirmar antes del Paso 13).
2. Iconos adaptativos (usar `flutter_launcher_icons` para generarlos desde un logo base, placeholder si no hay uno final).

### Verificación
```bash
cd src/mobile && ~/flutter/bin/flutter build appbundle --release
```

### Criterio de salida
`.aab` generado en `build/app/outputs/bundle/release/`.

### Rollback
`git checkout -- src/mobile/android`.

---

## Paso 6 — Identidad iOS [HECHO — código; build pendiente de CI/Mac]

**Modelo:** Sonnet 5. **Paralelizable con:** Paso 5.
**Depende de:** Paso 2. **Bloquea:** 9, 12.

**Ejecutado:** `CFBundleIdentifier`/`PRODUCT_BUNDLE_IDENTIFIER` confirmado consistente con Android (`com.TODO.appparaaprenderidiomas.appParaAprenderIdiomas`, mismo placeholder), `CFBundleDisplayName` ya correcto ("App Para Aprender Idiomas") desde el scaffold. Sin build local posible en este contenedor Linux, como estaba previsto — se confirma en el Paso 12 (CI, runner macOS).

### Contexto autocontenido
`src/mobile/ios/Runner/Info.plist` (`CFBundleIdentifier` — mismo valor base que Android), iconos, `LaunchScreen`. **Sin build local posible en este contenedor Linux** — se verifica en el Paso 12 (CI, runner macOS) o en Mac real del usuario.

### Tareas
1. `Info.plist`: `CFBundleIdentifier`, versión inicial.
2. Iconos vía `flutter_launcher_icons` (genera para ambas plataformas a la vez desde el mismo comando, ver Paso 5).

### Verificación
Ninguna build local posible. Revisión de código: `Info.plist` bien formado.

### Criterio de salida
Configuración completa, coherente con Android, marcada honestamente como "build pendiente de CI/macOS".

### Rollback
`git checkout -- src/mobile/ios`.

---

## Paso 7 — Persistencia local y progreso [HECHO]

**Modelo:** Sonnet 5.
**Depende de:** 3, 4. **Bloquea:** 8, 10.

**Ejecutado:** `UserProgress` ampliado con `lastActivityDate` + lógica de racha pura (`UserProgress.nextStreak`: mismo día no cambia, día siguiente +1, cualquier otro salto reinicia a 1). `ProgressRepository` (interfaz) con `load`/`recordLessonCompletion`; `InMemoryProgressRepository` (usada en tests y como override) y `SqliteProgressRepository` (real, `sqflite` + `path_provider`, dos tablas — `user_progress` y `completed_lessons` — con `INSERT OR REPLACE`/`OR IGNORE` en una transacción). `ExerciseScreen` llama a `completeLesson` al terminar la última pregunta antes de navegar al resumen; `LessonListScreen` marca con check las lecciones ya completadas vía `englishProgressProvider`. `flutter analyze`: sin issues. 14 tests en verde (6 nuevos de `InMemoryProgressRepository` — guardar/recuperar, aislamiento entre idiomas, las 3 ramas de la racha — más 1 de integración de los providers de Riverpod). `SqliteProgressRepository` no tiene test unitario propio (requiere canales de plataforma, no disponibles en `flutter test`; se revisó por código, sigue el mismo contrato que la versión en memoria) — pendiente de verificación real en `integration_test` sobre emulador/dispositivo cuando exista. Build de verificación: `flutter build apk --debug` con `sqflite` real integrado — `app-debug.apk` generado (112.9MB).

### Contexto autocontenido
`sqflite` para progreso (lecciones completadas, racha, puntuación) en `lib/data/progress_repository.dart`, con interfaz `ProgressRepository` abstracta + implementación SQLite + implementación en memoria para tests.

### Tareas
1. `sqflite` + `path_provider` en `pubspec.yaml`.
2. `ProgressRepository` (interfaz) + `SqliteProgressRepository` + `InMemoryProgressRepository`.
3. Conectar `ExerciseScreen`/`LessonSummaryScreen` al progreso real vía Riverpod provider.

### Verificación
```bash
cd src/mobile && ~/flutter/bin/flutter test test/progress_repository_test.dart
```

### Criterio de salida
Test contra `InMemoryProgressRepository`: guardar/recuperar progreso correcto.

### Rollback
`git checkout -- src/mobile/lib/data/progress_repository.dart src/mobile/test/progress_repository_test.dart`.

---

## Paso 8 — Paywall y entitlements [HECHO]

**Modelo:** Sonnet 5, esfuerzo alto (API de `in_app_purchase` verificada contra el código fuente instalado antes de escribir el repositorio real, dado el peso de la lógica de facturación).
**Depende de:** Paso 7. **Bloquea:** 9.

**Ejecutado:** `SubscriptionPlan` (productId/period/precio, `annualSavingsRatio` calculado a partir de precios reales, no hardcodeado) y `Entitlement` en `domain/models/`. `SubscriptionRepository` (interfaz) con `MockSubscriptionRepository` (planes placeholder, compra simulada con delay, usada en tests y para maquetar sin tienda) y `InAppPurchaseSubscriptionRepository` (real, sobre `in_app_purchase` 3.3.0 — `isAvailable`/`queryProductDetails`/`buyNonConsumable`/`purchaseStream`/`completePurchase`/`restorePurchases`, verificados contra el código fuente del paquete antes de usarlos). `PaywallScreen` con `PlanCard` (toggle mensual/anual, badge de ahorro, vista de "ya eres Premium" cuando hay entitlement activo), accesible desde un icono en `LessonListScreen` y en la ruta `/paywall`. Precios marcados con `// TODO: confirmar precio definitivo con el usuario antes del Paso 13` (placeholders: €7.99/mes, €44.99/año, ahorro real ~53%).

`flutter analyze`: sin issues. Tests en verde: 3 de `annualSavingsRatio` (cálculo real, caso borde de precio 0, placeholders razonables) + 2 de `PaywallScreen` con `MockSubscriptionRepository` (renderiza ambos planes con el badge de ahorro correcto; comprar actualiza la UI a "ya eres Premium"). Build de verificación: `flutter build apk --debug` con `in_app_purchase` real integrado.

### Contexto autocontenido
`lib/data/subscription_repository.dart` usando el paquete oficial `in_app_purchase` (abstrae Google Play Billing + StoreKit 2 bajo una sola API). UI de paywall en `lib/presentation/paywall/paywall_screen.dart` (mensual vs. anual con % de ahorro).

Precios: constante marcada `// TODO: confirmar precio definitivo con el usuario antes del Paso 13`, valor de mercado razonable solo para maquetar.

### Tareas
1. `in_app_purchase` en `pubspec.yaml`.
2. `SubscriptionRepository` (interfaz) + implementación real + `MockSubscriptionRepository` para poder probar la UI sin conexión a las tiendas.
3. `PaywallScreen` con toggle mensual/anual.

### Verificación
```bash
cd src/mobile && ~/flutter/bin/flutter analyze && ~/flutter/bin/flutter test
```
más revisión visual del paywall con `MockSubscriptionRepository`.

### Criterio de salida
Paywall renderiza los dos planes con descuento correcto, sin errores de análisis.

### Rollback
`git checkout -- src/mobile/lib/data/subscription_repository.dart src/mobile/lib/presentation/paywall`.

---

## Paso 9 — Configuración de productos de suscripción (Android + iOS) [HECHO — código; sandbox real pendiente del Paso 13]

**Modelo:** Sonnet 5.
**Depende de:** 5, 6, 8. **Bloquea:** 12, 13.

⚠️ **Bloqueo parcial de cuenta, sigue vigente:** el código compila y corre contra `MockSubscriptionRepository` sin cuenta de tienda. Las pruebas reales de compra (sandbox) requieren productos de suscripción creados en Play Console y App Store Connect — eso llega en el Paso 13.

**Ejecutado:** IDs de producto (`monthly_sub`/`annual_sub`) ya existían como constantes desde el Paso 8. Lo que faltaba y se añadió ahora:
- **`purchaseErrorStream`** nuevo en `SubscriptionRepository` — antes los estados `error`/`canceled`/`pending` de una compra se ignoraban en silencio (`break` sin más); ahora `error` y `canceled` emiten un mensaje legible, y `PaywallScreen` lo muestra en un `SnackBar` (`ref.listen(purchaseErrorProvider, ...)`) en vez de dejar al usuario sin ninguna señal de que algo falló.
- **Verificación local básica de recibo** (lo que el Paso 8 dejaba pendiente explícitamente): una compra `purchased`/`restored` con `verificationData.localVerificationData` vacío se rechaza — no se concede el entitlement y se emite un error. Es una comprobación de presencia, no una verificación criptográfica real; documentado así, sin exagerar, en el docstring de la clase.
- **`MockSubscriptionRepository.simulateFailure`** — hook de test para simular una compra fallida y comprobar que la UI reacciona correctamente.

**Documentado explícitamente qué sigue sin verificar** (en el docstring de `InAppPurchaseSubscriptionRepository`, no solo aquí): sin validación de recibo server-side contra las APIs de Apple/Google (no hay backend), sin verificación criptográfica de firma, sin seguimiento propio de expiración/renovación (depende enteramente de que la tienda vuelva a emitir eventos en `purchaseStream`), sin reconciliación de reembolsos más allá de lo que la tienda empuje.

`flutter analyze`: sin issues. 9 tests nuevos en verde (3 de `InAppPurchaseSubscriptionRepository` — verificación local rechazada, error reportado, cancelación reportada — con `FakeInAppPurchasePlatform`; 1 de `MockSubscriptionRepository.simulateFailure`; 1 de `PaywallScreen` mostrando el snackbar de error), 55 tests en total (antes 50). Cobertura `lib/domain`+`lib/data` subió a **98.8%** (antes 97.5%). Build de verificación: `flutter build apk --debug`.

### Criterio de salida
Código completo, tests contra mocks en verde, sin afirmar verificación no realizada. **Cumplido.**

### Rollback
`git checkout -- src/mobile/lib/data/in_app_purchase_subscription_repository.dart src/mobile/lib/data/mock_subscription_repository.dart src/mobile/lib/domain/repositories/subscription_repository.dart src/mobile/lib/presentation/paywall/paywall_screen.dart src/mobile/lib/presentation/providers/subscription_providers.dart`.

---

## Paso 10 — Onboarding y autenticación mínima [HECHO]

**Modelo:** Sonnet 5.
**Depende de:** 4, 7. **Paralelizable con:** 8, 9.

**Ejecutado:** `WelcomeScreen` → `LevelSelectionScreen` (A1 seleccionable, A2-C2 mostrados como "Próximamente" con candado — honesto sobre lo que existe de verdad) → `AuthChoiceScreen` (invitado o email, ambos **solo locales** en el MVP — la UI lo dice explícitamente al usuario, sin fingir que hay una cuenta real detrás del email). `OnboardingRepository` (interfaz) con `SharedPreferencesOnboardingRepository` (real) e `InMemoryOnboardingRepository` (tests). `RootScreen` decide en `/` si mostrar el onboarding o `LessonListScreen` según `onboardingProvider.completed` — sin usar `redirect` de `go_router` (evita la complejidad de mezclar estado async de Riverpod con el ciclo de vida del router; la decisión vive en el propio widget de la ruta `/`). `selectedLevel` se guarda pero todavía no cambia ningún contenido (solo existe el curso de inglés A1) — documentado como no-op honesto, no una promesa incumplida.

`flutter analyze`: sin issues. 24 tests en verde (2 nuevos de flujo de onboarding: instalación nueva muestra bienvenida en vez de la lista de lecciones; completar como invitado llega a la lista de lecciones). Se añadió `test/test_utils.dart` para no repetir el boilerplate de overrides en cada test que necesita `MyApp` completo. Build de verificación: `flutter build apk --debug` con el flujo de onboarding integrado.

### Contexto autocontenido
Bienvenida → selección de nivel de partida (simplificable a elección manual en el MVP) → email o invitado (invitado = progreso solo local, sin backend de auth en el MVP).

### Tareas
1. `WelcomeScreen`, `LevelSelectionScreen`, `AuthChoiceScreen`.
2. Conectar con `ProgressRepository` para inicializar progreso según nivel.

### Verificación
```bash
cd src/mobile && ~/flutter/bin/flutter test
```

### Criterio de salida
Flujo completo navegable sin bloqueos, tests de widget en verde.

### Rollback
`git checkout -- src/mobile/lib/presentation/onboarding`.

---

## Paso 11 — Tests automatizados con cobertura medida [HECHO]

**Modelo:** Sonnet 5, esfuerzo alto (diseño de fakes de plataforma para testear código real sin dispositivo).
**Depende de:** 3, 7, 8 (mínimo).

**Ejecutado:** cobertura real medida con `flutter test --coverage` + `lcov`/`genhtml` (instalados en el contenedor). En vez de aceptar 0% en los repositorios reales por "requieren plataforma", se testearon de verdad sin dispositivo:
- `SqliteProgressRepository`: `sqflite_common_ffi` contra la librería `libsqlite3` real del sistema (ya presente en el contenedor) + un `PathProviderPlatform` falso apuntando a un directorio temporal real — SQLite de verdad, no un mock.
- `InAppPurchaseSubscriptionRepository`: `FakeInAppPurchasePlatform` (`test/fakes/`) registrado vía `InAppPurchasePlatform.instance`, con `debugDefaultTargetPlatformOverride = TargetPlatform.linux` para evitar que `InAppPurchase.instance` registre un `BillingClientManager` real (que abriría una conexión nativa fallida en segundo plano) — descubierto por error real al escribir el test, no algo anticipado de antemano.
- `SharedPreferencesOnboardingRepository`: `SharedPreferences.setMockInitialValues()` (mecanismo de test oficial del paquete).
- Serialización JSON de los 5 modelos de dominio (`Course`, `CourseUnit`, `Lesson`, `Exercise`, `UserProgress`) con round-trip real, más el caso borde de `UserProgress.nextStreak` con racha corrupta en 0.

**Bug real encontrado y corregido durante este paso:** `MockSubscriptionRepository` emitía un entitlement inicial en el constructor antes de que nadie estuviera escuchando — como es un `StreamController.broadcast()`, ese evento se perdía para cualquier listener que se suscribiera después (exactamente el patrón real de uso en la app). Se eliminó esa emisión: el repositorio ahora se queda en silencio hasta la primera compra/restauración, igual que el repositorio real, y la UI ya trataba correctamente "sin evento todavía" como "sin entitlement activo" (`.value ?? const Entitlement()`), así que no hizo falta tocar `PaywallScreen`.

**Cobertura medida** (`lcov --extract ... 'lib/domain/*' 'lib/data/*'`): **97.5%** (236/242 líneas) — supera el 80% mínimo. Todos los archivos de `domain`/`data` están entre 90% y 100%; el hueco restante son ramas de error no alcanzables sin condiciones sintéticas adicionales (p. ej. `PurchaseStatus.error`/`canceled`/`pending` en el listener de compras). Cobertura del proyecto completo (incluyendo `presentation`, no exigida por el criterio de salida): 81.6%.

`flutter analyze`: sin issues. Suite completa: 46 tests en verde.

### Contexto autocontenido
Cobertura de `ContentRepository`, `ProgressRepository`, cálculo de descuento del paywall, `Level`/`AuthChoice`. Los servicios de `in_app_purchase` reales se testean con mocks, nunca contra tiendas reales en CI.

### Tareas
1. Completar suite de tests (`test/`).
2. `flutter test --coverage` genera `coverage/lcov.info`.

### Verificación
```bash
cd src/mobile && ~/flutter/bin/flutter test --coverage
genhtml coverage/lcov.info -o coverage/html 2>/dev/null || lcov --summary coverage/lcov.info
```

### Criterio de salida
Suite en verde, cobertura ≥80% medida (no estimada) sobre `lib/domain` y `lib/data`.

### Rollback
`git checkout -- src/mobile/test`.

---

## Paso 12 — CI: build Android + iOS [HECHO]

**Modelo:** Sonnet 5.
**Depende de:** 5, 6, 9, 11 (ejecutado sin esperar al Paso 9 completo — CI solo compila y testea, no depende de productos de tienda reales).

**Ejecutado:** `.github/workflows/mobile-ci.yml`, disparado sobre cambios en `src/mobile/**`. `build-android` (ubuntu-latest): `flutter analyze` + `flutter test --coverage` + `flutter build appbundle --release`, con caché de `~/.pub-cache` y de Gradle. `build-ios` (macos-latest): `flutter build ios --release --no-codesign` (sin firma hasta el Paso 13), con caché de `~/.pub-cache`.

**Verificación real, no solo escrita:** el push disparó el run [30968886009](https://github.com/JordiRibasOficial/App-para-aprender-idiomas/actions/runs/30968886009) contra PR #1 — **ambos jobs terminaron en verde** (`conclusion: success`). Primera confirmación real de que el build de iOS (Pasos 6/9) funciona, tal y como pedía el criterio de salida del plan original.

### Contexto autocontenido
`.github/workflows/mobile-ci.yml`, dos jobs:
- `build-android`: `ubuntu-latest`, `subosito/flutter-action` (acción oficial de la comunidad para instalar Flutter en CI), `flutter build appbundle --release`, `flutter test --coverage`.
- `build-ios`: `macos-latest` (obligatorio), `flutter build ios --release --no-codesign` (sin firma hasta tener certificados reales del Paso 13).

**Precondición:** confirmar que el token/credenciales para el push tienen scope `workflow` antes de asumir que el push a `.github/workflows/` funcionará igual que cualquier otro archivo.

### Tareas
1. Workflow YAML con los dos jobs.
2. Cacheo de paquetes pub/Gradle entre runs.

### Verificación
Push del workflow, observar el run real en GitHub Actions (herramientas MCP ya usadas en esta sesión).

### Criterio de salida
Ambos jobs en verde — primera confirmación real de que el build de iOS (Pasos 6/9) funciona.

### Rollback
`git rm .github/workflows/mobile-ci.yml`.

---

## Paso 13 — Assets de tienda y submission ⚠️ REQUIERE ACCIÓN DEL USUARIO [EN CURSO]

**Modelo:** Sonnet 5 para assets/textos; usuario para cuentas y revisión legal.
**Depende de:** 9, 12.

### Contexto autocontenido
Igual estructura que el plan anterior: el agente prepara ficha de tienda, capturas (si hay build real disponible), checklist de submission con cada ítem marcado honestamente como hecho/pendiente. El usuario crea las cuentas, confirma `applicationId`/bundle id definitivo, configura productos de suscripción reales, y hace la revisión legal real antes de publicar.

**Progreso:**
- Titularidad confirmada: **individual** (no organización) — evita el bloqueo de D-U-N-S de Apple, ambas cuentas se pueden crear en días, no semanas.
- Guía paso a paso entregada al usuario para crear Google Play Console (25 $, verificación de identidad ~2-3 días hábiles) y Apple Developer Program (99 $/año, normalmente aprobación el mismo día con cuenta individual). **Cuentas todavía sin crear por el usuario — bloqueo real, en curso.**
- `docs/business/store-listing.md` [HECHO]: textos completos y verificados dentro de límite de caracteres para ambas tiendas (nombre, descripción corta/completa, subtítulo y texto promocional de Apple, palabras clave, categoría, clasificación de contenido). Reclamo de "curso completo gratis, sin lecciones bloqueadas" verificado contra el código (`lib/presentation/lessons` no tiene ninguna lógica de gating por entitlement) antes de escribirlo, para no afirmar algo falso en una ficha pública.
- **Pendiente, bloqueado por assets que no existen todavía:** icono final y gráfico de feature (necesitan un logo real, el proyecto sigue con el icono por defecto del scaffold), capturas de pantalla (necesitan un dispositivo/emulador gráfico real, este contenedor no tiene uno), alojar `privacy-policy-draft.md`/`terms-of-service-draft.md` en una URL pública real (las tiendas no aceptan un enlace a GitHub sin más para el campo obligatorio de política de privacidad).

### Criterio de salida
Paquete de submission listo para que el usuario suba a un track interno/TestFlight en cuanto tenga las cuentas. **Parcialmente cumplido** — textos listos, cuentas y assets gráficos pendientes.

### Rollback
No aplica (documentación).

---

## Paso 14 — Marketing, legal y negocio (paralelo desde el Paso 0) [HECHO — primera pasada]

**Modelo:** Sonnet 5, skill de ECC `marketing-campaign` para la estrategia de lanzamiento — nunca como sustituto de un profesional real.
**Depende de:** nada técnico.

**Ejecutado**, todo en `docs/business/`, cada documento con nota de borrador explícita:
- `launch-strategy.md`: posicionamiento, panorama competitivo (Duolingo/Babbel/Busuu), canales orgánicos priorizados (ASO, TikTok/Reels con contenido real de las lecciones, comunidades), calendario orientativo de 12 semanas, KPIs tempranos sin cifras objetivo inventadas.
- `financial-projection.md`: supuestos declarados explícitamente (precios placeholder del Paso 8, comisión de tienda, conversión/churn de referencia de industria sin datos propios), 3 escenarios a 12 meses, coste real conocido de las cuentas de plataforma (~124 USD/año).
- `privacy-policy-draft.md` y `terms-of-service-draft.md`: borradores coherentes con RGPD y políticas de Apple/Google, honestos sobre que no hay backend todavía (progreso 100% local), con placeholders `[PENDIENTE]` explícitos donde falta decisión legal real.
- `business-registration-checklist.md`: checklist informativo (autónomo vs. sociedad, IVA digital cuando las tiendas actúan como reseller of record, RGPD) — cada punto marcado "pendiente de asesor", ningún trámite ejecutado.

**Marcado como "primera pasada"** porque el trío de idiomas adicional (Paso 3 iteración) y las cuentas reales (Paso 13) todavía no existen — estos documentos se revisarán cuando haya datos reales que sustituyan las hipótesis declaradas.

### Contexto autocontenido
Idéntico en alcance al plan anterior: estrategia de lanzamiento, proyección financiera estimada (marcada como estimación), borradores de política de privacidad/términos (propietario de estos documentos — el Paso 13 los consume, no los duplica), checklist informativo de alta de actividad/IVA digital (sin ejecutar ningún trámite real). Usuario ya confirmó que buscará asesor real antes de publicar.

### Criterio de salida
Documentos en `docs/business/`, cada uno con nota de "borrador, revisar con profesional" donde aplique.

### Rollback
`rm -rf docs/business/`.

---

## Resumen para el usuario

- **14 pasos** (0-14, sin el 4.5 intercalado que hacía falta en MAUI — Flutter separa `android/`/`ios/` de forma nativa en la estructura del proyecto, así que 5 y 6 son paralelos sin necesidad de un paso previo de identidad compartida).
- Paso 0 y parte del Paso 1 **ya ejecutados y en curso de verificación** en esta sesión.
- Primer bloqueo real de tu parte: Paso 13, igual que antes.
- Ventaja real de Flutter frente al plan MAUI descartado: `in_app_purchase` unifica Google Play Billing + StoreKit en una sola API, así que la facturación por plataforma es 1 paso (9) en vez de 2 (9a/9b) — menos superficie de bugs, menos código a mantener duplicado.
