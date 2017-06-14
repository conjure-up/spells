sudo patch -d/ -p0 --dry-run << EOF &>/dev/null || exposeResult "Unable to patch Nova/LXD driver." 1 "false"
--- /usr/lib/python2.7/dist-packages/nova_lxd/nova/virt/lxd/config.py.orig	2017-06-13 16:28:47.787500165 +0000
+++ /usr/lib/python2.7/dist-packages/nova_lxd/nova/virt/lxd/config.py	2017-06-13 16:29:48.370404003 +0000
@@ -56,11 +56,17 @@
         instance_name = instance.name
         try:
 
+            # Profiles to be applied to the container
+            profiles = [str(instance.name)]
+            lxd_profiles = instance.flavor.extra_specs.get('lxd:profiles')
+            if lxd_profiles:
+                profiles += lxd_profiles.split(',')
+
             # Fetch the container configuration from the current nova
             # instance object
             container_config = {
                 'name': instance_name,
-                'profiles': [str(instance.name)],
+                'profiles': profiles,
                 'source': self.get_container_source(instance),
                 'devices': {}
             }
EOF
sudo service nova-compute restart
exposeResult "Nova/LXD has been patched for Docker support via Nova flavors." 0 "true"
