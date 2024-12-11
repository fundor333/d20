# Costruire un server FTP

Piccola guida per la creazione e configurazione di un server FTP

## Installazione

Per il server useremo __vsftpd__

``` bash
sudo apt update
sudo apt install vsftpd
```

Fatto questo controlliamo per vedere se è in funzione

``` bash
sudo systemctl status vsftpd
```

Se non funziona vai alla sezione [Problemi](#problemi)

Bisogna anche lanciare il comando per fare il modo che venga lanciato all avvio

``` bash
sudo systemctl enable vsftpd
```

## Creare utente FTP

Va creato un utente FTP per accesso al server e per gestire i file del server FTP

``` bash
sudo adduser ftpuser
```

E va aggiunto all'elenco di utenti che possono usare i comandi FTP sul server

``` bash
echo "ftpuser" | sudo tee -a  /etc/vsftpd.userlist
```

## Creazione e configurazione cartella FTP

Bisogna creare una cartella come destinazione FTP settando correttamente i permessi per la cartella e tutta la parte "sotto"

``` bash
sudo mkdir -p /home/ftpuser/ftp_dir/upload
sudo chmod 550 /home/ftpuser/ftp_dir
sudo chmod -R 750 /home/ftpuser/ftp_dir/upload
sudo chown -R ftpuser: /home/ftpuser/ftp_dir
```

## Configurare VSFtpD

Per configurare il demone e il server annesso bisogna editare il file __/etc/vsftpd.conf__

``` bash
sudo nano /etc/vsftpd.conf
```

Inizia rimuovendo il permesso di accesso anonimo

``` bash
anonymous_enable=NO
local_enable=YES
```

Vanno abilitati gli accessi alla home e di scrittura

``` bash
write_enable=YES
chroot_local_user=YES
allow_writeable_chroot=YES
```

E quindi limitare a solo gli utenti aiblitati

``` bash
userlist_enable=YES
userlist_file=/etc/vsftpd.userlist
userlist_deny=NO
```

Fatta tutta la configurazione va riavviato il server e verificato che sia tornato su correttamente

``` bash
sudo systemctl restart vsftpd
sudo systemctl status vsftpd
```

## Problemi

### VSFtpD risulta offline

Lancia il seguente comanda

``` bash
sudo systemctl start vsftpd
```
