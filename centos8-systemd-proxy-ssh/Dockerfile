FROM mveyret/centos8-systemd-proxy

VOLUME /run /tmp

ENV container docker

RUN /tmp/set-proxy.sh
RUN yum clean all
RUN yum install openssh openssh-server openssh-clients -y
RUN rm -f /run/nologin