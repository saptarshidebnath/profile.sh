#!/usr/bin/env bash

function cs(){
	if [[ "${CLEAN_SYSTEM}" -eq "${TRUE}" ]]; then
		echo "Cleaning up oracle and openjdk PPAs"
		sudo add-apt-repository --remove ${VENDOR_ORACLE_PPA} -y &> /dev/null
		sudo add-apt-repository --remove ${VENDOR_OPENJDK_PPA} -y &> /dev/null
		echo "Finding and deleting java installation"
		{
			dpkg-query -W -f='${binary:Package}\n' | grep -E -e '^(ia32-)?(sun|oracle)-java' -e '^openjdk-' -e '^icedtea' -e '^(default|gcj)-j(re|dk)' -e '^gcj-(.*)-j(re|dk)' -e '^java-common' | xargs sudo apt-get -y remove
	    	sudo apt-get -y autoremove
	    	dpkg -l | grep ^rc | awk '{print($2)}' | xargs sudo apt-get -y purge
	    	sudo bash -c 'ls -d /home/*/.java' | xargs sudo rm -rf
	    	sudo rm -rf /usr/lib/jvm/*
	    	for g in ControlPanel java java_vm javaws jcontrol jexec keytool mozilla-javaplugin.so orbd pack200 policytool rmid rmiregistry servertool tnameserv unpack200 appletviewer apt extcheck HtmlConverter idlj jar jarsigner javac javadoc javah javap jconsole jdb jhat jinfo jmap jps jrunscript jsadebugd jstack jstat jstatd native2ascii rmic schemagen serialver wsgen wsimport xjc xulrunner-1.9-javaplugin.so; do sudo update-alternatives --remove-all $g; done
	    	sudo updatedb
		} &> /dev/null
	    echo "---"
	    echo "Please delete the files if required"
	    echo "---"
	    sudo locate -b '\pack200'
	    echo ""
    fi
}

function helpAndUsage(){
	if [[ $# -gt 0 ]]; then
		echo "$@"
		echo ""
	fi
	echo "This small utility installs and updates oracle jdk and openjdk. For the versions supported please see below."
	echo "It uses apt-get as package manager and switches JAVA_HOME environment variable accordingly."
	echo ""
	echo "Usage : jdk {-cs|--clean-system} {-${VENDOR_OPENJDK_SHORT}|-${VENDOR_OPENJDK} | -${VENDOR_ORACLE_SHORT}|-${VENDOR_ORACLE}} [7|8|9]"
	echo "           -cs|--clean-system : Clean the system of all trace of jdk and jre installation."
	echo "                                It is a optional parameter."
	echo "           -${VENDOR_OPENJDK_SHORT}|-${VENDOR_OPENJDK} 		: select openjdk as the JDK vendor."
	echo "                                Either openjdk or oacle as vendor is a required parameter."
	echo "           -${VENDOR_ORACLE_SHORT}|-${VENDOR_ORACLE} 		: select openjdk as the JDK vendor."
	echo "                                Either openjdk or oacle as vendor is a required parameter."
	echo "			  [7|8|9]			: Select the JDK version. it accepts in format of 7 and not 1.7."
	echo "                                The supported version are listed below"
	echo "OpenJdk version supported are : $( printf '%s ' "${VENDOR_OPENJDK_JDK_VERSION[@]}" )"
	echo "Orcale jdk version supported are : $( printf '%s ' "${VENDOR_ORACLE_JDK_VERSION[@]}" )"
	set +x
}

function searchForElementInArray(){
	local elementtosearchfor=$1
	shift;
	echo $( printf '%s\n' "$@" | grep "^${elementtosearchfor}$" | wc -l )
}

function setEnv(){
	local __java_home=$(dirname $(dirname $(readlink -f $(which javac))))
	#
	# SH file
	#
	echo "Creating SH profile.d entry"
	local __temp_file_sh=$( mktemp )
	sudo echo "export J2SDKDIR=${__java_home} " > ${__temp_file_sh} && \
	sudo echo "export J2REDIR=${__java_home} " >> ${__temp_file_sh} && \
	#sudo echo "export PATH=$PATH:${__java_home}/bin:${__java_home}/db/bin " >> ${__temp_file_sh} && \
	sudo echo "export JAVA_HOME=${__java_home} " >> ${__temp_file_sh} && \
	sudo echo "export DERBY_HOME=${__java_home}/db " >> ${__temp_file_sh}
	sudo mv ${__temp_file_sh} ${PROFILE_JDK_SH}
	echo "Setting environment variable for current shell excluding cshell."
	source ${PROFILE_JDK_SH} && cat ${PROFILE_JDK_SH} || { echo "Unable to source ${PROFILE_JDK_SH}" && return 8 ; }
	local __alternative_entry=$( update-java-alternatives -l | grep ${VENDOR} | grep ${EXPECTED_JDK_VERSION} | cut -d" " -f1 )
	local __update_alternative_log=$( mktemp )
	if [[ $( echo ${__alternative_entry} | wc -m ) -gt 0 ]]; then
		printf "Setting current java version using update-java-alternatives . . . " && \
		{ sudo update-java-alternatives -s ${__alternative_entry} &> ${__update_alternative_log} \
			|| { echo "Logs are at : ${__update_alternative_log}" && cat ${__update_alternative_log} && return 7 ; } ; } \
		&& echo "done" \
		&& rm ${__update_alternative_log}
	fi
}

#cs
function validateParams(){
	[[ $( echo ${VENDOR} | wc -m ) -gt 0 ]] || { helpAndUsage "Vendor name is required." && return 2 ; }
	[[ $( echo ${EXPECTED_JDK_VERSION} | wc -m ) -gt 0 ]] || { helpAndUsage "JDK version is required." && return 3 ; }
	case ${VENDOR} in
		${VENDOR_OPENJDK} )
	 		echo "Requested JDK vendor as : ${VENDOR}"
			if [[ $( searchForElementInArray ${EXPECTED_JDK_VERSION} ${VENDOR_OPENJDK_JDK_VERSION[@]} ) == 0 ]]; then
				helpAndUsage "Version ${EXPECTED_JDK_VERSION} not suppported"
				return 3
			fi
			;;
		${VENDOR_ORACLE} )
			echo "Requested JDK vendor as : ${VENDOR}" 
			if [[ $( searchForElementInArray ${EXPECTED_JDK_VERSION} ${VENDOR_ORACLE_JDK_VERSION[@]} ) == 0 ]]; then
				helpAndUsage "Version ${EXPECTED_JDK_VERSION} not suppported"
				return 3
			fi
			;;
		*)
			echo "Requested JDK vendor \"${VENDOR}\" not supported."
			helpAndUsage
			return 2
			;;
	esac
	echo "Expected JDK version is : ${EXPECTED_JDK_VERSION}"
}

#
# If the user reach this point the the the parameters VENDOR and EXPECTED_JDK_VERSION are both validated.
#
function addPPA(){
	if [[ $# -lt 2 ]]; then
		echo "Please pass the search param and the ppa add command"
		return 104
	fi
	local __searchTerm=$1
	shift
	local __ppa_add_command=$*
	if [[ $( find /etc/apt/ -name *.list | xargs cat | grep  ^[[:space:]]*deb | grep ${__searchTerm} | wc -l ) == 0 ]]; then
		echo "Importing PPA for vendor : ${VENDOR}"
	 	sudo add-apt-repository ${__ppa_add_command} -y &> /dev/null
	else
		echo "PPA is already installed for vendor : ${VENDOR}"
	fi 
}

function installOrUpdate(){
	#
	# Notify if packages are going to be updated or installed.
	#	
	local __is_installing="true"
	#
	# Looks in the status field to check if package is already installed or not 
	#
	__is_package_installed="$( dpkg -s ${__PACKAGE_TO_INSTALL} 2>&1 | grep Status | cut -d":" -f2 | grep -w "install" | wc -l )"
	{ [[ ${__is_package_installed} -gt 0 ]] ; } && \
	{ 
		echo "Package(s) ${__PACKAGE_TO_INSTALL} are already installed. Checking if any update is available or not."
	 __is_installing="false"
	} || \
	echo "New Package(s) going to be installed are : ${__PACKAGE_TO_INSTALL}."

	#
	# Update package indexes and then try to run the update / installation
	#
	local __apt_get_update_output=$( mktemp )
	local __apt_get_install_output=$( mktemp )
	{ \
		{ printf "Fetching package indexes [ Loged at : ${__apt_get_update_output} ]. . . " && sudo apt-get update &> ${__apt_get_update_output} ; } \
		&& { echo "done and cleaned up logs." && rm ${__apt_get_update_output} ; } \
		|| { echo "Unable to fetch package indexes." \
				&& cat ${__apt_get_update_output} && return 5 ;  } \
	; } && \
	{ \
		{ \
			{ [[ ${__is_installing} == 'true' ]] && printf "Installing" || printf "Updating" ; } && \
		 	printf " packages [ Loged at : ${__apt_get_install_output} ] . . . " && \
		 	sudo apt-get ${__INSTALLATION_FLAG} install ${__PACKAGE_TO_INSTALL} -y &> ${__apt_get_install_output} \
		 	&& echo "done and cleaned up logs." \
		 	&& rm ${__apt_get_install_output} \
	 	; }|| \
		{ \
			printf "Unable to " && \
			{ [[ ${__is_installing} == 'true' ]] && printf "install" || printf "update" ; } && \
			echo " ${__installing_update_copy} packages : ${__PACKAGE_TO_INSTALL}" \
			&& cat ${__apt_get_install_output} && return 6 \
		; } \
	; }
}

#
# Add PPA to the sources if required.
#
function genereatePackagesInstallationName(){
	__INSTALLATION_FLAG=""
	case ${VENDOR} in
		${VENDOR_ORACLE} )
			#
			# Add PPA if required
			#
			addPPA ${VENDOR_ORACLE_PPA_SEARCH_KEYWORD} ${VENDOR_ORACLE_PPA}
			local __exit_code=$?
			if [[ ${__exit_code} != 0 ]]; then
				return ${__exit_code}
			fi
			#
			# build the packagename
			#
			__PACKAGE_TO_INSTALL="oracle-java${EXPECTED_JDK_VERSION}-installer"
			__INSTALLATION_FLAG="-o Dpkg::Options::=--force-confnew ${__INSTALLATION_FLAG}"
			echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | sudo debconf-set-selections
			if [[ ${EXPECTED_JDK_VERSION} == 9 ]]; then
				echo "Please note that openjdk 9 if installed will be uninstalled. "
				#echo "Please confirm by typing y/Y. To cancel please type n/N : "
				# while true; do
			 #        read -p "$* [y/n]: " yn
			 #        case $yn in
			 #            [Yy]*) break ;;  
			 #            [Nn]*) echo "Aborted" ; return 0;;
			 #        esac
		  #   	done
	  		fi
			;;
		${VENDOR_OPENJDK} )
			#
			# Add PPA if required
			#
			addPPA ${VENDOR_OPENJDK_PPA_SEARCH_KEYWORD} ${VENDOR_OPENJDK_PPA}
			local __exit_code=$?
			if [[ ${__exit_code} != 0 ]]; then
				return ${__exit_code}
			fi
			__PACKAGE_TO_INSTALL="openjdk-${EXPECTED_JDK_VERSION}-jdk"
			if [[ ${EXPECTED_JDK_VERSION} == 9 ]]; then
				echo "Setting openjdk java 9 force overwrite flag"
				__INSTALLATION_FLAG="-o Dpkg::Options::="--force-overwrite""
				echo "Please note that oraclejdk 9 if installed will be uninstalled. "
			fi
			;;
	esac
}

###################
#  Configuration  #
###################
VENDOR_ORACLE_JDK_VERSION=( 8 9 )
VENDOR_OPENJDK_JDK_VERSION=( 7 8 9 )
VENDOR_ORACLE="oracle"
VENDOR_ORACLE_SHORT="c"
VENDOR_ORACLE_PPA_SEARCH_KEYWORD='webupd8team/java'
VENDOR_ORACLE_PPA="ppa:${VENDOR_ORACLE_PPA_SEARCH_KEYWORD}"
VENDOR_OPENJDK="openjdk"
VENDOR_OPENJDK_SHORT="n"
VENDOR_OPENJDK_PPA_SEARCH_KEYWORD='openjdk-r'
VENDOR_OPENJDK_PPA="ppa:${VENDOR_OPENJDK_PPA_SEARCH_KEYWORD}"
PROFILE_JDK_SH='/etc/profile.d/jdk.sh'
PROFILE_JDK_CSH='/etc/profile.d/jdk.csh'
TRUE='1'
FALSE='0'

####################################
#######Main Execution steps#########
####################################
if [[ $# -lt 2 ]]; then
	helpAndUsage
	return 1
fi
while [ $# -gt 0 ]
do
	local __current_word=$1
	case ${__current_word} in
		"-n"|"--${VENDOR_OPENJDK}" )
			VENDOR=${VENDOR_OPENJDK}
			;;
		"-c"|"--${VENDOR_ORACLE}" )
			VENDOR=${VENDOR_ORACLE}
			;;
		[1-9]* )
			EXPECTED_JDK_VERSION=${__current_word}
			;;
		"-cs"|"--clean-system" )
			CLEAN_SYSTEM=${TRUE}
			;;
		* )
			helpAndUsage
			return 1
			;;
	esac
	shift
done

validateParams || return $?
cs || return $?
genereatePackagesInstallationName || return $?
installOrUpdate || return $?
setEnv || return $?


#
# UNSET variables
#
unset VENDOR_ORACLE_JDK_VERSION
unset VENDOR_OPENJDK_JDK_VERSION
unset VENDOR_ORACLE
unset VENDOR_ORACLE_SHORT
unset VENDOR_ORACLE_PPA_SEARCH_KEYWORD
unset VENDOR_ORACLE_PPA
unset VENDOR_OPENJDK
unset VENDOR_OPENJDK_SHORT
unset VENDOR_OPENJDK_PPA_SEARCH_KEYWORD
unset VENDOR_OPENJDK_PPA
unset PROFILE_JDK_SH
unset PROFILE_JDK_CSH
unset TRUE
unset FALSE
unset VENDOR
unset EXPECTED_JDK_VERSION
unset CLEAN_SYSTEM


#
# Unset functions
#
unset -f cs
unset -f helpAndUsage
unset -f searchForElementInArray
unset -f setEnv
unset -f validateParams
unset -f addPPA
unset -f installOrUpdate
unset -f genereatePackagesInstallationName