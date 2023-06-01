ARG CI_REGISTRY_IMAGE
ARG TAG
ARG DAVFS2_VERSION
ARG DCM2NIIX_VERSION
ARG ANYWAVE_VERSION
FROM ${CI_REGISTRY_IMAGE}/dcm2niix:${DCM2NIIX_VERSION}${TAG} as dcm2niix
FROM ${CI_REGISTRY_IMAGE}/anywave:${ANYWAVE_VERSION}${TAG}
LABEL maintainer="anthony.BOYER@univ-amu.fr"

ARG DEBIAN_FRONTEND=noninteractive
ARG CARD
ARG CI_REGISTRY
ARG APP_NAME
ARG APP_VERSION

LABEL app_version=$APP_VERSION
LABEL app_tag=$TAG

WORKDIR /apps/${APP_NAME}

COPY --from=dcm2niix /apps/dcm2niix/install /apps/dcm2niix/install

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install --no-install-recommends -y \ 
    curl unzip python3-pip python3-tk python3-scipy git && \
    pip3 install gdown setuptools PyQt5==5.15.4 nibabel xlrd numpy==1.21 \
    PySimpleGUI pydicom paramiko tkcalendar bids_validator requests && \
    mkdir ./install && \
    cd install && \
    git clone https://github.com/Dynamap/BIDS_Manager.git && \
    cd BIDS_Manager/ && \
    git checkout ${APP_VERSION} && \
    python3 setup.py install && \
    apt-get remove -y --purge curl unzip && \
    apt-get autoremove -y --purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV APP_SPECIAL="terminal"
ENV APP_CMD=""
ENV PROCESS_NAME=""
ENV APP_DATA_DIR_ARRAY="SoftwarePipeline"
ENV DATA_DIR_ARRAY=""
ENV CONFIG_ARRAY=".bash_profile"

HEALTHCHECK --interval=10s --timeout=10s --retries=5 --start-period=30s \
  CMD sh -c "/apps/${APP_NAME}/scripts/process-healthcheck.sh \
  && /apps/${APP_NAME}/scripts/ls-healthcheck.sh /home/${HIP_USER}/nextcloud/"

COPY ./scripts/ scripts/
COPY ./apps/${APP_NAME}/config config/

ENTRYPOINT ["./scripts/docker-entrypoint.sh"]
