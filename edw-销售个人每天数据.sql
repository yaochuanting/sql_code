select t1.`date`, t1.name, t1.user_id, t1.job_number, t1.login_time,
       t2.new_req, t2.all_oc_req,
       t3.new_keys, t3.all_oc_keys, t3.new_rec_keys, 
       t4.new_plan, t4.new_plan_exp, t4.new_trial, t4.new_trial_deal, t5.new_deal_num, t5.new_deal_amount,
       t4.all_oc_plan, t4.all_oc_plan_exp, t4.all_oc_trial, t4.all_oc_trial_deal, t5.all_oc_deal_num, t5.all_oc_deal_amount,
       t4.new_rec_plan, t4.new_rec_plan_exp, t4.new_rec_trial, t4.new_rec_trial_deal, t5.new_rec_deal_num, t5.new_rec_deal_amount,
       t1.department_name

       
from(                            
                select to_date(cd.`date`) `date`, cd.user_id, cdme.job_number, cdme.name, cdme.department_name,
                       to_date(min(crl.opt_time)) as login_time
                from dw_hf_mobdb.dw_charlie_dept_history cd
                left join dw_hf_mobdb.dw_view_user_info ui on ui.user_id = cd.user_id
                left join dw_hf_mobdb.dw_sys_change_role_log crl on crl.user_id=cd.user_id
                inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id = cd.user_id
                           and cdme.class = 'CC' and cdme.stats_date = '${analyse_date}'
                           and cdme.`date` >= trunc('${analyse_date}','MM')
                where (cd.department_name like 'CC%' or cd.department_name like '销售%')
                       and to_date(cd.`date`) >= trunc('${analyse_date}','MM')
                       and to_date(cd.`date`) <= '${analyse_date}'
                group by to_date(cd.`date`), cd.user_id, cdme.job_number, cdme.name, cdme.department_name
                ) as t1


left join (
                select  aa.`date`,
                        aa.user_id,
                        count(case when aa.is_new = 1 then aa.student_intention_id end) as new_req,
                        count(case when aa.is_new = 0 then aa.student_intention_id end) as all_oc_req

                from(
                        select  min(to_date(view_time)) as `date`,
                                ss.user_id,
                                ss.student_intention_id,
                                avg(case when to_date(s.create_time) >= trunc('${analyse_date}','MM') then 1 else 0 end) is_new
                        from dw_hf_mobdb.dw_ss_collection_sale_roster_action ss
                        left join dw_hf_mobdb.dw_view_student s on s.student_intention_id = ss.student_intention_id
                        where to_date(view_time) >= trunc('${analyse_date}','MM')
                                and to_date(view_time) <= '${analyse_date}'
                        group by user_id, ss.student_intention_id
                        ) as aa
                group by aa.`date`, aa.user_id
                ) as t2 on t2.`date` = t1.`date` and t2.user_id = t1.user_id



left join (
                select  aa.`date`,
                        aa.track_userid as user_id,
                        count(case when aa.is_new = 1 then aa.intention_id end) as new_keys,
                        count(case when aa.is_new = 0 then aa.intention_id end) as all_oc_keys,
                        count(case when aa.is_new = 1 and aa.is_rec = 1 then aa.intention_id end) as new_rec_keys
                from(

                        select  min(to_date(into_pool_date)) as `date`,
                                tpel.track_userid,
                                tpel.intention_id,
                                avg(case when to_date(s.create_time) >= trunc('${analyse_date}','MM') then 1 else 0 end) is_new,
                                avg(case when s.coil_in in (13,22) or s.know_origin in (56,71,22,24,25,41) then 1 else 0 end) is_rec


                        from dw_hf_mobdb.dw_tms_pool_exchange_log tpel
                        left join dw_hf_mobdb.dw_view_student s on s.student_intention_id = tpel.intention_id
                        where to_date(tpel.into_pool_date) >= trunc('${analyse_date}','MM')
                              and to_date(tpel.into_pool_date) <= '${analyse_date}'
                        group by tpel.intention_id, tpel.track_userid
                        ) as aa
                group by aa.`date`, aa.track_userid
                ) as t3 on t3.`date` = t1.`date` and t3.user_id = t1.user_id

left join (
            select 
                    bb.`date`,
                    bb.apply_user_id as user_id,
                    count(case when bb.is_new = 1 then bb.student_intention_id end) as new_plan,
                    count(case when bb.is_new = 0 then bb.student_intention_id end) as all_oc_plan,
                    count(case when bb.is_new = 1 and bb.is_rec = 1 then bb.student_intention_id end) as new_rec_plan,
                    count(case when bb.is_new = 1 and bb.is_trial_exp = 1 then bb.student_intention_id end) as new_plan_exp,
                    count(case when bb.is_new = 0 and bb.is_trial_exp = 1 then bb.student_intention_id end) as all_oc_plan_exp,
                    count(case when bb.is_new = 1 and bb.is_rec =1 and bb.is_trial_exp = 1 then bb.student_intention_id end) as new_rec_plan_exp,
                    count(case when bb.is_new = 1 and bb.is_trial = 1 then bb.student_intention_id end) as new_trial,
                    count(case when bb.is_new = 0 and bb.is_trial = 1 then bb.student_intention_id end) as all_oc_trial,
                    count(case when bb.is_new = 1 and bb.is_rec = 1 and bb.is_trial = 1 then bb.student_intention_id end) as new_rec_trial,
                    count(case when bb.is_new = 1 and bb.is_trial_deal = 1 then bb.student_intention_id end) as new_trial_deal,
                    count(case when bb.is_new = 0 and bb.is_trial_deal = 1 then bb.student_intention_id end) as all_oc_trial_deal,
                    count(case when bb.is_new = 1 and bb.is_trial_deal = 1 and bb.is_rec = 1 then bb.student_intention_id end) as new_rec_trial_deal



                from(
                        select
                                lpo.apply_user_id, lpo.student_intention_id,
                                min(to_date(lp.adjust_start_time)) as `date`,
                                avg(case when lp.status in (3,5) then 1 else 0 end) is_trial,
                                avg(case when to_date(s.create_time) >= trunc('${analyse_date}','MM') then 1 else 0 end) is_new,
                                avg(case when s.coil_in in (13,22) or s.know_origin in (56,71,22,24,25,41)  then 1 else 0 end) is_rec,
                                avg(case when aa.student_intention_id is not null then 1 else 0 end) is_trial_deal,
                                avg(case when lp2.student_id is not null then 1 else 0 end) is_trial_exp,          
                                avg(aa.real_pay_amount) real_pay_amount           
                        from dw_hf_mobdb.dw_lesson_plan_order lpo
                        left join dw_hf_mobdb.dw_lesson_relation lr on lpo.order_id = lr.order_id
                        left join dw_hf_mobdb.dw_lesson_plan lp on lr.plan_id = lp.lesson_plan_id
                        left join dw_hf_mobdb.dw_view_student s on s.student_intention_id = lpo.student_intention_id
                        left join dw_hf_mobdb.dw_lesson_plan lp2 on lp2.student_id = s.student_id and lp2.lesson_type = 3 
                                                                 and lp2.status in (3, 5) and lp2.solve_status <> 6
                        left join (
                                        select  min(tcp.pay_date) min_date,
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
                                and s.account_type = 1 and lp.solve_status <> 6
                        group by lpo.apply_user_id, lpo.student_intention_id
                        ) as bb 
                group by bb.`date`, bb.apply_user_id
                ) as t4 on t4.user_id = t1.user_id and t4.`date` = t1.`date`

left join (
                select  to_date(c.max_date) as `date`,
                        c.submit_user_id as user_id,
                        count(distinct case when c.is_new = 1 then c.contract_id end) as new_deal_num,
                        sum(case when c.is_new = 1 then c.real_pay_amount end) as new_deal_amount,
                        count(distinct case when c.is_new = 0 then c.contract_id end) as all_oc_deal_num,
                        sum(case when c.is_new = 0 then c.real_pay_amount end) as all_oc_deal_amount,
                        count(distinct case when c.is_new = 1 and c.is_rec = 1 then c.contract_id end) as new_rec_deal_num,
                        sum(distinct case when c.is_new = 1 and c.is_rec = 1 then c.real_pay_amount end) as new_rec_deal_amount
                        
                from(        
                        select  min(tcp.pay_date) min_date,
                                max(tcp.pay_date) max_date,
                                tc.contract_id,
                                tc.student_intention_id,
                                avg(case when to_date(s.create_time) >= trunc('${analyse_date}','MM') then 1 else 0 end) is_new,
                                avg(case when s.coil_in in (13,22) or s.know_origin in (56,71,22,24,25,41) then 1 else 0 end) is_rec,
                                sum(tcp.sum/100) real_pay_amount,
                                avg((tc.sum-666)*10) contract_amount,
                                tcp.submit_user_id
                        from dw_hf_mobdb.dw_view_tms_contract_payment tcp
                        left join dw_hf_mobdb.dw_view_tms_contract tc on tc.contract_id = tcp.contract_id
                        left join dw_hf_mobdb.dw_view_student s on s.student_intention_id = tc.student_intention_id
                        inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id = tcp.submit_user_id
                                   and cdme.stats_date = '${analyse_date}' and cdme.class = 'CC'
                                   and cdme.`date` >= trunc('${analyse_date}','MM')
                        where tcp.pay_status in (2,4) and tc.status <> 8
                        group by tc.contract_id, tc.student_intention_id, tcp.submit_user_id
                        having to_date(max(tcp.pay_date)) >= trunc('${analyse_date}','MM')
                                and to_date(max(tcp.pay_date)) <= '${analyse_date}'
                                and round(sum(tcp.sum/100),0) >= round(avg((tc.sum-666)*10),0)
                                ) as c
                group by to_date(c.max_date), c.submit_user_id
                ) as t5 on t5.user_id = t1.user_id and t5.`date` = t1.`date`