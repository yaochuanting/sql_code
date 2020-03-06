-- 日战报核心指标-当月mtd
select  date_sub(curdate(),interval 1 day) as 统计日期,
        t1.center as 大区, 
        t1.region as 区,
        t1.department as 部, 
        t1.department_name as 部门名称, 
        t3.manager as 经理,
        t3.number as 抗标人数,
        t3.order_number as 订单数指标, 
        t4.new_sales as 新人数,
        t4.mid_sales as 中人数,
        t4.old_sales as 老人数,
        t2.today_order as 今日订单数,
        t2.k_today_order as 今日绩效订单数,
        t2.tomonth_order as 当月总订单数, 
        t2.k_tomonth_order as 当月绩效订单数,
        t2.tomonth_amount as 当月总订单额,
        t2.tomonth_new_order as 新粒子当月总订单数,
        t2.tomonth_oc_order as OC粒子当月总订单数,
        t2.tomonth_rec_order as 转介绍当月总订单数
from( 
      select cdme.center, 
             cdme.region,
             cdme.department,
             cdme.department_name
      from bidata.charlie_dept_month_end cdme 
      where cdme.stats_date = curdate() and cdme.class = 'CC'
            and cdme.department_name like 'CC%' 
      group by cdme.department_name
      ) as t1

left join (
            select a.department_name,
                   count(case when date(max_pay_date)= date_sub(curdate(),interval 1 day) then a.contract_id end) as today_order,
                   sum(case when date(max_pay_date)= date_sub(curdate(),interval 1 day) then a.k_order_num end) k_today_order,
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
                                case when s.coil_in in (13,22) or s.know_origin in (56,71,22,24,25,41) then 1 else 0 end as is_rec,
                                case when s.create_time >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01') then 1 else 0 end as is_new,
                                case when tc.period >= 60 then 1 else 0.5 end as k_order_num, 
                                max(tcp.pay_date) as max_pay_date,
                                sum(tcp.sum/100) real_pay_sum, 
                                (tc.sum-666)*10 contract_amount
                    from hfjydb.view_tms_contract_payment tcp
                    left join hfjydb.view_tms_contract tc on tc.contract_id = tcp.contract_id 
                    left join view_student s on  tc.student_intention_id= s.student_intention_id
                    left join hfjydb.view_user_info ui on ui.user_id = tc.submit_user_id 
                    inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tc.submit_user_id
                               and cdme.stats_date = curdate() and cdme.class = 'CC'
                               and cdme.date >= date_format(date_sub(curdate(),interval 1 day) ,'%Y-%m-01')  
                    where tcp.pay_status in (2,4) 
                          and tc.status <> 8  -- 剔除合同终止和废弃
                          and ui.account_type = 1  -- 剔除测试数据
                    group by tcp.contract_id
                    having real_pay_sum >= contract_amount 
                           and date(max_pay_date) >= date_format(date_sub(curdate(),interval 1 day) ,'%Y-%m-01')
                           and date(max_pay_date) <= date_sub(curdate(),interval 1 day) 
                                      ) as a
            group by a.department_name
            ) as t2 on t2.department_name = t1.department_name


left join (select     
                    st.group_name,
                    st.number,
                    st.order_number,
                    st.manager
          from bidata.sales_tab st
          where st.type = 'normal'
          ) t3 on t3.group_name = t1.department_name

-- 新中老人的人数
left join (
              select  x.department_name,
                      count(case when x.work_time<60 then x.user_id end) as new_sales,
                      count(case when x.work_time>=60 and x.work_time<180 then x.user_id end) as mid_sales,
                      count(case when x.work_time>=180 then x.user_id end) as old_sales
              from(
                            select cdme.department_name,cdme.user_id,
                                   ifnull(timestampdiff(day,min(opt_time),date_format(curdate(),'%Y-%m-01')),0) work_time
                            from bidata.charlie_dept_month_end cdme
                            left join hfjydb.sys_change_role_log scr on scr.user_id=cdme.user_id
                            where cdme.stats_date=curdate() and cdme.class='CC' 
                                  and cdme.date=curdate() and cdme.quarters in ('销售组员','销售组长')
                            group by cdme.department_name,cdme.user_id
                            )x
              group by x.department_name
              )t4 on t4.department_name=t1.department_name
;