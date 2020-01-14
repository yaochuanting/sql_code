select  date_sub(curdate(),interval 1 day) as stats_date,
        key_attr,
        count(a.contract_id) as order_num

from(
        select  max(tcp.pay_date) as max_pay_date,
                tc.contract_id,
                case when s.submit_time >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01') then 'new'
                     when s.submit_time >= date_sub(date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01'),interval 1 month) then 'sec_new'
                else 'oc' end as key_attr,
                sum(tcp.sum/100) real_pay_sum, 
                (tc.sum-666)*10 contract_amount
        from hfjydb.view_tms_contract_payment tcp
        left join hfjydb.view_tms_contract tc on tc.contract_id = tcp.contract_id 
        left join hfjydb.view_user_info ui on ui.user_id = tc.submit_user_id 
        left join view_student s on s.student_intention_id = tc.student_intention_id
        inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tc.submit_user_id
                   and cdme.stats_date = curdate() and cdme.class = '销售'    
        where tcp.pay_status in (2,4) 
              and tc.status <> 8  -- 剔除合同终止和废弃
              and ui.account_type = 1  -- 剔除测试数据
        group by tcp.contract_id
        having real_pay_sum >= contract_amount 
               and date(max_pay_date) >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
               and date(max_pay_date) <= date_sub(curdate(),interval 1 day)
               ) as a
group by stats_date, key_attr
