#!/bin/sh
set -e

COUCHDB_HOST="http://couchdb:5984"
USER="${COUCHDB_USER:-admin}"
PASSWORD="${COUCHDB_PASSWORD:-password}"

echo "Waiting for CouchDB to be ready..."
until curl -s "${COUCHDB_HOST}/_up" > /dev/null 2>&1; do
    sleep 2
done

echo "Configuring CouchDB for Obsidian LiveSync..."

# Enable single node setup (try without auth first, then with auth)
echo "Setting up single node..."
for i in 1 2 3 4 5; do
    RESULT=$(curl -s -X POST "${COUCHDB_HOST}/_cluster_setup" \
        -H "Content-Type: application/json" \
        -d "{\"action\":\"enable_single_node\",\"username\":\"${USER}\",\"password\":\"${PASSWORD}\",\"bind_address\":\"0.0.0.0\",\"port\":5984,\"singlenode\":true}" \
        --user "${USER}:${PASSWORD}" 2>/dev/null)
    if echo "$RESULT" | grep -q '"ok":true'; then
        echo "Single node setup successful"
        break
    fi
    # Try without auth
    RESULT=$(curl -s -X POST "${COUCHDB_HOST}/_cluster_setup" \
        -H "Content-Type: application/json" \
        -d "{\"action\":\"enable_single_node\",\"username\":\"${USER}\",\"password\":\"${PASSWORD}\",\"bind_address\":\"0.0.0.0\",\"port\":5984,\"singlenode\":true}" 2>/dev/null)
    if echo "$RESULT" | grep -q '"ok":true'; then
        echo "Single node setup successful"
        break
    fi
    echo "Retry $i: $RESULT"
    sleep 2
done

# Configure security settings
curl -s -X PUT "${COUCHDB_HOST}/_node/_local/_config/chttpd/require_valid_user" \
    -H "Content-Type: application/json" \
    -d '"true"' \
    --user "${USER}:${PASSWORD}"

curl -s -X PUT "${COUCHDB_HOST}/_node/_local/_config/chttpd_auth/require_valid_user" \
    -H "Content-Type: application/json" \
    -d '"true"' \
    --user "${USER}:${PASSWORD}"

curl -s -X PUT "${COUCHDB_HOST}/_node/_local/_config/httpd/WWW-Authenticate" \
    -H "Content-Type: application/json" \
    -d '"Basic realm=\"couchdb\""' \
    --user "${USER}:${PASSWORD}"

# Configure CORS for Obsidian
curl -s -X PUT "${COUCHDB_HOST}/_node/_local/_config/httpd/enable_cors" \
    -H "Content-Type: application/json" \
    -d '"true"' \
    --user "${USER}:${PASSWORD}"

curl -s -X PUT "${COUCHDB_HOST}/_node/_local/_config/chttpd/enable_cors" \
    -H "Content-Type: application/json" \
    -d '"true"' \
    --user "${USER}:${PASSWORD}"

curl -s -X PUT "${COUCHDB_HOST}/_node/_local/_config/cors/credentials" \
    -H "Content-Type: application/json" \
    -d '"true"' \
    --user "${USER}:${PASSWORD}"

curl -s -X PUT "${COUCHDB_HOST}/_node/_local/_config/cors/origins" \
    -H "Content-Type: application/json" \
    -d '"app://obsidian.md,capacitor://localhost,http://localhost"' \
    --user "${USER}:${PASSWORD}"

curl -s -X PUT "${COUCHDB_HOST}/_node/_local/_config/cors/methods" \
    -H "Content-Type: application/json" \
    -d '"GET,PUT,POST,HEAD,DELETE"' \
    --user "${USER}:${PASSWORD}"

curl -s -X PUT "${COUCHDB_HOST}/_node/_local/_config/cors/headers" \
    -H "Content-Type: application/json" \
    -d '"accept,authorization,content-type,origin,referer"' \
    --user "${USER}:${PASSWORD}"

# Increase limits for large vaults
curl -s -X PUT "${COUCHDB_HOST}/_node/_local/_config/chttpd/max_http_request_size" \
    -H "Content-Type: application/json" \
    -d '"4294967296"' \
    --user "${USER}:${PASSWORD}"

curl -s -X PUT "${COUCHDB_HOST}/_node/_local/_config/couchdb/max_document_size" \
    -H "Content-Type: application/json" \
    -d '"50000000"' \
    --user "${USER}:${PASSWORD}"

echo "CouchDB configuration complete!"
