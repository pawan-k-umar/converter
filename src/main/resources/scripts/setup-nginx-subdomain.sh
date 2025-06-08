#!/bin/bash

SUBDOMAIN="$1"
PORT="$2"
EMAIL="$3"
DOMAIN="kpawan.com"
FULL_DOMAIN="$SUBDOMAIN.$DOMAIN"

echo "➡️ Setting up $FULL_DOMAIN -> http://localhost:$PORT"

# Check if cert already exists
CERT_PATH="/etc/letsencrypt/live/$FULL_DOMAIN/fullchain.pem"
if [ ! -f "$CERT_PATH" ]; then
  echo "🔐 Requesting SSL certificate for $FULL_DOMAIN"
  sudo certbot --nginx -d "$FULL_DOMAIN" --non-interactive --agree-tos -m "$EMAIL" --redirect
  if [ $? -ne 0 ]; then
    echo "❌ Failed to obtain SSL certificate for $FULL_DOMAIN"
    exit 1
  fi
else
  echo "✅ Certificate already exists for $FULL_DOMAIN"
fi

# Nginx config
NGINX_CONF="/etc/nginx/sites-available/$FULL_DOMAIN"
cat <<EOF | sudo tee "$NGINX_CONF" > /dev/null
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

# Enable site and reload
sudo ln -sf "$NGINX_CONF" "/etc/nginx/sites-enabled/$FULL_DOMAIN"
sudo nginx -t && sudo systemctl reload nginx

echo "🎉 $FULL_DOMAIN is now live and proxied to port $PORT"
