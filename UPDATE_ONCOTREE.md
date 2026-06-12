# Updating OncoTree

Steps to refresh matchminer to the latest OncoTree release.

## 1. Download the flat TSV (deprecated API)

Use the OncoTree **deprecated** flat-file endpoint ([documented here](https://groups.google.com/g/oncotree-users/c/r9Rf_LzHe_0)):

```bash
curl -o oncotree_file.txt \
  "https://oncotree.mskcc.org/api/tumor_types.txt?version=oncotree_latest_stable"
```

To pin a specific release, replace `oncotree_latest_stable` (e.g. `oncotree_2021_11_02`). Browse versions at [oncotree.mskcc.org](https://oncotree.mskcc.org/).

Save the file as-is. `scratch.py` reads whatever `level_N` columns the TSV provides (the API may add more as the tree grows deeper).

## 2. Replace `oncotree_file.txt`

Copy the downloaded file to these locations in **matchminer-api**:

| Location | Purpose |
|---|---|
| `matchminer-api/data/oncotree_file.txt` | Production API (`ONCOTREE_CUSTOM_DIR` default) |
| `matchminer-api/tests/data/oncotree_file.txt` | Local Docker / tests (`docker-compose.yml`) |

matchengine-V2 is a separate GitHub repo. Update `matchengine/ref/oncotree_file.txt` in that repo and push your changes. matchminer-api pulls it via the git URL in `requirements.txt` when the Docker image is built (`pip install -r requirements.txt`).

## 3. Regenerate `oncotree_mapping.json`

matchengine-V2 uses the JSON mapping (not the TSV) at match time. From your matchengine-V2 clone:

```bash
cd matchengine-V2/matchengine
export ONCOTREE_TXT_FILE_PATH="/path/to/oncotree_file.txt"
python scratch.py
mv oncotree_mapping.json ref/oncotree_mapping.json
```

Commit and push the updated `ref/` files to the matchengine-V2 repo.

Output location:

| Location |
|---|
| `matchengine/ref/oncotree_mapping.json` |

Then bump the matchengine-V2 commit SHA in `matchminer-api/requirements.txt` (and `requirements.in` if used) and rebuild the Docker image so the new `ref/` files are picked up.

## 4. Verify and deploy

- Rebuild the Docker image and restart the API so it picks up the new TSV and matchengine-V2 ref files.
- Re-run matchengine / filters so matches use the new mapping.
- Spot-check the filter editor cancer-type autocomplete and a few known trial diagnoses.
