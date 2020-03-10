# Stage 1: Build the application
# docker build -t ohif/viewer:latest .
# FROM node:11.2.0-slim as builder
FROM node:10.16.3-slim as builder

# Get the needed files from github with wget
ENV DOWNLOAD_DIR="/tmp/downloaded-src"
ENV OHIF_SOURCE_DIR="/tmp/downloaded-src/Viewers"
WORKDIR $DOWNLOAD_DIR

ENV GIT_URL="https://github.com/OHIF/Viewers.git"

RUN apt-get update && apt-get install -y \
  git

RUN git clone $GIT_URL

RUN mkdir /usr/src/app
WORKDIR /usr/src/app

# Copy Files
RUN cp -r $OHIF_SOURCE_DIR/.docker /usr/src/app/.docker
RUN cp -r $OHIF_SOURCE_DIR/.webpack /usr/src/app/.webpack
RUN cp -r $OHIF_SOURCE_DIR/extensions /usr/src/app/extensions
RUN cp -r $OHIF_SOURCE_DIR/platform /usr/src/app/platform
RUN cp $OHIF_SOURCE_DIR/.browserslistrc /usr/src/app/.browserslistrc
RUN cp $OHIF_SOURCE_DIR/aliases.config.js /usr/src/app/aliases.config.js
RUN cp $OHIF_SOURCE_DIR/babel.config.js /usr/src/app/babel.config.js
RUN cp $OHIF_SOURCE_DIR/lerna.json /usr/src/app/lerna.json
RUN cp $OHIF_SOURCE_DIR/package.json /usr/src/app/package.json
RUN cp $OHIF_SOURCE_DIR/postcss.config.js /usr/src/app/postcss.config.js
RUN cp $OHIF_SOURCE_DIR/yarn.lock /usr/src/app/yarn.lock

# Run the install before copying the rest of the files
RUN yarn config set workspaces-experimental true
RUN yarn install
#
ENV PATH /usr/src/app/node_modules/.bin:$PATH
ENV QUICK_BUILD true
# ENV GENERATE_SOURCEMAP=false
# ENV REACT_APP_CONFIG=config/default.js

RUN yarn run build

FROM library/tomcat:9-jre8 as tomcat
ENV OHIF_SOURCE_DIR="/tmp/downloaded-src/Viewers"
## install nginx and copy in the OHIF code
RUN apt-get update && apt-get install -y \
	nginx
RUN rm -rf /etc/nginx/conf.d
COPY --from=builder $OHIF_SOURCE_DIR/.docker/Viewer-v2.x/default.conf /etc/nginx/conf.d/default.conf
RUN printf '\
\n\
server {\n\
  listen 3000;\n\
  location / {\n\
    root   /usr/share/nginx/html;\n\
    index  index.html index.htm;\n\
    try_files $uri $uri/ /index.html;\n\
  }\n\
  error_page   500 502 503 504  /50x.html;\n\
  location = /50x.html {\n\
    root   /usr/share/nginx/html;\n\
  }\n\
}' >> /etc/nginx/conf.d/default.conf
COPY --from=builder $OHIF_SOURCE_DIR/.docker/Viewer-v2.x/entrypoint.sh /usr/src/
RUN chmod 777 /usr/src/entrypoint.sh
COPY --from=builder /usr/src/app/platform/viewer/dist /usr/share/nginx/html


# Env for Guacamole
ENV ARCH=amd64 \
  GUAC_VER=1.0.0 \
  GUACAMOLE_HOME=/app/guacamole

# Env for VNC
ENV DISPLAY=:1 \
    VNC_PORT=5901
EXPOSE $VNC_PORT

ENV HOME=/headless \
    TERM=xterm \
    STARTUPDIR=/headless/dockerstartup \
    INST_SCRIPTS=/headless/install \
    NO_VNC_HOME=/headless/noVNC \
    DEBIAN_FRONTEND=noninteractive \
    VNC_COL_DEPTH=24 \
    VNC_RESOLUTION=1980x1024 \
    VNC_PW="" \
    VNC_VIEW_ONLY=false \
    USER_NAME="" \
    USER_HOME=""

ENV USER=$USERID

RUN mkdir $HOME
RUN mkdir $STARTUPDIR
RUN mkdir $INST_SCRIPTS
RUN mkdir -p /usr/local/renci/bin

# Apply the s6-overlay
RUN curl -SLO "https://github.com/just-containers/s6-overlay/releases/download/v1.20.0.0/s6-overlay-${ARCH}.tar.gz" \
  && tar -xzf s6-overlay-${ARCH}.tar.gz -C / \
  && tar -xzf s6-overlay-${ARCH}.tar.gz -C /usr ./bin \
  && rm -rf s6-overlay-${ARCH}.tar.gz \
  && mkdir -p ${GUACAMOLE_HOME} \
    ${GUACAMOLE_HOME}/lib \
    ${GUACAMOLE_HOME}/extensions

# Copy in the static GUACAMOLE configuration files.
ADD ./src/common/guacamole/guacamole.properties ${GUACAMOLE_HOME} 
ADD ./src/common/guacamole/user-mapping-template.xml ${GUACAMOLE_HOME}

WORKDIR ${GUACAMOLE_HOME}

# Install dependencies
RUN apt-get update && apt-get install -y \
    libcairo2-dev libjpeg62-turbo-dev libpng-dev \
    libossp-uuid-dev libavcodec-dev libavutil-dev \
    libswscale-dev libfreerdp-dev libpango1.0-dev \
    libssh2-1-dev libtelnet-dev libvncserver-dev \
    libpulse-dev libssl-dev libvorbis-dev libwebp-dev \
  && rm -rf /var/lib/apt/lists/*

# Link FreeRDP to where guac expects it to be
RUN [ "$ARCH" = "armhf" ] && ln -s /usr/local/lib/freerdp /usr/lib/arm-linux-gnueabihf/freerdp || exit 0
RUN [ "$ARCH" = "amd64" ] && ln -s /usr/local/lib/freerdp /usr/lib/x86_64-linux-gnu/freerdp || exit 0

# Install guacamole-server
RUN curl -SLO "http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUAC_VER}/source/guacamole-server-${GUAC_VER}.tar.gz" \
  && tar -xzf guacamole-server-${GUAC_VER}.tar.gz \
  && cd guacamole-server-${GUAC_VER} \
  && ./configure \
  && make -j$(getconf _NPROCESSORS_ONLN) \
  && make install \
  && cd .. \
  && rm -rf guacamole-server-${GUAC_VER}.tar.gz guacamole-server-${GUAC_VER} \
  && ldconfig

# Install guacamole-client and postgres auth adapter
RUN set -x \
  && rm -rf ${CATALINA_HOME}/webapps/ROOT \
  && curl -SLo ${CATALINA_HOME}/webapps/ROOT.war "http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUAC_VER}/binary/guacamole-${GUAC_VER}.war" \
  && curl -SLO "http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUAC_VER}/binary/guacamole-auth-jdbc-${GUAC_VER}.tar.gz" \
  && tar -xzf guacamole-auth-jdbc-${GUAC_VER}.tar.gz \
  && rm -rf guacamole-auth-jdbc-${GUAC_VER} guacamole-auth-jdbc-${GUAC_VER}.tar.gz

# Add optional extensions
RUN set -xe \
  && mkdir ${GUACAMOLE_HOME}/extensions-available \
  && for i in auth-ldap auth-duo auth-header auth-cas auth-openid auth-quickconnect auth-totp; do \
    echo "http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUAC_VER}/binary/guacamole-${i}-${GUAC_VER}.tar.gz" \
    && curl -SLO "http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUAC_VER}/binary/guacamole-${i}-${GUAC_VER}.tar.gz" \
    && tar -xzf guacamole-${i}-${GUAC_VER}.tar.gz \
    && cp guacamole-${i}-${GUAC_VER}/guacamole-${i}-${GUAC_VER}.jar ${GUACAMOLE_HOME}/extensions-available/ \
    && rm -rf guacamole-${i}-${GUAC_VER} guacamole-${i}-${GUAC_VER}.tar.gz \
  ;done

ENV GUACAMOLE_HOME=/config/guacamole

WORKDIR /config

COPY root /

# Reset the WORKDIR for the vnc/desktop install
WORKDIR $HOME

### Add all install scripts for further steps
ADD ./src/common/install/ $INST_SCRIPTS/
ADD ./src/debian/install/ $INST_SCRIPTS/
RUN find $INST_SCRIPTS -name '*.sh' -exec chmod a+x {} +

### Install some common tools
RUN $INST_SCRIPTS/tools.sh
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

### Install custom fonts
RUN $INST_SCRIPTS/install_custom_fonts.sh

### Install xvnc-server & noVNC - HTML5 based VNC viewer
RUN $INST_SCRIPTS/tigervnc.sh

### Install firefox and chrome browser
RUN $INST_SCRIPTS/firefox.sh

### Install xfce UI
RUN $INST_SCRIPTS/xfce_ui.sh
ADD ./src/common/xfce/ $HOME/

ADD ./src/common/scripts $STARTUPDIR
RUN $INST_SCRIPTS/set_user_permission.sh $STARTUPDIR $HOME

### Make the /usr/local/bin/renci directory
RUN mkdir -p /usr/local/renci/bin

EXPOSE 80
EXPOSE 443

ENTRYPOINT [ "/init" ]
