sudo -s

# Stop everything
sudo systemctl stop kubelet
crictl ps -q | xargs crictl stop
sudo systemctl stop crio

# Prepare backup folder
mkdir /var/tmp/backup

# Tar var
# TODO: Exclude CNI binaries /var/lib/cni
tar -czf \
    /var/tmp/backup/ocpvar.tar.gz \
    --exclude='/var/tmp/*' \
    --exclude='/var/lib/log/*' \
    --exclude='/var/lib/containers/*' \
    /var/
    

# Tar etcd
# TODO: Different treatment for M and A files?
ostree admin config-diff | awk '{print "/etc/" $2}' | xargs tar -czf /var/tmp/backup/etc.tar.gz

# Commit
ostree commit --branch haha /var/tmp/backup

# Into image
mkdir /root/.docker
vi /root/.docker/config.json
ostree container encapsulate haha registry:quay.io/otuchfel/ostmagic:latest --repo /ostree/repo --label ostree.bootable=true

# laptop stuff
podman pull quay.io/otuchfel/ostmagic:latest
podman save quay.io/otuchfel/ostmagic:latest -o ha.tar

# vm stuff
mount /sysroot -o remount,rw
ostree container unencapsulate registry:quay.io/otuchfel/ostmagic:latest | tee /tmp/unencapsulate.backup
ostree refs --create=haha $(cut -d ' ' -f 2 < /tmp/unencapsulate.backup)
ostree cat haha /etc.tar.gz | tar -C / -xz
ostree cat haha /ocpvar.tar.gz | tar -C / -xz
