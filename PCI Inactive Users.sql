DECLARE
vmailmessage VARCHAR2(20000);
v_client_name VARCHAR2(500);
v_client_emails VARCHAR2(500);
v_client_bccs VARCHAR2(500);
v_client_ID INTEGER;
v_email varchar(150);
v_last_login varchar(150);
v_user_name varchar(150);
v_user_number varchar(150);

  -- FIRST CURSOR pulls just the clients who have expired users
CURSOR cursor_clients_w_expired IS 
      select  distinct  c.client as client_name,
          c.client_services_emails emails,
          c.admin_bcc as bcc_emails,
          c.client_ID as client_ID
          
      from [table name redacted] u, [table name redacted] c, ( 
            select max(event_dt) as event_dt, 
              decode(sign(instr(user_id,'@')),1,substr(user_id,0,instr(user_id,'@')-1),user_id) user_id
            from [table name redacted]
            where status_comment in ('LOGON_SUCCESS','LOGON_EXPIRED')  
             group by decode(sign(instr(user_id,'@')),1,substr(user_id,0,instr(user_id,'@')-1),user_id) 
         ) rl
         
         where u.client_id=c.client_id 
          and u.user_id=rl.user_id(+)
          and c.client_status = 'A'
          and (event_dt < SYSDATE - 90
            or (event_dt is null and u.password_change_dt < SYSDATE - 90) 
          )
          
          and 'API Access' not in
          
            (select g.group_name from [table name redacted] ug, [table name redacted] g 
             where ug.user_number=u.user_number
             and ug.group_ID = g.group_ID)
          
          order by client_name, client_ID, emails, bcc_emails;
          
BEGIN
          
  vmailmessage := '';

  -- Loop through these clients, grabbing their names and contact emails
  OPEN cursor_clients_w_expired;
  LOOP
    FETCH cursor_clients_w_expired INTO v_client_name, v_client_emails, v_client_bccs, v_client_ID;
    EXIT WHEN cursor_clients_w_expired%NOTFOUND;
    
    vmailmessage := v_client_name || ', ' || v_client_emails || '\n';
    DBMS_OUTPUT.PUT_LINE('EXPIRED USERS FOR CLIENT: ' || v_client_name || ', ' || v_client_emails || ', ' || v_client_bccs);
    
    -- SECOND CURSOR grabs all the expired users for this client
    DECLARE 
    CURSOR cursor_expired_users IS 
      select  distinct  u.email,
          rl.event_dt as recent_login,
          FNAME || ' ' || LNAME as user_name,
          u.user_number
          
      from [table name redacted] u, [table name redacted] c, ( 
            select max(event_dt) as event_dt, 
              decode(sign(instr(user_id,'@')),1,substr(user_id,0,instr(user_id,'@')-1),user_id) user_id 
            from [table name redacted] 
            where status_comment in ('LOGON_SUCCESS','LOGON_EXPIRED')  
             group by decode(sign(instr(user_id,'@')),1,substr(user_id,0,instr(user_id,'@')-1),user_id) 
         ) rl
         
         where u.client_id=c.client_id 
          and u.user_id=rl.user_id(+)
          and u.user_status = 'A'
          and (event_dt < SYSDATE - 90            
            or (event_dt is null and u.password_change_dt < SYSDATE - 90) 
          )
          and c.client_ID = v_client_ID
          
          and 'API Access' not in
          
            (select g.group_name from [table name redacted] ug, [table name redacted] g 
             where ug.user_number=u.user_number
             and ug.group_ID = g.group_ID)
          
          order by user_name, event_dt, recent_login, email, user_number desc;
          
        BEGIN
        
          -- Loop through them and add their names to the email
          OPEN cursor_expired_users;
          LOOP
            FETCH cursor_expired_users INTO v_email, v_last_login, v_user_name, v_user_number;
            EXIT WHEN cursor_expired_users%NOTFOUND;
            
            DBMS_OUTPUT.PUT_LINE(v_user_name || '(' || v_email || ')' || ' - ' || v_user_number || ' - ' || v_last_login);
             
             update r_user set user_status = 'I', last_change_user = '90-Day Expiration' where user_number = v_user_number;
             
          END LOOP;
          
          CLOSE cursor_expired_users;
        END;
        
        DBMS_OUTPUT.PUT_LINE(' ');
         
  END LOOP;
 
  CLOSE cursor_clients_w_expired;
  
  commit;
  
ROI_TOOLBOX_MAIL.MAIL('arehm@roisolutions.com','arehm@roisolutions.com',null, null, 'Expired Results', vmailmessage);
         
 END;
