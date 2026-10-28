#!/usr/bin/env bash
# 在 glibc 较老（< 2.34）的机器上从源码编译 Neovim
#   ./scripts/build-nvim.sh                装到 ~/.local/opt/nvim
#   PREFIX=/opt/nvim ./scripts/build-nvim.sh
#   PROXY=http://host:7897 ./scripts/build-nvim.sh
set -euo pipefail

NVIM_VERSION="${NVIM_VERSION:-v0.11.4}"
PREFIX="${PREFIX:-$HOME/.local/opt/nvim}"
WORK="${WORK:-/tmp/nvim-build}"
BIN_DIR="$HOME/.local/bin"

info() { printf '\033[32m==>\033[0m %s\n' "$*"; }
die()  { printf '\033[31m[x]\033[0m %s\n' "$*"; exit 1; }

if [[ -n "${PROXY:-}" ]]; then
  export https_proxy="$PROXY" http_proxy="$PROXY"
  info "使用代理 $PROXY"
fi

command -v gcc  >/dev/null || die "需要 gcc / make"
command -v make >/dev/null || die "需要 make"
command -v git  >/dev/null || die "需要 git"

mkdir -p "$WORK" "$BIN_DIR" && cd "$WORK"

# 1) cmake + ninja：不用系统包，直接下二进制，避免动系统
if ! command -v cmake >/dev/null; then
  info "下载 cmake"
  curl -fsSL -o cmake.tar.gz \
    "https://github.com/Kitware/CMake/releases/download/v3.31.6/cmake-3.31.6-linux-x86_64.tar.gz"
  tar xzf cmake.tar.gz
  export PATH="$WORK/cmake-3.31.6-linux-x86_64/bin:$PATH"
fi
if ! command -v ninja >/dev/null; then
  info "下载 ninja"
  curl -fsSL -o ninja.zip "https://github.com/ninja-build/ninja/releases/download/v1.12.1/ninja-linux.zip"
  unzip -oq ninja.zip
  export PATH="$WORK:$PATH"
fi

# 2) 源码
info "下载 Neovim 源码 $NVIM_VERSION"
[[ -f nvim.tar.gz ]] || curl -fsSL -o nvim.tar.gz \
  "https://github.com/neovim/neovim/archive/refs/tags/${NVIM_VERSION}.tar.gz"
[[ -d "neovim-${NVIM_VERSION#v}" ]] || tar xzf nvim.tar.gz
cd "neovim-${NVIM_VERSION#v}"

# 3) 编译（会顺带编译内置依赖，约 5–15 分钟）
info "开始编译（-j$(nproc)）"
make CMAKE_BUILD_TYPE=Release CMAKE_INSTALL_PREFIX="$PREFIX" -j"$(nproc)"

info "安装到 $PREFIX"
make install

ln -sf "$PREFIX/bin/nvim" "$BIN_DIR/nvim"
info "完成：$("$PREFIX/bin/nvim" --version | head -1)"
info "如果 $BIN_DIR 不在 PATH 里，加到 ~/.bashrc： export PATH=\$HOME/.local/bin:\$PATH"
