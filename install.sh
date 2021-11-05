#!/bin/bash -x


SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

INSTALL_PREFIX=${SCRIPT_DIR}/bin

TOR_COMMIT=main
#SHADOW_COMMIT=v1.15.0
SHADOW_COMMIT=v2.0.0
TORNETTOOLS_COMMIT=mods2

function get_shadow_version {
	shadow --version 2>&1 | perl -lne '/Shadow v([\d]+)\.[\d]+/ && print $1'
}

function install_shadow {
	pushd ${SCRIPT_DIR}/dependencies/shadow
	git checkout $SHADOW_COMMIT
	if [ "$(get_shadow_version)" -ge 2 ]; then
		./setup build --prefix  ${INSTALL_PREFIX}
	else
		./setup build --use-cpu-timer --prefix  ${INSTALL_PREFIX}
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
	yes | ./setup dependencies
	yes | ./setup build --tor-prefix ../tor --prefix  ${INSTALL_PREFIX} --shadow-root ${INSTALL_PREFIX} ${USE_ENCRYPTION}
	./setup install
	popd
}

function install_tgen {
	mkdir ${SCRIPT_DIR}/dependencies/tgen/build
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
	mkdir ${SCRIPT_DIR}/dependencies/oniontrace/build
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

optstring=":e"
while getopts ${optstring} arg; do
	case ${arg} in
	e)
		echo "Enabling encryption"
		USE_ENCRYPTION="--use-encryption"
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
