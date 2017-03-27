sudo apt-get -qq update > /dev/null 2>&1
sudo apt-get -qqyf install landscape-api > /dev/null 2>&1
CREDS=$(landscape-api call BootstrapLDS --json admin_email="$LDS_EMAIL" admin_name="$LDS_NAME" admin_password="$LDS_PASSWORD" --uri https://$HAPROXY/api/ --ssl-ca-file /etc/ssl/certs/landscape_server_ca.crt)
export LANDSCAPE_API_KEY=$(echo $CREDS|python -c "import sys,yaml; print(yaml.load(sys.stdin))['LANDSCAPE_API_KEY']")
export LANDSCAPE_API_SECRET=$(echo $CREDS|python -c "import sys,yaml; print(yaml.load(sys.stdin))['LANDSCAPE_API_SECRET']")
landscape-api register-maas-region-controller --json "http://$MAAS_ENDPOINT/MAAS/" "$MAAS_APIKEY" --uri https://$HAPROXY/api/ --ssl-ca-file /etc/ssl/certs/landscape_server_ca.crt || /bin/true
