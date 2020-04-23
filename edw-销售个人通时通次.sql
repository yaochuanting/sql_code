select  t1.department_name, t1.name, t1.job_number, t1.login_time,
        if(t2.tr_call_cnt is null, 0, t2.tr_call_cnt) + if(t3.wp_call_cnt is null, 0, t3.wp_call_cnt) total_call_cnt,
        if(t2.tr_bridge_call_cnt is null, 0, t2.tr_bridge_call_cnt) + if(t3.wp_bridge_call_cnt is null, 0, t3.wp_bridge_call_cnt) total_bridge_cnt,
        (if(t2.tr_call_time is null, 0, t2.tr_call_time) + if(t3.wp_call_time is null, 0, t3.wp_call_time))/3600 total_call_time,
        t2.tr_call_cnt, t2.tr_bridge_call_cnt, t2.tr_call_time tr_call_time_s, t2.tr_call_time/3600 tr_call_time_h, 
        t3.wp_call_cnt, t3.wp_bridge_call_cnt, t3.wp_call_time wp_call_time_s, t3.wp_call_time/3600 wp_call_time_h,
        t1.`date` 
       


from(     
        
        select cd.`date`, cd.user_id, cdme.job_number,cdme.name, cdme.department_name, 
               to_date(min(crl.opt_time)) as login_time
        from dw_hf_mobdb.dw_charlie_dept_history cd
        left join dw_hf_mobdb.dw_view_user_info ui on ui.user_id = cd.user_id
        left join dw_hf_mobdb.dw_sys_change_role_log crl on crl.user_id=cd.user_id
        left join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id = cd.user_id
                  and cdme.class = 'CC' and cdme.stats_date = '${analyse_date}'
        where (cd.department_name like 'CC%' or cd.department_name like '销售%')
               and cd.`date` >= trunc('${analyse_date}','MM')
               and cd.`date` <= '${analyse_date}'
        group by cd.`date`, cd.user_id, cdme.job_number, cdme.name, cdme.department_name
        ) as t1


left join (
            select 
                        to_date(tcr.end_time) `date`, 
                        tcr.user_id,                        
                        sum(unix_timestamp(tcr.end_time)-unix_timestamp(tcr.bridge_time)) tr_call_time,
                        count(*) tr_call_cnt,
                        count(tcr.bridge_time) tr_bridge_call_cnt
            from dw_hf_mobdb.dw_view_tms_call_record tcr
            where tcr.call_type = 1 -- 呼叫学生
                  and to_date(tcr.end_time) >= trunc('${analyse_date}','MM')
                  and to_date(tcr.end_time) <= '${analyse_date}'
            group by to_date(tcr.end_time), tcr.user_id
            ) as t2 on t2.`date` = t1.`date` and t2.user_id = t1.user_id


left join (
            select  to_date(begin_time) as `date`,
                    user_id,
                    count(student_intention_id) as wp_call_cnt,
                    count(case when on_type = 1 then student_intention_id end) as wp_bridge_call_cnt,
                    sum(calling_seconds) as wp_call_time
            from dw_hf_mobdb.dw_will_work_phone_call_recording wp
            where is_call_out = 'True'
                  and to_date(begin_time) >= trunc('${analyse_date}','MM')
                  and to_date(begin_time) <= '${analyse_date}'
            group by to_date(begin_time), user_id
            ) as t3 on t3.user_id = t1.user_id and t3.`date` = t1.`date`
            
            
where t1.date>=#{d1} and t1.date<=#{d2}