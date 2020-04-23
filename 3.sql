select t1.*, t2.call_time, t2.total_call_count, t2.connected_call_count,
       t3.wp_call_cnt, t3.wp_bridge_cnt, t3.wp_call_time
       


from(     
        
        select cd.date, cd.user_id, cdme.job_number,cdme.name, cdme.department_name, cdme.city, cdme.branch, cdme.center, cdme.region, cdme.department,
               date(min(crl.opt_time)) as login_time
        from bidata.charlie_dept_history cd
        left join hfjydb.view_user_info ui on ui.user_id = cd.user_id
        left join hfjydb.sys_change_role_log crl on crl.user_id=cd.user_id
        left join bidata.charlie_dept_month_end cdme on cdme.user_id = cd.user_id
                  and cdme.class = 'CC' and cdme.stats_date = curdate()
        where (cd.department_name like 'CC%' or cd.department_name like '销售%')
               and cd.date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
               and cd.date < curdate()
        group by cd.date, cd.user_id, cdme.job_number, cdme.name, cdme.department_name, cdme.center, cdme.region,cdme.department
        ) as t1


left join (
            select 
                        date(tcr.end_time) date, 
                        tcr.user_id, 
                        sum(timestampdiff(second,bridge_time,end_time)) call_time,
                        count(*) total_call_count,
                        count(tcr.bridge_time) connected_call_count
            from view_tms_call_record tcr
            where tcr.call_type = 1 -- 呼叫学生
                    and tcr.end_time >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
                    and tcr.end_time < curdate()
            group by date(tcr.end_time), tcr.user_id
            ) as t2 on t2.date = t1.date and t2.user_id = t1.user_id


left join (
            select  date(begin_time) as date,
                    user_id,
                    count(student_intention_id) as wp_call_cnt,
                    count(case when on_type = 1 then student_intention_id end) as wp_bridge_cnt,
                    sum(calling_seconds) as wp_call_time

            from bidata.will_work_phone_call_recording 
            where is_call_out = 'True'
                  and begin_time >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
                  and begin_time < curdate()
            group by date, user_id
            ) as t3 on t3.user_id = t1.user_id and t3.date = t1.date