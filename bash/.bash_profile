#!/bin/bash

###-SSH-AGENT-BEGIN-------------------------------------------------------------

SSH_ENV=$HOME/.ssh/environment

# start the ssh-agent
function start_agent {
    echo "Initializing new SSH agent..."
    # spawn ssh-agent
    /usr/bin/ssh-agent | sed 's/^echo/#echo/' > "${SSH_ENV}"
    echo succeeded
    chmod 600 "${SSH_ENV}"
    . "${SSH_ENV}" > /dev/null
    /usr/bin/ssh-add
}

if [ -f "${SSH_ENV}" ]; then
    . "${SSH_ENV}" > /dev/null
	ps -ef | grep ${SSH_AGENT_PID} | grep ssh-agent$ > /dev/null || {
	    start_agent;
	}
else
    start_agent;
fi

###-SSH-AGENT-END---------------------------------------------------------------

###-HISTORY-BEGIN---------------------------------------------------------------

export HISTSIZE=5000
export HISTFILESIZE=10000
export HISTCONTROL=ignoredups

stty -ixon

shopt -s histappend

export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"

cd $HOME/Development/Projects

###-HISTORY-END-----------------------------------------------------------------

###-SDKMAN-BEGIN----------------------------------------------------------------

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="/c/Users/grzegorz.witkowski/.sdkman"
[[ -s "/c/Users/grzegorz.witkowski/.sdkman/bin/sdkman-init.sh" ]] && source "/c/Users/grzegorz.witkowski/.sdkman/bin/sdkman-init.sh"

###-SDK-MAN-END-----------------------------------------------------------------
