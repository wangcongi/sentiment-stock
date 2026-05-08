#!/bin/bash
# =====================================
# Vultr VPS 一键部署脚本
# 在VPS上执行: bash deploy.sh
# =====================================
set -e

echo "=== 舆情监控系统 VPS 部署 ==="

# 1. 安装系统依赖
apt update && apt install -y python3 python3-venv python3-pip git

# 2. 创建应用目录
mkdir -p /opt/sentiment-stock
cp -r . /opt/sentiment-stock/
cd /opt/sentiment-stock

# 3. 创建虚拟环境
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# 4. 配置 .env (提示用户输入)
if [ ! -f .env ]; then
    echo "请配置 .env 文件:"
    cp .env.example .env
    echo "编辑 /opt/sentiment-stock/.env 填入真实值后重新运行"
    exit 1
fi

# 5. 创建 systemd 服务(保活+开机自启)
cat > /etc/systemd/system/sentiment-stock.service << 'SERVICE'
[Unit]
Description=Sentiment Stock Monitor
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/sentiment-stock
Environment=PATH=/opt/sentiment-stock/.venv/bin:/usr/local/bin:/usr/bin:/bin
ExecStart=/opt/sentiment-stock/.venv/bin/python main.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable sentiment-stock
systemctl start sentiment-stock

echo "=== 部署完成 ==="
echo "查看状态: systemctl status sentiment-stock"
echo "查看日志: journalctl -u sentiment-stock -f"
