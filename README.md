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

`./setup.sh` launches all of the Docker containers. It also creates a seed MongoDB user. Set that user's details in `setup.sh`, and update `matchminer-ui/config.json`, before you run the script for production.

2. Update the ObjectId and token in the seed user in `setup.sh`:

   ```javascript
   "_id": ObjectId("insert-id-here")
   }, {
   "_id": ObjectId("insert-id-here"),
   "last_name" : "User",
   "teams" : [
     ObjectId("5a8ede8f4e0cce002dd5913c")
   ],
   "_updated" : ISODate("2018-02-22T10:15:27.000-05:00"),
   "first_name" : "Matchminer",
   "roles" : [
     "user",
     "cti",
     "oncologist",
     "admin"
   ],
   "title" : "",
   "email" : "fake_email@institution.edu",
   "_created" : ISODate("2018-02-22T10:15:27.000-05:00"),
   "user_name" : "matchmineruser",
   "token" : "insert-token-here",
   "oncore_token" : "5f3c2421-271c-41ba-ac14-899f214d49b9"
   }, { "upsert": true })
   ```

   Replace both `insert-id-here` values and `insert-token-here`. With `--dev true`, the script upserts this user into MongoDB.

3. Create the seed user id and token.

   **MongoDB id**

   Launch a basic MongoDB container only to generate an ObjectId. The container name can be anything:

   ```bash
   docker run -d --name mongo-objectid mongo
   docker exec -it mongo-objectid /bin/sh
   mongosh
   ObjectId()
   ```

   `ObjectId()` prints a value such as `ObjectId("64b7c2e1a9f04c0012ab34cd")`. Copy the 24-character hex string into both `_id` fields in the block above. Set the user's name there as well (`first_name`, `last_name`, and `user_name`).

   **Token**

   Generate a UUID:

   ```bash
   uuidgen
   ```

   Example: `6728e50a-2fb5-43b5-bbd6-a88ffb6ef0dc`

   Replace `insert-token-here` in `setup.sh` with that UUID. The `token` field on the user document is the UUID itself. Use this same UUID as `devUser.token` in `matchminer-ui/config.json` (step 4). The UI reads that value and sends `base64(uuid + ":")` on each request.

   Clients send that UUID as HTTP Basic auth, with an empty password. The header is `Authorization: Basic` plus the base64 encoding of `uuid + ":"`:

   ```text
   Authorization: Basic base64(uuid + ":")
   ```

   For the example UUID, the encoded value is `base64("6728e50a-2fb5-43b5-bbd6-a88ffb6ef0dc:")`.

   matchminer-api uses Eve `TokenAuth` (`matchminer/security.py`). Flask decodes the Basic header and `check_auth` receives the username, which is the UUID before the colon. The API then runs `db.user.find_one({'token': token})`. The same encoding is what the API tests send (`base64(f'{user_token}:')`) and what the UI request interceptor builds (`btoa(token + ':')`).

4. Update `matchminer-ui/config.json` before you run `./setup.sh`. Set the server name to the host that serves matchminer-api and matchminer-ui. These fields use that host:

   ```json
   "elasticsearch": {
     "proxy": "https://<server-name>:1952/api/es"
   },
   "api": {
     "host": "https://<server-name>:1952"
   },
   "linkToHomePage": "https://<server-name>:1952/"
   ```

   On the current deployment the server name is `dshihlab01.sbms.hku.hk`, so `proxy` is `https://dshihlab01.sbms.hku.hk:1952/api/es` and `api.host` is `https://dshihlab01.sbms.hku.hk:1952`.

   **devUser.** Set `token` to the UUID from `setup.sh` and `user_id` to that user's MongoDB ObjectId:

   ```json
   "devUser": {
     "token": "add-dev-user-token-here",
     "user_id": "add-dev-user-id-here"
   }
   ```

   **institution.** Set `resources.institution` to the name you want shown in the UI. This deployment uses `HKUMED`.

   **email.** Set `resources.email` to the address shown in the FAQ section.

   **linkToHomePage.** Use the same server name as `proxy` and `api.host`, for example `https://dshihlab01.sbms.hku.hk:1952/`.

5. From the `matchminer-setup` directory, run:

   ```bash
   ./setup.sh --dev true
   ```

   Use `--dev true` when you need the seeded MongoDB user. Otherwise run:

   ```bash
   ./setup.sh --dev false
   ```

This script will:

- Set `MATCHMINER_BUILD_PATH` to the current directory
- Start MongoDB and Elasticsearch
- With `--dev true`, upsert the seed user from `setup.sh` into the `user` collection
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
