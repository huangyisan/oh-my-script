#!/bin.bash
source ./common/pre_check.sh
source ./prometheus/src/prometheus_install.sh
source ./prometheus/src/node_exporter_install.sh

source ./thanos/src/thanos_sidecar_install.sh

# github proxy
function switch_github_proxy() {
    # 判断github_proxy_prefix是否为空
    if [ -z "$github_proxy_prefix" ]; then
        github_proxy_prefix="https://ghp.ci/"
        echo "已设置github代理为：$github_proxy_prefix"
    else
        unset github_proxy_prefix
        echo "已取消github代理。"
    fi   
}

exec_path=$(pwd)
# 主菜单
function main_menu() {
    while true; do
        clear
        
        echo "退出脚本，请按ctrl c退出即可"
        echo "请选择要执行的操作:"
        echo "0. github代理开关"
        echo "1. 安装prometheus最新release"
        echo "2. 从本地安装prometheus"
        echo "3. 安装node_exporter最新release"
        echo "4. 从本地安装node_exporter"
        echo "5. 安装thanos-sidecar最新release"
        echo "6. 安装thanos-query最新release"
        read -p "请输入选项（0-9）: " OPTION

        case $OPTION in
        0) switch_github_proxy ;;
        1) install_prometheus ;;
        2) install_prometheus_local ;;
        3) install_node_exporter ;;
        4) install_node_exporter_local ;;
        5) install_thanos_sidecar;;
        6) install_thanos_query;;
        *) echo "无效选项。" ;;
        esac
        echo "按任意键返回主菜单..."
        read -n 1
    done

}

# 显示主菜单
main_menu