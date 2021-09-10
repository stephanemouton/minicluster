# Container technolgy installation

## Documentation used

* https://github.com/cri-o/cri-o/blob/master/install.md
* https://kubernetes.io/docs/setup/production-environment/container-runtimes/#cri-o
* https://prog.world/cri-o-as-a-replacement-for-docker-as-the-runtime-for-kubernetes-setting-up-on-centos-8/

## Procedure

curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/CentOS_8_Stream/devel:kubic:libcontainers:stable.repo
curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable:cri-o:1.22.repo https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:1.22/CentOS_8_Stream/devel:kubic:libcontainers:stable:cri-o:1.22.repo
yum install cri-o
