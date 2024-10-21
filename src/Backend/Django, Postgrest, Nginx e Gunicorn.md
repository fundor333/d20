# Installazione dipendenze

Si assume che sia un progetto Django e che necessiti un db Postgresql. In oltre si assume che il progetto Django sia giá pronto per la messa sul server (settings, views, etc...).

Come prima cosa va aggiornato il sistema

``` bash
sudo apt-get update
sudo apt-get install nginx git
```

## Installazione Python

Indipendentemente alla versione di Python vanno installate **_N_** dipendenze

``` bash
sudo apt-get install python3-pip python-dev libpq-dev
```

Questo comando installa la versione di default di Python3. Bisogna fare l'installazione manuale per la versione di Python scelta. Si suggerisce di usare sempre la piú aggiornata e bisogna fare riferimento al sito ufficiale di Python per l'installazione

## Installazzione DB

Installazione dipendenze db

``` bash
sudo apt-get install postgresql postgresql-contrib
```

# Setting dei componenti

## Setting DB

Si inizia creando il DB. Per farlo bisogna prima entrare nel DB Server

``` bash
sudo -u postgres psql
```

Quindi si lanciano i comandi SQL di creazione

``` sql
CREATE DATABASE myproject;
CREATE USER myprojectuser WITH PASSWORD 'password';
ALTER ROLE myprojectuser SET client_encoding TO 'utf8';
ALTER ROLE myprojectuser SET default_transaction_isolation TO 'read committed';
ALTER ROLE myprojectuser SET timezone TO 'UTC';
GRANT ALL PRIVILEGES ON DATABASE myproject TO myprojectuser;
\q
```

## Setup del codice

Bisogna portare nel server il codice. Per farlo la prima scelta é **git** dal repo collegato.

``` bash
git clone <url_git_del_progetto>
cd <nome_del_progetto>
pipenv install
```

Il comando di **pipenv** produce una cartella con l'ambiente virtuale. Bisogna prendere nota del path della cartella.

Ora bisogna settare **GUnicorn**

``` bash
sudo nano /etc/systemd/system/gunicorn.service
```

E quindi inserire questi dati configurati secondo l'installazione corrente

``` toml
[Unit]
Description=gunicorn daemon
After=network.target

[Service]
User=developer
Group=www-data
WorkingDirectory=/home/developer/myproject
ExecStart=/home/developer/myproject/myprojectenv/bin/gunicorn --access-logfile - --workers 3 --bind unix:/home/developer/myproject/myproject.sock myproject.wsgi:application

[Install]
WantedBy=multi-user.target
```

Quindi bisogna abilitare il demone

``` bash
sudo systemctl start gunicorn
sudo systemctl enable gunicorn
```

Per controllare che funzioni bisogna vedere che ha creato il **sock**

``` bash
ls /home/developer/myproject
```

e dovrebbe tornare qualcosa tipo


``` bash
manage.py  myproject  myprojectenv  myproject.sock  static
```

che contiene il file **sock**

Con il seguente comando si riavvia il servizio


``` bash
sudo systemctl restart gunicorn
```

## Preparazione di Nginx per GUnicorn

Serve creare un file di config per Nginix


``` bash
sudo nano /etc/nginx/sites-available/myproject
```

E bisogna passare al file i config

``` nginx
server {
    listen 80;
    server_name server_domain_or_IP;

    location = /favicon.ico { access_log off; log_not_found off; }
    location /static/ {
        root /home/sammy/myproject;
    }

    location ~*.php$ {
        return 444;
    }

    ## Deny illegal Host headers

    if ($host !~* ^(server_domain_or_IP|www.server_domain_or_IP)$ ) {
        return 444;
    }

    location / {
        include proxy_params;
        proxy_pass http://unix:/home/sammy/myproject/myproject.sock;
    }
}
```

Quindi bisogna gestire le config. Viene fatto con un linking

``` bash
sudo ln -s /etc/nginx/sites-available/myproject /etc/nginx/sites-enabled
```

Quindi si controlla se tutto é ok

``` bash
sudo nginx -t
```

E se tutto ok si riavvia il servizio


``` bash
sudo systemctl restart nginx
```

## Lets Encrypt

Aggiungi dipendenze


``` bash
sudo add-apt-repository ppa:certbot/certbot
sudo apt install python-certbot-nginx
```

Gli dai i dominii di interessati


``` bash
sudo certbot --nginx -d example.com -d www.example.com
```

Qui ti fa scegliere delle config tra cui se avere il redirect automatico (consigliato) e il _no redirect_

Bisogna poi controllare che funzioni il rinnovo. Per farlo lancia


``` bash
sudo certbot renew --dry-run
```

E controlal che vada tutto bene

# Problemi, errori e aggiornamenti

## G-Unicorn

### Errore con GUnicorn che non parte

#### Problema

GUnicorn non parte correttamente

#### Soluzione

GUnicorn, se installato correttamente attraverso il **_Pipfile_** logga col comando


``` bash
sudo journalctl -u gunicorn
```

### Errore nel riavvio di GUnicorn

#### Problema

GUnicorn non parte correttamente al riavvio dopo modifiche

#### Soluzione

Va registrato il nuovo daemon


``` bash
sudo systemctl daemon-reload
sudo systemctl restart gunicorn
```
