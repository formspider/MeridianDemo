DROP USER c##meridian CASCADE;

CREATE USER c##meridian IDENTIFIED BY meridian DEFAULT TABLESPACE users 
                                  TEMPORARY TABLESPACE temp  
                                  QUOTA UNLIMITED ON users;

GRANT create session TO c##meridian ;
GRANT alter session TO c##meridian ;
GRANT create table TO c##meridian ;
GRANT create trigger TO c##meridian ;
GRANT create view TO c##meridian;
GRANT create sequence TO c##meridian ;
GRANT create synonym TO c##meridian ;
GRANT create type TO c##meridian;
GRANT create procedure TO c##meridian;
