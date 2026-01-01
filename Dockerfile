FROM node:22-alpine AS builder

WORKDIR /app

# Install dependencies (including devDependencies for build)
COPY package.json pnpm-lock.yaml ./
RUN corepack enable && corepack prepare pnpm@latest --activate
RUN pnpm install --frozen-lockfile

# Copy source code
COPY . .

# Generate Prisma client
# DATABASE_URL is required by prisma.config.ts but value doesn't matter for generation
RUN DATABASE_URL="postgresql://johndoe:randompassword@localhost:5432/mydb" npx prisma generate

# Build the project
RUN pnpm run build

# Production image
FROM node:22-alpine AS runner

WORKDIR /app

# Install OpenSSL (required for Prisma on Alpine)
RUN apk add --no-cache openssl

# Install production dependencies only
COPY package.json pnpm-lock.yaml ./
RUN corepack enable && corepack prepare pnpm@latest --activate
RUN pnpm install --frozen-lockfile --prod

# Copy built artifacts and prisma schema
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/prisma ./prisma

# Expose ports
EXPOSE 8080 8081

# Command is set by docker-compose or overridden
CMD ["node", "dist/index.mjs"]
