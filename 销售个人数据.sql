-- 销售信息
select cd.date, cd.user_id, ui.job_number, ui.`name`, cd.department_name, cd.city, cd.branch, cd.center, cd.region, cd.department, cd.grp
from bidata.charlie_dept_history cd
left join view_user_info ui on ui.user_id = cd.user_id
where (cd.department_name like '%销售_区%' or cd.department_name like '销售考核_组')
        and cd.date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
        and cd.date < curdate();


-- 触碰线索量
select date(view_time) as date,
       ss.user_id,
       count(distinct case when s.submit_time >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
                           then ss.student_intention_id else null end) as new_req,
       count(distinct case when s.submit_time < date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
                           then ss.student_intention_id else null end) as all_oc_req
from hfjydb.ss_collection_sale_roster_action ss
left join hfjydb.view_student s on s.student_intention_id = ss.student_intention_id
where view_time >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
      and view_time < curdate()
group by date, user_id


-- 获取线索量
select date(into_pool_date) as date,
       tpel.track_userid,
       count(distinct case when s.submit_time >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
                           then tpel.intention_id else null end) as new_keys,
       count(distinct case when s.submit_time < date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
                           then tpel.intention_id else null end) as all_oc_keys,
       count(distinct case when s.submit_time >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
                                and (s.coil_in in (13,22) or s.know_origin in (56,71,22,24,25,41))
                           then tpel.intention_id else null end) as new_rec_keys
from hfjydb.tms_pool_exchange_log tpel
left join hfjydb.view_student s on s.student_intention_id = tpel.intention_id
where tpel.into_pool_date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
      and tpel.into_pool_date < curdate()
group by date, tpel.track_userid


-- 邀约
select  date,
        b.apply_user_id,
        count(distinct case when b.key_attr = 'new' then b.student_intention_id else null end) as new_plan,
        count(distinct case when b.key_attr = 'new' and b.is_trial = 1 then b.student_intention_id else null end) as new_trial,
        count(distinct case when b.key_attr = 'new' and b.is_trial_exp = 1 then b.student_intention_id else null end) as new_trial_exp,
        count(distinct case when b.key_attr = 'new' and b.is_trial = 1 and b.is_trial_deal = 1 then b.student_intention_id else null end) as new_trial_deal,
        count(distinct case when b.key_attr = 'all_oc' then b.student_intention_id else null end) as all_oc_plan,
        count(distinct case when b.key_attr = 'all_oc' and b.is_trial = 1 then b.student_intention_id else null end) as all_oc_trial,
        count(distinct case when b.key_attr = 'all_oc' and b.is_trial_exp = 1 then b.student_intention_id else null end) as all_oc_trial_exp,
        count(distinct case when b.key_attr = 'all_oc' and b.is_trial_deal = 1 then b.student_intention_id else null end) as all_oc_trial_deal,
        count(distinct case when b.is_recommend = 1 and b.key_attr = 'new' then b.student_intention_id else null end) as new_rec_plan,           
        count(distinct case when b.is_recommend = 1 and b.key_attr = 'new' and b.is_trial = 1 then b.student_intention_id else null end) as new_rec_trial,
        count(distinct case when b.is_recommend = 1 and b.key_attr = 'new' and b.is_trial_exp = 1 then b.student_intention_id else null end) as new_rec_trial_exp, 
        count(distinct case when b.is_recommend = 1 and b.key_attr = 'new' and b.is_trial_deal = 1 then b.student_intention_id else null end) as new_rec_trial_deal                     
            
from(           
            select
                        lpo.apply_user_id, lpo.student_intention_id,
                        date(lp.adjust_start_time) as date,
                        (case when lp.status in (3,5) and lp.solve_status <> 6 then 1 else 0 end) is_trial,
                        (case when s.submit_time >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01') then 'new' else 'all_oc' end) key_attr,
                        (case when s.coil_in in (13,22) or s.know_origin in (56,71,22,24,25,41)  then 1 else 0 end) is_recommend,
                        (case when aa.real_pay_amount > 0 then 1 else 0 end) is_trial_deal,
                        (case when lp.student_id in (select distinct student_id
                                                    from hfjydb.lesson_plan  
                                                    where lesson_type=3 and status in (3,5) and solve_status <> 6 
                                                        and adjust_start_time >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
                                                        and adjust_start_time < curdate()
                                                        )
                            then 1 else 0 end) is_trial_exp			  			  
            from hfjydb.lesson_plan_order lpo
            left join hfjydb.lesson_relation lr on lpo.order_id = lr.order_id
            left join hfjydb.lesson_plan lp on lr.plan_id = lp.lesson_plan_id
            left join hfjydb.view_student s on s.student_intention_id = lpo.student_intention_id
            inner join bidata.charlie_dept_month_end cdme on cdme.user_id = lpo.apply_user_id 
                    and cdme.stats_date = curdate() and cdme.class = '销售'
                    and cdme.date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
            left join (
                            select  min(tcp.pay_date) min_date,
                                    tc.contract_id,
                                    tc.student_intention_id,
                                    sum(tcp.sum/100) real_pay_amount,
                                    (tc.sum-666) * 10 contract_amount,
                                    tcp.submit_user_id
                            from hfjydb.view_tms_contract_payment tcp
                            left join hfjydb.view_tms_contract tc on tc.contract_id = tcp.contract_id
                            inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tcp.submit_user_id
                                        and cdme.stats_date = curdate() and cdme.class = '销售'
                                        and cdme.date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
                            where tcp.pay_status in (2, 4) and tc.status <> 8
                            group by tc.contract_id
                            having max(tcp.pay_date) >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
                                    and max(tcp.pay_date) < curdate()
                                    and real_pay_amount >= contract_amount
                                    ) as aa on aa.student_intention_id = lpo.student_intention_id
                                                and aa.submit_user_id = lpo.apply_user_id
                                                
            where lp.lesson_type = 2
                    and lp.adjust_start_time >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
                    and lp.adjust_start_time < curdate()
                    and s.account_type = 1
                    and lp.solve_status <> 6
                    ) as b
group by b.date, b.apply_user_id



select  c.max_date as date,
        c.submit_user_id,
        count(distinct case when c.key_attr = 'new' then c.contract_id else null end) as new_deal_num,
        sum(case when c.key_attr = 'new' then c.real_pay_amount else 0 end) as new_deal_amount,
        count(distinct case when c.key_attr = 'all_oc' then c.contract_id else null end) as all_oc_deal_num,
        sum(case when c.key_attr = 'all_oc' then c.real_pay_amount else 0 end) as all_oc_deal_amount,
        count(distinct case when c.key_attr = 'new' and c.is_recommend = 1 then c.contract_id else null end) as new_rec_deal_num,
        sum(distinct case when c.key_attr = 'new' and c.is_recommend = 1 then c.real_pay_amount else 0 end) as new_rec_deal_amount
        
from(        
            select  min(tcp.pay_date) min_date,
                    max(tcp.pay_date) max_date,
                    tc.contract_id,
                    tc.student_intention_id,
                    case when s.submit_time >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
                         then 'new' else 'all_oc' end as key_attr,
                    case when s.coil_in in (13,22) or s.know_origin in (56,71,22,24,25,41) then 1 else 0 end as is_recommend,
                    sum(tcp.sum/100) real_pay_amount,
                    (tc.sum-666) * 10 contract_amount,
                    tcp.submit_user_id
            from hfjydb.view_tms_contract_payment tcp
            left join hfjydb.view_tms_contract tc on tc.contract_id = tcp.contract_id
            left join hfjydb.view_student s on s.student_intention_id = tc.student_intention_id
            inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tcp.submit_user_id
                        and cdme.stats_date = curdate() and cdme.class = '销售'
                        and cdme.date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
            where tcp.pay_status in (2,4) and tc.status <> 8
            group by tc.contract_id
            having max(tcp.pay_date) >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
                    and max(tcp.pay_date) < curdate()
                    and real_pay_amount >= contract_amount
            ) as c
group by c.max_date, c.submit_user_id