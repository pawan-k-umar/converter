#!/bin/bash

SUBDOMAIN="$1"
PORT="$2"
EMAIL="$3"
DOMAIN="kpawan.com"
FULL_DOMAIN="$SUBDOMAIN.$DOMAIN"
CONFIG_PATH="/etc/nginx/sites-available/$FULL_DOMAIN.conf"

echo "➡️ Creating Nginx config for $FULL_DOMAIN on port $PORT"

# 1. Generate SSL Certificate (if not already)
if [ ! -f "/etc/letsencrypt/live/$FULL_DOMAIN/fullchain.pem" ]; then
    echo "🔐 Generating SSL certificate for $FULL_DOMAIN"
    certbot certonly --nginx -d "$FULL_DOMAIN" --non-interactive --agree-tos -m "$EMAIL"
else
    echo "✅ SSL certificate for $FULL_DOMAIN already exists"
fi

# 2. Write new Nginx config file
echo "🌐 Writing Nginx config to $CONFIG_PATH"
cat <<EOF > "$CONFIG_PATH"
server {
    listen 80;
    server_name $FULL_DOMAIN;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name $FULL_DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$FULL_DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$FULL_DOMAIN/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:$PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# 3. Enable the site
ln -sf "$CONFIG_PATH" "/etc/nginx/sites-enabled/$FULL_DOMAIN.conf"

# 4. Test and reload Nginx
echo "🔄 Reloading Nginx"
nginx -t && systemctl reload nginx

echo "🎉 $FULL_DOMAIN is now live and reverse-proxied to http://127.0.0.1:$PORT"
