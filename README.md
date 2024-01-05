# minicluster

Documentation of a mini bare-metal cluster intended for Kubernetes experiments. It consists in 6 nodes (X86_64 architecture) managed by a server node providing global services (DNS, etc.). The whole cluster fits in a case and is therefore portable.
![Cluster V1](./images/clusterv1.resized.jpg "Cluster V1")

Day-to-day information on the cluster [is available on my blog](https://www.mouton.in/categories/minicluster/).

## Building

All information related to hardware is gathered in a [dedicated page](./hardware/README.md).

## Gateway configuration and global network services

In addition to providing access to the minicluster, the gateway also hosts global services and network configuration for cluster nodes.
A dedicated page [gathers information](./gateway_configuration.md) on gateway configuration.

## Global cluster configuration

As much as possible, and once public keys of management accounts have been deployed on nodes, global configuration is done using [Ansible scripts](./ansible/README.md)

### OS deployment configuration

Initial plan was to deploy CentOS stream using provisioning tools like [The Foreman](https://theforeman.org) for nodes life cycle management. As I discovered that [cluster nodes](./hardware/README.md) couldn't boot with PXE, a more traditional and low level approach had to be used.

Furthermore, due to change in CentOS project management, I switched to Rocky Linux alternative.

Automated deployment of Operating System on cluster nodes [is documented on a dedicated page](./documentation/os_automated_deployment.md).

## Kubernetes deployment

### Container deployment

_Documentation available soon: stay tuned._

### Kubernetes setup

_Documentation available soon: stay tuned._

* Single cluster
* Two clusters in separate VLANs

