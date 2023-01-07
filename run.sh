#!/bin/bash
# Make by siben.vn
# Cloudflare's Zone ID, you can find this on the landing/overview page of your domain.
zone_id=xxxxxxxxxxxxxxxxxxxxxxxxxxxxx
# https://dash.cloudflare.com/profile/api-tokens
token=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
# dnsrecord is the A record which will be updated
dns_record=test.example.com

echo "==> Run: $(date "+%Y-%m-%d %H:%M:%S")"

# Get the current external IP address
ip=$(curl -4 -s -X GET https://checkip.amazonaws.com --max-time 10)
if [ -z "$ip" ]; then
    echo "Error! Can't get external ip from https://checkip.amazonaws.com"
    exit 0
fi

echo "Current IP is $ip"

if [ -f "./ip.log" ]; then
    ip_old=$(cat ./ip.log)
    if [[ ${ip} == ${ip_old} ]]; then
        echo "Warning! Dynamic IP Has Not Changed"
        exit 0
    fi
fi

# get the dns record id
dns_records_info=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?type=A&name=$dns_record" \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/json")
dns_record_id=$(echo ${dns_records_info} | grep -o '"id":"[^"]*' | cut -d'"' -f4)
if [[ -z "$dns_record_id" ]]; then
    echo "Error! Can't get '${dns_record}' record inforamiton from cloudflare API"
    exit 0
fi

echo "DNS record id for '$dns_record' is '$dns_record_id'"

# update the record
update_dns_record=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/$dns_record_id" \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/json" \
    --data "{\"type\":\"A\",\"name\":\"$dns_record\",\"content\":\"$ip\",\"ttl\":1,\"proxied\":false}")
if [[ ${update_dns_record} != *"\"success\":true"* ]]; then
    echo "Error! Update Failed"
    exit 0
fi

echo "Success! '$dns_record' DNS Record Updated To: '$ip'"

# create file log
echo -n "$ip" > ./ip.log
