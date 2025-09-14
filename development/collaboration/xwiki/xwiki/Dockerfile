FROM xwiki:lts-mysql-tomcat

ENV XWIKI_VER 11.10.4

RUN mkdir -p /usr/local/xwiki/data/extension/repository && \
    curl https://nexus.xwiki.org/nexus/content/groups/public/org/xwiki/platform/xwiki-platform-distribution-flavor-xip/$XWIKI_VER/xwiki-platform-distribution-flavor-xip-$XWIKI_VER.xip -o /tmp/xwiki-platform-flavor.zip && \
    unzip /tmp/xwiki-platform-flavor.zip -d /usr/local/xwiki/data/extension/repository && \
    rm -f /tmp/xwiki-platform-flavor.zip

ADD xwiki.properties /usr/local/xwiki/data

WORKDIR /usr/local/tomcat