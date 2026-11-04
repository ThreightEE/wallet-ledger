CREATE TABLE person (
    id       serial       PRIMARY KEY,
    email    varchar(255) NOT NULL,
    password varchar(255) NOT NULL,
    CONSTRAINT email_unique UNIQUE (email)
);

CREATE TABLE currency (
    id   serial       PRIMARY KEY,
    code varchar(3)   NOT NULL,
    name varchar(255) NOT NULL,
    CONSTRAINT code_unique UNIQUE (code)
);

CREATE TABLE wallet (
    id          serial        PRIMARY KEY,
    name        varchar(40)   NOT NULL,
    max_limit   decimal(10,2) NOT NULL,
    balance     decimal(10,2) DEFAULT 0,
    person_id   bigint        REFERENCES   person   (id) NOT NULL,
    currency_id bigint        REFERENCES   currency (id) NOT NULL,
    CONSTRAINT person_id_name_unique UNIQUE (person_id, name)
);

CREATE TABLE category (
    id         serial        PRIMARY KEY,
    name       varchar(40)   NOT NULL,
    type       varchar(7)    NOT NULL,
    person_id  bigint        REFERENCES   person (id),
    CONSTRAINT person_id_name_type_unique UNIQUE (person_id, name, type)
);

CREATE TABLE operation (
    id             serial        PRIMARY KEY,
    operation_dttm timestamp     NOT NULL,
    amount         decimal(10,2) NOT NULL,
    wallet_id      bigint        REFERENCES   wallet   (id) NOT NULL,
    category_id    bigint        REFERENCES   category (id) NOT NULL
);
