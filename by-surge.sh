#!/bin/bash
current_dir=$(pwd)

function run_surge() {
  surge_path=$(npm bin -g)/surge
  $surge_path "$@"
}
function generate_random_domain() {
  domain_length=10
  random_string=$(head /dev/urandom | tr -dc a-z0-9 | head -c $domain_length)
  echo "${random_string}.surge.sh"
}

function get_token() {
  echo ""
  echo "您的 Surge token 如下："
  token_result=$(run_surge token)
  echo "${token_result}"
  echo -e "${GREEN}请妥善保管您的 token。${NC}"
}
# 输出颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# 检测操作系统类型
if [[ "$(uname -s)" = "Linux" && -e "/etc/os-release" ]]; then
  source /etc/os-release
  case "$ID" in
    debian|ubuntu) OS="debian" ;;
    centos|rhel|fedora) OS="centos" ;;
    *) echo -e "${RED}不支持的操作系统：$NAME${NC}" ; exit 1 ;;
  esac
else
  echo -e "${RED}不支持的操作系统：$(uname -s)${NC}"
  exit 1
fi

# 安装必要的软件包
function install_packages() {
  case $OS in
    debian) 
      sudo apt-get update
      sudo apt-get install -y curl nodejs npm
      npm install -g surge
      ;;
    centos)
    
      sudo yum clean all
      sudo yum -y update
      sudo yum -y install epel-release
      #curl -sL https://rpm.nodesource.com/setup_lts.x | sudo bash -
      curl -sL https://rpm.nodesource.com/setup_14.x | sudo -E bash -
      sudo yum install -y gcc-c ++ make
      sudo wget -P /opt https://npm.taobao.org/mirrors/node/v10.14.1/node-v10.14.1-linux-x64.tar.gz
      sudo tar -xvf /opt/node-v10.14.1-linux-x64.tar.gz -C /opt/
      sudo mv /opt/node-v10.14.1-linux-x64 /opt/node
      sudo mv /opt/node/bin/node /usr/local/bin
      sudo mv /opt/node/bin/npm /usr/local/bin
      sudo mv /opt/node/bin/mpx /usr/local/bin
      #sudo echo "export NODE_HOME=/opt/node" >> /etc/profile
      #sudo echo "export PATH=$NODE_HOME/bin:$PATH" >> /etc/profile
      sudo source /etc/profile
      #sudo yum clean all 
      sudo yum -y install wget
      sudo yum -y install curl
      sudo yum -y install npm
      #sudo yum -y install nodejs
      ;;
  esac
}
# 检测 Node.js 是否已经安装
if ! command -v node &>/dev/null; then
  echo -e "${YELLOW}检测到未安装 Node.js，正在自动安装...${NC}"
  install_packages
fi

# 检查 surge 是否已经安装
if ! command -v surge &>/dev/null; then
  echo -e "${YELLOW}检测到未安装 Surge.sh，正在自动安装...${NC}"
  sudo npm install -g surge
fi

# 定义环境变量
export SURGE_LOGIN=""
export SURGE_TOKEN=""
CONFIG_FILE=~/.surge_config

# 检查是否已经登录
function check_login() {
  if [[ -z "run_surge_LOGIN" || -z "run_surge_TOKEN" ]]; then
    return 1
  fi
  return 0
}

# 自动登录或注册
function auto_login_or_register() {
  echo -e "${YELLOW}尚未登录 Surge.sh，请选择操作：${NC}"
  echo "1. 登录"
  echo "2. 注册"
  read -p "请输入数字并回车: " choice
  case $choice in
    1) 
      read -p "请输入邮箱: " email
      read -sp "请输入密码: " password
      echo ""
      echo "正在登录，请稍候..."
      echo "export SURGE_LOGIN=\"$email\"" > $CONFIG_FILE
      echo "export SURGE_TOKEN=\"$(surge token $email $password)\"" >> $CONFIG_FILE
      source $CONFIG_FILE
      ;;
    2) surge register ;;
    *) echo -e "${RED}无效的选择，请重新输入。${NC}" ; auto_login_or_register ;;
  esac
}

# 检查登录状态，未登录则自动登录或注册
if ! check_login; then
  if [[ -f $CONFIG_FILE ]]; then
    source $CONFIG_FILE
    if check_login; then
      echo -e "${GREEN}检测到已保存的登录信息，自动登录成功！${NC}"
    else
      auto_login_or_register
    fi
  else
    auto_login_or_register
  fi
fi

# surge.sh 命令路径
SURGE=$(npm bin -g)/surge



# 显示菜单并读取用户选择
function show_menu() {
  echo ""
  echo "当前默认路径：${current_dir}"
  echo ""
  echo "请选择要执行的操作："
  echo "1. 发布当前目录到 Surge"
  echo "2. 发布指定目录到 Surge"
  echo "3. 列出全部项目"
  echo "4. 删除 Surge 上的项目"
  echo "5. 更新密码"
  echo "6. 获取 Surge token"
  echo "7. 退出"
  read -p "请输入数字并回车: " choice
  case $choice in
    1) publish_current_dir ;;
    2) publish_specified_dir ;;
    3) list_projects ;;
    4) delete_project ;;
    5) update_password ;;
    6) get_token ;;
    7) exit 0;;
    *) invalid_choice;;
  esac
}



# 发布当前目录到 Surge
function publish_current_dir() {
  cd "${current_dir}"
  echo ""
  echo "当前发布项目路径：${current_dir}"
  echo ""
    read -p "请输入要发布的域名（留空使用随机域名）: " domain
  if [ -z "$domain" ]; then
    domain=$(generate_random_domain)
    echo "使用随机域名：$domain"
  fi

  echo ""
  echo "正在发布，请稍候..."
  run_surge --project $current_dir --domain $domain
  echo ""
  echo -e "${GREEN}发布成功.请访问 https://${domain} ${NC}"
}

# 发布指定目录到 Surge
function publish_specified_dir() {
  dir=""
  while [ ! -d "$dir" ]; do
    read -p "请输入要发布的目录路径: " dir
    if [ ! -d "$dir" ]; then
      echo -e "${RED}目录不存在，请重新输入。${NC}"
    fi
  done
   read -p "请输入要发布的域名（留空使用随机域名）: " domain
  if [ -z "$domain" ]; then
    domain=$(generate_random_domain)
    echo "使用随机域名：$domain"
  fi
  echo ""
  echo "正在发布，请稍候..."
  run_surge --project $dir --domain $domain
  echo ""
  echo -e "${GREEN}发布成功.请访问 https://${domain} ${NC}"
}

# 列出全部项目
function list_projects() {
  echo ""
  echo "正在获取项目列表，请稍候..."
  run_surge list
  echo -e "${GREEN}以上是您的全部项目。${NC}"
}

# 删除 Surge 上的项目
function delete_project() {

  echo ""
  echo "正在获取项目列表，请稍候..."
  run_surge list
  echo -e "${GREEN}以上是您的全部项目。${NC}"
  project=""
  while [ -z "$project" ]; do
    read -p "请输入要删除的项目域名: " project
  done
  echo ""
  echo "正在删除，请稍候..."
  run_surge teardown $project
  echo ""
  echo -e "${GREEN}删除成功！${NC}"
}

# 更新密码
function update_password() {
  read -sp "请输入新密码: " password
  echo ""
  echo "正在更新，请稍候..."
  echo "export SURGE_TOKEN=\"$(surge token run_surge_LOGIN $password)\"" >> $CONFIG_FILE
  source $CONFIG_FILE
  echo ""
  echo -e "${GREEN}更新密码成功！${NC}"
}

# 无效选择的处理
function invalid_choice() {
  echo -e "${RED}无效的选择，请重新输入。${NC}"
}

# 显示欢迎信息
echo -e "${GREEN}欢迎使用surge脚本管理端！${NC}"

# 显示菜单并循环执行
while true; do
  show_menu
done
