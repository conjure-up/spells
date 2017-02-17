# spell sdk
> Providing helper routines for spell deployment and testing

## how to use

conjure-up exposes its spells directory which contains this sdk. By sourcing the
**common.sh** file in your bash scripts will give you access to several helper
functions that can be used to ease the process of exposing a final result,
accessing IP addresses of the environment and more.

The easiest way to make use of this sdk is with:

```
#!/bin/bash

set -eu

# Path to executing script
SCRIPT=$(readlink -e $0)

# Directory housing script
SCRIPTPATH=$(dirname $SCRIPT)

. $CONJURE_UP_SPELLSDIR/sdk/common.sh
```

Placed in the beginning of any steps or tests you want to utilize the sdk for.

## documentation

coming soon :)

## authors

Adam Stokes <adam.stokes@ubuntu.com>

## copyright

2017 Adam Stokes <adam.stokes@ubuntu.com>
2017 Canonical, Ltd.

## license

MIT
