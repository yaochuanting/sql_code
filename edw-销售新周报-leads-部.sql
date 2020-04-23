select  t1.department_name,
	   	t5.number,
	   	t2.tomonth_new_keys as get_new_keys,
	   	round(t2.tomonth_new_keys/t5.number,2) as ps_get_new_keys,
	   	t3.tomonth_new_plan_num as new_plan_num,
	   	round(t3.tomonth_new_plan_num/t5.number,2) as ps_new_plan_num,
	   	concat(round(t3.tomonth_new_plan_num/t2.tomonth_new_keys*100,2),'%') as new_plan_rate,
	   	concat(round(t3.lm_new_plan_num/t2.lm_new_keys*100,2),'%') as lm_new_plan_rate,
	   	t3.tomonth_new_trial_num as new_trial_num,
	   	concat(round(t3.tomonth_new_trial_num/t3.tomonth_new_plan_num*100,2),'%') as new_trial_rate,
	   	concat(round(t3.lm_new_trial_num/t3.lm_new_plan_num*100,2),'%') as lm_new_trial_rate,
	   	t3.tomonth_new_trial_deal as new_trial_deal,
	   	concat(round(t3.tomonth_new_trial_deal/t3.tomonth_new_trial_num*100,2),'%') as new_trial_deal_rate,
	   	concat(round(t3.lm_new_trial_deal/t3.lm_new_trial_num*100,2),'%') as lm_new_trial_deal_rate,
	   	t4.tomonth_new_deal_num as new_deal,
	   	round(t4.tomonth_new_deal_amount) as new_deal_amount,
	   	round(t4.tomonth_new_deal_amount/t4.tomonth_new_deal_num) as new_pct,
	   	concat(round(t4.tomonth_new_deal_num/t2.tomonth_new_keys*100,2),'%') as new_keys_conversion,
	   	t2.tomonth_oc_keys as get_oc_keys,
		round(t2.tomonth_oc_keys/t5.number,2) as ps_get_oc_keys,
		t3.tomonth_oc_plan_num as oc_plan_num,
		round(t3.tomonth_oc_plan_num/t5.number,2) as ps_oc_plan_num,
		concat(round(t3.tomonth_oc_plan_num/t2.tomonth_oc_keys*100,2),'%') as oc_plan_rate,
		t3.tomonth_oc_trial_num as oc_trial_num,
		concat(round(t3.tomonth_oc_trial_num/t3.tomonth_oc_plan_num*100,2),'%') as oc_trial_rate,
		t3.tomonth_oc_trial_deal as oc_trial_deal,
		concat(round(t3.tomonth_new_trial_deal/t3.tomonth_oc_trial_num*100,2),'%') as oc_trial_deal_rate,
		t4.tomonth_oc_deal_num as oc_deal_num,
		round(t4.tomonth_oc_deal_amount) as oc_deal_amount,
		round(t4.tomonth_oc_deal_amount/t4.tomonth_oc_deal_num) as oc_pct,
		concat(round(t4.tomonth_oc_deal_num/t2.tomonth_oc_keys*100,2),'%') as oc_keys_conversion


       

-- 销售架构		
from (			
			
		select cdme.department_name
		from dt_mobdb.dt_charlie_dept_month_end cdme 
		where to_date(cdme.stats_date)='${analyse_date}' and cdme.class = 'CC'
		      and cdme.department_name like 'CC%' 
		      and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')
		group by cdme.department_name
		) as t1

-- 获取粒子数
left join (
             select 
	                  a.department_name,
                      count(distinct case when a.time_type=2 and a.is_new=1 then a.student_intention_id end) tomonth_new_keys,  -- 当月获取的新粒子量
                      count(distinct case when a.time_type=1 and a.is_new=1 then a.student_intention_id end) lm_new_keys,  -- 上月同期获取的新粒子量
	                  count(distinct case when a.time_type=2 and a.is_new=0 then a.student_intention_id end) tomonth_oc_keys,  -- 当月获取的大盘oc粒子量
	                  count(distinct case when a.time_type=1 and a.is_new=0 then a.student_intention_id end) lm_oc_keys  -- 上月同期获取的大盘oc粒子量									 
             from
                   (
                       select tpel.track_userid, tpel.intention_id as student_intention_id, cdme.department_name,
                       		  case when to_date(s.create_time)>=trunc(to_date(tpel.into_pool_date),'MM') then 1 else 0 end is_new,
                       		  case when to_date(tpel.into_pool_date)<=add_months('${analyse_date}',-1) then 1
                       		       when to_date(tpel.into_pool_date)>=trunc('${analyse_date}','MM') then 2
                       		  else 3 end time_type
                       from dw_hf_mobdb.dw_tms_pool_exchange_log tpel
                       inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id = tpel.track_userid
	                              and to_date(cdme.stats_date)='${analyse_date}' and cdme.class = 'CC'
	                              and to_date(cdme.`date`)>=trunc(date_sub(trunc('${analyse_date}','MM'),1),'MM')
                       left join dw_hf_mobdb.dw_view_student s on s.student_intention_id=tpel.intention_id
                       where to_date(tpel.into_pool_date)>=trunc(date_sub(trunc('${analyse_date}','MM'),1),'MM')
	                         and to_date(tpel.into_pool_date)<='${analyse_date}'
                       union
                       select tnn.user_id as track_userid, tnn.student_intention_id, cdme.department_name,
                       	      case when to_date(s.create_time)>=trunc(to_date(tnn.create_time),'MM') then 1 else 0 end is_new,
                       		  case when to_date(tnn.create_time)<=add_months('${analyse_date}',-1) then 1
                       		       when to_date(tnn.create_time)>=trunc('${analyse_date}','MM') then 2
                       		  else 3 end time_type
                       from dw_hf_mobdb.dw_tms_new_name_get_log tnn
                       left join dw_hf_mobdb.dw_view_student s on s.student_intention_id=tnn.student_intention_id
                       inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id=tnn.user_id
	                              and to_date(cdme.stats_date)='${analyse_date}' and cdme.class = 'CC'
	                              and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')
                       where to_date(tnn.create_time)>=trunc(date_sub(trunc('${analyse_date}','MM'),1),'MM')
	                         and to_date(tnn.create_time)<='${analyse_date}'
	                         and tnn.student_intention_id<>0
							 ) as a							 
             group by a.department_name
			 ) as t2 on t2.department_name=t1.department_name

-- 邀约转化
left join (
             select
		              b.department_name,
                      count(distinct case when b.is_new=1 and b.time_type=2 then b.student_intention_id end) tomonth_new_plan_num, -- 当月新粒子试听邀约量
                      count(distinct case when b.is_new=1 and b.time_type=1 then b.student_intention_id end) lm_new_plan_num, -- 上月新粒子试听邀约量
		              count(distinct case when b.is_new=0 and b.time_type=2 then b.student_intention_id end) tomonth_oc_plan_num, -- 当月大盘oc粒子试听邀约量
					  count(distinct case when b.is_new=0 and b.time_type=1 then b.student_intention_id end) lm_oc_plan_num, -- 上月大盘oc粒子试听邀约量
		              count(distinct case when b.is_new=1 and b.is_trial=1 and b.time_type=2 then b.student_intention_id end) tomonth_new_trial_num, -- 当月新粒子试听出席量
		              count(distinct case when b.is_new=1 and b.is_trial=1 and b.time_type=1 then b.student_intention_id end) lm_new_trial_num, -- 上月新粒子试听出席量
                      count(distinct case when b.is_new=0 and b.is_trial=1 and b.time_type=2 then b.student_intention_id end) tomonth_oc_trial_num, -- 当月大盘oc试听出席量
                      count(distinct case when b.is_new=0 and b.is_trial=1 and b.time_type=1 then b.student_intention_id end) lm_oc_trial_num, -- 上月大盘oc试听出席量
		              count(distinct case when b.is_new=1 and b.is_trial_deal=1 and b.time_type=2 then b.student_intention_id end) tomonth_new_trial_deal, -- 当月新粒子试听成单量
		              count(distinct case when b.is_new=1 and b.is_trial_deal=1 and b.time_type=1 then b.student_intention_id end) lm_new_trial_deal, -- 上月新粒子试听成单量
		              count(distinct case when b.is_new=0 and b.is_trial_deal=1 and b.time_type=2 then b.student_intention_id end) tomonth_oc_trial_deal, -- 当月大盘oc粒子试听成单量
		              count(distinct case when b.is_new=0 and b.is_trial_deal=1 and b.time_type=1 then b.student_intention_id end) lm_oc_trial_deal -- 当月大盘oc粒子试听成单量
		
             from(    
                    select
							   lpo.student_intention_id, cdme.department_name, 
							   case when lp.status in (3,5) and lp.solve_status <> 6 then 1 else 0 end is_trial,
							   case when to_date(lp.adjust_start_time)<=add_months('${analyse_date}',-1) then 1
							        when to_date(lp.adjust_start_time)>=trunc('${analyse_date}','MM') then 2
							   else 3 end time_type,
							   case when to_date(s.create_time)>=trunc(to_date(lp.adjust_start_time),'MM') then 1 else 0 end is_new,
							   case when aa.real_pay_amount>0 then 1 else 0 end is_trial_deal			  			  
					from dw_hf_mobdb.dw_lesson_plan_order lpo
					left join dw_hf_mobdb.dw_lesson_relation lr on lpo.order_id = lr.order_id
					left join dw_hf_mobdb.dw_lesson_plan lp on lr.plan_id = lp.lesson_plan_id
					left join dw_hf_mobdb.dw_view_student s on s.student_intention_id = lpo.student_intention_id
					inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id = lpo.apply_user_id 
							   and to_date(cdme.stats_date)='${analyse_date}' and cdme.class = 'CC'
							   and to_date(cdme.`date`)>=trunc(date_sub(trunc('${analyse_date}','MM'),1),'MM')
				    left join (
									select 
										   tc.contract_id,
										   tc.student_intention_id,
										   sum(tcp.sum/100) real_pay_amount,
										   avg((tc.sum-666)*10) contract_amount,
										   month(max(tcp.pay_date)) pay_month,
										   tcp.submit_user_id,
										   cdme.department_name
									from dw_hf_mobdb.dw_view_tms_contract_payment tcp
									left join dw_hf_mobdb.dw_view_tms_contract tc on tc.contract_id = tcp.contract_id
									inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id = tcp.submit_user_id
											   and to_date(cdme.stats_date)='${analyse_date}' and cdme.class='CC'
											   and to_date(cdme.`date`)>=trunc(date_sub(trunc('${analyse_date}','MM'),1),'MM')
									where tcp.pay_status in (2,4)
										  and tc.status<>8
									group by tc.contract_id, tc.student_intention_id, tcp.submit_user_id, cdme.department_name
									having to_date(max(tcp.pay_date))>=trunc(date_sub(trunc('${analyse_date}','MM'),1),'MM')
										   and to_date(max(tcp.pay_date))<='${analyse_date}'
										   and not(to_date(max(tcp.pay_date))>add_months('${analyse_date}',-1) and to_date(max(tcp.pay_date))<trunc('${analyse_date}','MM'))
										   and round(sum(tcp.sum/100))>=round(avg((tc.sum-666)*10))
										   ) as aa on aa.student_intention_id=lpo.student_intention_id
													  and aa.department_name=cdme.department_name
													  and aa.pay_month=month(lp.adjust_start_time)
													     
             where lp.lesson_type=2
				   and to_date(lp.adjust_start_time)>=trunc(date_sub(trunc('${analyse_date}','MM'),1),'MM')
				   and to_date(lp.adjust_start_time)<='${analyse_date}'
				   and s.account_type=1
				   ) as b
             group by b.department_name
			 ) as t3 on t3.department_name=t1.department_name


-- 成单量
left join (
             select  
					a.department_name,
					count(case when a.time_type=2 and a.is_new=1 then a.contract_id end) as tomonth_new_deal_num,   -- 当月新线索成单量
					count(case when a.time_type=1 and a.is_new=1 then a.contract_id end) as lm_new_deal_num,   -- 上月月新线索成单量
					sum(case when a.time_type=2 and a.is_new=1 then a.real_pay_sum end) as tomonth_new_deal_amount,   -- 当月新粒子成单额
					sum(case when a.time_type=1 and a.is_new=1 then a.real_pay_sum end) as lm_new_deal_amount,   -- 上月新粒子成单额
					count(case when a.time_type=2 and a.is_new=0 then a.contract_id end) as tomonth_oc_deal_num,   -- 当月大盘oc粒子成单量
					count(case when a.time_type=1 and a.is_new=0 then a.contract_id end) as lm_oc_deal_num,   -- 上月大盘oc粒子成单量
					sum(case when a.time_type=2 and a.is_new=0 then a.real_pay_sum end) as tomonth_oc_deal_amount,   -- 当月大盘oc粒子成单额
					sum(case when a.time_type=1 and a.is_new=0 then a.real_pay_sum end) as lm_oc_deal_amount   -- 当月大盘oc粒子成单额

             from(
					select
							max(tcp.pay_date) last_pay_date,
							tcp.contract_id,  
							s.student_intention_id,
							cdme.department_name,
							case when to_date(max(s.create_time))>=trunc(max(tcp.pay_date),'MM') then 1 else 0 end is_new,
							case when to_date(max(tcp.pay_date))<=add_months('${analyse_date}',-1) then 1
							     when to_date(max(tcp.pay_date))>=trunc('${analyse_date}','MM') then 2
							else 3 end time_type,
							sum(tcp.sum)/100 real_pay_sum, 
							avg((tc.sum-666)*10) contract_amount
					from dw_hf_mobdb.dw_view_tms_contract_payment tcp
					left join dw_hf_mobdb.dw_view_tms_contract tc on tcp.contract_id  = tc.contract_id
					left join dw_hf_mobdb.dw_view_student s on s.student_intention_id = tc.student_intention_id
					left join dw_hf_mobdb.dw_view_user_info ui on ui.user_id = tc.submit_user_id
					inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id = tcp.submit_user_id
							   and to_date(cdme.stats_date)='${analyse_date}' and cdme.class = 'CC'
							   and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')
					where tcp.pay_status in (2,4)
						  and ui.account_type=1
					group by tcp.contract_id, s.student_intention_id, cdme.department_name
					having round(sum(tcp.sum)/100)>=round(avg((tc.sum-666)*10))
						   and to_date(max(tcp.pay_date))>=add_months(trunc('${analyse_date}','MM'),-1)
						   and to_date(max(tcp.pay_date))<='${analyse_date}'
						   ) as a
             group by a.department_name
			 ) as t4 on t4.department_name=t1.department_name

-- 销售指标和抗标人数
left join (
             select st.group_name, st.number
             from hf_mobdb.sales_tab st
             where st.group_name like 'CC%'
             ) as t5 on t5.group_name=t1.department_name