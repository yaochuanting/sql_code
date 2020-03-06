select t1.*, t2.new_req, t2.all_oc_req,
       t3.new_keys, t3.alll_oc_keys, t3.new_rec_keys,
       t4.new_plan, t4.all_oc_plan, t4.new_rec_plan,
       t4.new_plan_exp, t4.all_oc_plan_exp, t4.new_rec_plan_exp,
       t4.new_trial, t4.all_oc_trial, t4.new_rec_trial,
       t4.new_trial_deal, t4.all_oc_trial_deal, t4.new_rec_trial_deal,
       t5.new_deal_num, t5.all_oc_deal_num, t5.new_rec_deal_num,
       t5.new_deal_amount, t5.all_oc_deal_amount, t5.new_rec_deal_amount

       
from(                            
                select cd.date, cd.user_id, cdme.job_number, cdme.name, cdme.department_name, cdme.center, cdme.region,cdme.department,
                       concat(ifnull(cdme.city,''),ifnull(cdme.branch,''),ifnull(cdme.center,''),ifnull(cdme.region,'')) as region_name,
                       date(min(crl.opt_time)) as login_time
                from bidata.charlie_dept_history cd
                left join view_user_info ui on ui.user_id = cd.user_id
                LEFT JOIN sys_change_role_log crl on crl.user_id=cd.user_id
                inner join bidata.charlie_dept_month_end cdme on cdme.user_id = cd.user_id
                           and cdme.class = 'CC' and cdme.stats_date = curdate()
                           and cdme.date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
                where (cd.department_name like 'CC%')
                       and cd.date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
                       and cd.date < curdate()
                group by cd.date, cd.user_id, cdme.job_number, cdme.name, cdme.department_name
                        ) as t1

left join (
                select  aa.date,
                        aa.user_id,
                        count(case when aa.key_attr = 'new' then aa.student_intention_id else null end) as new_req,
                        count(case when aa.key_attr = 'all_oc' then aa.student_intention_id else null end) as all_oc_req

                from(
                        select  min(date(view_time)) as date,
                                ss.user_id,
                                ss.student_intention_id,
                                case when s.submit_time >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
                                then 'new' else 'all_oc' end as key_attr,
                                case when s.coil_in in (13,22) or s.know_origin in (56,71,22,24,25,41) then 1 else 0 end as is_rec
                        from hfjydb.ss_collection_sale_roster_action ss
                        left join hfjydb.view_student s on s.student_intention_id = ss.student_intention_id
                        where view_time >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
                                and view_time < curdate()
                        group by user_id, ss.student_intention_id
                        ) as aa
                group by aa.date, aa.user_id
                ) as t2 on t2.date = t1.date and t2.user_id = t1.user_id

left join (
                select  aa.date,
                        aa.track_userid as user_id,
                        count(case when aa.key_attr = 'new' then aa.intention_id else null end) as new_keys,
                        count(case when aa.key_attr = 'all_oc' then aa.intention_id else null end) as alll_oc_keys,
                        count(case when aa.key_attr = 'new' and aa.is_rec = 1 then aa.intention_id else null end) as new_rec_keys
                from(

                        select min(date(into_pool_date)) as date,
                        tpel.track_userid,
                        tpel.intention_id,
                        case when s.submit_time >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
                             then 'new' else 'all_oc' end as key_attr,
                        case when s.coil_in in (13,22) or s.know_origin in (56,71,22,24,25,41) then 1 else 0 end as is_rec


                        from hfjydb.tms_pool_exchange_log tpel
                        left join hfjydb.view_student s on s.student_intention_id = tpel.intention_id
                        where tpel.into_pool_date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
                        and tpel.into_pool_date < curdate()
                        group by tpel.intention_id, tpel.track_userid
                        ) as aa
                group by aa.date, aa.track_userid
                ) as t3 on t3.date = t1.date and t3.user_id = t1.user_id

left join (
                select 
                                bb.date,
                                bb.apply_user_id as user_id,
                                count(case when bb.key_attr = 'new' then bb.student_intention_id end) as new_plan,
                                count(case when bb.key_attr = 'all_oc' then bb.student_intention_id end) as all_oc_plan,
                                count(case when bb.key_attr = 'new' and bb.is_rec = 1 then bb.student_intention_id end) as new_rec_plan,
                                count(case when bb.key_attr = 'new' and bb.is_trial_exp = 1 then bb.student_intention_id end) as new_plan_exp,
                                count(case when bb.key_attr = 'all_oc' and bb.is_trial_exp = 1 then bb.student_intention_id end) as all_oc_plan_exp,
                                count(case when bb.key_attr = 'new' and bb.is_rec =1 and bb.is_trial_exp = 1 then bb.student_intention_id end) as new_rec_plan_exp,
                                count(case when bb.key_attr = 'new' and bb.is_trial = 1 then bb.student_intention_id end) as new_trial,
                                count(case when bb.key_attr = 'all_oc' and bb.is_trial = 1 then bb.student_intention_id end) as all_oc_trial,
                                count(case when bb.key_attr = 'new' and bb.is_rec = 1 and bb.is_trial = 1 then bb.student_intention_id end) as new_rec_trial,
                                count(case when bb.key_attr = 'new' and bb.is_trial_deal = 1 then bb.student_intention_id end) as new_trial_deal,
                                count(case when bb.key_attr = 'all_oc' and bb.is_trial_deal = 1 then bb.student_intention_id end) as all_oc_trial_deal,
                                count(case when bb.key_attr = 'new' and bb.is_trial_deal = 1 and bb.is_rec = 1 then bb.student_intention_id end) as new_rec_trial_deal



                from(
                        select
                                lpo.apply_user_id, lpo.student_intention_id,
                                min(date(lp.adjust_start_time)) as date,
                                case when lp.status in (3,5) then 1 else 0 end is_trial,
                                case when s.submit_time >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01') 
                                        then 'new' else 'all_oc' end key_attr,
                                case when s.coil_in in (13,22) or s.know_origin in (56,71,22,24,25,41)  then 1 else 0 end is_rec,
                                case when aa.student_intention_id is not null then 1 else 0 end is_trial_deal,
                                (case when lp.student_id in (select distinct student_id
                                                             from hfjydb.lesson_plan  
                                                             where lesson_type=3 and status in (3,5) and solve_status <> 6 
                                                                    and adjust_start_time >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
                                                                    and adjust_start_time < curdate()
                                                                    )
                                      then 1 else 0 end) is_trial_exp,          
                                aa.real_pay_amount                
                        from hfjydb.lesson_plan_order lpo
                        left join hfjydb.lesson_relation lr on lpo.order_id = lr.order_id
                        left join hfjydb.lesson_plan lp on lr.plan_id = lp.lesson_plan_id
                        left join hfjydb.view_student s on s.student_intention_id = lpo.student_intention_id
                        left join (
                                        select  min(tcp.pay_date) min_date,
                                                tc.contract_id,
                                                tc.student_intention_id,
                                                sum(tcp.sum/100) real_pay_amount,
                                                (tc.sum-666) * 10 contract_amount,
                                                tcp.submit_user_id
                                        from hfjydb.view_tms_contract_payment tcp
                                        left join hfjydb.view_tms_contract tc on tc.contract_id = tcp.contract_id
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
                        group by lpo.apply_user_id, lpo.student_intention_id
                        ) as bb 
                group by bb.date, bb.apply_user_id
                ) as t4 on t4.user_id = t1.user_id and t4.date = t1.date

left join (
                select  date(c.max_date) as date,
                        c.submit_user_id as user_id,
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
                                        and cdme.stats_date = curdate() and cdme.class = 'CC'
                                        and cdme.date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
                        where tcp.pay_status in (2,4) and tc.status <> 8
                        group by tc.contract_id
                        having max(tcp.pay_date) >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
                                and max(tcp.pay_date) < curdate()
                                and real_pay_amount >= contract_amount
                        ) as c
                group by date(c.max_date), c.submit_user_id
                ) as t5 on t5.user_id = t1.user_id and t5.date = t1.date