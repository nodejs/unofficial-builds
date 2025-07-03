#!/bin/bash -eux

config_flags=
destCPU=x86
arch=x86
variation=

# GCC forbids SSE by default for x86 but it is required by Node.js so enable it manually
export CFLAGS='-msse2'
export CXXFLAGS='-msse2'
# export CFLAGS='-msse4.2'           # This can be used too for modern       CPUs (~2008)
# export CFLAGS='-mavx'              # This can be used too for modern       CPUs (~2011)
# export CFLAGS='-mavx2'             # This can be used too for modern       CPUs (~2013)
# export CFLAGS='-mavx2 -maes'       # This can be used too for modern       CPUs (~2015)
# export CFLAGS='-march=znver1'      # This can be used too for modern AMD   CPUs (~2017)
# export CFLAGS='-march=sandybridge' # This can be used too for modern Intel CPUs (~2011)

# x86 does not support _mm_cvtsi128_si64 instruction so forbid it's usage and fallback to non-SSE solution
cd "$nodeDir/deps/v8/src"
find  .  -name '*.cc'  -type f  -print0  |  xargs -0 sed -i -e 's/#ifdef __SSE2__/#if false/g'

# Replace %ifdef with #ifdef in assembler code
cd "$nodeDir/deps/openssl/config/archs/linux-elf/asm" &&
find  .  -name '*.S'  -type f  -print0  |  xargs -0 --no-run-if-empty sed -i -e 's/%ifdef/#ifdef/g' -e 's/%endif/#endif/g'

# Fix https://github.com/nodejs/node/issues/58458
str1='return __ Tuple<Word32, Word32>\(result, __ Word32Constant\(0\)\);'
str2='V<Word32> result_ = result;   return __ Tuple\(result_, __ Word32Constant\(0\)\);'
cd "$nodeDir/deps/v8/src/compiler/turboshaft" &&
[ -f int64-lowering-reducer.h ] && sed -i -E "s/$str1/$str2/g" int64-lowering-reducer.h
# https://github.com/nodejs/node/issues/58458#issuecomment-2916873746
# https://github.com/nodejs/node/commit/02f8cdb0c7a73d970ed7134a481a211bbd599c02

true  # To allow "&&" above
