-- 架构   '${analyse_date}'
select  distinct cdme.center, 
	    cdme.region,
	    cdme.department,
	    cdme.department_name
from dt_mobdb.dt_charlie_dept_month_end cdme 
where to_date(cdme.stats_date)='${analyse_date}' and cdme.class = 'CC'
      and cdme.department_name like 'CC%'
      and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')


-- 订单数
select a.department_name,
       count(case when to_date(a.max_pay_date)='${analyse_date}' then a.contract_id end) as today_order,
       sum(case when to_date(a.max_pay_date)='${analyse_date}' then a.k_order_num end) k_today_order,
       count(a.contract_id) as tomonth_order,
       sum(a.k_order_num) as k_tomonth_order,
       sum(a.contract_amount) as tomonth_amount,
       count(case when is_new=1 then a.contract_id end) as tomonth_new_order,
       count(case when is_new=0 then a.contract_id end) as tomonth_oc_order,
       count(case when is_rec=1 then a.contract_id end) as tomonth_rec_order

from(
        select  
                    cdme.department_name, 
                    tcp.contract_id,
                    tc.student_intention_id,
                    max(case when s.coil_in in (13,22) or s.know_origin in (56,71,22,24,25,41) then 1 else 0 end) as is_rec,
                    max(case when s.create_time>=trunc('${analyse_date}','MM') then 1 else 0 end) as is_new,
                    max(case when tc.period>=60 then 1 else 0.5 end) as k_order_num, 
                    max(tcp.pay_date) as max_pay_date,
                    sum(tcp.`sum`/100) real_pay_sum, 
                    max((tc.`sum`-666)*10) contract_amount
        from dw_hf_mobdb.dw_view_tms_contract_payment tcp
        left join dw_hf_mobdb.dw_view_tms_contract tc on tc.contract_id = tcp.contract_id 
        left join dw_hf_mobdb.dw_view_student s on  tc.student_intention_id= s.student_intention_id
        left join dw_hf_mobdb.dw_view_user_info ui on ui.user_id = tc.submit_user_id 
        inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id = tc.submit_user_id
                   and to_date(cdme.stats_date)='${analyse_date}' and cdme.class = 'CC'
                   and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')
        where tcp.pay_status in (2,4) 
              and tc.status<>8  --剔除合同终止和废弃
              and ui.account_type = 1  --剔除测试数据
        group by cdme.department_name, tcp.contract_id, tc.student_intention_id
        having round(sum(tcp.`sum`/100),0)>=round(max((tc.`sum`-666)*10),0)
               and to_date(max_pay_date)>=trunc('${analyse_date}','MM')
               and to_date(max_pay_date)<='${analyse_date}'
               ) as a
group by a.department_name


-- 指标
select     
	    st.group_name,
	    st.number,
	    st.order_number
from hf_mobdb.sales_tab st
where st.type = 'normal'



-- 新中老销售人数
select    x.department_name,
	      count(case when x.work_time<60 then x.user_id end) as new_sales,
	      count(case when x.work_time>=60 and x.work_time<180 then x.user_id end) as mid_sales,
	      count(case when x.work_time>=180 then x.user_id end) as old_sales
from(
            select cdme.department_name,cdme.user_id,
                   datediff(trunc('${analyse_date}','MM'),to_date(min(opt_time))) work_time

            from dt_mobdb.dt_charlie_dept_month_end cdme
            left join dw_hf_mobdb.dw_sys_change_role_log scr on scr.user_id=cdme.user_id
            where cdme.stats_date='${analyse_date}' and cdme.class='CC' 
                  and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')
                  and cdme.quarters in ('销售组员','销售组长')
            group by cdme.department_name,cdme.user_id
            )x
group by x.department_name