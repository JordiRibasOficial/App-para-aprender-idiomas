# Privacy Manifest y términos mínimos de EULA de Apple

> Dos requisitos de Apple, distintos entre sí, verificados en la misma pasada porque ambos bloquean la subida a App Store Connect si faltan.

## 1. `PrivacyInfo.xcprivacy` — antes no existía

Desde 2024 Apple exige que cualquier app (o SDK de terceros que acceda a las llamadas "required reason APIs" — UserDefaults, timestamps de archivo, espacio en disco, etc.) declare ese uso en un archivo de manifiesto de privacidad. Sin él, App Store Connect puede rechazar la build directamente, antes incluso de revisión humana.

**No existía ningún `PrivacyInfo.xcprivacy` en el proyecto.** Añadido en `src/mobile/ios/Runner/PrivacyInfo.xcprivacy` y enlazado en `Runner.xcodeproj/project.pbxproj` (fase de Resources) para que se empaquete de verdad en el `.app` — un archivo suelto en el directorio no se incluye solo, hay que darlo de alta en el proyecto de Xcode, igual que cualquier otro asset (mismo motivo por el que las imágenes del launch screen necesitaron entradas propias en el `.pbxproj`).

**Alcance del manifiesto**: solo el código propio de la app y los plugins que no traen su propio manifiesto. Google Mobile Ads (vía Swift Package Manager, se ve en el log de `build-ios`: "Xcode is fetching Swift Package Manager dependencies... swift-package-manager-google-mobile-ads") ya trae el suyo desde hace tiempo — Xcode lo fusiona automáticamente al archivar, no hay que duplicarlo aquí.

Contenido declarado:
- **`NSPrivacyAccessedAPITypes`**: `NSPrivacyAccessedAPICategoryUserDefaults` con motivo `CA92.1` ("acceso a información de la propia app, según documentación") — cubre `shared_preferences`, que solo guarda las propias preferencias de la app (onboarding, aceptación de términos, etc.), nunca lee las de otra app.
- **`NSPrivacyCollectedDataTypes`**: mapeado 1:1 desde la tabla "App Privacy" ya existente en `store-listing.md` (ID de usuario anónimo, historial de compras, idioma de estudio, datos de publicidad) — para que ambos documentos no diverjan, cualquier cambio en uno debe reflejarse en el otro.
- **`NSPrivacyTracking`**: `true` — coherente con que ya existe el prompt de ATT.

**Verificado**: XML bien formado (`plistlib` de Python), y las 4 referencias cruzadas del `.pbxproj` (`PBXBuildFile`, `PBXFileReference`, grupo `Runner`, fase `Resources`) siguen exactamente el mismo patrón que `Assets.xcassets`/`LaunchScreen.storyboard`. La compilación real en simulador/dispositivo solo puede verificarse en macOS — la corre `build-ios`/`integration-test-ios` en CI, como todos los cambios de iOS de esta sesión.

## 2. Términos mínimos del EULA de Apple — faltaban en el ToS

Cuando una app usa un EULA/ToS propio en vez del EULA estándar de Apple, App Store Connect exige que ese EULA propio incluya ciertas cláusulas mínimas ("Minimum Terms for Developer's End-User License Agreements", Schedule 2 del Acuerdo de Licencia de Programa de Apple) — básicamente: que Apple no es parte del acuerdo, que no tiene obligación de soporte, el procedimiento de reembolso por garantía, que no responde de reclamaciones de terceros ni de propiedad intelectual, la cláusula de tercero beneficiario a su favor, y la declaración de cumplimiento de control de exportación.

**No estaban.** Añadidas como nueva sección en `docs/business/terms-of-service-draft.md` (§14, antes de Contacto) y en el `terms.html` publicado (§12, mismo sitio relativo — la versión publicada no incluye las secciones 7/8 de DMCA/conducta porque siguen inactivas, así que su numeración es distinta a la del borrador).

`[PENDIENTE: como el resto del ToS, confirmar la redacción exacta con un asesor legal antes de publicar como definitiva — aquí se ha seguido el texto estándar que resume Apple, no una traducción jurada.]`
