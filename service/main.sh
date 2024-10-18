#!/bin.bash
source ./common/pre_check.sh
source ./common/env.sh

# github proxy
function switch_github_proxy() {
    # 判断github_proxy_prefix是否为空
    if [ -z "$github_proxy_prefix" ]; then
        export github_proxy_prefix="https://ghp.ci/"
        echo "已设置github代理为：$github_proxy_prefix"
    else
        unset github_proxy_prefix
        echo "已取消github代理。"
    fi
}

exec_path=$(pwd)

# 避免环境变量污染
function source_consul() {
    source ./consul/src/consul_install.sh
}

# 主菜单
function main_menu() {
    while true; do
        clear

        echo "退出脚本，请按ctrl c退出即可"
        echo "请选择要执行的操作:"
        echo "0. github代理开关"
        echo "1. 从本地安装consul server"
        echo "2. 从本地安装consul agent最新release"
        read -p "请输入选项（0-9）: " OPTION

        case $OPTION in
        0) switch_github_proxy ;;
        1) source_consul && install_consul_server ;;
        2) source_consul && install_consul_agent ;;
        *) echo "无效选项。" ;;
        esac
        echo "按任意键返回主菜单..."
        read -n 1
    done

}

# 显示主菜单
main_menu
