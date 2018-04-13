FROM nginx
MAINTAINER Mahmoud Gamal <mhmoudgmal.89@gmail.com>

COPY dist/index.html /usr/share/nginx/html
COPY dist/* /usr/share/nginx/html/

# NOTE
# copying (crt & key) files from the build server directory to avoid including them in github repo.
# @see Jenkinsfile - copy the certs to the workspace then you shoud be good to enable the following lines
#
# COPY certs/mydomain.crt /etc/ssl/certs
# COPY certs/mydomain.key /etc/ssl/private

ADD nginx /tmp/nginx

RUN cat /tmp/nginx/sites-enabled/staging > /etc/nginx/conf.d/default.conf
