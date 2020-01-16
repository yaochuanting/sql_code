select 	t.month,
		count(t.student_intention_id) as key_num,
		sum(t.submit_to_view_time) as submit_to_view_time,
		count(case when t.min_view_time is not null then t.student_intention_id else null end) as view_num,
		sum(t.view_to_pool_time) as view_to_pool_time,
		count(case when t.min_into_pool_date is not null then t.student_intention_id else null end) as into_pool_num,
		sum(t.view_to_bridge_time) as view_to_bridge_time,
		count(case when min_bridge_time is not null then t.student_intention_id else null end) as bridge_num,
		sum(ifnull(t.view_to_bridge_tcr_call_cnt,0)+ifnull(t.view_to_bridge_wr_call_cnt,0)) as view_to_bridge_call_cnt,
		count(case when t.min_bridge_time is null then t.student_intention_id else null end) as no_bridge_num,
		count(case when t.call_cnt=0 and t.min_bridge_time is null then t.student_intention_id else null end) as call_0_cnt,
		count(case when t.call_cnt>=1 and t.call_cnt<=2 and t.min_bridge_time is null then t.student_intention_id else null end) as call_12_cnt,
		count(case when t.call_cnt>=3 and t.call_cnt<=5 and t.min_bridge_time is null then t.student_intention_id else null end) as call_35_cnt,
		count(case when t.call_cnt>=6 and t.min_bridge_time is null then t.student_intention_id else null end) as call_5_cnt





from(
			select 	date_format(x.submit_time, '%Y-%m') as month,
					x.student_intention_id,
					x.submit_time,
					x.min_view_time,
					case when x.min_into_pool_date>=x.min_view_time
					     then timestampdiff(second,x.submit_time,x.min_view_time)
					else null end as submit_to_view_time,
					x.min_into_pool_date,
					case when x.min_into_pool_date>=x.min_view_time
						 then timestampdiff(second,x.min_view_time,x.min_into_pool_date)
					else null end as view_to_pool_time,
					x.min_bridge_time,
					case when x.min_bridge_time>=x.min_view_time
						 then timestampdiff(second,x.min_view_time,x.min_bridge_time)
					else null end as view_to_bridge_time,
					ifnull(y.tcr_call_cnt,0)+ifnull(z.wr_call_cnt,0) as call_cnt,  -- 总拨打次数
					
					(select count(tcr.student_intention_id)
					 from hfjydb.tms_call_record tcr
					 inner join bidata.charlie_dept_month_end cdme on cdme.user_id=tcr.user_id
					            and cdme.class='销售' and cdme.stats_date=curdate()
					            and cdme.date>='2019-10-01' and cdme.name<>'张小影'
					 where tcr.start_time>=x.min_view_time and tcr.start_time<=x.min_bridge_time
					       and tcr.student_intention_id=x.student_intention_id
					       and tcr.call_type=1) as view_to_bridge_tcr_call_cnt,
			 		
			 		(select count(wr.student_intention_id)
			 		 from bidata.will_work_phone_call_recording wr
			 		 inner join bidata.charlie_dept_month_end cdme on cdme.user_id=wr.user_id
			 		            and cdme.class='销售' and cdme.stats_date=curdate()
					            and cdme.date>='2019-10-01' and cdme.name<>'张小影'
					 where wr.begin_time>=x.min_view_time and wr.begin_time<=x.min_bridge_time
					 	   and wr.student_intention_id=x.student_intention_id
					       and wr.is_call_out='True') as view_to_bridge_wr_call_cnt




			from(

						select  t1.student_intention_id,
								t1.submit_time,
								t1.min_view_time,
								t2.min_into_pool_date,
								t3.min_bridge_time


							   

						from(
									select s.student_intention_id, aa.min_view_time, s.submit_time

									from hfjydb.view_student s
									left join (
												select ss.student_intention_id, min(ss.view_time) as min_view_time
												from ss_collection_sale_roster_action ss
												inner join bidata.charlie_dept_month_end cdme on cdme.user_id=ss.user_id
												           and cdme.class='销售' and cdme.stats_date=curdate()
												           and cdme.date>='2019-10-01' and cdme.name<>'张小影'
												where date(ss.view_time)>='2019-10-01'
												group by ss.student_intention_id
												) as aa on aa.student_intention_id=s.student_intention_id

									where date(s.submit_time)>='2019-10-01' and date(s.submit_time)<='2019-12-31'
										  and aa.student_intention_id is not null
									) as t1



						left join (
										select tpel.intention_id, min(tpel.into_pool_date) as min_into_pool_date
										from hfjydb.tms_pool_exchange_log tpel
										inner join hfjydb.view_student s on s.student_intention_id=tpel.intention_id
										           and date(s.submit_time)>='2019-10-01' and date(s.submit_time)<='2019-12-31'
										inner join bidata.charlie_dept_month_end cdme on cdme.user_id=tpel.track_userid
												   and cdme.class='销售' and cdme.stats_date=curdate()
												   and cdme.date>='2019-10-01' and cdme.name<>'张小影'
										where date(tpel.into_pool_date)>='2019-10-01'
										group by tpel.intention_id
										) as t2 on t2.intention_id=t1.student_intention_id



						left join (
										
									select a.student_intention_id, min(min_bridge_time) as min_bridge_time

									from(
											select tcr.student_intention_id, min(tcr.bridge_time) as min_bridge_time
											from tms_call_record tcr 
											inner join hfjydb.view_student s on s.student_intention_id=tcr.student_intention_id
											           and date(s.submit_time)>='2019-10-01' and date(s.submit_time)<='2019-12-31'
											inner join bidata.charlie_dept_month_end cdme on cdme.user_id=tcr.user_id
											           and cdme.class='销售' and cdme.stats_date=curdate()
											           and cdme.date>='2019-10-01' and cdme.name<>'张小影'
											where tcr.start_time>='2019-10-01'
												  and tcr.call_type = 1
												  and tcr.status = 33
											group by tcr.student_intention_id

											union

											select wr.student_intention_id, min(wr.begin_time) as min_bridge_time
											from bidata.will_work_phone_call_recording wr
											inner join bidata.charlie_dept_month_end cdme on cdme.user_id=wr.user_id
											           and cdme.class='销售' and cdme.stats_date=curdate()
											           and cdme.date>='2019-10-01' and cdme.name<>'张小影'
											inner join hfjydb.view_student s on s.student_intention_id=wr.student_intention_id
											           and date(s.submit_time)>='2019-10-01' and date(s.submit_time)<='2019-12-31'
											where date(wr.begin_time)>='2019-10-01'
											      and wr.is_call_out='True' and wr.on_type=1
											group by wr.student_intention_id
											) as a
									group by a.student_intention_id
									) as t3 on t3.student_intention_id=t1.student_intention_id
						) as x



			left join (
							select tcr.student_intention_id, count(tcr.student_intention_id) as tcr_call_cnt
							from tms_call_record tcr
							inner join bidata.charlie_dept_month_end cdme on cdme.user_id=tcr.user_id
									   and cdme.class='销售' and cdme.stats_date=curdate()
									   and cdme.date>='2019-10-01' and cdme.name<>'张小影'
							where tcr.start_time>='2019-10-01'
							      and tcr.call_type=1
							group by tcr.student_intention_id
							) as y on y.student_intention_id=x.student_intention_id

			left join (
							select wr.student_intention_id, count(wr.student_intention_id) as wr_call_cnt
							from bidata.will_work_phone_call_recording wr
							inner join bidata.charlie_dept_month_end cdme on cdme.user_id=wr.user_id
							           and cdme.class='销售' and cdme.stats_date=curdate()
							           and cdme.date>='2019-10-01' and cdme.name<>'张小影'
							where wr.begin_time>='2019-10-01'
							      and wr.is_call_out='True'
							group by wr.student_intention_id
							) as z on z.student_intention_id=x.student_intention_id
			) as t


group by month




