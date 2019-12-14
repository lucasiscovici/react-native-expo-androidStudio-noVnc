FROM consol/centos-xfce-vnc
ENV REFRESHED_AT 2019-01-11

# Switch to root user to install additional software
USER 0
ENV USERNAME dev
RUN groupadd --gid 1000 node \
  && useradd --gid node -rm -d /home/dev -s /bin/bash -g root -u 1005 ${USERNAME}

RUN yum update --disablerepo=\* --enablerepo=updates centos-release 
RUN yum -y update; yum clean all
RUN yum -y install epel-release; yum clean all
RUN yum -y install nodejs npm; yum clean all

USER $USERNAME

EXPOSE 8080
EXPOSE 19000
EXPOSE 19001
EXPOSE 19002

RUN apt update && yum install -y \
    git \
    procps

#used by react native builder to set the ip address, other wise 
#will use the ip address of the docker container.
ENV REACT_NATIVE_PACKAGER_HOSTNAME="10.0.0.2"

#https://github.com/nodejs/docker-node/issues/479#issuecomment-319446283
#should not install any global npm packages as root, a new user 
#is created and used here

#set the npm global location for dev user
ENV NPM_CONFIG_PREFIX="/home/$USERNAME/.npm-global"

RUN mkdir -p ~/src \
    && mkdir ~/.npm-global \
    && npm install expo-cli --global

#append the .npm-global to path, other wise globally installed packages 
#will not be available in bash
ENV PATH="/home/$USERNAME/.npm-global:/home/$USERNAME/.npm-global/bin:${PATH}"

RUN dpkg --add-architecture i386
RUN apt-get update

# Download specific Android Studio bundle (all packages).
RUN yum install -y curl unzip

RUN curl 'https://uit.fun/repo/android-studio-ide-183.5522156-linux.zip' > /tmp/studio.zip && unzip -d /opt /tmp/studio.zip && rm /tmp/studio.zip

# Install X11
ENV DEBIAN_FRONTEND=noninteractive
RUN yum install -y xorg


# Install other useful tools
RUN yum install -y vim ant

# install Java
RUN yum install -y default-jdk

# Install prerequisites
RUN yum install -y libz1 libncurses5 libbz2-1.0:i386 libstdc++6 libbz2-1.0 lib32stdc++6 lib32z1


# Clean up
RUN yum clean
RUN yum purge
