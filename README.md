# profile.sh
My working profile.sh

#
jdkswithcer.sh
---------------
Requirements :-
1. apt-get as package manager
2. bash shell
Instllation :-
Add the following to your ~/.profile or ~/.bashrc as per your system so that the login shell knows about the function on a new shell or login
```
function jdk(){
	local __current_working_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
	local __file="${__current_working_dir}/jdkswitcher.sh"
	if [[ -f ${__file} ]]; then
		source ${__file} $@
	else
		echo "jdk comand is not found. Please check your bhasrc / profile"
	fi
}
```
Replace the variable `__current_working_dir` with the localtion where you have downloaded and stored https://github.com/saptarshidebnath/profile.sh/blob/master/jdkswitcher.sh .

After making the edits, restart the shell, or reload your .bashrc / .profile and type in `jdk` to print the detailed help
