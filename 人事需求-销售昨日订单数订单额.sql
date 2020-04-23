select  t1.center 大区, t1.region 区, t1.department 部, t1.department_name 部门名称, t1.name 销售姓名, t1.job_number 员工编号,
        t2.order_num 完款订单数, t2.k_order_num 绩效订单数, t2.order_amount 完款订单额

from( 
      select cdme.class, cdme.center, cdme.region, cdme.department, cdme.department_name, cdme.user_id, cdme.name, cdme.job_number
      from bidata.charlie_dept_month_end cdme 
      where cdme.stats_date = curdate() and cdme.class = 'CC'
            and cdme.department_name like 'CC%' and cdme.date>=date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
      group by cdme.user_id
      ) as t1

left join (
            select a.submit_user_id,
                   count(a.contract_id) as order_num,
                   sum(a.k_order_num) k_order_num,
                   sum(a.contract_amount) as order_amount         
         
            from(
                            select  
                                    tcp.contract_id,
                                    case when tc.period>=60 then 1 else 0.5 end as k_order_num, 
                                    tc.submit_user_id,
                                    max(tcp.pay_date) as max_pay_date,
                                    sum(tcp.sum/100) real_pay_sum, 
                                    (tc.sum-666)*10 contract_amount
                            from hfjydb.view_tms_contract_payment tcp
                            left join hfjydb.view_tms_contract tc on tc.contract_id = tcp.contract_id 
                            left join hfjydb.view_user_info ui on ui.user_id = tc.submit_user_id 
                            inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tc.submit_user_id
                                       and cdme.stats_date=curdate() and cdme.class = 'CC'
                                       and cdme.date>=date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')  
                            where tcp.pay_status in (2,4) 
                                  and tc.status <> 8  -- 剔除合同终止和废弃
                                  and ui.account_type = 1  -- 剔除测试数据
                            group by tcp.contract_id
                            having real_pay_sum>=contract_amount 
                                   and date(max_pay_date)=date_sub(curdate(),interval 1 day)
                                    ) as a
            group by a.submit_user_id
            ) as t2 on t2.submit_user_id=t1.user_id