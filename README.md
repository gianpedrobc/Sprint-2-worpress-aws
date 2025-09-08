# WordPress Escalável na AWS
![Logo AWS](https://a0.awsstatic.com/libra-css/images/logos/aws_logo_smile_1200x630.png)


Este projeto provisiona uma infraestrutura **robusta e escalável** para hospedar WordPress **containerizado** na AWS ", utilizando "**Infraestrutura como Código (IaC)** com Terraform" e scripts de User Data."

A arquitetura utiliza **Auto Scaling Group**, **Application Load Balancer**, **Amazon EFS** e **RDS**, garantindo alta disponibilidade e performance para ambientes de produção.

---

## 🌐 Diagrama da Arquitetura

![Diagrama da Arquitetura](documents/worpress.drawio)


### ⚙️ Camadas Principais

1. **Rede (VPC Layer)**
   - VPC personalizada com 2 subnets públicas (ALB) e 4 privadas (EC2/RDS)
   - Internet Gateway (IGW) e NAT Gateway
   - Route Tables configuradas para roteamento correto

2. **Camada de Aplicação (Compute Layer)**
   - EC2 em Auto Scaling Group com Launch Template
   - Script User Data: instala WordPress, monta EFS e conecta ao RDS
   - Associado a Application Load Balancer (ALB) com Health Check

3. **Camada de Armazenamento**
   - Amazon EFS montado em todas as instâncias EC2
   - Armazena uploads, plugins e temas do WordPress

4. **Banco de Dados**
   - Amazon RDS Multi-AZ (MySQL ou MariaDB)
   - Acesso restrito apenas às instâncias EC2
   - Backup automático e failover

---

## 📑 tabela de serviços 

| Categoria      | Serviço AWS                              | Função                                          |
| -------------- | ---------------------------------------- | ----------------------------------------------- |
| Rede           | VPC, Subnets, IGW, NAT Gateway           | Isolamento e roteamento seguro                  |
| Computação     | EC2, Auto Scaling Group, Launch Template | Escalabilidade automática da aplicação          |
| Balanceamento  | Application Load Balancer                | Distribuição de tráfego e health checks         |
| Armazenamento  | Amazon EFS                               | Persistência de arquivos compartilhados         |
| Banco de Dados | RDS Multi-AZ (MySQL/MariaDB)             | Persistência confiável com alta disponibilidade |
| Segurança      | Security Groups                          | Controle de acesso às instâncias e banco        |

---

## 🔧 trevho do User data 
```
set -e 

sudo apt update -y && sudo apt upgrade -y 

sudo apt install -y docker.io docker-compose nfs-common  mysql-client
sudo systemctl enable --now docker
sudo usermod -aG docker ubuntu
sudo chown -R ubuntu:ubuntu /home/ubuntu

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

```


## monitoramento 
