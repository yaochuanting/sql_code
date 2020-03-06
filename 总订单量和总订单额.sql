select  a.class as '部门',
        date(a.last_pay_date) '完款日期',
        case when a.new_sign=0 and a.class='CR' then '续费' else '新签' end as '新签/续费',
        sum(case when a.period > 0 then 1 else 0 end) as '实际订单数',
        sum(case when a.period >= 60 then 1 else 0.5 end) as '绩效订单数',
        sum(contract_amount) as '总订单额'

from(
        select
            max(tcp.pay_date) last_pay_date,
            tcp.contract_id,
            tc.period,  
            tc.new_sign,
            cdme.class,
            (tc.sum-666)*10 contract_amount,
            sum(tcp.sum)/100 real_pay_sum

        from hfjydb.view_tms_contract_payment tcp
        left join hfjydb.view_tms_contract tc on tcp.contract_id  = tc.contract_id
        inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tc.submit_user_id
                   and cdme.stats_date = curdate() and cdme.date >= date_format(curdate(),'%Y-%m-01')
        left join hfjydb.view_user_info ui on ui.user_id = tc.submit_user_id
        where tcp.pay_status in (2,4)
              and  tc.status <> 8
              and ui.account_type = 1
        group by tcp.contract_id
        having real_pay_sum >= contract_amount
               and date(last_pay_date) >= '2020-01-01'
               and date(last_pay_date) <= curdate()
        ) as a
group by a.class,date(a.last_pay_date),case when a.new_sign=0 and a.class='学管' then '续费' else '新签' end