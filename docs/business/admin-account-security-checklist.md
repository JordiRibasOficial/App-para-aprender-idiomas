# Seguridad de las cuentas de administración

> **Esto lo tienes que verificar/activar tú.** No tengo acceso a la configuración de seguridad de ninguna de estas cuentas — solo puedo decirte exactamente qué mirar y por qué importa cada una. Esto es sobre **tus** cuentas de administración (acceso a producción, pagos, código fuente), no sobre la autenticación de los usuarios de la App (que ya está cubierta: identidad anónima, sin contraseñas que gestionar).

## Por qué esto es un punto real del checklist

Cualquiera de estas cuatro cuentas comprometida sin 2FA es un incidente grave por sí sola, sin necesitar ningún fallo en el código:

- **GitHub**: acceso de escritura al código fuente y a los *secrets* de CI/CD (si en algún momento se añaden claves de Supabase/App Store a GitHub Actions).
- **Supabase**: acceso directo a la base de datos de producción (`subscriptions`, `verify_purchase_attempts`) y a la `service_role_key`, que salta la RLS por completo.
- **Google Play Console**: puede publicar una versión maliciosa de la app a todos los usuarios existentes, o cambiar la cuenta de cobro de las suscripciones.
- **Apple Developer / App Store Connect**: mismo riesgo que Play Console, para iOS.

## Checklist

- [ ] **GitHub** (`github.com/settings/security`): 2FA activada (llave de seguridad o app TOTP, no solo SMS — SMS es vulnerable a SIM swapping). Revisar también en `Settings → Password and authentication` que no haya tokens de acceso personal (PAT) olvidados con permisos amplios.
- [ ] **Supabase** (`supabase.com/dashboard/account/security`): 2FA activada. Revisar también quién más tiene acceso al proyecto en `Project Settings → Team` — debería ser solo tú mientras no haya más gente en el equipo.
- [ ] **Google Play Console** (cuenta de Google vinculada, `myaccount.google.com/security`): verificación en dos pasos activada. Play Console además permite dar acceso granular a otras personas sin compartir la cuenta entera (`Users and permissions`) — no es aplicable hoy con un único desarrollador, pero es la vía correcta si en el futuro se suma alguien.
- [ ] **Apple Developer / App Store Connect** (Apple ID, `appleid.apple.com`): la autenticación de dos factores es **obligatoria** desde 2021 para nuevas cuentas de Apple ID — probablemente ya está forzada, pero confirmar. Revisar también en App Store Connect (`Users and Access`) que no haya usuarios/roles heredados de pruebas antiguas con más acceso del necesario.

## Reglas de protección de la rama `main`

`[PENDIENTE: esto lo tienes que activar tú desde la web de GitHub — las herramientas de GitHub a las que tengo acceso en este entorno no incluyen la API de protección de ramas (solo lectura/PRs/archivos/Actions), así que no puedo comprobar ni activar esto por ti.]`

Hoy cualquiera con acceso de escritura (o un token robado) puede hacer `git push --force` directamente a `main` o borrar la rama, sin pasar por ningún PR ni por la CI — el propio flujo de trabajo de este proyecto (rama → PR → merge) es solo una convención que se sigue por disciplina, no algo que GitHub esté haciendo cumplir.

Pasos (`github.com/JordiRibasOficial/App-para-aprender-idiomas/settings/branches` → "Add branch protection rule", patrón `main`):

- [ ] **Require a pull request before merging** — activarlo no cambia nada en la práctica: cada ronda de este checklist ya se ha fusionado siempre vía PR, nunca con push directo.
- [ ] **Require status checks to pass before merging**, marcando el job de `mobile-ci.yml` como *required*. Matiz importante antes de activarlo: ese workflow está filtrado por ruta (`src/mobile/**`) — varios PRs de este checklist (los que solo tocan `docs/business/**`, como el más reciente) nunca lo disparan. Si GitHub trata un check requerido-pero-nunca-disparado como bloqueante en tu configuración, un PR de solo documentación quedaría atascado sin poder fusionarse. Compruébalo con un PR de prueba antes de darlo por bueno; si bloquea, la alternativa es dejar el check como no-requerido y confiar en revisarlo manualmente antes de fusionar (que es lo que se ha hecho hasta ahora).
- [ ] **Block force pushes** y **Restrict deletions** — sin coste ninguno para el flujo actual, y cierran la vía más directa a reescribir o borrar el historial de `main`.
- [ ] **NO actives "Require approvals"** todavía: con un único desarrollador, GitHub no te deja aprobar tu propio PR por defecto, así que esa regla te bloquearía a ti mismo. Actívala el día que haya una segunda persona con acceso de escritura.

## Nota sobre dónde viven las claves reales

Ninguna clave de servicio (Supabase `service_role_key`, credenciales de las tiendas) está en este repositorio en texto plano — viven en `.env` locales (gitignored) y en la configuración del propio Dashboard de cada plataforma. Comprometer una de estas cuatro cuentas de administración es, hoy, la vía más directa para llegar a esas claves — de ahí que este punto importe tanto como cualquier hardening de código ya hecho en las rondas anteriores del checklist.
