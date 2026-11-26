#!/usr/bin/env bash
set -Eeuo pipefail

assert_acl() {
  local user="$1" password="$2" query="$3"
  local result
  result="$(PGPASSWORD="$password" psql -h postgres -U "$user" -d "$FLOWBRIDGE_POSTGRES_DB" -XAtq -c "$query")"
  test "$result" = "t" || { echo "Privilege check failed for $user" >&2; exit 1; }
}

assert_acl flowbridge_migrator "$FLOWBRIDGE_POSTGRES_MIGRATOR_PASSWORD" \
  "SELECT has_database_privilege(current_user, current_database(), 'CREATE') AND has_schema_privilege(current_user, 'public', 'CREATE')"
assert_acl flowbridge_api "$FLOWBRIDGE_POSTGRES_API_PASSWORD" \
  "SELECT has_database_privilege(current_user, current_database(), 'CONNECT') AND has_schema_privilege(current_user, 'public', 'USAGE') AND NOT has_schema_privilege(current_user, 'public', 'CREATE')"
assert_acl flowbridge_worker "$FLOWBRIDGE_POSTGRES_WORKER_PASSWORD" \
  "SELECT has_database_privilege(current_user, current_database(), 'CONNECT') AND has_schema_privilege(current_user, 'public', 'USAGE') AND NOT has_schema_privilege(current_user, 'public', 'CREATE')"

PGPASSWORD="$FLOWBRIDGE_POSTGRES_MIGRATOR_PASSWORD" psql \
  -h postgres \
  -U flowbridge_migrator \
  -d "$FLOWBRIDGE_POSTGRES_DB" \
  -v ON_ERROR_STOP=1 \
  -c "CREATE TABLE public.flowbridge_grants_check (id integer)" \
  -c "DROP TABLE public.flowbridge_grants_check"

for role in api worker; do
  password="$FLOWBRIDGE_POSTGRES_API_PASSWORD"
  [ "$role" = worker ] && password="$FLOWBRIDGE_POSTGRES_WORKER_PASSWORD"
  if PGPASSWORD="$password" psql \
    -h postgres \
    -U "flowbridge_$role" \
    -d "$FLOWBRIDGE_POSTGRES_DB" \
    -v ON_ERROR_STOP=1 \
    -c "CREATE TABLE public.flowbridge_forbidden_$role (id integer)" >/dev/null 2>&1; then
    echo "Runtime role flowbridge_$role unexpectedly created a table" >&2
    exit 1
  fi
done

echo "PostgreSQL role and schema privilege checks passed."
