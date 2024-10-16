source ./src/prometheus_install.sh
# 主菜单
function main_menu() {
    while true; do
        clear
        
        echo "退出脚本，请按ctrl c退出即可"
        echo "请选择要执行的操作:"
        echo "1. 安装prometheus最新release"
        echo "2. 安装prometheus从本地文件"
        # echo "2. 安装alertmanager"
        # echo "3. 安装node_exporter"
        read -p "请输入选项（1-3）: " OPTION

        case $OPTION in
        1) install_prometheus ;;
        2) install_prometheus_local ;;
        # 3) install_alertmanager ;;
        # 4) install_node_exporter ;;
        *) echo "无效选项。" ;;
        esac
        echo "按任意键返回主菜单..."
        read -n 1
    done

}

# 显示主菜单
main_menu