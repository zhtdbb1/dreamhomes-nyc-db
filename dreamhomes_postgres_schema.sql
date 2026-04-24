-- Dream Homes NYC - PostgreSQL schema
-- Based on the final listing-centered ownership schema.
-- Notes:
--   Table name changed to transactions to avoid the SQL keyword TRANSACTION.
--   This script assumes PostgreSQL.

BEGIN;

DROP TABLE IF EXISTS transaction_client_role;
DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS open_house_attendance;
DROP TABLE IF EXISTS open_house;
DROP TABLE IF EXISTS appointment;
DROP TABLE IF EXISTS client_inquiry;
DROP TABLE IF EXISTS listing_ownership;
DROP TABLE IF EXISTS listing;
DROP TABLE IF EXISTS property;
DROP TABLE IF EXISTS school;
DROP TABLE IF EXISTS neighborhood;
DROP TABLE IF EXISTS client_preference;
DROP TABLE IF EXISTS client;
DROP TABLE IF EXISTS agent;
DROP TABLE IF EXISTS employee;
DROP TABLE IF EXISTS office;

CREATE TABLE office (
    office_id       INTEGER PRIMARY KEY,
    office_name     VARCHAR(150) NOT NULL,
    street_address  VARCHAR(200) NOT NULL,
    city            VARCHAR(100) NOT NULL,
    state           VARCHAR(2) NOT NULL,
    zip_code        VARCHAR(10) NOT NULL,
    phone           VARCHAR(20) NOT NULL
);

CREATE TABLE employee (
    employee_id         INTEGER PRIMARY KEY,
    office_id           INTEGER NOT NULL REFERENCES office(office_id),
    first_name          VARCHAR(100) NOT NULL,
    last_name           VARCHAR(100) NOT NULL,
    email               VARCHAR(255) NOT NULL UNIQUE,
    phone               VARCHAR(20) NOT NULL,
    employment_type     VARCHAR(20) NOT NULL CHECK (employment_type IN ('full-time', 'part-time')),
    job_title           VARCHAR(100) NOT NULL,
    hire_date           DATE NOT NULL,
    employment_status   VARCHAR(50) NOT NULL
);

CREATE TABLE agent (
    employee_id      INTEGER PRIMARY KEY REFERENCES employee(employee_id),
    license_number   VARCHAR(50) NOT NULL UNIQUE,
    commission_rate  NUMERIC(5,4) NOT NULL,
    specialization   VARCHAR(100) NOT NULL
);

CREATE TABLE client (
    client_id                  INTEGER PRIMARY KEY,
    first_name                 VARCHAR(100) NOT NULL,
    last_name                  VARCHAR(100) NOT NULL,
    email                      VARCHAR(255) NOT NULL,
    phone                      VARCHAR(20) NOT NULL,
    preferred_contact_method   VARCHAR(20) NOT NULL,
    created_at                 DATE NOT NULL
);

CREATE TABLE client_preference (
    client_id            INTEGER PRIMARY KEY REFERENCES client(client_id),
    preferred_location   VARCHAR(100) NOT NULL,
    property_type        VARCHAR(50) NOT NULL,
    min_budget           NUMERIC(12,2) NOT NULL,
    max_budget           NUMERIC(12,2) NOT NULL,
    min_bedrooms         INTEGER NOT NULL,
    max_bedrooms         INTEGER NOT NULL,
    min_bathrooms        INTEGER NOT NULL,
    min_square_feet      INTEGER NOT NULL
);

CREATE TABLE neighborhood (
    neighborhood_id    INTEGER PRIMARY KEY,
    neighborhood_name  VARCHAR(100) NOT NULL,
    borough_or_city    VARCHAR(100) NOT NULL,
    state              VARCHAR(2) NOT NULL
);

CREATE TABLE school (
    school_id         INTEGER PRIMARY KEY,
    neighborhood_id   INTEGER NOT NULL REFERENCES neighborhood(neighborhood_id),
    school_name       VARCHAR(200) NOT NULL,
    school_type       VARCHAR(50) NOT NULL,
    rating            INTEGER NOT NULL,
    address           VARCHAR(250) NOT NULL
);

CREATE TABLE property (
    property_id       INTEGER PRIMARY KEY,
    neighborhood_id   INTEGER NOT NULL REFERENCES neighborhood(neighborhood_id),
    street_address    VARCHAR(200) NOT NULL,
    city              VARCHAR(100) NOT NULL,
    state             VARCHAR(2) NOT NULL,
    zip_code          VARCHAR(10) NOT NULL,
    property_type     VARCHAR(50) NOT NULL,
    square_feet       INTEGER NOT NULL,
    bedrooms          INTEGER NOT NULL,
    bathrooms         INTEGER NOT NULL,
    year_built        INTEGER NOT NULL
);

CREATE TABLE listing (
    listing_id          INTEGER PRIMARY KEY,
    property_id         INTEGER NOT NULL REFERENCES property(property_id),
    agent_employee_id   INTEGER NOT NULL REFERENCES agent(employee_id),
    listing_type        VARCHAR(10) NOT NULL CHECK (listing_type IN ('sale', 'rent')),
    listing_price       NUMERIC(12,2) NOT NULL,
    listing_status      VARCHAR(20) NOT NULL CHECK (listing_status IN ('active', 'pending', 'closed', 'cancelled')),
    list_date           DATE NOT NULL,
    end_date            DATE
);

CREATE TABLE listing_ownership (
    listing_id   INTEGER NOT NULL REFERENCES listing(listing_id),
    client_id    INTEGER NOT NULL REFERENCES client(client_id),
    role_type    VARCHAR(20) NOT NULL CHECK (role_type IN ('owner', 'landlord')),
    PRIMARY KEY (listing_id, client_id)
);

CREATE TABLE client_inquiry (
    inquiry_id        INTEGER PRIMARY KEY,
    client_id         INTEGER NOT NULL REFERENCES client(client_id),
    listing_id        INTEGER NOT NULL REFERENCES listing(listing_id),
    inquiry_date      DATE NOT NULL,
    inquiry_channel   VARCHAR(50) NOT NULL,
    inquiry_status    VARCHAR(50) NOT NULL
);

CREATE TABLE appointment (
    appointment_id         INTEGER PRIMARY KEY,
    listing_id             INTEGER NOT NULL REFERENCES listing(listing_id),
    client_id              INTEGER NOT NULL REFERENCES client(client_id),
    agent_employee_id      INTEGER NOT NULL REFERENCES agent(employee_id),
    appointment_datetime   TIMESTAMP NOT NULL,
    appointment_type       VARCHAR(50) NOT NULL,
    outcome                VARCHAR(50) NOT NULL
);

CREATE TABLE open_house (
    open_house_id        INTEGER PRIMARY KEY,
    listing_id           INTEGER NOT NULL REFERENCES listing(listing_id),
    agent_employee_id    INTEGER NOT NULL REFERENCES agent(employee_id),
    start_datetime       TIMESTAMP NOT NULL,
    end_datetime         TIMESTAMP NOT NULL
);

CREATE TABLE open_house_attendance (
    open_house_id     INTEGER NOT NULL REFERENCES open_house(open_house_id),
    client_id         INTEGER NOT NULL REFERENCES client(client_id),
    attended_flag     BOOLEAN NOT NULL,
    interest_level    VARCHAR(20) NOT NULL,
    PRIMARY KEY (open_house_id, client_id)
);

CREATE TABLE transactions (
    transaction_id        INTEGER PRIMARY KEY,
    listing_id            INTEGER NOT NULL UNIQUE REFERENCES listing(listing_id),
    agent_employee_id     INTEGER NOT NULL REFERENCES agent(employee_id),
    transaction_type      VARCHAR(10) NOT NULL CHECK (transaction_type IN ('sale', 'rental')),
    transaction_status    VARCHAR(20) NOT NULL CHECK (transaction_status IN ('pending', 'closed', 'cancelled')),
    transaction_amount    NUMERIC(12,2),
    monthly_rent          NUMERIC(12,2),
    lease_start_date      DATE,
    lease_end_date        DATE,
    closing_date          DATE,
    commission_amount     NUMERIC(12,2)
);

CREATE TABLE transaction_client_role (
    transaction_id   INTEGER NOT NULL REFERENCES transactions(transaction_id),
    client_id        INTEGER NOT NULL REFERENCES client(client_id),
    role_type        VARCHAR(20) NOT NULL CHECK (role_type IN ('buyer', 'seller', 'tenant', 'landlord')),
    PRIMARY KEY (transaction_id, client_id)
);

-- Helpful indexes on foreign keys / common joins
CREATE INDEX idx_employee_office_id ON employee(office_id);
CREATE INDEX idx_agent_employee_id ON agent(employee_id);
CREATE INDEX idx_client_preference_client_id ON client_preference(client_id);
CREATE INDEX idx_school_neighborhood_id ON school(neighborhood_id);
CREATE INDEX idx_property_neighborhood_id ON property(neighborhood_id);
CREATE INDEX idx_listing_property_id ON listing(property_id);
CREATE INDEX idx_listing_agent_employee_id ON listing(agent_employee_id);
CREATE INDEX idx_listing_ownership_client_id ON listing_ownership(client_id);
CREATE INDEX idx_client_inquiry_client_id ON client_inquiry(client_id);
CREATE INDEX idx_client_inquiry_listing_id ON client_inquiry(listing_id);
CREATE INDEX idx_appointment_listing_id ON appointment(listing_id);
CREATE INDEX idx_appointment_client_id ON appointment(client_id);
CREATE INDEX idx_appointment_agent_employee_id ON appointment(agent_employee_id);
CREATE INDEX idx_open_house_listing_id ON open_house(listing_id);
CREATE INDEX idx_open_house_agent_employee_id ON open_house(agent_employee_id);
CREATE INDEX idx_open_house_attendance_client_id ON open_house_attendance(client_id);
CREATE INDEX idx_transaction_agent_employee_id ON transactions(agent_employee_id);
CREATE INDEX idx_transaction_client_role_client_id ON transaction_client_role(client_id);

COMMIT;
