FROM alpine AS builder
RUN apk add --no-cache wget zip
RUN wget https://github.com/OpenBMB/ChatDev/archive/refs/tags/v1.1.2.zip && unzip -d /chatdev v1.1.2.zip

FROM python:3.9-slim
WORKDIR /chatdev
COPY --from=builder /chatdev/ChatDev-1.1.2 .
RUN pip install --no-cache-dir -r requirements.txt
CMD [ "python", "run.py" ]
