select t1.region_name,
	   t6.staffs,
	   
	   t7.new_req,
	   round(t7.new_req/t6.staffs,2) ps_new_req,
	   t2.new_keys,
	   round(t2.new_keys/t6.staffs,2) ps_new_keys,
	   t3.new_apply_num,
	   concat(round(t3.new_apply_num/t7.new_req*100,2),'%') new_req_apply_rate,
	   concat(round(t3.new_apply_num/t2.new_keys*100,2),'%') new_keys_apply_rate,
	   t4.new_plan_num,
	   concat(round(t4.new_plan_num/t7.new_req*100,2),'%') new_req_plan_rate,
	   concat(round(t4.new_plan_num/t2.new_keys*100,2),'%') new_keys_plan_rate,
	   round(t4.new_plan_num/t6.staffs,2) ps_new_plan,
	   t4.new_trial_exp,
	   concat(round(t4.new_trial_exp/t4.new_plan_num*100,2),'%') new_exp_rate,
	   t4.new_trial_num,
	   concat(round(t4.new_trial_num/t4.new_plan_num*100,2),'%') new_trial_rate,
	   t4.new_trial_deal,
	   concat(round(t4.new_trial_deal/t4.new_trial_num*100,2),'%') new_trial_deal_rate,
	   round(t4.new_trial_deal/t6.staffs,2) ps_new_trial_deal,
	   t5.new_deal_num,
	   round(t5.new_deal_num/t6.staffs,2) ps_new_deal_num,
	   t5.new_deal_amount,
	   round(t5.new_deal_amount/t5.new_deal_num) new_pct,
	   concat(round(t5.new_deal_num/t7.new_req*100,2),'%') new_req_deal_rate,
	   concat(round(t5.new_deal_num/t2.new_keys*100,2),'%') new_keys_deal_rate,

	   t7.all_oc_req,
	   round(t7.all_oc_req/t6.staffs,2) ps_all_oc_req,
	   t2.all_oc_keys,
	   round(t2.all_oc_keys/t6.staffs,2) ps_all_oc_keys,
	   t3.all_oc_apply_num,
	   concat(round(t3.all_oc_apply_num/t7.all_oc_req*100,2),'%') all_oc_req_apply_rate,
	   concat(round(t3.new_apply_num/t7.all_oc_req*100,2),'%') all_oc_keys_apply_rate,
	   t4.all_oc_plan_num,
	   concat(round(t4.all_oc_plan_num/t7.all_oc_req*100,2),'%') all_oc_req_plan_rate,
	   concat(round(t4.all_oc_plan_num/t2.all_oc_keys*100,2),'%') all_oc_keys_plan_rate,
	   round(t4.all_oc_plan_num/t6.staffs,2) ps_all_oc_plan,
	   t4.all_oc_trial_exp,
	   concat(round(t4.all_oc_trial_exp/t4.all_oc_plan_num*100,2),'%') all_oc_exp_rate,
	   t4.all_oc_trial_num,
	   concat(round(t4.all_oc_trial_num/t4.all_oc_plan_num*100,2),'%') all_oc_trial_rate,
	   t4.all_oc_trial_deal,
	   concat(round(t4.all_oc_trial_deal/t4.all_oc_trial_num*100,2),'%') all_oc_trial_deal_rate,
	   round(t4.all_oc_trial_deal/t6.staffs,2) ps_all_oc_trial_deal,
	   t5.all_oc_deal_num,
	   round(t5.all_oc_deal_num/t6.staffs,2) ps_all_oc_deal_num,
	   t5.all_oc_deal_amount,
	   round(t5.all_oc_deal_amount/t5.all_oc_deal_num) all_oc_pct,
	   concat(round(t5.all_oc_deal_num/t7.all_oc_req*100,2),'%') all_oc_deal_rate,
	   concat(round(t5.all_oc_deal_num/t2.all_oc_keys*100,2),'%') all_oc_deal_rate,

	   t2.new_rec_keys,
	   round(t2.new_rec_keys/t6.staffs,2) ps_new_rec_keys,
	   t4.new_rec_plan_num,
	   concat(round(t4.new_rec_plan_num/t2.new_rec_keys*100,2),'%') new_rec_keys_plan_rate,
	   round(t4.new_rec_plan_num/t6.staffs,2) ps_new_rec_plan_num,
	   t4.new_rec_trial_exp,
	   concat(round(t4.new_rec_trial_exp/t4.new_rec_plan_num*100,2),'%') new_rec_exp_rate,
	   t4.new_rec_trial_num,
	   concat(round(t4.new_rec_trial_num/t4.new_rec_plan_num*100,2),'%') new_rec_trial_rate,
	   t4.new_rec_trial_deal,
	   concat(round(t4.new_rec_trial_deal/t4.new_rec_trial_num*100,2),'%') new_rec_trial_deal_rate,
	   round(t4.new_rec_trial_deal/t6.staffs,2) ps_new_rec_trial_deal,
	   t5.new_rec_deal_num,
	   round(t5.new_rec_deal_num/t6.staffs,2) ps_new_rec_deal_num,
	   t5.new_rec_deal_amount,
	   round(t5.new_rec_deal_amount/t5.new_rec_deal_num) new_rec_pct,
	   concat(round(t5.new_rec_deal_num/t2.new_rec_keys*100,2),'%') new_rec_deal_rate
	   
	   
			
from (					
			select concat(if(cdme.center is null,'', cdme.center), if(cdme.region is null,'',cdme.region)) region_name
			from dt_mobdb.dt_charlie_dept_month_end cdme
			where cdme.stats_date='${analyse_date}'
				  and cdme.class='CC' and cdme.department_name like 'CC%'
				  and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')
			group by concat(if(cdme.center is null,'', cdme.center),if(cdme.region is null,'',cdme.region))
			) as t1



left join (
             select 
                      concat(if(cdme.center is null,'', cdme.center), if(cdme.region is null,'',cdme.region)) region_name,
	                  count(distinct intention_id) all_keys, -- 获取的总线索量
                      count(distinct case when to_date(s.create_time)>=trunc('${analyse_date}','MM') then intention_id end) new_keys, -- 获取的新线索量
	                  count(distinct case when to_date(s.create_time)<trunc('${analyse_date}','MM') then intention_id end) all_oc_keys,  -- 获取的大盘oc线索量
	                  count(distinct case when to_date(s.create_time)>=trunc('${analyse_date}','MM') and (s.coil_in in (13,22) or s.know_origin in (56,71,22,24,25,41)) then intention_id end) new_rec_keys	 -- 获取新转介绍新线索量										 
             from
                   (
                       select tpel.track_userid, tpel.intention_id
                       from dw_hf_mobdb.dw_tms_pool_exchange_log tpel
                       inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id=tpel.track_userid
	                              and cdme.stats_date='${analyse_date}' and cdme.class='CC'
	                              and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')
                       left join dw_hf_mobdb.dw_view_user_info ui on ui.user_id=tpel.create_userid
                       where to_date(tpel.into_pool_date)>=trunc('${analyse_date}','MM')
	                         and to_date(tpel.into_pool_date)<='${analyse_date}'
                       union
                       select tnn.user_id as track_userid, tnn.student_intention_id as intention_id
                       from dw_hf_mobdb.dw_tms_new_name_get_log tnn
                       inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id=tnn.user_id
	                              and cdme.stats_date='${analyse_date}' and cdme.class='CC'
	                              and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')
                       where to_date(tnn.create_time)>=trunc('${analyse_date}','MM')
	                         and to_date(tnn.create_time)<='${analyse_date}' and student_intention_id<>0
							 ) as a							 

             left join dw_hf_mobdb.dw_view_student s on s.student_intention_id=a.intention_id
             left join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id=a.track_userid
                       and cdme.stats_date='${analyse_date}'
		               and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')

             group by concat(if(cdme.center is null,'', cdme.center), if(cdme.region is null,'',cdme.region))
			 ) as t2 on t2.region_name=t1.region_name


left join (
			select  bb.region_name,
			  		count(distinct case when bb.is_new=1 then bb.student_intention_id end) as new_apply_num,
			        count(distinct case when bb.is_new=0 then bb.student_intention_id end) as all_oc_apply_num

			from(
					select  lpo.student_intention_id, lpo.apply_user_id, s.student_no,
							case when to_date(s.create_time)>=trunc('${analyse_date}','MM') then 1 else 0 end is_new,
							concat(if(cdme.center is null,'', cdme.center),if(cdme.region is null,'',cdme.region)) region_name
					from dw_hf_mobdb.dw_lesson_plan_order lpo
					left join dw_hf_mobdb.dw_lesson_relation lr on lpo.order_id=lr.order_id
					left join dw_hf_mobdb.dw_lesson_plan lp on lr.plan_id=lp.lesson_plan_id
					left join dw_hf_mobdb.dw_view_student s on s.student_intention_id=lpo.student_intention_id
					inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id=lpo.apply_user_id 
							   and cdme.stats_date='${analyse_date}' and cdme.class='CC'
							   and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')
					where lp.lesson_type=2
						  and to_date(lpo.apply_time)>=trunc('${analyse_date}','MM')
						  and to_date(lpo.apply_time)<='${analyse_date}'
						  and s.account_type=1
						  ) as bb
			group by bb.region_name
			) as t3 on t3.region_name=t1.region_name

left join (
            select
                      b.region_name,
		              count(distinct b.student_intention_id) all_plan_num, -- 总试听邀约量
                      count(distinct case when b.is_new=1 then b.student_intention_id end) new_plan_num, -- 新线索试听邀约量
		              count(distinct case when b.is_new=0 then b.student_intention_id end) all_oc_plan_num, -- 大盘oc线索试听邀约量,
                      count(distinct case when b.is_rec=1 and b.is_new=1 then b.student_intention_id end) new_rec_plan_num, -- 转介绍线索试听邀约量
		              count(distinct case when b.is_trial=1 then b.student_intention_id end) all_trial_num, -- 总试听出席量
		              count(distinct case when b.is_new=1 and b.is_trial=1 then b.student_intention_id end) new_trial_num, -- 新线索试听出席量
                      count(distinct case when b.is_new=0 and b.is_trial=1 then b.student_intention_id end) all_oc_trial_num, -- 大盘oc试听出席量
                      count(distinct case when b.is_new=1 and b.is_rec=1 and b.is_trial=1 then b.student_intention_id end) new_rec_trial_num, -- 转介绍新线索试听出席量
	                  count(distinct case when b.is_trial_deal=1 then b.student_intention_id end) all_trial_deal, -- 总试听成单量
		              count(distinct case when b.is_new=1 and b.is_trial_deal=1 then b.student_intention_id end) new_trial_deal, -- 新线索试听成单量
		              count(distinct case when b.is_new=0 and b.is_trial_deal=1 then b.student_intention_id end) all_oc_trial_deal, -- 大盘oc线索试听成单量
		              count(distinct case when b.is_new=1 and b.is_trial_deal=1 and b.is_rec=1 then b.student_intention_id end) new_rec_trial_deal, -- 转介绍新线索试听成单量
		              count(distinct case when b.is_trial_exp=1 then b.student_intention_id end) all_trial_exp, -- 总体验课数量
		              count(distinct case when b.is_new=1 and b.is_trial_exp=1 then b.student_intention_id end) new_trial_exp, -- 新线索体验课数量
		              count(distinct case when b.is_new=0 and b.is_trial_exp=1 then b.student_intention_id end) all_oc_trial_exp, -- 大盘oc线索体验课数量
		              count(distinct case when b.is_new=1 and b.is_trial_exp=1 and b.is_rec=1 then b.student_intention_id end) new_rec_trial_exp -- 转介绍新线索体验课数量
		
            from(    
                    select
							   lpo.apply_user_id, lpo.student_intention_id, s.student_no,
							   concat(if(cdme.center is null,'', cdme.center), if(cdme.region is null,'',cdme.region)) region_name,
							   case when lp.status in (3,5) and lp.solve_status<>6 then 1 else 0 end is_trial,
							   case when to_date(s.create_time)>=trunc('${analyse_date}','MM') then 1 else 0 end is_new,
							   case when s.coil_in in (13,22) or s.know_origin in (56,71,22,24,25,41) then 1 else 0 end is_rec,
							   case when aa.real_pay_amount>0 then 1 else 0 end is_trial_deal,
							   case when lp2.student_id is not null then 1 else 0 end is_trial_exp			  			  
					from dw_hf_mobdb.dw_lesson_plan_order lpo
					left join dw_hf_mobdb.dw_lesson_relation lr on lpo.order_id=lr.order_id
					left join dw_hf_mobdb.dw_lesson_plan lp on lr.plan_id=lp.lesson_plan_id
					left join dw_hf_mobdb.dw_lesson_plan lp2 on lp2.student_id=lp.student_id and lp2.lesson_type=3 and lp2.status<>6 
					left join dw_hf_mobdb.dw_view_student s on s.student_intention_id=lpo.student_intention_id
					inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id=lpo.apply_user_id 
							   and cdme.stats_date='${analyse_date}' and cdme.class='CC'
							   and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')
				    left join (
									select min(tcp.pay_date) min_date,
										   tc.contract_id,
										   tc.student_intention_id,
										   sum(tcp.sum/100) real_pay_amount,
										   avg((tc.sum-666)*10) contract_amount,
										   concat(if(cdme.center is null,'', cdme.center), if(cdme.region is null,'',cdme.region)) region_name
									from dw_hf_mobdb.dw_view_tms_contract_payment tcp
									left join dw_hf_mobdb.dw_view_tms_contract tc on tc.contract_id=tcp.contract_id
									inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id=tcp.submit_user_id
											   and cdme.stats_date='${analyse_date}' and cdme.class='CC'
											   and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')
									where tcp.pay_status in (2,4) and tc.status<>8
									group by tc.contract_id, concat(if(cdme.center is null,'', cdme.center),if(cdme.region is null,'',cdme.region)), tc.student_intention_id
									having to_date(max(tcp.pay_date))>=trunc('${analyse_date}','MM')
										   and to_date(max(tcp.pay_date))<='${analyse_date}'
										   and round(sum(tcp.sum/100))>=round(avg((tc.sum-666)*10))
										   ) as aa on aa.student_intention_id=lpo.student_intention_id
													  and aa.region_name=concat(if(cdme.center is null,'', cdme.center), if(cdme.region is null,'',cdme.region))		   
		             where lp.lesson_type=2
						   and to_date(lp.adjust_start_time)>=trunc('${analyse_date}','MM')
						   and to_date(lp.adjust_start_time)<='${analyse_date}'
						   and s.account_type=1
						   ) as b
            group by region_name
            ) as t4 on t4.region_name=t1.region_name



left join (
             select  
                    a.region_name,
					count(a.contract_id) as all_deal_num,   -- 总成单量
					sum(a.real_pay_sum) as all_deal_amount,   -- 总成单额
					count(case when a.is_new=1 then a.contract_id end) as new_deal_num,   -- 新线索成单量
					sum(case when a.is_new=1 then a.real_pay_sum end) as new_deal_amount,   -- 新线索成单额
					count(case when a.is_new=0 then a.contract_id end) as all_oc_deal_num,   -- 大盘oc线索成单量
					sum(case when a.is_new=0 then a.real_pay_sum end) as all_oc_deal_amount,   -- 大盘oc线索成单额
					count(case when a.is_new=1 and a.is_rec=1 then a.contract_id end) as new_rec_deal_num,   -- 新线索转介绍成单量
					sum(case when a.is_new=1 and a.is_rec=1 then a.real_pay_sum end) as new_rec_deal_amount   -- 新线索转介绍成单额

             from(
					select
							min(tcp.pay_date) min_pay_date,
							to_date(max(tcp.pay_date)) last_pay_date,
							tcp.contract_id,  
							s.student_intention_id,
							concat(if(cdme.center is null,'',cdme.center),if(cdme.region is null,'',cdme.region)) region_name,
							avg(case when to_date(s.create_time)>=trunc('${analyse_date}','MM') then 1 else 0 end) is_new,
							avg(case when s.coil_in in (13,22) or s.know_origin in (56,71,22,24,25,41) then 1 else 0 end) is_rec,
							sum(tcp.sum/100) real_pay_sum, 
							avg((tc.sum-666)*10) contract_amount
					from dw_hf_mobdb.dw_view_tms_contract_payment tcp
					left join dw_hf_mobdb.dw_view_tms_contract tc on tcp.contract_id =tc.contract_id
					left join dw_hf_mobdb.dw_view_student s on s.student_intention_id=tc.student_intention_id
					left join dw_hf_mobdb.dw_view_user_info ui on ui.user_id=tc.submit_user_id
					inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id=tcp.submit_user_id
							   and cdme.stats_date='${analyse_date}' and cdme.class='CC'
							   and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')
					where tcp.pay_status in (2,4) and ui.account_type=1
					group by tcp.contract_id, s.student_intention_id, s.student_intention_id, concat(if(cdme.center is null,'',cdme.center),if(cdme.region is null,'',cdme.region))
					having round(sum(tcp.sum/100))>=avg((tc.sum-666)*10)
						   and to_date(max(tcp.pay_date))>=trunc('${analyse_date}','MM')
						   and to_date(max(tcp.pay_date))<='${analyse_date}'
						   ) as a
             group by a.region_name
			 ) as t5 on t5.region_name=t1.region_name


left join (
              select t.region_name,
			         sum(t.number) as staffs

              from(
		              select distinct cdme.department_name,
			                 concat(if(cdme.center is null,'',cdme.center),if(cdme.region is null,'',cdme.region)) region_name,
							 st.number
		              from hf_mobdb.sales_tab st
		              inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.department_name=st.group_name
				                 and cdme.stats_date='${analyse_date}' and cdme.class='CC'
				                 and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')
								 ) as t
               group by t.region_name
			   ) as t6 on t6.region_name=t1.region_name


left join (
             select concat(if(cdme.center is null,'',cdme.center),if(cdme.region is null,'',cdme.region)) region_name,
                    count(distinct case when to_date(s.create_time)>=trunc('${analyse_date}','MM') then ss.student_intention_id end) as new_req,
	                count(distinct case when to_date(s.create_time)<trunc('${analyse_date}','MM') then ss.student_intention_id end) as all_oc_req
             from dw_hf_mobdb.dw_ss_collection_sale_roster_action ss
             inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id=ss.user_id
                        and cdme.stats_date='${analyse_date}' and cdme.class='CC'
		                and to_date(cdme.`date`)>=trunc('${analyse_date}','MM') 
             left join dw_hf_mobdb.dw_view_student s on s.student_intention_id=ss.student_intention_id
             where ss.view_time>=trunc('${analyse_date}','MM')  and ss.view_time<='${analyse_date}'
             group by concat(if(cdme.center is null,'',cdme.center),if(cdme.region is null,'',cdme.region))
			 ) as t7 on t7.region_name=t1.region_name