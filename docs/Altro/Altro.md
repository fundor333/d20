# Altre cose utili

## Setting per la data-ora fuso

``` bash
ENV DEBIAN_FRONTEND noninteractive
ENV TZ=Europe/Rome
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
```
