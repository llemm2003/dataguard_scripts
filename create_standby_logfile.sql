SET SERVEROUTPUT ON
set linesize 300
DECLARE
num_instance number;
num_curr_size number(10);
num_group number;
num_max_current_group number(2);
redo_type varchar2(10);
b varchar2(150);
num_new_standby_group number(2);
counter number(2);
num_count_of_sizes number(2);
BEGIN
 select max(INSTANCE_NUMBER) into  num_instance  from gv$instance;
 select max(group#)/num_instance+1 into num_group from v$log;
 select max(group#) into num_max_current_group from v$log;
 select distinct bytes into  num_curr_size from v$log;
 select count(distinct bytes) into  num_count_of_sizes from v$log;
 counter := num_max_current_group;
 IF num_count_of_sizes > 1 THEN
 RAISE_APPLICATION_ERROR(-20000,'MANY REDO LOG SIZE PLEASE REVIEW');
 END IF;
 BEGIN
  select distinct type into redo_type from gv$logfile where type='STANDBY';
 EXCEPTION
  WHEN NO_DATA_FOUND THEN
  redo_type := 'no_standby';
 END;
 dbms_output.put_line('Number of standby logfile to be created per thread: '||num_group);
 dbms_output.put_line('Standby log group will start on group: '|| num_max_current_group);
 IF redo_type = 'no_standby' then
  dbms_output.put_line('No Detected current standby logfile, proceeding with the logfile creation.');
  FOR j in 1..num_group LOOP
   --dbms_output.put_line(j);
    FOR k in 1..num_instance LOOP
	 num_new_standby_group :=counter+1;
     b := 'alter database add standby logfile thread '|| k ||' group ' ||num_new_standby_group||' (''+DATA'',''+DATA'') size '||num_curr_size;
	 dbms_output.put_line(b);
	 counter := num_new_standby_group;
	 /*THE EXECUTE COMMAND BELOW WILL RUN THE ADD, COMMENT THIS OUT IF YOU ARE JUST TESTING */
	 execute immediate b;
	END LOOP;
  END LOOP;
 END IF;
END;
/

/* Jan 6, 2017 - First version. */
/* Jan 15, 2017 -- Added set linesize 300 to avoid errors in creation on execute immediate part. */
/* Jan 18, 2017 -- Added / at the end. */
/* Jan 22, 2017 -- Changed the redo log number computation from 'max(group#)/2+1' to 'max(group#)/num_instance+1'. This will fix incorrect number of created redo log on a single instance. */
