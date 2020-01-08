CREATE DEFINER=`shenyuqing`@`%` PROCEDURE `yct_module_oc`()
begin

replace into tmp_mobdb.yct_module_data 
             (student_intention_id, view_time, record_auto_id, score, score_pct, req_call, req_call_bridge, req_call_valid, is_bridge, min_bridge_time, is_valid, is_into_pool, min_into_pool_date, is_plan, min_apply_time, is_trial, min_adjust_start_time, is_deal, min_pay_date, real_pay_sum)

select t1.student_intention_id,
			 t1.view_time,
			 t1.record_auto_id,
			 t1.score,
			 t1.score_pct,
       case when t1.record_auto_id <> -1 then 1 else 0 end as req_call,
       case when tcr.status = 33 then 1 else 0 end as req_call_bridge,
       case when timestampdiff(second, tcr.bridge_time, tcr.end_time) >= 90 then 1 else 0 end as req_call_valid,
       case when t2.student_intention_id is not null then 1 else 0 end as is_bridge,
       t2.min_bridge_time,
       case when t2.max_bridge_period >= 90 then 1 else 0 end as is_valid,
       case when t3.student_intention_id is not null then 1 else 0 end as is_into_pool,
       t3.min_into_pool_date,
       case when t4.student_intention_id is not null then 1 else 0 end as is_plan,
       t4.min_apply_time,
       case when t5.student_intention_id is not null then 1 else 0 end as is_trial,
       t5.min_adjust_start_time,
       case when t6.student_intention_id is not null then 1 else 0 end as is_deal,
       t6.min_pay_date,
       t6.real_pay_sum


from(
            select ss.view_time, 
                   ss.student_intention_id, 
                   ss.record_auto_id, 
                   ss.score,
									 ss.score_pct
            from tmp_mobdb.yct_ss_collection_score_daily ss
            inner join bidata.charlie_dept_month_end cdme on cdme.user_id = ss.user_id
                       and cdme.class = '销售' and cdme.stats_date = curdate()
            inner join hfjydb.view_student s on s.student_intention_id = ss.student_intention_id
            inner join (
                        select ss.student_intention_id,
                               min(view_time) as min_view_time
                        from tmp_mobdb.yct_ss_collection_score_daily ss
                        inner join bidata.charlie_dept_month_end cdme on cdme.user_id = ss.user_id
                                   and cdme.class = '销售' and cdme.stats_date = curdate()
                        group by ss.student_intention_id
                        ) as t1 on t1.min_view_time = ss.view_time
                                   and t1.student_intention_id = ss.student_intention_id
            where s.submit_time < date_format(ss.view_time,'%Y-%m-01')
            ) as t1

left join hfjydb.view_tms_call_record tcr on tcr.id = t1.record_auto_id
          and tcr.call_type = 1 and tcr.end_time >= '2019-12-19'
          and tcr.end_time < curdate()

left join (

            select a.student_intention_id,
                   min(a.min_bridge_time) as min_bridge_time,
                   max(a.max_bridge_period) as max_bridge_period
            from(
                        select
                                tcr.student_intention_id,
                                min(tcr.bridge_time) as min_bridge_time,
                                max(timestampdiff(second, tcr.bridge_time, tcr.end_time)) as max_bridge_period
                        from hfjydb.view_tms_call_record tcr
                        inner join hfjydb.view_student s on s.student_intention_id = tcr.student_intention_id
                        inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tcr.user_id
                                   and cdme.stats_date = curdate() and cdme.class = '销售'
                        where tcr.end_time >= '2019-12-19' and tcr.end_time < curdate()
                              and tcr.call_type = 1 -- 打给学生 
                              and tcr.status = 33 -- 接通
                        group by tcr.student_intention_id
                        union all										
                        select
                                wr.student_intention_id,
                                min(wr.begin_time) max_bridge_time,
                                max(timestampdiff(second, wr.begin_time, wr.end_time)) as max_bridge_period
                        from  bidata.will_work_phone_call_recording wr
                        inner join bidata.charlie_dept_month_end cdme on cdme.user_id = wr.user_id
                                and cdme.stats_date = curdate() and cdme.class = '销售' 
                        where wr.begin_time < curdate()
                            and wr.begin_time >= '2019-12-19'
                            and wr.on_type = 1 -- 接通
                        group by wr.student_intention_id
                        ) as a
            group by a.student_intention_id
            ) as t2 on t2.student_intention_id = t1.student_intention_id
                       and t2.min_bridge_time >= t1.view_time
left join (

             select p.student_intention_id, min(into_pool_date) as min_into_pool_date
             from tmp_mobdb.yct_pool_exchange_score_daily p
             inner join bidata.charlie_dept_month_end cdme on cdme.user_id = p.track_userid
                        and cdme.stats_date = curdate() and cdme.class = '销售'
             where p.into_pool_date >= '2019-12-19'
                   and p.into_pool_date < curdate()
             group by p.student_intention_id
             ) as t3 on t3.student_intention_id = t1.student_intention_id
                        and t3.min_into_pool_date >= t1.view_time 

left join (

                select
                                lpo.student_intention_id,
                                min(lpo.apply_time) as min_apply_time
                                                        
                from hfjydb.lesson_plan_order lpo
                left join hfjydb.lesson_relation lr on lpo.order_id = lr.order_id
                left join hfjydb.lesson_plan lp on lr.plan_id = lp.lesson_plan_id
                inner join bidata.charlie_dept_month_end cdme on cdme.user_id = lpo.apply_user_id 
                           and cdme.stats_date = curdate() and cdme.class = '销售'
                where lpo.apply_time >= '2019-12-19'
                      and lpo.apply_time < curdate()
                      and lp.lesson_type = 2
                      and lp.solve_status <> 6
                group by lpo.student_intention_id
                ) as t4 on t4.student_intention_id = t1.student_intention_id
                           and t4.min_apply_time >= t1.view_time
        
left join (

                select
                                lpo.student_intention_id,
                                min(lp.adjust_start_time) as min_adjust_start_time		  			  
                from hfjydb.lesson_plan_order lpo
                left join hfjydb.lesson_relation lr on lpo.order_id = lr.order_id
                left join hfjydb.lesson_plan lp on lr.plan_id = lp.lesson_plan_id
                inner join bidata.charlie_dept_month_end cdme on cdme.user_id = lpo.apply_user_id 
                           and cdme.stats_date = curdate() and cdme.class = '销售'
                where lp.status in (3,5) and lp.solve_status <> 6
                      and lp.lesson_type = 2
                      and lp.adjust_start_time >= '2019-12-19'
                      and lp.adjust_start_time < curdate()
                group by lpo.student_intention_id
                ) as t5 on t5.student_intention_id = t1.student_intention_id
                           and t5.min_adjust_start_time >= t1.view_time

left join (

             select
                    min(tcp.pay_date) min_pay_date,
                    max(tcp.pay_date) last_pay_date,
                    tcp.contract_id,  
                    s.student_intention_id,
                    sum(tcp.sum)/100 real_pay_sum, 
                    (tc.sum-666)*10 contract_amount
            from hfjydb.view_tms_contract_payment tcp
            left join hfjydb.view_tms_contract tc on tcp.contract_id  = tc.contract_id
            left join hfjydb.view_student s on s.student_intention_id = tc.student_intention_id
            left join hfjydb.view_user_info ui on ui.user_id = tc.submit_user_id
            inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tcp.submit_user_id
                       and cdme.stats_date = curdate() and cdme.class = '销售'
            where tcp.pay_status in (2,4)
                  and ui.account_type = 1
            group by tcp.contract_id
            having real_pay_sum >= contract_amount
                   and min_pay_date >= '2019-12-19'
                   and min_pay_date < curdate()
                   ) as t6 on t6.student_intention_id = t1.student_intention_id
                              and t6.min_pay_date >= t1.view_time;



end