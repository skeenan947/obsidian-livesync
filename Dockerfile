# Build stage for Obsidian LiveSync plugin
FROM node:22-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy source code
COPY . .

# Build the plugin
RUN npm run build

# Runtime stage - serve plugin files via HTTP
FROM nginx:alpine

# Copy built files from builder
COPY --from=builder /app/main.js /usr/share/nginx/html/
COPY --from=builder /app/manifest.json /usr/share/nginx/html/
COPY --from=builder /app/styles.css /usr/share/nginx/html/

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
