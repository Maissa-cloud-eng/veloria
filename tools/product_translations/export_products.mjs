#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
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
const OUT_ROOT = process.env.PRODUCT_TRANSLATION_EXPORT_DIR || 'exports/product-translations';

const CSV_COLUMNS = [
  'id',
  'brand',
  'title',
  'title_en',
  'title_ar',
  'description',
  'description_en',
  'description_ar',
  'usageTips',
  'usageTips_en',
  'usageTips_ar',
  'customBadge',
  'customBadge_en',
  'customBadge_ar',
  'category',
  'subCategory',
  'tags',
];

function timestampSlug() {
  return new Date().toISOString().replace(/[:.]/g, '-');
}

function decodeValue(value) {
  if (!value || typeof value !== 'object') return null;
  if ('stringValue' in value) return value.stringValue;
  if ('integerValue' in value) return Number(value.integerValue);
  if ('doubleValue' in value) return Number(value.doubleValue);
  if ('booleanValue' in value) return Boolean(value.booleanValue);
  if ('timestampValue' in value) return value.timestampValue;
  if ('nullValue' in value) return null;
  if ('arrayValue' in value) {
    return (value.arrayValue.values || []).map(decodeValue);
  }
  if ('mapValue' in value) {
    const out = {};
    const fields = value.mapValue.fields || {};
    for (const [key, child] of Object.entries(fields)) out[key] = decodeValue(child);
    return out;
  }
  if ('geoPointValue' in value) return value.geoPointValue;
  if ('referenceValue' in value) return value.referenceValue;
  return value;
}

function decodeDocument(doc) {
  const id = doc.name.split('/').pop();
  const data = { id };
  for (const [key, value] of Object.entries(doc.fields || {})) {
    data[key] = decodeValue(value);
  }
  return data;
}

function csvCell(value) {
  if (value === undefined || value === null) return '';
  let text;
  if (Array.isArray(value)) text = value.join('; ');
  else if (typeof value === 'object') text = JSON.stringify(value);
  else text = String(value);
  return /[",\n\r;]/.test(text) ? `"${text.replaceAll('"', '""')}"` : text;
}

function toCsv(rows) {
  const lines = [CSV_COLUMNS.join(',')];
  for (const row of rows) {
    lines.push(CSV_COLUMNS.map((col) => csvCell(row[col])).join(','));
  }
  return `${lines.join('\n')}\n`;
}

async function fetchProducts(accessToken) {
  const products = [];
  let pageToken = '';

  do {
    const url = new URL(
      `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/${DATABASE_ID}/documents/${COLLECTION}`
    );
    url.searchParams.set('pageSize', '300');
    if (pageToken) url.searchParams.set('pageToken', pageToken);

    const res = await fetch(url, {
      headers: { Authorization: `Bearer ${accessToken}` },
    });

    if (!res.ok) {
      const body = await res.text();
      throw new Error(`Firestore export failed (${res.status}): ${body}`);
    }

    const payload = await res.json();
    for (const doc of payload.documents || []) products.push(decodeDocument(doc));
    pageToken = payload.nextPageToken || '';
  } while (pageToken);

  products.sort((a, b) => String(a.title || '').localeCompare(String(b.title || ''), 'fr'));
  return products;
}

async function main() {
  const { apiv2, email } = configureFirebaseCliAuth();
  const accessToken = await apiv2.getAccessToken();
  console.log(`Compte Firebase CLI: ${email}`);

  const products = await fetchProducts(accessToken);
  const outDir = path.join(OUT_ROOT, timestampSlug());
  fs.mkdirSync(outDir, { recursive: true });

  const backupPath = path.join(outDir, 'products.backup.json');
  const csvPath = path.join(outDir, 'products.translation.csv');
  const metaPath = path.join(outDir, 'README.txt');

  fs.writeFileSync(
    backupPath,
    JSON.stringify(
      {
        exportedAt: new Date().toISOString(),
        projectId: PROJECT_ID,
        databaseId: DATABASE_ID,
        collection: COLLECTION,
        count: products.length,
        products,
      },
      null,
      2
    )
  );

  fs.writeFileSync(csvPath, toCsv(products));
  fs.writeFileSync(
    metaPath,
    [
      'Export produits Veloria',
      `Projet: ${PROJECT_ID}`,
      `Collection: ${COLLECTION}`,
      `Produits: ${products.length}`,
      '',
      'Fichiers:',
      '- products.backup.json : backup complet lisible avant import',
      '- products.translation.csv : fichier de travail pour les traductions arabes',
      '',
      'Colonnes arabes à remplir/corriger:',
      '- title_ar',
      '- description_ar',
      '- usageTips_ar',
      '- customBadge_ar',
      '',
      'L’import sécurisé ne mettra à jour que ces colonnes arabes.',
      '',
    ].join('\n')
  );

  console.log(`Export terminé: ${products.length} produits`);
  console.log(`Backup JSON: ${backupPath}`);
  console.log(`CSV: ${csvPath}`);
}

main().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
