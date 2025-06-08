#!/bin/bash
SUBDOMAIN="$1"
PORT="$2"
EMAIL="$3"
DOMAIN="kpawan.com"
FULL_DOMAIN="$SUBDOMAIN.$DOMAIN"

echo "➡️ Setting up $FULL_DOMAIN -> http://localhost:$PORT"

# Issue certificate if doesn't exist
if [ ! -f "/etc/letsencrypt/live/$FULL_DOMAIN/fullchain.pem" ]; then
  certbot --nginx -d "$FULL_DOMAIN" --non-interactive --agree-tos -m "$EMAIL" --redirect
else
  echo "✅ Certificate for $FULL_DOMAIN already exists."
fi

# Write nginx config
cat <<EOF > "/etc/nginx/sites-available/$FULL_DOMAIN"
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

ln -sf "/etc/nginx/sites-available/$FULL_DOMAIN" "/etc/nginx/sites-enabled/$FULL_DOMAIN"

# Reload nginx
nginx -t && systemctl reload nginx
echo "🎉 $FULL_DOMAIN is now live and proxied to port $PORT"