# Usage

```
gcloud compute ssh --tunnel-through-iap ansible-controller
git clone https://github.com/isnt/kubeadm-ansible.git
cd kubeadm-ansible/
git checkout tmp
chmod 600 gcp-test-environment/ansible_key
ansible-playbook -i inventory/gcp/hosts.ini install.yml
```
