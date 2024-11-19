\set ON_ERROR_STOP on

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS unaccent;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create non-root users with limited privileges
\set n8n_user `echo "$N8N_DB_USER"`
\set n8n_pass `echo "$N8N_DB_PASSWORD"`
\set kc_user `echo "$KC_DB_USERNAME"`
\set kc_pass `echo "$KC_DB_PASSWORD"`
\set br_user `echo "$BASEROW_DB_USER"`
\set br_pass `echo "$BASEROW_DB_PASSWORD"`

CREATE USER :n8n_user WITH PASSWORD :'n8n_pass';
CREATE USER :kc_user WITH PASSWORD :'kc_pass';
CREATE USER :br_user WITH PASSWORD :'br_pass';

-- Create databases
CREATE DATABASE keycloak;
CREATE DATABASE baserow;
CREATE DATABASE n8n;
CREATE DATABASE appwrite;

-- Configure keycloak database
\c keycloak
CREATE EXTENSION IF NOT EXISTS vector;
CREATE SCHEMA IF NOT EXISTS keycloak;
GRANT ALL PRIVILEGES ON DATABASE keycloak TO :kc_user;
GRANT ALL PRIVILEGES ON SCHEMA keycloak TO :kc_user;
ALTER DATABASE keycloak OWNER TO :kc_user;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA keycloak 
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO :kc_user;

-- Configure baserow database
\c baserow
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS unaccent;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
GRANT ALL PRIVILEGES ON DATABASE baserow TO :br_user;
ALTER DATABASE baserow OWNER TO :br_user;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public 
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO :br_user;

-- Configure n8n database
\c n8n
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
GRANT ALL PRIVILEGES ON DATABASE n8n TO :n8n_user;
GRANT ALL PRIVILEGES ON SCHEMA public TO :n8n_user;
ALTER DATABASE n8n OWNER TO :n8n_user;
ALTER SCHEMA public OWNER TO :n8n_user;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public 
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO :n8n_user;

-- Configure appwrite database
\c appwrite
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
GRANT ALL PRIVILEGES ON DATABASE appwrite TO postgres;
ALTER DATABASE appwrite OWNER TO postgres;
