#!/bin/bash

# consul env
binary_path="/usr/local/sbin"
config_path="/etc/consul"
data_path="/data/consul/data"
log_path="/data/consul/log"
systemctl_path="/etc/systemd/system/consul.service"
exec_user="consul"

function _check_consul_local() {
    echo "正在检查是否已安装 consul ..."
    if command -v consul &>/dev/null; then
        echo "consul 已安装。退出。"
        exit 1
    fi
}

function _create_consul_user() {
    echo "正在创建 ${exec_user} 用户 ..."
    useradd -s /sbin/nologin ${exec_user}
}

function _download_latest_consul() {
    echo "获取最新release 版本信息 ..."
    latest_release=$(curl -s https://api.github.com/repos/hashicorp/consul/releases/latest | grep "tag_name" | cut -d : -f 2 | tr -d "\" , ")
    file_name=$(echo $download_url | awk -F '/' '{print $NF}')
    file_name_without_suffix=$(echo $file_name | sed 's/\.tar.gz//')
    curl --connect-timeout ${CURL_TIMEOUT} --max-time ${CURL_TIMEOUT} -L -o ${file_name} ${github_proxy_prefix}${download_url}
    if [ $? -ne 0 ]; then
        echo "下载文件失败。"
        exit 1
    fi
}

function _install_consul() {
    echo "开始解压，并安装 ..."
    tar zxf ${file_name}
    file_path=$(echo ${file_name_without_suffix} | awk -F '/' '{print $NF}')
    cd ${file_path}

    echo "复制二进制文件到 ${binary_path} ..."
    $(which cp) -a consul ${binary_path}
    chown -R ${exec_user}.${exec_user}${binary_path}/consul

    echo "创建相关目录 ${config_path} ${data_path} ${log_path} ..."
    mkdir -p ${config_path} ${data_path} ${log_path}
    chown -R ${exec_user}.${exec_user} ${config_path} ${data_path} ${log_path}

}

function _create_consul_systemctl_config() {
    echo "生成systemctl 配置文件 ..."
    cat <<EOF >${systemctl_path}
[Unit]
Description=Consul
Documentation=https://consul.io/
Wants=network-online.target
After=network-online.target

[Service]
LimitNOFILE=65536
User=${exec_user}
Group=${exec_user}
Type=simple
ExecStart=${binary_path}/consul agent -config-dir=${config_path} 
KillSignal=SIGINT
TimeoutStopSec=10s
RestartSec=5
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
}

function _create_consul_server_config_json_file() {
    echo "生成配置文件 ..."
    cat <<EOF >${config_path}/config.json
{
    "data_dir": "${data_path}",
    "log_file": "${log_path}/consul.log",
    "log_level": "INFO",
    "log_rotate_duration": "24h",
    "server": true,
    "bootstrap_expect": 3,
    "bind_addr": "0.0.0.0",
    "client_addr": "0.0.0.0",
    "advertise_addr": "内网ip",
    "datacenter": "qz",
    "start_join": ["内网ip1","内网ip2","内网ip3"],
    "ui": true,
    "limits":
    {
        "http_max_conns_per_client": 1000,
        "rpc_max_conns_per_client": 1000
    },
    "telemetry":
    {
    "prometheus_retention_time": "60s",
    }
}
EOF
}

function _start_consul() {
    echo "正在启动 consul 服务 ..."
    systemctl daemon-reload
    systemctl enable consul --now
    systemctl --no-pager status consul
    echo "consul 安装完成。"
}

function _clean_tmp_file_path() {
    echo "正在清理临时目录 ${file_path} ..."
    cd ${exec_path}
    rm -rf ${file_path}
}

function install_consul_server() {
    _check_consul_local
    _create_consul_user
    _download_latest_consul
    _install_consul
    _create_consul_systemctl_config
    _create_consul_server_config_json_file
    _start_consul
    _clean_tmp_file_path
}
