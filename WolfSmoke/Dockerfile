FROM node:14-alpine as builder
WORKDIR /home/wolf
COPY package*.json ./
RUN npm ci
COPY tsconfig*.json ./
COPY src src
RUN npm run build

FROM alpine:3.10
RUN apk add --update nodejs
RUN apk add --no-cache tini
WORKDIR /home/wolf
ENV NODE_PATH=.
COPY --from=builder --chown=node:node /home/wolf/dist .
USER node
COPY package*.json ./
ENTRYPOINT [ "/sbin/tini", "-v", "-e", "143", "--", "node", "dist/index.js" ]
