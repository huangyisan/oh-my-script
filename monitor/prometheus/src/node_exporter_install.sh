#!/bin/bash
source ./common/pre_check.sh

# node_exporter env
binary_path="/usr/local/sbin"
config_path="/etc/node_exporter"
systemctl_path="/etc/systemd/system/node-exporter.service"
exec_user="prometheus"

function _check_node_exporter_local() {
    echo "正在检查是否已安装 node_exporter ..."
    if command -v node_exporter &> /dev/null; then
        echo "node_exporter 已安装。退出。"
        exit 1
    fi
}

function _create_node_exporter_user() {
    echo "正在创建 ${exec_user} 用户 ..."
    useradd -s /sbin/nologin ${exec_user}
}

function _download_latest_node_exporter() {
    echo "获取最新release 版本信息 ..."
    latest_release=$(curl -s https://api.github.com/repos/prometheus/node_exporter/releases/latest | grep "tag_name" | cut -d : -f 2 | tr -d "\" , ")

    # 检查是否获取到最新版本信息
    if [ -z "$latest_release" ]; then
        echo "无法获取最新版本信息。"
        exit 1
    fi

    echo "正在下载最新版本 $latest_release ..."
    download_url=$(curl -s https://api.github.com/repos/prometheus/node_exporter/releases/latest | grep "browser_download_url" | grep "linux-amd64" | grep -P -o "https.+" | sed 's/.$//')
    file_name=$(echo $download_url | awk -F '/' '{print $NF}')
    file_name_without_suffix=$(echo $file_name | sed 's/\.tar.gz//')
    curl --connect-timeout 30 --max-time 30 -L -o ${file_name} ${download_url}
    if [ $? -ne 0 ]; then
        echo "下载文件失败。"
        exit 1
    fi
}

function _install_node_exporter() {
    echo "开始解压，并安装 ..."
    tar zxf ${file_name}
    cd ${file_name_without_suffix}
    
    echo "复制二进制文件到 ${binary_path} ..."
    /usr/bin/cp -a node_exporter ${binary_path}
    chown -R ${exec_user}.${exec_user} ${binary_path}/node_exporter
}

function _create_systemctl_config() {
    echo "生成systemctl 配置文件 ..."
    cat <<EOF > ${systemctl_path}
[Unit]
Description=Node Exporter
Documentation=https://github.com/prometheus/node_exporter
Wants=network-online.target
After=network-online.target

[Service]
LimitNOFILE=65536
User=${exec_user}
Group=${exec_user}
Type=simple
ExecStart=${binary_path}/node_exporter \
    --collector.mountstats \
    --collector.sysctl \
    --collector.systemd \
    --collector.tcpstat

ExecReload=/bin/kill -HUP
TimeoutStopSec=10s
Restart=always

[Install]
WantedBy=multi-user.target
EOF
}

function _start_node_exporter() {
    echo "正在启动 node_exporter 服务 ..."
    systemctl daemon-reload
    systemctl enable node-exporter --now
    systemctl --no-pager status node-exporter
    echo "node-exporter 安装完成。"
}

function install_node_exporter() {
    _check_node_exporter_local
    _create_node_exporter_user
    _download_latest_node_exporter
    _install_node_exporter
    _create_systemctl_config
    _start_node_exporter   
}

# 指定本地文件
function _specify_local_file() {
    # 控制台输入文件名
    read -p "请输入文件名(tar.gz包)：" file_name
    if [ -z "$file_name" ]; then
        echo "文件名不能为空。"
        return 1
    fi
    #检查当前目录是否存在文件
    if [ ! -f "$file_name" ]; then
        echo "文件不存在。"
        return 1
    fi
    file_name_without_suffix=$(echo $file_name | sed 's/\.tar.gz//')
}

function install_node_exporter_local() {
    _check_node_exporter_local
    _create_node_exporter_user
    if ! _specify_local_file; then  # 检查返回值
        return  # 如果失败，返回到主菜单
    fi
    _install_node_exporter
    _create_systemctl_config
    _start_node_exporter
}