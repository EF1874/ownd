FROM node:22-bookworm-slim

WORKDIR /app

ENV NODE_ENV=production
ENV DATABASE_URL=postgresql://ownd:ownd@postgres:5432/ownd?schema=public

RUN corepack enable && corepack prepare pnpm@11.1.3 --activate
RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates openssl \
  && rm -rf /var/lib/apt/lists/*

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN pnpm install --frozen-lockfile

COPY . .
RUN pnpm prisma:generate
RUN pnpm run build

EXPOSE 3000

CMD ["sh", "-c", "pnpm prisma:migrate:deploy && pnpm start:prod"]
