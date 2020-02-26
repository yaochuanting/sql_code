select  case when t.coil like '%转介绍%' or t.coil like '%推荐%' or t.know_origin like '%转介绍%' or t.know_origin like '%推荐%'
            then '转介绍' else '非转介绍' end as 渠道,
        t.class,
        sum(t.real_pay_sum) as 总金额,
        count(t.contract_id) as 总订单数,
        case when year(t.last_pay_date)=2019 then '2019年订单'
             when year(t.last_pay_date)=2020 and month(t.last_pay_date)=1 then '2020年1月订单'
             when year(t.last_pay_date)=2020 and t.last_pay_date<'2020-02-03' then '2020年2月订单'
        else '其他' end as 时间段


from(

      select
          min(tcp.pay_date) min_pay_date,
          max(tcp.pay_date) last_pay_date,
          s.submit_time,
          tcp.contract_id,
          cdme.class,
          cdme.department_name,
          (select dd.value from ddic dd where s.coil_in=dd.code and dd.type='TP023') coil,
          (select dd.value from ddic dd where s.know_origin=dd.code and dd.type='TP016') know_origin,
          sum(tcp.sum)/100 real_pay_sum,
          (tc.sum-666)*10 contract_amount
      from view_tms_contract_payment tcp
      left join view_tms_contract tc on tcp.contract_id  = tc.contract_id
      left join view_student s on s.student_intention_id = tc.student_intention_id
      left join view_user_info ui on ui.user_id = tc.submit_user_id
      left join bidata.charlie_dept_month_end cdme on cdme.user_id = tc.submit_user_id
                and cdme.stats_date = '2020-02-02'
      where tcp.pay_status in (2,4)
            and ui.account_type = 1
      group by tcp.contract_id
      having real_pay_sum >= contract_amount
      ) as t

where t.last_pay_date >= '2019-01-01'
group by 时间段,渠道,class