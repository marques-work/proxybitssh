FROM ubuntu:latest

RUN apt-get update \
  && apt-get install -y \
  apache2 \
  netcat \
  curl \
  sudo \
  openssh-server

RUN a2enmod ssl \
  && a2ensite default-ssl \
  && a2enmod proxy proxy_connect proxy_http proxy_wstunnel \
  && groupadd -r wheel || true \
  && groupadd -r tunnel || true \
  && useradd -ms /bin/bash -G tunnel,wheel -g tunnel tunnel \
  && echo "tunnel ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/tunnel \
  && chmod 0440 /etc/sudoers.d/tunnel

COPY ./default-ssl.conf /etc/apache2/sites-available/default-ssl.conf
COPY ./entrypoint.sh /home/tunnel/entrypoint.sh

RUN chmod 644 /etc/apache2/sites-available/default-ssl.conf \
  && chown root:root /etc/apache2/sites-available/default-ssl.conf \
  && update-rc.d ssh defaults \
  && update-rc.d apache2 defaults \
  && chmod 755 /home/tunnel/entrypoint.sh \
  && chown tunnel:tunnel /home/tunnel/entrypoint.sh

USER tunnel
WORKDIR /home/tunnel

ENTRYPOINT [ "bash", "/home/tunnel/entrypoint.sh" ]
