FROM node:12.8-buster-slim
LABEL version=1.0.0

ENV USERNAME dev
RUN useradd -rm -d /home/dev -s /bin/bash -g root -G sudo -u 1005 ${USERNAME}

EXPOSE 19000
EXPOSE 19001
EXPOSE 19002

RUN apt update && apt install -y \
    git \
    procps

#used by react native builder to set the ip address, other wise 
#will use the ip address of the docker container.
ENV REACT_NATIVE_PACKAGER_HOSTNAME="10.0.0.2"

#https://github.com/nodejs/docker-node/issues/479#issuecomment-319446283
#should not install any global npm packages as root, a new user 
#is created and used here
USER $USERNAME

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
RUN apt-get install -y curl unzip

RUN curl 'https://uit.fun/repo/android-studio-ide-183.5522156-linux.zip' > /tmp/studio.zip && unzip -d /opt /tmp/studio.zip && rm /tmp/studio.zip

# Install X11
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get install -y xorg


# Install other useful tools
RUN apt-get install -y vim ant

# install Java
RUN apt-get install -y default-jdk

# Install prerequisites
RUN apt-get install -y libz1 libncurses5 libbz2-1.0:i386 libstdc++6 libbz2-1.0 lib32stdc++6 lib32z1


# Clean up
RUN apt-get clean
RUN apt-get purge

ENV DISPLAY=:1 \
    VNC_PORT=5901 \
    NO_VNC_PORT=6901
EXPOSE $VNC_PORT $NO_VNC_PORT

### Envrionment config
ENV HOME=/headless \
    TERM=xterm \
    STARTUPDIR=/dockerstartup \
    INST_SCRIPTS=/headless/install \
    NO_VNC_HOME=/headless/noVNC \
    DEBIAN_FRONTEND=noninteractive \
    VNC_COL_DEPTH=24 \
    VNC_RESOLUTION=1280x1024 \
    VNC_PW=vncpassword \
    VNC_VIEW_ONLY=false
WORKDIR $HOME

### Add all install scripts for further steps
ADD ./src/common/install/ $INST_SCRIPTS/
ADD ./src/ubuntu/install/ $INST_SCRIPTS/
RUN find $INST_SCRIPTS -name '*.sh' -exec chmod a+x {} +

### Install some common tools
RUN $INST_SCRIPTS/tools.sh
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

### Install custom fonts
RUN $INST_SCRIPTS/install_custom_fonts.sh

### Install xvnc-server & noVNC - HTML5 based VNC viewer
RUN $INST_SCRIPTS/tigervnc.sh
RUN $INST_SCRIPTS/no_vnc.sh

### Install firefox and chrome browser
RUN $INST_SCRIPTS/firefox.sh
RUN $INST_SCRIPTS/chrome.sh

### Install xfce UI
RUN $INST_SCRIPTS/xfce_ui.sh
ADD ./src/common/xfce/ $HOME/

### configure startup
RUN $INST_SCRIPTS/libnss_wrapper.sh
ADD ./src/common/scripts $STARTUPDIR
RUN $INST_SCRIPTS/set_user_permission.sh $STARTUPDIR $HOME

USER 1000

ENTRYPOINT ["/dockerstartup/vnc_startup.sh"]
CMD ["--wait"]
