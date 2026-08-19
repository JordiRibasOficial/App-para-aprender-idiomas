# Auditoría de licencias de dependencias

> **Documento interno.** Objetivo: confirmar que ninguna dependencia de terceros obliga a liberar el código propio de la App (copyleft fuerte tipo GPL/AGPL) ni impone condiciones incompatibles con venderla como producto de pago. Revisar de nuevo tras añadir cualquier paquete nuevo — este documento no se actualiza solo.

**Última actualización: 19 de agosto de 2026.**

## Método

- **Mobile (`src/mobile`)**: `flutter pub get` (Flutter 3.44.8) resolvió las 162 dependencias declaradas en `pubspec.lock` (14 directas + transitivas). Se inspeccionó el archivo `LICENSE`/`LICENSE.md` real de cada paquete descargado en `~/.pub-cache/hosted/pub.dev/` (219 paquetes en caché local, superconjunto de los 162 de este proyecto), buscando términos de licencias copyleft fuertes o restrictivas (GPL, AGPL, LGPL, SSPL, Business Source License).
- **Backend (`src/backend`)**: solo 3 dependencias directas declaradas en `deno.json` (Deno no genera un árbol `node_modules` completo en este entorno, así que la verificación es sobre las directas, todas de proveedores/paquetes ampliamente conocidos y permisivos).

## Resultado — Mobile

**Ningún hallazgo de copyleft fuerte.** El escaneo automático solo marcó un falso positivo:

- `gtk-2.2.0` (dependencia transitiva, utilidades GTK+ para Flutter Linux — este proyecto no compila para Linux desktop, solo Android/iOS, así que ni siquiera se enlaza en los binarios reales) — su `LICENSE` es **Mozilla Public License 2.0** (copyleft débil, a nivel de archivo, no viral al resto de la app). El escaneo lo marcó porque el propio texto de la MPL-2.0 menciona "GNU Lesser General Public License" y "GNU Affero General Public License" en su cláusula de "Secondary Licenses" — coincidencia de texto, no una licencia GPL/AGPL real.

El resto de las 162 dependencias del proyecto (incluidas `google_mobile_ads`, `app_tracking_transparency`, `supabase_flutter`, `flutter_secure_storage`, `flutter_riverpod`, `go_router`, `sqflite`, `in_app_purchase`, etc.) usan licencias permisivas estándar del ecosistema Dart/Flutter — predominantemente BSD-3-Clause, MIT y Apache 2.0. Ninguna exige distribuir el código fuente de la App ni restringe venderla como producto de pago.

## Resultado — Backend

| Paquete | Licencia | Nota |
|---|---|---|
| `@supabase/supabase-js` | MIT | Cliente oficial de Supabase. |
| `zod` | MIT | Validación de esquemas. |
| `@std/assert` (Deno std) | MIT | Solo usado en tests. |

Las tres son permisivas y de uso extendido en el ecosistema — sin riesgo de copyleft.

## Conclusión

No hay ninguna dependencia, directa ni transitiva detectada, que obligue a liberar el código de la App. `[PENDIENTE: repetir este escaneo cada vez que se añada una dependencia nueva — no es un análisis que se mantenga solo. Si se añade alguna librería con licencia GPL/AGPL/LGPL/SSPL/BUSL en el futuro, revisar con un asesor antes de publicar esa versión.]`
