<!-- atlas-snippet-hash:d5b214dc4e9c — section gérée automatiquement. Ne pas éditer manuellement.
     Pour mettre à jour : curl -s $ATLAS_URL/api/snippet > /tmp/snippet.md et remplace ce bloc. -->

## Atlas — control plane perso

Ce projet est catalogué dans **Atlas** (`atlas.json` à la racine, champ `slug` = clé de mapping).

---

### Mise à jour du snippet (à faire en début de session si Atlas est configuré)

```bash
source .env 2>/dev/null
CURRENT_HASH=$(grep -o 'atlas-snippet-hash:[a-f0-9]*' CLAUDE.md 2>/dev/null | cut -d: -f2)
REMOTE_HASH=$(curl -s "$ATLAS_URL/api/snippet?hash=1" | python3 -c "import json,sys; print(json.load(sys.stdin)['hash'])" 2>/dev/null)
[ -n "$REMOTE_HASH" ] && [ "$CURRENT_HASH" != "$REMOTE_HASH" ] && echo "SNIPPET PÉRIMÉ — mets à jour : curl -s $ATLAS_URL/api/snippet"
```

Si le hash diffère : télécharge `$ATLAS_URL/api/snippet` et remplace la section `<!-- atlas-snippet … -->` dans ce fichier.

---

### Setup (première fois — fais-le une fois, ne redemande pas)

**Étape 1 — vérifier / sauvegarder le token**

```bash
echo "ATLAS_URL=${ATLAS_URL:-<manquant>}  ATLAS_TOKEN=${ATLAS_TOKEN:0:12}…"
```

Si manquant : variables dans `.env` (déjà configuré, ne pas committer).

**Étape 2 — sync automatique en fin de session**

Hook configuré dans `.claude/settings.json` — sync `atlas.json` à chaque fin de session.

**Étape 3 — vérifier la connexion**

```bash
source .env
curl -s "$ATLAS_URL/api/projects/dev-tools-container" \
  -H "Authorization: Bearer $ATLAS_TOKEN" | python3 -c "import json,sys; p=json.load(sys.stdin); print(p['name'], '—', p['status'])"
```

---

### Usage courant

**Sync manuel** :

```bash
source .env
curl -s -X PUT "$ATLAS_URL/api/projects/dev-tools-container" \
  -H "Authorization: Bearer $ATLAS_TOKEN" -H "Content-Type: application/json" -d @atlas.json
```

**Mettre à jour le suivi** :

```bash
source .env
# Statut courant
curl -s -X PATCH "$ATLAS_URL/api/projects/dev-tools-container" \
  -H "Authorization: Bearer $ATLAS_TOKEN" -H "Content-Type: application/json" \
  -d '{"currentStatus": "…"}'

# Journal (kind : feat | fix | deploy | release | note | chore)
curl -s -X POST "$ATLAS_URL/api/projects/dev-tools-container/log" \
  -H "Authorization: Bearer $ATLAS_TOKEN" -H "Content-Type: application/json" \
  -d '{"kind": "feat", "title": "…"}'
```

**Features (kanban)** :

```bash
source .env
# Lire
curl -s "$ATLAS_URL/api/projects/dev-tools-container" \
  -H "Authorization: Bearer $ATLAS_TOKEN" | python3 -c \
  "import json,sys; p=json.load(sys.stdin); [print(f['status'].upper(), f['title'], f['id']) for f in p.get('features',[])]"

# Créer (status : idea | planned | active | paused | done)
curl -s -X POST "$ATLAS_URL/api/projects/dev-tools-container/features" \
  -H "Authorization: Bearer $ATLAS_TOKEN" -H "Content-Type: application/json" \
  -d '{"title": "…", "description": "…", "status": "active"}'

# Mettre à jour
curl -s -X PATCH "$ATLAS_URL/api/children/feature/<FEATURE_ID>" \
  -H "Authorization: Bearer $ATLAS_TOKEN" -H "Content-Type: application/json" \
  -d '{"status": "done"}'
```

> **Règle** : si une feature est `active` en début de session, travaille en référence à elle.
> Mets-la à `done` quand terminée. Crée une feature pour tout nouveau chantier significatif.
