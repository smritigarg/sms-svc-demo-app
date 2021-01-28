# App

## Run

```
docker-compose up
```

## Schema Import

Exec into Postgresql container

```
docker exec -it atc-ror-app_postgres_1 bash
```

> Container name may differ

Create database

```
psql -U postgres
CREATE DATABASE  msvc
```

Import schema

```
psql -U postgres msvc < /tmp/schema.sql
```

## Test

```
curl -XPOST -H 'Content-Type: application/json' -d '{"from":"959595","to":"959595","text":3}' http://localhost:3000/inbound/sms
```
