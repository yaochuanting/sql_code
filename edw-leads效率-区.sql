select t1.region_name,
	   t2.new_req,
	   concat(round(t2.bridge_new_req/t2.call_new_req*100,2),'%') new_req_call_bridge_rate,
	   t3.auto_new_keys,
	   t3.manual_new_keys,
	   t3.new_keys,
	   t3.bridge_new_keys,
	   concat(round(t3.bridge_new_keys/t3.new_keys*100,2),'%') new_keys_bridge_rate,
	   t3.valid_60_new_keys,
	   concat(round(t3.valid_60_new_keys/t3.new_keys*100,2),'%') new_keys_60_bridge_rate,
	   t3.valid_90_new_keys,
	   concat(round(t3.valid_90_new_keys/t3.new_keys*100,2),'%') new_keys_90_bridge_rate,
	   t2.all_oc_req,
	   concat(round(t2.bridge_all_oc_req/t2.call_all_oc_req*100,2),'%') all_oc_req_call_bridge_rate,
	   t3.auto_all_oc_keys,
	   t3.manual_all_oc_keys,
	   t3.all_oc_keys,
	   t3.bridge_all_oc_keys,
	   concat(round(t3.bridge_all_oc_keys/t3.all_oc_keys*100,2),'%') all_oc_keys_bridge_rate,
	   t3.valid_60_all_oc_keys,
	   concat(round(t3.valid_60_all_oc_keys/t3.all_oc_keys*100,2),'%') all_oc_keys_60_bridge_rate,
	   t3.valid_90_all_oc_keys,
	   concat(round(t3.valid_90_all_oc_keys/t3.all_oc_keys*100,2),'%') all_oc_keys_90_bridge_rate,
	   t4.staffs number



from (
		select concat(if(cdme.center is null,'',cdme.center),if(cdme.region is null,'',cdme.region)) region_name
		from dt_mobdb.dt_charlie_dept_month_end cdme
		where to_date(cdme.stats_date)='${analyse_date}'
			  and cdme.class='CC' and cdme.department_name like 'CC%'
			  and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')
		group by concat(if(cdme.center is null,'',cdme.center),if(cdme.region is null,'',cdme.region))
		) as t1

left join (
             select concat(if(cdme.center is null,'',cdme.center),if(cdme.region is null,'',cdme.region)) region_name,
				    count(distinct case when to_date(s.create_time)>=trunc('${analyse_date}','MM') then ss.student_intention_id end) as new_req,
				    count(distinct case when to_date(s.create_time)>=trunc('${analyse_date}','MM') and tcr.id is not null then ss.student_intention_id end) call_new_req,
				    count(distinct case when to_date(s.create_time)>=trunc('${analyse_date}','MM') and tcr.status=33 then ss.student_intention_id end) bridge_new_req,
				    count(distinct case when to_date(s.create_time)<trunc('${analyse_date}','MM') then ss.student_intention_id end) all_oc_req,
				    count(distinct case when to_date(s.create_time)<trunc('${analyse_date}','MM') and tcr.id is not null then ss.student_intention_id end) call_all_oc_req,
				    count(distinct case when to_date(s.create_time)<trunc('${analyse_date}','MM') and tcr.status=33 then ss.student_intention_id end) as bridge_all_oc_req

			 from dw_hf_mobdb.dw_ss_collection_sale_roster_action ss
			 left join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id=ss.user_id
					   and to_date(cdme.stats_date)='${analyse_date}' and cdme.class='CC'
					   and to_date(cdme.`date`)>=trunc('${analyse_date}','MM') 
			 left join dw_hf_mobdb.dw_view_student s on s.student_intention_id=ss.student_intention_id
			 left join dw_hf_mobdb.dw_view_tms_call_record tcr on ss.record_auto_id=tcr.id and tcr.call_type=1 -- 打给学生
			 where ss.view_time>=trunc('${analyse_date}','MM') and ss.view_time<='${analyse_date}'
			 group by concat(if(cdme.center is null,'',cdme.center),if(cdme.region is null,'',cdme.region))
			 ) as t2 on t2.region_name=t1.region_name

			 
left join (
             select 
					   a.region_name, 
					   count(distinct case when a.is_new=1 then a.intention_id end) new_keys, -- 获取的新线索量
					   count(distinct case when a.is_new=1 and c.max_bridge_time is not null then a.intention_id end) bridge_new_keys, -- 新线索接通量
					   count(distinct case when a.is_new=1 and c.max_bridge_time>=60 then a.intention_id end) valid_60_new_keys, -- 新线索60s接通量
					   count(distinct case when a.is_new=1 and c.max_bridge_time>=90 then a.intention_id end) valid_90_new_keys, -- 新线索90s接通量
					   count(distinct case when a.is_new=0 then a.intention_id end) all_oc_keys,  -- 获取的大盘oc线索量
					   count(distinct case when a.is_new=0 and c.max_bridge_time is not null then a.intention_id end) bridge_all_oc_keys,  -- 大盘oc线索接通量
					   count(distinct case when a.is_new=0 and c.max_bridge_time>=60 then a.intention_id end) valid_60_all_oc_keys,  -- 大盘oc线索60s接通量
					   count(distinct case when a.is_new=0 and c.max_bridge_time>=90 then a.intention_id end) valid_90_all_oc_keys,  -- 大盘oc线索90s接通量
					   count(distinct case when a.is_new=1 and b.is_auto=1 then a.intention_id end) auto_new_keys,  -- 主动获取新线索量
					   count(distinct case when a.is_new=1 and b.is_auto=0 then a.intention_id end) manual_new_keys,  -- 手动分配新线索量
					   count(distinct case when a.is_new=0 and b.is_auto=1 then a.intention_id end) auto_all_oc_keys,  -- 主动获取大盘oc线索量
					   count(distinct case when a.is_new=0 and b.is_auto=0 then a.intention_id end) manual_all_oc_keys  -- 手动分配大盘oc线索量
									 
		     from( 
						select tpel.track_userid, tpel.intention_id, tpel.into_pool_date,
							   case when to_date(s.create_time)>=trunc('${analyse_date}','MM') then 1 else 0 end is_new,
							   concat(if(cdme.center is null,'',cdme.center),if(cdme.region is null,'',cdme.region)) region_name
						from dw_hf_mobdb.dw_tms_pool_exchange_log tpel
						left join dw_hf_mobdb.dw_view_student s on s.student_intention_id=tpel.intention_id
						inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id=tpel.track_userid
							 and to_date(cdme.stats_date)='${analyse_date}' and cdme.class='CC'
							 and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')
						left join dw_hf_mobdb.dw_view_user_info ui on ui.user_id=tpel.create_userid
						where to_date(tpel.into_pool_date)>=trunc('${analyse_date}','MM')
							  and to_date(tpel.into_pool_date)<='${analyse_date}'
						union
						select tnn.user_id as track_userid, tnn.student_intention_id as intention_id, tnn.create_time as into_pool_date,
							   case when to_date(s.create_time)>=trunc('${analyse_date}','MM') then 1 else 0 end is_new,
							   concat(if(cdme.center is null,'',cdme.center),if(cdme.region is null,'',cdme.region)) region_name
						from dw_hf_mobdb.dw_tms_new_name_get_log tnn
						left join dw_hf_mobdb.dw_view_student s on s.student_intention_id=tnn.student_intention_id
						inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id=tnn.user_id
								   and to_date(cdme.stats_date)='${analyse_date}' and cdme.class='CC'
								   and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')
						where to_date(tnn.create_time)>=trunc('${analyse_date}','MM')
							  and to_date(tnn.create_time)<='${analyse_date}'
							  and tnn.student_intention_id<>0
							  ) as a							 
			
   			 left join (
							select bb.*, case when bb.distri_user in ('OC分配账号','自动分配销售') then 1 else 0 end is_auto
							from(
									select aa.track_userid, aa.intention_id, aa.distri_user,
									       row_number() over (partition by aa.intention_id order by aa.into_pool_date) as rn



									from(
											select tpel.track_userid, tpel.intention_id, tpel.into_pool_date, ui.name distri_user
											from dw_hf_mobdb.dw_tms_pool_exchange_log tpel
											left join dw_hf_mobdb.dw_view_student s on s.student_intention_id=tpel.intention_id
											inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id=tpel.track_userid
												 and to_date(cdme.stats_date)='${analyse_date}' and cdme.class='CC'
												 and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')
											left join dw_hf_mobdb.dw_view_user_info ui on ui.user_id=tpel.create_userid
											where to_date(tpel.into_pool_date)>=trunc('${analyse_date}','MM')
												  and to_date(tpel.into_pool_date)<='${analyse_date}'
											union
											select tnn.user_id as track_userid, tnn.student_intention_id as intention_id, tnn.create_time as into_pool_date, 'OC分配账号' distri_user
											from dw_hf_mobdb.dw_tms_new_name_get_log tnn
											left join dw_hf_mobdb.dw_view_student s on s.student_intention_id=tnn.student_intention_id
											inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id=tnn.user_id
													   and to_date(cdme.stats_date)='${analyse_date}' and cdme.class='CC'
													   and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')
											where to_date(tnn.create_time)>=trunc('${analyse_date}','MM')
												  and to_date(tnn.create_time)<='${analyse_date}'
												  and tnn.student_intention_id<>0
												  ) as aa
									) as bb
							where bb.rn=1
							) as b on b.intention_id=a.intention_id
 
			left join (
							select cc.region_name, cc.student_intention_id,max(cc.max_bridge_time) max_bridge_time

							from (

										 select
												 concat(if(cdme.center is null,'',cdme.center),if(cdme.region is null,'',cdme.region)) region_name,
												 tcr.student_intention_id,
												 max(unix_timestamp(tcr.end_time)-unix_timestamp(tcr.bridge_time)) max_bridge_time
										 from dw_hf_mobdb.dw_view_tms_call_record tcr
										 inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id=tcr.user_id
													and to_date(cdme.stats_date)='${analyse_date}' and cdme.class='CC'
													and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')
										 where to_date(tcr.end_time)>=trunc('${analyse_date}','MM')
											   and to_date(tcr.end_time)<='${analyse_date}'
											   and call_type=1 and tcr.status=33 -- 接通
										 group by concat(if(cdme.center is null,'',cdme.center),if(cdme.region is null,'',cdme.region)),tcr.student_intention_id

										 ) as cc
							group by cc.region_name, cc.student_intention_id
							) as c on c.region_name=a.region_name and c.student_intention_id=a.intention_id
			 group by a.region_name
			 ) as t3 on t3.region_name=t1.region_name

left join (
               select t.region_name,
			          sum(t.number) as staffs

               from(
		              select distinct cdme.department_name,
			                 concat(if(cdme.center is null,'',cdme.center),if(cdme.region is null,'',cdme.region)) region_name,
							 st.number
		              from hf_mobdb.sales_tab st
		              inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.department_name=st.group_name
				                 and to_date(cdme.stats_date)='${analyse_date}' and cdme.class='CC'
				                 and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')
								 ) as t
               group by t.region_name
			   ) as t4 on t4.region_name=t1.region_name