FROM openjdk:11-jre-slim
MAINTAINER ks0m1c_m0rpʒus <john@doe.com>
ENV DEBIAN_FRONTEND=noninteractive
RUN echo "Acquire::Check-Valid-Until \"false\";\nAcquire::Check-Date \"false\";" | cat > /etc/apt/apt.conf.d/10no--check-valid-until
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    dirmngr \
    gnupg2 \
    nginx \
    supervisor \
    xz-utils \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/

RUN mkdir ~/.gnupg && echo "disable-ipv6" >> ~/.gnupg/dirmngr.conf

# We need java and node in this image, so we'll start with java (cause it's
# more hairy), and then dump in the node Dockerfile below.
ENV NODE_VERSION 12
ENV NPM_CONFIG_LOGLEVEL error

# verify gpg and sha256: http://nodejs.org/dist/v*/SHASUMS256.txt.asc
# See: https://github.com/nodejs/node#release-keys
RUN set -ex && \
for key in \
    4ED778F539E3634C779C87C6D7062848A1AB005C \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    74F12602B6F1C4E913FAA37AD3A89613643B6201 \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    C82FA3AE1CBEDC6BE46B9360C43CEC45C17AB93C \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    A48C2BEE680E841632CD4E44F07496B3EB3C1762 \
    108F52B48DB57BB0CC439B2997B01419BD92F80A \
    B9E2F5981AA6E0CD28160D9FF13993A75599653C \
    ; do \
    gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "$key" || \
    gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key" ; \
    done

# config arm64 for rpi x64 for rest
RUN NODE_FILE="$(curl -sfS https://nodejs.org/dist/latest-v$NODE_VERSION.x/ | grep -oE node-v${NODE_VERSION}\.[0-9.]+-linux-x64.tar.xz | sort -r | head -n 1)" && \
    NODE_LATEST_VERSION=$(echo $NODE_FILE | grep -oE "v[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+") && \
    curl -fsSLO --compressed "https://nodejs.org/dist/$NODE_LATEST_VERSION/$NODE_FILE" && \
    curl -fsSLO --compressed "https://nodejs.org/dist/$NODE_LATEST_VERSION/SHASUMS256.txt.asc" && \
    gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc && \
    grep " $NODE_FILE\$" SHASUMS256.txt.asc | sha256sum -c - && \
    tar -xJf "$NODE_FILE" --warning=no-unknown-keyword -C /usr/local --strip-components=1 --no-same-owner && \
    ls -la /usr/local/bin/n* && \
    rm "$NODE_FILE" SHASUMS256.txt.asc SHASUMS256.txt && \
    npm install -g "npm@latest" && \
    npm cache clean --force

RUN npm install --no-optional --global dynamodb-admin@4.0.1 \
    && npm cache clean --force

RUN mkdir -p /var/lib/dynamodb && cd /usr/lib && \
    curl -L https://s3-us-west-2.amazonaws.com/dynamodb-local/dynamodb_local_latest.tar.gz | tar xz
VOLUME /var/lib/dynamodb

COPY nginx-proxy.conf /etc/nginx-proxy.conf
COPY supervisord.conf /etc/supervisord.conf

# Configure a sane default Java heap size (that can be overridden).
ENV JAVA_OPTS "-Xmx256m"

# Configuration for dynamo-admin to know where to hit dynamo.
ENV DYNAMO_ENDPOINT http://localhost:8002/

# For dinghy users.
ENV VIRTUAL_HOST dynamo.docker
ENV VIRTUAL_PORT 8000

# Main proxy on 8000, dynamo-admin on 8001, dynamodb on 8002
EXPOSE 8000 8001 8002

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
