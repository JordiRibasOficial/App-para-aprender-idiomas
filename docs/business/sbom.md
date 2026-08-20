# SBOM (inventario formal de dependencias)

Distinto de `docs/business/dependency-license-audit.md` (que audita las *licencias*): esto es un inventario formal, en formato estándar, de cada dependencia con su versión exacta y hash — el tipo de documento que la CRA exige como parte de la documentación técnica (ver `docs/business/cra-applicability-review.md`) y que cada vez más plataformas/clientes empresariales piden de forma explícita.

## Dónde vive

`sbom.cdx.json` en la raíz del repo — formato [CycloneDX](https://cyclonedx.org/) 1.5, el estándar más extendido junto con SPDX (elegido porque tiene mejor soporte de herramientas para el ecosistema JS/npm que usa el backend, y es el que recomienda la propia guía de la CRA).

**174 componentes**: 162 paquetes de Dart/Flutter (`src/mobile/pubspec.lock`) + 12 del backend (10 npm + 2 jsr, deduplicados entre las 3 Edge Functions — cada componente indica en `properties` qué función(es) lo usan).

## Cómo regenerarlo

```bash
python3 tools/sbom/generate_sbom.py
```

**Regenerarlo cada vez que cambien las dependencias** (`flutter pub add/upgrade`, o un bump en algún `deno.json`) — es una fotografía del momento en que se genera, no se actualiza solo. `[PENDIENTE: considerar automatizarlo como paso de CI que falle si `sbom.cdx.json` queda desactualizado respecto a `pubspec.lock`/`deno.lock` — no lo he montado todavía porque no hay ningún workflow de backend en CI hoy (ver hallazgo en `dependency-license-audit.md`).]`

## Relación con el resto del checklist

- **Licencias** (`dependency-license-audit.md`): ya auditadas, sin copyleft fuerte.
- **Vulnerabilidades conocidas**: cubiertas por Dependabot en los tres ecosistemas (`github-actions`, `pub`, `deno`) — ver `.github/dependabot.yml`.
- **CRA**: este SBOM es la pieza de "documentación técnica" que la CRA pedirá desde diciembre de 2027 — tenerlo ya generado (y el script para regenerarlo) adelanta ese trabajo sin coste real hoy.
