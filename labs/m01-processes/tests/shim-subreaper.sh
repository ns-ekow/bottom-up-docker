# Builds containerd's shim with the patch in $LAB_IMPL/no-subreaper.patch, runs one container
# through it, and checks the effect of a shim that is not a subreaper: the container's process is
# adopted by the host's PID 1 instead of the shim, and after it is killed containerd still reports
# it RUNNING, because the shim never collected its exit status. Exit 0 = pass.
export PATH=/usr/local/go/bin:$PATH GOTOOLCHAIN=local GOFLAGS=-mod=vendor
IMPL=${LAB_IMPL:-starter}
NS=bud-m01; ID=no-subreaper-$$; IMAGE=docker.io/library/busybox:1.37
W=$(mktemp -d); SHIM="$W/containerd-shim-runc-v2"
cleanup() {
  # A shim that never learns the exit makes normal cleanup hang, so force it.
  pkill -KILL -f "^$SHIM " 2>/dev/null || true; sleep 0.5
  timeout 15 ctr -n $NS task delete -f $ID >/dev/null 2>&1 || true
  timeout 15 ctr -n $NS containers delete $ID >/dev/null 2>&1 || true
  rm -rf "$W"
}
trap cleanup EXIT

# Copying the source out of the shared /course folder is slow, so keep one pristine copy on the
# VM's own disk (per pinned commit) and copy from that.
COMMIT=$(git -C ../../src/containerd rev-parse HEAD 2>/dev/null || awk '$1 == "containerd/containerd" {print $3}' ../../pins.lock)
CACHE=/var/lib/bud/cache/containerd-$COMMIT
[ -d "$CACHE" ] || { mkdir -p "$CACHE.tmp" && cp -r ../../src/containerd/. "$CACHE.tmp" && mv "$CACHE.tmp" "$CACHE"; }
cp -r "$CACHE" "$W/containerd"
if [ -s "$IMPL/no-subreaper.patch" ]; then
  patch -s -d "$W/containerd" -p1 < "$IMPL/no-subreaper.patch" || { echo "FAIL  patch does not apply"; exit 1; }
fi
# -p 2 limits parallel compile jobs, which keeps the build's peak memory inside the VM down.
(cd "$W/containerd" && go build -p 2 -o "$SHIM" ./cmd/containerd-shim-runc-v2) || { echo "FAIL  shim build"; exit 1; }

ctr -n $NS images ls -q | grep -qx $IMAGE || ctr -n $NS images pull $IMAGE >/dev/null
ctr -n $NS run -d --runtime "$SHIM" $IMAGE $ID sleep 30 >/dev/null
sleep 1
pid=$(ctr -n $NS task ls | awk -v id=$ID '$1 == id {print $2}')
parent=$(ps -o comm= -p "$(ps -o ppid= -p "$pid" | tr -d ' ')")
ctr -n $NS task kill -s KILL $ID; sleep 1
status=$(ctr -n $NS task ls | awk -v id=$ID '$1 == id {print $3}')

fails=0
if [ "$parent" != containerd-shim ]; then echo "ok    container process adopted by $parent, not the shim"
else echo "FAIL  container process's parent is still the shim (patch not effective)"; fails=1; fi
if [ "$status" = RUNNING ]; then echo "ok    after SIGKILL containerd still reports RUNNING (exit status lost)"
else echo "FAIL  after SIGKILL the status is $status: the shim still collected the exit"; fails=1; fi
[ $fails -eq 0 ]
