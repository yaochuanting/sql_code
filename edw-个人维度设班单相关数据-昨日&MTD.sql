select 
          cdme.user_id,cdme.name,cdme.job_number,cdme.department_name,
          if(t1.yes_apply is null, 0, t1.yes_apply) as yes_apply,
          if(t1.total_apply is null, 0, t1.total_apply) as total_apply,
          if(t2.yes_plan is null, 0, t2.yes_plan) as yes_plan,
          if(t2.total_plan is null, 0, t2.total_plan) as total_plan,
          if(t2.yes_trial is null, 0, t2.yes_trial) as yes_trial,
          if(t2.total_trial is null, 0, t2.total_trial) as total_trial,
          if(t2.yes_trial_deal is null, 0, t2.yes_trial_deal) as yes_trial_deal,
          if(t2.total_trial_deal is null, 0, t2.total_trial_deal) as total_trial_deal

from dt_mobdb.dt_charlie_dept_month_end cdme
left join(
            select  
                    lpo.apply_user_id, cdme.name, cdme.job_number, cdme.department_name,
                    count(distinct case when to_date(lpo.apply_time)='${analyse_date}' then lpo.student_intention_id end) as yes_apply,
                    count(distinct lpo.student_intention_id) as total_apply
      			from dw_hf_mobdb.dw_lesson_plan_order lpo
      			left join dw_hf_mobdb.dw_lesson_relation lr on lpo.order_id = lr.order_id
      			left join dw_hf_mobdb.dw_lesson_plan lp on lr.plan_id = lp.lesson_plan_id
      			left join dw_hf_mobdb.dw_view_student s on s.student_intention_id = lpo.student_intention_id
      			inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id = lpo.apply_user_id 
        					     and cdme.stats_date = '${analyse_date}' and cdme.class = 'CC'
        					     and to_date(cdme.`date`) >= trunc('${analyse_date}','MM')
      			where lp.lesson_type = 2
                  and to_date(lpo.apply_time) >= trunc('${analyse_date}','MM')
                  and to_date(lpo.apply_time) <= '${analyse_date}'
        				  and s.account_type = 1
      			group by lpo.apply_user_id, cdme.name, cdme.job_number, cdme.department_name
            ) t1 on cdme.user_id = t1.apply_user_id


-- 试听邀约、出席、成单
left join(
            select 
                   bb.apply_user_id,
                   count(distinct case when to_date(bb.adjust_start_time)='${analyse_date}' then bb.student_intention_id end) as yes_plan,
                   count(distinct bb.student_intention_id) as total_plan,
                   count(distinct case when to_date(bb.adjust_start_time)='${analyse_date}' and bb.is_trial = 1 then bb.student_intention_id end) as yes_trial,
                   count(distinct case when bb.is_trial = 1 then bb.student_intention_id end) as total_trial,
                   count(distinct case when date(bb.max_date )='${analyse_date}' and bb.is_trial_deal = 1 then bb.student_intention_id end) as yes_trial_deal,
                   count(distinct case when bb.is_trial_deal = 1 then bb.student_intention_id end) as total_trial_deal
            from(
                   select
                         lpo.student_intention_id,
                         lp.adjust_start_time,
                         lpo.apply_user_id,
                         cdme.department_name,
                         avg(case when lp.status in (3,5) and  lp.solve_status <> 6 then 1 else 0 end) is_trial,
                         avg(case when aa.student_intention_id is not null then 1 else 0 end) is_trial_deal,
                         aa.max_date                
                    from dw_hf_mobdb.dw_lesson_plan_order lpo
                    left join dw_hf_mobdb.dw_lesson_relation lr on lpo.order_id = lr.order_id
                    left join dw_hf_mobdb.dw_lesson_plan lp on lr.plan_id = lp.lesson_plan_id
                    left join dw_hf_mobdb.dw_view_student s on s.student_intention_id = lpo.student_intention_id
                    inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id = lpo.apply_user_id 
              			           and cdme.stats_date = '${analyse_date}' and cdme.class = 'CC'	
                               and to_date(cdme.`date`) >= trunc('${analyse_date}','MM')
                    left join (
                                  select  max(tcp.pay_date) max_date,
                                          tc.contract_id,
                                          tc.student_intention_id,
                                          sum(tcp.sum/100) real_pay_amount,
                                          avg((tc.sum-666)*10) contract_amount,
                                          tcp.submit_user_id
                                  from dw_hf_mobdb.dw_view_tms_contract_payment tcp
                                  left join dw_hf_mobdb.dw_view_tms_contract tc on tc.contract_id = tcp.contract_id
                                  where tcp.pay_status in (2, 4) and tc.status <> 8
                                  group by tc.contract_id, tc.student_intention_id, tcp.submit_user_id
                                  having to_date(max(tcp.pay_date)) >= trunc('${analyse_date}','MM')
                                         and to_date(max(tcp.pay_date)) <= '${analyse_date}'
                                         and round(sum(tcp.sum/100),0) >= round(avg((tc.sum-666)*10),0)
                                         ) as aa on aa.student_intention_id = lpo.student_intention_id 
                                                    and aa.submit_user_id = lpo.apply_user_id                                                               
                      where lp.lesson_type = 2
                            and to_date(lp.adjust_start_time) >= trunc('${analyse_date}','MM')
                            and to_date(lp.adjust_start_time) <= '${analyse_date}'
                            and s.account_type = 1
                      group by lpo.apply_user_id, lpo.student_intention_id, lp.adjust_start_time, cdme.department_name, aa.max_date 
                      ) bb
            group by bb.apply_user_id
            ) as t2 on cdme.user_id = t2.apply_user_id
where cdme.stats_date = '${analyse_date}' and cdme.department_name like  '%CC%'	and (cdme.`date`) >= trunc('${analyse_date}','MM')