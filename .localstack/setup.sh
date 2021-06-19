#!/bin/bash
set -eo pipefail

# Run the main entrypoint script in background mode
docker-entrypoint.sh &

# Wait for the SES service to be available before executing any post-run scripts
while ! nc -z localhost 4579; do   
    echo "Waiting for SES to launch on port 4579..."
    sleep 2
done

# Change YOUR_EMAIL_HERE to the email you want to verify
echo 'Running AWS verify identity command. See: https://github.com/localstack/localstack/issues/339'
aws ses verify-email-identity --email-address avivekbala@gmail.com --region ap-southeast-1 --endpoint-url=http://localhost:4579

# Keeps the container running, otherwise will take the exit code from the `aws` command and stop the container 
while :; do :; done & kill -STOP $! && wait $!
