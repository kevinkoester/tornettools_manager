#!/bin/bash -x


SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

INSTALL_PREFIX=${SCRIPT_DIR}/bin

function install_shadow {
	pushd ${SCRIPT_DIR}/dependencies/shadow
	./setup build --use-cpu-timer --prefix  ${INSTALL_PREFIX}
	./setup install
	popd
}

function install_shadow_plugin_tor {
	pushd ${SCRIPT_DIR}/dependencies/shadow-plugin-tor
	yes | ./setup dependencies
	yes | ./setup build --tor-prefix ../tor --prefix  ${INSTALL_PREFIX} --shadow-root ${INSTALL_PREFIX}
	./setup install
	popd
}

function install_tgen {
	mkdir dependencies/tgen/build
	pushd dependencies/tgen/build
	cmake .. -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX}
	make -j5
	make install
	popd
}

function install_tornettools {
	pushd dependencies/tornettools
	pip install wheel
	pip install -r requirements.txt
	pip install -I .
	popd
}
function install_oniontrace {
	mkdir dependencies/oniontrace/build
	pushd dependencies/oniontrace/build
	cmake .. -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX}
	make -j5
	make install
	popd
}

function install_oniontracetools {
	pushd dependencies/oniontrace/tools
	pip install -r requirements.txt
	pip install -I .
	popd
}

function install_tgentools {
	pushd dependencies/tgen/tools
	pip install -r requirements.txt
	pip install -I .
	popd
}


git submodule update --init --recursive
VENV_DIR=${SCRIPT_DIR}/venv
if [ ! -d "${VENV_DIR}" ]; then
	python3 -m venv ${VENV_DIR}
fi

source ${VENV_DIR}/bin/activate

pip install pyelftools

install_shadow
install_shadow_plugin_tor
install_tgen
install_tgentools
install_tornettools
install_oniontrace
install_oniontracetools
