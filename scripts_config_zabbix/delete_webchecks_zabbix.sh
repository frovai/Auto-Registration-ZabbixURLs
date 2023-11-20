#!/bin/bash

URL_ZABBIX_SERVER=$URL_ZABBIX_SERVER
TOKEN=$(curl -s -X POST -H 'Content-Type: application/json-rpc' -d '{ "params": { "user": "Admin", "password": "'$ZABBIX_PASSWORD'" }, "jsonrpc": "2.0", "method": "user.login", "id": 0 }' ''$URL_ZABBIX_SERVER'' | jq '.result')
EMAIL=$CLOUDFLARE_EMAIL_ZABBIX
HOST_NAME_ZABBIX=$HOST_NAME_ZABBIX

LISTA_URLS=$(cat files_url/urlsToDelete.txt)

HOST_ID=$(curl -H "Content-Type: application/json-rpc" -X GET $URL_ZABBIX_SERVER -d'
{
    "jsonrpc": "2.0",
    "method": "host.get",
    "params": {
        "filter": {
            "host": [
                "'$HOST_NAME_ZABBIX'"
            ]
        }
    },
    "auth": '${TOKEN}',
    "id": 0
}' | jq '.result' |  sed 's/[][]//g')

HOST_ID_FORMATED=$(echo $HOST_ID | jq '.hostid')

for URL_APP in ${LISTA_URLS}
do
    APP_NAME=$(echo $URL_APP | sed 's/.MYDOMAIN.com.br//g')
	HTTPTEST=$(curl -H "Content-Type: application/json-rpc" -X GET $URL_ZABBIX_SERVER/api_jsonrpc.php -d'
	{
    "jsonrpc": "2.0",
    "method": "httptest.get",
    "params": {
	"output": ["name","steps"],
        "selectSteps": ["httptestid", "url"],
        "filter":{ "name": "'$APP_NAME'"}
    },
    "auth": '$TOKEN',
    "id": 0
}'| jq '.result' |  sed 's/[][]//g' | jq '.steps') 

WEB_ID=$(echo $HTTPTEST | jq '.httptestid')
WEB_URL=$(echo $HTTPTEST | jq '.url')

echo $WEB_ID
echo $WEB_URL

curl -H "Content-Type: application/json-rpc" -X GET $URL_ZABBIX_SERVER/api_jsonrpc.php -d'
{
    "jsonrpc": "2.0",
    "method": "httptest.delete",
    "params": [
        '$WEB_ID'
    ],
    "auth": '$TOKEN',
    "id": 0
}'

done
