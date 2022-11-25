ARG CI_REGISTRY_IMAGE
ARG TAG
ARG DAVFS2_VERSION
ARG DCM2NIIX_VERSION
ARG ANYWAVE_VERSION
FROM ${CI_REGISTRY_IMAGE}/dcm2niix:${DCM2NIIX_VERSION}${TAG} as dcm2niix
FROM ${CI_REGISTRY_IMAGE}/anywave:${ANYWAVE_VERSION}${TAG}
LABEL maintainer="anthony.boyer.gin@univ-grenoble-alpes.fr"

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
    curl unzip python3-pip python3-tk python3-scipy && \
    pip3 install gdown setuptools PyQt5==5.15.4 nibabel xlrd \
    PySimpleGUI pydicom paramiko tkcalendar bids_validator && \
    gdown 1lwAgqS6fXKqWRzZhBntdLGGF4AIsWZx6 && \
    filename="bidsificator.zip" && \
    mkdir ./install && \
    unzip -q -d ./install ${filename} && \
    rm ${filename} && \
    cd install/$(basename $filename .zip)/ && \
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
