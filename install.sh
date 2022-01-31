#!/bin/bash -xe


SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

INSTALL_PREFIX=${SCRIPT_DIR}/bin

#TOR_COMMIT=heaptrack
TOR_COMMIT=tor-0.3.5.7
SHADOW_TOR_PLUGIN_COMMIT=heaptrack
SHADOW_COMMIT=master
TORNETTOOLS_COMMIT=mods

function get_shadow_version {
	shadow --version 2>&1 | perl -lne '/Shadow v([\d]+)\.[\d]+/ && print $1'
}

function install_heaptrack {
	mkdir -p ${SCRIPT_DIR}/dependencies/heaptrack/build
	pushd ${SCRIPT_DIR}/dependencies/heaptrack/build
	cmake .. -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX}
	make -j4
	make install
	popd
}

function install_shadow {
	pushd ${SCRIPT_DIR}/dependencies/shadow
	git checkout $SHADOW_COMMIT
	set +e
	./setup build --help | grep use-cpu-timer > /dev/null
	retcode=$?
	set -e
	if [ "$retcode" -eq "0"]; then
		./setup build --use-cpu-timer --prefix  ${INSTALL_PREFIX}
	else
		./setup build --prefix  ${INSTALL_PREFIX}
	fi
	./setup install
	popd
}

function install_tor {
	pushd ${SCRIPT_DIR}/dependencies/tor
	git checkout $TOR_COMMIT
	./autogen.sh
	./configure --disable-asciidoc --disable-unittests --disable-manpage --disable-html-manual --prefix ${INSTALL_PREFIX}
	make -j$(nproc)
	make install
	popd
}

function install_shadow_plugin_tor {
	pushd ${SCRIPT_DIR}/dependencies/shadow-plugin-tor
	pushd ../tor
	git checkout $TOR_COMMIT
	popd
	git checkout $SHADOW_TOR_PLUGIN_COMMIT
	yes | ./setup dependencies
	yes | ./setup build --tor-prefix ../tor --prefix  ${INSTALL_PREFIX} --shadow-root ${INSTALL_PREFIX} ${USE_ENCRYPTION} ${USE_HEAPTRACK} -j $(nproc)
	./setup install
	popd
}

function install_tgen {
	mkdir -p ${SCRIPT_DIR}/dependencies/tgen/build
	pushd ${SCRIPT_DIR}/dependencies/tgen/build
	cmake .. -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX}
	make -j5
	make install
	popd
}

function install_tornettools {
	pushd ${SCRIPT_DIR}/dependencies/tornettools
	git checkout $TORNETTOOLS_COMMIT
	pip install wheel
	pip install -r requirements.txt
	pip install -I .
	popd
}
function install_oniontrace {
	mkdir -p ${SCRIPT_DIR}/dependencies/oniontrace/build
	pushd dependencies/oniontrace/build
	cmake .. -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX}
	make -j5
	make install
	popd
}

function install_oniontracetools {
	pushd ${SCRIPT_DIR}/dependencies/oniontrace/tools
	pip install -r requirements.txt
	pip install -I .
	popd
}

function install_tgentools {
	pushd ${SCRIPT_DIR}/dependencies/tgen/tools
	pip install -r requirements.txt
	pip install -I .
	popd
}

optstring=":e:h"
while getopts ${optstring} arg; do
	case ${arg} in
	e)
		echo "Enabling encryption"
		USE_ENCRYPTION="--use-encryption"
		;;
	h)
		echo "Enabling heaptrack"
		USE_HEAPTRACK="--use-heaptrack"
		;;
	:)
		echo "$0: Must supply an argument to -$OPTARG." >&2
		exit 1
		;;
	?)
		echo "Invalid option: -${OPTARG}."
		exit 2
		;;
	esac
done

#git submodule update --init --recursive
VENV_DIR=${SCRIPT_DIR}/venv
if [ ! -d "${VENV_DIR}" ]; then
	python3 -m venv ${VENV_DIR}
fi

source ${SCRIPT_DIR}/activate_env.sh

pip install pyelftools
pip install requests

install_heaptrack
install_shadow
if [ "$(get_shadow_version)" -ge 2 ]; then
	install_tor
else
	install_shadow_plugin_tor
fi
install_tgen
install_tgentools
install_tornettools
install_oniontrace
install_oniontracetools
