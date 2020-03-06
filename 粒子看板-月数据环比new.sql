-- 新粒子月数据

select x.month as 年月,
       x.new_keys as 注册新粒子数, x.new_distri_keys as 新粒子分配数, y.new_req_sale_num as 新粒子分配销售人数, x.new_deal_num as 新粒子成单数,
       x.create_to_distri_diff as 注册到首次分配间隔h, x.create_call_diff as 注册到首次拨打间隔h, x.create_to_deal_diff as 注册到成单间隔h

from(

		select t1.month,
		       count(distinct t1.intention_id) as new_keys,
		       count(distinct case when t2.intention_id is not null then t1.intention_id end) as new_distri_keys,
		       count(t4.student_intention_id) as new_deal_num,
		       sum(case when t2.intention_id is not null then timestampdiff(hour, t1.create_time, t2.min_into_pool_date) end)/count(t2.intention_id) as create_to_distri_diff,
		       sum(case when t3.student_intention_id is not null then timestampdiff(hour, t1.create_time, t3.min_call_date) end)/count(t3.student_intention_id) as create_call_diff,
		       sum(case when t4.student_intention_id is not null then timestampdiff(hour, t1.create_time, t4.max_pay_date) end)/count(t4.student_intention_id) as create_to_deal_diff


		from (
				-- 属于销售的注册新粒子
				select date_format(s.create_time, '%Y-%m') as month, tpel.intention_id, s.create_time
		        from hfjydb.tms_pool_exchange_log tpel
		        left join hfjydb.view_student s on s.student_intention_id = tpel.intention_id
		        where (tpel.track_userid='23251' 
			           or (tpel.reason='学习中心注册' and tpel.track_userid is null and s.coil_in=12)
			           or (tpel.reason='学习中心注册' and tpel.track_userid is null and s.know_origin=55 and s.coil_in=13))
			           and s.coil_in <> 23 and s.know_origin <> 106
			           and (
				          		(date(s.create_time)>= date_sub(date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01'),interval 1 month) 
				          	     and date(s.create_time) < date_sub(curdate(), interval 1 month))              
				                 or 
				                (date(s.create_time) >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
				                  and date(s.create_time)< curdate()))
			          and (
			          		(date(tpel.into_pool_date) >= date_sub(date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01'),interval 1 month)
			          		 and date(tpel.into_pool_date) < date_sub(curdate(),interval 1 month))
			          		 or
			          		 (date(tpel.into_pool_date) >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
			          		  and date(tpel.into_pool_date) < curdate()))

			    group by tpel.intention_id
			    ) as t1


		left join (
					
					select 	a.intention_id, min(min_into_pool_date) as min_into_pool_date, date_format(min(min_into_pool_date),'%Y-%m') as month

					from(
							select tpel.intention_id, min(tpel.into_pool_date) as min_into_pool_date  
			                from hfjydb.tms_pool_exchange_log tpel
			                inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tpel.track_userid
			                           and cdme.stats_date = curdate() and cdme.class = '销售'
			                where ((date(tpel.into_pool_date) >= date_sub(date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01'),interval 1 month)
			                	    and date(tpel.into_pool_date) < date_sub(curdate(),interval 1 month))
			                        or
			                	    (date(tpel.into_pool_date) >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01') 
			                	     and date(tpel.into_pool_date)< curdate()))
			                group by tpel.intention_id
			                union all
			                select ss.student_intention_id as intention_id, min(ss.view_time) as min_into_pool_date
			                from ss_collection_sale_roster_action ss
			                inner join bidata.charlie_dept_month_end cdme on cdme.user_id = ss.user_id
			                           and cdme.stats_date = curdate() and cdme.class = '销售'
			                where ((date(ss.view_time) >= date_sub(date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01'),interval 1 day)
			                	    and date(ss.view_time) < date_sub(curdate(),interval 1 month))
			                		or
			                	    (date(ss.view_time) >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
			                	     and date(ss.view_time ) < curdate()))
			                	  and ss.student_intention_id <> 0
			                group by intention_id
			                ) as a
					group by a.intention_id
					) as t2 on t2.intention_id = t1.intention_id and t2.month = t1.month


		left join (

					select b.student_intention_id, min(b.min_call_date) as min_call_date, date_format(min(b.min_call_date),'%Y-%m') as month
					from(
							select tcr.student_intention_id, min(tcr.start_time) as min_call_date
							from hfjydb.view_tms_call_record tcr
							inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tcr.user_id
							           and cdme.class = '销售' and cdme.stats_date = curdate()
							inner join hfjydb.view_student s on s.student_intention_id = tcr.student_intention_id
							           and s.create_time >= date_sub(date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01'),interval 1 month)
							where ((date(tcr.start_time)>= date_sub(date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01'),interval 1 month)
								    and date(tcr.start_time) < date_sub(curdate(),interval 1 month))
							        or
				                   (date(tcr.start_time)>= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
				                    and date(tcr.start_time)< curdate()))
								  and call_type = 1 -- 打给学生
						    group by tcr.student_intention_id 
							union all
							select wr.student_intention_id, min(wr.begin_time) as min_call_date
							from  bidata.will_work_phone_call_recording wr
							inner join bidata.charlie_dept_month_end cdme on cdme.user_id = wr.user_id
							      and cdme.class = '销售' and cdme.stats_date = curdate()
							inner join hfjydb.view_student s on s.student_intention_id = wr.student_intention_id
							           and s.create_time >= date_sub(date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01'),interval 1 month)  
							where ((date(wr.begin_time)>= date_sub(date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01'),interval 1 month)
								    and date(wr.begin_time) < date_sub(curdate(),interval 1 month))
							        or
				                    (date(wr.begin_time) >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
				                    and date(wr.begin_time) < curdate()))
				            group by wr.student_intention_id
				            ) as b
					group by b.student_intention_id
					) as t3 on t3.student_intention_id = t1.intention_id and t3.month = t1.month


		left join (
					select 
			                  max(tcp.pay_date) as max_pay_date,
			                  date_format(max(tcp.pay_date),'%Y-%m') as month,
							  tc.contract_id,
							  tc.student_intention_id,
			                  s.create_time,
			                  s.student_no,
							  sum(tcp.sum/100) real_pay_amount,
							  (tc.sum-666) * 10 contract_amount
					from hfjydb.view_tms_contract_payment tcp
					left join hfjydb.view_tms_contract tc on tc.contract_id = tcp.contract_id
		            left join hfjydb.view_student s on s.student_intention_id=tc.student_intention_id
					inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tcp.submit_user_id
							   and cdme.stats_date = curdate() and cdme.class = '销售'
					where tcp.pay_status in (2,4) and tc.status <> 8
		                  and date(s.create_time) >= date_sub(date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01'),interval 1 month)
					group by tc.contract_id
					having (
							    (date(max(tcp.pay_date))>= date_sub(date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01'),interval 1 month)
							     and date(max(tcp.pay_date)) < date_sub(curdate(), interval 1 month))
						         or
			                    (date(max(tcp.pay_date))>= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')     
			                     and date(max(tcp.pay_date))< curdate())
			                    )
						   and real_pay_amount >= contract_amount
						   ) as t4 on t4.student_intention_id = t1.intention_id and t4.month = t1.month


		group by t1.month
		) as x


left join (

				select   c.month, count(distinct c.track_userid) as new_req_sale_num

				from(

				          select tpel.track_userid, date_format(tpel.into_pool_date,'%Y-%m') as month
				          from hfjydb.tms_pool_exchange_log tpel
				          left join hfjydb.view_student s on s.student_intention_id = tpel.intention_id
				          inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tpel.track_userid
				                     and cdme.stats_date = curdate() and cdme.class = '销售'
				          where ((date(tpel.into_pool_date) >= date_sub(date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01'),interval 1 month)
				                  and date(tpel.into_pool_date) < date_sub(curdate(),interval 1 month))
				                  or
				                 (date(tpel.into_pool_date) >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01') 
				                   and date(tpel.into_pool_date)< curdate()))
				                and s.create_time >= date_format(tpel.into_pool_date,'%Y-%m-01')
				          union 
				          select ss.user_id, date_format(ss.view_time,'%Y-%m') as month
				          from ss_collection_sale_roster_action ss
				          left join hfjydb.view_student s on s.student_intention_id = ss.student_intention_id
				          inner join bidata.charlie_dept_month_end cdme on cdme.user_id = ss.user_id
				                     and cdme.stats_date = curdate() and cdme.class = '销售'
				          where ((date(ss.view_time) >= date_sub(date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01'),interval 1 day)
				                  and date(ss.view_time) < date_sub(curdate(),interval 1 month))
				                  or
				                  (date(ss.view_time) >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
				                   and date(ss.view_time ) < curdate()))
				                and ss.student_intention_id <> 0
				                and s.create_time >= date_format(ss.view_time,'%Y-%m-01')
				                ) as c
				group by c.month
				) as y on y.month = x.month


