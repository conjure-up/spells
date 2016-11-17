# The Canonical Distribution of Kubernetes
> This is the conjure-up spell

# Pre-requisites

You must setup your host to increase **max_user_instances** (https://github.com/lxc/lxd/blob/master/doc/production-setup.md#etcsysctlconf). In your **/etc/sysctl.conf** on the host system append this line:

```
fs.inotify.max_user_instances = 1048576
fs.inotify.max_queued_events = 1048576
fs.inotify.max_user_watches = 1048576
vm.max_map_count = 262144
```

Next run this as root:

```
$ sudo sysctl -p
```

Now you can run Canonical Kubernetes in the localhost provider within Juju.

```
$ conjure-up
```

# Authors

Adam Stokes <adam.stokes@ubuntu.com>

# Copyright

2016 Canonical, Ltd.
