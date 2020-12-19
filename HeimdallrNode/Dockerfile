# Use the official image as a parent image.
FROM alpine:3.7

# Set the working directory.

WORKDIR /usr/src/heimdallr

RUN apk add python3
RUN apk add nodejs
ENV AWS_SECRET_ACCESS_KEY=scratchbac1
ENV AWS_ACCESS_KEY_ID=scratchbac
ENV AWS_DEFAULT_REGION=ap-southeast-1

# Copy the file from your host to your current location.
COPY package*.json ./

# Run the command inside your image filesystem.
RUN npm install

# Add metadata to the image to describe which port the container is listening on at runtime. Check docker-compose for 9229 its only for inspection remove for production
# EXPOSE 5000

# Run the specified command within the container.
CMD [ "npm", "start" ]

# Copy the rest of your app's source code from your host to your image filesystem.
COPY . .
