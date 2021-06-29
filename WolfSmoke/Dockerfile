FROM node:14-alpine as builder
WORKDIR /usr/src/wolf
COPY package*.json ./
RUN npm ci
COPY tsconfig*.json ./
COPY src src
RUN npm run build

FROM builder as prod
ENV NODE_ENV=production
RUN apk add --no-cache tini
WORKDIR /usr/src/wolf
RUN chown node:node .
USER node
COPY package*.json ./
RUN npm install
COPY --from=builder /usr/src/wolf/dist/ dist/
ENTRYPOINT [ "/sbin/tini", "-v", "-e", "143", "--", "node", "dist/index.js" ]
