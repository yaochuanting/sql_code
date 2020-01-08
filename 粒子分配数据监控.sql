          
              select case when date(t2.submit_time) >= '2019-11-01' and date(t2.submit_time) <= '2019-11-30'
                     then '11月'
                     when date(t2.submit_time) >= '2019-09-01' and date(t2.submit_time) <= '2019-10-31' 
                     then '9-10月'
                     when date(t2.submit_time) >= '2019-07-01' and date(t2.submit_time) <= '2019-08-31'
                     then '7-8月'
                     when date(t2.submit_time) >= '2019-04-01' and date(t2.submit_time) <= '2019-06-30' 
                     then '4-6月'
                     when date(t2.submit_time) >= '2019-01-01' and date(t2.submit_time) <= '2019-03-31' 
                     then '1-3月'
                     when year(t2.submit_time) < 2019 then '2019年以前' else null end as period,
                     t2.name,
                     count(t2.student_intention_id),
                     count(case when t2.max_into_pool_date >= '2019-06-01' and t2.max_into_pool_date < '2019-09-01'
                            then t2.student_intention_id else null end) last_commu_6_8,
                     count(case when t2.max_into_pool_date >= '2019-09-01' and t2.max_into_pool_date < '2019-12-01'
                            then t2.student_intention_id else null end) last_commu_9_11,
                     count(case when t2.max_into_pool_date >= '2019-09-01' and t2.max_into_pool_date < '2019-12-01'
                                   and ifnull(t3.tr_call_cnt_9_11,0)<5
                            then t2.student_intention_id else null end) last_commu_9_11_and_call_cnt_less_than_5,
                     count(case when t2.max_into_pool_date >= '2019-12-01' then t2.student_intention_id else null end) into_pool_in_M12,
                     count(case when ifnull(t3.tr_call_cnt_9_11,0)<5
                            then t2.student_intention_id else null end) call_cnt_less_than_5
              
                     
              from(          
                     select s.student_intention_id, 
                            s.student_no, s.submit_time,
                            ui.name,
                            t1.max_into_pool_date
                            
                     from hfjydb.view_student s
                     left join hfjydb.view_user_info ui on ui.user_id = s.track_userid
                     left join (
                                   select  max(tpel.into_pool_date) as max_into_pool_date,
                                          tpel.intention_id
                                   from tms_pool_exchange_log tpel
                                   left join hfjydb.view_user_info ui on ui.user_id = tpel.track_userid
                                   left join hfjydb.sys_user_role sur on ui.user_id=sur.user_id
                                   left join hfjydb.sys_role sr on sur.role_id=sr.role_id
                                   left join hfjydb.sys_department sd on sr.department_id=sd.department_id
                                   where sr.role_code like 'XS%'
                                          and ui.name not like '%OC%'
                                   group by tpel.intention_id
                                   ) as t1 on t1.intention_id = s.student_intention_id
                     where ui.name like '%OC%'
                                   ) as t2
              left join (
                     select tcr.student_intention_id,
                            count(tcr.id) as tr_call_cnt_9_11
                     from hfjydb.view_tms_call_record tcr
                     where tcr.start_time >= '2019-09-01' and tcr.start_time < '2019-12-01'
                            and tcr.call_type = 1
                     group by tcr.student_intention_id
                     ) as t3 on t3.student_intention_id = t2.student_intention_id
              left join (
                     select wr.student_intention_id,
                            count(wr.id) as wp_call_cnt_9_11
                     from bidata.will_work_phone_call_recording wr
                     where wr.begin_time >= '2019-09-01' and wr.begin_time < '2019-12-01'
                            and wr.is_call_out = 'True'
                     group by wr.student_intention_id
                     ) as t4 on t2.student_intention_id = t4.student_intention_id
              left join (
                     select tcr.student_intention_id,
                            count(tcr.id) as tr_call_cnt
                     from hfjydb.view_tms_call_record tcr
                     where tcr.call_type = 1
                     group by tcr.student_intention_id
                     ) as t5 on t5.student_intention_id = t2.student_intention_id

              left join (
                     select wr.student_intention_id,
                            count(wr.id) as wp_call_cnt
                     from bidata.will_work_phone_call_recording wr
                     where wr.is_call_out = 'True'
                     group by wr.student_intention_id
                     ) as t6 on t2.student_intention_id = t6.student_intention_id
              group by period, name