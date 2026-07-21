FROM mcr.microsoft.com/playwright:v1.61.1-noble

WORKDIR /app

COPY pnpm-lock.yaml pnpm-workspace.yaml package.json ./
RUN corepack enable && pnpm install --frozen-lockfile

COPY tsconfig.json ./
COPY src/ src/
RUN pnpm run build

ENV BROWSER_TYAN_PORT=3000
ENV BROWSER_TYAN_PROFILE_DIR=/app/browser-profile

CMD ["node", "dist/index.js"]
