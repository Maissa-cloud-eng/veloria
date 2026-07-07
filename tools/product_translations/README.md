# Product Translation Export/Import

Ces scripts servent a preparer les traductions produits Veloria et a importer les champs multilingues.

## 1. Export avec backup

```bash
node tools/product_translations/export_products.mjs
```

Le script cree un dossier dans `exports/product-translations/<date>/` avec :

- `products.backup.json` : backup complet des documents produits exportes.
- `products.translation.csv` : fichier CSV a ouvrir dans Excel/Google Sheets.

## 2. Colonnes a remplir

Dans le CSV, remplir/corriger seulement les champs de traduction :

- `title_en`
- `title_ar`
- `description_en`
- `description_ar`
- `usageTips_en`
- `usageTips_ar`
- `customBadge_en`
- `customBadge_ar`

Ne modifie pas la colonne `id`.

## 3. Verification import sans ecriture

```bash
node tools/product_translations/import_product_translations.mjs exports/product-translations/<date>/products.translation.csv
```

Par defaut c'est un dry-run : aucune ecriture Firebase.

## 4. Import reel

```bash
node tools/product_translations/import_product_translations.mjs exports/product-translations/<date>/products.translation.csv --commit
```

L'import ne met a jour que les champs de traduction produits : `title_en`, `title_ar`, `description_en`, `description_ar`, `usageTips_en`, `usageTips_ar`, `customBadge_en`, `customBadge_ar`.

## Options

Importer seulement certains champs :

```bash
node tools/product_translations/import_product_translations.mjs exports/product-translations/<date>/products.translation.csv --fields=description_en,description_ar
```

Ajouter `--clear-empty` seulement si tu veux vider explicitement des champs existants.

## Ancien import arabe seul

`import_product_ar_translations.mjs` est garde pour un import limite aux champs arabes uniquement.


## Reecriture des descriptions FR

Avant de traduire en anglais/arabe, on peut simplifier les descriptions FR dans un format marketing scannable.

### Export de travail + backup

```bash
node tools/product_translations/prepare_description_rewrite_csv.mjs
```

Le script cree :

- `products.before-description-rewrite.backup.json` : backup complet avant reecriture.
- `products.description-rewrite.csv` : fichier de travail.

Dans le CSV, remplir uniquement `description_new_fr`.

### Dry-run import FR

```bash
node tools/product_translations/import_description_rewrite_fr.mjs exports/product-translations/<date>/products.description-rewrite.csv
```

### Import reel FR

```bash
node tools/product_translations/import_description_rewrite_fr.mjs exports/product-translations/<date>/products.description-rewrite.csv --commit
```

Cet import ne modifie que `description` et `updatedAt` pour les lignes ou `description_new_fr` est rempli.
