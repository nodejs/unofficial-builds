#!/bin/bash -eux

setPython() {
	if isNodeVersionGE 'v22.3';  then export PYTHON='python3.13';  return;  fi  # Python 3.13: Node.js v22.3  ~ latest (v24.3)
	if isNodeVersionGE 'v14.14'; then export PYTHON='python3.9';   return;  fi  # Python 3.9:  Node.js v14.14 ~ latest (v24.3)
	if isNodeVersionGE 'v4.0';   then export PYTHON='python2.7';   return;  fi  # Python 2.7:  Node.js v4.0   ~ v15.14 (latest)
	
	# Node.js v16.0 is first version not supporting Python 2.7 but supports Python 3.6 ~ 3.9 so Python 3.9 is chosen
}

setGCC() {
	if isNodeVersionGE 'v22.3';  then source /opt/gcc15/enable;            return;  fi  # GCC 15.1:  Node.js v22.3 ~ latest (v24.3)  (v22.3~v22.17 has more compilation warnings)
	if isNodeVersionGE 'v7.10';  then source /opt/rh/devtoolset-9/enable;  return;  fi  # GCC 9.3:   Node.js v7.10 ~ v21.7 (latest)  (v20.0~v21.7 has compatibility warning by Node.js)
	                                                                                    # GCC 4.8.5: Node.js v4.0  ~ v10.14          (v9.0~v10.2 have compatibility warning by Node.js)
	
	# Node.js v22.0 is first version not supporting GCC 9.3 but supports GCC 12.4- so GCC 12.4
	# should be chosen, but support of v22.0~v22.2 is dropped and GCC 15.1 is chosen instead
}
