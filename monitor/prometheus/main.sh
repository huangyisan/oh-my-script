#!/bin.bash
source ./src/prometheus_install.sh
source ./src/node_exporter_install.sh
# 主菜单
function main_menu() {
    while true; do
        clear
        
        echo "退出脚本，请按ctrl c退出即可"
        echo "请选择要执行的操作:"
        echo "1. 安装prometheus最新release"
        echo "2. 从本地安装prometheus"
        echo "3. 安装node_exporter最新release"
        echo "4. 从本地安装node_exporter"
        read -p "请输入选项（1-9）: " OPTION

        case $OPTION in
        1) install_prometheus ;;
        2) install_prometheus_local ;;
        3) install_node_exporter ;;
        4) install_node_exporter_local ;;
        *) echo "无效选项。" ;;
        esac
        echo "按任意键返回主菜单..."
        read -n 1
    done

}

# 显示主菜单
main_menu