#!/bin/bash

# 设置版本号
current_version=20250425007

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
# Program name
PROGRAMNAME="gensyn"
update_script() {
    # 指定URL
    update_url="https://raw.githubusercontent.com/breaddog100/$PROGRAMNAME/main/$PROGRAMNAME.sh"
    file_name=$(basename "$update_url")

    # 下载脚本文件
    tmp=$(date +%s)
    timeout 10s curl -s -o "$HOME/$tmp" -H "Cache-Control: no-cache" "$update_url?$tmp"
    exit_code=$?
    if [[ $exit_code -eq 124 ]]; then
        echo "命令超时"
        return 1
    elif [[ $exit_code -ne 0 ]]; then
        echo "下载失败"
        return 1
    fi

    # 检查是否有新版本可用
    latest_version=$(grep -oP 'current_version=([0-9]+)' $HOME/$tmp | sed -n 's/.*=//p')

    if [[ "$latest_version" -gt "$current_version" ]]; then
        clear
        echo ""
        # 提示需要更新脚本
        printf "\033[31m脚本有新版本可用！当前版本：%s，最新版本：%s\033[0m\n" "$current_version" "$latest_version"
        echo "正在更新..."
        sleep 3
        mv $HOME/$tmp $HOME/$file_name
        chmod +x $HOME/$file_name
        exec "$HOME/$file_name"
    else
        # 脚本是最新的
        rm -f $tmp
    fi

}

# 节点安装
function install_node() {

    export NEEDRESTART_MODE=a

    # 定义目标swap大小（单位：GB）
    TARGET_SWAP_GB=32

    # 获取当前swap大小（单位：KB）
    CURRENT_SWAP_KB=$(free -k | awk '/Swap:/ {print $2}')

    # 转换为GB
    CURRENT_SWAP_GB=$((CURRENT_SWAP_KB / 1024 / 1024))

    echo "当前Swap大小: ${CURRENT_SWAP_GB}GB"

    if [ "$CURRENT_SWAP_GB" -lt "$TARGET_SWAP_GB" ]; then

        # 临时关闭所有swap
        swapoff -a

        # 删除所有swap分区（如果有）
        sed -i '/swap/d' /etc/fstab

        # 创建新的swap文件
        SWAPFILE=/swapfile
        fallocate -l ${TARGET_SWAP_GB}G $SWAPFILE
        chmod 600 $SWAPFILE
        mkswap $SWAPFILE
        swapon $SWAPFILE

        # 添加到fstab
        echo "$SWAPFILE none swap sw 0 0" >> /etc/fstab

        # 调整swappiness参数（可选）
        echo "vm.swappiness = 10" >> /etc/sysctl.conf
        sysctl -p

        echo "Swap已调整为${TARGET_SWAP_GB}GB"
    fi

    sudo apt-get update && sudo apt-get upgrade -y
    sudo apt install screen curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev  -y
    
    sudo apt update
    sudo apt install python3.10 python3.10-venv python3.10-dev -y
    sudo apt install python-is-python3
    python --version
    sudo apt-get update
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    sudo apt-get install nodejs -y
    node -v
    sudo npm install -g yarn
    yarn -v
    curl -o- -L https://yarnpkg.com/install.sh | bash
    export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
    source ~/.bashrc

    git clone https://github.com/gensyn-ai/rl-swarm/
    cd rl-swarm
    python -m venv .venv
    source .venv/bin/activate

    cd $HOME/rl-swarm
    sed -i '1i # ~/.bashrc: executed by bash(1) for non-login shells.\n\n# If not running interactively, don'\''t do anything\ncase $- in\n    *i*) ;;\n    *) return;;\nesac\n' ~/.bashrc
    screen -S rl_swarm -dm bash -c 'source .venv/bin/activate && ./run_rl_swarm.sh'

	echo "部署完成..."
}

# 查看日志
function view_logs(){
	screen -r rl_swarm
}

# 启动节点
function start_node(){
    cd $HOME/rl-swarm
    screen -S rl_swarm
    source .venv/bin/activate
    ./run_rl_swarm.sh
	echo "$PROGRAMNAME 节点已启动"
}

# 停止节点
function stop_node(){
	screen -S rl_swarm -X quit
	echo "$PROGRAMNAME 节点已停止"
}

# 卸载节点
function uninstall_node(){
	echo "你确定要卸载 $PROGRAMNAME 节点程序吗？这将会删除所有相关的数据。[Y/N]"
	read -r -p "请确认: " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            echo "开始卸载节点程序..."
            stop_node
			rm -rf $PROJECT_DIR
            sudo rm -f /etc/systemd/system/$PROGRAMNAME.service
            sudo systemctl daemon-reload
			echo "卸载完成。"
            ;;
        *)
            echo "取消卸载操作。"
            ;;
    esac
}

# 主菜单
function main_menu() {
	while true; do
	    clear
	    echo "================== $PROGRAMNAME 一键部署脚本=================="
		echo "当前版本：$current_version"
		echo "沟通电报群：https://t.me/lumaogogogo"
		echo "最低配置：4C16G100G；推荐配置：8C32G300G；"
	    echo "请选择要执行的操作:"
	    echo "1. 部署节点 install_node"
	    echo "2. 查看状态 view_logs"
	    echo "3. 查看日志 view_logs"
	    echo "4. 停止节点 stop_node"
	    echo "5. 启动节点 start_node"
	    echo "1618. 卸载节点 uninstall_node"
	    echo "0. 退出脚本 exit"
	    read -p "请输入选项: " OPTION
	
	    case $OPTION in
	    1) install_node ;;
	    2) view_logs ;;
	    3) view_logs ;;
	    4) stop_node ;;
	    5) start_node ;;
	    1618) uninstall_node ;;
	    0) echo "退出脚本。"; exit 0 ;;
	    *) echo "无效选项，请重新输入。"; sleep 3 ;;
	    esac
	    echo "按任意键返回主菜单..."
        read -n 1
    done
}

# 检查更新
update_script

# 显示主菜单
main_menu