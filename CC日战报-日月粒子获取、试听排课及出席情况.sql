-- CC日战报-日/月粒子获取、试听排课及出席情况
select  date_sub(curdate(),interval 1 day) 统计日期,
		t1.department_name 部门名称,
        t2.d_keys 日获取粒子数,
        t2.d_new_keys 日新粒子获取数,
        t2.d_oc_keys 日oc粒子获取数,
        (t5.d_tcr_call_time+t6.d_wp_call_time)/3600 `日总通时/h`,
        t5.d_tcr_call_cnt+t6.d_wp_call_cnt 日总通次,
        t3.d_apply_num 日发起设班单数,
        t4.d_plan_num 日试听排课数,
        t2.m_keys 月获取粒子数,
        t2.m_new_keys 月新粒子获取数,
        t2.m_oc_keys 月oc粒子获取数,
        t4.m_plan_num 月试听排课数,
        t4.m_trial_num 月试听课出席数


from( 
      select cdme.center, 
             cdme.region,
             cdme.department,
             cdme.department_name
      from bidata.charlie_dept_month_end cdme 
      where cdme.stats_date=curdate() and cdme.class='CC'
            and cdme.department_name like 'CC%' 
      group by cdme.department_name
      ) as t1


-- 粒子获取数
left join (
			select cdme.department_name, 
			       count(distinct case when date(tpel.into_pool_date)=date_sub(curdate(),interval 1 day) then tpel.intention_id end) d_keys,
			       count(distinct case when date(tpel.into_pool_date)=date_sub(curdate(),interval 1 day) and s.create_time>=date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
			       	                   then tpel.intention_id end) d_new_keys,
			       count(distinct case when date(tpel.into_pool_date)=date_sub(curdate(),interval 1 day) and s.create_time<date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
			       	          		   then tpel.intention_id end) d_oc_keys,
			       count(distinct tpel.intention_id) m_keys,
			       count(distinct case when s.create_time>=date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
			                           then tpel.intention_id end) m_new_keys,
			       count(distinct case when s.create_time<date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
			                           then tpel.intention_id end) m_oc_keys
			from hfjydb.tms_pool_exchange_log tpel
			left join hfjydb.view_student s on s.student_intention_id=tpel.intention_id
			inner join bidata.charlie_dept_month_end cdme on cdme.user_id=tpel.track_userid
			           and cdme.class='CC' and cdme.stats_date=curdate()
			where date(tpel.into_pool_date)>=date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
			      and date(tpel.into_pool_date)<=date_sub(curdate(),interval 1 day)
			      and cdme.date>=date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
			group by cdme.department_name
			) as t2 on t2.department_name=t1.department_name


-- 设班单发起数
left join (
			select  cdme.department_name,
			        count(distinct case when date(lpo.apply_time)=date_sub(curdate(),interval 1 day) then lpo.student_intention_id end) as d_apply_num,
			        count(distinct lpo.student_intention_id) as m_apply_num
			from hfjydb.lesson_plan_order lpo
			left join hfjydb.lesson_relation lr on lpo.order_id=lr.order_id
			left join hfjydb.lesson_plan lp on lr.plan_id=lp.lesson_plan_id
			left join hfjydb.view_student s on s.student_intention_id=lpo.student_intention_id
			inner join bidata.charlie_dept_month_end cdme on cdme.user_id=lpo.apply_user_id 
					   and cdme.stats_date=curdate() and cdme.class='CC'
					   and cdme.date>=date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
			where lp.lesson_type=2
				  and date(lpo.apply_time)>=date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
				  and date(lpo.apply_time)<=date_sub(curdate(),interval 1 day)
				  and s.account_type = 1
			group by cdme.department_name
		    ) as t3 on t3.department_name=t1.department_name

-- 排课数
left join (
			select  cdme.department_name,
					count(distinct case when date(lp.adjust_start_time)=date_sub(curdate(),interval 1 day) then lpo.student_intention_id end) as d_plan_num,
					count(distinct lpo.student_intention_id) as m_plan_num,
					count(distinct case when lp.status in (3,5) and lp.solve_status<>6 then lpo.student_intention_id end) as m_trial_num
			from hfjydb.lesson_plan_order lpo
			left join hfjydb.lesson_relation lr on lpo.order_id=lr.order_id
			left join hfjydb.lesson_plan lp on lr.plan_id=lp.lesson_plan_id
			left join hfjydb.view_student s on s.student_intention_id=lpo.student_intention_id
			inner join bidata.charlie_dept_month_end cdme on cdme.user_id=lpo.apply_user_id 
					   and cdme.stats_date=curdate() and cdme.class='CC'
					   and cdme.date>=date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
			where lp.lesson_type=2
				  and date(lp.adjust_start_time)>=date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
				  and date(lp.adjust_start_time)<=date_sub(curdate(),interval 1 day)
				  and s.account_type = 1
			group by cdme.department_name
				  ) as t4 on t4.department_name=t1.department_name

-- 天润通时通次
left join (
			select  cdme.department_name,
                    sum(timestampdiff(second,bridge_time,end_time)) d_tcr_call_time,
                    count(*) d_tcr_call_cnt
            from hfjydb.view_tms_call_record tcr
            inner join bidata.charlie_dept_month_end cdme on cdme.user_id=tcr.user_id
                       and cdme.stats_date=curdate() and cdme.class='CC'
                       and cdme.date>=date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
            where tcr.call_type = 1 -- 呼叫学生
                  and date(tcr.end_time)=date_sub(curdate(),interval 1 day)
            group by cdme.department_name
            ) as t5 on t5.department_name=t1.department_name


-- 工作手机通时通次
left join (
			select  cdme.department_name,
                    count(student_intention_id) as d_wp_call_cnt,
                    sum(calling_seconds) as d_wp_call_time
            from bidata.will_work_phone_call_recording wr
            inner join bidata.charlie_dept_month_end cdme on cdme.user_id=wr.user_id
                       and cdme.stats_date=curdate() and cdme.class='CC'
                       and cdme.date>=date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
            where is_call_out = 'True'
                  and date(begin_time)=date_sub(curdate(),interval 1 day)
            group by cdme.department_name
            ) as t6 on t6.department_name=t1.department_name