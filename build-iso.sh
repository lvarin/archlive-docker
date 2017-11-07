#!/bin/bash
#

ACTION=$1

pushd "$(dirname "$0")" >/dev/null

if [ -z "$ACTION" ];
then
    if ! which docker >/dev/null;
    then
        echo "Docker is not installed"
        exit 1
    fi

    docker run -it --rm -v $PWD:/root/src/ --workdir /root/src/ --privileged base/archlinux /root/src/$0 build

elif [ "$ACTION" == 'build' ];
then
    if [ -d archlive ];
    then
        echo "Cleaning previous run"
        rm -fv archlive/work/build.make_*
    else
        mkdir archlive
    fi

    echo "Installing dependecies"
    pacman -Sy
    pacman -S git archiso rsync --noconfirm

    echo "Rsyncing the template, so we have a copy to modify"
    rsync -av /usr/share/archiso/configs/releng/ archlive/

    echo "Mix our and arch's file with the packages"
    cat archlive/packages.both packages.both >packages.mixed
    cp -f packages.mixed archlive/packages.both
    rm packages.mixed

    echo "Build the ISO"
    pushd archlive
    ./build.sh -v
    if [ "$?" -ne 0 ];
    then
        echo "*****" >&2
        echo "Something failed, check out output" >&2
        echo "*****" >&2
        exit 2
    fi
    popd

    echo "If all went fine the ISO is at: archlive/out/"
else
    echo "Unrecognized command" >&2
    exit 3
fi
