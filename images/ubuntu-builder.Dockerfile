FROM gcr.io/trusted-builds/ubuntu-1804-base
RUN apt-get -qqy update && apt-get -qqy upgrade
RUN apt-get -qqy install make gpg wget

# google cloud build
WORKDIR /workspace
