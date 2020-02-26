-- 粒子数
select 
          count(distinct intention_id) all_keys, -- 获取的总线索量
          count(distinct case when date(s.submit_time) >= '2020-02-01'
                              then intention_id end) new_keys -- 获取的新线索量
									 
from
   (
       select tpel.track_userid, tpel.intention_id, tpel.into_pool_date, ui.name distri_user
       from hfjydb.tms_pool_exchange_log tpel
       inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tpel.track_userid
                and cdme.stats_date = curdate() and cdme.class = '销售'
       left join hfjydb.view_user_info ui on ui.user_id = tpel.create_userid
       where date(tpel.into_pool_date) >= '2020-02-01'
           and date(tpel.into_pool_date) <= '2020-02-11'
       union all
       select tnn.user_id as track_userid, tnn.student_intention_id as intention_id, tnn.create_time as into_pool_date, 'OC分配账号' distri_user
       from hfjydb.tms_new_name_get_log tnn
       inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tnn.user_id
                and cdme.stats_date = curdate() and cdme.class = '销售'
       where date(tnn.create_time) >= '2020-02-01'
           and date(tnn.create_time) <= '2020-02-11'
           and student_intention_id <> 0
) as a							 

left join hfjydb.view_student s on s.student_intention_id = a.intention_id;



-- 邀约数
select

      count(distinct b.student_intention_id) all_plan_num, -- 总试听邀约量
      count(distinct(case when b.key_attr = 'new' then b.student_intention_id else null end)) new_plan_num, -- 新线索试听邀约量
      count(distinct(case when b.is_trial = 1 then b.student_intention_id else null end)) all_trial_num, -- 总试听出席量
      count(distinct(case when b.key_attr = 'new' and b.is_trial = 1 then b.student_intention_id else null end)) new_trial_num, -- 新线索试听出席量
      count(distinct(case when b.is_trial_deal = 1 then b.student_intention_id else null end)) all_trial_deal, -- 总试听成单量
      count(distinct(case when b.key_attr = 'new' and b.is_trial_deal = 1 then b.student_intention_id else null end)) new_trial_deal -- 新线索试听成单量
    
from(    
        select
               lpo.apply_user_id, lpo.student_intention_id, s.student_no,
               (case when lp.status in (3,5) and lp.solve_status <> 6 then 1 else 0 end) is_trial,
               (case when s.submit_time >= '2020-02-01' then 'new' else 'all_oc' end) key_attr,
               (case when aa.real_pay_amount > 0 then 1 else 0 end) is_trial_deal              
        from hfjydb.lesson_plan_order lpo
        left join hfjydb.lesson_relation lr on lpo.order_id = lr.order_id
        left join hfjydb.lesson_plan lp on lr.plan_id = lp.lesson_plan_id
        left join hfjydb.view_student s on s.student_intention_id = lpo.student_intention_id
        inner join bidata.charlie_dept_month_end cdme on cdme.user_id = lpo.apply_user_id 
             and cdme.stats_date = curdate() and cdme.class = '销售'
        left join (
                      select min(tcp.pay_date) min_date,
                             tc.contract_id,
                             tc.student_intention_id,
                             sum(tcp.sum/100) real_pay_amount,
                             (tc.sum-666) * 10 contract_amount,
                             tcp.submit_user_id
                      from hfjydb.view_tms_contract_payment tcp
                      left join hfjydb.view_tms_contract tc on tc.contract_id = tcp.contract_id
                      inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tcp.submit_user_id
                             and cdme.stats_date = curdate() and cdme.class = '销售'
                      where tcp.pay_status in (2, 4)
                            and tc.status <> 8
                      group by tc.contract_id
                      having date(max(tcp.pay_date)) >= '2020-02-01'
                             and date(max(tcp.pay_date)) <= '2020-02-11'
                             and real_pay_amount >= contract_amount
               ) as aa on aa.student_intention_id = lpo.student_intention_id
        where lp.lesson_type = 2
        and date(lp.adjust_start_time) >= '2020-02-01'
        and date(lp.adjust_start_time) <= '2020-02-11'
        and s.account_type = 1
        ) as b;