select count(*) from stock_despatch sd
left join (select closed_at,shipment_id from shipment_man where shipment_type not in ('E_DIS')) sm on sm.shipment_id=sd.shipment_id  
where sm.closed_at between trunc(SYSDATE - 2) + 0.25 and trunc(SYSDATE-1) + 0.25

--153368

select *
--TMS_SLOT_REF 
 from shipment_man
where closed_at between trunc(SYSDATE - 7) + 0.25 and trunc(SYSDATE) + 0.25 
and Truck_LP like ('SBS%')
order by Truck_LP desc

select * from tbl_xdpr_plan

select * from customer_orders co
left join tbl_xdpr_plan x on x.order_no=co.order_no
where co.create_time between trunc(SYSDATE - 2) + 0.25 and trunc(SYSDATE-1) + 0.25 
--19908


---------------------------========================== View created =============================================-------------------------------------------------   


create and replace view SHIPMENT_ORDER as
 select    sd.SHIPMENT_ID SHIPMENT_ID_SD
        , sd.SKU SKU_SD
        , sd.ORDER_NO  ORDER_NO_SD
        , sd.ROUTING_BARCODE ROUTING_BARCODE_SD
        , sum(sd.QTY) QTY_SD
        , sm.closed_at closed_at_sm
        , sm.SHIPMENT_ID SHIPMENT_ID_SM
        , sm.SHIPMENT_NAME SHIPMENT_NAME_SM
        , sm.TOUR_NAME TOUR_NAME_SM
        , sm.SHIPMENT_TYPE SHIPMENT_TYPE_SM
        , sm.TRUCK_LP TRUCK_LP_SM
        , sm.TMS_SLOT_REF
        , case when sm.TMS_SLOT_REF is null and  length(sm.TRUCK_LP )=14
                then concat('SBS-',substr(rtrim(ltrim(sm.TRUCK_LP)),-7)) 
             else sm.TMS_SLOT_REF 
          end TMS_SLOT_REF_SM
        , sum(sm.PICK_SGL) PICK_SGL_SM
        , sum(sm.XD_SGL) XD_SGL_SM
        , sm.DUMMY DUMMY_SM
        , sm.EMPTY EMPTY_SM
        , sm.SHIP_TO_CODE SHIP_TO_CODE_SM
        , sum(sm.RTN_SGL) RTN_SGL_SM
        , sm.SHIP_TO_MULTI SHIP_TO_MULTI_SM
        , co.SHIP_TO_SITE_CODE  SHIP_TO_SITE_CODE_CO
        , co.TDEPT  TDEPT_CO
        , co.ORDER_NO ORDER_NO_CO
        , case when  length(sd.ROUTING_BARCODE )=32 
                then 'X'
                    when sd.ROUTING_BARCODE like ('81%') and length(sd.ROUTING_BARCODE )=10
                        then 'C'
                            when sd.ROUTING_BARCODE like ('45%')
                                then 'T'
                                    when sd.ROUTING_BARCODE like ('5%') and length(sd.ROUTING_BARCODE )=10
                                        then 'P'                            
                else 'O'
          end LOAD_UNIT_TYPE
from stock_despatch sd          --137049247
left join (select  closed_at
                 , shipment_id 
                 , SHIP_TO_MULTI
                 , sum(RTN_SGL) RTN_SGL
                 , SHIP_TO_CODE
                 , EMPTY
                 , DUMMY
                 , sum(XD_SGL) XD_SGL
                 , sum(PICK_SGL) PICK_SGL
                 , TMS_SLOT_REF
                 , TRUCK_LP
                 , SHIPMENT_TYPE
                 , TOUR_NAME
                 , SHIPMENT_NAME
                 
            from shipment_manual 
            where shipment_type not in ('ECOM_DISPATCH') 
                and closed_at between trunc(SYSDATE - 2) + 0.25 and trunc(SYSDATE-1) + 0.25 
            group by   closed_at
                     , shipment_id 
                     , SHIP_TO_MULTI
                     , SHIP_TO_CODE
                     , EMPTY
                     , DUMMY                     
                     , TMS_SLOT_REF
                     , TRUCK_LP
                     , SHIPMENT_TYPE
                     , TOUR_NAME
                     , SHIPMENT_NAME
            ) sm on sm.shipment_id=sd.shipment_id
left join (select * from customer_orders where create_time between trunc(SYSDATE - 30) + 0.25 and trunc(SYSDATE-1) + 0.25) co on co.order_no = sd.order_no
where sm.closed_at between trunc(SYSDATE - 2) + 0.25 and trunc(SYSDATE-1) + 0.25 
    --and sm.TRUCK_LP like ('SBS%')
group by  sd.SHIPMENT_ID 
        , sd.SKU 
        , sd.ORDER_NO 
        , sd.ROUTING_BARCODE                  
        , sm.closed_at        
        , sm.SHIPMENT_ID 
        , sm.SHIPMENT_NAME 
        , sm.TOUR_NAME 
        , sm.SHIPMENT_TYPE 
        , sm.TRUCK_LP 
        , sm.TMS_SLOT_REF 
        , sm.DUMMY 
        , sm.EMPTY 
        , sm.SHIP_TO_CODE 
        , sm.SHIP_TO_MULTI
        , co.SHIP_TO_SITE_CODE 
        , co.TDEPT 
        , co.ORDER_NO;

commit;

select count(*), SKU_SD from SHIPMENT_ORDER
group by SKU_SD
having count(*)>1
order by count(*) desc ;

------------------------================ Update Dummy and Empty ==================================------------------------------------

update shipment_manual
set Dummy = 1
where Shipment_name like ('DUM%')

update shipment_manual
set Dummy = 0
where Dummy is null


update shipment_manual
set Empty =1 
where shipment_id not in (select distinct ID from picking_progress )

update shipment_manual
set Empty =0 
where Empty is null



select * from shipment_manual
where shipment_id not in (select distinct ID from picking_progress )


select count(*),Order_no_sd,ROUTING_BARCODE_sd
from SHIPMENT_ORDER
where Order_no_sd='6743481718'
group by Order_no_sd,ROUTING_BARCODE_sd

--------------------======================== Structure for otbl_Shipment_Order ==============================================-----------------------------------------
select * 
from
(
select trunc(so.closed_at_sm-0.25) 
        , so.SHIPMENT_ID_SD
        , so.ORDER_NO_SD
        , so.TDEPT_CO
        , so.LOAD_UNIT_TYPE
        , sum(so.QTY_SD) Singles
        ,round(sum(1/ (select count_ 
                from(select count(*) count_ ,Order_no_sd,ROUTING_BARCODE_sd
                from OTBL_SHIPMENT_ORDER  
                group by Order_no_sd,ROUTING_BARCODE_sd)o
                where so.ORDER_NO_SD=o.ORDER_NO_SD and o.ROUTING_BARCODE_sd=so.ROUTING_BARCODE_sd )),4) Load_Unit_Count
        
from SHIPMENT_ORDER so
--where so.ORDER_NO_SD in ('6743556940')
group by so.closed_at_sm
        , so.SHIPMENT_ID_SD
        , so.ORDER_NO_SD
        , so.TDEPT_CO
        , so.LOAD_UNIT_TYPE
        --, so.ROUTING_BARCODE_sd;
)v1
order by v1.Load_Unit_Count
        
--------------------========================== Pick_Sgl | XD_Sgl | Ship_To_Code | Ship_To_Multi (concatenation of multiple ship_to_sites) ================================---------------------------------

select    --ORDER_NO_SD

         sum( (select sum(QTY_SD) XD_Sgl 
            from OTBL_SHIPMENT_ORDER s
            where LOAD_UNIT_TYPE != 'X' and s.ORDER_NO_SD=so.ORDER_NO_SD and s.ROUTING_BARCODE_sd=so.ROUTING_BARCODE_sd) )  Pick_Sgl 
            
        , sum((select sum(QTY_SD) XD_Sgl 
            from OTBL_SHIPMENT_ORDER s
            where LOAD_UNIT_TYPE = 'X' and s.ORDER_NO_SD=so.ORDER_NO_SD and s.ROUTING_BARCODE_sd=so.ROUTING_BARCODE_sd))   XD_Sgl
            
        , so.Ship_To_site_Code_CO
        
        ,  mu.ship_to_multi_sm
      
from SHIPMENT_ORDER so
left join (
            select v3.shipment_id_sd
                , v3.ship_to_multi_sm
            
            from
            (
            select v2.shipment_id_sd
                    , case when length(LISTAGG(v2.Ship_To_site_Code_CO, ',') WITHIN GROUP (ORDER BY rank_) )>6 
                             then LISTAGG(v2.Ship_To_site_Code_CO, ',') WITHIN GROUP (ORDER BY rank_) 
                                else null
                      end ship_to_multi_sm
            from
            
            (
            select    v1.shipment_id_sd
                    , v1.Ship_To_site_Code_CO
                    , rank()over(
                                  partition by   v1.shipment_id_sd
                                  order by v1.Ship_To_site_Code_CO ) rank_
            from         
            (
            select   distinct shipment_id_sd
                   , Ship_To_site_Code_CO
            from OTBL_SHIPMENT_ORDER     
            )v1
            
            )v2
             
            group by  v2.shipment_id_sd
            )v3
            where  v3.ship_to_multi_sm is not null
         ) mu on mu.shipment_id_sd=so.shipment_id_sd
group by  --ORDER_NO_SD
          so.Ship_To_site_Code_CO
        , mu.ship_to_multi_sm
--order by   ORDER_NO_SD     


----------------============================== Find the ship_to_multi_sm ==============================================--------------------------- 

select v3.shipment_id_sd
    , v3.ship_to_multi_sm

from
(
select v2.shipment_id_sd
        , case when length(LISTAGG(v2.Ship_To_site_Code_CO, ',') WITHIN GROUP (ORDER BY rank_) )>6 
                 then LISTAGG(v2.Ship_To_site_Code_CO, ',') WITHIN GROUP (ORDER BY rank_) 
                    else null
          end ship_to_multi_sm
from

(
select    v1.shipment_id_sd
        , v1.Ship_To_site_Code_CO
        , rank()over(
                      partition by   v1.shipment_id_sd
                      order by v1.Ship_To_site_Code_CO ) rank_
from         
(
select   distinct shipment_id_sd
       , Ship_To_site_Code_CO
from SHIPMENT_ORDER     
)v1

)v2
 
group by  v2.shipment_id_sd
)v3
where  v3.ship_to_multi_sm is not null


-----------------================ Update Tdept from tbl_headers =================================-----------------------------------------

MERGE INTO customer_orders c
USING headers i
ON (c.order_no = i.order_no)
WHEN MATCHED THEN
UPDATE SET
c.TDEPT = i.TDEPT;