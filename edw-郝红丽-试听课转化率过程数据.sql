-- 试听课转化率过程数据
select
          count(distinct case when b.time_type=1 then b.student_intention_id end) plan_num  -- 本月试听邀约量
          ,count(distinct case when b.time_type=1 and b.is_trial_exp=1 then b.student_intention_id end) trial_exp -- 本月试听课调试数
          ,count(distinct case when b.time_type=1 and b.is_trial=1 then b.student_intention_id end) trial_num -- 本月试听出席量
          ,count(distinct case when b.time_type=1 and b.is_sale_enter=1 then b.student_intention_id end) sale_enter_num  -- 本月销售进课堂数
          ,count(distinct case when b.time_type=1 and b.is_trial_deal=1 then b.student_intention_id end) trial_deal -- 本月试听成单量
          ,count(distinct case when b.time_type=1 and b.hour_diff <= 24 then b.student_intention_id end) plan_deal_in_24h  -- 本月24小时内试听成单数
          ,count(distinct case when b.time_type=2 then b.student_intention_id end) lm_plan_num  --上月同期试听邀约量
          ,count(distinct case when b.time_type=2 and b.hour_diff <= 24 then b.student_intention_id end) lm_plan_deal_in_24h -- 上月同期24h试听成单数
          ,round(sum(case when b.time_type=1 then hour_diff end),2) total_hour_diff  -- 本月试听-成单总时长
          ,count(distinct case when b.time_type=2 and b.is_trial_deal=1 then b.student_intention_id end) lm_trial_deal  -- 上月同期试听成单量
          ,round(sum(case when b.time_type=2 then hour_diff end),2) lm_total_hour_diff  -- 上月同期试听-成单总时长
          ,count(case when b.time_type=1 and b.hour_diff>0 then b.student_intention_id end) hourdiff_notnull  -- 成单最小支付大于试听完成时间
          ,count(case when b.time_type=2 and b.hour_diff>0 then b.student_intention_id end) lm_hourdiff_notnull  -- 上月同期成单最小支付大于试听完成时间





from(    
        select
				   lpo.apply_user_id, lpo.student_intention_id, s.student_no,
				   case when to_date(lp.adjust_start_time) >= trunc('${analyse_date}','MM') then 1
				        when to_date(lp.adjust_start_time) <= add_months('${analyse_date}',-1) then 2
				   else 3 end time_type,
				   case when lp2.student_id is not null then 1 else 0 end is_trial_exp,
				   case when lp.status in (3,5) and lp.solve_status<>6 then 1 else 0 end is_trial,
				   case when sl.lessonplanid is not null then 1 else 0 end is_sale_enter,
				   case when aa.real_pay_amount>0 then 1 else 0 end is_trial_deal,
				   case when (unix_timestamp(aa.min_date)-unix_timestamp(lp.adjust_end_time))/3600 >0 
				        then (unix_timestamp(aa.min_date)-unix_timestamp(lp.adjust_end_time))/3600 else null end hour_diff

		from dw_hf_mobdb.dw_lesson_plan_order lpo
		left join dw_hf_mobdb.dw_lesson_relation lr on lpo.order_id=lr.order_id
		left join dw_hf_mobdb.dw_lesson_plan lp on lr.plan_id=lp.lesson_plan_id
		left join dw_hf_mobdb.dw_lesson_plan lp2 on lp2.student_id=lp.student_id and lp2.lesson_type=3 and lp2.status<>6 
		left join dw_hf_mobdb.dw_view_student s on s.student_intention_id=lpo.student_intention_id
		left join dw_hf_mobdb.dw_smp_log_room_event_his_202004 sl on sl.lessonplanid = lp.lesson_plan_id
		          and sl.usertype = 5 and sl.eventtype = 1 and sl.currenttimestamp >= lp.adjust_start_time
		inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id=lpo.apply_user_id 
				   and cdme.stats_date='${analyse_date}' and cdme.class='CC'
				   and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')
	    left join (
						select min(tcp.pay_date) min_date,
							   tc.contract_id,
							   tc.student_intention_id,
							   sum(tcp.sum/100) real_pay_amount,
							   avg((tc.sum-666)*10) contract_amount
						from dw_hf_mobdb.dw_view_tms_contract_payment tcp
						left join dw_hf_mobdb.dw_view_tms_contract tc on tc.contract_id=tcp.contract_id
						inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id=tcp.submit_user_id
								   and cdme.stats_date='${analyse_date}' and cdme.class='CC'
								   and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')
						where tcp.pay_status in (2,4) and tc.status<>8
						group by tc.contract_id, tc.student_intention_id
						having to_date(max(tcp.pay_date)) >= add_months(trunc('${analyse_date}','MM'),-1)
							   and to_date(max(tcp.pay_date)) <= '${analyse_date}'
							   and not(to_date(max(tcp.pay_date)) > add_months('${analyse_date}',-1) and to_date(max(tcp.pay_date)) < trunc('${analyse_date}','MM'))
							   and round(sum(tcp.sum/100)) >= round(avg((tc.sum-666)*10))
							   ) as aa on aa.student_intention_id = lpo.student_intention_id
	                                      and month(aa.min_date) = month(lp.adjust_start_time)
   
         where lp.lesson_type = 2
			   and to_date(lp.adjust_start_time) >= add_months(trunc('${analyse_date}','MM'),-1)
			   and to_date(lp.adjust_start_time) <= '${analyse_date}'
			   and not(to_date(lp.adjust_start_time) > add_months('${analyse_date}',-1) and to_date(lp.adjust_start_time) < trunc('${analyse_date}','MM'))
			   and s.account_type = 1
			   ) as b
