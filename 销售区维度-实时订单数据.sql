select  t1.region as 区,
        sum(t2.today_order) as 今日订单数, sum(t2.tomonth_order) as 当月订单数,
        sum(t2.today_amount) as 今日订单额, sum(t2.tomonth_amount) as 当月订单额

from( 
      select cdme.class, cdme.branch, cdme.center, 
             case when cdme.department_name like '销售考核_组' then '考核部'
                  when cdme.department_name like '%待分配部%' then '待分配部'
             else cdme.region end region,
             case when cdme.department_name like '销售考核_组' then cdme.grp 
                  when cdme.department_name like '%待分配%' then '待分配部'
             else cdme.department end department,
             cdme.department_name
      from bidata.charlie_dept_month_end cdme 
      where cdme.stats_date = curdate() and cdme.class = '销售'
            and cdme.department_name like '销售_区%'
            or cdme.department_name like '销售考核%'
      group by cdme.department_name
      ) as t1

left join (
            select a.department_name,
                   count(case when date(max_pay_date)=curdate() then a.contract_id else null end) as today_order,
                   count(a.contract_id) as tomonth_order,
                   sum(case when date(max_pay_date)=curdate() then a.contract_amount else 0 end) as today_amount,
                   sum(a.contract_amount) as tomonth_amount        
         
            from(
                            select  
                                    cdme.department_name, 
                                    tcp.contract_id,        
                                    max(tcp.pay_date) as max_pay_date,
                                    sum(tcp.sum/100) real_pay_sum, 
                                    (tc.sum-666)*10 contract_amount
                            from hfjydb.view_tms_contract_payment tcp
                            left join hfjydb.view_tms_contract tc on tc.contract_id = tcp.contract_id 
                            left join hfjydb.view_user_info ui on ui.user_id = tc.submit_user_id 
                            inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tc.submit_user_id
                                       and cdme.stats_date = curdate() and cdme.class = '销售'    
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
        ) t3 on t1.department_name = t3.group_name

where not(t2.department_name is null and t3.group_name is null)

group by 区