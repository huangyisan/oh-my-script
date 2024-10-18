# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
    exit 1
fi

# 检查是否为 Ubuntu 系统
cat /etc/os-release | grep -q "Ubuntu"
if [ $? -ne 0 ]; then
    echo "此脚本仅支持 Ubuntu 系统。"
    exit 1
fi

# 检查是否为x64系统
if [ "$(uname -m)" != "x86_64" ]; then
    echo "此脚本仅支持x64系统。"
    exit 1
fi
