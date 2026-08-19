# Prueba real de restauración de backup

> **Este runbook lo tienes que ejecutar tú.** No tengo acceso ni credenciales al proyecto real de Supabase (`nfkhnrwyekqbjxwxmctu`) — igual que con el redeploy del backend, esto requiere tu sesión autenticada de `supabase login` en tu propia máquina. Un backup que nunca se ha restaurado es una suposición, no una garantía — la sección "Backups" de `src/backend/README.md` documenta que existen, pero nadie ha comprobado que un restore real funcione y devuelva datos correctos.

## Por qué en un proyecto aparte, no en el real

**No restaures nunca sobre el proyecto de producción para "probarlo"** — un restore sustituye la base de datos entera, no es un simulacro reversible por sí mismo. El procedimiento de abajo usa un **proyecto Supabase nuevo y temporal**, gratuito, solo para la prueba.

## Procedimiento

```powershell
# 1. Generar un dump del proyecto real (dato de referencia para comparar después)
cd "D:\Claude\Claude Code\apps\Aprender Idiomas\App-para-aprender-idiomas\src\backend"
npx supabase db dump --linked -f backup-test-$(Get-Date -Format yyyyMMdd).sql

# 2. Anotar manualmente 2-3 filas reales de `subscriptions` y
#    `verify_purchase_attempts` desde el Dashboard (Table Editor) antes de
#    seguir — esto es lo que vas a comprobar que sobrevive al restore.

# 3. Crear un proyecto Supabase NUEVO y temporal (Dashboard → New project,
#    plan Free, cualquier nombre tipo "backup-restore-test") — no toques
#    el proyecto real a partir de aquí.

# 4. Vincular la CLI a ese proyecto temporal (no al real)
npx supabase link --project-ref <ref-del-proyecto-temporal>

# 5. Restaurar el dump del paso 1 en el proyecto temporal
npx supabase db push --linked --file backup-test-<fecha>.sql
# (si `db push` no acepta un dump plano de `pg_dump`, usar en su lugar:
#  psql "postgresql://postgres:<password>@<host-del-proyecto-temporal>:5432/postgres" -f backup-test-<fecha>.sql
#  — la connection string temporal está en Project Settings → Database del proyecto de prueba)

# 6. Verificar en el Dashboard del proyecto temporal (Table Editor) que las
#    filas anotadas en el paso 2 existen ahí, con los mismos valores.

# 7. Borrar el proyecto temporal (Project Settings → General → Delete
#    project) — no dejarlo vivo indefinidamente, es un proyecto Free extra
#    sin uso real.
```

## Qué confirma esta prueba

- Que el dump generado por `supabase db dump` es válido y restaurable de verdad, no solo que el comando termina sin error.
- Que las tablas `subscriptions` y `verify_purchase_attempts` (las que de verdad importan — son la fuente de verdad de quién ha pagado) sobreviven el ciclo completo dump→restore con los datos intactos.
- Que **tú** sabes ejecutar el procedimiento antes de necesitarlo de verdad en un incidente real — la primera vez que se prueba un restore no debería ser durante una emergencia.

## Sobre el restore nativo de Supabase (PITR / snapshot diario)

Este runbook prueba el mecanismo de respaldo manual (`db dump`), que es el que ya usa este repo como "stopgap". El restore **nativo** de Supabase (snapshot diario o PITR, ver `src/backend/README.md` § Backups) se hace desde el propio Dashboard del proyecto real (Project Settings → Backups → Restore) y **sí actúa directamente sobre el proyecto real** — no hay forma de probarlo en un proyecto aparte porque es una función del proyecto en sí. `[PENDIENTE: decidir si merece la pena programar una ventana de mantenimiento para probar también ese restore nativo contra el proyecto real, dado el riesgo de downtime real durante la prueba — la prueba con `db dump` de arriba ya da bastante confianza sin ese riesgo.]`
