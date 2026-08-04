# Plan: App para Aprender Idiomas — MVP móvil (Android + iOS)

**v2 — revisado tras auditoría adversarial (Opus) + verificación empírica real en este contenedor. Ver "Registro de cambios" al final.**

**Objetivo:** convertir el scaffold actual (Blazor Web App en `src/AppParaAprenderIdiomas.Web`) en una app móvil publicable en Google Play y App Store, con curso de inglés para hispanohablantes, progreso persistente y suscripción (mensual / anual con descuento) funcionando de verdad en ambas tiendas.

**Decisiones ya tomadas (no reabrir sin motivo nuevo):**
- Stack: .NET MAUI Blazor Hybrid — reutiliza C#/Razor del scaffold actual, un solo código para Android + iOS.
- Idioma de partida: inglés para hispanohablantes.
- Alcance: MVP funcional y publicable, no gamificación avanzada ni IA conversacional en esta fase.
- Modo: **direct** (sin `gh` CLI en este entorno; se sigue el flujo ya usado en la rama `claude/obra-superpowers-marketplace-mwtr1t` — commit + push directo, PR #1 existente en GitHub gestionado vía MCP).

**Bloqueo externo aceptado:** publicar en tienda requiere que el usuario cree por su cuenta Apple Developer Program (99$/año) y Google Play Console (25$ pago único) — **precios verificados a fecha 2026-08; confirmar en el momento del alta por si han cambiado**. El plan está diseñado para que el desarrollo llegue a "listo para publicar" sin depender de tener esas cuentas ya creadas — se marca explícitamente en qué paso empiezan a hacer falta (Paso 13).

**Modelo por defecto:** Sonnet 5. Se usa Opus 5 / esfuerzo alto donde el paso lo indica explícitamente (decisiones de arquitectura, lógica de facturación, diseño de tests, revisión adversarial).

---

## Grafo de dependencias (autoritativo — las líneas `Depende de:` de cada paso mandan sobre este dibujo si hay discrepancia)

```
0 (entorno)
 └─1 (scaffold MAUI)
    └─2 (librería compartida + wiring de rutas)
       └─4.5 (identidad/versión/iconos compartidos — csproj + Resources/, una sola vez)
          ├─3a (modelos + loader + 1 unidad) ──┐
          ├─3b (resto de unidades) [tras 3a] ──┤
          ├─4 (UI de lecciones, con mocks) ────┤
          ├─5 (Android head: Platforms/Android/ únicamente)
          ├─6 (iOS head: Platforms/iOS/ únicamente)
          │
          ├──────────┬───────────┘
          │     7 (persistencia/progreso) [depende solo de 3a,4]
          │           │
          │           ├─8 (paywall + entitlements + scaffolding #if ANDROID/#if IOS)
          │           │   ├─9a (Google Play Billing) [Platforms/Android/*Billing*.cs]
          │           │   └─9b (StoreKit / Apple IAP) [Platforms/iOS/*Billing*.cs]
          │           │
          │           └─10 (onboarding/auth mínimo)
          │
14 (marketing/legal/negocio — paralelo a TODO desde el Paso 0, sin dependencias técnicas)
          │
     11 (tests, incl. cobertura)
          │
     12 (CI: build Android real + iOS en runner macOS)
          │
     13 (assets de tienda + submission) ⚠️ requiere cuentas de tienda del usuario
```

**Parejas realmente paralelizables (sin colisión de archivos, verificado):** `{3a→3b son secuenciales, no paralelas: se corrigió}`, `{4 puede empezar en paralelo a 3a con datos mock, converge antes de cerrar}`, `{5, 6}` (una vez hecho 4.5, cada uno toca solo su carpeta `Platforms/<OS>/`), `{9a, 9b}` (una vez hecho 8, cada uno toca solo su carpeta de plataforma + su bloque `#if` propio en `MauiProgram.cs`), `14` es paralelo a todo el árbol técnico desde el Paso 0.

---

## Paso 0 — Entorno: SDK con soporte de workloads + Android SDK nativo

**Modelo:** Sonnet 5.
**Depende de:** nada. **Bloquea:** todo lo demás.

### Contexto autocontenido
**Verificado empíricamente en este contenedor, no es una suposición:** el `dotnet` instalado vía `apt` (`dotnet-sdk-8.0`, en `/usr/lib/dotnet`) **no soporta workloads** (`dotnet workload search` no devuelve nada, `dotnet workload install android` falla con "Workload ID android is not recognized"). El SDK instalado con el script oficial de Microsoft (`dotnet-install.sh`) sí los soporta. Además, compilar para Android requiere el **SDK nativo de Android de Google** (distinto del workload de .NET) — sin él, el build falla con `XA5300: The Android SDK directory could not be found`, aunque el workload de .NET esté instalado.

Se probó el flujo completo y **funciona**: SDK oficial → workload `android` → paquete de plantillas `Microsoft.Maui.Templates` → Android SDK nativo (cmdline-tools + platform-tools + `platforms;android-34` + `build-tools;34.0.0`) → parche de TFMs (ver Paso 1) → `dotnet build -f net8.0-android` termina en 0 errores.

**iOS sigue siendo imposible de compilar en este contenedor** (Linux) independientemente del SDK usado — eso no cambia; se verifica en CI con runner macOS (Paso 12) o en un Mac real del usuario.

**Ubicación:** instalar en rutas persistentes del `$HOME`, no en `/tmp` (se pierde entre sesiones de este entorno remoto). Si se ejecuta este paso en una sesión nueva de Claude Code on the web, considerar añadirlo a `.claude/hooks/session-start.sh` (mismo patrón ya usado en este repo para `superpowers`/`napkin`/`markitdown`/ECC) para no repetir la descarga (~10-15 min) en cada sesión.

### Tareas
1. `curl -fsSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh && bash /tmp/dotnet-install.sh --channel 8.0 --install-dir ~/.dotnet-maui`
2. `~/.dotnet-maui/dotnet workload install android --skip-sign-check`
3. `~/.dotnet-maui/dotnet new install Microsoft.Maui.Templates` (usar la última disponible; a fecha de esta verificación no hay build fijado 8.0.100 publicado en NuGet, así que no pinnear una versión que no existe)
4. Android SDK nativo:
   ```bash
   mkdir -p ~/android-sdk/cmdline-tools
   curl -fsSL https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -o /tmp/cmdline-tools.zip
   unzip -q /tmp/cmdline-tools.zip -d ~/android-sdk/cmdline-tools && mv ~/android-sdk/cmdline-tools/cmdline-tools ~/android-sdk/cmdline-tools/latest
   export PATH="$HOME/android-sdk/cmdline-tools/latest/bin:$PATH"
   yes | sdkmanager --sdk_root="$HOME/android-sdk" "platform-tools" "platforms;android-34" "build-tools;34.0.0"
   ```
5. Exportar de forma persistente (perfil de shell o script del entorno): `PATH` con `~/.dotnet-maui` primero, y `ANDROID_HOME=~/android-sdk`.

### Verificación
```bash
~/.dotnet-maui/dotnet workload list   # debe listar 'android'
~/.dotnet-maui/dotnet new list maui-blazor   # debe encontrar la plantilla
ls ~/android-sdk/platforms/android-34   # debe existir
```

### Criterio de salida
Los tres comandos de verificación devuelven lo esperado, sin errores.

### Rollback
`rm -rf ~/.dotnet-maui ~/android-sdk` (no toca el repo git, es infraestructura de entorno).

---

## Paso 1 — Scaffold de la solución MAUI Blazor Hybrid

**Modelo:** Opus 5 / esfuerzo alto (decisión de arquitectura, afecta a todos los pasos siguientes).
**Depende de:** Paso 0. **Bloquea:** todo lo demás salvo 14.

### Contexto autocontenido
El repo tiene hoy `AppParaAprenderIdiomas.sln` en la raíz con un único proyecto `src/AppParaAprenderIdiomas.Web` (Blazor Web App, .NET 8, interactividad de servidor, paquete `Humanizer` — pinneado a `2.14.1` porque la `3.0.10` publicada en NuGet está rota: su sub-paquete `Humanizer.Core.fil` no declara ningún target framework compatible). No existe ningún proyecto MAUI todavía. El proyecto Web existente **no se borra** — queda como referencia, pero el desarrollo activo se mueve al proyecto Mobile.

**Importante, verificado empíricamente:** la plantilla `maui-blazor` genera por defecto `<TargetFrameworks>net8.0-android;net8.0-ios;net8.0-maccatalyst</TargetFrameworks>` **sin condicionar por sistema operativo**. NuGet restore evalúa TODOS los TFMs listados, así que incluso pidiendo compilar solo `-f net8.0-android`, el restore falla en Linux porque los packs de iOS no existen aquí (`NETSDK1178`). Hay que parchear el `.csproj` en este mismo paso, no dejarlo para después.

### Tareas
1. `~/.dotnet-maui/dotnet new maui-blazor -n AppParaAprenderIdiomas.Mobile -o src/AppParaAprenderIdiomas.Mobile --framework net8.0`
2. `~/.dotnet-maui/dotnet sln add src/AppParaAprenderIdiomas.Mobile/AppParaAprenderIdiomas.Mobile.csproj`
3. Editar `AppParaAprenderIdiomas.Mobile.csproj`: reemplazar la línea `<TargetFrameworks>net8.0-android;net8.0-ios;net8.0-maccatalyst</TargetFrameworks>` por:
   ```xml
   <TargetFrameworks>net8.0-android</TargetFrameworks>
   <TargetFrameworks Condition="$([MSBuild]::IsOSPlatform('osx'))">$(TargetFrameworks);net8.0-ios;net8.0-maccatalyst</TargetFrameworks>
   ```
   (dejar intacta la línea de Windows que ya trae el propio template).

### Verificación
```bash
export ANDROID_HOME=~/android-sdk
~/.dotnet-maui/dotnet build src/AppParaAprenderIdiomas.Mobile -f net8.0-android /p:AndroidSdkDirectory=$ANDROID_HOME
```
Este comando **sí se puede y se debe ejecutar de verdad** en este entorno — no es una verificación aplazada a CI. `-f net8.0-ios` no es verificable aquí; eso se confirma en el Paso 12.

### Criterio de salida
`dotnet build ... -f net8.0-android` termina en 0 errores. La solución tiene 3 proyectos (`Web`, `Mobile`, y luego `Core` en el Paso 2).

### Rollback
`git checkout -- AppParaAprenderIdiomas.sln && rm -rf src/AppParaAprenderIdiomas.Mobile`.

---

## Paso 2 — Librería de clases compartida + wiring de rutas

**Modelo:** Sonnet 5.
**Depende de:** Paso 1. **Bloquea:** 3a, 4, 5, 6, 4.5.

### Contexto autocontenido
Se extrae a una **Razor Class Library** (`src/AppParaAprenderIdiomas.Core`, `net8.0`) todo lo que no dependa de la plataforma: modelos de dominio, servicios de lógica de negocio, y componentes Razor de UI compartidos (se rellenan en pasos posteriores). Ambos proyectos (`Web`, `Mobile`) referencian `Core`.

**Wiring no obvio que hay que resolver aquí y no en cada paso posterior por separado:** para que las páginas Razor "routables" definidas dentro de `Core` (que llegarán en los Pasos 4/8/10) sean visibles por el router de Blazor, hace falta registrar el ensamblado de `Core` como `AdditionalAssemblies` **en los dos sitios**: `Web/Components/Routes.razor` (`<Router AppAssembly="..." AdditionalAssemblies="new[] { typeof(AppParaAprenderIdiomas.Core.SomeMarkerType).Assembly }">`) y en el `Routes.razor` equivalente que la plantilla `maui-blazor` genera dentro de `Mobile`. Si no se hace aquí, los Pasos 4/8/10 chocarán entre sí intentando arreglarlo cada uno por su lado (eran "paralelos" solo en apariencia).

### Tareas
1. `dotnet new razorclasslib -n AppParaAprenderIdiomas.Core -o src/AppParaAprenderIdiomas.Core`.
2. `dotnet sln add src/AppParaAprenderIdiomas.Core/AppParaAprenderIdiomas.Core.csproj`.
3. Referenciar `Core` desde `Web` y `Mobile`: `dotnet add <proyecto> reference src/AppParaAprenderIdiomas.Core`.
4. Mover `Humanizer 2.14.1` como dependencia de `Core` en vez de solo `Web`.
5. Crear un tipo marcador vacío (`Core/_AssemblyMarker.cs`) y registrar `AdditionalAssemblies` en ambos `Routes.razor` (Web y Mobile) apuntando al ensamblado de `Core`.

### Verificación
```bash
export ANDROID_HOME=~/android-sdk
~/.dotnet-maui/dotnet build AppParaAprenderIdiomas.sln -f net8.0-android
dotnet build src/AppParaAprenderIdiomas.Web   # el proyecto Web no necesita el SDK oficial, el de apt le vale
```

### Criterio de salida
Ambos builds terminan en 0 errores. Un componente de prueba puesto en `Core/Components/_Probe.razor` con una ruta `@page "/probe"` es navegable desde ambos proyectos (verificación manual rápida, se borra después del Paso 2).

### Rollback
`git checkout -- AppParaAprenderIdiomas.sln src/AppParaAprenderIdiomas.Web/Components/Routes.razor src/AppParaAprenderIdiomas.Mobile/Components/Routes.razor && rm -rf src/AppParaAprenderIdiomas.Core`.

---

## Paso 4.5 — Identidad, versión e iconos compartidos (una sola vez, antes de tocar cada plataforma)

**Modelo:** Sonnet 5.
**Depende de:** Paso 2. **Bloquea:** 5, 6.

### Contexto autocontenido
En MAUI single-project, `ApplicationId`, `ApplicationDisplayVersion`, `ApplicationVersion`, `MauiIcon` y `MauiSplashScreen` viven en el **`Mobile.csproj` compartido**, no en las carpetas `Platforms/<OS>/`. Si esto se deja para los Pasos 5 y 6 por separado, ambos editan el mismo archivo y dejan de ser paralelos de verdad (era el hallazgo C3 de la revisión). Se resuelve aquí, una vez, antes de que 5 y 6 arranquen.

**Decisión pendiente del usuario, no inventar:** el `ApplicationId`/bundle identifier definitivo (ej. `com.<nombreempresa>.appparaaprenderidiomas`). Usar un placeholder explícito (`com.TODO.appparaaprenderidiomas`) documentado como "hay que confirmar con el usuario antes del Paso 13" — cambiarlo después de publicar en tienda no es trivial.

### Tareas
1. En `Mobile.csproj`: `ApplicationId`, `ApplicationDisplayVersion` (`0.1.0`), `ApplicationVersion` (`1`).
2. Iconos adaptativos + splash screen en `Mobile/Resources/` (placeholder si no hay logo final del usuario, documentar que se debe sustituir antes de publicar).

### Verificación
```bash
export ANDROID_HOME=~/android-sdk
~/.dotnet-maui/dotnet build src/AppParaAprenderIdiomas.Mobile -f net8.0-android
```

### Criterio de salida
Build en 0 errores con la nueva identidad/iconos aplicados.

### Rollback
`git checkout -- src/AppParaAprenderIdiomas.Mobile/AppParaAprenderIdiomas.Mobile.csproj src/AppParaAprenderIdiomas.Mobile/Resources`.

---

## Paso 3a — Modelo de contenido, loader, y primera unidad real

**Modelo:** Sonnet 5.
**Depende de:** Paso 2. **Bloquea:** 3b, 7. **Paralelizable con:** Paso 4 (con datos mock).

### Contexto autocontenido
Define en `Core/Models/`: `Course`, `Unit`, `Lesson`, `Exercise` (subtipos: opción múltiple, rellenar hueco, emparejar), `UserProgress`. Contenido semilla en `Core/Content/course-en-a1.json` como `EmbeddedResource`. En este paso se crea **solo 1 unidad completa** (4-6 lecciones, 8-12 ejercicios cada una) — el resto del curso es el Paso 3b. Esto evita el problema de un paso de "hasta 570 ítems" no acotado para una sola sesión de agente.

El contenido debe ser lingüísticamente correcto (nivel A1 CEFR real, no inventado sin criterio) — si hay duda de vocabulario/gramática, verificar con las skills de documentación/research disponibles en este entorno en vez de adivinar.

### Tareas
1. Modelos C# en `Core/Models/`.
2. `ContentLoader` service que deserializa el JSON.
3. `Core/Content/course-en-a1.json` con 1 unidad completa.
4. **Test committeado** (no un script ad-hoc que se descarta) en `tests/AppParaAprenderIdiomas.Tests` (crear el proyecto de tests ya desde aquí si el Paso 11 aún no ha corrido) que carga el JSON y verifica `unit.Lessons.Count >= 4` y que cada ejercicio tiene los campos obligatorios rellenos.

### Verificación
```bash
dotnet test tests/AppParaAprenderIdiomas.Tests --filter ContentLoader
```

### Criterio de salida
El test de carga de contenido pasa en verde contra la unidad 1 real.

### Rollback
`git checkout -- src/AppParaAprenderIdiomas.Core/Models src/AppParaAprenderIdiomas.Core/Content tests/AppParaAprenderIdiomas.Tests`.

---

## Paso 3b — Resto de unidades del curso

**Modelo:** Sonnet 5. Ejecutar en lotes de 1 unidad por sesión/sub-agente para no perder calidad pedagógica por prisa.
**Depende de:** Paso 3a.

### Contexto autocontenido
Igual que 3a pero para las 4-7 unidades restantes hasta completar 5-8 unidades totales. Cada unidad se añade al mismo `course-en-a1.json`, ampliando el test del Paso 3a para cubrir el nuevo total.

### Tareas
1. Por cada unidad nueva: contenido + ampliar el test de conteo del Paso 3a.

### Verificación
```bash
dotnet test tests/AppParaAprenderIdiomas.Tests --filter ContentLoader
```

### Criterio de salida
≥5 unidades totales, todas pasando el test de carga.

### Rollback
`git checkout -- src/AppParaAprenderIdiomas.Core/Content/course-en-a1.json tests/AppParaAprenderIdiomas.Tests`.

---

## Paso 4 — UI compartida de lecciones (componentes Razor)

**Modelo:** Sonnet 5. **Paralelizable con:** 3a (usando datos mock hasta que 3a converja).
**Depende de:** Paso 2. **Bloquea:** 7, 10.

### Contexto autocontenido
Componentes Razor en `Core/Components/`: lista de unidades/lecciones, pantalla de ejercicio (según `Exercise.Type`), pantalla de resultado, barra de progreso. Agnósticos de plataforma. **Verificación honesta de dependencia:** este paso puede arrancar antes de que 3a/3b terminen usando un `MockContentLoader` con 1-2 ejercicios de prueba, pero **no se considera cerrado** hasta re-verificar contra el `ContentLoader` real del Paso 3a con datos reales.

### Tareas
1. `LessonListPage.razor`, `ExercisePage.razor`, `LessonSummaryPage.razor`, `ProgressBar.razor`, con rutas `@page` (aprovechando el wiring del Paso 2).
2. Reutilizar estilos de `Web/wwwroot/app.css` y Bootstrap ya presentes en el scaffold.

### Verificación
```bash
dotnet run --project src/AppParaAprenderIdiomas.Web   # preview rápido, comparte los mismos componentes Core
curl -s -o /dev/null -w "%{http_code}" http://localhost:5299/   # o el puerto que arranque
```

### Criterio de salida
Las 4 pantallas navegan sin errores, primero contra mock, y una segunda pasada obligatoria contra los datos reales del Paso 3a antes de dar el paso por cerrado.

### Rollback
`git checkout -- src/AppParaAprenderIdiomas.Core/Components`.

---

## Paso 5 — Cabecera Android

**Modelo:** Sonnet 5. **Paralelizable con:** Paso 6 (verificado sin colisión: cada uno toca solo su carpeta `Platforms/<OS>/`, la identidad compartida ya se resolvió en 4.5).
**Depende de:** Paso 4.5. **Bloquea:** 7, 9a, 12.

### Contexto autocontenido
Configuración específica de Android en `Mobile/Platforms/Android/` **únicamente**: `MainActivity.cs`, `MainApplication.cs`, `AndroidManifest.xml` (permisos — ninguno especial en el MVP, sin cámara/micrófono todavía).

### Tareas
1. Ajustar `MainActivity.cs`/`MainApplication.cs` generados por la plantilla si hace falta.
2. `AndroidManifest.xml`: revisar permisos, dejar el mínimo necesario.

### Verificación
```bash
export ANDROID_HOME=~/android-sdk
~/.dotnet-maui/dotnet publish src/AppParaAprenderIdiomas.Mobile -f net8.0-android -c Release
```
(`dotnet publish`, no `build` — `build` no genera el `.aab`/`.apk` final; verificado que `publish` es el comando correcto para producir el artefacto instalable, firmado con el keystore de debug por defecto en esta fase).

### Criterio de salida
`dotnet publish` genera un `.apk`/`.aab` en `bin/Release/net8.0-android/`.

### Rollback
`git checkout -- src/AppParaAprenderIdiomas.Mobile/Platforms/Android`.

---

## Paso 6 — Cabecera iOS

**Modelo:** Sonnet 5. **Paralelizable con:** Paso 5.
**Depende de:** Paso 4.5. **Bloquea:** 9b, 12.

### Contexto autocontenido
Configuración específica de iOS en `Mobile/Platforms/iOS/` **únicamente**: `Info.plist`, `LaunchScreen`. **Limitación de entorno confirmada, no hipotética:** este contenedor es Linux; no hay build ni firma de iOS posible aquí bajo ninguna combinación de SDK (a diferencia de Android, que sí se desbloqueó en el Paso 0). Se verifica en el Paso 12 (CI, runner macOS) o en un Mac real del usuario.

### Tareas
1. `Info.plist`: `CFBundleIdentifier` (mismo valor base que el `ApplicationId` de Android, coherente), versión inicial.
2. Documentar (sin inventar) qué falta para firmar: certificado de distribución + perfil de aprovisionamiento, dependientes de tener la cuenta de Apple Developer Program activa (Paso 13).

### Verificación
Ninguna build local posible. Revisión de código: `Info.plist` bien formado, sin placeholders sin marcar.

### Criterio de salida
Código y configuración completos y coherentes con Android; explícitamente marcado como "build pendiente de CI/macOS", nunca como "verificado" sin haberlo hecho.

### Rollback
`git checkout -- src/AppParaAprenderIdiomas.Mobile/Platforms/iOS`.

---

## Paso 7 — Persistencia local y progreso del usuario

**Modelo:** Sonnet 5.
**Depende de:** 3a, 4. **Bloquea:** 8, 10.
(No depende de 5/6 — SQLite vía `FileSystem.AppDataDirectory` de MAUI no necesita nada de las cabeceras nativas; dependencia eliminada respecto a la v1 del plan, que serializaba innecesariamente.)

### Contexto autocontenido
Progreso (lecciones completadas, racha, puntuación) en SQLite local vía `sqlite-net-pcl`. Vive en `Core/Services/ProgressStore.cs` mediante interfaz `IProgressStore`, con `SqliteProgressStore` (real) e `InMemoryProgressStore` (para tests). **Decisión de arquitectura resuelta aquí, no aplazada:** el paquete `sqlite-net-pcl` y el acceso al filesystem van en `Core`, usando `Microsoft.Maui.Storage.FileSystem.AppDataDirectory` — disponible porque `Core` es una Razor Class Library referenciada por `Mobile` (que sí trae el SDK de MAUI); no hace falta duplicar la implementación por plataforma.

### Tareas
1. Paquete `sqlite-net-pcl` en `Core`.
2. `IProgressStore` + `SqliteProgressStore` + `InMemoryProgressStore`.
3. Conectar `ExercisePage`/`LessonSummaryPage` (Paso 4) al progreso real.

### Verificación
```bash
dotnet test tests/AppParaAprenderIdiomas.Tests --filter ProgressStore
```

### Criterio de salida
Test contra `InMemoryProgressStore`: guardar y recuperar progreso funciona correctamente.

### Rollback
`git checkout -- src/AppParaAprenderIdiomas.Core/Services`.

---

## Paso 8 — Paywall, entitlements, y scaffolding de facturación por plataforma

**Modelo:** Opus 5 / esfuerzo alto (lógica de negocio de facturación, errores aquí cuestan dinero real).
**Depende de:** Paso 7. **Bloquea:** 9a, 9b.

### Contexto autocontenido
Interfaz `ISubscriptionService` en `Core` (`GetOfferingsAsync`, `PurchaseAsync`, `RestorePurchasesAsync`, `IsEntitledAsync`). UI de paywall en `Core/Components/PaywallPage.razor` (mensual vs. anual con % de ahorro visible), dependiente solo de la interfaz.

**Para que 9a y 9b sean realmente paralelos** (hallazgo C3), este paso deja ya preparado en `Mobile/MauiProgram.cs` el registro condicional del servicio:
```csharp
#if ANDROID
builder.Services.AddSingleton<ISubscriptionService, GooglePlayBillingService>();
#elif IOS
builder.Services.AddSingleton<ISubscriptionService, AppleStoreKitService>();
#endif
```
con las clases `GooglePlayBillingService`/`AppleStoreKitService` como *stubs* vacíos que lanzan `NotImplementedException` — así 9a y 9b solo tienen que rellenar su propio archivo, sin tocar `MauiProgram.cs` ni pisarse entre sí.

Precios: constantes marcadas `// TODO: confirmar precio definitivo con el usuario antes del Paso 13`, con un valor de mercado razonable solo para poder maquetar (no se presenta como precio final).

### Tareas
1. `ISubscriptionService` + modelos (`SubscriptionOffering`, `PurchaseResult`).
2. `PaywallPage.razor` con toggle mensual/anual y cálculo de ahorro.
3. Stubs `GooglePlayBillingService`/`AppleStoreKitService` + registro condicional en `MauiProgram.cs`.
4. `MockSubscriptionService` para poder probar la UI sin conexión real a las tiendas.

### Verificación
```bash
export ANDROID_HOME=~/android-sdk
~/.dotnet-maui/dotnet build src/AppParaAprenderIdiomas.Mobile -f net8.0-android
```
más revisión visual del paywall con `MockSubscriptionService` desde `dotnet run --project src/AppParaAprenderIdiomas.Web`.

### Criterio de salida
Build en 0 errores, paywall renderiza los dos planes con el descuento calculado correctamente, sin dependencia de plataforma en `Core`.

### Rollback
`git checkout -- src/AppParaAprenderIdiomas.Core/Services src/AppParaAprenderIdiomas.Core/Components/PaywallPage.razor src/AppParaAprenderIdiomas.Mobile/MauiProgram.cs`.

---

## Paso 9a — Google Play Billing (Android)

**Modelo:** Sonnet 5. **Paralelizable con:** 9b (archivos distintos, confirmado tras el Paso 8).
**Depende de:** 5, 8. **Bloquea:** 12, 13.

⚠️ **Bloqueo parcial de cuenta:** compila sin cuenta de Google Play Console, pero las **pruebas reales de compra** (sandbox de Play Billing) requieren la app subida a un track interno con los productos de suscripción ya creados — eso llega en el Paso 13.

### Contexto autocontenido
Implementar `GooglePlayBillingService : ISubscriptionService` **solo** en `src/AppParaAprenderIdiomas.Mobile/Platforms/Android/Services/GooglePlayBillingService.cs`, reemplazando el stub del Paso 8. No tocar `MauiProgram.cs` (ya resuelto) ni ningún archivo de `Platforms/iOS/`.

### Tareas
1. Paquete NuGet de Play Billing para .NET 8/MAUI.
2. Implementar la interfaz completa, con manejo de errores (cancelado, pago fallido, ya suscrito) y restauración de compras.

### Verificación
```bash
export ANDROID_HOME=~/android-sdk
~/.dotnet-maui/dotnet build src/AppParaAprenderIdiomas.Mobile -f net8.0-android -c Release
```
Verificación funcional real de compra: pendiente hasta el Paso 13 — documentar explícitamente, no marcar como "probado".

### Criterio de salida
Compila en Release sin errores; código revisado contra la documentación oficial de Play Billing.

### Rollback
`git checkout -- src/AppParaAprenderIdiomas.Mobile/Platforms/Android/Services/GooglePlayBillingService.cs` (rollback acotado a este archivo — **no** al Paso 5 completo, para no borrar la cabecera Android al deshacer solo la facturación).

---

## Paso 9b — StoreKit / Apple In-App Purchase (iOS)

**Modelo:** Sonnet 5. **Paralelizable con:** 9a.
**Depende de:** 6, 8. **Bloquea:** 12, 13.

⚠️ Mismo bloqueo que 9a pero para Apple, más la limitación de compilación ya descrita en el Paso 6.

### Contexto autocontenido
Implementar `AppleStoreKitService : ISubscriptionService` **solo** en `src/AppParaAprenderIdiomas.Mobile/Platforms/iOS/Services/AppleStoreKitService.cs` (StoreKit 2), reemplazando el stub del Paso 8. No tocar `MauiProgram.cs` ni `Platforms/Android/`.

### Tareas
1. Implementar la interfaz con StoreKit 2 (bindings de .NET 8 para iOS).
2. Manejo de "Ask to Buy", restauración de compras, errores.
3. `StoreKit Configuration file` local de Xcode para pruebas en simulador sin depender de tener productos reales en App Store Connect todavía (esto sí se puede preparar sin cuenta).

### Verificación
Sin build local posible (falta macOS/Xcode). Código revisado contra la documentación oficial de StoreKit 2, marcado como pendiente de compilar/probar en el Paso 12 (CI) o en Mac del usuario.

### Criterio de salida
Código completo y coherente con 9a (misma interfaz, mismo comportamiento de UI).

### Rollback
`git checkout -- src/AppParaAprenderIdiomas.Mobile/Platforms/iOS/Services/AppleStoreKitService.cs`.

---

## Paso 10 — Onboarding y autenticación mínima

**Modelo:** Sonnet 5.
**Depende de:** 4, 7. **Paralelizable con:** 8, 9a, 9b (sin archivos compartidos).

### Contexto autocontenido
Flujo mínimo: bienvenida → selección de nivel de partida (simplificable a elección manual, sin test de nivel elaborado, en este MVP) → email o invitado (invitado = solo progreso local, sin backend de auth en el MVP). **Pregunta abierta, no decisión cerrada:** si la cuenta con email se aplaza a post-MVP — dejarlo como interfaz preparada pero no bloqueante, y confirmarlo con el usuario antes de invertir tiempo extra ahí.

### Tareas
1. `WelcomePage.razor`, `PlacementQuizPage.razor` (o selección manual simplificada), `AuthChoicePage.razor`.
2. Conectar con `IProgressStore` (Paso 7) para inicializar progreso según nivel elegido.

### Verificación
Flujo completo navegable de principio a fin (emulador Android o `dotnet run` del proyecto Web como preview).

### Criterio de salida
De "abrir la app por primera vez" a "ver la primera lección" sin bloqueos.

### Rollback
`git checkout -- src/AppParaAprenderIdiomas.Core/Components/WelcomePage.razor src/AppParaAprenderIdiomas.Core/Components/PlacementQuizPage.razor src/AppParaAprenderIdiomas.Core/Components/AuthChoicePage.razor`.

---

## Paso 11 — Tests automatizados (con cobertura medida de verdad)

**Modelo:** Opus 5 para diseñar qué probar y por qué; Sonnet 5 para escribirlos.
**Depende de:** 3a, 3b, 7, 8 (mínimo); idealmente también tras 9a/9b/10.

### Contexto autocontenido
Proyecto `tests/AppParaAprenderIdiomas.Tests` (xUnit) — puede que ya exista parcialmente desde el Paso 3a; completar aquí. Cobertura: `ContentLoader`, `ProgressStore` (contra `InMemoryProgressStore`), cálculo de descuento del paywall, lógica de `PlacementQuiz`/`AuthChoice`. Los servicios de billing reales (9a/9b) se testean con dobles, nunca contra las tiendas reales en CI.

`dotnet test` por sí solo **no mide cobertura** — hace falta el paquete `coverlet.collector` y el flag de recolección para que el objetivo de 80% sea verificable de verdad, no una cifra aspiracional sin instrumento de medida.

### Tareas
1. Completar el proyecto de tests si hace falta, añadir a la solución.
2. Paquete `coverlet.collector`.
3. Tests AAA, nombres descriptivos (convención en `~/.claude/rules/ecc/common/testing.md`).

### Verificación
```bash
dotnet test tests/AppParaAprenderIdiomas.Tests --collect:"XPlat Code Coverage"
```
Revisar el `coverage.cobertura.xml` generado (o usar `reportgenerator` si se quiere un resumen legible) y confirmar ≥80% sobre `Core/Services` y `Core/Models`.

### Criterio de salida
Suite en verde, cobertura ≥80% **medida**, no estimada.

### Rollback
`git checkout -- AppParaAprenderIdiomas.sln && rm -rf tests/AppParaAprenderIdiomas.Tests`.

---

## Paso 12 — CI: build automático Android + iOS

**Modelo:** Sonnet 5.
**Depende de:** 5, 6, 9a, 9b, 11.

### Contexto autocontenido
GitHub Actions (`.github/workflows/mobile-ci.yml`). Dos jobs:
- `build-android`: `ubuntu-latest`. Reproduce exactamente el Paso 0 (instalar SDK oficial + workload `android` + Android SDK nativo — o cachear estos pasos entre runs) y luego `dotnet publish -f net8.0-android -c Release` + `dotnet test`.
- `build-ios`: `macos-latest` (obligatorio, sin alternativa Linux). Xcode viene preinstalado en el runner. `dotnet build -f net8.0-ios -c Release`.

**Precondición no obvia a verificar antes de este paso:** el token/credenciales usados para hacer push del workflow deben tener el scope `workflow` (los tokens sin ese scope fallan silenciosamente al intentar añadir o modificar archivos bajo `.github/workflows/`) — comprobarlo antes de asumir que un push normal funcionará igual que con cualquier otro archivo del repo.

### Tareas
1. Workflow YAML con los dos jobs, replicando el Paso 0 para el job Android.
2. Cacheo de NuGet/workloads entre runs.
3. Trigger en push a la rama de trabajo y en PRs.

### Verificación
Push del workflow y observar el resultado real en GitHub Actions (herramientas MCP de GitHub ya usadas en esta sesión: `actions_list`/`actions_get`).

### Criterio de salida
Ambos jobs en verde en un run real — esta es también la primera confirmación real de que el build de iOS (Paso 6) funciona, ya que este contenedor no puede compilarlo.

### Rollback
`git rm .github/workflows/mobile-ci.yml` (o `git checkout --` si ya existía).

---

## Paso 13 — Assets de tienda y paquete de publicación ⚠️ REQUIERE ACCIÓN DEL USUARIO

**Modelo:** Sonnet 5 para assets/textos; el usuario para las cuentas y la revisión legal.
**Depende de:** 9a, 9b, 12.

### Contexto autocontenido
**Punto donde el bloqueo externo se vuelve real.** Antes de este paso, todo el desarrollo avanza sin las cuentas de tienda. A partir de aquí hace falta que el usuario:
1. Cree (si no lo ha hecho) Apple Developer Program y Google Play Console.
2. Confirme el `ApplicationId`/bundle identifier definitivo (placeholder usado desde el Paso 4.5).
3. Cree los productos de suscripción reales con precios definitivos (ya no el placeholder del Paso 8).
4. Revise legalmente (persona real, no un agente) la política de privacidad/términos antes de publicar — especialmente relevante por ser una app educativa con posible uso por menores.

### Tareas (agente, sin esperar al usuario)
1. Ficha de Play Store y App Store: título, descripción corta/larga, palabras clave.
2. Borrador de política de privacidad y términos de servicio — **redactados en el Paso 14, no duplicados aquí; este paso solo los adjunta al paquete de submission**.
3. Capturas de pantalla: **solo si hay un build Android real disponible** (artefacto de CI del Paso 12, o un dispositivo/emulador del usuario) — no se pueden generar en este contenedor sin un emulador gráfico, marcar como pendiente si no hay build disponible en el momento de ejecutar este paso.
4. Checklist de submission con cada ítem marcado como "hecho" o "pendiente de dato del usuario" — nunca "hecho" si depende de una cuenta inexistente.

### Tareas (usuario, bloqueantes)
1. Crear/confirmar cuentas de desarrollador.
2. Confirmar `ApplicationId`/bundle id definitivos.
3. Configurar productos de suscripción reales con precios definitivos.
4. Revisión legal real antes de publicar.
5. Pulsar "publicar" — solo el titular de la cuenta puede hacerlo.

### Verificación
Checklist completo, ningún ítem marcado como "hecho" que en realidad dependa de algo que no existe todavía.

### Criterio de salida
Paquete de submission (textos + capturas si están disponibles + checklist) listo para que el usuario suba a un track interno/TestFlight en cuanto tenga las cuentas.

### Rollback
No aplica (documentación, no código).

---

## Paso 14 — Pista paralela: marketing, legal y negocio (arranca desde el Paso 0, sin bloquear lo técnico)

**Modelo:** Sonnet 5, apoyado en las skills de ECC instaladas en este entorno: `content-engine` y `marketing-campaign` (nombres corregidos — `marketing-agent` no existe en esta instalación).
**Depende de:** nada técnico.

### Contexto autocontenido
Cubre marketing/financiero/legal/gestoría **dentro de lo que un agente de código puede honestamente ofrecer**: borradores y análisis, no sustituyen a un profesional humano colegiado para constituir empresa o cumplir normativa fiscal real. **Este paso es el propietario de los borradores legales** (política de privacidad, términos de servicio) — el Paso 13 los consume, no los duplica.

### Tareas
1. **Marketing**: estrategia de lanzamiento, calendario de contenido (skill `content-engine`), copy de la página de precios.
2. **Financiero**: modelo simple de proyección de ingresos (usuarios estimados × conversión × precio) — marcado explícitamente como estimación, no auditoría.
3. **Legal**: política de privacidad y términos de servicio (borrador), con aviso explícito de implicaciones adicionales por ser educativa/posible uso por menores (COPPA en EEUU, GDPR-K en la UE) — profesional debe revisar antes de publicar.
4. **Gestoría/empresa**: checklist informativo sobre alta de actividad e IVA en servicios digitales (OSS/MOSS) desde España/UE — sin ejecutar ningún trámite real, solo para saber qué preguntar a un gestor.

### Verificación
Ninguna técnica — contenido/documento. "Completo" cuando el usuario confirma que los borradores son un punto de partida útil.

### Criterio de salida
Documentos en `docs/business/`, cada uno con nota clara de "borrador, revisar con profesional" donde aplique.

### Rollback
`rm -rf docs/business/`.

---

## Resumen para el usuario

- **15 pasos** (0 a 14, con 3 desdoblado en 3a/3b y un 4.5 intercalado). Parejas realmente paralelizables, verificadas sin colisión de archivos: `{5,6}`, `{9a,9b}`, y `14` en paralelo a todo desde el principio.
- **Primer bloqueo real de tu parte**: el Paso 13 (assets y submission) — todo lo anterior avanza con preguntas puntuales de producto (nombre de paquete, precios definitivos), no con bloqueos duros.
- **Android se puede compilar y probar de verdad en este contenedor** (verificado empíricamente en la sesión de planificación) — no es "código sin probar" como se pensaba inicialmente; solo iOS necesita macOS/CI.
- Nada de esto reemplaza a un profesional legal/fiscal real para constituir empresa o cumplir normativa — el Paso 14 deja borradores útiles, no asesoría vinculante.

---

## Registro de cambios (v1 → v2)

Revisión adversarial (Opus) + verificación empírica encontraron 5 hallazgos críticos, 8 avisos y 5 menores en la v1. Todos corregidos en esta v2:
- **C1**: se demostró que Android, no solo iOS, era irrealizable con el SDK original (`apt`) — añadido Paso 0 con la ruta real que sí funciona, verificada con un build exitoso.
- **C2**: TFMs de iOS/MacCatalyst ahora condicionados por SO desde el Paso 1, con el parche exacto verificado.
- **C3**: Pasos 5/6 y 9a/9b ya no colisionan — identidad/versión compartida movida a un Paso 4.5 propio, y el registro condicional de servicios de facturación movido al Paso 8.
- **C4**: rollbacks de 9a/9b acotados a su archivo, no a toda la carpeta de plataforma.
- **C5**: criterio de salida del Paso 13 corregido para no afirmar un resultado (app subida a tienda) que el agente no puede producir.
- **W1-W8**: dependencia espuria de 7→6 eliminada, Paso 3 desdoblado en 3a/3b, cobertura de tests ahora medida con `coverlet`, comando de build de Android 5 cambiado a `publish`, wiring de rutas de `Core` resuelto en el Paso 2, precondición de scope de token documentada en el Paso 12, nombres de skills corregidos en el Paso 14.
- **M1-M5**: precios de tienda marcados con fecha de verificación, diagrama de dependencias realineado con el texto autoritativo, referencia a `napkin.md` sustituida por el dato inline, decisión de arquitectura de `Core`/filesystem resuelta explícitamente en el Paso 7, propiedad de los borradores legales asignada al Paso 14 en vez de duplicarse en el 13.
