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
    } catch (_) {}
  }
  throw new Error('firebase-tools introuvable.');
}

function configureFirebaseCliAuth() {
  const { apiv2, auth } = loadFirebaseTools();
  const account = auth.getProjectDefaultAccount(process.cwd()) || auth.getGlobalDefaultAccount();
  const refreshToken = account?.tokens?.refresh_token;
  if (!refreshToken) throw new Error('Firebase CLI non authentifiee. Lance `firebase login --reauth`.');
  apiv2.setRefreshToken(refreshToken);
  return { apiv2, email: account.user?.email || 'compte Firebase CLI' };
}

const PROJECT_ID = process.env.FIREBASE_PROJECT_ID || 'veloria-f35fd';
const DATABASE_ID = process.env.FIRESTORE_DATABASE_ID || '(default)';
const COLLECTION = process.env.FIRESTORE_PRODUCTS_COLLECTION || 'products';
const OUT_ROOT = process.env.PRODUCT_DESCRIPTION_REWRITE_DIR || 'exports/product-translations';
const COLUMNS = [
  'id', 'brand', 'title', 'category', 'subCategory',
  'description_current_fr', 'description_new_fr',
  'description_en', 'description_ar',
  'usageTips', 'usageTips_en', 'usageTips_ar'
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
  if ('arrayValue' in value) return (value.arrayValue.values || []).map(decodeValue);
  if ('mapValue' in value) {
    const out = {};
    for (const [key, child] of Object.entries(value.mapValue.fields || {})) out[key] = decodeValue(child);
    return out;
  }
  return value;
}

function decodeDocument(doc) {
  const id = doc.name.split('/').pop();
  const data = { id };
  for (const [key, value] of Object.entries(doc.fields || {})) data[key] = decodeValue(value);
  return data;
}

function csvCell(value) {
  if (value === undefined || value === null) return '';
  const text = Array.isArray(value) ? value.join('; ') : typeof value === 'object' ? JSON.stringify(value) : String(value);
  return /[",\n\r;]/.test(text) ? `"${text.replaceAll('"', '""')}"` : text;
}

function toCsv(rows) {
  return `${[COLUMNS.join(','), ...rows.map((row) => COLUMNS.map((col) => csvCell(row[col])).join(','))].join('\n')}\n`;
}

async function fetchProducts(accessToken) {
  const products = [];
  let pageToken = '';
  do {
    const url = new URL(`https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/${DATABASE_ID}/documents/${COLLECTION}`);
    url.searchParams.set('pageSize', '300');
    if (pageToken) url.searchParams.set('pageToken', pageToken);
    const res = await fetch(url, { headers: { Authorization: `Bearer ${accessToken}` } });
    if (!res.ok) throw new Error(`Firestore read failed ${res.status}: ${await res.text()}`);
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

  const backupPath = path.join(outDir, 'products.before-description-rewrite.backup.json');
  const csvPath = path.join(outDir, 'products.description-rewrite.csv');
  const rows = products.map((p) => ({
    id: p.id,
    brand: p.brand || '',
    title: p.title || '',
    category: p.category || '',
    subCategory: p.subCategory || '',
    description_current_fr: p.description || '',
    description_new_fr: '',
    description_en: p.description_en || '',
    description_ar: p.description_ar || '',
    usageTips: p.usageTips || '',
    usageTips_en: p.usageTips_en || '',
    usageTips_ar: p.usageTips_ar || '',
  }));

  fs.writeFileSync(backupPath, JSON.stringify({ exportedAt: new Date().toISOString(), projectId: PROJECT_ID, collection: COLLECTION, count: products.length, products }, null, 2));
  fs.writeFileSync(csvPath, toCsv(rows));
  fs.writeFileSync(path.join(outDir, 'README-description-rewrite.txt'), [
    'Fichier de reecriture FR des descriptions Veloria',
    '',
    'Remplir uniquement la colonne description_new_fr.',
    'Ne pas modifier id.',
    'L import securise ne modifie que le champ Firestore description.',
    'Il ignore les lignes ou description_new_fr est vide.',
    '',
    'Ordre recommande:',
    '1. Recrire description_new_fr en format marketing scannable.',
    '2. Importer description_new_fr vers description apres validation.',
    '3. Re-exporter puis traduire vers description_en et description_ar.',
    '',
  ].join('\n'));
  console.log(`Export descriptions: ${products.length} produits`);
  console.log(`Backup JSON: ${backupPath}`);
  console.log(`CSV travail: ${csvPath}`);
}

main().catch((err) => { console.error(err.message || err); process.exit(1); });
