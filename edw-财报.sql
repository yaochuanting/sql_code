select 
          t1.last_pay_year as `年份`,
          t1.last_pay_month as `月份`,
          t1.class as `部门架构`,
          t1.type as `新签续费`,
          t3.orders as `订单指标`,
          t1.order_num `完成订单数`,
          concat(round(t1.order_num/t3.orders*100,2),'%') as `订单完标率`,
          t1.order_amount as `总订单额`,
          t3.amounts as `交易流水指标`,
          t2.transaction_flow as `完成交易流水`,
          concat(round(t2.transaction_flow/t3.amounts*100,2),'%') as `交易流水完标率`


from (
          select  month(a.last_pay_date) last_pay_month,
                  year(a.last_pay_date) last_pay_year,
                  a.class,
                  case when a.new_sign=0 and a.class='CR' then '续费' else '新签' end as type,
                  sum(case when a.period>0 then 1 else 0 end) as order_num,
                  sum(case when a.period>=60 then 1 else 0.5 end) as k_order_num,
                  sum(real_pay_sum) as order_amount

          -- 总订单量、订单额
          from(
                  select
                            max(tcp.pay_date) last_pay_date,
                            tcp.contract_id,
                            avg(tc.period) period,  
                            avg(tc.new_sign) new_sign,
                            cdme.class,
                            avg((tc.sum-666)*10) contract_amount,
                            sum(tcp.sum/100) real_pay_sum

                  from dw_hf_mobdb.dw_view_tms_contract_payment tcp
                  left join dw_hf_mobdb.dw_view_tms_contract tc on tcp.contract_id  = tc.contract_id
                  inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id = tc.submit_user_id
                             and to_date(cdme.stats_date)='${analyse_date}' 
                  left join dw_hf_mobdb.dw_view_user_info ui on ui.user_id = tc.submit_user_id
                  where tcp.pay_status in (2,4) and tc.status<>8 and ui.account_type = 1
                  group by tcp.contract_id, cdme.class
                  having round(sum(tcp.sum/100))>=round(avg((tc.sum-666)*10))
                         and to_date(max(tcp.pay_date))>='2020-01-01'
                         and to_date(max(tcp.pay_date))<='${analyse_date}'
                         ) as a
          group by month(a.last_pay_date), a.class, case when a.new_sign=0 and a.class='CR' then '续费' else '新签' end
          ) as t1

-- 交易流水
left join (
              select
                        month(tcp.pay_date) pay_month,
                        cdme.class,  
                        case when tc.new_sign=0 and cdme.class='CR' then '续费' else '新签' end type,
                        sum(tcp.sum/100) as transaction_flow
              from dw_hf_mobdb.dw_view_tms_contract_payment tcp
              left join dw_hf_mobdb.dw_view_tms_contract tc on tcp.contract_id=tc.contract_id
              inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id=tc.submit_user_id
                         and cdme.stats_date='${analyse_date}'
              left join dw_hf_mobdb.dw_view_user_info ui on ui.user_id=tc.submit_user_id
              where tcp.pay_status in (2,4) and tc.status<>8 and ui.account_type=1
                    and to_date(tcp.pay_date)>='2020-01-01'
                    and to_date(tcp.pay_date)<='${analyse_date}'
              group by month(tcp.pay_date), cdme.class, case when tc.new_sign=0 and cdme.class='CR' then '续费' else '新签' end
              ) as t2 on t2.pay_month=t1.last_pay_month 
                         and t2.class=t1.class and t2.type=t1.type

left join hf_mobdb.load_target t3 on t3.month=t1.last_pay_month and t3.class=t1.class and t3.type=t1.type