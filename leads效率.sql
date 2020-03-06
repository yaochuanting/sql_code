select x.stats_date 统计日期,
       x.region_name 区,
	   y.new_req 新线索触碰量,
	   y.call_new_req 新线索触碰拨打,
	   y.bridge_new_req 新线索触碰接通,
	   z.auto_new_keys 主动获取新线索量,
	   z.manual_new_keys 手动分配新线索量,
	   z.new_keys 实获新线索量,
	   z.bridge_new_keys 新线索接通量,
	   z.valid_60_new_keys 新线索60秒接通量,
	   z.valid_90_new_keys 新线索90秒接通量,
	   y.all_oc_req 大盘oc触碰量,
	   y.call_all_oc_req 大盘oc触碰拨打,
	   y.bridge_all_oc_req 大盘oc触碰接通,
	   z.auto_all_oc_keys 主动获取大盘oc线索量,
	   z.manual_all_oc_keys 手动分配大盘oc线索量,
	   z.all_oc_keys 实获大盘oc线索量,
	   z.bridge_all_oc_keys 大盘oc线索接通量,
	   z.valid_60_all_oc_keys 大盘oc线索60秒接通量,
	   z.valid_90_all_oc_keys 大盘oc线索90秒接通量,
	   xx.staffs 月初抗标人数



from (
		select  date_sub(curdate(),interval 1 day) stats_date,
				concat(ifnull(cdme.center,''),ifnull(cdme.region,'')) region_name
		from bidata.charlie_dept_month_end cdme
		where cdme.stats_date = curdate()
			  and cdme.class = 'CC'
			  and cdme.department_name like 'CC%'
			  and cdme.date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
		group by stats_date, region_name
		) as x

left join (
             select date_sub(curdate(), interval 1 day) stats_date,
                    concat(ifnull(cdme.center,''),ifnull(cdme.region,'')) region_name,
				    count(distinct case when s.submit_time >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01') 
									    then ss.student_intention_id else null end) as new_req,
				    count(distinct case when s.submit_time >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
											 and tcr.id is not null
									    then ss.student_intention_id else null end) as call_new_req,
				    count(distinct case when s.submit_time >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
											 and tcr.status = 33
									    then ss.student_intention_id else null end) as bridge_new_req,
				    count(distinct case when s.submit_time >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
											 and tcr.status <> 33 and tcr.id is not null
											 and timestampdiff(second, tcr.start_time, tcr.end_time) <= 5	
									    then ss.student_intention_id else null end) as nobridge_wt5_new_req,
				    count(distinct case when s.submit_time < date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01') 
									    then ss.student_intention_id else null end) as all_oc_req,
				    count(distinct case when s.submit_time < date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
											 and tcr.id is not null	   
									    then ss.student_intention_id else null end) as call_all_oc_req,
				    count(distinct case when s.submit_time < date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01') 
											 and tcr.status = 33
									    then ss.student_intention_id else null end) as bridge_all_oc_req,
				    count(distinct case when s.submit_time < date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01') 
											 and tcr.status <> 33 and tcr.id is not null
											 and timestampdiff(second, tcr.start_time, tcr.end_time) <= 5
									    then ss.student_intention_id else null end) as nobridge_wt5_all_oc_req

			 from hfjydb.ss_collection_sale_roster_action ss
			 left join bidata.charlie_dept_month_end cdme on cdme.user_id = ss.user_id
					   and cdme.stats_date = curdate() and cdme.class = 'CC'
					   and cdme.date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01') 
			 left join hfjydb.view_student s on s.student_intention_id = ss.student_intention_id
			 left join hfjydb.tms_call_record tcr on ss.record_auto_id = tcr.id
					   and tcr.call_type = 1 -- 打给学生
			 where ss.view_time >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01') 
				   and ss.view_time < curdate()
			 group by region_name, stats_date
			 ) as y on y.region_name = x.region_name and y.stats_date = x.stats_date

			 
left join (
             select 
					   a.region_name, date_sub(curdate(), interval 1 day) stats_date,
					   count(distinct case when s.submit_time >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
										   then a.intention_id end) new_keys, -- 获取的新线索量
					   count(distinct case when s.submit_time >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
												and b.max_bridge_time is not null
										   then a.intention_id end) bridge_new_keys, -- 新线索接通量
					   count(distinct case when s.submit_time >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
												and b.max_bridge_time >= 60
										   then a.intention_id end) valid_60_new_keys, -- 新线索60s接通量
					   count(distinct case when s.submit_time >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
												and b.max_bridge_time >= 90
										   then a.intention_id end) valid_90_new_keys, -- 新线索90s接通量
					   count(distinct case when s.submit_time < date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
										   then a.intention_id end) all_oc_keys,  -- 获取的大盘oc线索量
					   count(distinct case when s.submit_time < date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
												and b.max_bridge_time is not null
										   then a.intention_id end) bridge_all_oc_keys,  -- 大盘oc线索接通量
					   count(distinct case when s.submit_time < date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
												and b.max_bridge_time >= 60
										   then a.intention_id end) valid_60_all_oc_keys,  -- 大盘oc线索60s接通量
					   count(distinct case when s.submit_time < date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
												and b.max_bridge_time >= 90
										   then a.intention_id end) valid_90_all_oc_keys,  -- 大盘oc线索90s接通量
					   count(distinct case when s.submit_time >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
												and t.distri_type = 'auto'
										   then a.intention_id end) auto_new_keys,  -- 主动获取新线索量
					   count(distinct case when s.submit_time >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
												and t.distri_type = 'manual'
										   then a.intention_id end) manual_new_keys,  -- 手动分配新线索量
					   count(distinct case when s.submit_time < date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
												and t.distri_type = 'auto'
										   then a.intention_id end) auto_all_oc_keys,  -- 主动获取大盘oc线索量
					   count(distinct case when s.submit_time < date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
												and t.distri_type = 'manual'
										   then a.intention_id end) manual_all_oc_keys  -- 手动分配大盘oc线索量
									 
		     from( 
						select tpel.track_userid, tpel.intention_id, tpel.into_pool_date, ui.name distri_user,
							   concat(ifnull(cdme.center,''),ifnull(cdme.region,'')) region_name
						from hfjydb.tms_pool_exchange_log tpel
						inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tpel.track_userid
							 and cdme.stats_date = curdate() and cdme.class = 'CC'
							 and cdme.date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
						left join hfjydb.view_user_info ui on ui.user_id = tpel.create_userid
						where tpel.into_pool_date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
							  and tpel.into_pool_date < curdate()
						union all
						select tnn.user_id as track_userid, tnn.student_intention_id as intention_id, tnn.create_time as into_pool_date, 'OC分配账号' distri_user,
							   concat(ifnull(cdme.center,''),ifnull(cdme.region,'')) region_name
						from hfjydb.tms_new_name_get_log tnn
						inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tnn.user_id
								   and cdme.stats_date = curdate() and cdme.class = 'CC'
								   and cdme.date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
						where tnn.create_time >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
							  and tnn.create_time < curdate()
							  and student_intention_id <> 0
							  ) as a							 
			
   			 left join (
							  select t2.track_userid, t2.intention_id, t2.into_pool_date, t2.distri_user,
									 case when t2.distri_user in ('OC分配账号','自动分配销售') then 'auto' else 'manual' end as distri_type

							  from(

										  select tpel.track_userid, tpel.intention_id, tpel.into_pool_date, ui.name distri_user
										  from hfjydb.tms_pool_exchange_log tpel
										  inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tpel.track_userid
													 and cdme.stats_date = curdate() and cdme.class = 'CC'
													 and cdme.date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
										  left join hfjydb.view_user_info ui on ui.user_id = tpel.create_userid
										  where tpel.into_pool_date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
												and tpel.into_pool_date < curdate()
										  union all
										  select tnn.user_id as track_userid, tnn.student_intention_id as intention_id, tnn.create_time as into_pool_date, 'OC分配账号' distri_user
										  from hfjydb.tms_new_name_get_log tnn
										  inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tnn.user_id
													 and cdme.stats_date = curdate() and cdme.class = 'CC'
													 and cdme.date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
										  where tnn.create_time >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
												and tnn.create_time < curdate()
												and student_intention_id <> 0
												) as t2
		
		
							  inner join(		
					                         select min(t1.into_pool_date) as min_into_pool_date,t1.intention_id
											 from(
														select tpel.track_userid, tpel.intention_id, tpel.into_pool_date, ui.name distri_user
														from hfjydb.tms_pool_exchange_log tpel
														inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tpel.track_userid
																   and cdme.stats_date = curdate() and cdme.class = 'CC'
																   and cdme.date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
														left join hfjydb.view_user_info ui on ui.user_id = tpel.create_userid
														where tpel.into_pool_date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
															  and tpel.into_pool_date < curdate()
														union all
														select tnn.user_id as track_userid, tnn.student_intention_id as intention_id, tnn.create_time as into_pool_date, 'OC分配账号' distri_user
														from hfjydb.tms_new_name_get_log tnn
														inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tnn.user_id
																   and cdme.stats_date = curdate() and cdme.class = 'CC'
																   and cdme.date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
														where tnn.create_time >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
															  and tnn.create_time < curdate()
															  and student_intention_id <> 0
															  ) as t1

				              group by t1.intention_id
							  ) as t3 on t2.into_pool_date = t3.min_into_pool_date 
							             and t2.intention_id = t3.intention_id
										 ) as t on t.intention_id = a.intention_id
 
			left join (
									select bb.region_name, bb.student_intention_id,max(bb.max_bridge_time) max_bridge_time

									from (

												 select
														 concat(ifnull(cdme.center,''),ifnull(cdme.region,'')) region_name,
														 tcr.student_intention_id,
														 max(timestampdiff(second, bridge_time, end_time)) max_bridge_time
												 from hfjydb.view_tms_call_record tcr
												 inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tcr.user_id
															and cdme.stats_date = curdate()
															and cdme.class = 'CC'
															and cdme.date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
												 where tcr.end_time >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
													   and tcr.end_time < curdate()
													   and call_type = 1 -- 打给学生
													   and tcr.status = 33 -- 接通
												 group by region_name,tcr.student_intention_id
											
												 union all
											
												 select
														 concat(ifnull(cdme.center,''),ifnull(cdme.region,'')) region_name,
														 wr.student_intention_id,
														 max(calling_seconds) max_bridge_time
												 from  bidata.will_work_phone_call_recording wr
												 inner join bidata.charlie_dept_month_end cdme on cdme.user_id = wr.user_id
															and cdme.stats_date = curdate() and cdme.class = 'CC' 
															and cdme.date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
												 where wr.begin_time < curdate()
													   and wr.begin_time >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
													   and on_type = 1 -- 接通
												 group by region_name, wr.student_intention_id
												 ) as bb
									group by bb.region_name, bb.student_intention_id
									) as b on b.region_name = a.region_name 
											  and b.student_intention_id = a.intention_id

			 left join hfjydb.view_student s on s.student_intention_id = a.intention_id
			 left join bidata.charlie_dept_month_end cdme on cdme.user_id = a.track_userid
					   and cdme.stats_date = curdate()
					   and cdme.date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
			 group by region_name, stats_date
			 ) as z on z.region_name = x.region_name and z.stats_date = x.stats_date

left join (
               select date_sub(curdate(),interval 1 day) stats_date,
                     region_name,
			         sum(number) as staffs

               from(
		              select distinct cdme.department_name,
			                 concat(ifnull(cdme.center,''),ifnull(cdme.region,'')) region_name,
							 st.number
		              from bidata.sales_tab st
		              inner join bidata.charlie_dept_month_end cdme on cdme.department_name = st.group_name
				                 and cdme.stats_date = curdate() and cdme.class = 'CC'
				                 and cdme.date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
								 ) as t
               group by region_name, stats_date
			   ) as xx on xx.region_name = x.region_name and xx.stats_date = x.stats_date