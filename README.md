# iwilltry42/nextcloud

## Thanks

Thanks to [@wonderfall](https://github.com/wonderfall) who created the original project [wonderfall/docker-nextcloud](https://github.com/wonderfall/nextcloud).
I'm using the same `Dockerfile`, so you can choose to pull either from [wonderfall/nextcloud](https://hub.docker.com/r/wonderfall/nextcloud) or from [iwilltry42/nextcloud](https://hub.docker.com/r/iwilltry42/nextcloud).

## Features

- Based on Alpine Linux.
- Bundled with nginx and PHP 7.x ([wonderfall/nginx-php](https://hub.docker.com/rwonderfall/nginx-php) image).
- Automatic installation using environment variables.
- Package integrity (SHA512) and authenticity (PGP) checked during building process.
- Data and apps persistence.
- OPCache (opcocde), APCu (local) installed and configured.
- system cron task running.
- MySQL, PostgreSQL (server not built-in) and sqlite3 support.
- Redis, FTP, SMB, LDAP, IMAP support.
- GNU Libiconv for php iconv extension (avoiding errors with some apps).
- No root processes. Never.
- Environment variables provided (see below).

### Tags

- **latest** : latest stable version.
- **20.0** : latest 20.0.x version (stable, recommended)
- **19.0** : latest 19.0.x version (old stable)

Since this project should suit my needs, I'll only maintain the latest stable version available.

## Build-time variables

- **NEXTCLOUD_VERSION** : version of nextcloud
- **GPG_nextcloud** : signing key fingerprint

## Environment variables

- **UID** : nextcloud user id *(default : 991)*
- **GID** : nextcloud group id *(default : 991)*
- **UPLOAD_MAX_SIZE** : maximum upload size *(default : 10G)*
- **APC_SHM_SIZE** : apc memory size *(default : 128M)*
- **OPCACHE_MEM_SIZE** : opcache memory size in megabytes *(default : 128)*
- **MEMORY_LIMIT** : php memory limit *(default : 512M)*
- **CRON_PERIOD** : time interval between two cron tasks *(default : 15m)*
- **CRON_MEMORY_LIMIT** : memory limit for PHP when executing cronjobs *(default : 1024m)*
- **TZ** : the system/log timezone *(default : Etc/UTC)*
- **ADMIN_USER** : username of the admin account *(default : none, web configuration)*
- **ADMIN_PASSWORD** : password of the admin account *(default : none, web configuration)*
- **DOMAIN** : domain to use during the setup *(default : localhost)*
- **DB_TYPE** : database type (sqlite3, mysql or pgsql) *(default : sqlite3)*
- **DB_NAME** : name of database *(default : none)*
- **DB_USER** : username for database *(default : none)*
- **DB_PASSWORD** : password for database user *(default : none)*
- **DB_HOST** : database host *(default : none)*

Don't forget to use a **strong password** for the admin account!

## Port

- **8888** : HTTP Nextcloud port.

## Volumes

- **/data** : Nextcloud data.
- **/config** : config.php location.
- **/apps2** : Nextcloud downloaded apps.
- **/nextcloud/themes** : Nextcloud themes location.
- **/php/session** : php session files.

## Database

Basically, you can use a database instance running on the host or any other machine. An easier solution is to use an external database container. I suggest you to use Postgres, which is a reliable database server. You can use the official `postgres` image available on Docker Hub to create a database container, which must be linked to the Nextcloud container. MariaDB can also be used as well.

## Setup

Pull the image and create a container. `/docker` can be anywhere on your host, this is just an example. Change `POSTGRES_PASSWORD` values (postgres). You may also want to change UID and GID for Nextcloud, as well as other variables (see *Environment Variables*).

```shell
docker pull iwilltry42/nextcloud:16 && docker pull postgres:11

docker run -d --name nextcloud_postgres \
       -v /docker/nextcloud/db:/var/lib/postgresql/data \
       -e POSTGRES_DB=nextcloud \
       -e POSTGRES_USERNAME=nextcloud \
       -e POSTGRES_PASSWORD=supersecretpassword \
       postgres:11

docker run -d --name nextcloud \
       --link nextcloud_postgres:db \
       -v /docker/nextcloud/data:/data \
       -v /docker/nextcloud/config:/config \
       -v /docker/nextcloud/apps:/apps2 \
       -v /docker/nextcloud/themes:/nextcloud/themes \
       -e UID=1000 \
       -e GID=1000 \
       -e UPLOAD_MAX_SIZE=10G \
       -e APC_SHM_SIZE=128M \
       -e OPCACHE_MEM_SIZE=128 \
       -e CRON_PERIOD=15m \
       -e TZ=Etc/UTC \
       -e ADMIN_USER=mrrobot \
       -e ADMIN_PASSWORD=supercomplicatedpassword \
       -e DOMAIN=cloud.example.com \
       -e DB_TYPE=mysql \
       -e DB_NAME=nextcloud \
       -e DB_USER=nextcloud \
       -e DB_PASSWORD=supersecretpassword \
       -e DB_HOST=db_nextcloud \
       iwilltry42/nextcloud:18.0.3
```

You are **not obliged** to use `ADMIN_USER` and `ADMIN_PASSWORD`. If these variables are not provided, you'll be able to configure your admin acccount from your browser.

**Below you can find a docker-compose file, which is very useful!**

Now you have to use a **reverse proxy** in order to access to your container through Internet, steps and details are available at the end of the README.md. And that's it! Since you already configured Nextcloud through setting environment variables, there's no setup page.

## ARM-based devices

You will have to build yourself using an Alpine-ARM image, like `orax/alpine-armhf:edge`.

## Configure

In the admin panel, you should switch from `AJAX cron` to `cron` (system cron).

## Update

Pull a newer image, then recreate the container as you did before (*Setup* step). None of your data will be lost since you're using external volumes.

## docker-compose

I advise you to use [docker-compose](https://docs.docker.com/compose/), which is a great tool for managing containers. You can create a `docker-compose.yml` with the following content (which must be adapted to your needs) and then run `docker-compose up -d nextcloud_postgres`, wait some 15 seconds for the database to come up, then run everything with `docker-compose up -d`, that's it!
On subsequent runs, a single `docker-compose up -d` is sufficient!

### docker-compose file

You can grab a [docker-compose.yml from here](./docker-compose.yml) which boots up Nextcloud, Redis and PostgreSQL.
Don't copy/paste without thinking! It is a model so you can see how to do it correctly.
You can update everything with `docker-compose pull` followed by `docker-compose up -d`.

## How to configure Redis

Redis can be used for distributed and file locking cache, alongside with APCu (local cache), thus making Nextcloud even more faster. As PHP redis extension is already included, all you have to is to deploy a redis server (you can do as above with docker-compose) and bind it to nextcloud in your config.php file :

```conf
'memcache.distributed' => '\OC\Memcache\Redis',
'memcache.locking' => '\OC\Memcache\Redis',
'memcache.local' => '\OC\Memcache\APCu',
'redis' => array(
   'host' => 'redis',
   'port' => 6379,
   ),
```

## Tip : how to use occ command

There is a script for that, so you shouldn't bother to log into the container, set the right permissions, and so on. Just use `docker exec -ti nexcloud occ command`.

## Reverse proxy

Of course you can use your own software! nginx, Haproxy, Caddy, h2o, [Traefik](https://traefik.io/)...

Whatever your choice is, you have to know that headers are already sent by the container, including HSTS, so there's no need to add them again. **It is strongly recommended (I'd like to say : MANDATORY) to use Nextcloud through an encrypted connection (HTTPS).** [Let's Encrypt](https://letsencrypt.org/) provides free SSL/TLS certificates, so you have no excuses.
