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
function jdk(){
	if [[ $# != 1 ]]; then
		echo "Please pass the Opnejdk version you want to install like 7"
		echo Usage "jdk 9"
		return
	fi
	__expected_version=$1
	if [[ -f "${__current_working_dir}/jdk.sh" ]]; then
		source ${__current_working_dir}/jdk.sh ${__expected_version}
	fi
}