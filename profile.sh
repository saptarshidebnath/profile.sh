#!/sur/bin/env bash

#
# Aliases
#
alias t="subl"
alias i="nohup idea > /dev/null 2>&1 &"
alias dk="docker-compose"
alias br="source ~/.bashrc"

#
# local variable
#
__current_working_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# function openjdk(){
# 	__expected_version=$@
# 	if [[ -f "${__current_working_dir}/newjdk.sh" ]]; then
# 		source ${__current_working_dir}/newjdk.sh 'openjdk' ${__expected_version}
# 	fi
# }

# function oraclejdk(){
# 	__expected_version=$@
# 	if [[ -f "${__current_working_dir}/newjdk.sh" ]]; then
# 		source ${__current_working_dir}/newjdk.sh 'oracle' ${__expected_version}
# 	fi
# }


function jdk(){
	local __current_working_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
	local __file="${__current_working_dir}/jdkswitcher.sh"
	if [[ -f ${__file} ]]; then
		source ${__file} $@
	else
		echo "jdk comand is not found. Please check your bhasrc / profile"
	fi
}
