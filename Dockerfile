FROM purik/android-studio
ENV REFRESHED_AT 2019-01-11

# Switch to root user to install additional software
USER 0
ENV USERNAME dev
RUN groupadd --gid 1000 node \
  && useradd --gid node -rm -d /home/dev -s /bin/bash -g root -u 1005 ${USERNAME}

RUN apt-get update && apt-get install -y nodejs npm


EXPOSE 8080

EXPOSE 19000
EXPOSE 19001
EXPOSE 19002

RUN apt-get install -y \
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
    && npm install --unsafe-perm expo-cli --global

#append the .npm-global to path, other wise globally installed packages 
#will not be available in bash
ENV PATH="/home/$USERNAME/.npm-global:/home/$USERNAME/.npm-global/bin:${PATH}"

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
ADD ./docker-headless-vnc-container/src/common/install/ $INST_SCRIPTS/
ADD ./docker-headless-vnc-container/src/ubuntu/install/ $INST_SCRIPTS/
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
RUN  $INST_SCRIPTS/chrome.sh

### Install xfce UI
RUN $INST_SCRIPTS/xfce_ui.sh
ADD ./src/common/xfce/ $HOME/

### configure startup
RUN $INST_SCRIPTS/libnss_wrapper.sh
ADD ./src/common/scripts $STARTUPDIR
RUN $INST_SCRIPTS/set_user_permission.sh $STARTUPDIR $HOME

USER $USERNAME
