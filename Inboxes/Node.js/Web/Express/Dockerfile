FROM node:20-alpine
RUN apk add --no-cache openssl
WORKDIR /app
COPY src/package.json ./
RUN npm install
COPY src/ .
RUN npx prisma generate
EXPOSE 3000
CMD ["sh", "-c", "npx prisma db push --skip-generate && node server.js"]

