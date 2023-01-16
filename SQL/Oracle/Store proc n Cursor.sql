
------------------------------=========== Stored Procedure =====================-------------------------------------

drop procedure sp_kisoft_usrid_expire;

create or replace procedure sp_kisoft_usrid_expire (name in varchar2) 

is

 v_User_  NVARCHAR2(20 CHAR);
 v_First_name  NVARCHAR2(50 CHAR);
 v_Last_name  NVARCHAR2(50 CHAR);
 v_Expires date;

begin

for x in(
        select User_,First_name,Last_name,Expires into v_User_, v_First_name,v_Last_name,v_Expires
        from tbl_kisoft_users
        where First_Name like name||'%' 
        )
    loop
        dbms_output.put_line(x.User_||'     '|| x.First_name ||'    ' || x.Last_name|| '    ' || x.Expires);
    end loop;

    
end;




exec sp_kisoft_usrid_expire ('Mark')

-----------------------------=============== Date conversion ================--------------------

select to_date(to_char(EXPIRES,'yyyymmdd'),'yyyymmdd') from tbl_kisoft_users

Select trunc(Sysdate-EXPIRES) as Day--,

--           trunc(mod((EXPIRES-Sysdate)*24,24)) as Hour,
--
--           trunc(mod((EXPIRES-Sysdate)*24*60,60)) as Minutes,
--
--           trunc(mod((EXPIRES-Sysdate)*24*60*60)) as Seconds

From tbl_kisoft_users;

select ADD_MONTHS(SYSDATE, -6) from dual

SELECT SYSDATE AS current_date,

       SYSDATE + 1 AS plus_1_day,

       SYSDATE + 1/24 AS plus_1_hours,

       SYSDATE + 1/24/60 AS plus_1_minutes,

       SYSDATE + 1/24/60/60 AS plus_1_seconds

FROM   dual;

-------------------------------=============== Loops =======================---------------------

DECLARE
  l_counter NUMBER := 0;
BEGIN
  LOOP
    l_counter := l_counter + 1;
    EXIT WHEN l_counter > 3;
    dbms_output.put_line( 'Inside loop: ' || l_counter ) ;
  END LOOP;

  -- control resumes here after EXIT
  dbms_output.put_line( 'After loop: ' || l_counter );
END;

---------=============== Nested Loop =======================---------------------

DECLARE
  l_i NUMBER := 0;
  l_j NUMBER := 0;
BEGIN
  <<outer_loop>>
  LOOP
    l_i := l_i + 1;
    EXIT outer_loop WHEN l_i > 2;    
    dbms_output.put_line('Outer counter ' || l_i);
    -- reset inner counter
    l_j := 0;
      <<inner_loop>> LOOP
      l_j := l_j + 1;
      EXIT inner_loop WHEN l_j > 3;
      dbms_output.put_line(' Inner counter ' || l_j);
    END LOOP inner_loop;
  END LOOP outer_loop;
END;
  
-----------------======================== For Loop =====================----------------------

--1)
BEGIN
  FOR l_counter IN 1..5
  LOOP
    DBMS_OUTPUT.PUT_LINE( l_counter );
  END LOOP;
END;

--2)
DECLARE
  l_step  PLS_INTEGER := 2;
BEGIN
  FOR l_counter IN 1..5 LOOP
    dbms_output.put_line (l_counter*l_step);
  END LOOP;
END;

--3)
DECLARE
  l_counter PLS_INTEGER := 10;
BEGIN
  FOR l_counter IN 1.. 5 loop
    DBMS_OUTPUT.PUT_LINE (l_counter);
  end loop;
  -- after the loop
  DBMS_OUTPUT.PUT_LINE (l_counter);
END; 

-----------======================= Cursors =================--------------------------
--1)
DECLARE
    r_product products%rowtype;
    CURSOR c_product (low_price NUMBER, high_price NUMBER)
    IS
        SELECT *
        FROM products
        WHERE list_price BETWEEN low_price AND high_price;
BEGIN
    -- show mass products
    dbms_output.put_line('Mass products: ');
    OPEN c_product(50,100);
    LOOP
        FETCH c_product INTO r_product;
        EXIT WHEN c_product%notfound;
        dbms_output.put_line(r_product.product_name || ': ' ||r_product.list_price);
    END LOOP;
    CLOSE c_product;

    -- show luxury products
    dbms_output.put_line('Luxury products: ');
    OPEN c_product(800,1000);
    LOOP
        FETCH c_product INTO r_product;
        EXIT WHEN c_product%notfound;
        dbms_output.put_line(r_product.product_name || ': ' ||r_product.list_price);
    END LOOP;
    CLOSE c_product;

END;
/

--2)
  CURSOR c3
RETURN tbl_kisoft_users%ROWTYPE
IS
   SELECT *
   FROM tbl_kisoft_users
   WHERE First_Name = 'Guy';
-------------======================= Cursor inside Procedure ==============---------------------
--1)
CREATE OR REPLACE PROCEDURE Test_cursor (Out_Pid OUT VARCHAR2) AS 
cursor  c1 IS
SELECT shipment_id,p_id FROM test
WHERE shipment_id = 99;

c1_rec c1%rowtype;

BEGIN
 OPEN c1;
  LOOP
  FETCH c1 INTO c1_rec;
  EXIT WHEN c1%NOTFOUND;

  Out_Pid := c1_rec.p_id;
  DBMS_OUTPUT.PUT_LINE('Result from query '||c1_rec.p_id );
  DBMS_OUTPUT.PUT_LINE('Result from out parameter '||Out_Pid );
 END LOOP;

  END Test_cursor;
  
 
  
  