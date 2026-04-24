import os
import pandas as pd
from sqlalchemy import create_engine

# PostgreSQL connection
# Update this connection string before running.
# conn_url = 'postgresql://postgres:your_password@localhost:5432/your_database_name'

conn_url = 'postgresql://postgres:123@localhost:5432/apan_5310_group_project'

# Create an engine that connects to PostgreSQL server
engine = create_engine(conn_url)

# Establish a connection
connection = engine.raw_connection()
cursor = connection.cursor()

# Pass the SQL schema that create all tables
schema = """
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
    office_id integer,
    office_name varchar(150) NOT NULL,
    street_address varchar(200),
    city varchar(100),
    state varchar(2),
    zip_code varchar(10),
    phone varchar(20),
    PRIMARY KEY (office_id)
);

CREATE TABLE employee (
    employee_id integer,
    office_id integer,
    first_name varchar(100) NOT NULL,
    last_name varchar(100) NOT NULL,
    email varchar(255) NOT NULL,
    phone varchar(20),
    employment_type varchar(20),
    job_title varchar(100),
    hire_date date,
    employment_status varchar(50),
    PRIMARY KEY (employee_id),
    UNIQUE (email),
    FOREIGN KEY (office_id) REFERENCES office (office_id)
);

CREATE TABLE agent (
    employee_id integer,
    license_number varchar(50) NOT NULL,
    commission_rate numeric,
    specialization varchar(100),
    PRIMARY KEY (employee_id),
    UNIQUE (license_number),
    FOREIGN KEY (employee_id) REFERENCES employee (employee_id)
);

CREATE TABLE client (
    client_id integer,
    first_name varchar(100) NOT NULL,
    last_name varchar(100) NOT NULL,
    email varchar(255),
    phone varchar(20),
    preferred_contact_method varchar(20),
    created_at date,
    PRIMARY KEY (client_id)
);

CREATE TABLE client_preference (
    client_id integer,
    preferred_location varchar(100),
    property_type varchar(50),
    min_budget numeric,
    max_budget numeric,
    min_bedrooms integer,
    max_bedrooms integer,
    min_bathrooms integer,
    min_square_feet integer,
    PRIMARY KEY (client_id),
    FOREIGN KEY (client_id) REFERENCES client (client_id)
);

CREATE TABLE neighborhood (
    neighborhood_id integer,
    neighborhood_name varchar(100) NOT NULL,
    borough_or_city varchar(100),
    state varchar(2),
    PRIMARY KEY (neighborhood_id)
);

CREATE TABLE school (
    school_id integer,
    neighborhood_id integer,
    school_name varchar(200) NOT NULL,
    school_type varchar(50),
    rating integer,
    address varchar(250),
    PRIMARY KEY (school_id),
    FOREIGN KEY (neighborhood_id) REFERENCES neighborhood (neighborhood_id)
);

CREATE TABLE property (
    property_id integer,
    neighborhood_id integer,
    street_address varchar(200),
    city varchar(100),
    state varchar(2),
    zip_code varchar(10),
    property_type varchar(50),
    square_feet integer,
    bedrooms integer,
    bathrooms integer,
    year_built integer,
    PRIMARY KEY (property_id),
    FOREIGN KEY (neighborhood_id) REFERENCES neighborhood (neighborhood_id)
);

CREATE TABLE listing (
    listing_id integer,
    property_id integer,
    agent_employee_id integer,
    listing_type varchar(10),
    listing_price numeric,
    listing_status varchar(20),
    list_date date,
    end_date date,
    PRIMARY KEY (listing_id),
    FOREIGN KEY (property_id) REFERENCES property (property_id),
    FOREIGN KEY (agent_employee_id) REFERENCES agent (employee_id)
);

CREATE TABLE listing_ownership (
    listing_id integer,
    client_id integer,
    role_type varchar(20),
    PRIMARY KEY (listing_id, client_id),
    FOREIGN KEY (listing_id) REFERENCES listing (listing_id),
    FOREIGN KEY (client_id) REFERENCES client (client_id)
);

CREATE TABLE client_inquiry (
    inquiry_id integer,
    client_id integer,
    listing_id integer,
    inquiry_date date,
    inquiry_channel varchar(50),
    inquiry_status varchar(50),
    PRIMARY KEY (inquiry_id),
    FOREIGN KEY (client_id) REFERENCES client (client_id),
    FOREIGN KEY (listing_id) REFERENCES listing (listing_id)
);

CREATE TABLE appointment (
    appointment_id integer,
    listing_id integer,
    client_id integer,
    agent_employee_id integer,
    appointment_datetime timestamp,
    appointment_type varchar(50),
    outcome varchar(50),
    PRIMARY KEY (appointment_id),
    FOREIGN KEY (listing_id) REFERENCES listing (listing_id),
    FOREIGN KEY (client_id) REFERENCES client (client_id),
    FOREIGN KEY (agent_employee_id) REFERENCES agent (employee_id)
);

CREATE TABLE open_house (
    open_house_id integer,
    listing_id integer,
    agent_employee_id integer,
    start_datetime timestamp,
    end_datetime timestamp,
    PRIMARY KEY (open_house_id),
    FOREIGN KEY (listing_id) REFERENCES listing (listing_id),
    FOREIGN KEY (agent_employee_id) REFERENCES agent (employee_id)
);

CREATE TABLE open_house_attendance (
    open_house_id integer,
    client_id integer,
    attended_flag boolean,
    interest_level varchar(20),
    PRIMARY KEY (open_house_id, client_id),
    FOREIGN KEY (open_house_id) REFERENCES open_house (open_house_id),
    FOREIGN KEY (client_id) REFERENCES client (client_id)
);

CREATE TABLE transactions (
    transaction_id integer,
    listing_id integer,
    agent_employee_id integer,
    transaction_type varchar(10),
    transaction_status varchar(20),
    transaction_amount numeric,
    monthly_rent numeric,
    lease_start_date date,
    lease_end_date date,
    closing_date date,
    commission_amount numeric,
    PRIMARY KEY (transaction_id),
    UNIQUE (listing_id),
    FOREIGN KEY (listing_id) REFERENCES listing (listing_id),
    FOREIGN KEY (agent_employee_id) REFERENCES agent (employee_id)
);

CREATE TABLE transaction_client_role (
    transaction_id integer,
    client_id integer,
    role_type varchar(20),
    PRIMARY KEY (transaction_id, client_id),
    FOREIGN KEY (transaction_id) REFERENCES transactions (transaction_id),
    FOREIGN KEY (client_id) REFERENCES client (client_id)
);

CREATE INDEX idx_employee_office_id ON employee (office_id);
CREATE INDEX idx_property_neighborhood_id ON property (neighborhood_id);
CREATE INDEX idx_school_neighborhood_id ON school (neighborhood_id);
CREATE INDEX idx_listing_property_id ON listing (property_id);
CREATE INDEX idx_listing_agent_employee_id ON listing (agent_employee_id);
CREATE INDEX idx_listing_status ON listing (listing_status);
CREATE INDEX idx_listing_type ON listing (listing_type);
CREATE INDEX idx_listing_list_date ON listing (list_date);
CREATE INDEX idx_listing_ownership_client_id ON listing_ownership (client_id);
CREATE INDEX idx_client_inquiry_listing_id ON client_inquiry (listing_id);
CREATE INDEX idx_client_inquiry_client_id ON client_inquiry (client_id);
CREATE INDEX idx_appointment_listing_id ON appointment (listing_id);
CREATE INDEX idx_appointment_client_id ON appointment (client_id);
CREATE INDEX idx_open_house_listing_id ON open_house (listing_id);
CREATE INDEX idx_open_house_attendance_client_id ON open_house_attendance (client_id);
CREATE INDEX idx_transactions_agent_employee_id ON transactions (agent_employee_id);
CREATE INDEX idx_transactions_status ON transactions (transaction_status);
CREATE INDEX idx_transactions_type ON transactions (transaction_type);
CREATE INDEX idx_transaction_client_role_client_id ON transaction_client_role (client_id);
"""

# Execute the statement to create tables
cursor.execute(schema)
connection.commit()
print('Group project tables created successfully.')

# ETL: load all CSV files
# Update data_dir before running.
data_dir = r'./DreamHomes_Full_Synthetic_Dataset'


office_df = pd.read_csv(os.path.join(data_dir, 'office.csv'))
office_df = office_df[['office_id', 'office_name', 'street_address', 'city', 'state', 'zip_code', 'phone']]
office_df.to_sql(name='office', con=engine, if_exists='append', index=False)
print('office loaded')


employee_df = pd.read_csv(os.path.join(data_dir, 'employee.csv'))
employee_df = employee_df[['employee_id', 'office_id', 'first_name', 'last_name', 'email', 'phone', 'employment_type', 'job_title', 'hire_date', 'employment_status']]
employee_df['hire_date'] = pd.to_datetime(employee_df['hire_date'], errors='coerce').dt.date
employee_df.to_sql(name='employee', con=engine, if_exists='append', index=False)
print('employee loaded')


agent_df = pd.read_csv(os.path.join(data_dir, 'agent.csv'))
agent_df = agent_df[['employee_id', 'license_number', 'commission_rate', 'specialization']]
agent_df.to_sql(name='agent', con=engine, if_exists='append', index=False)
print('agent loaded')


client_df = pd.read_csv(os.path.join(data_dir, 'client.csv'))
client_df = client_df[['client_id', 'first_name', 'last_name', 'email', 'phone', 'preferred_contact_method', 'created_at']]
client_df['created_at'] = pd.to_datetime(client_df['created_at'], errors='coerce').dt.date
client_df.to_sql(name='client', con=engine, if_exists='append', index=False)
print('client loaded')


client_preference_df = pd.read_csv(os.path.join(data_dir, 'client_preference.csv'))
client_preference_df = client_preference_df[['client_id', 'preferred_location', 'property_type', 'min_budget', 'max_budget', 'min_bedrooms', 'max_bedrooms', 'min_bathrooms', 'min_square_feet']]
client_preference_df.to_sql(name='client_preference', con=engine, if_exists='append', index=False)
print('client_preference loaded')


neighborhood_df = pd.read_csv(os.path.join(data_dir, 'neighborhood.csv'))
neighborhood_df = neighborhood_df[['neighborhood_id', 'neighborhood_name', 'borough_or_city', 'state']]
neighborhood_df.to_sql(name='neighborhood', con=engine, if_exists='append', index=False)
print('neighborhood loaded')


school_df = pd.read_csv(os.path.join(data_dir, 'school.csv'))
school_df = school_df[['school_id', 'neighborhood_id', 'school_name', 'school_type', 'rating', 'address']]
school_df.to_sql(name='school', con=engine, if_exists='append', index=False)
print('school loaded')


property_df = pd.read_csv(os.path.join(data_dir, 'property.csv'))
property_df = property_df[['property_id', 'neighborhood_id', 'street_address', 'city', 'state', 'zip_code', 'property_type', 'square_feet', 'bedrooms', 'bathrooms', 'year_built']]
property_df.to_sql(name='property', con=engine, if_exists='append', index=False)
print('property loaded')


listing_df = pd.read_csv(os.path.join(data_dir, 'listing.csv'))
listing_df = listing_df[['listing_id', 'property_id', 'agent_employee_id', 'listing_type', 'listing_price', 'listing_status', 'list_date', 'end_date']]
listing_df['list_date'] = pd.to_datetime(listing_df['list_date'], errors='coerce').dt.date
listing_df['end_date'] = pd.to_datetime(listing_df['end_date'], errors='coerce').dt.date
listing_df.to_sql(name='listing', con=engine, if_exists='append', index=False)
print('listing loaded')


listing_ownership_df = pd.read_csv(os.path.join(data_dir, 'listing_ownership.csv'))
listing_ownership_df = listing_ownership_df[['listing_id', 'client_id', 'role_type']]
listing_ownership_df.to_sql(name='listing_ownership', con=engine, if_exists='append', index=False)
print('listing_ownership loaded')


client_inquiry_df = pd.read_csv(os.path.join(data_dir, 'client_inquiry.csv'))
client_inquiry_df = client_inquiry_df[['inquiry_id', 'client_id', 'listing_id', 'inquiry_date', 'inquiry_channel', 'inquiry_status']]
client_inquiry_df['inquiry_date'] = pd.to_datetime(client_inquiry_df['inquiry_date'], errors='coerce').dt.date
client_inquiry_df.to_sql(name='client_inquiry', con=engine, if_exists='append', index=False)
print('client_inquiry loaded')


appointment_df = pd.read_csv(os.path.join(data_dir, 'appointment.csv'))
appointment_df = appointment_df[['appointment_id', 'listing_id', 'client_id', 'agent_employee_id', 'appointment_datetime', 'appointment_type', 'outcome']]
appointment_df['appointment_datetime'] = pd.to_datetime(appointment_df['appointment_datetime'], errors='coerce')
appointment_df.to_sql(name='appointment', con=engine, if_exists='append', index=False)
print('appointment loaded')


open_house_df = pd.read_csv(os.path.join(data_dir, 'open_house.csv'))
open_house_df = open_house_df[['open_house_id', 'listing_id', 'agent_employee_id', 'start_datetime', 'end_datetime']]
open_house_df['start_datetime'] = pd.to_datetime(open_house_df['start_datetime'], errors='coerce')
open_house_df['end_datetime'] = pd.to_datetime(open_house_df['end_datetime'], errors='coerce')
open_house_df.to_sql(name='open_house', con=engine, if_exists='append', index=False)
print('open_house loaded')


open_house_attendance_df = pd.read_csv(os.path.join(data_dir, 'open_house_attendance.csv'))
open_house_attendance_df = open_house_attendance_df[['open_house_id', 'client_id', 'attended_flag', 'interest_level']]
open_house_attendance_df.to_sql(name='open_house_attendance', con=engine, if_exists='append', index=False)
print('open_house_attendance loaded')


transactions_df = pd.read_csv(os.path.join(data_dir, 'transactions.csv'))
transactions_df = transactions_df[['transaction_id', 'listing_id', 'agent_employee_id', 'transaction_type', 'transaction_status', 'transaction_amount', 'monthly_rent', 'lease_start_date', 'lease_end_date', 'closing_date', 'commission_amount']]
transactions_df['lease_start_date'] = pd.to_datetime(transactions_df['lease_start_date'], errors='coerce').dt.date
transactions_df['lease_end_date'] = pd.to_datetime(transactions_df['lease_end_date'], errors='coerce').dt.date
transactions_df['closing_date'] = pd.to_datetime(transactions_df['closing_date'], errors='coerce').dt.date
transactions_df.to_sql(name='transactions', con=engine, if_exists='append', index=False)
print('transactions loaded')


transaction_client_role_df = pd.read_csv(os.path.join(data_dir, 'transaction_client_role.csv'))
transaction_client_role_df = transaction_client_role_df[['transaction_id', 'client_id', 'role_type']]
transaction_client_role_df.to_sql(name='transaction_client_role', con=engine, if_exists='append', index=False)
print('transaction_client_role loaded')


# Row-count check
row_count_tables = [
    'office', 'employee', 'agent', 'client', 'client_preference',
    'neighborhood', 'school', 'property', 'listing', 'listing_ownership',
    'client_inquiry', 'appointment', 'open_house', 'open_house_attendance',
    'transactions', 'transaction_client_role'
]

for table_name in row_count_tables:
    query = f'SELECT COUNT(*) FROM {table_name};'
    count_df = pd.read_sql(query, engine)
    print(f"{table_name}: {count_df.iloc[0, 0]}")

cursor.close()
connection.close()
print('Done.')