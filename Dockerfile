FROM mcr.microsoft.com/playwright:v1.59.1-noble
WORKDIR /app

COPY package*.json ./
RUN npm i
COPY . .

RUN npm run build

CMD ["node", "dist/index.js"]
