# Design — App para Aprender Idiomas (legal micro-site)

A locked design system for this 3-page static site (index · privacy · terms).
Every page redesign reads this file before emitting code.

## Pre-flight findings

- Font stack: system stack only (`-apple-system, ... sans-serif`) — no web fonts, no framework.
- Palette: hex custom properties in `:root`, with a `prefers-color-scheme: dark` override already in place (index.html L8–25, duplicated identically in privacy.html and terms.html).
- Motion: none detected.
- Spacing: ad-hoc pixel values, no scale.
- Framework: none — plain static HTML, one `<style>` block per page (fully duplicated across all three files), served via GitHub Pages (`.nojekyll`).

Hallmark preserves: the brand accent (`#3d5afe` / `#7b8cff` dark), the light/dark split via `prefers-color-scheme`, all legal copy verbatim, the site's information architecture (index → privacy, index → terms, back-links on each doc).

Hallmark introduces: OKLCH tokens (derived from the existing hex values — the accent hue is genuinely the app's icon colour, not invented), a real type pairing, a 4pt spacing scale, macrostructure per page-type, and a single shared stylesheet instead of three duplicated `<style>` blocks.

**Custom theme, not catalog.** The existing accent is the app's actual brand colour (confirmed against `docs/business/brand-assets/` in the main repo — same `#3D5AFE` used for the app icon). Anchoring the palette on it, rather than rotating to one of the 21 catalog themes, is the honest choice for a page that represents this specific brand.

## Genre

Editorial. Reading-focused, credible, no marketing register — this is a legal micro-site, not a landing page.

## Macrostructure family

Two macrostructures, one page-type each:

- **Hub page** (`index.html`): **Index-First** — the page IS the list of the two legal docs. No hero, no narrative.
- **Content pages** (`privacy.html`, `terms.html`): **Long Document** — continuous prose, inline `h2` section heads, single column, generous measure. Exactly matches the shape legal text already has.

Both are **default-off** for motion (per `microinteractions.md`) — stillness is correct here.

## Theme — custom, anchored on the existing brand blue

Converted from the site's own hex values to OKLCH (`oklch()`, D65, sRGB gamut). Nothing invented; this is the existing palette named as tokens.

```
Light
--color-paper    oklch(100%   0     0)      was #ffffff
--color-paper-2  oklch(97.4%  0.005 275)    was #f5f6fa  (card bg)
--color-ink      oklch(22.8%  0.038 283)    was #1a1a2e
--color-ink-2    oklch(47.7%  0.038 285)    was #5a5a72  (muted)
--color-rule     oklch(92%    0.014 277)    was #e2e4ee  (border)
--color-accent   oklch(55.5%  0.243 269)    was #3d5afe

Dark
--color-paper    oklch(19.7%  0.022 284)    was #14141f
--color-paper-2  oklch(23.4%  0.031 284)    was #1c1c2c
--color-ink      oklch(95.2%  0.019 280)    was #eceefc
--color-ink-2    oklch(73.2%  0.040 281)    was #a3a6c2
--color-rule     oklch(30.2%  0.036 284)    was #2c2c40
--color-accent   oklch(68%    0.169 275)    was #7b8cff
```

Axes: paper band = light (>85%) / dark (<30%) depending on mode · display style = classical-serif (Newsreader) · accent hue = cool (268–275°, blue).

Contrast checked against the original hex values (WCAG AA, all pass comfortably): ink/paper 17:1, muted/paper 6.7:1 (light) and 7.6:1 (dark), accent-as-text/paper 5.1:1 (light) and 6.1:1 (dark). No value needed adjusting.

## Typography

- Display: **Newsreader**, weight 600, roman only (optical-size axis on). Page titles and `h2` section heads.
- Body: **IBM Plex Sans**, weight 400 (500 for interactive link labels).
- Outlier: **Geist Mono**, weight 500. Used in exactly one slot per page — the "última actualización" date stamp on `privacy.html`/`terms.html`, and the small kicker label on `index.html`. Never a third body font.
- Scale: 1.25 ratio (major third), 16px body floor. No hero display size — this is a document, not a landing page; `h1` tops out at `--text-2xl` (~2.4rem).
- Measure: 65ch on Long Document pages, ~52ch on the index (Index-First is a short stub, not a reading column).

## Spacing

4-point named scale in `tokens.css` (`--space-3xs` … `--space-2xl`). No raw pixel values in page CSS.

## Motion

Minimal by design (default-off macrostructures). Only: link/card hover (border + colour, 180ms `--ease-out`), `:focus-visible` ring (instant, never animated in). No page-load reveals, no stagger. `prefers-reduced-motion: reduce` collapses the hover transition to 0ms colour swap (nothing spatial to begin with).

## Microinteractions stance

- No toasts, no modals, no forms on this site — none needed.
- Hover delay: n/a (no tooltips).
- Silent by default; the only feedback surface is link hover/focus.

## CTA voice

- Primary action (index page): the two document links themselves, styled as bordered cards — same shape as the source, refined tokens/type.
- Secondary action (content pages): "← Volver" as a typographic link (C3), no button chrome.

## Per-page allowances

- Index (`Index-First`): no enrichment, no imagery.
- Content pages (`Long Document`): no enrichment, no imagery. The one `.card` callout in `privacy.html` (§2, data collected) is a content-block, not decoration — kept, restyled on tokens.

## What pages MUST share

- The `App para Aprender Idiomas` wordmark (set in Newsreader, no separate wordmark face — Long Document/Index-First collapse to one family per `typography.md`).
- The accent colour and its restrained use (link colour, hover border, focus ring — never a large fill).
- `tokens.css` + `styles.css`, linked identically by all three pages (replacing the three duplicated inline `<style>` blocks).
- The Ft2 (inline single-line) footer.

## What pages MAY differ on

- Macrostructure: Index-First (hub) vs. Long Document (content) — see above.
- The presence of a "← Volver" back link (content pages only; the hub page has nothing to go back to).

## Nav

**N1a-equivalent, justified.** `component-cookbook.md` defaults away from N1a unless "the page genuinely has 2 destinations" — this site genuinely does: every content page's only outbound link is back to the hub. No wordmark-plus-menu bar is added; the back-link on content pages *is* the nav. The hub page has no nav chrome at all (Index-First: the page is the destination list).

## Theme toggle

A fixed, top-right icon button (`#theme-toggle`, `theme-toggle.js`) on every page — a single utility control, not a nav element. Three states, matching the app's `AppThemeMode` for a consistent choice across both surfaces: **system** (monitor icon, default) → **light** (sun) → **dark** (moon) → back to system. Choice persists in `localStorage` (`theme-preference`); applied via `data-theme` on `<html>`, set by a blocking inline script in `<head>` before first paint to avoid a flash of the wrong theme. `tokens.css` keys dark values off `@media (prefers-color-scheme: dark) :root:not([data-theme="light"])` (system default) and `:root[data-theme="dark"]` (explicit override) — both routes land on the same token values, nothing duplicated. Hand-built SVG icons (monitor / sun / moon), one consistent stroke style, `currentColor` — no icon library, no emoji.

## Footer

**Ft2 · Inline single line** on every page — hairline rule, one line, wordmark + copyright. `Ft3` (index-style columns) was considered and rejected: this site has two destinations total, not a sitemap.

## Exports

Single-page-scale project (3 static HTML files, no build tooling) — `tokens.css` only, no Tailwind/DTCG/shadcn exports (`export-formats.md` is for `design.md`-managed apps with those build targets; this project has none).
