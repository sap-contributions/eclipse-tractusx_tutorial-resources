# Tractus-X Backend Service

## API Details Summary

Backend Service is used to validate the transfer. It has the following APIs.

- [Contents API](#contents-api)
- [Transfer API](#transfer-api)

## Contents API

### Store an Asset

- Method : POST
- URL : http://localhost/backend-service/api/v1/contents
- Request Body:

```json
{
  "userId": 1,
  "id": 1,
  "title": "delectus aut autem",
  "completed": false
}
```

- Response

```json
{
  "id": "3b777103-5e06-461b-90c6-1f99e597f60d",
  "url": "http://localhost:9000/api/v1/contents/3b777103-5e06-461b-90c6-1f99e597f60d"
}
```

### Fetch an Asset

- Method : GET
- URL : http://localhost/backend-service/api/v1/contents/{id}
- Response

```json
{
  "userId": 1,
  "id": 1,
  "title": "delectus aut autem",
  "completed": false
}
```

This URL will be used as a DataAddress in the assets API.

### Fetch All Assets

- Method : GET
- URL : http://localhost/backend-service/api/v1/contents
- Response

```json
[
  {
    "userId": 1,
    "id": 1,
    "title": "delectus aut autem",
    "completed": false
  },
  {
    "userId": 1,
    "id": 2,
    "title": "quis ut nam facilis et officia qui",
    "completed": false
  }
]
```

### Generate a random content

- Method : GET
- URL : http://localhost/backend-service/api/v1/contents/random
- Response

```json
{
  "userId": 894688136,
  "title": "fijp",
  "text": "wvfaauux"
}
```

## Transfer API

### Accept the transfer data from the connector

Connector will push something similar to this:
```json
{
  "id": "123456789011",
  "endpoint": "http://alice-tractusx-connector-dataplane:8081/api/public",
  "authKey": "Authorization",
  "authCode": "<Auth Code>",
  "properties": {}
}
```

- Method : POST
- URL : http://localhost/backend-service/api/v1/transfers
- Request/ Response

```json
{
  "id": "123456789011",
  "endpoint": "http://alice-tractusx-connector-dataplane:8081/api/public",
  "authKey": "Authorization",
  "authCode": "100000",
  "properties": {}
}
```

### Get transfer data with ID

- Method : GET
- URL : http://localhost/backend-service/api/v1/transfers/{id}
- Response

```json
{
  "id": "123456789011",
  "endpoint": "http://alice-tractusx-connector-dataplane:8081/api/public",
  "authKey": "Authorization",
  "authCode": "100000",
  "properties": {}
}
```

### Get Actual Asset Content
Get the data which is stored at the above endpoint http://alice-tractusx-connector-dataplane:8081/api/public
- Method : GET
- URL : http://localhost/backend-service/api/v1/transfers/{id}/contents
- Response

```json
{
  "userId": 123456789011,
  "id": 6,
  "title": "qui ullam ratione quibusdam voluptatem quia omnis",
  "completed": false
}
```


## Database Schema

### following Schema is used for contents

```shell
CREATE TABLE IF NOT EXISTS content
(
    id          text,
    asset       text,
    createddate timestamp(6) DEFAULT CURRENT_TIMESTAMP,
    updateddate timestamp(6) DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT content_pkey PRIMARY KEY (id)
);
```

### following Schema is used for transfer

```shell
CREATE TABLE IF NOT EXISTS transfer
(
    transferid  text,
    asset       text,
    contents    text,
    createddate timestamp(6) DEFAULT CURRENT_TIMESTAMP,
    updateddate timestamp(6) DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT transfer_pkey PRIMARY KEY (transferid)
);
```