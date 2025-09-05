# Meal Management & Reporting Platform (Next.js + Express + MySQL)

Ce fichier décrit l’architecture, le schéma SQL, les API, la logique métier (tarifs/limites/dépassements), la planification des rapports (daily/weekly/bi‑weekly/semi‑monthly/monthly/custom) et l’option d’envoi automatique par SMTP.

---

## 0) TL;DR — Objectifs

* Saisir et valoriser les **repas** des employés à partir des logs **FingerTec/Ingress** (FEDERATED tables).
* Appliquer des **règles de tarification** : tarif normal jusqu’à **limite**, puis **tarif après limite** (par type de repas / workcode).
* Calculer et stocker les **déductions** (reporting) par période.
* Offrir un **self‑service employé** (consultation conso & déductions) + un **back‑office RH**.
* Générer des **rapports** à des fréquences multiples (**daily, weekly, bi‑weekly, semi‑monthly, monthly, custom**) et **envoyer automatiquement par email (SMTP)**.
* Authentification simple (user/role), UI moderne **Tailwind** (login avec **logo de l’entreprise en fond**, modal centré).

---

## 1) Stack & Prérequis

* **Frontend** : Next.js ≥ 14 (App Router), Tailwind CSS, React Hook Form, Zod.
* **Backend** : Express.js (Node ≥ 18), TypeScript recommandé, `mysql2`/`knex` ou `prisma` (au choix). Nodemailer pour SMTP.
* **DB** : MySQL 8.0. FEDERATED tables pointant vers Ingress (FingerTec). Tables métier en **InnoDB** locales.
* **Auth** : Sessions JWT (stateless) ou cookies signés (au choix). Ici : **JWT sans refresh table** (simple).
* **Planification** : `node-cron` (ou BullMQ si Redis dispo) pour exécuter les rapports selon `report_schedule`.

### 1.1) Variables d’environnement (.env)

```
# MySQL
DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=meal_db
DB_USER=meal
DB_PASS=1000_Database

# JWT
JWT_SECRET=1000Password@20XX
JWT_EXPIRES_IN=3600s

** Dans un .env si possible
# SMTP
SMTP_HOST=smtp.gmail.com
SMTP_PORT=465
SMTP_SECURE=true
SMTP_USER=your.smtp.user@gmail.com
SMTP_PASS=yourAppPassword
SMTP_FROM="Meal Reports" <no-reply@itxpress.net>

# App
APP_BASE_URL=http://localhost:3000
COMPANY_LOGO_URL=/logo.png  # ou URL publique ; configurable via app_settings
```

---

## 2) Schéma SQL (rappel & ajouts)

### 2.1) Tables FEDERATED (déjà en place)

* `company` (infos entreprise, **federated**, vers Ingress)
* `employee` (employés, **federated**)
* `user_group` (départements, **federated**)
* `meal` (types de repas, **federated**)
* `meal_cons` (logs de consommation, **federated**)

> ⚠️ **Pas de FOREIGN KEY** possible depuis InnoDB vers FEDERATED → on conserve des **liens logiques** (par clé technique) et on valide côté app.

### 2.2) Tables InnoDB (métier)

* `meal_setting` — paramètres globaux par *workcode* (tarif normal, limite, tarif après limite)
* `employee_meal_rate` — exceptions employé/repas (override des tarifs/limites)
* `meal_salary` — résultats mensuels (ou par période) persistés pour export
* `logs` — audit des actions admin

**Ajouts pour Auth, UI, Reporting & SMTP** :

* `user` — comptes applicatifs (login, rôle, liaison optionnelle `employee.userid`)
* `app_settings` — paires clé/valeur (ex: `company_logo_url`)
* `report_schedule` — planification des rapports (daily/weekly/bi‑weekly/semi‑monthly/monthly/custom)
* `report_schedule_recipient` — destinataires email par planification
* `report_logs` — historique d’exécution (période, fichier, statut, erreurs)

#### 2.2.1) DDL — Ajouts InnoDB

```sql
-- Comptes applicatifs
CREATE TABLE IF NOT EXISTS `user` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `username` VARCHAR(50) NOT NULL UNIQUE,
  `password` VARCHAR(255) NOT NULL,
  `email` VARCHAR(100) DEFAULT NULL,
  `role` ENUM('admin','manager','employee') DEFAULT 'employee',
  `employee_id` VARCHAR(30) DEFAULT NULL COMMENT 'Lien logique vers employee.userid',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `last_login` DATETIME DEFAULT NULL,
  KEY `employee_id` (`employee_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Paramètres d’application (logo, thèmes, etc.)
CREATE TABLE IF NOT EXISTS `app_settings` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `k` VARCHAR(100) NOT NULL UNIQUE,
  `v` TEXT NULL,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Planification des rapports
CREATE TABLE IF NOT EXISTS `report_schedule` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(100) NOT NULL,
  `type` ENUM('daily','weekly','bi-weekly','semi-monthly','monthly','custom') NOT NULL,
  `anchor_date` DATE DEFAULT NULL COMMENT 'Point de départ pour bi-weekly (et weekly si besoin)',
  `start_date` DATE DEFAULT NULL COMMENT 'Utilisé quand type=custom',
  `end_date` DATE DEFAULT NULL COMMENT 'Utilisé quand type=custom',
  `day_of_week` TINYINT DEFAULT NULL COMMENT '1=Lundi ... 7=Dimanche (weekly)',
  `day_of_month` TINYINT DEFAULT NULL COMMENT 'Monthly: jour; Semi-monthly: ignoré (1–15 et 16–fin)',
  `time_of_day` TIME DEFAULT '06:00:00' COMMENT 'Heure locale d\'exécution',
  `email_subject` VARCHAR(200) DEFAULT 'Meal Report',
  `email_body` TEXT DEFAULT NULL,
  `email_enabled` TINYINT(1) DEFAULT 0,
  `format` ENUM('csv','xlsx','pdf','json') DEFAULT 'csv',
  `next_run` DATETIME DEFAULT NULL,
  `last_run` DATETIME DEFAULT NULL,
  `created_by` INT DEFAULT NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Destinataires email par planification
CREATE TABLE IF NOT EXISTS `report_schedule_recipient` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `schedule_id` INT NOT NULL,
  `email` VARCHAR(200) NOT NULL,
  `name` VARCHAR(100) DEFAULT NULL,
  KEY `schedule_id` (`schedule_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Historique d\'exécution des rapports
CREATE TABLE IF NOT EXISTS `report_logs` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `schedule_id` INT DEFAULT NULL,
  `period_start` DATE NOT NULL,
  `period_end` DATE NOT NULL,
  `format` VARCHAR(10) DEFAULT 'csv',
  `file_path` VARCHAR(500) DEFAULT NULL,
  `status` ENUM('success','error','skipped') DEFAULT 'success',
  `error_message` TEXT DEFAULT NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  KEY `schedule_id` (`schedule_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
```

> **Note** : Les DDL des tables FEDERATED, ainsi que `meal_setting`, `employee_meal_rate`, `meal_salary`, `logs` sont déjà fournis et installés par Schneider. Les ajouts ci‑dessus complètent l’écosystème (auth + reporting).

---

## 3) Logique métier — Tarifs, Limites, Dépassements

### 3.1) Sources & Paramètres

* **Quantités** : `meal_cons` (FingerTec) → (userid, checktime, workcode)
* **Paramètres globaux** : `meal_setting` (par workcode)
* **Overrides employés** : `employee_meal_rate` (par userid + workcode)

### 3.2) Règle de valorisation (par workcode)

* Soit $q$ = nombre de repas consommés sur la période.
* Soit $r$ = tarif normal, $L$ = limite, $r_a$ = tarif après limite.
* **Coût** = `CASE WHEN q <= L THEN r*q ELSE r*L + (q-L)*r_a END`.

### 3.3) Agrégation SQL — Exemple (toutes les lignes agrégées par employé)

> Idée : calculer les quantités par employé + workcode, puis appliquer les paramètres effectifs (override si présent, sinon global).

```sql
-- 1) Quantités par employé et workcode sur une période
SELECT mc.userid,
       mc.workcode,
       COUNT(*) AS qty
FROM meal_cons mc
WHERE mc.checktime >= :start_date
  AND mc.checktime <  :end_date_plus_1  -- exclusif
GROUP BY mc.userid, mc.workcode;
```

```sql
-- 2) Paramètres effectifs (override > global)
SELECT
  x.userid,
  x.workcode,
  x.qty,
  COALESCE(emr.custom_rate, ms.rate_meal)            AS rate,
  COALESCE(emr.custom_limit, ms.meal_limit)          AS lim,
  COALESCE(emr.custom_rate_after_limit, ms.rate_after_limit) AS rate_after
FROM (
  SELECT mc.userid, mc.workcode, COUNT(*) AS qty
  FROM meal_cons mc
  WHERE mc.checktime >= :start
    AND mc.checktime <  :end
  GROUP BY mc.userid, mc.workcode
) x
LEFT JOIN employee_meal_rate emr
  ON emr.userid = x.userid AND emr.workcode = x.workcode
LEFT JOIN meal_setting ms
  ON ms.workcode = x.workcode;
```

```sql
-- 3) Valorisation et totalisation
SELECT
  t.userid,
  SUM(
    CASE WHEN t.qty <= t.lim
         THEN t.rate * t.qty
         ELSE t.rate * t.lim + (t.qty - t.lim) * t.rate_after
    END
  ) AS total_deduction,
  JSON_OBJECTAGG(
    t.workcode,
    JSON_OBJECT(
      'qty', t.qty,
      'rate', t.rate,
      'limit', t.lim,
      'rate_after', t.rate_after,
      'cost', CASE WHEN t.qty <= t.lim
                   THEN t.rate * t.qty
                   ELSE t.rate * t.lim + (t.qty - t.lim) * t.rate_after
              END
    )
  ) AS breakdown
FROM (
  -- sous‑requête = sélection paramètres effectifs (cf. bloc précédent)
  SELECT
    x.userid,
    x.workcode,
    x.qty,
    COALESCE(emr.custom_rate, ms.rate_meal)             AS rate,
    COALESCE(emr.custom_limit, ms.meal_limit)           AS lim,
    COALESCE(emr.custom_rate_after_limit, ms.rate_after_limit) AS rate_after
  FROM (
    SELECT mc.userid, mc.workcode, COUNT(*) AS qty
    FROM meal_cons mc
    WHERE mc.checktime >= :start
      AND mc.checktime <  :end
    GROUP BY mc.userid, mc.workcode
  ) x
  LEFT JOIN employee_meal_rate emr
    ON emr.userid = x.userid AND emr.workcode = x.workcode
  LEFT JOIN meal_setting ms
    ON ms.workcode = x.workcode
) t
GROUP BY t.userid;
```

> Ces requêtes sont destinées au **service de reporting** (Express). Les résultats pourront être persistés dans `meal_salary` (selon fréquence) et/ou exportés.

---

## 4) Fréquences de Reporting & Calcul des Périodes

### 4.1) Sémantique

* **daily** : période = *hier* (ou *aujourd’hui* selon besoin) → `[D, D]`.
* **weekly** : période = semaine ISO (Lundi–Dimanche) contenant `next_run` ou basée sur `day_of_week`.
* **bi‑weekly** : blocs de 14 jours à partir de `anchor_date` (ex : 2025‑01‑01) → `[anchor + 14k, anchor + 14(k+1) - 1]`.
* **semi‑monthly** : `1–15` et `16–fin_de_mois`.
* **monthly** : `1–fin_de_mois`.
* **custom** : `start_date`–`end_date` fixés dans `report_schedule`.

### 4.2) Pseudocode (Node) — Résolution de période

```ts
function resolvePeriod(schedule: ReportSchedule, now = new Date()) {
  const tz = 'America/Port-au-Prince'; // cohérent avec l\'exploitation
  switch (schedule.type) {
    case 'daily': {
      const d = dayjs(now).tz(tz).subtract(1, 'day');
      const start = d.startOf('day');
      const end = d.endOf('day');
      return { start, end };
    }
    case 'weekly': {
      const base = dayjs(now).tz(tz).startOf('week'); // Lundi comme début
      const start = base.startOf('day');
      const end = base.add(6, 'day').endOf('day');
      return { start, end };
    }
    case 'bi-weekly': {
      const anchor = dayjs(schedule.anchor_date).tz(tz).startOf('day');
      const diff = dayjs(now).tz(tz).diff(anchor, 'day');
      const k = Math.floor(diff / 14);
      const start = anchor.add(k * 14, 'day');
      const end = start.add(13, 'day').endOf('day');
      return { start, end };
    }
    case 'semi-monthly': {
      const d = dayjs(now).tz(tz);
      const day = d.date();
      if (day <= 15) {
        return { start: d.date(1).startOf('day'), end: d.date(15).endOf('day') };
      } else {
        return { start: d.date(16).startOf('day'), end: d.endOf('month') };
      }
    }
    case 'monthly': {
      const d = dayjs(now).tz(tz);
      return { start: d.startOf('month'), end: d.endOf('month') };
    }
    case 'custom': {
      return { start: dayjs(schedule.start_date).startOf('day'), end: dayjs(schedule.end_date).endOf('day') };
    }
  }
}
```

---

## 5) Backend Express — Endpoints (proposition)

### 5.1) Auth

* `POST /api/auth/login` → { username, password } → {accessToken, role, employee_id }
* `GET /api/auth/me` → profil courant (JWT required)
* `POST /api/auth/logout` → invalider côté client (optionnel)

### 5.2) Paramètres

* `GET /api/meal/settings` — liste des `meal_setting`
* `POST /api/meal/settings` — créer/mettre à jour un setting (admin)
* `GET /api/meal/employee-rate/:userid` — overrides par employé
* `POST /api/meal/employee-rate` — créer/MAJ override (admin/manager)

### 5.3) Reporting

* `POST /api/report/preview` — calcule pour une période `{start,end}` sans persister
* `POST /api/report/run` — calcule & **persiste** (optionnellement enregistre export) pour `{start,end}`
* `GET /api/report/schedules` — lister
* `POST /api/report/schedules` — créer une planification
* `PATCH /api/report/schedules/:id` — MAJ planification (incl. email_enabled)
* `DELETE /api/report/schedules/:id` — supprimer
* `GET /api/report/logs` — suivre les exécutions

### 5.4) Self‑Service Employé

* `GET /api/me/consumption?start=YYYY-MM-DD&end=YYYY-MM-DD` — son détail valorisé (par workcode + total)
* `GET /api/me/snapshots?month=YYYY-MM` — snapshots mensuels (si `meal_salary` alimentée)

### 5.5) SMTP

* `POST /api/email/test` — envoi test (admin)

---

## 6) Service Scheduler — Cron + Envoi Email

### 6.1) Cron (node-cron)

* Job toutes les minutes :

  1. Charger les `report_schedule` actifs.
  2. Pour chacun : si `now >= next_run` ⇒ `resolvePeriod()` ⇒ calcul ⇒ export ⇒ email si `email_enabled=1` ⇒ MAJ `report_logs` + `next_run`.

### 6.2) Export (CSV par défaut)

* Générer `meal_report_YYYYMMDD_YYYYMMDD.csv` (ou `.xlsx/.pdf` selon `format`).
* Stocker le chemin (S3/local) dans `report_logs.file_path`.

### 6.3) Email (Nodemailer)

* Sujet = `report_schedule.email_subject`
* Corps = `email_body` (ou template par défaut)
* Pièce jointe = le fichier exporté
* Destinataires = `report_schedule_recipient` par `schedule_id`

---

## 7) Frontend — Pages & UX

### 7.1) Pages principales (Next.js App Router)

* `/login` — modal centré, **fond = logo company** (configuré via `app_settings.company_logo_url` ou `.env`)
* `/dashboard` — KPIs (repas/jour, top départements, déductions vs. mois dernier)
* `/settings/meal` — CRUD `meal_setting`
* `/settings/employee-rate` — overrides par employé
* `/reports/run` — exécution ad‑hoc (custom dates)
* `/reports/schedules` — gestion des planifications & destinataires
* `/me` — self‑service employé (consommation courante, historique, téléchargement)

### 7.2) Design System (Tailwind)

* Polices système, cards **rounded-2xl**, ombres douces, espacement généreux.
* Boutons primaires `rounded-2xl px-5 py-2`.
* Grilles 12 colonnes pour dashboards.

### 7.3) **Page Login** — Implémentation (Next.js + Tailwind)

> UI : background image = logo company en *cover*, overlay sombre, modal au centre.

```tsx
// app/login/page.tsx (Next.js 14, App Router)
'use client';
import { useState } from 'react';

export default function LoginPage() {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function onSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setLoading(true); setError(null);
    const formData = new FormData(e.currentTarget);
    const body = {
      username: formData.get('username'),
      password: formData.get('password')
    } as any;
    try {
      const res = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body)
      });
      if (!res.ok) throw new Error('Identifiants invalides');
      window.location.href = '/dashboard';
    } catch (err: any) {
      setError(err.message || 'Erreur de connexion');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="relative min-h-screen w-full">
      {/* Background = logo */}
      <div
        className="absolute inset-0 bg-center bg-no-repeat bg-cover"
        style={{ backgroundImage: 'url(' + (process.env.NEXT_PUBLIC_COMPANY_LOGO_URL || '/logo.png') + ')' }}
      />
      {/* Overlay sombre */}
      <div className="absolute inset-0 bg-black/50" />

      {/* Modal */}
      <div className="relative z-10 min-h-screen flex items-center justify-center p-4">
        <form onSubmit={onSubmit} className="w-full max-w-md bg-white/90 backdrop-blur rounded-2xl shadow-xl p-8">
          <h1 className="text-2xl font-semibold text-center mb-6">Connexion</h1>
          {error && (
            <div className="mb-4 text-sm text-red-600 bg-red-50 border border-red-200 rounded p-3">{error}</div>
          )}
          <label className="block text-sm font-medium mb-1">Utilisateur</label>
          <input
            name="username"
            type="text"
            className="w-full mb-4 rounded-xl border px-4 py-2 focus:outline-none focus:ring focus:ring-black/10"
            placeholder="ex: jdoe"
            required
          />

          <label className="block text-sm font-medium mb-1">Mot de passe</label>
          <input
            name="password"
            type="password"
            className="w-full mb-6 rounded-xl border px-4 py-2 focus:outline-none focus:ring focus:ring-black/10"
            placeholder="••••••••"
            required
          />

          <button
            type="submit"
            disabled={loading}
            className="w-full rounded-2xl bg-black text-white py-2.5 font-medium hover:opacity-90 transition disabled:opacity-60"
          >
            {loading ? 'Connexion...' : 'Se connecter'}
          </button>
        </form>
      </div>
    </div>
  );
}
```

**Tailwind config minimal**

```ts
// tailwind.config.ts
import type { Config } from 'tailwindcss';

export default {
  content: ['./app/**/*.{ts,tsx}', './components/**/*.{ts,tsx}'],
  theme: { extend: {} },
  plugins: [],
} satisfies Config;
```

**Env côté Next**

```
NEXT_PUBLIC_COMPANY_LOGO_URL=/logo.png
```

> Alternative : lire `COMPANY_LOGO_URL` depuis `app_settings` via un endpoint (`/api/app/settings`) et hydrater côté client.

---

## 8) Backend — Extraits de Code (TypeScript)

### 8.1) Auth — /api/auth/login

```ts
// src/routes/auth.ts
import { Router } from 'express';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';
import { db } from '../services/db';

const router = Router();

router.post('/login', async (req, res) => {
  const { username, password } = req.body;
  const [rows] = await db.query('SELECT * FROM `user` WHERE username=? LIMIT 1', [username]);
  const user = Array.isArray(rows) ? (rows as any[])[0] : null;
  if (!user) return res.status(401).json({ message: 'Invalid credentials' });
  const ok = await bcrypt.compare(password, user.password);
  if (!ok) return res.status(401).json({ message: 'Invalid credentials' });
  const token = jwt.sign({ sub: user.id, role: user.role, employee_id: user.employee_id }, process.env.JWT_SECRET!, { expiresIn: process.env.JWT_EXPIRES_IN || '3600s' });
  res.json({ accessToken: token, role: user.role, employee_id: user.employee_id });
});

export default router;
```

### 8.2) Reporting — calcul + export + email

```ts
// src/services/report.ts
import { db } from './db';
import { createTransport } from 'nodemailer';
import { writeFileSync } from 'fs';
import path from 'path';

export async function computeReport(start: string, end: string) {
  const [rows] = await db.query(/* sql */`
    SELECT
      t.userid,
      SUM(
        CASE WHEN t.qty <= t.lim
             THEN t.rate * t.qty
             ELSE t.rate * t.lim + (t.qty - t.lim) * t.rate_after
        END
      ) AS total_deduction
    FROM (
      SELECT
        x.userid,
        x.workcode,
        x.qty,
        COALESCE(emr.custom_rate, ms.rate_meal)             AS rate,
        COALESCE(emr.custom_limit, ms.meal_limit)           AS lim,
        COALESCE(emr.custom_rate_after_limit, ms.rate_after_limit) AS rate_after
      FROM (
        SELECT mc.userid, mc.workcode, COUNT(*) AS qty
        FROM meal_cons mc
        WHERE mc.checktime >= ? AND mc.checktime < ?
        GROUP BY mc.userid, mc.workcode
      ) x
      LEFT JOIN employee_meal_rate emr
        ON emr.userid = x.userid AND emr.workcode = x.workcode
      LEFT JOIN meal_setting ms
        ON ms.workcode = x.workcode
    ) t
    GROUP BY t.userid
  `, [start, end]);
  return rows as any[];
}

export async function exportCsv(rows: any[], start: string, end: string) {
  const header = 'userid,total_deduction\n';
  const body = rows.map(r => `${r.userid},${r.total_deduction}`).join('\n');
  const csv = header + body + '\n';
  const file = path.join(process.cwd(), 'exports', `meal_${start}_${end}.csv`);
  writeFileSync(file, csv);
  return file;
}

export async function sendEmail(filePath: string, to: string[], subject: string, html?: string) {
  const transporter = createTransport({
    host: process.env.SMTP_HOST,
    port: Number(process.env.SMTP_PORT || 465),
    secure: String(process.env.SMTP_SECURE || 'true') === 'true',
    auth: { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS }
  });
  await transporter.sendMail({
    from: process.env.SMTP_FROM,
    to: to.join(','),
    subject,
    html: html || '<p>Veuillez trouver ci-joint le rapport de repas.</p>',
    attachments: [{ filename: path.basename(filePath), path: filePath }]
  });
}
```

### 8.3) Scheduler — node-cron

```ts
// src/scheduler.ts
import cron from 'node-cron';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import tz from 'dayjs/plugin/timezone';
import { db } from './services/db';
import { computeReport, exportCsv, sendEmail } from './services/report';

dayjs.extend(utc); dayjs.extend(tz);
const TIMEZONE = 'America/Port-au-Prince';

cron.schedule('* * * * *', async () => {
  const now = dayjs().tz(TIMEZONE);
  const [schedules] = await db.query('SELECT * FROM report_schedule');
  for (const sch of schedules as any[]) {
    if (!sch.next_run || now.isBefore(dayjs(sch.next_run))) continue;
    const { start, end } = resolvePeriod(sch, now.toDate()); // implémenter selon §4.2
    try {
      const rows = await computeReport(start.format('YYYY-MM-DD 00:00:00'), end.add(1,'day').format('YYYY-MM-DD 00:00:00'));
      const file = await exportCsv(rows, start.format('YYYYMMDD'), end.format('YYYYMMDD'));

      // envoi email
      if (sch.email_enabled) {
        const [rcpts] = await db.query('SELECT email FROM report_schedule_recipient WHERE schedule_id=?', [sch.id]);
        const to = (rcpts as any[]).map(r => r.email);
        if (to.length) await sendEmail(file, to, sch.email_subject || 'Meal Report', sch.email_body || undefined);
      }

      // log OK
      await db.query('INSERT INTO report_logs (schedule_id, period_start, period_end, format, file_path, status) VALUES (?,?,?,?,?,?)', [
        sch.id, start.format('YYYY-MM-DD'), end.format('YYYY-MM-DD'), sch.format || 'csv', file, 'success'
      ]);

      // compute next_run (à implémenter selon type)
      const next = computeNextRun(sch, now);
      await db.query('UPDATE report_schedule SET last_run=?, next_run=? WHERE id=?', [now.format('YYYY-MM-DD HH:mm:ss'), next, sch.id]);
    } catch (e: any) {
      await db.query('INSERT INTO report_logs (schedule_id, period_start, period_end, status, error_message) VALUES (?,?,?,?,?)', [
        sch.id, start.format('YYYY-MM-DD'), end.format('YYYY-MM-DD'), 'error', e.message?.slice(0,2000) || String(e)
      ]);
    }
  }
});
```

---

## 9) Sécurité & Conformité

* **Hash** des mots de passe (bcrypt/argon2), jamais en clair.
* JWT signé avec `JWT_SECRET`. Limiter la durée (`JWT_EXPIRES_IN`).
* Rôles : `admin` (plein accès), `manager` (settings & reporting), `employee` (self‑service uniquement).
* Logging d’audit dans `logs` + `report_logs`.
* Sauvegardes exports (S3/Backblaze) et rétention configurable.

---

## 10) Arborescence Projet (Mise à jour)

```
/ (monorepo ou 2 repos)
├─ app/                 # Next.js (frontend)
│  ├─ app/login/page.tsx
│  ├─ app/dashboard/page.tsx
│  ├─ app/settings/meal/page.tsx
│  ├─ app/settings/employee-rate/page.tsx
│  ├─ app/reports/run/page.tsx
│  ├─ app/reports/schedules/page.tsx
│  ├─ app/me/page.tsx
│  ├─ components/
│  └─ public/logo.png
└─ api/                 # Express (backend)
   ├─ src/routes/auth.ts
   ├─ src/routes/report.ts
   ├─ src/services/db.ts
   ├─ src/services/report.ts
   ├─ src/scheduler.ts
   └─ exports/
```

---

## 11) Scénarios d’usage (gemini‑cli)

> **Intentions** pour guider un agent IA (scaffolding & codegen) :

* **Init Backend** : générer Express TS, `mysql2`, `node-cron`, `nodemailer`, endpoints §5, services §8, .env §1.1.
* **Init Frontend** : Next.js App Router, Tailwind, page login §7.3, pages dashboard & settings §7.1.
* **DB Migrations** : appliquer DDL §2.2.1 + existants.
* **Scheduler** : implémenter `resolvePeriod()` et `computeNextRun()` (suivant §4).
* **Exports** : CSV par défaut, hooks pour XLSX/PDF.
* **SMTP** : test endpoint `/api/email/test` & envoi planifié.
* **Self‑Service** : endpoint `/api/me/consumption` & page `/me` (graph par workcode, total déduction).

Prompts types :

```
- Génère l\'API /api/report/preview selon la requête SQL §3.3.
- Implémente computeNextRun() pour weekly/bi-weekly/semi-monthly (§4.1/4.2).
- Construit le tableau React (DataTable) pour /reports/schedules avec édition inline.
- Ajoute un export XLSX (sheetjs) dans exportCsv().
- Ajoute lecture de company_logo_url depuis app_settings côté /login.
```

---

## 12) Tests & Validation

* **Unit** : `computeReport()` avec cas limites (q=0, q=L, q>L, tarifs null/override).
* **Intégration** : scheduler → report_logs + fichier généré.
* **E2E** : login → run report custom → email reçu → téléchargement fichier.

---

## 13) Roadmap

* v1 : CSV + daily/weekly/monthly + SMTP
* v1.1 : bi‑weekly, semi‑monthly + export XLSX
* v1.2 : PDF branding + multi‑tenancy (ITXpress/clients)
* v2 : portail employé avancé (notifications, graphiques historiques)

---

## 14) Annexes

### 14.1) Exemples d’insertions

```sql
INSERT INTO app_settings (k, v) VALUES ('company_logo_url', '/logo.png')
ON DUPLICATE KEY UPDATE v=VALUES(v);

INSERT INTO report_schedule (name, type, email_enabled, email_subject, next_run)
VALUES ('Rapport quotidien', 'daily', 1, 'Rapport Quotidien Repas', NOW());

INSERT INTO report_schedule_recipient (schedule_id, email)
VALUES (1, 'rh@itxpress.us'), (1, 'manager@itxpress.us');
```

### 14.2) Exemples de `meal_setting`

```sql
INSERT INTO meal_setting (workcode, rate_meal, meal_limit, rate_after_limit)
VALUES (1, 2.00, 10, 5.00), (2, 3.00, 8, 6.00), (3, 2.50, 10, 5.00), (4, 4.00, 6, 7.00);
```

### 14.3) Notes d’implémentation bi‑weekly

* Choisir `anchor_date` (p. ex. 2025‑01‑01). Tous les intervalles sont `[anchor+14k, anchor+14(k+1)−1]`.
* `computeNextRun()` : ajouter 1× période (14 jours pour bi‑weekly) à partir de `next_run` courant.

---

## Project Status

This project is currently in the initial development phase. The basic structure for both the backend and frontend has been set up.

### Implemented Features

*   **Backend**:
    *   Express server setup with TypeScript.
    *   Database connection with `mysql2`.
    *   Authentication endpoint (`/api/auth/login`).
    *   Reporting service with `computeReport`, `exportCsv`, and `sendEmail` functions.
    *   Basic structure for reporting endpoints.
    *   Scheduler service with `node-cron`.
*   **Frontend**:
    *   Next.js setup with TypeScript and Tailwind CSS.
    *   Login page (`/login`).
    *   Dashboard page (`/dashboard`).
    *   Meal settings page (`/settings/meal`).
    *   Employee meal rate page (`/settings/employee-rate`).
    *   Run report page (`/reports/run`).
    *   Report schedules page (`/reports/schedules`).
    *   Employee self-service page (`/me`).

### Next Steps

*   **Backend**:
    *   Implement the missing endpoints in `api/src/routes/report.ts`.
    *   Implement the `computeNextRun()` function in `api/src/scheduler.ts`.
    *   Add more detailed error handling.
    *   Implement logging.
*   **Frontend**:
    *   Connect the pages to the backend API.
    *   Add forms for creating and editing data.
    *   Implement authentication and authorization.
    *   Improve the UI and UX.

---

Fin du document.
