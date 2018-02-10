################################################################################
#### zsh config                                                             ####
################################################################################

# prompt. just use predefined themes shipped with zsh
# https://github.com/johan/zsh/tree/master/Functions/Prompts
autoload -Uz promptinit
promptinit
prompt adam1
# Use modern completion system
autoload -Uz compinit
compinit


# Use emacs keybindings because gnu readline is great, maybe not necessary? 
# https://en.wikipedia.org/wiki/GNU_Readline#Emacs_keyboard_shortcuts
# bindkey -e

# set history to an unreasonable size. RIP memory
# store in ~/.zsh_history
HISTSIZE=1000000
SAVEHIST=1000000
HISTFILE=~/.zsh_history

################################################################################
#### Environment configuration                                              ####
################################################################################
# exports / setting paths goes here


################################################################################
#### Aliases                                                                ####
################################################################################
alias ta='attach_tmux_session $1'
alias ll='ls -l'
alias grep='grep --color=auto'
alias pign='ping'
alias l='ls -CF'
alias ssh_bastion='ssh -At $1 $2'

# AWS CLI specific aliases
alias ai='get_instances_by_nametag $1'
alias ami='get_ami_by_name $1'
alias giia='get_instance_in_asg $1'
alias rds='get_rds_by_db_id $1'

################################################################################
#### Sysadmin functions                                                     ####
################################################################################

# SSH when the socket opens
connect-when-ready() {
  until nc -z -G 3 $1 22; do;
    echo "Can't ssh to $1 yet. Sleeping."
    sleep 5
  done
  ssh $1
}

### TMUX specific functions
# lazily re-attach tmux sessions
attach_tmux_session () {
    # if user input, try to connect to that session
    if [ $1 ]; then
        tmux attach-session -t ${1}
    fi

    # get session numbers
    TMUX_SESSIONS=$( tmux ls | awk '{ print substr($0,0,1) }' )

    # if more than 1 session exists, prompt
    if [[ $( echo ${TMUX_SESSIONS} | wc -l) -gt 1 ]] ; then
        echo "What tmux session?"
        echo ${TMUX_SESSIONS}
        read session_number
        tmux attach-session -t ${session_number}

    # else just connect to the only session
    else
        tmux attach-session -t ${TMUX_SESSIONS}
    fi
}

# name tmux windows after IP of host we SSH to
ssh() {
    if [ "$(ps -p $(ps -p $$ -o ppid=) -o comm=)" = "tmux" ]; then
        tmux rename-window "$(echo $*)"
        command ssh "$@"
        tmux set-window-option automatic-rename "on" 1>/dev/null
    else
        command ssh "$@"
    fi
}

################################################################################
#### AWS functions                                                          ####
################################################################################

# so AWS commands autocomplete
enable_aws_autocomplete(){
    export PATH=/usr/local/aws/bin/:$PATH
    source /usr/local/aws/bin/aws_zsh_completer.sh 
}

# gets instances that match input
get_instances_by_nametag() { 
    if [ $1 ] 
        then
            search_string="*${1}*"
            # this is an abomination. 
            # NOTE: tables only return things in alphabetical order...
            # hence the abcdefgh
            aws ec2 describe-instances \
                --output=table \
                --query 'Reservations[*].Instances[*].{
                    aName:Tags[?Key==`Name`] | [0].Value, 
                    bIP:PrivateIpAddress,
                    cPublicIP:PublicIpAddress,
                    dSSHKey:KeyName,
                    eLaunchTime:LaunchTime,
                    fASGName:Tags[?Key==`aws:autoscaling:groupName`] | [0].Value,
                    gInstanceType:InstanceType,
                    hImageId:ImageId,
                    iInstanceId:InstanceId}' \
                --filters Name=tag:Name,Values=${search_string}
    else
        echo "You need to specify an instance name"
    fi
}

# gets AMIs that match input
get_ami_by_name() {
    if [ $1 ]
        then
          search_string="*${1}*"
          aws ec2 describe-images \
            --owners self \
            --output=table \
            --query 'Images[*].{
                aNameTag:Tags[?Key==`Name`] | [0].Value,
                bName:Name,
                cType:VirtualizationType,
                dID:ImageId,
                eCreationDate:CreationDate}' \
            --filters Name=name,Values=${search_string}
    else
        echo "You need to specify an AMI name"
    fi
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

# returns IPs of all instances in an ASG
get_instance_in_asg(){
  for instance in $(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names ${1} --query 'AutoScalingGroups[*].Instances[*].InstanceId' --output text); 
    do
      aws ec2 describe-instances --instance-ids $instance --query "Reservations[*].Instances[*].PrivateIpAddress" --output text;
  done
}