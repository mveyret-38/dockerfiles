FROM centos:centos8

ADD set-proxy.sh /tmp/
ADD color.sh /tmp/

VOLUME /run /tmp

ENV container docker

RUN /tmp/set-proxy.sh
RUN yum clean all
RUN yum update -y
RUN yum install tree curl net-tools -y

RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;

ENV init=/lib/systemd/systemd

VOLUME [/sys/fs/cgroup]

ENTRYPOINT ["/lib/systemd/systemd"]
