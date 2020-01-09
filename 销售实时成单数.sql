select  t3.class as 类型, t3.region as 区, t3.department as 部, t3.department_name as 部门名称,
        t2.number as 抗标人数,t2.order_number as 订单数指标, 
        t1.today_order as 今日订单数,t1.tomonth_order as 当月总订单数,t1.achieve_rate as 月应完标率

from( 
      select cdme.class, cdme.branch, cdme.center, cdme.region, cdme.department, cdme.grp, cdme.department_name
      from bidata.charlie_dept_month_end cdme 
      where cdme.stats_date = curdate() and cdme.class = '销售'
            and cdme.department_name like '销售_区%'
            or cdme.department_name like '销售考核%'
      group by cdme.department_name
      ) as t3

left join (
            select a.class,  
                   a.branch,
                   a.center,
                   a.region,
                   a.department,
                   a.department_name,
                   count(case when date(a.max_pay_date) = curdate() then a.contract_id end) as today_order,
                   count(a.contract_id) as tomonth_order,
                   (1/DAYOFMONTH(LAST_DAY(curdate()))*DAYOFMONTH(curdate())) achieve_rate             
         
            from(
                            select  
                                    cdme.class,
                                    cdme.branch,
                                    cdme.center,
                                    cdme.region,
                                    cdme.department,
                                    cdme.grp,
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
                                   and max_pay_date >= date_format(curdate(),'%Y-%m-01')
                                    ) as a
        group by a.department_name
        ) as t1 on t1.department_name = t3.department_name


left join 
    (select     
        st.group_name,
        st.number,
        st.order_number
    from bidata.sales_tab st
    where st.type = 'normal'
) t2 on t3.department_name = t2.group_name


where not(t1.department_name is null and t2.group_name is null);