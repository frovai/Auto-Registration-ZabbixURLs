#!/bin/bash

URL_ZABBIX_SERVER=$URL_ZABBIX_SERVER
TOKEN=$(curl -s -X POST -H 'Content-Type: application/json-rpc' -d '{ "params": { "user": "Admin", "password": "'$ZABBIX_PASSWORD'" }, "jsonrpc": "2.0", "method": "user.login", "id": 0 }' ''$URL_ZABBIX_SERVER'' | jq '.result')
DNS_TXT="urlsZabbix.txt"
EMAIL=$CLOUDFLARE_EMAIL_ZABBIX
KEY=$CLOUDFLARE_KEY_ID
ZONE_ID=$CLOUDFLARE_ZONE_ID

#for TYPE in 'A' 'CNAME'; 
#    do
#        curl -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?per_page=1000&type=${TYPE}" \
#	-H "X-Auth-Email: $EMAIL" \
#	-H "X-Auth-Key: $KEY" \
#	-H "Content-Type: application/json" | python3 -m json.tool >> dns.txt 
#    done && cat dns.txt | grep '"name"' | awk '{print $2}' | sed 's/"//g' | sed 's/,//g' > $DNS_TXT && rm dns.txt

HOST_NAME_ZABBIX=$HOST_NAME_ZABBIX
LIST_DNS=$(cat urlsZabbix.txt)
#LIST_DNS=$(cat $DNS_TXT)

for URL_APP in ${LIST_DNS}
do

	URL=$(echo $URL_APP | awk -F"," '{ print $1 }')
	APP_NAME=$(echo $URL | sed 's/.MYDOMAIN.com.br//g')

	curl -H  "Content-Type: application/json-rpc" -X POST $URL_ZABBIX_SERVER -d'
	{
    	"jsonrpc": "2.0",
    	"method": "trigger.create",
    	"params": [
        	{
            	"description": "'$APP_NAME' HIGH response time!",
            	"expression": "last(/'$HOST_NAME_ZABBIX'/web.test.time['$APP_NAME','$APP_NAME',resp])>5",
				"event_name": "'$APP_NAME'.MYDOMAIN.com.br",
				"opdata": "HIGH response time!",
            	"priority": 3,
            	"tags": [
				{
				    "tag": "trigger-responsetime",
				    "value": "'$APP_NAME'"
				}
            	]
        	},
        	{
            	"description": "'$APP_NAME' URL is DOWN!",
          		"expression": "last(/'$HOST_NAME_ZABBIX'/web.test.fail['$APP_NAME'])>0",
				"event_name": "'$APP_NAME'.MYDOMAIN.com.br",
				"opdata": "URL is DOWN!",
            	"priority": 5,
            	"tags": [
                		{
                    		    "tag": "trigger",
                    		    "value": "'$APP_NAME'"
               			}
            		]
        	}
    	],
    	"auth": '$TOKEN',
    	"id": 0
	}' | jq
done
