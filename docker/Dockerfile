FROM ubuntu:bionic

RUN apt-get update && apt-get install -y \
    wget parted dosfstools binutils p7zip-full \
    sudo xz-utils jq u-boot-tools

COPY source /opt/source

# The repository should be mounted at /app.
WORKDIR /opt/source

CMD /opt/source/build-image.sh raspberrypi
