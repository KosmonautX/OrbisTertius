FROM python:3.8.6-slim-buster

WORKDIR /usr/src/mercury


ENV AWS_SECRET_ACCESS_KEY=scratchbac1
ENV AWS_ACCESS_KEY_ID=scratchbac
ENV AWS_DEFAULT_REGION=ap-southeast-1
ENV PRINCE_JWT=92CDB3B5F5D8F2B1D5D93470D0E9170D7F4CA76F33061B9386EB0AE0BA59CC6A
ENV BALA=SECRET_TUNNEL
ENV TELE_BOT=1184812909:AAE1kZB5QcX46a7Ul_wkFATFdIjUfLiwmPw


COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY . .


CMD [ "python3", "wsgi.py" ]
