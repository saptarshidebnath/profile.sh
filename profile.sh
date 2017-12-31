#!/sur/bin/env bash

#
# Aliases
#
alias t="subl"
alias i="nohup idea > /dev/null 2>&1 &"
alias dk="docker-compose"

#
# local variable
#
__current_working_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ -f ${__current_working_dir}/.jdkconfig ]]; then
	source ${__current_working_dir}/.jdkconfig
fi
function openjdk(){
	__expected_version=$@
	if [[ -f "${__current_working_dir}/newjdk.sh" ]]; then
		source ${__current_working_dir}/newjdk.sh 'openjdk' ${__expected_version}
	fi
}

function oraclejdk(){
	__expected_version=$@
	if [[ -f "${__current_working_dir}/newjdk.sh" ]]; then
		source ${__current_working_dir}/newjdk.sh 'oracle' ${__expected_version}
	fi
}



function cleanJdk(){
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