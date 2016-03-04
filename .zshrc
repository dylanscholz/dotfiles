export PATH=/usr/local/aws/bin/:$PATH
# Set up the prompt

autoload -Uz promptinit
promptinit
prompt adam1

setopt histignorealldups sharehistory

# Use emacs keybindings even if our EDITOR is set to vi
bindkey -e

# Keep 9000 lines of history within the shell and save it to ~/.zsh_history:
HISTSIZE=9000
SAVEHIST=9000
HISTFILE=~/.zsh_history


# Use modern completion system
autoload -Uz compinit
compinit

#So AWS commands autocomplete http://docs.aws.amazon.com/cli/latest/userguide/cli-command-completion.html
source /usr/local/aws/bin/aws_zsh_completer.sh 

#aliases
alias ta='attach_tmux_session $1'
alias ll='ls -l'
alias grep='grep --color=auto'
alias pign='ping'
alias l='ls -CF'
alias amazon_instances='get_instances_by_nametag $1'
alias ai='get_instances_by_nametag $1'
alias ami='get_ami_by_name $1'


#functions
#lazily re-attach tmux sessions, by default go to 0, but allow to go to different sessions
attach_tmux_session () {
    if [ $1 ]  
        then
            tmux attach-session -t $1
    else
        tmux attach-session -t 0
    fi
}

#making it easy to use the west bastion host as a jump host. 
#NOTE, ssh-add -l should contain the proper pems for bastion (eq-devops-west.pem) and the pem for what you're sshing to.
#add via: ssh-add eq-devops-west.pem lynx-staging-west.pem
ssh_through_bastion() {
    if [ $1 ]
        then
            ssh -Atvvv ubuntu@#nope ssh $1
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
    nc -zv $1 22

}

#setting up ruby environment
export RBENV_ROOT=/usr/local/var/rbenv
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi
