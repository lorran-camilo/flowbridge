#!/usr/bin/env bash
set -Eeuo pipefail

: "${FLOWBRIDGE_POSTGRES_MIGRATOR_PASSWORD:?Missing migration role password}"
: "${FLOWBRIDGE_POSTGRES_API_PASSWORD:?Missing API role password}"
: "${FLOWBRIDGE_POSTGRES_WORKER_PASSWORD:?Missing worker role password}"

psql \
  --set=ON_ERROR_STOP=1 \
  --set=db_name="$POSTGRES_DB" \
  --set=migrator_password="$FLOWBRIDGE_POSTGRES_MIGRATOR_PASSWORD" \
  --set=api_password="$FLOWBRIDGE_POSTGRES_API_PASSWORD" \
  --set=worker_password="$FLOWBRIDGE_POSTGRES_WORKER_PASSWORD" \
  --username "$POSTGRES_USER" \
  --dbname "$POSTGRES_DB" <<'SQL'
CREATE ROLE flowbridge_migrator LOGIN PASSWORD :'migrator_password';
CREATE ROLE flowbridge_api LOGIN PASSWORD :'api_password';
CREATE ROLE flowbridge_worker LOGIN PASSWORD :'worker_password';

REVOKE ALL PRIVILEGES ON DATABASE :"db_name" FROM PUBLIC;
GRANT CONNECT, CREATE ON DATABASE :"db_name" TO flowbridge_migrator;
GRANT CONNECT ON DATABASE :"db_name" TO flowbridge_api, flowbridge_worker;

REVOKE CREATE ON SCHEMA public FROM PUBLIC;
GRANT USAGE, CREATE ON SCHEMA public TO flowbridge_migrator;
GRANT USAGE ON SCHEMA public TO flowbridge_api, flowbridge_worker;
SQL
