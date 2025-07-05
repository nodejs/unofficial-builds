#!/bin/bash -eu

# Copies files from recipes/x64-glibc-217 to:
#     recipes/x64-pointer-compression
#     recipes/x86

__dirname="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
recipesDir="$(dirname "$__dirname")/recipes"
srcRecipeDir="$recipesDir/x64-glibc-217"



# Copy to x64-pointer-compression

for dirBase in x64-pointer-compression; do
	  destRecipeDir="$recipesDir/$dirBase"
	  mkdir -p "$destRecipeDir/files"
	
	  cp -f  "$srcRecipeDir/Dockerfile"      "$destRecipeDir/"
	  cp -f  "$srcRecipeDir/run.sh"          "$destRecipeDir/"
	# cp -f  "$srcRecipeDir/run_other.sh"    "$destRecipeDir/"  # Recipe specific code
	  cp -f  "$srcRecipeDir/run_versions.sh" "$destRecipeDir/"
	# cp -f  "$srcRecipeDir/should-build.sh" "$destRecipeDir/"  # Pointer compression is supported from v13.4
	  cp -rf "$srcRecipeDir/files/"*         "$destRecipeDir/files/"
done



# Copy to x86

if true; then
	  destRecipeDir="$recipesDir/x86"
	  mkdir -p "$destRecipeDir/files"
	  
	  cp -f  "$srcRecipeDir/Dockerfile"      "$destRecipeDir/"
	  cp -f  "$srcRecipeDir/run.sh"          "$destRecipeDir/"
	# cp -f  "$srcRecipeDir/run_other.sh"    "$destRecipeDir/"  # Recipe specific code
	# cp -f  "$srcRecipeDir/run_versions.sh" "$destRecipeDir/"  # Different versions of programs are used  (because devtoolset-12 is not available)
	# cp -f  "$srcRecipeDir/should-build.sh" "$destRecipeDir/"
	  
	# cp -f "$srcRecipeDir/files/"*.repo                "$destRecipeDir/files/"  # Different versions of programs are used  (because devtoolset-12 is not available)
	# cp -f "$srcRecipeDir/files/installPrerequisites"  "$destRecipeDir/files/"  # Different versions of programs are used  (because devtoolset-12 is not available)
	  cp -f "$srcRecipeDir/files/installFromSourceCode" "$destRecipeDir/files/"
	  cp -f "$srcRecipeDir/files/opt__gcc15__enable"    "$destRecipeDir/files/"
	  
	  sed -i -e 's/ --platform=linux\/amd64 / --platform=linux\/386 /g'     "$destRecipeDir/Dockerfile"
	  sed -i -E 's/# RUN (.* binutils )/RUN   \1/g'                         "$destRecipeDir/Dockerfile"
	  sed -i -E 's/--build=x86_64-redhat-linux/--build=i686-redhat-linux/g' "$destRecipeDir/Dockerfile"
	# sed -i -e 's/gcc-15.1.0/gcc-12.4.0/g'                                 "$destRecipeDir/Dockerfile"
	# sed -i -e 's/gcc15/gcc12/g'                                           "$destRecipeDir/Dockerfile"  "$destRecipeDir/files/opt__gcc12__enable"  "$destRecipeDir/files/installFromSourceCode"
	  sed -i -e 's/devtoolset-12/devtoolset-9/g'                            "$destRecipeDir/files/opt__gcc"*'__enable'
fi
