#!/bin/bash

#TODO

#if [ "$USER" == "root" ]; then
# echo " [*] NO Lo corras con sudo ni como root  ---gato"
#  exit 0
#fi 

#Variables#########
NPROC=$(nproc)
DISTRO=""
NODO=""
BOOST_VERSION=""
###################


usage () {
cat << EOF
NAME
    
    bitshares nodo builder 


SYNOPSIS

    nodo-builder.sh [-h|--help]
                    [--full] [--lowmen] [--mini]
                    [--debian] [--ubuntu]
                    [--boost=<version>] ex: --boost=60


DESCRIPTION

    nodo-builder es un builder para witnesses de bitshares
    genera 3 tipos distintos de nodos, los full para firmar
    bloques, los lowmen para pricefeeds y los mini (en beta)
    para tener un nodo local no witness.


OPTIONS

    -h, --help
            se explica solo, si no lo entendes no uses un witness.
    --full
            levanta un witness full node con partial-operations true
            y max-ops-per-account 100

    --lowmen
            sirve para block producers tanto main como failover.
            Compila bitshares-core con history plugins deshabilitados
    --boost
            sirve para inidcar que version de boost queremos usar.
            Ex: --boost=59
    --debian
            Buildea para debian
    --ubuntu
            Buildea para ubuntu


EXAMPLES

    SHELL> nodo-builder.sh --debian --full --boost=60

Apretale la q!
EOF
}




#############################
#Instalando dependencias
#############################

dependencias_debian() {

set -x
ps axjf
apt --assume-yes  install  $(tr  '\n' ' ' < config/dependencias-debian)

      cd ~
      git clone https://github.com/cryptonomex/secp256k1-zkp.git
      cd secp256k1-zkp
      ./autogen.sh
      ./configure
      make  -j$NPROC

}

dependencias_ubuntu() {

apt --assume-yes  install  $(tr  '\n' ' ' < config/dependencias-ubuntu)

      cd ~
      git clone https://github.com/cryptonomex/secp256k1-zkp.git
      cd secp256k1-zkp
      ./autogen.sh
      ./configure
      make  -j$NPROC


}

boost() {

printf "###########################"
printf "#    Instalando boost     #"
printf "###########################"
    url=http://sourceforge.net/projects/boost/files/boost/1.${BOOST_VERSION}.0/boost_1_${BOOST_VERSION}_0.tar.bz2/download
    cd /$HOME/tmp
    time wget -c $url -O boost_1_${BOOST_VERSION}_0.tar.bz2
    time tar xjf boost_1_${BOOST_VERSION}_0.tar.bz2
    cd boost_1_${BOOST_VERSION}_0/
    BOOST_ROOT=$HOME/boost_1_${BOOST_VERSION}_0
    set -x
    time ./bootstrap.sh "--prefix=$BOOST_ROOT"
    time ./b2 install
}

config_final() {

    cd /$HOME/nodo-builder/config
    tar -xzf blockchain.tar.gz
    mv blockchain/  /$HOME/bitshares-core/programs/witness_node/witness_node_data_dir/
}


bitshares_clone() {
  read -p "queres compilar bitshare-core? Y/N" -n 1 -r
  echo ""

  if [[ $REPLY =~ ^[Yy]$ ]]
    	then
            echo ""
            echo ""
			printf "\n\n###########################"
			printf "# clonando bitshares-core"
			printf "##########################\n\n"
			cd /$HOME
			set -x
            git clone https://github.com/bitshares/bitshares-core.git
			cd /$HOME/bitshares-core/
			git checkout master
			git submodule update --init --recursive
			cmake -DBOOST_ROOT="$BOOST_ROOT" -DCMAKE_BUILD_TYPE=RelWithDebInfo .
			time make -j$NPROC
        else
          echo ""
          echo "chau, hacelo a mano"
          echo ""
          exit 0
      fi


}

##Argumentos
while true; do
    case $1 in
        -h | --help )
            clear > /dev/null;
            usage | less;
            exit 0
            ;;
        --boost=* )
            BOOST_VERSION="${1#*=}";
            shift
            ;;
        --full )
            NODO="full";
            shift
            ;;
        --lowmen=* )
            NODO="lowmen";
            shift
            ;;
        --mini=* )
            NODO="mini"
            shift
            ;;
        --debian )
            DISTRO="debian"
            shift
            ;;
        --ubuntu )
            DISTRO="ubuntu"
            shift
            ;;
        -* )
            printf 'recatate y leete el usage "%s" no es una opcion \n' "${1}";
            exit 0
            ;;
        * )
      #      usage;
            break
            ;;
        esac
    done


if [ -z "${BOOST_VERSION}" ] || [ -z "${NODO}" ] || [ -z "${DISTRO}" ]; then
    usage | less
    exit 0
fi

if  [ $DISTRO = "ubuntu" ]; then
    dependencias_ubuntu
fi

if [ $DISTRO = "debian" ]; then
    dependencias_debian
fi
#Config inicial
dpkg-reconfigure locales
#llamada a funciones
boost
bitshares_clone
config_final
