/******************************************************************************
 * Sessions
 * Cross-connection identifier for persistent state
 *
 * Created by Aquameta Labs in Portland, Oregon, USA.
 * Company: http://aquameta.com/
 * Project: http://blog.aquameta.com/
 ******************************************************************************/

begin;

create extension if not exists "uuid-ossp" schema public;

create schema session;

set search_path=session;

/************************************************************************
 * session
 *
 * a cross-connection identifier for persistent state
 *
 ***********************************************************************/

-- persistent session object.
create table session.session (
    id uuid default public.uuid_generate_v4() primary key,
    owner_id meta.role_id not null, -- the owner's role
    connection_id meta.connection_id
);



-- create a new session.session and listen to it's channel on this postgresql connection
create or replace function session.session_create() returns uuid as $$
    declare
        session_id uuid;
    begin
        insert into session.session (owner_id, connection_id)
            values (meta.current_role_id(), meta.current_connection_id())
            returning id into session_id;
        execute 'listen "' || session_id || '"';
        return session_id;
    end;
$$ language plpgsql;



-- reattach to an existing session
create or replace function session.session_attach( session_id uuid ) returns void as $$
    DECLARE
        session_exists boolean;
        event json;
    BEGIN
        -- check to see that session exists
        EXECUTE 'select exists(select 1 from session.session where id=' || quote_literal(session_id) || ')' INTO session_exists;
        RAISE NOTICE 'session exists? %', session_exists;

        IF session_exists THEN
            RAISE NOTICE 'listen on %', session_id;
            EXECUTE 'listen "' || session_id || '"';

            -- send all events in the event table for this session (because they haven't yet been deleted aka recieved by the client)
            FOR event IN
                EXECUTE 'select event from event.event where session_id=' || quote_literal(session_id)
            LOOP
                RAISE NOTICE 'notifying %', session_id;
                EXECUTE 'notify ' || session_id || ', ' || event;
            END LOOP;
        END IF;

        -- to not do?: update session.session set connection_id=meta.current_connection_id() where id=session_id;
        --EXECUTE 'update session.session set connection_id=meta.current_connection_id() where id=' || quote_literal(session_id);
    END;
$$ language plpgsql;



create or replace function session.session_detach( session_id uuid ) returns void as $$
    begin
        RAISE NOTICE 'unlisten on %', session_id;
        execute 'unlisten "' || session_id || '"';
    end;
$$ language plpgsql;



create or replace function session.session_delete( session_id uuid ) returns void as $$
    begin
        execute 'delete from session.session where id=' || quote_literal(session_id);
    end;
$$ language plpgsql;



create or replace function session.current_session_id() returns uuid as $$
    select id from session.session where connection_id=meta.current_connection_id();
$$ language sql;


commit;
