# Tornettools Manager

This software makes running [Tor](https://gitweb.torproject.org/tor.git) simulations using [Shadow](https://github.com/shadow/shadow) easy. Currently it focuses on comparing different settings for the `MaxCircuitDirtiness`. The maximum circuit dirtiness (MCD) dictates the time a circuit might get used after the first...

 
Only a single command is needed to download all dependencies, start and analyze a given time frame of the Tor network.

## Installation

Install dependencies (Debian 11):


```
# base
apt install git python3-venv cmake 

# heaptrack
apt install g++ libz-dev libboost-program-options-dev libboost-iostreams-dev libboost-system-dev  libboost-filesystem-dev libunwind-dev

# shadow
apt install cmake gcc g++ libc-dbg libglib2.0-dev libigraph-dev make python3 python3-pyelftools xz-utils

# shaodw plugin tor
apt install gcc automake autoconf zlib1g-dev liblzma5 liblzma-dev python2.7

```

If you get the error
```
error: conflicting types for ‘gettimeofday’
```
run
```
git apply gettimeofday.patch
```
and try again.

First clone the repository with submodules
```
git clone --recurse-submodules https://github.com/kevinkoester/tornettools_manager
```

If you have downloaded the source archive or cloned the repo without initializing the submodules run
```
git submodule update --init --recursive
```

After that run the `installation.sh` script to compile all dependencies. If you want to use different versions for Shadow or Tor, adjust the variables at the top.

Then run 
```
source ./activate_env.sh
```
to make all the binaries available.

## Usage

Parameters:

 * `--date`: Specify which month to use for the simulation in the format YYYY-MM.
 * `--dirty`: A list of dirtiness settings to use. For example "300,400"
 * `--scale`: The scale of the Tor network. A value of 1 would simulate 100% of the network while a value of 0.01 would simulate 1% of the network
 * `--output`: Specifies the output path where the results are saved. Depending on the size of the simulation this may take up several GB of storage
 * `--seed`: Specify the seed to use for the simulation. The same seed should produce the same results.
 * `--skip-parse`: Skips the parse phase. Currently we only detect if the simulation already ran, but not if we have already parsed the results. This flag can be used if you only changed the plot script.
 

Example with 8% network size on 2021-03 and a dirtiness of 300:

```
python3 ./tornetmanager.py -d 2021-03 --scale 0.08 --dirty 300  --output experiments --seed 123
```

