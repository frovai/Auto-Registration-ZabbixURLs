#!/bin/bash

URL_ZABBIX_SERVER=$URL_ZABBIX_SERVER
TOKEN=$(curl -s -X POST -H 'Content-Type: application/json-rpc' -d '{ "params": { "user": "Admin", "password": "'$ZABBIX_PASSWORD'" }, "jsonrpc": "2.0", "method": "user.login", "id": 0 }' ''$URL_ZABBIX_SERVER'' | jq '.result')
DNS_TXT="urlsZabbix.txt"
EMAIL=$CLOUDFLARE_EMAIL_ZABBIX
KEY=$CLOUDFLARE_KEY_ID
ZONE_ID=$CLOUDFLARE_ZONE_ID
HOST_NAME_ZABBIX=$HOST_NAME_ZABBIX

#for TYPE in 'A' 'CNAME'; 
#    do
#        curl -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?per_page=1000&type=${TYPE}" \
#	-H "X-Auth-Email: $EMAIL" \
#	-H "X-Auth-Key: $KEY" \
#	-H "Content-Type: application/json" | python3 -m json.tool >> dns.txt 
#    done && cat dns.txt | grep '"name"' | awk '{print $2}' | sed 's/"//g' | sed 's/,//g' > $DNS_TXT && rm dns.txt

LIST_DNS=$(cat urlsZabbix.txt)
#LIST_DNS=$(cat $DNS_TXT)

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
    "auth": '$TOKEN',
    "id": 0
}' | jq '.result' |  sed 's/[][]//g')

HOST_ID_FORMATED=$(echo $HOST_ID | jq '.hostid')

for URL_APP in ${LIST_DNS}
	do

    HEALTHCHECK=$(echo $URL_APP | awk -F"," '{ print $2 }')

    URL=$(echo $URL_APP | awk -F"," '{ print $1 }')
    APP_NAME=$(echo $URL | sed 's/.MYDOMAIN.com.br//g')
    curl -H  "Content-Type: application/json-rpc" -X POST $URL_ZABBIX_SERVER -d'
    {
    	"jsonrpc": "2.0",
        "method": "httptest.create",
        "params": {
        "name": "'$APP_NAME'",
    	"delay": "30s",
        "retries": "2",
    	"hostid": '$HOST_ID_FORMATED',
            "steps": [
              {
                    "name": "'$APP_NAME'",
                    "url": "'https://$URL$HEALTHCHECK'",
        	        "status_codes": "200",
                    "no": 1
         	    }
            ]
        },
        "auth": '$TOKEN',
        "id": 0
    }' | jq 
done
