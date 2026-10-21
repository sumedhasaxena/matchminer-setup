# Restoring MongoDB Data for a New User

This guide is for a new Linux user on the same server who will run the same `docker-compose.yml` (4 containers: `mongo`, `elasticsearch`, `matchminer-api`, `matchminer-ui`) using rootless Docker. It explains how to restore the exported MongoDB backup (`mongo-backup.gz`) into the new user's Mongo container and ensure the data persists in the named volume `matchminer_data`.

### Assumptions

1. MongoDB backup was creating with the command: 

`mongodump --archive --gzip` and is placed at /data3/mm_mongo/mongo-backup.gz on the same server.

2. The service name for mongo in docker-compose.yaml is `mongo`.
3. The volume name for mongo service in docker-compose.yaml is `matchminer_data`

---
## Step 1 — Start only Mongo and confirm the volume

From the project directory:

```bash
cd <project directory>
docker compose up -d mongo
```

Confirm that the container is running and that the volume is correctly mounted:

```bash
docker compose ps
docker volume ls | grep matchminer_data
```

As long as the service name in docker-compose.yml remains mongo, the container will automatically mount matchminer_data:/data/db at startup.

## Step 2 — Copy the backup file into the container
Assuming the backup is at /data3/mm_mongo/mongo-backup.gz on the host:

```bash
docker compose cp /data3/mm_mongo/mongo-backup.gz mongo:/tmp/mongo-backup.gz
```

## Step 3 — Restore the data inside the container
The mongo image is mongo:6.0-focal, which includes mongorestore.

```bash
docker compose exec mongo mongorestore --gzip --archive=/tmp/mongo-backup.gz
```

## Step 4 — Verify the restored data
Check the databases and collections:

```bash
docker compose exec mongo mongosh matchminer --eval 'db.getCollectionNames()'
```

Confirm the data is stored in the persistent volume (not just the container layer):

```bash
docker volume inspect <project_name>_matchminer_data
```

The Mountpoint field shows the actual storage path on the host (under the new user's home directory in rootless Docker).


## Step 5 — Clean up the backup file inside the container
```bash
docker compose exec mongo rm /tmp/mongo-backup.gz
```

## Step 6 — Start the full stack
Run the startup script (setup.sh) normally. The script's docker compose up -d mongo elasticsearch will reuse the existing volume and will not overwrite the restored data.

```bash
./setup.sh --dev true
```

Persistence rules (important)
The data persists because of the named volume matchminer_data defined in docker-compose.yml. Do not remove or rename it.

To stop the stack, use:

```bash
docker compose down
```

Do NOT use docker compose down -v — the -v flag deletes named volumes, which will destroy the restored MongoDB data.
