create or replace procedure Final_Proc
as
begin

    begin
        insert into utbl_process_times
        (   process
          , start_time)
        VALUES
        ('Final_Proc', current_date);
    end;

-- call procedure
    begin

        sp_proc_1;

        Dbms_output.put_line('sp_proc_1 executed successsfully'); 

        commit;

        EXCEPTION
        WHEN OTHERS THEN
        dbms_output.put_line('Error in sp_proc_1!');

    end;
-- call procedure
    begin

        sp_proc_2;

        Dbms_output.put_line('sp_proc_2 executed successsfully');

        commit;

        EXCEPTION
        WHEN OTHERS THEN
        dbms_output.put_line('Error in sp_proc_2!');

    end;
-- call procedure
    begin

        sp_proc_3;

        Dbms_output.put_line('sp_proc_3 executed successsfully'); 

        commit;

        EXCEPTION
        WHEN OTHERS THEN
        dbms_output.put_line('Error in sp_proc_3!');

    end;
-- call procedure
    begin
    
        sp_proc_4;
    
         Dbms_output.put_line('sp_proc_4 executed successsfully'); 

        commit;

        EXCEPTION
        WHEN OTHERS THEN
        dbms_output.put_line('Error in sp_proc_4!');

    end;
 
 
    begin
        update utbl_process_times
        set end_time = current_date
       where rowid = (select max(rowid) from utbl_process_times where process =  'Final_Proc' and END_TIME is NULL); 
    end;
 

COMMIT;

EXCEPTION
WHEN OTHERS THEN
dbms_output.put_line('Error in Final_Proc!');

end Final_Proc;