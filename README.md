# matchminer-setup

This repository provides a combined setup to run [matchminer-ui](https://github.com/sumedhasaxena/matchminer-ui) and [matchminer-api](https://github.com/sumedhasaxena/matchminer-api). Both repositories are included as Git submodules.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) with Docker Compose v2 or later
- Git

## Clone the repository

Clone this repo together with its submodules:

```bash
git clone --recurse-submodules https://github.com/sumedhasaxena/matchminer-setup.git
cd matchminer-setup
```

If you already cloned the repo without submodules, initialize them with:

```bash
git submodule update --init --recursive
```

To pull the latest changes for the parent repo and all submodules:

```bash
git pull --recurse-submodules
```

---

## Production setup (API + UI)

Use this path when you want to run the full MatchMiner stack (MongoDB, Elasticsearch, API, and UI) from the root of this repository.

### First-time setup

1. Clone the repo with submodules (see above).
2. From the `matchminer-setup` directory, run:

   ```bash
   ./setup.sh --dev true
   ```

   Use `--dev true` if you need a seeded MongoDB user for local testing. Otherwise run:

   ```bash
   ./setup.sh --dev false
   ```

This script will:

- Set `MATCHMINER_BUILD_PATH` to the current directory
- Start MongoDB and Elasticsearch
- Configure Elasticsearch indexes and mappings
- Build and start **matchminer-api**
- Build and start **matchminer-ui**

The UI will be available at [http://localhost:1952/](http://localhost:1952/).

### Updating an existing installation

If you previously cloned the repo, pull the latest changes and re-run setup:

```bash
git pull --recurse-submodules
./setup.sh --dev false
```

Use `./setup.sh --dev true` instead if you need the seeded MongoDB user.

### Production SSL configuration (matchminer-ui)

The matchminer-ui submodule is forked from the DFCI codebase ([dfci/matchminer-ui](https://github.com/dfci/matchminer-ui)). For production deployments that terminate TLS in the UI container, configure SSL certificates before building.

**SSL certificates**

1. Navigate to `matchminer-setup/matchminer-ui/`.
2. Create a folder named `certificates` under `matchminer-setup/matchminer-ui/`.
3. Generate an SSL certificate and private key pair and place them inside the `certificates` folder.
4. Also place the certificate pair on the server hosting this application.

**Dockerfile update**

Update the Dockerfile under `matchminer-ui` to add SSL certificate paths:

```dockerfile
COPY certificates/my_ssl_cert.crt /etc/ssl/certs
COPY certificates/my_ssl_cert.key /etc/ssl/private
```

**Nginx configuration**

Update `nginx.conf` under `matchminer-ui` with the corresponding SSL settings for your certificate files.

---

## Development setup: matchminer-api

Use this path when you are developing against the API submodule only. This starts Elasticsearch, MongoDB, and the API in development mode. Also set up the local UI (see [Development setup: matchminer-ui](#development-setup-matchminer-ui)) if you need to add or update patient or trial data, or for general testing of the API.

### Steps

1. Clone the repo with submodules (see above).
2. Change directory to the `matchminer-api` submodule:

   ```bash
   cd matchminer-api
   ```

3. Run the setup script:

   ```bash
   ./setup.sh
   ```

This creates and runs Docker containers for:

| Service         | Description                          |
|-----------------|--------------------------------------|
| Elasticsearch   | Search index for MatchMiner          |
| MongoDB         | Primary data store                   |
| matchminer-api  | API server (development configuration) |

In development mode, when `setup.sh` under `matchminer-api` is executed, Docker builds the API container using **`Dockerfile-dev`**. This is different from the production setup for matchminer-api, which uses the standard **`Dockerfile`** (via the root `matchminer-setup` compose stack).

The **matchminer-api** container runs on port **5000** by default. After setup completes, the API is available at [http://localhost:5000](http://localhost:5000).

Once the matchminer-api development environment is set up with `setup.sh`, MongoDB starts empty except for one dummy user, **John Doe**, which is seeded to bypass authentication during local development.

### Running tests

With the API stack running, run tests inside the `mm-api` container with nosetests. For example, to run `test_negated_hormone_receptor_status`:

```bash
cd matchminer-api
docker compose exec mm-api nosetests -v tests/unit/test_api/test_trial.py:TestTrialValidation.test_negated_hormone_receptor_status
```

---

## Development setup: matchminer-ui

Use this path when you are developing against the UI submodule, or when you need to add or update patient or trial data, or for general testing of the API. **It is recommended to set up matchminer-api first** (see [Development setup: matchminer-api](#development-setup-matchminer-api)) so the UI can communicate with the API.

### Branch workflow

The `dev` branch of matchminer-ui contains the configuration needed to run the UI in this local development setup. The `master` branch does **not** include those local-dev changes.

All functional code changes go to `master`. Then merge `master` into `dev` (not the other way around) so the development configuration stays isolated on `dev` while still picking up the latest product changes.

### Steps

1. Clone the repo with submodules (see above).

2. Submodules are checked out at a specific commit (detached HEAD) by default. To use the development configuration for matchminer-ui, check out the `dev` branch:

   ```bash
   cd matchminer-ui
   git checkout dev
   ```

3. Return to the parent directory and set the build path environment variable:

   ```bash
   cd ..
   export MATCHMINER_BUILD_PATH=$(pwd)
   ```

4. Change directory to the `matchminer-ui` submodule and start the UI:

   ```bash
   cd matchminer-ui
   docker compose up --build -d
   ```

The UI runs on port **1952**. Open [http://localhost:1952/](http://localhost:1952/) in your browser.

If matchminer-api has already been set up using the steps above, matchminer-ui will be able to communicate with the API. The UI dev container connects to the Docker network created by the API dev stack (`matchminer-api_mm-dev-network`).

To add trial or patient data for testing in the local environment, use [matchminer-admin](https://github.com/sumedhasaxena/matchminer-admin). Follow that repository's steps for setting it up locally. Once set up, matchminer-admin is configured to post requests to [http://localhost:1952](http://localhost:1952/) for patient and trial data operations.

---

## Quick reference

| Environment | Location              | Command                              | UI URL                    | API URL                   |
|-------------|-----------------------|--------------------------------------|---------------------------|---------------------------|
| Production  | `matchminer-setup/`   | `./setup.sh --dev true\|false`       | http://localhost:1952     | (internal to Docker network) |
| API dev     | `matchminer-api/`     | `./setup.sh`                         | —                         | http://localhost:5000     |
| UI dev      | `matchminer-ui/`      | `docker compose up --build -d`       | http://localhost:1952     | http://localhost:5000 (if API dev is running) |
