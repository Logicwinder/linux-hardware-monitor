#!/bin/bash

# 设置脚本遇到错误就停止
set -e

echo "🚀 开始部署 Linux 硬件监控脚本..."

# ==========================================
# 1. 【新增】自动检测并安装系统依赖 (Git, Python, Pip)
# ==========================================
echo "🔍 检查系统环境..."

# 检测是否是 CentOS/RedHat 系统
if command -v yum &> /dev/null; then
    echo "📦 检测到 CentOS/RedHat 系统，正在安装依赖..."
    # 安装 Git, Python3, Pip3
    # -y 表示自动确认，--assumeyes 是某些版本的写法，通常 -y 即可
    yum install -y git python3 python3-pip || {
        echo "⚠️  yum 安装失败，尝试使用 dnf..."
        dnf install -y git python3 python3-pip
    }

# 检测是否是 Ubuntu/Debian 系统
elif command -v apt &> /dev/null; then
    echo "📦 检测到 Ubuntu/Debian 系统，正在安装依赖..."
    # 先更新软件源列表
    apt update
    # 安装 Git, Python3, Pip3
    DEBIAN_FRONTEND=noninteractive apt install -y git python3 python3-pip

else
    echo "❌ 未识别的系统类型，请手动安装 git, python3, python3-pip"
    exit 1
fi

echo "✅ 系统依赖检查/安装完成。"

# ==========================================
# 2. 进入项目目录
# ==========================================
cd "$(dirname "$0")"

# ==========================================
# 3. 安装 Python 依赖 (requirements.txt)
# ==========================================
echo "📦 正在安装 Python 依赖 (requirements.txt)..."
# 使用 python3 -m pip 确保使用的是刚才安装的 pip3
python3 -m pip install --user -r requirements.txt

# ==========================================
# 4. 停止旧的进程
# ==========================================
echo "🛑 检查并停止旧进程..."
pkill -f "python3 monitor.py" || true

# ==========================================
# 5. 启动新进程 (后台运行)
# ==========================================
echo "▶️ 启动监控服务..."
nohup python3 monitor.py > /dev/null 2>&1 &

# ==========================================
# 6. 验证启动
# ==========================================
sleep 2
if pgrep -f "python3 monitor.py" > /dev/null; then
    echo "✅ 部署成功！监控服务已运行。"
    tail -n 5 system-manager.log || echo "日志文件尚未生成，请稍后查看。"
else
    echo "❌ 部署失败！服务未能启动。"
    exit 1
fi