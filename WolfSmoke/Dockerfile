FROM node:14-alpine as builder
WORKDIR /home/wolf
COPY package*.json shardState.json ./
RUN npm ci
COPY tsconfig*.json ./
COPY src src
RUN npm run build

FROM node:14-alpine
WORKDIR /home/wolf
ENV NODE_PATH=.
COPY --from=builder --chown=node:node /home/wolf .
COPY --from=builder --chown=node:node /home/wolf/shardState.json .
#ENTRYPOINT ["tail", "-f", "/dev/null"]
RUN apk add --no-cache tini
ENTRYPOINT [ "/sbin/tini", "-v", "-e", "143", "--"]
CMD ["node", "dist/index.js" ]
