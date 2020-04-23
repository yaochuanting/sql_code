select  t1.department_name,
		t5.new_keys,
		t2.apply_num,
		t3.plan_num, 
		t3.trial_num,
		concat(round(t3.trial_num/t3.plan_num*100,2),'%') as trial_rate,
		t4.new_deal_num, 
		concat(round(t4.new_deal_num/t5.new_keys*100,2),'%') as new_deal_rate


from (
		select cdme.department_name
		from dt_mobdb.dt_charlie_dept_month_end cdme
		where to_date(cdme.stats_date)='${analyse_date}'
			  and cdme.class='CC' and cdme.department_name like 'CC%'
			  and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')
		group by cdme.department_name
		) as t1


left join(
			select  count(distinct lpo.student_intention_id) as apply_num,
					cdme.department_name
			from dw_hf_mobdb.dw_lesson_plan_order lpo
			left join dw_hf_mobdb.dw_lesson_relation lr on lpo.order_id=lr.order_id
			left join dw_hf_mobdb.dw_lesson_plan lp on lr.plan_id=lp.lesson_plan_id
			left join dw_hf_mobdb.dw_view_student s on s.student_intention_id=lpo.student_intention_id
			inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id=lpo.apply_user_id 
					   and to_date(cdme.stats_date)='${analyse_date}' and cdme.class='CC'
					   and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')
			where lp.lesson_type=2
				  and lpo.apply_time>=trunc('${analyse_date}','MM')
				  and lpo.apply_time<='${analyse_date}' and s.account_type=1
			group by cdme.department_name
			) as t2 on t2.department_name=t1.department_name


left join (
			
			select  aa.department_name,
					count(distinct aa.student_intention_id) as plan_num,
					count(distinct case when aa.is_trial=1 then aa.student_intention_id end) as trial_num
			from(
						select  lpo.apply_user_id, lpo.student_intention_id, cdme.department_name,
								case when lp.status in (3,5) and lp.solve_status<>6 then 1 else 0 end as is_trial
						  			  
						from dw_hf_mobdb.dw_lesson_plan_order lpo
						left join dw_hf_mobdb.dw_lesson_relation lr on lpo.order_id=lr.order_id
						left join dw_hf_mobdb.dw_lesson_plan lp on lr.plan_id=lp.lesson_plan_id
						left join dw_hf_mobdb.dw_view_student s on s.student_intention_id=lpo.student_intention_id
						inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id=lpo.apply_user_id 
								   and to_date(cdme.stats_date)='${analyse_date}' and cdme.class='CC'
								   and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')
						where lp.lesson_type=2
							   and to_date(lp.adjust_start_time)>=trunc('${analyse_date}','MM')
							   and to_date(lp.adjust_start_time)<='${analyse_date}'
							   and s.account_type=1
							   ) as aa
			group by aa.department_name
			) as t3 on t3.department_name=t1.department_name


left join(
			select  bb.department_name,
					count(bb.contract_id) as new_deal_num,
					sum(bb.real_pay_sum) as new_deal_amount

			from(		
						select  max(tcp.pay_date) last_pay_date,
								tcp.contract_id,  
								s.student_intention_id,
								cdme.department_name,
								sum(tcp.sum/100) real_pay_sum, 
								avg((tc.sum-666)*10) contract_amount
						from dw_hf_mobdb.dw_view_tms_contract_payment tcp
						left join dw_hf_mobdb.dw_view_tms_contract tc on tcp.contract_id=tc.contract_id
						left join dw_hf_mobdb.dw_view_student s on s.student_intention_id=tc.student_intention_id
						left join dw_hf_mobdb.dw_view_user_info ui on ui.user_id=tc.submit_user_id
						inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id=tcp.submit_user_id
								   and to_date(cdme.stats_date)='${analyse_date}' and cdme.class='CC'
								   and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')
						where tcp.pay_status in (2,4)
							  and ui.account_type=1
							  and s.submit_time>=trunc('${analyse_date}','MM')
							  and tc.status<>8
						group by tcp.contract_id, s.student_intention_id, cdme.department_name
						having round(sum(tcp.sum/100))>=round(avg((tc.sum-666)*10))
							   and to_date(max(tcp.pay_date))>=trunc('${analyse_date}','MM')
							   and to_date(max(tcp.pay_date))<='${analyse_date}'
							   ) as bb
			group by bb.department_name
			) as t4 on t4.department_name=t1.department_name


left join (
			select  cc.department_name,
					count(distinct cc.intention_id) as new_keys		
			from(
						select cdme.department_name, tpel.intention_id
			            from dw_hf_mobdb.dw_tms_pool_exchange_log tpel
			            left join dw_hf_mobdb.dw_view_student s on s.student_intention_id=tpel.intention_id
			            inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id=tpel.track_userid
				                   and to_date(cdme.stats_date)='${analyse_date}' and cdme.class='CC'
				                   and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')
			            where to_date(tpel.into_pool_date)>=trunc('${analyse_date}','MM')
				              and to_date(tpel.into_pool_date)<='${analyse_date}'
				              and to_date(s.submit_time)>=trunc('${analyse_date}','MM')
			            union
			            select cdme.department_name, tnn.student_intention_id as intention_id
			            from dw_hf_mobdb.dw_tms_new_name_get_log tnn
			            left join dw_hf_mobdb.dw_view_student s on s.student_intention_id=tnn.student_intention_id
			            inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id=tnn.user_id
				                   and to_date(cdme.stats_date)='${analyse_date}' and cdme.class='CC'
				                   and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')
			            where to_date(tnn.create_time)>=trunc('${analyse_date}','MM')
				              and to_date(tnn.create_time)<='${analyse_date}'
				              and tnn.student_intention_id<>0
				              and to_date(s.submit_time)>=trunc('${analyse_date}','MM')
				              ) as cc
			group by cc.department_name
			) as t5 on t5.department_name=t1.department_name
