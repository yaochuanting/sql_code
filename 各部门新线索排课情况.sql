select  t.department_name as 当前部门,
		count(distinct t.student_intention_id) as 新粒子数, 
	    count(distinct case when t.adjust_start_time is not null then t.student_intention_id else null end) as 排课学生数,
	    count(distinct case when t.is_trial=1 then t.student_intention_id else null end) as 出席学生数


from(


		select  s.student_intention_id, s.student_no,
				lp.adjust_start_time,
				case when lp.status in (3,5) and lp.solve_status <> 6 then 1 else 0 end as is_trial,
				ui.name as 跟进人, sd.department_name
				

		from hfjydb.view_student s
		left join hfjydb.view_user_info ui on ui.user_id=s.track_userid
		left join hfjydb.sys_user_role sur on ui.user_id=sur.user_id
		left join hfjydb.sys_role sr on sur.role_id=sr.role_id
		left join hfjydb.sys_department sd on sr.department_id=sd.department_id
		left join hfjydb.lesson_plan_order lpo on lpo.student_intention_id=s.student_intention_id
		left join hfjydb.lesson_relation lr on lpo.order_id = lr.order_id
		left join hfjydb.lesson_plan lp on lr.plan_id = lp.lesson_plan_id

		where s.submit_time>='2020-02-01'
		      and s.submit_time<='2020-02-05'
		      and sd.department_name like '%销售%'
		      ) as t

group by t.department_name