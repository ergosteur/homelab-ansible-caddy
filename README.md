# homelab-ansible-caddy

Ansible playbooks and setup tools for deploying Caddy as a reverse proxy in a homelab environment.

Clone this repo to an Ubuntu server or workstation.
run the ./setup-caddy-ansible.sh to install ansible and xcaddy

make sure PATH is updated, run source ~/.bashrc

check if xcaddy is found in path
$ xcaddy
go: cannot match "all": go.mod file not found in current directory or any parent directory; see 'go help modules'
Error: exec 0x5b55a0: exit status 1: 
exec 0x5b55a0: exit status 1: 

this error is normal

run make build to build the caddy.custom binary.