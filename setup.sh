#!/usr/bin/env bash

# Set up a local development mongo/mongo-connector/elasticsearch environment.
set -e

 case "$(docker compose version)" in
   *docker\ compose\ version\ 1*)
     # docker-compose exec sometimes breaks in v1
     echo "Requires docker-compose version 2 or greater."
     exit 1
     ;;
 esac

DEV_MODE=false

# Check if the first argument is provided
if [[ "$#" -eq 0 ]]; then
    echo "Usage: $0 --dev <true/false>"
    exit 1
fi

# Check if the first argument is --dev
if [[ "$1" == "--dev" ]]; then
    DEV_MODE="$2"
else
    echo "Unknown parameter passed: $1"
    exit 1
fi

export MATCHMINER_BUILD_PATH=$(pwd)
echo "MATCHMINER_BUILD_PATH = $MATCHMINER_BUILD_PATH"

echo "*****************"
echo "STARTING DATABASE SERVICES"
echo "*****************"
docker compose up -d mongo elasticsearch
echo "DONE."
echo ""

echo "*****************"
echo "SETTING UP MONGO"
echo "*****************"
sleep 5


if [[ $DEV_MODE == true ]]; then
  echo "Add dev user to database to bypass authentication"
  docker compose exec mongo mongosh matchminer --eval 'db.user.replaceOne({
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
  }, { "upsert": true })'
fi

echo ""
echo "*****************"
echo "SETTING UP ELASTICSEARCH"
echo "*****************"
# naively wait for elasticsearch to start up
sleep 20
# run script to configure indexes, synonyms, etc.
docker compose build matchminer-api
echo "Setup elasticsearch settings, mappings"

docker compose run --rm matchminer-api python pymm_run.py reset-elasticsearch
echo "DONE."
echo ""

echo "*****************"
echo "STARTING API"
echo "*****************"
docker compose build matchminer-api
docker compose up -d matchminer-api
echo "API is running"
sleep 10
echo "*****************"
echo "STARTING UI"
echo "*****************"
docker compose build matchminer-ui
docker compose up -d matchminer-ui
echo "UI is running at: http://localhost:1952"
