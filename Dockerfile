FROM debian:stretch
MAINTAINER David Zemon <david.zemon@redlion.net>

ENV DEBIAN_FRONTEND=noninteractive \
    REPREPRO_ROOT_DIR=/data \
    GNUPGHOME="/data/.gnupg" \
    REPREPRO_USERNAME=reprepro

RUN apt-get update && apt-get install --yes --no-install-recommends \
    reprepro \
    openssh-server && \
  echo "AllowUsers reprepro" >> /etc/ssh/sshd_config && \
  echo "X11Forwarding no" >> /etc/ssh/sshd_config && \
  echo "AllowAgentForwarding no" >> /etc/ssh/sshd_config && \
  echo "AllowTcpForwarding no" >> /etc/ssh/sshd_config

ADD run.sh /run.sh
RUN chmod +x /run.sh

VOLUME ["/data"]
EXPOSE 22
CMD ["/run.sh"]
