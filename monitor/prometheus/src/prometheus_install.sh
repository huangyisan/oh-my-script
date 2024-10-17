#!/bin/bash

# prometheus env
binary_path="/usr/local/sbin"
config_path="/etc/prometheus"
lib_path="/var/lib/prometheus"
systemctl_path="/etc/systemd/system/prometheus.service"
exec_user="prometheus"
tsdb_path="/data/prometheus"

function _check_prometheus_local() {
    echo "正在检查是否已安装 Prometheus ..."
    if command -v prometheus &>/dev/null; then
        echo "Prometheus 已安装。退出。"
        exit 1
    fi
}

function _create_prometheus_user() {
    echo "正在创建 ${exec_user} 用户 ..."
    useradd -s /sbin/nologin ${exec_user}
}

function _download_latest_prometheus() {
    echo "获取最新release 版本信息 ..."
    latest_release=$(curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest | grep "tag_name" | cut -d : -f 2 | tr -d "\" , ")

    # 检查是否获取到最新版本信息
    if [ -z "$latest_release" ]; then
        echo "无法获取最新版本信息。"
        exit 1
    fi

    echo "正在下载最新版本 $latest_release ..."
    download_url=$(curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest | grep "browser_download_url" | grep "linux-amd64" | grep -P -o "https.+" | sed 's/.$//')
    file_name=$(echo $download_url | awk -F '/' '{print $NF}')
    file_name_without_suffix=$(echo $file_name | sed 's/\.tar.gz//')
    curl --connect-timeout ${CURL_TIMEOUT} --max-time ${CURL_TIMEOUT} -L -o ${file_name} ${github_proxy_prefix}${download_url}
    if [ $? -ne 0 ]; then
        echo "下载文件失败。"
        exit 1
    fi
}

function _install_prometheus() {
    echo "开始解压，并安装 ..."

    tar zxf ${file_name}
    file_path=$(echo ${file_name_without_suffix} | awk -F '/' '{print $NF}')
    cd ${file_path}

    echo "复制二进制文件到 ${binary_path} ..."
    $(which cp) -a promtool prometheus ${binary_path}
    chown -R ${exec_user}.${exec_user} ${binary_path}/prometheus
    chown -R ${exec_user}.${exec_user} ${binary_path}/promtool

    echo "复制静态资源到 ${lib_path} ..."
    mkdir -p ${lib_path}
    $(which cp) -a console_libraries consoles ${lib_path}
    chown -R ${exec_user}.${exec_user} ${lib_path}

    echo "复制配置文件到${config_path} ..."
    mkdir -p ${config_path}
    $(which cp) -a prometheus.yml ${config_path}/prometheus.yml
    chown -R ${exec_user}.${exec_user} ${config_path}/prometheus.yml

    echo "创建数据目录 ${tsdb_path} ..."
    mkdir -p ${tsdb_path}
    chown -R ${exec_user}.${exec_user} ${tsdb_path}
}

function _create_systemctl_config() {
    echo "生成systemctl 配置文件 ..."
    cat <<EOF >${systemctl_path}
[Unit]
Description=Prometheus
Documentation=https://prometheus.io/
Wants=network-online.target
After=network-online.target

[Service]
LimitNOFILE=65536
User=${exec_user}
Group=${exec_user}
Type=simple
ExecStartPre=${binary_path}/promtool check config ${config_path}/prometheus.yml
ExecStart=${binary_path}/prometheus \
    --config.file=${config_path}/prometheus.yml \
    --web.listen-address=127.0.0.1:9090 \
    --web.enable-lifecycle \
    --web.enable-admin-api \
    --web.console.libraries=${lib_path}/console_libraries \
    --web.console.templates=${lib_path}/consoles \
    --log.level=info \
    --storage.tsdb.path=${tsdb_path} \
    --storage.tsdb.retention.time=30d \
    --storage.tsdb.retention.size=30MB \
    --storage.tsdb.min-block-duration=2h \
    --storage.tsdb.max-block-duration=2h \
    --query.timeout=1m

ExecReload=/bin/curl -X POST http://localhost:9090/-/reload
TimeoutStopSec=10s
Restart=always
[Install]
WantedBy=multi-user.target
EOF
}

function _start_prometheus() {
    echo "正在启动 Prometheus 服务 ..."
    systemctl daemon-reload
    systemctl enable prometheus --now
    systemctl --no-pager status prometheus
    echo "Prometheus 安装完成。"
}

function install_prometheus() {
    _check_prometheus_local
    _create_prometheus_user
    _download_latest_prometheus
    _install_prometheus
    _create_systemctl_config
    _start_prometheus
}

# 指定本地文件
function _specify_local_file() {
    # 控制台输入文件名
    read -p "请输入文件绝对路径名称(tar.gz包)：" file_name
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

function _clean_tmp_file_path() {
    echo "正在清理临时目录 ${file_path} ..."
    cd ${exec_path}
    rm -rf ${file_path}
}

function install_prometheus_local() {
    _check_prometheus_local
    _create_prometheus_user
    if ! _specify_local_file; then # 检查返回值
        return                     # 如果失败，返回到主菜单
    fi
    _install_prometheus
    _create_systemctl_config
    _start_prometheus
    _clean_tmp_file_path
}
