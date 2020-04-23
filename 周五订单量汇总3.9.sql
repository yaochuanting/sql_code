select t.week_of_year,
       t.day_of_week,
       count(t.contract_id) as order_num,
       sum(t.contract_amount) as order_amount

from (

        select  
                tcp.contract_id,
                tc.submit_user_id,
                max(tcp.pay_date) as max_pay_date,
                weekofyear(max(tcp.pay_date)) as week_of_year,
                date_format(max(tcp.pay_date),'%W') as day_of_week,
                sum(tcp.sum/100) real_pay_sum, 
                (tc.sum-666)*10 contract_amount

        from hfjydb.view_tms_contract_payment tcp
        left join hfjydb.view_tms_contract tc on tc.contract_id = tcp.contract_id 
        left join hfjydb.view_user_info ui on ui.user_id = tc.submit_user_id 
        inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tc.submit_user_id
                   and cdme.stats_date=curdate() and (cdme.class = 'CC' or cdme.class='销售')
                   and cdme.date>='2020-01-01' 
        where tcp.pay_status in (2,4) 
              and tc.status<>8  -- 剔除合同终止和废弃
              and ui.account_type = 1  -- 剔除测试数据
        group by tcp.contract_id
        having real_pay_sum>=contract_amount 
               and date(max_pay_date)>='2020-01-01'
               ) as t

group by t.week_of_year, t.day_of_week