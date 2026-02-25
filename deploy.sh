#!/bin/bash
set -e
cd ~/linux-hardware-monitor

echo "[$(date)] 开始部署..." >> ~/deploy_status.log

# 1. 拉取最新代码
git pull origin main >> ~/deploy_status.log 2>&1

# 2. 安装系统依赖
if command -v yum &> /dev/null; then
    yum install -y epel-release git gcc gcc-c++ make python3 python3-pip python3-devel >> ~/deploy_status.log 2>&1 || true
else
    apt update >> ~/deploy_status.log 2>&1 && apt install -y git gcc g++ make python3 python3-pip python3-dev >> ~/deploy_status.log 2>&1 || true
fi

# 3. 安装 Python 依赖 (清华源)
python3 -m pip install --upgrade pip -i https://pypi.tuna.tsinghua.edu.cn/simple --user >> ~/deploy_status.log 2>&1
python3 -m pip install -i https://pypi.tuna.tsinghua.edu.cn/simple --user -r requirements.txt >> ~/deploy_status.log 2>&1

# 4. 重启服务
pkill -f "python3 monitor.py" || true
nohup python3 monitor.py > /dev/null 2>&1 &

sleep 3
if pgrep -f "python3 monitor.py" > /dev/null; then
    echo "[$(date)] ✅ SUCCESS" >> ~/deploy_status.log
else
    echo "[$(date)] ❌ FAILED" >> ~/deploy_status.log
fi