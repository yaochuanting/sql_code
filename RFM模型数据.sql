select  t1.student_id 学生id, s.student_no 学生编号,
		t3.first_pay_date as 首次消费时间,
		t1.classMinutes/60 as 消课数,
		t1.min_class_time as 最小消课时间,
		t1.max_class_time as 最大消课时间,
		t2.deal_num as 总成单数,
		t2.deal_amount as 总成单额


from (

		select  lp.student_id, sum(lp.classMinutes) as classMinutes, min(lp.adjust_start_time) as min_class_time,
				max(lp.adjust_start_time) as max_class_time
		from hfjydb.lesson_plan lp
		where   lp.status in (3,5) and lp.solve_status <> 6 and lp.lesson_type = 1
      			and year(lp.adjust_start_time)=2019
      	group by lp.student_id
      	having sum(lp.classMinutes)>0
      			) as t1 

left join hfjydb.view_student s on s.student_id=t1.student_id
left join (
			select a.student_intention_id,
			       count(a.contract_id) as deal_num,
			       sum(a.contract_amount) as deal_amount


			from(
					select  tc.student_intention_id, 
						    tcp.contract_id,       
						    max(tcp.pay_date) as max_pay_date,
						    sum(tcp.sum/100) real_pay_sum, 
						    (tc.sum-666)*10 contract_amount
					from hfjydb.view_tms_contract_payment tcp
					left join hfjydb.view_tms_contract tc on tc.contract_id = tcp.contract_id 
					left join hfjydb.view_user_info ui on ui.user_id = tc.submit_user_id   
					where tcp.pay_status in (2,4) 
						  and tc.status<>8  -- 剔除合同终止和废弃
						  and ui.account_type=1  -- 剔除测试数据
					group by tcp.contract_id
					having real_pay_sum>=contract_amount 
					   and year(max_pay_date)=2019
					   ) as a
			group by a.student_intention_id
			) as t2 on t2.student_intention_id=s.student_intention_id

left join (
				select a.student_intention_id,
				       min(a.max_pay_date) as first_pay_date


				from(
						select  tc.student_intention_id, 
							    tcp.contract_id,       
							    max(tcp.pay_date) as max_pay_date,
							    sum(tcp.sum/100) real_pay_sum, 
							    (tc.sum-666)*10 contract_amount
						from hfjydb.view_tms_contract_payment tcp
						left join hfjydb.view_tms_contract tc on tc.contract_id = tcp.contract_id 
						left join hfjydb.view_user_info ui on ui.user_id = tc.submit_user_id   
						where tcp.pay_status in (2,4) 
							  and tc.status<>8  -- 剔除合同终止和废弃
							  and ui.account_type=1  -- 剔除测试数据
						group by tcp.contract_id
						having real_pay_sum>=contract_amount 
						   ) as a
				group by a.student_intention_id
				) as t3 on t3.student_intention_id=s.student_intention_id

where t1.min_class_time>=t3.first_pay_date
      and t3.first_pay_date is not null
      and t1.classMinutes>0