#!/usr/bin/python2.7

# Copyyright(C) 2017 Felipe Alfaro Solana <felipe.alfaro@gmail.com>

"""Add Docker profile to LXD containers for Juju unit "nova-compute".

Uses LXD REST API via the local UNIX domain socket as document in the
following URL: https://github.com/lxc/lxd/blob/master/doc/rest-api.md
"""

import json
import subprocess
import urllib

import requests_unixsocket


def get_profiles(session, host, container):
    """Retrieves the list of profiles of an LXD container."""

    url = 'http+unix://%(host)s/1.0/containers/%(container)s' % {
        'host': host,
        'container': container,
    }
    response = session.get(url)
    assert response.status_code == 200, response
    profiles = set(response.json()['metadata']['profiles'])
    return profiles


def set_profiles(session, host, container, profiles):
    """Updates the profiles of an LXD container."""

    url = 'http+unix://%(host)s/1.0/containers/%(container)s' % {
        'host': host,
        'container': container,
    }
    data = {
        'profiles': list(profiles),
    }
    json_data = json.dumps(data)
    response = session.patch(url, data=json_data)
    assert response.status_code == 200, response


def get_container_list(juju_unit):
    """Get the list of LXD containers where the Juju unit is running."""

    containers = []
    proc = subprocess.Popen(['juju', 'status', '--format', 'json', juju_unit],
                            stdout=subprocess.PIPE)
    stdout, _ = proc.communicate()
    j = json.loads(stdout)
    for _, machine_data in j['machines'].iteritems():
        containers.append(machine_data['instance-id'])
    return containers


def main():
    """Adds the docker profile to all LXD containers for nova-compute."""

    # UNIX socket where LXD domain listens
    host = urllib.quote_plus('/var/lib/lxd/unix.socket')

    session = requests_unixsocket.Session()

    containers = get_container_list(juju_unit='nova-compute')
    for container in containers:
        profiles = get_profiles(session, host, container)
        profiles.add('docker')
        print('Setting profiles of LXD container "%s" to "%s".' % (
            container, ','.join(profiles)))
        set_profiles(session, host, container, profiles)


if __name__ == '__main__':
    main()
