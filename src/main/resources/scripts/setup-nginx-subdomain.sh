#!/bin/bash

SUBDOMAIN="$1"     # e.g. converter
PORT="$2"          # e.g. 9091
EMAIL="$3"         # your email for certbot
DOMAIN="kpawan.com"
FULL_DOMAIN="$SUBDOMAIN.$DOMAIN"
CONFIG_PATH="/etc/nginx/sites-available/$DOMAIN"

if [[ -z "$SUBDOMAIN" || -z "$PORT" || -z "$EMAIL" ]]; then
  echo "❗ Usage: $0 <subdomain> <port> <email>"
  exit 1
fi

echo "➡️ Adding subdomain $FULL_DOMAIN to $CONFIG_PATH"

# 1. Issue certificate if not already present
if [ ! -f "/etc/letsencrypt/live/$FULL_DOMAIN/fullchain.pem" ]; then
  echo "🔐 Requesting SSL certificate for $FULL_DOMAIN"
  sudo certbot certonly --nginx -d "$FULL_DOMAIN" --non-interactive --agree-tos -m "$EMAIL"
  if [ $? -ne 0 ]; then
    echo "❌ Certificate issuance failed for $FULL_DOMAIN"
    exit 2
  fi
else
  echo "✅ Certificate already exists for $FULL_DOMAIN"
fi

# 2. Append new server block to existing config
cat <<EOF | sudo tee -a "$CONFIG_PATH" > /dev/null

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

# 3. Test and reload nginx
echo "🔁 Reloading nginx..."
sudo nginx -t && sudo systemctl reload nginx

if [ $? -eq 0 ]; then
  echo "🎉 $FULL_DOMAIN successfully added and proxied to port $PORT"
else
  echo "❌ Failed to reload nginx. Please check config."
fi
