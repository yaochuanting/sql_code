select t1.*, t2.get_oc_keys, t2.oc_deal_num, t2.oc_deal_amount


from (
			select cdme.user_id, cdme.name, cdme.department_name
			from bidata.charlie_dept_month_end cdme
			where cdme.class = '销售' 
				  and cdme.stats_date = curdate()
				  and cdme.date >= '2020-02-01'
			      and (cdme.department_name like '销售_区_部'
			      or cdme.department_name like '销售考核_组')
			      ) as t1


left join (

				select b.track_userid, count(intention_id) as get_oc_keys, count(b.contract_id) as oc_deal_num, sum(b.real_pay_sum) as oc_deal_amount


				from(
								select distinct tpel.track_userid, tpel.intention_id, a.contract_id, a.real_pay_sum
								from hfjydb.tms_pool_exchange_log tpel
								left join hfjydb.view_student s on s.student_intention_id = tpel.intention_id
								inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tpel.track_userid
										   and cdme.stats_date = curdate() and cdme.class = '销售'
								left join (
											select
													max(tcp.pay_date) last_pay_date,
													tcp.contract_id,  
													tc.student_intention_id,
													tc.submit_user_id,
													sum(tcp.sum)/100 real_pay_sum, 
													(tc.sum-666)*10 contract_amount
											from hfjydb.view_tms_contract_payment tcp
											left join hfjydb.view_tms_contract tc on tcp.contract_id  = tc.contract_id
											left join hfjydb.view_user_info ui on ui.user_id = tc.submit_user_id
											inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tcp.submit_user_id
													   and cdme.stats_date = curdate() and cdme.class = '销售'
											where tcp.pay_status in (2,4)
												  and ui.account_type = 1
											group by tcp.contract_id
											having real_pay_sum >= contract_amount
												   and date(last_pay_date) >= '2020-02-01'
												   and date(last_pay_date) <= '2020-02-19'
												   ) as a on a.student_intention_id = tpel.intention_id
								                             and a.submit_user_id = tpel.track_userid

								where date(tpel.into_pool_date) >= '2020-02-01'
								      and date(tpel.into_pool_date) <= '2020-02-19'
								      and date(s.submit_time) < date_format(tpel.into_pool_date,'%Y-%m-01')
								      ) as b
				group by b.track_userid
				) as t2 on t2.track_userid = t1.user_id