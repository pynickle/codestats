# Dockerfile Test
FROM node:18-alpine

# This is a comment in Dockerfile
WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
