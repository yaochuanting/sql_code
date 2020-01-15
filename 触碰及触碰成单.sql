select date_format(ss.view_time, '%Y%m') as month,
	   count(distinct ss.student_intention_id) as req_num,

	   count(distinct case when min_start_date <= date_format(view_time,'%Y-%m-07')
	   	                        and min_start_date >= date_format(view_time,'%Y-%m-01')
	   	                   then t2.student_intention_id else null end) as first7_plan_num,
	   count(distinct case when min_start_date <= last_day(view_time)
	   	                        and min_start_date >= date_format(view_time,'%Y-%m-01')
	   	                   then t2.student_intention_id else null end) as tomonth_plan_num,

	   count(distinct case when min_start_date <= date_format(view_time,'%Y-%m-07')
	   	                        and min_start_date >= date_format(view_time,'%Y-%m-01')
	   	                        and t2.is_trial = 1
	   	                   then t2.student_intention_id else null end) as first7_trial_num,
	   count(distinct case when min_start_date <= last_day(view_time)
	   	                        and min_start_date >= date_format(view_time,'%Y-%m-01')
	   	                        and t2.is_trial = 1
	   	                   then t2.student_intention_id else null end) as tomonth_trial_num,

	   count(distinct case when min_pay_date <= date_format(view_time,'%Y-%m-07')
	                            and min_pay_date >= date_format(view_time,'%Y-%m-01')
	                       then t1.contract_id else null end) as first7_order_num,
	   count(distinct case when min_pay_date >= date_format(view_time,'%Y-%m-01')
	   	                        and min_pay_date <= last_day(view_time)
	   	                   then t1.contract_id else null end) as tomonth_order_num


from hfjydb.ss_collection_sale_roster_action ss


left join (
				select min(date(tcp.pay_date)) min_pay_date,
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
				where tcp.pay_status in (2, 4)
						and tc.status <> 8
				group by tc.contract_id
				having min_pay_date >= '2019-10-01'
						and min_pay_date <= '2020-01-13'
						and real_pay_amount >= contract_amount
						) as t1 on t1.student_intention_id = ss.student_intention_id

left join (
				select
						  lpo.student_intention_id,
						  date(min(lp.adjust_start_time)) as min_start_date,
			              case when sum((case when lp.status in (3,5) and lp.solve_status <> 6 then 1 else 0 end))>0 
			                   then 1 else 0 end as is_trial	  			  
		        from hfjydb.lesson_plan_order lpo 
		        left join hfjydb.lesson_relation lr on lpo.order_id = lr.order_id
		        left join hfjydb.lesson_plan lp on lr.plan_id = lp.lesson_plan_id
		        left join hfjydb.view_student s on s.student_intention_id = lpo.student_intention_id
				inner join bidata.charlie_dept_month_end cdme on cdme.user_id = lpo.apply_user_id 
				           and cdme.stats_date = curdate() and cdme.class = '销售'
				where lp.lesson_type = 2
		              and date(lp.adjust_start_time) >= '2019-10-01'
		              and date(lp.adjust_start_time) <= '2020-01-13'
		              and s.account_type = 1
		        group by lpo.student_intention_id
		              ) as t2 on t2.student_intention_id = ss.student_intention_id

group by month 