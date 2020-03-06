select  date_sub(curdate(),interval 1 day) 统计日期,
		t1.department_name 部门名称,
		t2.yes_trial_deal_rate 当日试听课关单率,
		t2.rc7_trial_deal_rate 近7日试听课关单率,
		t2.rc30_trial_deal_rate 近30日试听课关单率,




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


left join(

			select b.department_name,
			       count(distinct case when date(b.adjust_start_time)=date_sub(curdate(),interval 1 day) then b.contract_id end)/count(distinct case when date(b.adjust_start_time)=date_sub(curdate(),interval 1 day) then b.student_intention_id end) yes_trial_deal_rate,
			       count(distinct case when date(b.adjust_start_time)>=date_sub(curdate(),interval 7 day) then b.contract_id end)/count(distinct case when date(b.adjust_start_time)>=date_sub(curdate(),interval 7 day) then b.student_intention_id end) rc7_trial_deal_rate,
			       count(distinct case when date(b.adjust_start_time)>=date_sub(curdate(),interval 30 day) then b.contract_id end)/count(distinct case when date(b.adjust_start_time)>=date_sub(curdate(),interval 30 day) then b.student_intention_id end) rc30_trial_deal_rate


			from(
					select  cdme.department_name, lpo.student_intention_id, lpo.apply_user_id, lp.adjust_start_time,
					        a.max_date, a.contract_id
					from hfjydb.lesson_plan_order lpo
					left join hfjydb.lesson_relation lr on lpo.order_id = lr.order_id
					left join hfjydb.lesson_plan lp on lr.plan_id = lp.lesson_plan_id
					left join hfjydb.view_student s on s.student_intention_id = lpo.student_intention_id
					inner join bidata.charlie_dept_month_end cdme on cdme.user_id = lpo.apply_user_id 
							   and cdme.stats_date=curdate() and cdme.class = 'CC'
							   and cdme.date>=date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
					left join (
								select max(tcp.pay_date) max_date,
									   tc.contract_id,
									   tc.student_intention_id,
									   sum(tcp.sum/100) real_pay_amount,
									   (tc.sum-666)*10 contract_amount,
									   tcp.submit_user_id,
									   cdme.department_name

								from hfjydb.view_tms_contract_payment tcp
								left join hfjydb.view_tms_contract tc on tc.contract_id = tcp.contract_id
								inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tcp.submit_user_id
										   and cdme.stats_date = curdate() and cdme.class = 'CC'
										   and cdme.date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
								where tcp.pay_status in (2,4)
									  and tc.status<>8
								group by tc.contract_id, cdme.department_name
								having max(tcp.pay_date)>=date_sub(curdate(),interval 30 day)
									   and max(tcp.pay_date)<=date_sub(curdate(),interval 1 day)
									   and real_pay_amount>=contract_amount
									   ) as a on a.student_intention_id=lpo.student_intention_id 
					                             and a.department_name=cdme.department_name

					where lp.lesson_type = 2
						  and date(lpo.apply_time)>=date_sub(curdate(),interval 30 day)
						  and date(lpo.apply_time)<=date_sub(curdate(),interval 1 day)
						  and lp.status in (3,5) and lp.solve_status <> 6
						  and s.account_type = 1
						  ) as b
			group by b.department_name
			) as t2 on t2.department_name=t1.department_name



left join (
			   select tpel.track_userid, tpel.intention_id, tpel.into_pool_date, ui.name distri_user
	           from hfjydb.tms_pool_exchange_log tpel
	           inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tpel.track_userid
	                      and cdme.stats_date=curdate() and cdme.class = 'CC'
	                      and cdme.date>=date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
	           left join hfjydb.view_user_info ui on ui.user_id = tpel.create_userid
	           where date(tpel.into_pool_date)>=date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
	                 and date(tpel.into_pool_date)<=date_sub(curdate(),interval 1 day)
	           union all
	           select tnn.user_id as track_userid, tnn.student_intention_id as intention_id, tnn.create_time as into_pool_date, 'OC分配账号' distri_user
	           from hfjydb.tms_new_name_get_log tnn
	           inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tnn.user_id
	                      and cdme.stats_date=curdate() and cdme.class = 'CC'
	                      and cdme.date>=date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
	           where tnn.create_time >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
	                 and tnn.create_time < curdate()
	                 and student_intention_id <> 0

)