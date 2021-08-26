# Fix to 3.13.5 due to Python 3.9 incompatibility introduced in Alpine 3.14 and newer (AttributeError: module 'base64' has no attribute 'decodestring')
FROM alpine:3.13.5
MAINTAINER boredazfcuk

ENV config_dir="/config"

# Container version serves no real purpose. Increment to force a container rebuild.
ARG container_version="1.0.14"
ARG app_dependencies="python3 py3-pip exiftool coreutils tzdata curl libheif-tools py3-certifi py3-cffi py3-cryptography py3-secretstorage py3-jeepney py3-dateutil"
ARG build_dependencies="git"
# Fix tzlocal to 2.1 due to Python 3.8 being default in alpine 3.13.5
ARG python_dependencies="pytz tzlocal==2.1 wheel"
ARG app_repo="icloud-photos-downloader/icloud_photos_downloader"

RUN echo "$(date '+%d/%m/%Y - %H:%M:%S') | ***** BUILD STARTED FOR ICLOUDPD ${container_version} *****" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install build dependencies" && \
  apk add --no-cache --no-progress --virtual=build-deps ${build_dependencies} && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install requirements" && \
   apk add --no-progress --no-cache ${app_dependencies} && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Clone ${app_repo}" && \
   temp_dir=$(mktemp -d) && \
   git clone -b master "https://github.com/${app_repo}.git" "${temp_dir}" && \
   cd "${temp_dir}" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install Python dependencies" && \
   pip3 install --upgrade pip && \
   pip3 install --no-cache-dir ${python_dependencies} && \
   pip3 install --no-cache-dir -r requirements.txt && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install ${app_repo}" && \
   python3 setup.py install && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Clean up" && \
   cd / && \
   rm -r "${temp_dir}" && \
   apk del --no-progress --purge build-deps

COPY --chmod=0755 sync-icloud.sh /usr/local/bin/sync-icloud.sh
COPY --chmod=0755 healthcheck.sh /usr/local/bin/healthcheck.sh

HEALTHCHECK --start-period=10s --interval=1m --timeout=10s \
  CMD /usr/local/bin/healthcheck.sh
  
VOLUME "${config_dir}"

CMD /usr/local/bin/sync-icloud.sh
