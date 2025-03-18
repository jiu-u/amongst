#!/bin/bash

# frpc.sh
# Description: frpc.sh
# Author:   <q8a6um@outlook.com>
# Version:  1.0

frpc_version="0.61.2"

# 检查架构
check_arch() {
  arch=$(uname -m)
  case $arch in
  x86_64)
    arch="amd64"
    ;;
  aarch64 | arm64)
    arch="arm64"
    ;;
  armv7l)
    arch="arm"
    ;;
  *)
    echo "不支持的架构: $arch"
    exit 1
    ;;
  esac
  echo "检测到架构: $arch"
  return 0
}

# 下载frp
download_frp() {
  check_arch
  os="linux"
  # download_url="https://gh-proxy.com/github.com/fatedier/frp/releases/download/v${frpc_version}/frp_${frpc_version}_${os}_${arch}.tar.gz"

  download_url="https://ghfast.top/https://github.com/fatedier/frp/releases/download/v${frpc_version}/frp_${frpc_version}_${os}_${arch}.tar.gz"

  echo "正在下载 frp $frpc_version..."
  # echo "下载url $download_url"

  wget $download_url -O frp.tar.gz || {
    echo "下载失败!"
    exit 1
  }

  echo "正在解压文件..."
  tar -zxf frp.tar.gz

  mkdir -p /opt/frp
  mv frp_${frpc_version}_${os}_${arch}/* /opt/frp/

  chmod +x /opt/frp/frpc

  # 清理临时文件
  rm -rf frp_${frpc_version}_${os}_${arch}
  rm frp.tar.gz

  echo "frpc 已安装到 /opt/frp"
}

# 配置service
setup_service() {
  echo "正在配置 frpc 服务..."

  # 创建systemd服务文件
  cat >/etc/systemd/system/frpc.service <<EOF
[Unit]
Description = frp server
After = network.target syslog.target
Wants = network.target

[Service]
Type=simple
# User=nobody
Restart=on-failure
RestartSec=5s
ExecStart=/opt/frp/frpc -c /opt/frp/frpc.toml
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

  # 重新加载systemd配置
  systemctl daemon-reload

  echo "服务已配置:"
  echo "请先修改/opt/frp/frpc.toml文件，然后重启服务"
  echo "您可以使用以下命令管理服务:"
  echo "systemctl start frpc    # 启动服务"
  echo "systemctl stop frpc     # 停止服务"
  echo "systemctl enable frpc   # 设置开机启动"
  echo "systemctl status frpc   # 查看服务状态"
}

# 主函数
main() {
  # 检查是否为root用户
  if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要root权限运行"
    exit 1
  fi

  download_frp
  setup_service

  echo "frpc $frpc_version 安装完成!"
}

main "$@"
