#!/usr/bin/env node
// atlas-sync — pousse le manifeste `atlas.json` de CE projet vers une instance Atlas.
// Idempotent : crée le projet s'il n'existe pas (mappé par slug), sinon met à jour.
//
// Pré-requis (variables d'env, à garder secrètes — pas dans le git) :
//   ATLAS_URL    ex: http://tower:3939
//   ATLAS_TOKEN  le ATLAS_API_TOKEN de ton instance
//
// Usage :  node scripts/atlas-sync.mjs [chemin/vers/atlas.json]
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

const url = process.env.ATLAS_URL;
const token = process.env.ATLAS_TOKEN;
if (!url || !token) {
  console.error("✖ ATLAS_URL et ATLAS_TOKEN sont requis (variables d'env).");
  process.exit(1);
}

const file = process.argv[2] || "atlas.json";
let manifest;
try {
  manifest = JSON.parse(readFileSync(resolve(file), "utf8"));
} catch (e) {
  console.error(`✖ Lecture de ${file} impossible : ${e.message}`);
  process.exit(1);
}

const slug = manifest.slug;
if (!slug) {
  console.error('✖ Le manifeste doit contenir un "slug" (clé de mapping vers Atlas).');
  process.exit(1);
}

const res = await fetch(`${url.replace(/\/$/, "")}/api/projects/${encodeURIComponent(slug)}`, {
  method: "PUT",
  headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
  body: JSON.stringify(manifest),
});

const body = await res.json().catch(() => ({}));
if (!res.ok) {
  console.error(`✖ Échec (HTTP ${res.status}) :`, JSON.stringify(body));
  process.exit(1);
}
console.log(`✓ ${body.created ? "créé" : "synchronisé"} : ${slug}`, JSON.stringify(body.summary ?? {}));
