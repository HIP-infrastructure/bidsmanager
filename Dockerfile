ARG CI_REGISTRY_IMAGE
ARG DAVFS2_VERSION
FROM ${CI_REGISTRY_IMAGE}/dcm2niix:1.0.20211006 as dcm2niix
FROM ${CI_REGISTRY_IMAGE}/anywave:2.1.3
LABEL maintainer="nathalie.casati@chuv.ch"

ARG DEBIAN_FRONTEND=noninteractive
ARG CARD
ARG CI_REGISTRY
ARG APP_NAME
#ARG APP_VERSION

#LABEL app_version=$APP_VERSION

WORKDIR /apps/${APP_NAME}

COPY --from=dcm2niix /apps/dcm2niix/install /apps/dcm2niix/install

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install --no-install-recommends -y \ 
    curl unzip python3-pip python3-tk && \
    pip3 install setuptools PyQt5==5.15.4 nibabel bids_validator && \
    ggID='1r4ZQo4TMZQ6p0IoDpKGLA7pGwzhNhItm' && \
    ggURL='https://drive.google.com/uc?export=download' && \
    filename="$(curl -sc /tmp/gcokie "${ggURL}&id=${ggID}" \
    | grep -o '="uc-name.*</span>' | sed 's/.*">//;s/<.a> .*//')" && \ 
    getcode="$(awk '/_warning_/ {print $NF}' /tmp/gcokie)"  && \
    curl -Lb /tmp/gcokie "${ggURL}&confirm=${getcode}&id=${ggID}" -o "${filename}" && \
    mkdir ./install && \
    unzip -q -d ./install ${filename} && \
    rm ${filename} && \
    cd install/BIDS_Manager/ && \
    python3 setup.py install && \
    apt-get remove -y --purge curl unzip && \
    apt-get autoremove -y --purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV APP_SHELL="no"
ENV APP_CMD="bids_manager"
ENV PROCESS_NAME="bids_manager"
ENV DIR_ARRAY=""
ENV CONFIG_ARRAY=".bash_profile"

HEALTHCHECK --interval=10s --timeout=10s --retries=5 --start-period=30s \
  CMD sh -c "/apps/${APP_NAME}/scripts/process-healthcheck.sh \
  && /apps/${APP_NAME}/scripts/ls-healthcheck.sh /home/${HIP_USER}/nextcloud/"

COPY ./scripts/ scripts/
COPY ./apps/${APP_NAME}/config config/

ENTRYPOINT ["./scripts/docker-entrypoint.sh"]
