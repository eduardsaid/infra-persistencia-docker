# Infraestrutura de Persistência com Docker

Tudo foi feito com o SSH pelo meu Windows 11 ""ssh eduardo248648@192.168.15.54"" na VM com Ubuntu Server

## CENÁRIO 1 — Persistência de Dados com MySQL e Named Volume

Neste cenário, foi criado um volume nomeado para garantir o ciclo de vida dos dados de forma independente do contêiner do banco de dados MySQL 8.0.

### Comandos Utilizados:
sudo docker volume create mysql-prod-data

sudo docker run -d --name mysql-container -v mysql-prod-data:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=senha_secreta mysql:8.0
sudo docker exec -it mysql-container mysql -u root -p

### Explicação Técnica:
O banco de dados foi acessado e a tabela de usuários foi populada com três registros. Para validar a persistência, o contêiner original foi removido forçadamente através do comando docker rm -f. Em seguida, um novo contêiner foi iniciado utilizando exatamente o mesmo volume nomeado (mysql-prod-data). A validação final via query de SELECT comprovou que os dados inseridos anteriormente permaneceram intactos, demonstrando que o ciclo de vida dos dados está totalmente desacoplado do ciclo de vida do contêiner.

## CENÁRIO 2 — Backup e Restauração de Volume

Simulação de plano de recuperação de desastres (Disaster Recovery) através da extração física e lógica dos dados persistidos.

### Comandos Utilizados (Backup):
sudo docker exec -i mysql-container-novo mysqldump -u root -psenha_secreta producao > scripts/mysql-init.sql
sudo docker run --rm -v mysql-prod-data:/volume -v $(pwd)/backups:/backup ubuntu tar cvf /backup/backup-mysql.tar.gz -C /volume .

### Comandos Utilizados (Restauração):
sudo docker rm -f mysql-container-novo
sudo docker volume rm mysql-prod-data
sudo docker volume create mysql-prod-data
sudo docker run --rm -v mysql-prod-data:/volume -v $(pwd)/backups:/backup ubuntu tar xvf /backup/backup-mysql.tar.gz -C /volume

### Validação:
Após a destruição completa do volume original e reconstrução através do desempacotamento do arquivo .tar.gz, a integridade estrutural e os registros do banco foram restabelecidos com sucesso no novo contêiner.

## CENÁRIO 3 — Bind Mount e Desenvolvimento

Utilização de Bind Mount para vincular um diretório do sistema operacional hospedeiro (Host) ao sistema de arquivos interno de um servidor web Nginx, técnica amplamente utilizada em ambientes de desenvolvimento local.

### Comandos Utilizados:
mkdir -p dev-site
echo "Atividade de Persistencia - Eduardo Dias" > dev-site/index.html
sudo docker run -d --name servidor-dev -v $(pwd)/dev-site:/usr/share/nginx/html -p 8080:80 nginx:alpine
curl http://localhost:8080

### Diferença Técnica (Host vs Container):
Enquanto os volumes nomeados são gerenciados pelo próprio Docker Engine dentro de uma área restrita (/var/lib/docker/volumes/), o Bind Mount aponta diretamente para qualquer caminho escolhido no Host. Isso permite que alterações feitas nos arquivos locais da máquina física reflitam instantaneamente dentro do contêiner em tempo real, eliminando a necessidade de rebuilds frequentes da imagem durante a codificação.

## CENÁRIO 4 — Compartilhamento de Dados Entre Containers

Implementação de arquitetura baseada em compartilhamento de volumes, onde múltiplos contêineres acessam concorrentemente a mesma área de armazenamento estável.

### Comandos Utilizados:
sudo docker volume create volume-compartilhado
sudo docker run -d --name container-produtor -v volume-compartilhado:/app/dados alpine sh -c 'while true; do echo "Log gerado por Eduardo Dias em $(date)" >> /app/dados/output.log; sleep 5; done'
sudo docker run --rm -v volume-compartilhado:/dados alpine tail -n 5 /dados/output.log

### Análise Técnica:
O comportamento valida de forma prática o desacoplamento de serviços e a concorrência de leitura e escrita. Um contêiner focado exclusivamente em escrita (Produtor) alimenta dados continuamente no volume isolado, permitindo que contêineres efêmeros ou de monitoramento (Consumidores) realizem a leitura paralela do mesmo arquivo de log sem bloqueios.

## CENÁRIO 5 — Automação de Backup

Criação de rotina automatizada em Shell Script para empacotamento cíclico de ativos estruturados persistidos em volumes Docker.

### Execução do Script (scripts/backup.sh):
chmod +x scripts/backup.sh
./scripts/backup.sh
ls -lh backups/

### Resultado Esperado:
O script extrai de forma automatizada o estado atual do volume indicado, gera arquivos compactados no formato .tar.gz identificados pela data e hora exatas da execução e armazena os pacotes de segurança de forma organizada no diretório de destino.
