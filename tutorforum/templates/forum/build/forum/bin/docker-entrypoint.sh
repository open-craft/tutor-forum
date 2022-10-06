#!/bin/sh -e

if [ "${MONGODB_HOST#mongodb+srv://}" != "${HOST}" ]; then
    export MONGOHQ_URL="$MONGODB_HOST/$MONGODB_DATABASE"
elif [ "${MONGODB_HOST#mongodb://}" != "${HOST}" ]; then
    export MONGOHQ_URL="$MONGODB_HOST/$MONGODB_DATABASE"
else
    export MONGOHQ_URL="mongo://$MONGODB_AUTH$MONGODB_HOST:$MONGODB_PORT/$MONGODB_DATABASE"
fi

# the search server variable was renamed after the upgrade to elasticsearch 7
export SEARCH_SERVER_ES7="$SEARCH_SERVER"

# make sure that there is an actual authentication mechanism in place, if necessary
if [ -n "$MONGODB_AUTH" ]
then
    export MONGOID_AUTH_MECH=":scram"
fi

echo "Waiting for mongodb/elasticsearch..."
if [ "${MONGODB_HOST#mongodb+srv://}" != "${HOST}" ]; then
    echo "MongoDB is using SRV records, so we cannot wait for it to be ready"
    dockerize -wait $SEARCH_SERVER -wait-retry-interval 5s -timeout 600s
elif [ "${MONGODB_HOST#mongodb://}" != "${HOST}" ]; then
    echo "MongoDB URL cannot be split, so we cannot wait for it to be ready"
    dockerize -wait $SEARCH_SERVER -wait-retry-interval 5s -timeout 600s
else
    dockerize -wait tcp://$MONGODB_HOST:$MONGODB_PORT -wait $SEARCH_SERVER -wait-retry-interval 5s -timeout 600s
fi
exec "$@"
