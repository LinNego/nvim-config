#!/usr/bin/env bash
# 一键安装这套 Neovim 配置（Linux x86_64）
#   ./install.sh                         普通安装
#   PROXY=http://host:7897 ./install.sh  走代理下载
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
BIN_DIR="$HOME/.local/bin"

info() { printf '\033[32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33m[!]\033[0m %s\n' "$*"; }
die()  { printf '\033[31m[x]\033[0m %s\n' "$*"; exit 1; }
need() { command -v "$1" >/dev/null 2>&1; }

if [[ -n "${PROXY:-}" ]]; then
  export https_proxy="$PROXY" http_proxy="$PROXY" all_proxy="$PROXY"
  info "使用代理 $PROXY"
fi

mkdir -p "$BIN_DIR" "$HOME/.local/opt"

# ---------- 1. Neovim 0.11+ ----------
nvim_ok() {
  need nvim && nvim --version 2>/dev/null | head -1 | grep -qE 'v0\.(1[1-9]|[2-9][0-9])'
}

if nvim_ok; then
  info "Neovim 已满足：$(nvim --version | head -1)"
else
  info "下载 Neovim 预编译包"
  tmp="$(mktemp -d)"
  if curl -fsSL -o "$tmp/nvim.tar.gz" \
      "https://github.com/neovim/neovim/releases/download/stable/nvim-linux-x86_64.tar.gz"; then
    tar xzf "$tmp/nvim.tar.gz" -C "$tmp"
    if "$tmp"/nvim-linux-x86_64/bin/nvim --version >/dev/null 2>&1; then
      rm -rf "$HOME/.local/opt/nvim"
      mv "$tmp"/nvim-linux-x86_64 "$HOME/.local/opt/nvim"
      ln -sf "$HOME/.local/opt/nvim/bin/nvim" "$BIN_DIR/nvim"
      info "Neovim 装到 ~/.local/opt/nvim"
    else
      warn "预编译包在本机跑不起来（glibc 太老），需要源码编译："
      warn "  见 README 的「glibc 太老怎么办」一节，编好后重跑本脚本"
      exit 1
    fi
  else
    die "下载失败，检查网络或设置 PROXY"
  fi
  rm -rf "$tmp"
fi

# ---------- 2. 配置文件 ----------
if [[ -e "$CFG_DIR" && ! -L "$CFG_DIR" ]]; then
  bak="$CFG_DIR.bak-$(date +%Y%m%d-%H%M%S)"
  mv "$CFG_DIR" "$bak"
  info "原有配置已备份到 $bak"
fi
ln -sfn "$REPO_DIR" "$CFG_DIR"
info "配置已链接：$CFG_DIR -> $REPO_DIR"

# ---------- 3. 命令行工具 ----------
install_tarball_bin() { # $1=名称 $2=url $3=解压后二进制相对路径
  local name="$1" url="$2" member="$3" tmp
  tmp="$(mktemp -d)"
  if curl -fsSL -o "$tmp/pkg.tar.gz" "$url"; then
    tar xzf "$tmp/pkg.tar.gz" -C "$tmp"
    if [[ -f "$tmp/$member" ]]; then
      install -m755 "$tmp/$member" "$BIN_DIR/$name"
      info "$name -> $BIN_DIR/$name"
    fi
  else
    warn "$name 下载失败（可稍后手动装）"
  fi
  rm -rf "$tmp"
}

need rg || install_tarball_bin rg \
  "https://github.com/BurntSushi/ripgrep/releases/download/14.1.1/ripgrep-14.1.1-x86_64-unknown-linux-musl.tar.gz" \
  "ripgrep-14.1.1-x86_64-unknown-linux-musl/rg"

need ruff || install_tarball_bin ruff \
  "https://github.com/astral-sh/ruff/releases/latest/download/ruff-x86_64-unknown-linux-musl.tar.gz" \
  "ruff-x86_64-unknown-linux-musl/ruff"

if ! need gofumpt && need go; then
  go install mvdan.cc/gofumpt@latest >/dev/null 2>&1 && info "gofumpt 已安装" || warn "gofumpt 安装失败"
fi

if ! need pyright && need npm; then
  npm install -g pyright >/dev/null 2>&1 && info "pyright 已安装" || warn "pyright 安装失败"
fi

# ---------- 4. 收尾 ----------
case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) warn "把 $BIN_DIR 加进 PATH：echo 'export PATH=$HOME/.local/bin:$PATH' >> ~/.bashrc" ;;
esac

info "完成。直接运行 nvim，第一次会自动装插件（需要联网）"
info "忘了按键就按 <leader>?（空格 + ?）"
