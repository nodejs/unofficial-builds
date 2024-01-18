#!/usr/bin/env bash

set -e
set -x

release_urlbase="$1"
disttype="$2"
customtag="$3"
datestring="$4"
commit="$5"
fullversion="$6"
source_url="$7"
config_flags=

cd /home/node

tar -xf node.tar.xz
cd "node-${fullversion}"

# see https://github.com/nodejs/node/pull/45756
cat << "EOF" > correct-cflags.patch
diff --git a/configure.py b/configure.py
index a6dae354d4233..e2bb9dce12795 100755
--- a/configure.py
+++ b/configure.py
@@ -1247,9 +1247,7 @@ def configure_node(o):
 
   o['variables']['want_separate_host_toolset'] = int(cross_compiling)
 
-  # Enable branch protection for arm64
   if target_arch == 'arm64':
-    o['cflags']+=['-msign-return-address=all']
     o['variables']['arm_fpu'] = options.arm_fpu or 'neon'
 
   if options.node_snapshot_main is not None:
diff --git a/node.gyp b/node.gyp
index 448cb8a8c7cd4..6cec024ffe722 100644
--- a/node.gyp
+++ b/node.gyp
@@ -109,6 +109,9 @@
     },
 
     'conditions': [
+      ['target_arch=="arm64"', {
+        'cflags': ['-msign-return-address=all'],  # Pointer authentication.
+      }],
       ['OS in "aix os400"', {
         'ldflags': [
           '-Wl,-bnoerrmsg',
EOF
git apply correct-cflags.patch --verbose
rm -f correct-cflags.patch

export CC_host="ccache gcc-8"
export CXX_host="ccache g++-8"
export CC="ccache aarch64-linux-gnu-gcc-8"
export CXX="ccache aarch64-linux-gnu-g++-8"

make -j$(getconf _NPROCESSORS_ONLN) binary V= \
  DESTCPU="arm64" \
  ARCH="arm64" \
  VARIATION="" \
  DISTTYPE="$disttype" \
  CUSTOMTAG="$customtag" \
  DATESTRING="$datestring" \
  COMMIT="$commit" \
  RELEASE_URLBASE="$release_urlbase" \
  CONFIG_FLAGS="$config_flags"

mv node-*.tar.?z /out/
