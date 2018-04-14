# JFrog Artifactory Enterprise Addon to Canonical-Kubernetes Spell

Select this Addon to install Artifactory Enterprise on a Canonical Distribution of Kubernetes (CDK) Cluster in the cloud (currently AWS only) and region you have already selected. After completing this installation JFrog Artifactory will be installed on your Kubernetes cluster. Once you apply the Artifactory licenses you will be able to use Artifactory as a Docker registry, Helm repo, NPM repo and more.

## Prerequistes:

- AWS:- Amazon AWS Account setup with all priveleges required to create a Kubernetes Cluster, create persistent storage, and run load balancers.

- AWS Secret and Key available.

- Installation machine (where you install and run conjure-up)
  -  sudo privielges
  -  OS is certified by JFrog(http://www.jfrog.com) and Canonical(http://wwww.canonical.com)(e.g Ubuntu 16.04 LTS).
  -  Conjure-up dependenices installed (python, jq, perl)


- conjure-up installed. Please see http://conjure-up.io for more details on conjure-up. Please note that JFrog has tested using the Locally Hosted Controller option. Juju as A Service (Jaas) option has not been cerfified by JFrog.

- Licenses for Artifactory Enterprise Edition 5.9 or later versions from JFrog. You can obtain Enterprise Edition trial licenses from https://jfrog.com/artifactory/free-trial/#enterprise

## Basic installation

1. Run "conjure-up canonical-kubernetes --bundle-add channels.yaml" where channels.yaml has the following text:

```applications:
  kubernetes-master:
    options:
      channel: 1.9/stable
  kubernetes-worker:
    options:
      channel: 1.9/stable
```

Select JFrog Addon.


![JFrog_Addon](images/jfrog_addon.png)


2. For a defult basic installation, accept all default choices for JFrog menu items and select Next to deploy all.

![ArtifactorySelectionsP1](images/selectionp1.png)

![ArtifactorySelectionP2](images/selectionp2.png)



3. After you see the "Your big software is deployed", you can see the succesful installation of Artifactory message. If you do not, scroll down and follow the instruction to obtain the Artifactory URL.  This is how the screen looks like:

![PostDeployScreen](images/postdeploy.png)


The main command to use here is "kubectl get svc -o wide". On AWS, the external hostname of the LoadBalancer for nginx is the one that needs to be used as the artifactory URL. Opening up the Artifactory URL will them ask you provide the Licenses and the Artifactory documentation can then be followed to configure Artifactory.

For detailed explanation of how to find the URL of artifactory, please review the documentation available on official Kubernetes charts maintained on Github at https://github.com/kubernetes/charts/tree/master/stable/artifactory-ha

## Custom installation

If the Basic installation is not suitable, then instead of accepting the defaults, the selections can be changed. Here is a brief description of the choices provided.

1. Database User: Artifactory by default creates a PostgresQL database user with the id artifactory. You can change the database user here.
2. Database password: You change the default password for the database here.
3. Force Reinstall Helm: You can use this to reinstall a new version
4. Helm version: If you would like a specific version due to known issues with the latest, you can specify it here.
5. Use Ingress Controller: Set this to true if you would prefer to use Ingress controller instead of explicit nginx container. Please note that using Ingress Controller is not recommended as this feature is still experimental.
6. Artifactory Service Type: Recommended to use LoadBalancer. NodePort is preferred if you already have a LoadBalancer.
7. Artifactory release name and path. You can specify your own name and release path here. For examnple, --name myartifactory stable/artifactory.
8. Configure TLS can be set to true and in this case, provide the TLS cert and TLS key file location and the secret file name.


Additional customizations can be made by including the appropriate values in values.yaml in JFrog Addon. Consult official JFrog documentation for details


## Developer Notes on Various Issues

### Persistence Storage Handling

The installation silently creates a Persistence Storage Class definition with the name jfrogstandard. This storage class name is referred to in the install via the values.yaml. There is a template for storageclass generation with the name zstorageclass.yaml with the following contents.

```
apiVersion: storage.k8s.io/v1
metadata:
  name: jfrogstandard
  annotations:
    storageclass.beta.kubernetes.io/is-default-class: "false"
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp2
  zone: ZONE
reclaimPolicy: Retain
mountOptions:
  - debug
```

Using the "juju status" command, we obtain a list of applicable zones and pick the first one and generate a new storageclass file replacing the ZONE value with the selected ZONE. So the generated storageclass file gen_storageclass.yaml would look like this.
```
apiVersion: storage.k8s.io/v1
metadata:
  name: jfrogstandard
  annotations:
    storageclass.beta.kubernetes.io/is-default-class: "false"
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp2
  zone: us-east-1a
reclaimPolicy: Retain
mountOptions:
  - debug
```

This file is then used by the addon script to create a persistence storageclass via the kubectl command

### Post Install Display message

After the installation is complete, it generally takes a while for all pods deployed to be active and runnning and also to access the URL of the artifactory, the LoadBalancer has to publish the external IP or hostname.  We could point to the Helm installer output log files but that output at this time is also not specific to the current cloud deployment. So currently we provide very basic general instructions to get the LoadBalancer URL and refer to our published documentation for mode details.

Please note that to see the post install message, on conjure-up output you might have to scroll down to see the screen.
This might be changed in future.

### Ingress Controller Feature

It is not recommended to use Ingress Controller functionality as it is still experimental.


### Local build and test environment setup

To have a local build and test environment setup it is essential to  1) install conjure-up and 2) locally populate the spell directory canonical-kubernetes and the jfrog addon scripts together in one working directory and then execute conjure-up pointing to the local working directory.

1. Install conjure-up. (sudo snap install conjure-up)
2. mkdir conjure-up-base.
3. cd conjure-up-base; git clone conjure-up-spells; cd ..
4. mkdir addon-base; git clone JFrogDev/soldev; cd ..
5. mkdir workingdir; copy canonical-kubernetes from conjure-up-base; copy addon from JFrogDev to addon under canonical-kuberbetes.
6. cd canonical-kubernetes; conjure-up .
7. Follow the prompts. (Later on, will provide updates about unattended install if it is supported by conjure-up for the addons also)


#### A note about debug messages and logs in debugging conjure-up.

Any debug outputs are echo statements in the addon scripts show up on the conjure-up screen at the lower status bar, but they get replaced by the next one. If these need to be reviewed post install, then navigate to ~/.cache/conjure-up directroy and locate the addon script directory and see files with .out and .err extensions. They include all the standard output and standard error messages of the scripts. The output of helm installer for JFrog artifactory is redirected in the adodn script to a log file jfrog_installer.log and this along the with other .out and .err can be used to debug any issues.

## References

Conjure-up documentation - https://conjure-up.io/

Artifactory documentation - http://wwww.jfrog.com

JFrog addon to spell Canonical-Kubernetes documentation - https://github.com/JFrogDev/soldev/blob/master/canonical/integration/canonical-kubernetes/addons/jfrog/README.md

Conjure-up on Github - https://github.com/conjure-up

JFrogDev on Github  -  https://github.com/JFrogDev/soldev