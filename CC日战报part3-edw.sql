-- 架构
select  cdme.center, 
        cdme.region,
        cdme.department,
        cdme.department_name
from dt_mobdb.dt_charlie_dept_month_end cdme 
where to_date(cdme.stats_date)='${analyse_date}'
    and cdme.class='CC' and cdme.department_name like 'CC%'
    and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')
group by cdme.center, cdme.region, cdme.department, cdme.department_name


-- 试听关单率
select b.department_name,
       count(distinct case when to_date(b.adjust_start_time)='${analyse_date}' then b.contract_id end)/count(distinct case when to_date(b.adjust_start_time)='${analyse_date}' then b.student_intention_id end) yes_trial_deal_rate,
       count(distinct case when to_date(b.adjust_start_time)>=date_sub('${analyse_date}',7) then b.contract_id end)/count(distinct case when to_date(b.adjust_start_time)>=date_sub('${analyse_date}',7) then b.student_intention_id end) rc7_trial_deal_rate,
       count(distinct case when to_date(b.adjust_start_time)>=date_sub('${analyse_date}',30) then b.contract_id end)/count(distinct case when to_date(b.adjust_start_time)>=date_sub('${analyse_date}',30) then b.student_intention_id end) rc30_trial_deal_rate


from(
      select cdme.department_name, lpo.student_intention_id, lpo.apply_user_id, lp.adjust_start_time, a.max_date, a.contract_id
      from dw_hf_mobdb.dw_lesson_plan_order lpo
      left join dw_hf_mobdb.dw_lesson_relation lr on lpo.order_id = lr.order_id
      left join dw_hf_mobdb.dw_lesson_plan lp on lr.plan_id = lp.lesson_plan_id
      left join dw_hf_mobdb.dw_view_student s on s.student_intention_id = lpo.student_intention_id
      inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id = lpo.apply_user_id 
                 and to_date(cdme.stats_date)='${analyse_date}' and cdme.class = 'CC'
                 and to_date(cdme.`date`)>=date_sub('${analyse_date}',30)
      left join (
                    select max(tcp.pay_date) max_date,
                           tc.contract_id,
                           tc.student_intention_id,
                           sum(tcp.`sum`/100) real_pay_amount,
                           max((tc.`sum`-666)*10) contract_amount,
                           tcp.submit_user_id,
                           cdme.department_name

                    from dw_hf_mobdb.dw_view_tms_contract_payment tcp
                    left join dw_hf_mobdb.dw_view_tms_contract tc on tc.contract_id = tcp.contract_id
                    inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id = tcp.submit_user_id
                           and to_date(cdme.stats_date)='${analyse_date}' and cdme.class = 'CC'
                           and to_date(cdme.`date`)>=date_sub('${analyse_date}',30)
                    where tcp.pay_status in (2,4)
                        and tc.status<>8
                    group by tc.contract_id, cdme.department_name, tc.student_intention_id, tcp.submit_user_id
                    having max(tcp.pay_date)>=date_sub('${analyse_date}',30)
                         and max(tcp.pay_date)<='${analyse_date}'
                         and round(sum(tcp.`sum`/100),0)>=round(max((tc.`sum`-666)*10),0)
                         ) as a on a.student_intention_id=lpo.student_intention_id 
                                   and a.department_name=cdme.department_name

      where lp.lesson_type = 2
          and to_date(lpo.apply_time)>=date_sub('${analyse_date}',30)
          and to_date(lpo.apply_time)<='${analyse_date}'
          and lp.status in (3,5) and lp.solve_status <> 6
          and s.account_type = 1
          ) as b
group by b.department_name



-- 当月粒子数
select  c.department_name,
        count(case when to_date(s.create_time)>=trunc('${analyse_date}','MM') then c.intention_id end) tomonth_new_keys,
        count(case when to_date(s.create_time)<trunc('${analyse_date}','MM') then c.intention_id end) tomonth_oc_keys

from(
       select tpel.intention_id, cdme.department_name
       from dw_hf_mobdb.dw_tms_pool_exchange_log tpel
       inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id = tpel.track_userid
                  and to_date(cdme.stats_date)='${analyse_date}' and cdme.class = 'CC'
                  and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')
       where to_date(tpel.into_pool_date)>=trunc('${analyse_date}','MM')
             and to_date(tpel.into_pool_date)<='${analyse_date}'
       union all
       select tnn.student_intention_id, cdme.department_name
       from dw_hf_mobdb.dw_tms_new_name_get_log tnn
       inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id = tnn.user_id
                  and to_date(cdme.stats_date)='${analyse_date}' and cdme.class = 'CC'
                  and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')
       where to_date(tnn.create_time)>=trunc('${analyse_date}','MM')
             and to_date(tnn.create_time)<='${analyse_date}'
             and student_intention_id<>0
             ) as c
left join dw_hf_mobdb.dw_view_student s on s.student_intention_id=c.intention_id
group by c.department_name





-- 当月订单数
select d.department_name,
       count(case when d.is_new=1 then d.contract_id end) as new_order,
       count(case when d.is_new=0 then d.contract_id end) as oc_order

from(

      select max(tcp.pay_date) max_date,
             tc.contract_id,
             tc.student_intention_id,
             sum(tcp.`sum`/100) real_pay_amount,
             max((tc.`sum`-666)*10) contract_amount,
             tcp.submit_user_id,
             max(case when to_date(s.create_time)>=trunc('${analyse_date}','MM') then 1 else 0 end) is_new,
             cdme.department_name
      from dw_hf_mobdb.dw_view_tms_contract_payment tcp
      left join dw_hf_mobdb.dw_view_tms_contract tc on tc.contract_id=tcp.contract_id
      left join dw_hf_mobdb.dw_view_student s on s.student_intention_id=tc.student_intention_id
      inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id=tcp.submit_user_id
                 and to_date(cdme.stats_date)='${analyse_date}' and cdme.class='CC'
                 and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')
      where tcp.pay_status in (2,4) and tc.status<>8
      group by tc.contract_id, cdme.department_name, tc.student_intention_id, tcp.submit_user_id
      having max(tcp.pay_date)>=trunc('${analyse_date}','MM')
             and max(tcp.pay_date)<='${analyse_date}'
             and round(sum(tcp.`sum`/100),0)>=round(max((tc.`sum`-666)*10),0)
             ) as d 
group by d.department_name



-- 最近30天注册转化率
select f.department_name,
       count(distinct f.contract_id)/count(distinct f.intention_id) as rc30_order_rate


from(

      select tpel.intention_id, cdme.department_name, e.contract_id
      from dw_hf_mobdb.dw_tms_pool_exchange_log tpel
      left join dw_hf_mobdb.dw_view_student s on s.student_intention_id = tpel.intention_id
      inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id=tpel.track_userid
                 and to_date(cdme.stats_date)='${analyse_date}' and cdme.class='CC'
                 and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')
      left join (
                    select min(tcp.pay_date) min_date,
                           tc.contract_id,
                           tc.student_intention_id,
                           sum(tcp.`sum`/100) real_pay_amount,
                           max((tc.`sum`-666) * 10) contract_amount,
                           tcp.submit_user_id,
                           cdme.department_name
                    from hfjydb.view_tms_contract_payment tcp
                    left join hfjydb.view_tms_contract tc on tc.contract_id = tcp.contract_id
                    inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tcp.submit_user_id
                           and to_date(cdme.stats_date)='${analyse_date}' and cdme.class = 'CC'
                           and to_date(cdme.`date`)>=date_sub('${analyse_date}',interval 30 day)
                    where tcp.pay_status in (2,4)
                          and tc.status<>8
                    group by tc.contract_id, cdme.department_name, tc.student_intention_id, tcp.submit_user_id,
                    having max(tcp.pay_date)>=date_sub('${analyse_date}',interval 30 day)
                         and max(tcp.pay_date)<='${analyse_date}' 
                         and round(sum(tcp.`sum`/100),0)>=round(max((tc.`sum`-666) * 10),0)
                         ) as e on e.student_intention_id=tpel.intention_id
                                   and e.department_name=cdme.department_name

      where  to_date(s.create_time)>=date_sub('${analyse_date}',interval 30 day)
             and to_date(s.create_time)<='${analyse_date}'
      group by tpel.intention_id, cdme.department_name, e.contract_id
      ) as f
group by f.department_name
