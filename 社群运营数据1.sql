select ww.user_id, u3.job_number, u3.name, sd3.department_name, 
       ww.student_no, ww.chat_title, s.name, 
       c.provincename, c.cityname,
       s.exam_year,
       case  when month(curdate()) >=7 then
	        case s.exam_year - year(curdate())
	        	  when 12 then    '小一'
	              when 11 then    '小二'
	              when 10 then    '小三'
	              when 9 then    '小四'
	              when 8 then    '小五'
	              when 7 then    '预初'
	              when 6 then    '初一'
	              when 5 then    '初二'
	              when 4 then    '初三'
	              when 3 then    '高一'
	              when 2 then    '高二'
	              when 1 then    '高三'
	        ELSE s.exam_year END
	   else
	        case s.exam_year - year(curdate()) 
		          when 11 then    '小一'
		          when 10 then    '小二'
		          when 9 then    '小三'
		          when 8 then    '小四'
		          when 7 then    '小五'
		          when 6 then    '预初'
		          when 5 then    '初一'
		          when 4 then    '初二'
		          when 3 then    '初三'
		          when 2 then    '高一'
		          when 1 then    '高二'
		          when 0 then    '高三'
		    ELSE s.exam_year END
    END grade,
    t1.adjust_start_time,
	t1.subject_name,
	t1.adjust_start_time,
	case  when t1.is_trial=1 then '出席' 
	      when t1.is_trial=0 then '跳票' end is_trial,
	case  when t2.contract_id is not null then '成单' else '未成单' end is_deal,
	u1.job_number,
	u1.name as track_sale_name,
	sd1.department_name,
	u2.job_number,
	u2.name as track_assistant_name,
	sd2.department_name
	


from bidata.will_work_phone_wechat_friend ww
inner join hfjydb.view_student s on s.student_no = ww.student_no
inner join hfjydb.map_phone_city c on c.phone7 = left(s.phone, 7)
inner join bidata.charlie_dept_month_end cdme on cdme.user_id=ww.user_id
           and cdme.class = '销售' and cdme.stats_date = curdate()
left join view_user_info u1 on u1.user_id = s.track_userid
left join sys_user_role sur1 on u1.user_id=sur1.user_id
left join sys_role sr1 on sur1.role_id=sr1.role_id
left join sys_department sd1 on sr1.department_id=sd1.department_id
left join view_user_info u2 on u2.user_id = s.by_assistant
left join sys_user_role sur2 on u2.user_id=sur2.user_id
left join sys_role sr2 on sur2.role_id=sr2.role_id
left join sys_department sd2 on sr2.department_id=sd2.department_id
left join view_user_info u3 on u3.user_id = ww.user_id
left join sys_user_role sur3 on u3.user_id=sur3.user_id
left join sys_role sr3 on sur3.role_id=sr3.role_id
left join sys_department sd3 on sr3.department_id=sd3.department_id
left join (
			select
			        lpo.apply_user_id, lpo.student_intention_id, lp.adjust_start_time, s1.subject_name,
			        case  when lp.status in (3,5) and lp.solve_status <> 6 then 1 else 0 end is_trial
		  			  
			from hfjydb.lesson_plan_order lpo
			left join hfjydb.lesson_relation lr on lpo.order_id = lr.order_id
			left join hfjydb.lesson_plan lp on lr.plan_id = lp.lesson_plan_id
			left join hfjydb.subject s1 on s1.subject_id = lp.subject_id
			inner join bidata.charlie_dept_month_end cdme on cdme.user_id = lpo.apply_user_id 
					   and cdme.stats_date = curdate() and cdme.class = '销售'
			inner join (
							select lpo.apply_user_id, lpo.student_intention_id, max(lp.adjust_start_time) as max_start_time
							from hfjydb.lesson_plan_order lpo
							left join hfjydb.lesson_relation lr on lpo.order_id = lr.order_id
							left join hfjydb.lesson_plan lp on lr.plan_id = lp.lesson_plan_id
							inner join bidata.charlie_dept_month_end cdme on cdme.user_id = lpo.apply_user_id 
					   				   and cdme.stats_date = curdate() and cdme.class = '销售'
					   		where lp.lesson_type = 2
					   		group by lpo.apply_user_id, lpo.student_intention_id
					   		) as a on a.apply_user_id=lpo.apply_user_id
			                          and a.student_intention_id=lpo.student_intention_id
			                          and a.max_start_time = lp.adjust_start_time

			where lp.lesson_type = 2 and lp.adjust_start_time>='2019-06-01'
			) as t1 on t1.student_intention_id = s.student_intention_id
                       and t1.apply_user_id = ww.user_id
left join (
			select  tc.contract_id,
			        tc.submit_user_id,
				    tc.student_intention_id,
				    sum(tcp.sum/100) real_pay_amount,
				    (tc.sum-666) * 10 contract_amount
			from hfjydb.view_tms_contract_payment tcp
			left join hfjydb.view_tms_contract tc on tc.contract_id = tcp.contract_id
			where tcp.pay_status in (2,4) and tc.status<>8
			      and tcp.pay_date >= '2019-06-01'
			group by tc.contract_id, tc.submit_user_id
			) as t2 on t2.submit_user_id=ww.user_id
                       and t2.student_intention_id=s.student_intention_id
where ww.wechat_friend_pass_time>='2019-06-01'