#export PATH=/usr/local/aws/bin/:$PATH
# Set up the prompt

autoload -Uz promptinit
promptinit
prompt adam1

setopt histignorealldups sharehistory

# Use emacs keybindings even if our EDITOR is set to vi
bindkey -e

# Keep 1000 lines of history within the shell and save it to ~/.zsh_history:
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history


# Use modern completion system
autoload -Uz compinit
compinit

#So AWS commands autocomplete
enable_aws_autocomplete(){
    export PATH=/usr/local/aws/bin/:$PATH
    source /usr/local/aws/bin/aws_zsh_completer.sh 
    #complete -C aws_autocompleter aws
}
#autoload -U bashcompinit
#complete -C aws_autocompleter aws
#export COMP_POINT
#export COMP_LINE


#zstyle ':completion:*' auto-description 'specify: %d'
#zstyle ':completion:*' completer _expand _complete _correct _approximate
#zstyle ':completion:*' format 'Completing %d'
#zstyle ':completion:*' group-name ''
#zstyle ':completion:*' menu select=2
#zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
#zstyle ':completion:*' list-colors ''
#zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
#zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
#zstyle ':completion:*' menu select=long
#zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
#zstyle ':completion:*' use-compctl false
#zstyle ':completion:*' verbose true
#
#zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
#zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

#aliases
alias ta='attach_tmux_session $1'
alias ll='ls -l'
alias grep='grep --color=auto'
alias pign='ping'
alias l='ls -CF'
alias sshw='ssh_through_west_bastion $1'
alias sshe='ssh_through_east_bastion $1'
alias amazon_instances='get_instances_by_nametag $1'
alias ai='get_instances_by_nametag $1'
alias ami='get_ami_by_name $1'
alias giia='get_instance_in_asg $1'
alias rds='get_rds_by_db_id $1'

#functions
#lazily re-attach tmux sessions, by default go to 0, but allow to go to different sessions
attach_tmux_session () {
    if [ $1 ]; then
            tmux attach-session -t $1
    else
        tmux attach-session -t 0
    fi
}

#making it easy to use the west bastion host as a jump host. 
#NOTE, ssh-add -l should contain the proper pems for bastion (eq-devops-west.pem) and the pem for what you're sshing to.
#add via: ssh-add eq-devops-west.pem lynx-staging-west.pem
ssh_through_west_bastion() {
    if [ $1 ]
        then
            ssh -At ubuntu@nope ssh $1
    else
        printf "You didn't specify a host to connect to"
    fi
}


ssh_through_east_bastion() {
    if [ $1 ]
        then
            ssh -At ubuntu@nope ssh $1
    else
        printf "You didn't specify a host to connect to"
    fi
}

get_instances_by_nametag() { 
    if [ $1 ] 
        then
            search_string="*${1}*"
            aws ec2 describe-instances --output=table --query  'Reservations[*].Instances[*].{aName:Tags[?Key==`Name`] | [0].Value,bIP:PrivateIpAddress,cPublicIP:PublicIpAddress,dSSHKey:KeyName,eLaunchTime:LaunchTime,fASGName:Tags[?Key==`aws:autoscaling:groupName`] | [0].Value,gImageId:ImageId,hInstanceId:InstanceId}' --filters Name=tag:Name,Values=${search_string}
    else
        printf "You need to specify an instance name"
    fi
}

get_ami_by_name() {
    if [ $1 ]
        then
          search_string="*${1}*"
          aws ec2 describe-images --owners self --output=table --query 'Images[*].{aNameTag:Tags[?Key==`Name`] | [0].Value,bName:Name,cType:VirtualizationType,dID:ImageId,eCreationDate:CreationDate}' --filters Name=name,Values=${search_string}
    else
        printf "You need to specify an AMI name"
    fi
}    
test_ssh() {
    #watch 'nc -zv $1 22'
    while true; do nc -zv $1 22; sleep 5; done
}
connect-when-ready() {
  until nc -z -G 3 $1 22; do;
    echo "Can't ssh to $1 yet. Sleeping."
    sleep 5
  done
  ssh $1
}
test_elb_healthcheck() { 
  HEALTHCHECK_URL=$(python ~/working/evqt_mgmt_tool/standalone_scripts/ssl/elb_certs.py | grep ${1} | awk '{print $3$2}')
  echo "curling https://${HEALTHCHECK_URL}... for elb ${1}"
  curl -I --insecure https://${HEALTHCHECK_URL}
}

get_instance_in_asg(){
  for instance in $(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names ${1} --query 'AutoScalingGroups[*].Instances[*].InstanceId' --output text); 
    do
      aws ec2 describe-instances --instance-ids $instance --query "Reservations[*].Instances[*].PrivateIpAddress" --output text;
  done
}


get_rds_by_db_id() {
    if [ $1 ]
        then
            search_string="${1}"
            aws rds  describe-db-instances  \
            --query  'DBInstances[*].{Name:DBInstanceIdentifier,Endpoint:Endpoint.Address,Engine:Engine,Username:MasterUsername}' \
            | jq '.[] | select(.Name | contains ("'${search_string}'"))'

    else
        printf "You need to specify a name"
    fi
}

ssh() {
    if [ "$(ps -p $(ps -p $$ -o ppid=) -o comm=)" = "tmux" ]; then
        tmux rename-window "$(echo $*)"
        command ssh "$@"
        tmux set-window-option automatic-rename "on" 1>/dev/null
    else
        command ssh "$@"
    fi
}

#rbenv stuff
export RBENV_ROOT=/usr/local/var/rbenv
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi


# awsless autocompletion
source /usr/local/share/zsh/site-functions/_awless


eval "$(nodenv init -)"
