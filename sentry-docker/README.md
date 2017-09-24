# Sentry on Docker

This collection of shell scripts will attempt to install [Sentry](https://sentry.io/welcome/) on [Docker](https://www.docker.com/) on a [CentOS](https://www.centos.org/) machine (VM or bare metal).

The main script, `docker-sentry` will install `etcd`, `docker`, `sentry` and `nginx` reverse proxy with SSL support. The SSL certificates will be generated using the help of  https://github.com/JrCs/docker-letsencrypt-nginx-proxy-companion

Please keep in mind that in order to use SSL, you will need a DNS A, AAAA or CNAME record in your domain's zone file, otherwise SSL won't work. You can run it on port 80 but that's entirely not recommended.

The `sentry-exec` script will take care of "administrative tasks", such as stopping, starting, upgrading sentry components after installation. Please have a look at the help section for detailed info.

If this gets deployed on AWS EC2, use a machine with at least 2 GB of RAM. Same amount of RAM applies for bare metal

There are environment variables in the main script which need to be changed and set into etcd, according to your setup.

```
POSTGRES_PASSWORD supersecret
POSTGRES_USER sentry
SENTRY_SINGLE_ORGANIZATION False
SENTRY_SERVER_EMAIL sentry@example.com
SENTRY_EMAIL_HOST smtp.example.com
SENTRY_EMAIL_PASSWORD super-secret
SENTRY_EMAIL_USER mailuser
SENTRY_EMAIL_PORT 587
SENTRY_EMAIL_USE_TLS True
VIRTUAL_HOST sentry.example.com
LETSENCRYPT_HOST sentry.example.com
LETSENCRYPT_EMAIL example@example.com
```

Please refer to https://hub.docker.com/_/sentry/ and https://github.com/JrCs/docker-letsencrypt-nginx-proxy-companion for more information

### Backing up the database
`$ ./sentry_exec backup`

The sql file will be written to the container's folder `/var/lib/postgresql/data/pgdata/`
and to the host's folder defined in the env variable `/sentry/PG_DIR`

### Restoring a database

Restoring a database from a backup (for example from another sentry install):
1. Get the secret key from the other sentry install and add it to etcd `/sentry/SENTRY_SECRET_KEY`;
2. Create a sql backup of the database (from the other sentry installation);
3. Start your postgresql container then stop it (this will create the `${WORKDIR}/sentry/postgres` directory) and copy the backed up sql file there (i.e. `$ sudo cp backed-up-sentry.sql ${WORKDIR}/sentry/postgres/`);
4. Do not run `$ etcdctl set /sentry/SENTRY_SECRET_KEY $(docker run --rm sentry config generate-secret-key)`
since we already have it;
5. Start your postgresql container and then run below command
`$ docker exec -it postgres bash -c 'psql -U sentry sentry < /var/lib/postgresql/data/pgdata/backed-up-sentry.sql'`
Wait for it to finish;
6. Proceed upgrading the database with `$ ./sentry_exec upgrade`

### Removing old entries from the database

`$ ./sentry_exec cleanup`

This will clean all entries from all projects older than 60 days. This can be adjusted in the `sentry_exec` script.
Also it's possible to trim down entries based on projects https://docs.sentry.io/server/cli/cleanup/
