#!/bin/bash
#
# 30_gen_ssl_keys.sh
#

mkdir -p /config/keys

# Ensure ServerName exists and is non-empty
if [[ ! -s /config/keys/ServerName ]]; then
    echo "localhost" > /config/keys/ServerName
fi

SERVER=$(cat /config/keys/ServerName)

# Generate self-signed cert only if missing
if [[ ! -f /config/keys/cert.key || ! -f /config/keys/cert.crt ]]; then
    echo "Generating self-signed keys in /config/keys (CN=$SERVER with SAN)"
    
    # Temporary OpenSSL config for SAN
    SAN_CONFIG=$(mktemp)
    cat > "$SAN_CONFIG" <<EOL
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
CN = $SERVER

[v3_req]
subjectAltName = @alt_names

[alt_names]
DNS.1 = $SERVER
EOL

    openssl req -x509 -nodes -days 4096 -newkey rsa:2048 \
        -keyout /config/keys/cert.key \
        -out /config/keys/cert.crt \
        -config "$SAN_CONFIG"

    rm -f "$SAN_CONFIG"
fi

# Apply ServerName to Apache
sed -i "/ServerName/c\ServerName $SERVER" /etc/apache2/apache2.conf

# Set secure permissions
chown root:root /config/keys
chmod 755 /config/keys

chown root:root /config/keys/cert.crt
chmod 644 /config/keys/cert.crt

chown root:root /config/keys/cert.key
chmod 600 /config/keys/cert.key

chown root:root /config/keys/ServerName
chmod 644 /config/keys/ServerName
