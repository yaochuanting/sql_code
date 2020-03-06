select  now() as 更新时间,
        concat(ifnull(t1.center,''),ifnull(t1.region,'')) as 区,
        sum(t2.today_rec_order) as 今日转介绍订单数,  sum(t2.k_today_rec_order) as 今日转介绍绩效订单数,
        sum(t2.tomonth_rec_order) as 当月转介绍订单数, sum(t2.k_tomonth_rec_order) as 当月转介绍绩效订单数,
        sum(t2.today_rec_amount) as 今日转介绍订单额, sum(t2.tomonth_rec_amount) as 当月转介绍订单额,
        sum(t2.today_order) as 今日订单数,  sum(t2.k_today_order) as 今日绩效订单数,
        sum(t2.today_amount) as 今日订单额,
        sum(t2.tomonth_order) as 当月订单数, sum(t2.k_tomonth_order) as 当月绩效订单数,
        sum(t2.tomonth_amount) as 当月订单额

from( 
      select cdme.class, cdme.center, cdme.region, cdme.department, cdme.department_name
      from bidata.charlie_dept_month_end cdme 
      where cdme.stats_date = curdate() and cdme.class = 'CC'
            and cdme.department_name like 'CC%'
      group by cdme.department_name
      ) as t1

left join (
            select a.department_name,
                   count(case when date(max_pay_date)=curdate() and a.is_rec=1 then a.contract_id end) as today_rec_order,
                   sum(case when date(max_pay_date)=curdate() and a.is_rec=1 then a.k_num end) as k_today_rec_order,
                   count(case when a.is_rec=1 then a.contract_id end) as tomonth_rec_order,
                   sum(case when a.is_rec=1 then a.k_num end) as k_tomonth_rec_order,
                   sum(case when date(max_pay_date)=curdate() and a.is_rec=1 then a.contract_amount end) as today_rec_amount,
                   sum(case when a.is_rec=1 then a.contract_amount end) as tomonth_rec_amount,
                   count(case when date(max_pay_date)=curdate() then a.contract_id end) as today_order,
                   sum(case when date(max_pay_date)=curdate() then a.k_num end) as k_today_order,
                   sum(case when date(max_pay_date)=curdate() then a.contract_amount else null end) as today_amount,
                   count(a.contract_id) as tomonth_order,
                   sum(a.k_num) as k_tomonth_order,
                   sum(a.contract_amount) as tomonth_amount        
         
            from(
                            select  
                                    cdme.department_name, 
                                    tcp.contract_id,
                                    case when tc.period >= 60 then 1 else 0.5 end k_num,       
                                    max(tcp.pay_date) as max_pay_date,
                                    sum(tcp.sum/100) real_pay_sum, 
                                    (tc.sum-666)*10 contract_amount,
                                    case when s.coil_in in (13,22) or s.know_origin in (56,71,22,24,25,41)  then 1 else 0 end is_rec
                                    

                            from hfjydb.view_tms_contract_payment tcp
                            left join hfjydb.view_tms_contract tc on tc.contract_id = tcp.contract_id 
                            left join hfjydb.view_user_info ui on ui.user_id = tc.submit_user_id 
                            left join hfjydb.view_student s on s.student_intention_id=tc.student_intention_id
                            inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tc.submit_user_id
                                       and cdme.stats_date = curdate() and cdme.class = 'CC'    
                            where tcp.pay_status in (2,4) 
                                  and tc.status <> 8  -- 剔除合同终止和废弃
                                  and ui.account_type = 1  -- 剔除测试数据
                            group by tcp.contract_id
                            having real_pay_sum >= contract_amount 
                                   and date(max_pay_date) >= date_format(curdate(),'%Y-%m-01')
                                   and date(max_pay_date) <= curdate()
                                    ) as a
        group by a.department_name
        ) as t2 on t1.department_name = t2.department_name


left join (select     
                st.group_name,
                st.number,
                st.order_number,
                st.manager
            from bidata.sales_tab st
            where st.type = 'normal'
                  and st.group_name like 'CC%'
        ) t3 on t1.department_name = t3.group_name

where not(t2.department_name is null and t3.group_name is null)

group by 区
order by 当月订单额 desc