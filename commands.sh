sudo -s

# Stop everything
sudo systemctl stop kubelet
crictl ps -q | xargs crictl stop
sudo systemctl stop crio
while pgrep etcd; do
    kill $(pgrep etcd)
    sleep 1
done

# Unlock (can we just tar into somewhere else instead?)
ostree admin unlock

# Prepare backup folder
mkdir /usr/bkup/

# Tar var
# TODO: Exclude CNI binaries /var/lib/cni
PROM_POD_ID=$(find '/var/lib/kubelet/pods' | grep -E 'containers/prometheus$' | grep -E --only-matching '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}')
tar -czf \
    /usr/bkup/ocpvar.tar.gz \
    --exclude='/var/tmp/' \
    --exclude='/var/lib/kubelet/pods/'$PROM_POD_ID'/volumes/kubernetes.io~empty-dir' \
    --exclude='/var/lib/log' \
    --exclude='/var/lib/containers' \
    /var/
    

# Tar etcd
ostree admin config-diff | awk '{print "/etc/" $2}' | xargs tar -czf /usr/bkup/etcd.tar.gz

# Commit
ostree commit --branch haha /usr/bkup

# Into image
mkdir /root/.docker
vi /root/.docker/config.json
ostree container encapsulate haha registry:quay.io/otuchfel/ostmagic:latest --repo /ostree/repo

# laptop stuff
podman pull quay.io/otuchfel/ostmagic:latest
podman save quay.io/otuchfel/ostmagic:latest -o ha.tar
