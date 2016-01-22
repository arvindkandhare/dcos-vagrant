DCOS Local Demo using Vagrant and Virtual Box
==================

The purpose of this repo was to create a simple way to quickly provision various DCOS cluster(s) on an internal system. In addition, make it easy to discuss and demonstrate some of the core capabilities of DCOS.

This can optionally provide a model for a self-guided trial that is quick yet still robust. The cluster is setup using the opensource VirtualBox virtualization layer (Oracle) 5.0.10 and Vagrant 1.8.1 which is a tool for easily modeling system deployments against various providers (VirtualBox). The driving goals of this implementation are:

- **KISS - Keep It Simple Stupid:** I prefer explicit/simple configuration over flexible/complex so it's easy to understand.
- **Experiment, Iterate and Test:**
 - Experiment: Make DCOS accessible to more people that can validate new releases, demos and use cases.
 - Iterate: Various config changes can be tried to find better ways they will function and operate.
 - Test: New releases and customer env can be tested more thoroughly ensuring a more positive customer experience.
- **Localized:** Ensure ease of use without network constraints and a more mutable cluster.

**NOTE: Before making changes to your local repo be sure to fork the repo or create a branch. Also, take note of the files in the .gitignore file which will not be committed.**

**Repo Structure**

	.
	├── build
	│   │
	│   ├── bin
	│   │   ├── base.sh                # Base virtual-box OS script
	│   │   ├── cleanup.sh             # Cleanup script
	│   │   ├── vagrant.sh             # Vagrant specific setup script
	│   │   ├── virtualbox.sh          # virtualbox specific (guest-additions, etc.)  script
	│   │   └── zerodisk.sh            # virtualbox image compression
	│   │
	│   ├── http                       # Artifact repo for packer build process (kickstart, etc.)
	│   │   └── ks.cfg                 # Kickstart definition for base image provisioning			
	│   │
	│   ├── Dockerfile                 # Docker file for java-spring applications
	│   └── packer_template.json       # template for creating base image using packer
	│
	├─── docs                          # Misc images or supporting documentation
	│
	├─── etc
	│   ├── ip-detect                  # Script for pulling appropriate ip. Be sure to confirm interface (enp0s8)
	│   ├── hosts.file                 # Resolve instances 
	│   ├── 1_master-config.yaml       # DCOS config for 1 master
	│   └── 3_master-config.yaml       # DCOS config for 3 masters
	│
	├── provision
	│   │
	│   ├── bin
	│   │   ├── base.sh                # Base OS for all nodes
	│   │   ├── boot.sh                # Bootstrap node
	│   │   ├── hosts.sh               # Hosts file for all nodes
	│   │   ├── master.sh              # Master node
	│   │   ├── worker-private.sh      # Worker node (private)
	│   │   └── worker-public.sh       # Worker node (public)
	│   │
	│   ├── gs-spring-boot-0.1.0.jar   # Simple standalone java application (requires jre 8.1).
	│   └── <jre-8u66-linux-x64.tgz>   # Download from Oracle
	│
	├── <dcos_generate_config.sh>      # This is the core installer for DCOS from Mesosphere.
	├── java-spring-docker.json        # Marathon descriptor for docker based java spring application.
	├── java-spring.json               # Marathon descriptor for standalone java spring application.
	├── jenkins.json                   # Marathon descriptor for standalone jenkins, not currently functioning.
	├── oinker.json                    # Marathon descriptor for functioning twitter clone, use with cassandra
	├── README.md
	├── stress.json                    # Marathon descriptor for standalone commandline which uses CPU.
	├── VagrantConfig.yaml.example     # Used to define vagrant instances. Copy to VagrantConfig.yaml
	└── VagrantFile                    # Used to deploy various nodes (boot, masters and workers)

**Tested On**
- On a MacBook Pro (Retina, 13-inch, Early 2015), 2.7 GHz Intel Core i5, 15GB Memory
- Deploying single framework(s), cassandra.
- Deploying applications in the repo - spring.json, stress.json, oinker.json and router.json

1) Preparation
------------------

**1a)** Please review the [Appendix](#appendix) section for configuring local system settings, copying files and installing Vagrant + VirtualBox. This repo assumes a functioning vagrant is setup using the virtualbox provider.

**1b)** Ideally you'll want to use packer to build the base image along with the system requirements to install a cluster. This will significantly speed up bringing up a cluster from scratch. You can use the following commands to do this.

```bash
cd <repo>/build

packer build packer-template.json

cd ..

vagrant box add dcos build/centos-dcos.box
```

**1c)** Optionally use a standard base box

[non-updated OS](https://github.com/CommanderK5/packer-centos-template/releases/download/0.7.1/vagrant-centos-7.1.box) github.com/CommanderK5/packer-centos-template/releases/download/0.7.1/vagrant-centos-7.1.box

```bash
vagrant box add --name new-centos https://github.com/CommanderK5/packer-centos-template/releases/download/0.7.1/vagrant-centos-7.1.box
```

**1d)** You will need to ensure the internal private network for the cluster is configured to the 192.168.65.0/24 subnet. You can use the following command to create it on the vboxnet0 interface.

```bash
VBoxManage hostonlyif ipconfig vboxnet0 --ip 192.168.65.1
```

![Vagrant Network Settings](https://github.com/mesosphere/dcos-vagrant-demo/blob/master/docs/vbox_network.png?raw=true)

**1e)** You will need to download the dcos_generate_config.sh installer locally.

**Important**: Contact your sales representative or sales@mesosphere.io to obtain the DCOS setup file.

**1f)** Optionally review the commands to be executed by the VagrantFile. They are in `provision/bin`:

	.
	├── provision
	│   │
	│   ├── bin
	│   │   ├── base.sh                # Base OS for all nodes
	│   │   ├── boot.sh                # Bootstrap node
	│   │   ├── hosts.sh               # Hosts file for all nodes
	│   │   ├── master.sh              # Master node
	│   │   ├── worker-private.sh      # Worker node (private)
	│   │   └── worker-public.sh       # Worker node (public)

These commands can be easily extrapolated for a non-virtualbox (bare-metal, cloud, etc) installation as well.

**1f)** Configure the DCOS machine types (e.g. cpus, memory)

Copy one of the example VagrantConfig files:

```
cd <repo>
cp VagrantConfig.yaml.example VagrantConfig.yaml
```

Update `VagrantConfig.yaml` to match your requirements. Some frameworks (e.g. cassandra) may require more nodes/resources than others.

**IMPORTANT**: Make sure your local machine has enough memory to launch all your desired VMs, otherwise your machine will lock up as all the memory is consumed.


2) Example Deployment
------------------

###Prepare env

```bash
vagrant up boot m1 w1 w2 w3 lb
```

###Deploy java-spring app instance

**Deploy app**

```bash
dcos marathon app add marathon/java-spring.json
```

**Scale out**

```bash
dcos marathon app update marathon/java-spring instances=3
```

**Verify through dashboard, browser**

```bash
curl http://<ip>:<port>
```

###Deploy front-end LB

**Add Multi-verse to Config**

```bash
dcos config prepend package.sources \
https://github.com/mesosphere/multiverse/archive/version-1.x.zip

dcos package update --validate
```

**Deploy Marathon LB**

```bash
dcos package install marathon-lb --yes
```

**Refresh to see instances in pool**


```bash
curl http://spring.acme.org
```


Appendix
==================

### Single Master (boot node, master node, 3 x worker nodes)

> NOTE: This is a minimal configuration and will not support robust demos or deployments. Sample application deployments will work but not with frameworks.

```bash
cd <repo>

vi VagrantFile # Uncomment appropriate variable to define config.json eg. DCOS_CONFIG="1_master-config.json"

vagrant up boot m1 w1 w2 w3
```
> NOTE: This will support a minimal framework and application deployment. It was tested against the oinker app + cassandra.

```bash
vagrant up boot m1 w4 w5 w6
```

### Multi Master (boot node, 3 x master node, worker node)

> NOTE: This is a minimal configuration and will not support robust demos or deployments. Sample application deployments will work but not with frameworks.

```bash
cd <repo>

vi VagrantFile # Uncomment appropriate variable to define config.json eg. DCOS_CONFIG="3_master-config.json"

vagrant up boot

vagrant up m1 m2 m3 --no-provision
```

Next, In multiple terminals run the commands simultaneously

```bash
term1# vagrant provision m1
term2# vagrant provision m2
term3# vagrant provision m3
```

Next, deploy the worker node

```bash
vagrant up w1
```

### System Setup

1. Get the repo

	```bash
	git clone https://github.com/mesosphere/dcos-vagrant-demo
	```

2. Copy etc/hosts.file to your local hosts file (/etc/hosts)

	```bash
	cp <repo>/etc/hosts.file /etc/hosts
	```

3. Download the appropriate dcos_generate_config.sh file from Mesosphere and place into the root repo directory.

4. Install VirtualBox

	> https://www.virtualbox.org/wiki/Downloads

5. Intall Vagrant

	> http://www.vagrantup.com/downloads

### Vagrant Setup (Virtual Box)

**Networking**

- NatNetwork
 - DHCP
 - 10.0.1.0/24
 - No static port forwarding

- vboxnet0 
 - No DHCP
 - IP4 Address 192.168.65.1
 - Netmask 255.255.255.0

### Vagrant Setup Diagram

![Vagrant Diagram](https://github.com/mesosphere/dcos-vagrant-demo/blob/master/docs/dcos_vagrant_setup.png?raw=true)

License and Author
==================

Author:: Stathy Touloumis, Karl Isenberg

CreatedBy:: Stathy Touloumis (<stathy@mesosphere.com>)

Copyright:: 2015, Mesosphere

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

