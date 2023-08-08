sudo -s

# Stop everything
sudo systemctl stop kubelet
crictl ps -q | xargs crictl stop
sudo systemctl stop crio

# Unlock (can we just tar into somewhere else instead?)
ostree admin unlock

# Prepare backup folder
mkdir /usr/bkup/

# Tar var
# TODO: Exclude CNI binaries /var/lib/cni
tar -czf \
    /usr/bkup/ocpvar.tar.gz \
    --exclude='/var/tmp/' \
    --exclude='/var/lib/log' \
    --exclude='/var/lib/containers' \
    /var/
    

# Tar etcd
# TODO: Different treatment for M and A files?
ostree admin config-diff | awk '{print "/etc/" $2}' | xargs tar -czf /usr/bkup/etcd.tar.gz

# Commit
ostree commit --branch haha /usr/bkup

# Into image
mkdir /root/.docker
vi /root/.docker/config.json
ostree container encapsulate haha registry:quay.io/otuchfel/ostmagic:latest --repo /ostree/repo --label ostree.bootable=true

# laptop stuff
podman pull quay.io/otuchfel/ostmagic:latest
podman save quay.io/otuchfel/ostmagic:latest -o ha.tar

# vm stuff
mount /sysroot -o remount,rw
ostree container unencapsulate registry:quay.io/otuchfel/ostmagic:latest
ostree refs --create=haha <commit_hash>
ostree cat haha /etc.tar.gz | tar -C / -xz
ostree cat haha /ocpvar.tar.gz | tar -C / -xz
