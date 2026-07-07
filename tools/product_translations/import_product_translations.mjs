#!/usr/bin/env node
import fs from 'node:fs';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);

function loadFirebaseTools() {
  const roots = [
    'firebase-tools/lib',
    '/opt/homebrew/lib/node_modules/firebase-tools/lib',
    '/usr/local/lib/node_modules/firebase-tools/lib',
  ];

  for (const root of roots) {
    try {
      return {
        apiv2: require(`${root}/apiv2.js`),
        auth: require(`${root}/auth.js`),
      };
    } catch (_) {
      // Try next location.
    }
  }

  throw new Error(
    'firebase-tools introuvable. Installe Firebase CLI ou lance `npm install firebase-tools`.'
  );
}

function configureFirebaseCliAuth() {
  const { apiv2, auth } = loadFirebaseTools();
  const account = auth.getProjectDefaultAccount(process.cwd()) || auth.getGlobalDefaultAccount();
  const refreshToken = account?.tokens?.refresh_token;

  if (!refreshToken) {
    throw new Error('Firebase CLI non authentifiee. Lance `firebase login --reauth` puis reessaie.');
  }

  apiv2.setRefreshToken(refreshToken);
  return { apiv2, email: account.user?.email || 'compte Firebase CLI' };
}

const PROJECT_ID = process.env.FIREBASE_PROJECT_ID || 'veloria-f35fd';
const DATABASE_ID = process.env.FIRESTORE_DATABASE_ID || '(default)';
const COLLECTION = process.env.FIRESTORE_PRODUCTS_COLLECTION || 'products';
const TRANSLATION_FIELDS = [
  'title_en',
  'title_ar',
  'description_en',
  'description_ar',
  'usageTips_en',
  'usageTips_ar',
  'customBadge_en',
  'customBadge_ar',
];

function parseArgs() {
  const args = process.argv.slice(2);
  const csvPath = args.find((arg) => !arg.startsWith('--'));
  const fieldsArg = args.find((arg) => arg.startsWith('--fields='));
  const selectedFields = fieldsArg
    ? fieldsArg
        .slice('--fields='.length)
        .split(',')
        .map((field) => field.trim())
        .filter(Boolean)
    : TRANSLATION_FIELDS;

  const unknownFields = selectedFields.filter((field) => !TRANSLATION_FIELDS.includes(field));
  if (unknownFields.length) {
    throw new Error(`Champs non autorises: ${unknownFields.join(', ')}`);
  }

  return {
    csvPath,
    fields: selectedFields,
    dryRun: !args.includes('--commit'),
    clearEmpty: args.includes('--clear-empty'),
  };
}

function parseCsv(text) {
  const rows = [];
  let row = [];
  let cell = '';
  let inQuotes = false;

  for (let i = 0; i < text.length; i += 1) {
    const char = text[i];
    const next = text[i + 1];

    if (inQuotes) {
      if (char === '"' && next === '"') {
        cell += '"';
        i += 1;
      } else if (char === '"') {
        inQuotes = false;
      } else {
        cell += char;
      }
    } else if (char === '"') {
      inQuotes = true;
    } else if (char === ',') {
      row.push(cell);
      cell = '';
    } else if (char === '\n') {
      row.push(cell.replace(/\r$/, ''));
      rows.push(row);
      row = [];
      cell = '';
    } else {
      cell += char;
    }
  }

  if (cell.length || row.length) {
    row.push(cell.replace(/\r$/, ''));
    rows.push(row);
  }

  const header = rows.shift() || [];
  return rows
    .filter((values) => values.some((value) => value.trim() !== ''))
    .map((values) => Object.fromEntries(header.map((key, index) => [key, values[index] || ''])));
}

function encodeValue(value) {
  return { stringValue: value };
}

function updateMask(fields) {
  return fields.map((field) => `updateMask.fieldPaths=${encodeURIComponent(field)}`).join('&');
}

async function patchProduct(accessToken, id, fields) {
  const qs = updateMask(Object.keys(fields));
  const url = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/${DATABASE_ID}/documents/${COLLECTION}/${encodeURIComponent(id)}?${qs}`;
  const body = {
    fields: Object.fromEntries(Object.entries(fields).map(([key, value]) => [key, encodeValue(value)])),
  };

  const res = await fetch(url, {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });

  if (!res.ok) {
    const errorBody = await res.text();
    throw new Error(`Update failed for ${id} (${res.status}): ${errorBody}`);
  }
}

async function main() {
  const { csvPath, fields, dryRun, clearEmpty } = parseArgs();
  if (!csvPath) {
    console.error('Usage: node tools/product_translations/import_product_translations.mjs <products.translation.csv> [--commit] [--clear-empty] [--fields=description_en,description_ar]');
    console.error('Par defaut: dry-run, aucune ecriture Firebase. Ajoute --commit pour ecrire.');
    process.exit(1);
  }

  const rows = parseCsv(fs.readFileSync(csvPath, 'utf8'));
  const updates = [];

  for (const row of rows) {
    const id = (row.id || '').trim();
    if (!id) continue;

    const updateFields = {};
    for (const field of fields) {
      const value = row[field] ?? '';
      if (value.trim() || clearEmpty) updateFields[field] = value.trim();
    }

    if (Object.keys(updateFields).length) updates.push({ id, fields: updateFields });
  }

  console.log(`${dryRun ? 'DRY-RUN' : 'COMMIT'}: ${updates.length} produits a mettre a jour`);
  console.log(`Champs autorises: ${fields.join(', ')}`);
  for (const update of updates.slice(0, 10)) {
    console.log(`- ${update.id}: ${Object.keys(update.fields).join(', ')}`);
  }
  if (updates.length > 10) console.log(`... +${updates.length - 10} autres`);

  if (dryRun) {
    console.log('\nAucune ecriture faite. Relance avec --commit pour importer.');
    return;
  }

  const { apiv2, email } = configureFirebaseCliAuth();
  const accessToken = await apiv2.getAccessToken();
  console.log(`Compte Firebase CLI: ${email}`);

  for (const update of updates) {
    await patchProduct(accessToken, update.id, update.fields);
  }

  console.log(`Import termine: ${updates.length} produits mis a jour.`);
}

main().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
