# Frontend Dockerfile for Wipsie Angular App
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production && npm cache clean --force

# Copy app source
COPY . .

# Create non-root user
RUN addgroup -g 1001 -S nodejs \
    && adduser -S angular -u 1001 \
    && chown -R angular:nodejs /app
USER angular

# Expose port
EXPOSE 4200

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:4200 || exit 1

# Start development server
CMD ["npm", "start"]
