# Updating OncoTree

Steps to refresh matchminer to the latest OncoTree release.

## 1. Export and build in matchengine-V2

All OncoTree data changes live in the **matchengine-V2** repo. From your clone:

```bash
cd matchengine-V2/matchengine

# Export normalized TSV from /api/tumorTypes (write straight to ref/)
python3 export_oncotree_tsv.py \
  --version oncotree_latest_stable \
  -o ref/oncotree_file.txt

# Generate mapping JSON for matchengine matching
export ONCOTREE_TXT_FILE_PATH="$(pwd)/ref/oncotree_file.txt"
python3 scratch.py
mv oncotree_mapping.json ref/oncotree_mapping.json
```

To pin a specific OncoTree release, replace `oncotree_latest_stable` (e.g. `oncotree_2025_10_03`). Browse versions at [oncotree.mskcc.org](https://oncotree.mskcc.org/).
Currently, version oncotree_2025_10_03 is being used.

`export_oncotree_tsv.py` sets the number of `level_N` columns to the max tree depth from the API (no trailing blank columns).

**Do not** use the deprecated `tumor_types.txt` API (`curl .../api/tumor_types.txt`). That format shifts metadata into `level_N` columns and will produce a bad mapping if fed to `scratch.py`.

Files updated in matchengine-V2:

| File | Purpose |
|---|---|
| `matchengine/ref/oncotree_mapping.json` | **Required** — diagnosis expansion mapping used at match time |
| `matchengine/ref/oncotree_file.txt` | Optional — kept in repo as source input for re-running `scratch.py` |

## 2. Commit matchengine-V2 once

Stage all OncoTree-related changes and commit in a **single** matchengine-V2 commit and note the new new commit hash:

```bash
git rev-parse HEAD
```

## 3. Bump matchengine-V2 in matchminer-api

Update **both** files with the commit hash from step 2:

**`matchminer-api/requirements.in`**

```
git+https://github.com/sumedhasaxena/matchengine-V2.git@<COMMIT_HASH>
```

**`matchminer-api/requirements.txt`** — update the `matchengine-v2 @ git+...` line to the same hash.

Then copy the exported TSV into matchminer-api (used by the API filter editor and `ONCOTREE_CUSTOM_DIR`):

| Location | Purpose |
|---|---|
| `matchminer-api/data/oncotree_file.txt` | Production API default |
| `matchminer-api/tests/data/oncotree_file.txt` | Local Docker / tests (`docker-compose.yml`) |

Copy from `matchengine-V2/matchengine/ref/oncotree_file.txt` (or re-export directly to those paths).

## 4. Verify and deploy

- Rebuild the Docker image (`pip install -r requirements.txt` picks up the new matchengine-V2 hash).
- Restart the API.