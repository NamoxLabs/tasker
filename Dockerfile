FROM python:3.7 as build-python

RUN \
    apt-get -y update && \
    apt-get install -y gettext && \
    # Cleanup apt cache
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN pip install pipenv
ADD Pipfile /app/
ADD Pipfile.lock /app/
WORKDIR /app
RUN pipenv install --system --deploy --dev

###Final image
FROM python:3.7-slim

RUN \
    apt-get update && \
    apt-get install -y libxml2 libcairo2 libpango-1.0-0 libpangocairo-1.0-0 libgdk-pixbuf2.0-0 shared-mime-info mime-support && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ADD . /app
COPY --from=build-python /usr/local/lib/python3.7/site-packages/ /usr/local/lib/python3.7/site-packages/
COPY --from=build-python /usr/local/bin/ /usr/local/bin/
WORKDIR /app

RUN SECRET_KEY=dummy
RUN DOCKER_CONTAINER=True

RUN useradd --system tasker && \
    mkdir -p /app/media /app/static && \
    chown -R tasker:tasker /app/

USER tasker

EXPOSE 9099
ENV PORT 9099

ENV PYTHONUNBUFFERED 1
ENV PROCESSES 4
CMD ["uwsgi", "/app/demr/wsgi/uwsgi.ini"]
