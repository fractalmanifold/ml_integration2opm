mkdir ml2OPM && cd ml2OPM

CURRENT_DIRECTORY="$PWD"

# Dune modules
for module in common geometry grid istl
do   git -c http.sslVerify=false clone https://gitlab.dune-project.org/core/dune-$module.git
done
for module in common geometry grid istl
do   ./dune-common/bin/dunecontrol --only=dune-$module cmake -DCMAKE_DISABLE_FIND_PACKAGE_MPI=1
     ./dune-common/bin/dunecontrol --only=dune-$module make -j10
done

# OPM modules
for repo in common grid models simulators
do
    git -c http.sslVerify=false clone https://github.com/OPM/opm-$repo.git
done

mkdir build

for repo in common grid models
do
    mkdir build/opm-$repo
    cd build/opm-$repo
    cmake -DUSE_MPI=0 -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="$CURRENT_DIRECTORY/dune-common/build-cmake;$CURRENT_DIRECTORY/dune-grid/build-cmake;$CURRENT_DIRECTORY/dune-geometry/build-cmake;$CURRENT_DIRECTORY/dune-istl/build-cmake;$CURRENT_DIRECTORY/build/opm-common;$CURRENT_DIRECTORY/build/opm-grid" $CURRENT_DIRECTORY/opm-$repo
    make -j10
    cd ../..
done
