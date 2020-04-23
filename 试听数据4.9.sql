select
		   lpo.apply_user_id, lpo.student_intention_id, s.student_no,
		   cdme.department_name,
		   (case when lp.status in (3,5) and lp.solve_status <> 6 then 1 else 0 end) is_trial,
		   (case when aa.real_pay_amount > 0 then 1 else 0 end) is_trial_deal,
		   (case when lp.student_id in (select distinct student_id
										from hfjydb.lesson_plan  
										where lesson_type=3 and status = 3 and solve_status <> 6 
											  and adjust_start_time >= '2019-07-01'
											  and adjust_start_time < '2019-08-01'
											  )
                 then 1 else 0 end) is_trial_exp			  			  
from hfjydb.lesson_plan_order lpo
left join hfjydb.lesson_relation lr on lpo.order_id = lr.order_id
left join hfjydb.lesson_plan lp on lr.plan_id = lp.lesson_plan_id
left join hfjydb.view_student s on s.student_intention_id = lpo.student_intention_id
inner join bidata.charlie_dept_month_end cdme on cdme.user_id = lpo.apply_user_id 
		   and cdme.stats_date = '2019-07-31' and (cdme.class = 'CC' or cdme.class = '销售')
		   and cdme.date >= '2019-07-01'
left join (
				select min(tcp.pay_date) min_date,
					   tc.contract_id,
					   tc.student_intention_id,
					   sum(tcp.sum/100) real_pay_amount,
					   (tc.sum-666) * 10 contract_amount,
					   tcp.submit_user_id,
					   cdme.department_name
				from hfjydb.view_tms_contract_payment tcp
				left join hfjydb.view_tms_contract tc on tc.contract_id = tcp.contract_id
				inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tcp.submit_user_id
						   and cdme.stats_date = '2019-07-31' and (cdme.class = 'CC' or cdme.class = '销售')
						   and cdme.date >= '2019-07-01'
				where tcp.pay_status in (2,4)
					  and tc.status <> 8
				group by tc.contract_id, cdme.department_name
				having max(tcp.pay_date) >= '2019-07-01'
					   and max(tcp.pay_date) < '2019-08-01'
					   and real_pay_amount >= contract_amount
					   ) as aa on aa.student_intention_id = lpo.student_intention_id
								  and aa.department_name = cdme.department_name		   
where lp.lesson_type = 2
	   and lp.adjust_start_time >= '2019-07-01'
	   and lp.adjust_start_time < '2019-08-01'
	   and s.account_type = 1