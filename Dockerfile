FROM centos:centos7
LABEL maintainer="ome-devel@lists.openmicroscopy.org.uk"
LABEL org.opencontainers.image.created="2019-11-13T18:26:30Z"
LABEL org.opencontainers.image.revision="fa6d8c52ffb0eab289b8ce4de1a23d2393a129d5"
LABEL org.opencontainers.image.source="https://github.com/openmicroscopy/omero-server-docker"

RUN mkdir /opt/setup
WORKDIR /opt/setup
ADD playbook.yml requirements.yml /opt/setup/

RUN yum -y install epel-release \
    && yum -y install ansible sudo git \
    && ansible-galaxy install -p /opt/setup/roles -r requirements.yml

ARG OMERO_VERSION=5.6.0-m1
ARG OMEGO_ADDITIONAL_ARGS=
RUN ansible-playbook playbook.yml \
    -e omero_server_release=$OMERO_VERSION \
    -e omero_server_omego_additional_args="$OMEGO_ADDITIONAL_ARGS"

RUN curl -L -o /usr/local/bin/dumb-init \
    https://github.com/Yelp/dumb-init/releases/download/v1.2.0/dumb-init_1.2.0_amd64 && \
    chmod +x /usr/local/bin/dumb-init
ADD entrypoint.sh /usr/local/bin/
ADD 50-config.py 60-database.sh 99-run.sh /startup/

USER omero-server
EXPOSE 4063 4064
VOLUME ["/OMERO", "/opt/omero/server/OMERO.server/var"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
