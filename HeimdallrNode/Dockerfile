# Use the official image as a parent image.
FROM node:14-stretch
WORKDIR /build
COPY package-lock.json package.json ./
RUN npm ci
COPY . .

# Set the working directory.
FROM alpine:3.10
RUN apk add --update nodejs npm
RUN addgroup -S node && adduser -S node -G node
USER node


WORKDIR /home/node/heimdallr
COPY --from=0 --chown=node:node /build .

# Add metadata to the image to describe which port the container is listening on at runtime. Check docker-compose for 9229 its only for inspection remove for production

EXPOSE 5000


# Run the specified command within the container.
CMD [ "node", "app.js" ]
