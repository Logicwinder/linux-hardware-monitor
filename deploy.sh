#!/bin/bash

# 设置脚本遇到错误就停止
set -e

echo "🚀 开始部署 Linux 硬件监控脚本..."

# 1. 进入项目目录 (GitHub Actions 会自动把代码拉取到当前目录，所以直接用 .)
cd "$(dirname "$0")"

# 2. 安装 Python 依赖
echo "📦 正在安装依赖 (requirements.txt)..."
# 确保使用 python3 和 pip3
python3 -m pip install --user -r requirements.txt

# 3. 赋予执行权限 (可选，为了保险)
chmod +x monitor.py

# 4. 停止旧的进程 (如果有的话)
# 使用 pkill 杀死名为 monitor.py 的进程，避免重复运行
echo "🛑 检查并停止旧进程..."
pkill -f "python3 monitor.py" || true
# 或者更激进一点，杀死所有包含 'monitor.py' 的进程
# killall -9 python3 || true

# 5. 启动新进程 (后台运行)
# 使用 nohup 让程序在后台运行，即使断开 SSH 也不会停
# 日志输出到 system-manager.log (你的代码里已经配置了)
echo "▶️ 启动监控服务..."
nohup python3 monitor.py > /dev/null 2>&1 &

# 6. 验证启动
sleep 2
if pgrep -f "python3 monitor.py" > /dev/null; then
    echo "✅ 部署成功！监控服务已运行。"
    # 显示一下最新的日志尾巴，确认正常
    tail -n 5 system-manager.log || echo "日志文件尚未生成，请稍后查看。"
else
    echo "❌ 部署失败！服务未能启动。"
    exit 1
fi