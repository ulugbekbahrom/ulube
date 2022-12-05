#!/bin/bash

# declare variables

install_maven=
maven_version=
maven_install_path=
install_git=
git_version=
git_install_path=
install_java=
java_package=
install_postgresql=
postgresql_version=
postgresql_install_path=
sink=

# utilities

function install_general_prerequisites
{
    sudo dnf -y install make gcc wget > ${sink} 2>&1
}

function is_sudo
{
    if [[ $(id -u) -eq 0 ]] ; then
        true
    else
        false
    fi
}

function is_url_valid
{
    if wget -q --method=HEAD "$1"; then
        true
    else
        false
    fi
}

function is_installed
{
    if which $1 > /dev/null; then
        true
    else
        false
    fi
}

# main flow

function display_help
{
: '    while [ "$1" != "" ]; do
	case $1 in
		
		--install_maven )
			cat << EOF
			Command for installing maven.
			Takes 2 mandatory and 1 not mandatory arguments.
			Arguments: --install_maven [true or false], --maven_version [version-number], --verbose.
			Additionally, starts java download.
EOF
			shift;
			;;

		--maven_version )
			cat << EOF
			Command for checking maven version.
			Takes 1 argument.
			Argument: --maven_version
EOF
			shift;
			;;
		
		--install_git )
			cat << EOF
                        Command for installing git.
                        Takes 2 mandatory and 1 not mandatory arguments.
                        Arguments: --install_git [true or false], --git_version [version-number], --verbose
EOF
			shift;
			;;

		--git_version )
			cat << EOF
                        Command for checking git version.
                        Takes 1 argument.
                        Argument: --git_version
EOF
			shift;
			;;
		
		--git_install_path )
		       	cat << EOF
			Command for making install path of git.
			Argument: --git_install_path [directory]
EOF
			shift;
			;;

		--install_java )
			cat << EOF
			Command for installing java.
			Argument: --install-java [true or false]
EOF
			shift;
			;;
		
		--java_package )
			cat << EOF
			Command for java package.
			Argument: 1 argument for java package.
EOF
			shift;
			;;
		
		--install_postgresql )
			cat << EOF
			Command for installing postgres.
			Argument: --install-postgresql [postgresql-version]
EOF
			shift;
			;;
		
		--postgresql_version )
			cat << EOF
			Command for checking postgresql_version.
			Argument: --postgresql_version.
EOF
			shift;
			;;
		
		--postgresql_path )
			cat << EOF
			Command for making postgresql directory.
			Argument: --postgresql_path [directory]
EOF
			shift;
			;;

		-a | --install_all )
			cat << EOF
                        Command for installing git, maven, java, postgres.
                        Takes no argument.
EOF
			;;
		
		-v | --verbose )
			echo "verbose option"
			;;
		
		-h | --help )
			echo "help display"
			;;

	esac
	shift
   done
'
}

function set_defaults
{
    install_maven=false
    maven_version=3.8.6
    maven_install_path=/opt

    install_git=false
    git_version=2.3.1
    git_install_path=/usr/local

    install_java=false
    java_package=java-17-openjdk
    #java-1.8.0-openjdk.x86_64

    install_postgresql=false
    postgresql_version=9.2.3
    postgresql_install_path=/usr/local/pgsql

    sink=/dev/null
}

function parse_options 
{
  args=()

  while [ "$1" != "" ]; do
    case "$1" in
        
        --install_maven )           
            install_maven="$2";
            # install_java=true;          # java is maven dependacy
            shift;
            ;;

        --maven_version )           
            maven_version=$2;          
            shift;
            ;;
        
        --install_git )
            install_git="$2";
            shift;
            ;;

        --git_version )
            git_version="$2";
            shift;
            ;;

        --git_install_path )
            git_install_path="$2";
            shift;
            ;;

        --install_java )               
            install_java="$2";
            shift;
            ;;

        --java_package )               
            java_package="$2";
            shift;
            ;;
        
        --install_postgresql )
            install_postgresql="$2";
            shift;
            ;;

        --postgresql_version )
            postgresql_version="$2";
            shift;
            ;;

        --postgresql_path )
            postgresql_path="$2";
            shift;
            ;;

        -a | --install_all )
            install_maven=true;
            install_git=true;
            install_java=true;
            install_postgresql=true;
            ;;
          
        -v | --verbose )
            sink=/dev/stdout
            ;;
            
        
        -h | --help )
            display_help;
            exit;;

    esac
    shift
  done

  set -- "${args[@]}"

}

function install_git
{
    local git_version="$1"
    local git_install_path="$2"

    local git_url="https://www.kernel.org/pub/software/scm/git/git-${git_version}.tar.gz"
    local git_archive_name="git-${git_version}.tar.gz"
    local git_folder_name="git-${git_version}"

    printf "\nStarting git installation ${git_version} in ${git_install_path}"

    if ! is_url_valid ${git_url} ; then
        printf "\nInvalid URL link for git"
        printf "\nMake sure you have entered valid git version"
        return
    fi

    # install dependecies
    sudo dnf install -y dh-autoreconf curl-devel expat-devel gettext-devel openssl-devel perl-devel zlib-devel

    # create install path if it does exist
    mkdir -p ${git_install_path}

    # download source code
    wget ${git_url} > ${sink} 2>&1

    # extract the archive
    tar -zxf ${git_archive_name} > ${sink} 2>&1

    # enter the directory
    cd ${git_folder_name}

    # compile
    make configure > ${sink} 2>&1
    ./configure --prefix=${git_install_path} > ${sink} 2>&1
    make all > ${sink}

    # install
    sudo make install > ${sink} 2>&1
    sudo ldconfig > ${sink} 2>&1

    # exit directory and delete residues
    cd ..
    rm -f ${git_archive_name}
    rm -rf ${git_folder_name}
}

function install_java
{
    local java_package=$1

    printf "\nStarting java installation of ${java_package}"

    ### Here we should add code to check if package name is correct

    sudo dnf install -y ${java_package} > ${sink} 2>&1

    ### sudo apt install -y ${java_package} > ${sink} 2>&1
}

function install_postgresql
{
    local postgresql_version=$1
    local postgresql_install_path=$2

    local postgresql_url="https://ftp.postgresql.org/pub/source/v${postgresql_version}/postgresql-${postgresql_version}.tar.bz2"
    local postgresql_archive_name="postgresql-${postgresql_version}.tar.bz2"
    local postgresql_folder_name="postgresql-${postgresql_version}"

    printf "\nStarting PostgreSQL ${postgresql_version} installation in ${postgresql_install_path}"

    if ! is_url_valid ${postgresql_url} ; then
        printf "\nInvalid URL link for PostrgreSQL"
        printf "\nMake sure you have entered valid PostgreSQL version"
        return
    fi

    # install dependecies
    sudo dnf -y install zlib-devel readline-devel flex-devel> ${sink} 2>&1

    ### sudo apt install -y make gcc zlib1g-dev libreadline-dev wget
    
    # create install path if it does exist
    sudo mkdir -p ${postgresql_install_path}

    # download source code
    wget ${postgresql_url} > ${sink} 2>&1

    # extract the archive
    tar jxvf ${postgresql_archive_name} > ${sink} 2>&1

    # enter the directory
    cd ${postgresql_folder_name}

    # compile
    ./configure --prefix=${postgresql_install_path} > ${sink} 2>&1
    make ${sink}

    # install
    sudo make install > ${sink} 2>&1
    sudo ldconfig > ${sink} 2>&1

    # exit directory and delete residues
    cd ..
    rm -f ${postgresql_archive_name}
    rm -rf ${postgresql_folder_name}
}

function install_maven
{
    local maven_version="$1"
    local maven_install_path="$2"

    local maven_url="https://dlcdn.apache.org/maven/maven-3/${maven_version}/binaries/apache-maven-${maven_version}-bin.tar.gz"
    local maven_archive_name="apache-maven-${maven_version}-bin.tar.gz"
    local maven_folder_name="apache-maven-${maven_version}"

    printf "\nStarting Maven ${maven_version} installation in ${maven_install_path}"

    if ! is_url_valid ${maven_url} ; then
        printf "\nInvalid URL link for Maven"
        printf "\nMake sure you have entered valid Maven version"
        printf "\n${maven_url}"
        return
    fi

    # create install path if it does exist
    mkdir -p ${maven_install_path}

    # download source code
    wget ${maven_url} > ${sink} 2>&1

    # extract the archive
    tar xzf ${maven_archive_name} -C ${maven_install_path}> ${sink} 2>&1

    # save current path
    local curr_dir=$(pwd)

    # enter the directory
    cd ${maven_install_path}
    mv ${maven_folder_name} maven

    # create Maven envirnoment

    local home_dir=/home/$SUDO_USER

    echo "export M2_HOME=$maven_install_path/maven" >> ${home_dir}/.bashrc
    echo "export PATH=\${M2_HOME}/bin:\${PATH}" >> ${home_dir}/.bashrc

    # exit directory and delete residues
    cd ${curr_dir}
    rm -f ${maven_archive_name}
}

set_defaults

parse_options "$@"

install_general_prerequisites

if ! is_sudo; then
    printf "\nThis script should be run with root privileges\n\n"
    exit;
fi

if [ ${install_git} = "true" ]; then
    if is_installed "git" ; then
        printf "\n Git already installed"
    else
        install_git ${git_version} ${git_install_path}
    fi
fi

if [ ${install_java} = "true" ]; then
    if is_installed "javac" ; then
        printf "\n Java already installed"
    else
        install_java ${java_package}
    fi
fi

if [ ${install_postgresql} = "true" ]; then
    install_postgresql ${postgresql_version} ${postgresql_install_path}
fi

if [ ${install_maven} = "true" ]; then
    if is_installed "mvn" ; then
        printf "\n Maven already installed"
    else
        install_maven ${maven_version} ${maven_install_path}
    fi
fi

printf "\n\n"
