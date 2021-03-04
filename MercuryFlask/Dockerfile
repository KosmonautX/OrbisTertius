FROM python:3.8.6-slim-buster

WORKDIR /usr/src/mercury


ENV AWS_SECRET_ACCESS_KEY=scratchbac1
ENV AWS_ACCESS_KEY_ID=scratchbac
ENV AWS_DEFAULT_REGION=ap-southeast-1


COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY . .


CMD [ "python3", "wsgi.py" ]
