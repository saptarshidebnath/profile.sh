#!/usr/bin/env bash

function helpAndUsage(){
	echo "This small utility installs and updates openjdk 7 / 8 and 9 in an linux system using apt-get as installer. It also switches JAVA_HOME environment variable accordingly."
	echo "Usage : jdk 7"
}

function cleanJava(){
	dpkg-query -W -f='${binary:Package}\n' | grep -E -e '^(ia32-)?(sun|oracle)-java' -e '^openjdk-' -e '^icedtea' -e '^(default|gcj)-j(re|dk)' -e '^gcj-(.*)-j(re|dk)' -e '^java-common' | xargs sudo apt-get -y remove
    sudo apt-get -y autoremove
    dpkg -l | grep ^rc | awk '{print($2)}' | xargs sudo apt-get -y purge
    sudo bash -c 'ls -d /home/*/.java' | xargs sudo rm -rf
    sudo rm -rf /usr/lib/jvm/*
    for g in ControlPanel java java_vm javaws jcontrol jexec keytool mozilla-javaplugin.so orbd pack200 policytool rmid rmiregistry servertool tnameserv unpack200 appletviewer apt extcheck HtmlConverter idlj jar jarsigner javac javadoc javah javap jconsole jdb jhat jinfo jmap jps jrunscript jsadebugd jstack jstat jstatd native2ascii rmic schemagen serialver wsgen wsimport xjc xulrunner-1.9-javaplugin.so; do sudo update-alternatives --remove-all $g; done
    sudo updatedb
    echo "---"
    echo "Please delete the files if required"
    echo "---"
    sudo locate -b '\pack200'
}

function installJdk(){
	if [[ $# != 1 ]]; then
		helpAndUsage
		return 3
	fi
	__version=$1
	__is_ppa_added=$( find /etc/apt/ -name *.list | xargs cat | grep  ^[[:space:]]*deb | grep openjdk | wc -l )
	if [[ ${__is_ppa_added} != 1 ]]; then
		echo "Adding the openjdk PPA repository."
		sudo add-apt-repository ppa:openjdk-r/ppa -y
	fi
	__package_name="openjdk-${__version}-jdk"
	__is_package_installed=$( dpkg -l | grep ${__package_name} | wc -l )
	if [[ ${__is_package_installed} == 0 ]]; then
		echo "Installing the package : ${__package_name}"
		if [[ ${__version} == 9 ]]; then
			echo "Adding java-9 force-overwrite flag hack for installation."
			__flag="-o Dpkg::Options::="--force-overwrite""
		fi
		sudo apt-get update
		sudo apt-get ${__flag} install ${__package_name} -y
	else
		echo "Checking if there is any update for package : ${__package_name}"
		sudo apt-get install --only-upgrade ${__package_name} -y
	fi
}

function updateAlternative(){
	if [[ $# != 2 ]]; then
		echo "Please pass alternative config parameter and the entry search term in the alternative menu"
		return
	fi
	__alternative_search_term=$1
	__search_term=$2
	__input_number=$( update-alternatives --list ${__alternative_search_term} | grep -n ${__search_term} | cut -d":" -f1 )
	echo ${__input_number} | sudo update-alternatives --config ${__alternative_search_term} > /dev/null
}

function setEnvVariables(){
	if [[ $# != 1 ]]; then
		helpAndUsage
		return 2
	fi
	__search_term="java-$1"
	echo "Setting correct version of java and javac in path"
	updateAlternative 'java' ${__search_term} && updateAlternative 'javac' ${__search_term}
	export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which javac))))
	echo "Setting JAVA_HOME to ${JAVA_HOME}"
	echo "JAVA_HOME=${JAVA_HOME}" > ${__current_working_dir}/.jdkconfig
}

function main(){
	installJdk ${__expected_jdk_version} && setEnvVariables ${__expected_jdk_version}
}


if [[ $# != 1 ]]; then
	helpAndUsage
	return 1
fi
__expected_jdk_version=$1

case "${__expected_jdk_version}" in
	[7-9])
		echo "Requested JDK version ${__expected_jdk_version}"
        ;;
    *)
        helpAndUsage
        return 2
        ;;
esac
__current_working_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

main ${__expected_jdk_version}