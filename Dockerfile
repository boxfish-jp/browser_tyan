FROM mcr.microsoft.com/playwright:v1.59.1-noble
ARG APT_MIRROR_URL=https://ftp.udx.icscoe.jp/pub/Linux/ubuntu
ARG APT_MIRROR_URL

WORKDIR /app

COPY package*.json ./
RUN npm i
COPY . .

RUN npm run build

CMD ["node", "dist/index.js"]
