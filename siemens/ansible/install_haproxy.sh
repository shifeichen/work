wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
yum install ansible -y
cp -a haproxy /etc/ansible/roles/
cp hosts /etc/ansible/
ansible-playbook /etc/ansible/haproxy.yml