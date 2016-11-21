# kubernetes core spell

# prereqs

You must setup your host to increase **max_user_instances** (https://github.com/lxc/lxd/blob/master/doc/production-setup.md#etcsysctlconf). In your **/etc/sysctl.conf** on the host system append this line:

```
fs.inotify.max_user_instances = 1048576
fs.inotify.max_queued_events = 1048576
fs.inotify.max_user_watches = 1048576
vm.max_map_count = 262144
```

Next run this as root:

```
sudo sysctl -p
```

Now you can run canonical kubernetes in the localhost provider within Juju.

# usage

```
conjure-up kubernetes
```
