#!/bin/bash

# alertmanager env
binary_path="/usr/local/sbin"
config_path="/etc/alertmanager"
systemctl_path="/etc/systemd/system/alertmanager.service"
data_path="/data/alertmanager"
exec_user="prometheus"
prometheus_component_name="alertmanager"

function _check_alertmanager_local() {
    echo "正在检查是否已安装 alertmanager ..."
    if command -v alertmanager &>/dev/null; then
        echo "alertmanager 已安装。退出。"
        exit 1
    fi
}

function _create_alertmanager_user() {
    echo "正在创建 ${exec_user} 用户 ..."
    useradd -s /sbin/nologin ${exec_user}
}

function _download_latest_alertmanager() {
    echo "获取最新release 版本信息 ..."
    latest_release=$(curl -s https://api.github.com/repos/prometheus/alertmanager/releases/latest | grep "tag_name" | cut -d : -f 2 | tr -d "\" , ")

    # 检查是否获取到最新版本信息
    if [ -z "$latest_release" ]; then
        echo "无法获取最新版本信息。"
        exit 1
    fi

    echo "正在下载最新版本 $latest_release ..."
    download_url=$(curl -s https://api.github.com/repos/prometheus/alertmanager/releases/latest | grep "browser_download_url" | grep "linux-amd64" | grep -P -o "https.+" | sed 's/.$//')
    file_name=$(echo $download_url | awk -F '/' '{print $NF}')
    file_name_without_suffix=$(echo $file_name | sed 's/\.tar.gz//')
    curl --connect-timeout ${CURL_TIMEOUT} --max-time ${CURL_TIMEOUT} -L -o ${file_name} ${github_proxy_prefix}${download_url}
    if [ $? -ne 0 ]; then
        echo "下载文件失败。"
        exit 1
    fi
}

function _install_alertmanager() {
    echo "开始解压，并安装 ..."

    mkdir -p ${data_path}
    chown -R ${exec_user}.${exec_user} ${data_path}
    mkdir -p ${config_path}
    chown -R ${exec_user}.${exec_user} ${config_path}

    tar zxf ${file_name}
    file_path=$(echo ${file_name_without_suffix} | awk -F '/' '{print $NF}')
    cd ${file_path}

    echo "复制二进制文件到 ${binary_path} ..."
    $(which cp) -a ${prometheus_component_name} ${binary_path}/${prometheus_component_name}
    $(which cp) -a alertmanager.yml ${config_path}/alertmanager.yml
    chown -R ${exec_user}.${exec_user} ${binary_path}/${prometheus_component_name}
    chown -R ${exec_user}.${exec_user} ${config_path}/alertmanager.yml
}

function _create_alertmanager_systemctl_config() {
    echo "生成systemctl 配置文件 ..."
    cat <<EOF >${systemctl_path}
[Unit]
Description=Alertmanager
Documentation=https://prometheus.io/docs/alerting/alertmanager/
Wants=network-online.target
After=network-online.target

[Service]
LimitNOFILE=65536
User=${exec_user}
Group=${exec_user}
Type=simple
ExecStart=${binary_path}/${prometheus_component_name} \
    --config.file=${config_path}/alertmanager.yml \
    --storage.path=${data_path} \
    --web.listen-address=10.11.12.136:9093 \
    --cluster.listen-address=10.11.12.136:9094


ExecReload=/bin/kill -HUP \$MAINPID
TimeoutStopSec=10s
Restart=always

[Install]
WantedBy=multi-user.target
EOF
}

function _start_alertmanager() {
    echo "正在启动 ${prometheus_component_name} 服务 ..."
    systemctl daemon-reload
    systemctl enable ${prometheus_component_name} --now
    systemctl --no-pager status ${prometheus_component_name}
    echo "${prometheus_component_name} 安装完成。"
}

function _clean_tmp_file_path() {
    echo "正在清理临时目录 ${file_path} ..."
    cd ${exec_path}
    rm -rf ${file_path}
}

function install_alertmanager() {
    _check_alertmanager_local
    _create_alertmanager_user
    _download_latest_alertmanager
    _install_alertmanager
    _create_alertmanager_systemctl_config
    _start_alertmanager
    _clean_tmp_file_path
}
