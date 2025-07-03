#!/bin/bash -eux

setPython() {
	if [ "$MAJOR_VERSION" -ge 23 ]; then export PYTHON='python3.13';  return;  fi  # Python 3.13: Node.js v22.3  ~ latest (v24.3)
	if [ "$MAJOR_VERSION" -ge 15 ]; then export PYTHON='python3.9';   return;  fi  # Python 3.9:  Node.js v14.14 ~ latest (v24.3)
	if [ "$MAJOR_VERSION" -ge 4  ]; then export PYTHON='python2.7';   return;  fi  # Python 2.7:  Node.js v4.0   ~ v15.14 (latest)
	
	# Node.js v16.0 is first version not supporting Python 2.7 but supports Python 3.6 ~ 3.9 so Python 3.9 is chosen
}

setGCC() {
	if [ "$MAJOR_VERSION" -ge 23 ]; then source /opt/gcc15/enable;            return;  fi  # GCC 15.1:  Node.js v22.3 ~ latest (v24.3)  (v22.3~v22.17 has more compilation warnings)
	if [ "$MAJOR_VERSION" -ge 8  ]; then source /opt/rh/devtoolset-12/enable; return;  fi  # GCC 12.1:  Node.js v8.0  ~ v23.7
	                                                                                       # GCC 4.8.5: Node.js v4.0  ~ v10.14          (v9.0~v10.2 have compatibility warning by Node.js)
}
