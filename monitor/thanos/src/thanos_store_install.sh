#!/bin/bash

# thanos store env
binary_path="/usr/local/sbin"
store_path="/data/thanos/store"
systemctl_path="/etc/systemd/system/thanos-store.service"
objstore_config_path="/etc/thanos"
exec_user="prometheus"
thanos_component_name="thanos-store"

function _check_thanos_store_local() {
    echo "正在检查是否已安装 ${thanos_component_name} ..."
    if command -v ${thanos_component_name} &>/dev/null; then
        echo "${thanos_component_name} 已安装。退出。"
        exit 1
    fi
}

function _create_thanos_user() {
    echo "正在创建 ${exec_user} 用户 ..."
    useradd -s /sbin/nologin ${exec_user}
}

function _download_latest_thanos_store() {
    echo "获取最新release 版本信息 ..."
    latest_release=$(curl -s https://api.github.com/repos/thanos-io/thanos/releases/latest | grep "tag_name" | cut -d : -f 2 | tr -d "\" , ")

    # 检查是否获取到最新版本信息
    if [ -z "$latest_release" ]; then
        echo "无法获取最新版本信息。"
        exit 1
    fi

    echo "正在下载最新版本 $latest_release ..."
    download_url=$(curl -s https://api.github.com/repos/thanos-io/thanos/releases/latest | grep "browser_download_url" | grep "linux-amd64" | grep -P -o "https.+" | sed 's/.$//')
    file_name=$(echo $download_url | awk -F '/' '{print $NF}')
    file_name_without_suffix=$(echo $file_name | sed 's/\.tar.gz//')
    curl --connect-timeout ${CURL_TIMEOUT} --max-time ${CURL_TIMEOUT} -L -o ${file_name} ${github_proxy_prefix}${download_url}
    if [ $? -ne 0 ]; then
        echo "下载文件失败。"
        exit 1
    fi

}

function _install_thanos_store() {
    echo "开始解压，并安装 ..."

    mkdir -p ${store_path}
    chown -R ${exec_user}.${exec_user} ${store_path}
    mkdir -p ${objstore_config_path}
    chown -R ${exec_user}.${exec_user} ${objstore_config_path}

    tar zxf ${file_name}
    file_path=$(echo ${file_name_without_suffix} | awk -F '/' '{print $NF}')
    cd ${file_path}

    echo "复制二进制文件到 ${binary_path} ..."
    $(which cp) -a thanos ${binary_path}/${thanos_component_name}
    chown -R ${exec_user}.${exec_user} ${binary_path}/${thanos_component_name}
}

function _create_thanos_store_systemctl_config() {
    echo "生成systemctl 配置文件 ..."
    cat <<EOF >${systemctl_path}
[Unit]
Description=Thanos Store
Documentation=https://thanos.io/
Wants=network-online.target
After=network-online.target

[Service]
LimitNOFILE=65536
User=${exec_user}
Group=${exec_user}
Type=simple
ExecStart=${binary_path}/${thanos_component_name} store \
    --data-dir=${store_path} \
    --objstore.config-file=${objstore_config_path}/thanos-alioss.yml \
    --http-address=127.0.0.1:10905 \
    --grpc-address=127.0.0.1:10906 \
    --block-sync-concurrency=200 \
    --store.grpc.series-max-concurrency=200 \
    --chunk-pool-size=2GB \
    --max-time=30d

ExecReload=/bin/kill -HUP $MAINPID
TimeoutStopSec=10s
Restart=always
[Install]
WantedBy=multi-user.target
EOF
}

function _start_thanos_query() {
    echo "正在启动 Thanos store 服务 ..."
    systemctl daemon-reload
    systemctl enable ${thanos_component_name} --now
    systemctl --no-pager status ${thanos_component_name}
    echo "${thanos_component_name} 安装完成。"
}

function _clean_tmp_file_path() {
    echo "正在清理临时目录 ${file_path} ..."
    cd ${exec_path}
    rm -rf ${file_path}
}

function install_thanos_store() {
    _check_thanos_store_local
    _create_thanos_user
    _download_latest_thanos_store
    _install_thanos_store
    _create_thanos_store_systemctl_config
    _start_thanos_query
    _clean_tmp_file_path
}
