#!/usr/bin/env bash
# Provision the bottom-up-docker lab VM. Runs as root INSIDE the VM (invoked by ../vm/reset).
# Idempotent: safe to re-run. Every download is checked against vm/versions.env.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=versions.env
source "$HERE/versions.env"

[ "$(id -u)" -eq 0 ] || { echo "run as root" >&2; exit 1; }
LAB_USER="${SUDO_USER:-$(logname 2>/dev/null || echo "")}"
DL=/var/cache/bud-downloads
mkdir -p "$DL"

fetch() { # url sha256 dest
  local url=$1 sum=$2 dest=$3
  if [ ! -f "$dest" ] || ! echo "$sum  $dest" | sha256sum -c --quiet - 2>/dev/null; then
    curl -fsSL --retry 3 -o "$dest.part" "$url"
    echo "$sum  $dest.part" | sha256sum -c --quiet - || { echo "CHECKSUM MISMATCH: $url" >&2; rm -f "$dest.part"; exit 1; }
    mv "$dest.part" "$dest"
  fi
}

echo "==> apt packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update -q
apt-get install -y -q --no-install-recommends \
  build-essential pkg-config git curl ca-certificates jq make python3 \
  strace ltrace gdb bpftrace \
  iproute2 iptables nftables conntrack tcpdump socat bridge-utils iputils-ping dnsutils \
  util-linux uidmap libcap2-bin libseccomp-dev busybox-static \
  man-db manpages manpages-dev \
  e2fsprogs xfsprogs attr tree

echo "==> Go $GO_VERSION"
fetch "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" "$GO_SHA256" "$DL/go.tgz"
if [ "$(/usr/local/go/bin/go env GOVERSION 2>/dev/null)" != "go$GO_VERSION" ]; then
  rm -rf /usr/local/go && tar -C /usr/local -xzf "$DL/go.tgz"
fi
cat > /etc/profile.d/go.sh <<'EOF'
export PATH=/usr/local/go/bin:$HOME/go/bin:$PATH
EOF

echo "==> Docker $DOCKER_VERSION (dockerd, docker, docker-proxy, docker-init)"
fetch "https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz" "$DOCKER_SHA256" "$DL/docker.tgz"
tmp=$(mktemp -d); tar -C "$tmp" -xzf "$DL/docker.tgz"
install -m 0755 "$tmp/docker/dockerd" "$tmp/docker/docker" "$tmp/docker/docker-proxy" "$tmp/docker/docker-init" /usr/local/bin/
rm -rf "$tmp"

echo "==> containerd $CONTAINERD_VERSION"
fetch "https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz" "$CONTAINERD_SHA256" "$DL/containerd.tgz"
tar -C /usr/local -xzf "$DL/containerd.tgz"   # bin/containerd, bin/containerd-shim-runc-v2, bin/ctr

echo "==> runc $RUNC_VERSION"
fetch "https://github.com/opencontainers/runc/releases/download/v${RUNC_VERSION}/runc.amd64" "$RUNC_SHA256" "$DL/runc"
install -m 0755 "$DL/runc" /usr/local/bin/runc

echo "==> BuildKit $BUILDKIT_VERSION (buildkitd, buildctl: standalone, for week 11)"
fetch "https://github.com/moby/buildkit/releases/download/v${BUILDKIT_VERSION}/buildkit-v${BUILDKIT_VERSION}.linux-amd64.tar.gz" "$BUILDKIT_SHA256" "$DL/buildkit.tgz"
tar -C /usr/local -xzf "$DL/buildkit.tgz"     # bin/buildkitd, bin/buildctl, ...

echo "==> buildx $BUILDX_VERSION"
fetch "https://github.com/docker/buildx/releases/download/v${BUILDX_VERSION}/buildx-v${BUILDX_VERSION}.linux-amd64" "$BUILDX_SHA256" "$DL/buildx"
install -D -m 0755 "$DL/buildx" /usr/local/lib/docker/cli-plugins/docker-buildx

echo "==> delve $DELVE_VERSION"
GOBIN=/usr/local/bin GOTOOLCHAIN=local /usr/local/go/bin/go install "github.com/go-delve/delve/cmd/dlv@v${DELVE_VERSION}"

echo "==> systemd units"
cat > /etc/systemd/system/containerd.service <<'EOF'
[Unit]
Description=containerd container runtime (bottom-up-docker pin)
After=network.target local-fs.target
[Service]
ExecStartPre=-/sbin/modprobe overlay
ExecStart=/usr/local/bin/containerd
Type=notify
Delegate=yes
KillMode=process
Restart=always
RestartSec=5
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
OOMScoreAdjust=-999
[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/docker.socket <<'EOF'
[Unit]
Description=Docker Socket for the API
[Socket]
ListenStream=/run/docker.sock
SocketMode=0660
SocketUser=root
SocketGroup=docker
[Install]
WantedBy=sockets.target
EOF

cat > /etc/systemd/system/docker.service <<'EOF'
[Unit]
Description=Docker Application Container Engine (bottom-up-docker pin)
After=network-online.target containerd.service docker.socket
Wants=network-online.target containerd.service
Requires=docker.socket
[Service]
Type=notify
ExecStart=/usr/local/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock
ExecReload=/bin/kill -s HUP $MAINPID
TimeoutStartSec=0
RestartSec=2
Restart=always
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
Delegate=yes
KillMode=process
OOMScoreAdjust=-500
[Install]
WantedBy=multi-user.target
EOF

getent group docker >/dev/null || groupadd docker
if [ -n "$LAB_USER" ] && id "$LAB_USER" >/dev/null 2>&1; then usermod -aG docker "$LAB_USER"; fi

mkdir -p /var/lib/bud   # VM-local scratch for destructive experiments

systemctl daemon-reload
systemctl enable --now containerd.service docker.socket docker.service

echo "==> done; run /course/vm/verify inside the VM to check versions"
