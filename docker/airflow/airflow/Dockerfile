#TODO check if full version is needed (slim and other are available)
ARG VERSION=2.9.1-python3.10

FROM apache/airflow:${VERSION}
ARG KUBECTL_VERSION="v1.29.3"
ARG FILENAME
USER root
#TODO remove wget and all az cli  
RUN apt-get update \
  && apt-get install -y --no-install-recommends wget ncat postgresql-common graphviz

ENV ACCEPT_EULA=Y
RUN apt-get upgrade -y

RUN wget https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl \
  && chmod 755 kubectl \
  && mv kubectl /usr/bin/kubectl

USER airflow
COPY ${FILENAME} .
RUN pip install --upgrade pip
RUN pip install apache-airflow-providers-databricks \
        #vertica-python \
        #sqlalchemy-vertica-python \
        #apache-airflow-providers-vertica[common.sql] \
        #apache-airflow-providers-vertica \
        tomli \        
        ${FILENAME}

RUN rm ${FILENAME}
RUN docker --version
RUN pip list
RUN pip install gevent cryptography werkzeug==2.3.8 idna==3.7 aiohttp==3.9.4 gunicorn==22.0.0 --upgrade
RUN pip list
#RUN pip --disable-pip-version-check list --outdated --format=json | python -c "import json, sys; print('\n'.join([x['name'] for x in json.load(sys.stdin)]))" | xargs -n1 pip install -U
