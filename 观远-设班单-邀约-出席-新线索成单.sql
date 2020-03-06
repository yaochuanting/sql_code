select  x.department_name 部门名称, y.apply_num 申请设班单量, 
		z.plan_num 邀约量, z.trial_num 出席量,
		xx.new_deal_num 新线索成单量, xx.new_deal_amount 新线索成单额,
		yy.new_keys 新线索量


from (
		select  date_sub(curdate(),interval 1 day) stats_date,
				cdme.department_name
		from bidata.charlie_dept_month_end cdme
		where cdme.stats_date = curdate()
			  and cdme.class = 'CC'
			  and cdme.date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
		group by stats_date, cdme.department_name
		having department_name like 'CC%'
		) as x


left join(
			select  count(distinct lpo.student_intention_id) as apply_num,
					department_name
			from hfjydb.lesson_plan_order lpo
			left join hfjydb.lesson_relation lr on lpo.order_id = lr.order_id
			left join hfjydb.lesson_plan lp on lr.plan_id = lp.lesson_plan_id
			left join hfjydb.view_student s on s.student_intention_id = lpo.student_intention_id
			inner join bidata.charlie_dept_month_end cdme on cdme.user_id = lpo.apply_user_id 
					   and cdme.stats_date = curdate() and cdme.class = 'CC'
					   and cdme.date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
			where lp.lesson_type = 2
				  and lpo.apply_time >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
				  and lpo.apply_time < curdate()
				  and s.account_type = 1
			group by department_name
			) as y on y.department_name=x.department_name


left join (
			
			select  aa.department_name,
					count(distinct aa.student_intention_id) as plan_num,
					count(distinct case when aa.is_trial=1 then aa.student_intention_id else null end) as trial_num
			from(
						select lpo.apply_user_id, lpo.student_intention_id, 
						cdme.department_name,
						case when lp.status in (3,5) and lp.solve_status <> 6 then 1 else 0 end as is_trial
						  			  
						from hfjydb.lesson_plan_order lpo
						left join hfjydb.lesson_relation lr on lpo.order_id = lr.order_id
						left join hfjydb.lesson_plan lp on lr.plan_id = lp.lesson_plan_id
						left join hfjydb.view_student s on s.student_intention_id = lpo.student_intention_id
						inner join bidata.charlie_dept_month_end cdme on cdme.user_id = lpo.apply_user_id 
								   and cdme.stats_date = curdate() and cdme.class = 'CC'
								   and cdme.date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
						where lp.lesson_type = 2
							   and lp.adjust_start_time >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
							   and lp.adjust_start_time < curdate()
							   and s.account_type = 1
							   ) as aa
			group by aa.department_name
			) as z on z.department_name=x.department_name

left join(
			select  bb.department_name,
					count(bb.contract_id) as new_deal_num,
					sum(bb.real_pay_sum) as new_deal_amount

			from(		
						select  max(tcp.pay_date) last_pay_date,
								tcp.contract_id,  
								s.student_intention_id,
								cdme.department_name,
								sum(tcp.sum)/100 real_pay_sum, 
								(tc.sum-666)*10 contract_amount
						from hfjydb.view_tms_contract_payment tcp
						left join hfjydb.view_tms_contract tc on tcp.contract_id  = tc.contract_id
						left join hfjydb.view_student s on s.student_intention_id = tc.student_intention_id
						left join hfjydb.view_user_info ui on ui.user_id = tc.submit_user_id
						inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tcp.submit_user_id
								   and cdme.stats_date = curdate() and cdme.class = 'CC'
								   and cdme.date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
						where tcp.pay_status in (2,4)
							  and ui.account_type = 1
							  and s.submit_time >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
							  and tc.status <> 8
						group by tcp.contract_id
						having real_pay_sum >= contract_amount
							   and last_pay_date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
							   and last_pay_date < curdate()
							   ) as bb
			group by bb.department_name
			) as xx on xx.department_name=x.department_name

left join (
			select  cc.department_name,
					count(distinct cc.intention_id) as new_keys		
			from(
						select cdme.department_name, tpel.track_userid, tpel.intention_id, tpel.into_pool_date
			            from hfjydb.tms_pool_exchange_log tpel
			            left join hfjydb.view_student s on s.student_intention_id=tpel.intention_id
			            inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tpel.track_userid
				                   and cdme.stats_date = curdate() and cdme.class = 'CC'
				                   and cdme.date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
			            where tpel.into_pool_date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
				              and tpel.into_pool_date < curdate()
				              and s.submit_time>=date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
			            union all
			            select cdme.department_name, tnn.user_id as track_userid, tnn.student_intention_id as intention_id, tnn.create_time as into_pool_date
			            from hfjydb.tms_new_name_get_log tnn
			            left join hfjydb.view_student s on s.student_intention_id=tnn.student_intention_id
			            inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tnn.user_id
				                   and cdme.stats_date = curdate() and cdme.class = 'CC'
				                   and cdme.date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
			            where tnn.create_time >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
				              and tnn.create_time < curdate()
				              and tnn.student_intention_id <> 0
				              and s.submit_time>=date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
				              ) as cc
			group by cc.department_name
			) as yy on yy.department_name=x.department_name




