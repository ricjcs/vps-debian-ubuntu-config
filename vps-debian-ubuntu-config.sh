#! /usr/bin/env sh
#================================================================
# VPS DEBIAN & UBUNTU CONFIG
#
# AUTOR     : Ricardo S.
# GITHUB    : https://github.com/ricjcs/vps-debian-ubuntu-config
# DESCRIÇÃO : Script para facilitar a configuração de uma VPS com
# sistema operativo Debian ou Ubuntu. Inclui configurações gerais,
# configurações de segurança, instalação e configuração do Apache
# e Wordpress, etc, através do terminal. Em alternativa sugere a 
# instalação de paineis administrativos de forma a que quase todo 
# o processo de gestão do servidor possa ser feito por interface
# gráfica.
#================================================================

prgname="VPS DEBIAN & UBUNTU CONFIG"
version="1.0"

#################################################################
#   FUNÇÕES                                      ################
#################################################################

# VERIFICAÇÃO DE ROOT -------------------------------------------
select_root() {
    if [[ ! $(whoami) = "root" ]]; then 
        echo "OPS! VOCÊ TEM QUE EXECUTAR O SCRIPT COMO ROOT."
        exit 1
    fi
}
# ---------------------------------------------------------------

###############################################
#   CONFIGURAÇÕES INICIAIS         ############
###############################################

# ATUALIZAR SISTEMA
update_system() {
    clear
    echo "---------------------------------------------------"
    echo "  Update System"
    echo "---------------------------------------------------"
    apt update
    apt upgrade
}

# CONFIGURAR DATA
data_config() {
    clear
    echo "---------------------------------------------------"
    echo "  Data config"
    echo "---------------------------------------------------"
    dpkg-reconfigure tzdata
}

# ALTERAR PASSWORD DO ROOT
change_root_password() {
    clear
    echo "---------------------------------------------------"
    echo "  Alterar password do root"
    echo "---------------------------------------------------"
    passwd
}

# CRIAR UTILIZADOR COMUM
add_new_user() {
    clear
    echo "---------------------------------------------------"
    echo "  Criar utilziador comum"
    echo "---------------------------------------------------"
    echo "  Qual o nome do utilizador comum?"
    printf "  "
    read novoUser
    adduser $novoUser
}

# INSTALAR UTILITÁRIOS
utilities() {
    clear
    echo "---------------------------------------------------"
    echo "  Instalando utilitários: htop e net-tools"
    echo "---------------------------------------------------"
    apt install htop net-tools
    echo "---------------------------------------------------"
    echo "  Se tiver necessidade, adicione reposidórios em:
    /etc/apt/sources.list
    "
}

# CONFIGURAÇÕES DE SEGURANÇA SSH #############################
ssh_security() {
    clear
    echo "---------------------------------------------------"
    echo "  Configurações de Segurança SSH "
    echo "---------------------------------------------------"
    echo "  Fazer as alterações manualmente em:"
    echo "  /etc/ssh/sshd_config"
    echo
    echo "  Para facilitar, faça as alterações num novo terminal"
    echo "  enquanto mantém este aberto."
    echo "---------------------------------------------------"
    echo
    echo "  Alterar porta padrão 22 para uma porta alta:"
    echo "  #Port 22 >>>>>> Port [NOVA] "
    echo
    echo "  Desativar login como root:"
    echo "  PermitRootLogin no"
    echo
    echo "  Desativar senhas vazias:"
    echo "  PermitEmptyPasswords no"
    echo
    echo "  Encaminhamento X11:"
    echo "  X11Forwarding no "
    echo 
    echo "  Ativar tempo de inatividade:"
    echo "  ClientAliveInterval 300"
    echo
    echo "  Ativar tentativas de acesso:"
    echo "  MaxAuthTries 4"
    echo
    echo "  Máximo de conexões por ip:"
    echo "  MaxSessions 2"
    echo
    echo "---------------------------------------------------"
    pause
    systemctl restart ssh
    systemctl status ssh
    echo
    echo "---------------------------------------------------"
    echo
    echo " Se já configurou a nova porta, saia e faça a   "
    echo " conexão com a nova porta, exemplo:"
    echo " ssh -p PORTA user@ip-ou-domínio-do-servidor"
}

###############################################
#   AUTO-UPDATES DE SEGURANÇA E FAIL2BAN ######
###############################################

# AUTO-UPDATES COM O unattended-upgrades e 20auto-upgrades
auto_updates() {
    clear
    echo "---------------------------------------------------"
    echo "  AUTO-UPDATES COM O unattended-upgrades e 20auto-upgrades"
    echo "---------------------------------------------------"
    echo "  Instalando o unattended-upgrades e Ativando no Boot"
    echo "---------------------------------------------------"
    apt install unattended-upgrades
    systemctl enable unattended-upgrades
    echo "---------------------------------------------------"
    echo "  Status do unattended-upgrades"
    echo "  Digite :q para sair e continuar"
    echo "---------------------------------------------------"
    systemctl status unattended-upgrades
    pause
    clear
    echo "---------------------------------------------------"
    echo
    echo "  [50unattended-upgrades]"
    echo "  Verificar manualmente as configurações em:"
    echo "  /etc/apt/apt.conf.d/50unattended-upgrades"
    echo
    echo "  Alterar caso seja necessário:"
    echo '
        "${distro_id}ESMApps:${distro_codename}-apps-security";
        "${distro_id}ESM:${distro_codename}-infra-security";
    //  "${distro_id}:${distro_codename}-updates";
    //  "${distro_id}:${distro_codename}-proposed";
    //  "${distro_id}:${distro_codename}-backports";
    '
    echo
    echo "  [20auto-upgrades]"
    echo "  Verificar manualmente as configurações em:"
    echo "  /etc/apt/apt.conf.d/20auto-upgrades"
    echo
    echo "  Alterar caso seja necessãrio:"
    echo "  APT::Periodic::Update-Package-Lists "1"; "
    echo "  APT::Periodic::Unattended-Upgrade "1"; "
    echo
    echo "---------------------------------------------------"
    pause
    clear
    echo "---------------------------------------------------"
    echo "  Teste"
    echo "---------------------------------------------------"
    unattended-upgrades --dry-run --debug
}

# FAIL2BAN: INSTALL
fail2ban_install() {
    clear
    echo "---------------------------------------------------"
    echo "  Instalando o Fail2ban"
    echo "---------------------------------------------------"
    systemctl restart rsyslog
    apt install fail2ban
    cd /etc/fail2ban/
    cp -v jail.conf jail.local
    cp -v fail2ban.conf fail2ban.local

    systemctl enable fail2ban
    systemctl start fail2ban

    clear
    echo "---------------------------------------------------"
    echo "  Status do Fail2ban"
    echo "  Digite :q para sair e continuar"
    echo "---------------------------------------------------"
    systemctl status fail2ban
    fail2ban-client status sshd
}

# FAIL2BAN: MANUAL CONFIG
fail2ban_manual_config() {
    clear
    echo "---------------------------------------------------"
    echo "  Fail2ban"
    echo "  Fazer configurações manualmente em /etc/fail2ban/jail.local"
    echo "---------------------------------------------------"
    echo "
    -- Categoria Global --
    [Default]
    ignoreip = 127.0.0.1/8 ::1  # ativar/configurar para ignorar ip local
    
    bantime  = 1h    # Tempo de ban do ip
    findtime  = 5m   # Limite de tempo
    maxretry = 5     # Número de tentativas de login
    
    -- Categoria SSH Servers --
    [sshd]
    mode = normal
    enabled = true
    
    port = ssh  # substituir o ssh pela porta que está a ser utilizada
    
    [dropbear]
    port = ssh # colocar o número da porta
    
    [seLinux-ssh]
    port = ssh # colocar o número da porta
    
    -- No caso de estar a usar o Apache: --  
    [apache-badbots]
    enabled = true     

    [apache-noscript]
    enabled = true

    [apache-overflows]
    enabled = true

    [apache-fakegooglebot]
    enabled = true

    [apache-modsecurity]
    enabled = true

    [apache-shellshock]
    enabled = true
    "
    echo "---------------------------------------------------"
    pause
    clear
    echo "---------------------------------------------------"
    echo "  Status do Fail2ban"
    echo "  Digite :q para sair e continuar"
    echo "---------------------------------------------------"
    systemctl status fail2ban
    fail2ban-client status sshd
}

###############################################
#   FIREWALL                             ######
###############################################

# UFW
firewall() {
    clear
    echo "---------------------------------------------------"
    echo "  Instalando a UFW"
    echo "---------------------------------------------------"
    apt install ufw
    echo "---------------------------------------------------"
    echo "  Ligando Negação de Entrada e Saída"
    echo "---------------------------------------------------"
    ufw default deny outgoing
    ufw default deny incoming
    echo "---------------------------------------------------"
    echo "  Abrir manualmente portas de entrada e saída"
    echo "  conforme as necessidades, usar os comandos:"
    echo "  ufw allow out port / ufw allow in port "
    echo
    echo "  Algumas portas úteis"
    echo
    echo "  Outgoing (SAÍDA)
            80  ======> HTTP
            443 ======> HTTPS
            53  ======> DNS  
            "
    echo
    echo "  Incoming (ENTRADA)
            port_num ======> SSH
            80       ======> HTTP
            443      ======> HTTPS    
            "
    echo
    echo "  ATENÇÃO !!!"
    echo "  MUITO IMPORTANTE: Abrir a porta SSH com o valor escolhido"
    echo "  para que seja possível fazer a conexão à VPS."
    echo "  Usar o comando num novo terminal: ufw allow in port"
    echo
    pause
    ufw enable
    systemctl enable ufw
    ufw status
}

###############################################
#   APLICAÇÕES / SERVIÇOS                ######
###############################################

# APACHE: Instalação/Configuração de segurança
apache_install_config() {
    clear
    echo "---------------------------------------------------"
    echo "  Instalando o APACHE"
    echo "---------------------------------------------------"
    apt install apache2
    pause
    clear
    echo "---------------------------------------------------"
    echo "  APACHE: Configurações manuais de segurança"
    echo "---------------------------------------------------"
    echo "  Editar os seguintes ficheiros:"
    echo "
    -- Ficheiro security.conf --
    /etc/apache2/conf-available/security.conf

         ServerTokens prod    # para não informar o SO
         ServerSignature Off  # Para não mostrar a versão do Apache
    
    -- Ficheiro apache2.conf --
    /etc/apache2/apache2.conf
    
    <Directory /var/www/>
        Options -FollowSymLinks
        Optinos -ExecCGI
        Optinos -Indexes
        AllowOverride None
        Require all denied

    Timeout 45

    MaxKeepAliveRequests 100
    "
    pause
    clear
    systemctl restart apache2
    echo "---------------------------------------------------"
    echo "  Status do Apache"
    echo "  Digite :q para sair e continuar"
    echo "---------------------------------------------------"
    systemctl status apache2
} 

# MARIADB 
mariadb_install_config() {
    clear
    echo "---------------------------------------------------"
    echo "  Instalando MariaDB"
    echo "---------------------------------------------------"
    apt install mariadb-server
    echo "---------------------------------------------------"
    echo "  Status do MariaDB"
    echo "  Digite :q para sair e continuar"
    echo "---------------------------------------------------"
    systemctl status mariadb
    clear
    echo "---------------------------------------------------"
    echo "  Configuração de segurança com o script mysql_secure"
    echo "---------------------------------------------------"
    echo "  Definir password da MariaDB para user root"
    echo "  Definir o restante como Yes."
    echo "---------------------------------------------------"
    mysql_secure_installation
    echo "---------------------------------------------------"
    echo "O MariaDB utiliza a porta 3306, caso seja necessário abrir na firewall."
}

# PHP E EXTENÇÕES
php_install() {
    clear
    echo "---------------------------------------------------"
    echo "  Instalando o PHP"
    echo "---------------------------------------------------"
    apt install php libapache2-mod-php php-mysql
    echo "---------------------------------------------------"
    echo "  Instalando extenções para trabalhar bem com o Wordpress"
    echo "---------------------------------------------------"
    apt install php-curl php-gd php-mbstring php-xml php-xmlrpc php-soap php-intl php-zip

    systemctl restart apache2
}

# HOSTNAME
hostname_server() {
    clear
    echo "---------------------------------------------------"
    echo "  Definir Hostname no servidor (se não estiver correto)"
    echo "---------------------------------------------------"
    echo "  Atualiza o ficheiro /etc/hostname"
    echo "  Qual é o seu domínio?"
    printf "  "
    read meuDominioSite
    hostnamectl set-hostname $meuDominioSite
}

# CERTIFICADO SSL
certificado_ssl_certbot() {
    clear
    echo "---------------------------------------------------"
    echo "  Certificado SSL com Certbot"
    echo "---------------------------------------------------"
    echo "  Abrindo portas na Firewall: 80, 443, 53"
    ufw allow out 80
    ufw allow out 443
    ufw allow out 53
    echo "  Instalando..."
    apt install python3-certbot-apache
    echo "---------------------------------------------------"
    echo "  Configuração..."
    certbot --apache --register-unsafely-without-email
    echo "---------------------------------------------------"
    echo "  Configurar Cron do user root para renovação automática do cerficado, de 3 em 3 meses."
    echo "  Adicionar ao crontab:"
    echo "  0 0 1 * * certbot --apache renew "
    pause
    crontab -e
}

###############################################
#   WORDPRESS                             #####
###############################################

# WORDPRESS PRÉ-PROCESSO DE INSTALAÇÃO WORDPRESS
# Criação de DB e User
# Outras configurações
wordpress_pre_install() {
    clear
    echo "---------------------------------------------------"
    echo "  Criação de Data Base e User"
    echo "---------------------------------------------------"
    echo "  Qual o nome da DB?"
    printf "  "
    read nomeDB
    echo "  Qual o user a criar para manipular a DB?"
    printf "  "
    read userDB
    echo "  Qual a password para o user?"
    printf "  "
    read passUserDB
    echo "---------------------------------------------------"
    echo "  Para executar a criação utilizar a password criada para" 
    echo "  logar na MariaDB com o user root."
    echo "---------------------------------------------------"
    mysql -u root -p -e "CREATE DATABASE $nomeDB DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci; GRANT ALL ON $nomeDB.* TO '$userDB'@'localhost' IDENTIFIED BY '$passUserDB'; FLUSH PRIVILEGES;"
    pause
    clear
    echo "---------------------------------------------------"
    echo "  Configuração para o .httacess funcionar"
    echo "---------------------------------------------------"
    echo "  Editar manualmente o ficheiro /etc/apache2/apache2.conf"
    echo "
    <Directory /var/www/>
        Options -FollowSymLinks
        Optinos -ExecCGI   
        Optinos -Indexes      
        AllowOverride All  #<<<<
        Require all denied
    "
    pause
    clear
    echo "---------------------------------------------------"
    echo "  Ativando Módulo Rewrite do Apache"
    echo "---------------------------------------------------"
    a2enmod rewrite
    systemctl restart apache2
    echo
    echo "---------------------------------------------------"
    echo "  Execução de teste de configuração"
    echo "---------------------------------------------------"
    apache2ctl configtest
}

# WORDPRESS DOWNLOAD E INSTALAÇÃO
wordpress_install() {
    clear
    echo "---------------------------------------------------"
    echo "  Download e Intalação do Wordpress"
    echo "---------------------------------------------------"
    cd /var/www/html
    rm index.html

    curl -O https://wordpress.org/latest.tar.gz
    tar xvf latest.tar.gz
    rm latest.tar.gz

    cd wordpress/
    mv * ../
    cd ..
    rmdir wordpress

    cp -v wp-config-sample.php wp-config.php
    > .htaccess
    mkdir -v wp-content/upgrade

    chown -R www-data:www-data .

    find . -type f -exec chmod 640 {} \;
    find . -type d -exec chmod 750 {} \; 

    echo "---------------------------------------------------"
    echo "  FEITO!"
    echo "  Editar manualmente o ficheiro wp-config.php" 
}

###############################################
#   MAILUTILS, POSIX E LOGWATCH          ######
###############################################

# MAILUTILS E POSTFIX
mailutils_postfix_install() {
    clear
    echo "---------------------------------------------------"
    echo "  Instalação de Utilitários de e-mail e POSTFIX configurado"
    echo "  para que o servidor possa mandar e-mails localmente gerados"
    echo "  pelo Logwatch"
    echo "---------------------------------------------------"
    apt install mailutils -y
    echo
    echo "---------------------------------------------------"
    echo "  Seguidamente, na instalação do POSTFIX usar a seguinte configuração:"
    echo "      1. Tipo de configuração: Local only"
    echo "      2. System mail name: localhost"
    echo "  O Postfix trabalha na porta 25, abrir caso seja necessário."
    pause
    apt install postfix
}

# LOGWATCH
logwatch_install() {
    clear
    echo "---------------------------------------------------"
    echo "  Instalando Logwatch"
    echo "---------------------------------------------------"
    apt install logwatch
    echo "---------------------------------------------------"
    echo "  Configurar manualmente em:"
    echo " /usr/share/logwatch/default.conf/logwatch.conf"
    echo "---------------------------------------------------"
    echo "
    Format = text
    MailTo = nome-user@localhost
    Range = yesterday  # envia o relatório do dia anterior
    Detail = Med   # detalhe do relatório
    Service = All  # mostra relatório de todos os serviços: ssh, apache, etc.
    Service = "-exim"
    "
}
    
###############################################
#   PAINÉIS DE ADMNISTRAÇÃO              ######
###############################################

# WEBMIN
webmin_install() {
    clear
    echo "---------------------------------------------------"
    echo "  Instalando Webmin"
    echo "---------------------------------------------------"
  
    echo "deb http://download.webmin.com/download/repository/ sarge contrib" | sudo tee -a /etc/apt/sources.list
    echo "deb http://webmin.mirror.somersettechsolutions.co.uk/repository/ sarge contrib" | sudo tee -a /etc/apt/sources.list
    wget -q http://www.webmin.com/jcameron-key.asc -O- | sudo apt-key add -
    apt update
    apt install webmin apt-transport-https
}

# VIRTUALMIN
virtualmin_install() {
    clear
    echo "---------------------------------------------------"
    echo "  Instalando Virtualmin"
    echo "---------------------------------------------------"
    mount -o remount,exec /tmp

    wget https://software.virtualmin.com/gpl/scripts/install.sh
    sh install.sh

    mount -o remount,noexec /tmp
}

# CYBERPANEL e LITESPEED
cyberpanel_LiteSpeed_install() {
    clear
    echo "---------------------------------------------------"
    echo "  Instalando Cyberpanel com LiteSpeed"
    echo "---------------------------------------------------"
    sh <(curl https://cyberpanel.net/install.sh || wget -O - https://cyberpanel.net/install.sh)
}

# PAUSA NO LOOP -------------------------------------------------
pause() {
    printf "\e[1;91m\n  <ENTER PARA CONTINUAR> \e[m\n"
    read go
}
# ---------------------------------------------------------------

#################################################################
#   INICIO / MENU                               #################
#################################################################
select_root
while true; do
    clear
    echo "---------------------------------------------------"
    printf "\e[37;45m $prgname - $version \e[m\n"
    echo "---------------------------------------------------"
    echo
    printf "\e[1;96m »»» CONFIGURAÇÕES INICIAIS \e[m\n"
    echo " 1. Atualizar o Sistema"
    echo " 2. Data/time config"
    echo " 3. Alterar password do root"
    echo " 4. Criar utilizador comum"
    echo " 5. Instalar utilitários: htop e net-tools"
    echo " 6. Configurações de segurança SSH"
    echo
    printf "\e[1;96m »»» AUTO-UPDATES DE SEGURANÇA E FAIL2BAN \e[m\n"
    echo " 7. Auto-Updates com unattended-upgrades e 20auto-upgrades"
    echo " 8. Fail2ban: Intalação"
    echo " 9. Fail2ban: Configurações a fazer manualmente"
    echo
    printf "\e[1;96m »»» FIREWALL \e[m\n"
    echo " 10. UFW: Instalação e Configuração"
    echo
    printf "\e[1;96m »»» APLICAÇÕES/SERVIÇOS \e[m\n"
    echo " 11. Apache: Intalação e config. de segurança"
    echo " 12. MariaDB: Intalação e config. de segurança"
    echo " 13. PHP e Extenções"
    echo " 14. Hostname config"
    echo " 15. Certificado SSL com Certbot"
    echo
    printf "\e[1;96m »»» WORDPRESS \e[m\n"
    echo " 16. Pré-processo de instalação WP (Criação de DB/User, etc)"
    echo " 17. Download e Instalação"
    echo
    printf "\e[1;96m »»» MAILUTILS, POSIX E LOGWATCH \e[m\n"
    echo " 18. Mailutils e Postfix"
    echo " 19. Logwatch"
    echo
    printf "\e[1;96m »»» PAINÉIS DE ADMINISTRAÇÃO \e[m\n"
    echo " Em alternativa ao que foi feito anteriormente"
    echo " via linha de comando, instale um dos painéis"
    echo " administrativos para gerir a VPS."
    echo " 20. Webmin"
    echo " 21. Virtualmin"
    echo " 22. Cyberpanel com LiteSpeed"
    echo
    echo "---------------------------------------------------"
    printf "\e[1;91m E. Exit    \e[1;93m S. Sobre \e[m\n"
    echo "---------------------------------------------------"
    printf " Escolha uma opção: "
    read menuOP

    case $menuOP in
        # ====== CONFIGURAÇÕES INICIAIS ======
        1) update_system ;;
        2) data_config ;;
        3) change_root_password ;;
        4) add_new_user ;;
        5) utilities ;;
        6) ssh_security ;;
        # ====== AUTO-UPDATES DE SEGURANÇA E FAIL2BAN ======
        7) auto_updates ;;
        8) fail2ban_install ;;
        9) fail2ban_manual_config ;;
        # ====== FIREWALL ======
        10) firewall ;;
        # ====== APLICAÇÕES / SERVIÇOS ======
        11) apache_install_config ;;
        12) mariadb_install_config ;;
        13) php_install ;;
        14) hostname_server ;;
        15) certificado_ssl_certbot ;;
        # ====== WORDPRESS ======
        16) wordpress_pre_install ;;
        17) wordpress_install ;;
        # ====== MAILUTILS, POSIX E LOGWATCH ======
        18) mailutils_postfix_install ;;
        19) logwatch_install ;;
        # ====== PAINEIS DE ADMNISTRAÇÃO  ======
        20) webmin_install ;;
        21) virtualmin_install ;;
        22) cyberpanel_LiteSpeed_install ;;  
        ###
        E|e) echo; echo " Até à Próxima!"; echo; exit 0 ;;
        S|s) echo "
        Script para facilitar a configuração de uma VPS com
        sistema operativo Debian ou Ubuntu. Inclui configurações
        gerais, configurações de segurança, instalação e
        configuração do Apache e Wordpress, etc, através do
        terminal. Em alternativa sugere a  instalação de paineis
        administrativos de forma a que quase todo o processo de
        gestão do servidor possa ser feito por interface gráfica.
        GITHUB: https://github.com/ricjcs/vps-debian-ubuntu-config 
        AUTOR: Ricardo S.
        " ;;
        *) echo " OPS! Você não digitou corretamente." ;;
    esac
    pause
done
