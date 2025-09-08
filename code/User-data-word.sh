#!/bin/bash
set -e   # Faz o script parar imediatamente se algum comando falhar

# Atualiza o sistema
sudo apt update -y && sudo apt upgrade -y 

# Instala Docker, Docker Compose, NFS (para montar EFS) e cliente MySQL
sudo apt install -y docker.io docker-compose nfs-common  mysql-client
sudo systemctl enable --now docker
sudo usermod -aG docker ubuntu
sudo chown -R ubuntu:ubuntu /home/ubuntu


# Cria o arquivo docker-compose.yml
cat <<EOF > /home/ubuntu/docker-compose.yml
version: '3.3'
services:
  wordpress:
    image: wordpress:latest
    ports:
      - "80:80"
    restart: always
    environment:
      WORDPRESS_DB_HOST: ${ENDERECO_DO_RDS:3306}
      WORDPRESS_DB_USER: ${USER_DO_BANCO_DE_DADOS}
      WORDPRESS_DB_PASSWORD: ${SENHA_DO_BANCO_DE_DADOS}
      WORDPRESS_DB_NAME: ${NAME_DO_BANCO_DE_DADOS}
      WORDPRESS_CONFIG_EXTRA: |
        define('WP_HOME', '${URL_DO_ALB}');
        define('WP_SITEURL', '${URL_DO_ALB}');

    volumes:
      - /var/www/html/wp-content:/var/www/html 


volumes:
  wordpress_data:

EOF

# Inicia os containers
sudo docker-compose -f /home/ubuntu/docker-compose.yml up -d

# Instala utilitários necessários para montar EFS via TLS
sudo apt install -y software-properties-common
sudo add-apt-repository universe
sudo apt update -y
sudo apt install -y amazon-efs-utils


# Cria ponto de montagem
sudo mkdir -p /efs

# Monta o EFS com TLS
sudo mount -t efs -o tls ${FS-ID}:/ /efs

# adiciona ao fstab para montar automaticamente no boot
echo "${FS-ID:/ /efs efs _netdev,tls 0 0}" | sudo tee -a /etc/fstab


# WORDPRESS_CONFIG_EXTRA: Config extra para o WordPress reconhecer o ALB como URL base