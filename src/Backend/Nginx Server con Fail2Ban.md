# Proteggere un server Nginx con Fail2Ban

## Introduzione

 Quando gli utenti falliscono ripetutamente l'autenticazione ad un servizio (o si impegnano in altre attività sospette), fail2ban può emettere divieti temporanei sull'indirizzo IP offensivo modificando dinamicamente il criterio del firewall in esecuzione. Ogni "jail" fail2ban funziona controllando i log scritti da un servizio per i pattern che indicano i tentativi falliti. Configurare fail2ban per monitorare i registri di Nginx è abbastanza semplice utilizzando alcuni dei filtri di configurazione inclusi e alcuni creati da noi.

## Installazione Nginx

Aggiorna l'indice locale dei pacchetti e installa digitando:

``` bash
sudo apt-get update
sudo apt-get install nginx
```

Controlla lo stato di Nginx digitando:

``` bash
systemctl status nginx
```

Se hai bisogno dell'IP utilizza:

``` bash
ip addr show eth0 | grep inet | awk '{ print $2; }' | sed 's/\/.*$//'
```

Se Nginx sta girando correttamente dovresti vedere la landing page:


## Comandi utili Nginx

Se li sai già a memoria puoi saltare tranquillamente questa parte.


Arresta servizio Nginx:

``` bash
sudo systemctl stop nginx
```

Avvia servizio Nginx:

``` bash
sudo systemctl start nginx
```

Riavvia servizio Nginx:

``` bash
sudo systemctl restart nginx
```

Ricarica settings senza drop connessioni (utile per cambi ai settings):

``` bash
sudo systemctl reload nginx
```

## Impostazioni dei Server Block

Anche questi passaggi fanno parte della configurazione standard di Nginx.
Se già li conosci salta questa parte


Per permettere a Nginx di servire i contenuti, è necessario creare un server block con le direttive corrette.
Invece di modificare direttamente il file di configurazione predefinito (`/etc/nginx/nginx.conf`), ne creiamo uno nuovo in /etc/nginx/sites-available/miosito.com:

``` 
server {
        listen 80;
        listen [::]:80;

        root /var/www/miosito.com/html;
        index index.html index.htm index.nginx-debian.html;

        server_name miosito.com www.miosito.com;

        location / {
                try_files $uri $uri/ =404;
        }
}
```

Abilitiamo il file creando un collegamento alla directory sites-enabled, che Nginx legge durante l'avvio:

``` bash
sudo ln -s /etc/nginx/sites-available/miosito.com /etc/nginx/sites-enabled/
```

## Intallazione Fail2Ban

Una volta che il tuo server Nginx è in esecuzione puoi procedere e installare Fail2Ban:

``` bash
sudo apt-get install fail2ban
```

## Settings generali Fail2Ban

Per iniziare, è necessario regolare il file di configurazione che Fail2Ban utilizza per determinare quali registri delle applicazioni monitorare e quali azioni intraprendere quando vengono trovate voci offensive.
Il file fornito di default è `/etc/fail2ban/jail.conf`, ma potrebbe venire sovrascritto in caso di aggiornamento del pacchetto.
Per fare modifiche, è necessario copiarlo in `/etc/fail2ban/jail.local`:

``` bash
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
```

Apri il file appena copiato in modo da poter impostare il monitoraggio del registro Nginx:

``` bash
sudo nano /etc/fail2ban/jail.local
```

Se lo desidera si può aggiungere una lista IP che non verranno soggetti alle policy di Fail2Ban, grazie alla direttiva `ignoreip`.
Può essere utile ad es. per escludere l'IP dell'ufficioo di casa:

``` toml
[DEFAULT]

. . .
ignoreip = 127.0.0.1/8 IP_di_casa IP_di_ufficio
```

Se si vuole si può configurare un `bantime` diverso da quello di default.
Il bantime è un intero espresso in secondi, il valore di default è 600 (10 minuti).

``` toml
[DEFAULT]

. . .
bantime = 3600
```

I due item successivi determinano l'ambito delle righe di registro utilizzate per determinare un client malvagio.
Nello specifico individuano il momento in cui un determinato numero (direttiva `maxretry`) di tentativi viene rilevato all'interno di una particolare finestra temporale (`findtime`). Il findtime è anch'esso un intero espresso in secondi.

```
[DEFAULT]

. . .
findtime = 3600   # These lines combine to ban clients that fail
maxretry = 6      # to authenticate 6 times within a half hour.
```

## Configurazione di Fail2Ban per monitoraggio log Nginx

### Introduzione

Di default l'unico jail abilitato è quello `[ssh]`.
I cosiddetti _jail_ all'interno di `/etc/fail2ban/jail.local` si presentano così:

``` toml
[nome-del-jail]

enabled  = false # Disabilitato di default
filter   = nome-del-filter # Uguale al nome del jail, deve esistere un file omonimo nel path /etc/fail2ban/filter.d/
port    = http,https
logpath = %(nginx_access_log)s # Path log da monitorare. Alternativa: %(nginx_error_log)s
```

La logica utilizzata dai _jail_ viene definita nei _filter_ in `/etc/fail2ban/filter.d/`.
Per semplicità i filter vengono denominati come i jail.
I _filter_ si presentano così:

``` toml
[Definition]

failregex = ^<HOST> -.*METHOD.*REGEX

ignoreregex =
```

dove `failregex` indica il pattern da controllare nel file di log definito nel jail e `ignoreregex` i pattern da ignorare.

### Configurazione Jail specifici per Nginx

#### Jail - Nginx Http Auth

Per abilitare il monitoraggio dei tentativi di login cerca il jail `[nginx-http-auth]`.
È l'unico jail specifico per Nginx incluso nel package Fail2Ban per Debian/Ubuntu.
Impostare quindi `enabled  = true` per abilitarlo.

#### Jail - Nginx No Script

Per bloccare client che cercano script per eseguirli o sfruttare un exploit creiamo un jail `[nginx-noscript]`:

``` toml
[nginx-noscript]

enabled  = true
port     = http,https
filter   = nginx-noscript
logpath  = %(nginx_access_log)s
maxretry = 6
```

#### Jail - Nginx Bot Search e Bad Bot

Per bloccare le richieste provenienti da mailicious bot conosciuti, creare `[nginx-botsearch]` e `[nginx-badbots]`:

``` toml
[nginx-botsearch]

enabled  = true
filter   = nginx-botsearch
port     = http,https
logpath  = %(nginx_access_log)s
maxretry = 2

[nginx-badbots]

enabled  = true
port     = http,https
filter   = nginx-badbots
logpath  = %(nginx_access_log)s
maxretry = 2
```

#### Jail - Nginx No Home

Per bloccare le richieste ai contenuti web nella home directory, creare un `[nginx-nohome]`:

``` toml
[nginx-nohome]

enabled  = true
port     = http,https
filter   = nginx-nohome
logpath  = %(nginx_access_log)s
maxretry = 2
```

#### Jail - Nginx No Proxy

Per bloccare client che cercano di usare il nostro Nginx come open proxy, creare un `[nginx-noproxy`:

``` toml
[nginx-noproxy]

enabled  = true
port     = http,https
filter   = nginx-noproxy
logpath  = %(nginx_access_log)s
maxretry = 2
```

### Configurazione filter dei jail abilitati

#### Filter - Nginx Http Auth

Editare `/etc/fail2ban/filter.d/nginx-http-auth.conf`:

``` toml
[Definition]


failregex = ^ \[error\] \d+#\d+: \*\d+ user "\S+":? (password mismatch|was not found in ".*"), client: <HOST>, server: \S+, request: "\S+ \S+ HTTP/\d+\.\d+", host: "\S+"\s*$
            ^ \[error\] \d+#\d+: \*\d+ no user/password was provided for basic authentication, client: <HOST>, server: \S+, request: "\S+ \S+ HTTP/\d+\.\d+", host: "\S+"\s*$ # Aggiungere questa riga per avere un match sugli utenti che non hanno inserito username e password

ignoreregex =
```

#### Filter - Nginx Bad Bots

Copiare `apache-badbots.conf` come `nginx-badbots.conf`:

``` bash
sudo cp /etc/fail2ban/filter.d/apache-badbots.conf /etc/fail2ban/filter.d/nginx-badbots.conf
```

#### Filter - Nginx Bot Search

Creare nuovo file:

``` bash
sudo nano /etc/fail2ban/filter.d/nginx-botsearch.conf
```

Nel file copiare:

``` toml
# Fail2Ban filter to match web requests for selected URLs that don't exist
#

[INCLUDES]

# Load regexes for filtering
before = botsearch-common.conf

[Definition]

failregex = ^<HOST> \- \S+ \[\] \"(GET|POST|HEAD) \/<block> \S+\" 404 .+$
            ^ \[error\] \d+#\d+: \*\d+ (\S+ )?\"\S+\" (failed|is not found) \(2\: No such file or directory\), client\: <HOST>\, server\: \S*\, request: \"(GET|POST|HEAD) \/<block> \S+\"\, .*?$

ignoreregex =


# DEV Notes:
# Based on apache-botsearch filter
#
# Author: Frantisek Sumsal
```

#### Filter - Nginx No Script

Creare nuovo file:

``` bash
sudo nano nginx-noscript.conf
```

Nel file copiare:

``` toml
[Definition]

failregex = ^<HOST> -.*GET.*(\.php|\.asp|\.exe|\.pl|\.cgi|\.scgi)

ignoreregex =
```

#### Filter - Nginx No Home

Creare nuovo file:

``` bash
sudo nano nginx-nohome.conf
```

Nel file copiare:

``` toml
[Definition]

failregex = ^<HOST> -.*GET .*/~.*

ignoreregex =
```

#### Filter - Nginx No Proxy

Creare nuovo file:

``` bash
sudo nano nginx-noproxy.conf
```

Nel file copiare:

``` toml
[Definition]

failregex = ^<HOST> -.*GET http.*

ignoreregex =
```

## Attivazione delle Jail Nginx

Riavvia il servizio di Fail2Ban:

``` bash
sudo service fail2ban restart
```

## Ottenere info su stato Jail

``` bash
sudo fail2ban-client status
```
