# Runtime stage - serve pre-built plugin files via HTTP
FROM nginx:alpine

# Copy built files (build locally first with: npm run build)
COPY main.js /usr/share/nginx/html/
COPY manifest.json /usr/share/nginx/html/
COPY styles.css /usr/share/nginx/html/

# Copy nginx config with CORS enabled for Obsidian
COPY <<EOF /etc/nginx/conf.d/default.conf
server {
    listen 80;
    server_name localhost;

    location / {
        root /usr/share/nginx/html;
        index manifest.json;

        # CORS headers for Obsidian
        add_header Access-Control-Allow-Origin * always;
        add_header Access-Control-Allow-Methods 'GET, OPTIONS' always;
        add_header Access-Control-Allow-Headers 'accept, origin, content-type' always;

        if (\$request_method = OPTIONS) {
            return 204;
        }
    }
}
EOF

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
