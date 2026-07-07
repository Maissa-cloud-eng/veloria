#!/usr/bin/env node
import fs from 'node:fs';
import { createRequire } from 'node:module';
const require = createRequire(import.meta.url);

function loadFirebaseTools() {
  const roots = ['firebase-tools/lib', '/opt/homebrew/lib/node_modules/firebase-tools/lib', '/usr/local/lib/node_modules/firebase-tools/lib'];
  for (const root of roots) {
    try { return { apiv2: require(`${root}/apiv2.js`), auth: require(`${root}/auth.js`) }; } catch (_) {}
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

function parseCsv(text) {
  const rows = [];
  let row = [], cell = '', inQuotes = false;
  for (let i = 0; i < text.length; i++) {
    const char = text[i], next = text[i + 1];
    if (inQuotes) {
      if (char === '"' && next === '"') { cell += '"'; i++; }
      else if (char === '"') inQuotes = false;
      else cell += char;
    } else if (char === '"') inQuotes = true;
    else if (char === ',') { row.push(cell); cell = ''; }
    else if (char === '\n') { row.push(cell.replace(/\r$/, '')); rows.push(row); row = []; cell = ''; }
    else cell += char;
  }
  if (cell.length || row.length) { row.push(cell.replace(/\r$/, '')); rows.push(row); }
  const header = rows.shift() || [];
  return rows.filter((values) => values.some((v) => v.trim())).map((values) => Object.fromEntries(header.map((key, i) => [key, values[i] || ''])));
}

function args() {
  const raw = process.argv.slice(2);
  return { csvPath: raw.find((a) => !a.startsWith('--')), dryRun: !raw.includes('--commit') };
}

async function patchDescription(accessToken, id, description) {
  const url = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/${DATABASE_ID}/documents/${COLLECTION}/${encodeURIComponent(id)}?updateMask.fieldPaths=description&updateMask.fieldPaths=updatedAt`;
  const body = { fields: { description: { stringValue: description }, updatedAt: { timestampValue: new Date().toISOString() } } };
  const res = await fetch(url, { method: 'PATCH', headers: { Authorization: `Bearer ${accessToken}`, 'Content-Type': 'application/json' }, body: JSON.stringify(body) });
  if (!res.ok) throw new Error(`Update failed for ${id} (${res.status}): ${await res.text()}`);
}

async function main() {
  const { csvPath, dryRun } = args();
  if (!csvPath) {
    console.error('Usage: node tools/product_translations/import_description_rewrite_fr.mjs <products.description-rewrite.csv> [--commit]');
    process.exit(1);
  }
  const rows = parseCsv(fs.readFileSync(csvPath, 'utf8'));
  const updates = rows.map((r) => ({ id: (r.id || '').trim(), description: (r.description_new_fr || '').trim() })).filter((u) => u.id && u.description);
  console.log(`${dryRun ? 'DRY-RUN' : 'COMMIT'}: ${updates.length} descriptions FR a mettre a jour`);
  for (const update of updates.slice(0, 10)) console.log(`- ${update.id}: ${update.description.slice(0, 80).replace(/\n/g, ' ')}...`);
  if (updates.length > 10) console.log(`... +${updates.length - 10} autres`);
  if (dryRun) { console.log('\nAucune ecriture faite. Relance avec --commit pour importer.'); return; }
  const { apiv2, email } = configureFirebaseCliAuth();
  const accessToken = await apiv2.getAccessToken();
  console.log(`Compte Firebase CLI: ${email}`);
  for (const update of updates) await patchDescription(accessToken, update.id, update.description);
  console.log(`Import termine: ${updates.length} descriptions mises a jour.`);
}

main().catch((err) => { console.error(err.message || err); process.exit(1); });
