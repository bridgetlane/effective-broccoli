FROM centos:latest

COPY repos/* /etc/yum.repos.d/ 
RUN yum-config-manager --disable base \
  --disable updates \
  --disable extras \ 
  && yum -y update \
  && yum clean all \
  && update-ca-trust forces-enable \
  && curl -o /etc/pki/ca-trust/source/anchors/ca.pem https://artifactory.gannettdigital.com/artifactory/ca-certificates/ca_public.pem \
  && update-ca-trust extract