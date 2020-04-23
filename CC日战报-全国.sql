-- CC日战报-全国
select   t1.number -- 月初抗标人数
		,t2.old_sales  -- 老销售人数
		,t2.mid_sales  -- 中销售人数
		,t2.new_sales  -- 新销售人数
		,t4.d_req  -- 昨日触碰总粒子数
		,t3.d_keys  -- 昨日获取总粒子数
		,t4.d_new_req  -- 昨日触碰新粒子数
		,t3.d_new_keys  -- 昨日获取新粒子数
		,t4.d_oc_req  -- 昨日触碰oc粒子数
		,t3.d_oc_keys  -- 昨日获取oc粒子数
		,t3.m_keys  -- 月粒子获取总数
		,t3.m_new_keys  -- 月新粒子获取数
		,t3.m_oc_keys  -- 月oc粒子获取数
		,coalesce(t5.d_tr_call_time,0) as d_tr_call_time  -- 昨日天润通时
		,coalesce(t6.d_wp_call_time,0) as d_wp_call_time  -- 昨日工作手机通时
		,coalesce(t5.d_tr_call_cnt,0) as d_tr_call_cnt  -- 昨日天润通次
		,coalesce(t6.d_wp_call_cnt,0) as d_wp_call_cnt  -- 昨日工作手机通次
		,coalesce(t5.m_tr_call_cnt,0) as m_tr_call_cnt  -- 月天润通次
		,coalesce(t6.m_wp_call_cnt,0) as m_wp_call_cnt  -- 月工作手机通次
		,coalesce(t5.m_tr_bridge_call_cnt,0) as m_tr_bridge_call_cnt  -- 月天润接通通次
		,coalesce(t6.m_wp_bridge_call_cnt,0) as m_wp_bridge_call_cnt  -- 月工作手机接通通次
		,coalesce(t5.m_tr_new_call_cnt,0) as m_tr_new_call_cnt  -- 月天润新粒子通次
		,coalesce(t5.m_tr_new_bridge_call_cnt,0) as m_tr_new_bridge_call_cnt  -- 月天润新粒子接通通次
		,coalesce(t5.m_tr_oc_call_cnt,0) as m_tr_oc_call_cnt  -- 月天润oc粒子通次
		,coalesce(t5.m_tr_oc_bridge_call_cnt,0) as m_tr_oc_bridge_call_cnt  -- 月天润oc粒子接通通次
		,t7.m_commu_cnt  -- 月总粒子沟通频次
		,t7.m_new_commu_cnt  -- 月新粒子沟通频次
		,t7.m_oc_commu_cnt  -- 月oc粒子沟通频次
		,t8.d_apply_num  -- 昨日发起设班单数
		,t9.d_exp  -- 昨日体验课数
		,t10.d_plan_num  -- 昨日试听课排课数
		,t10.d_trial_num  -- 昨日试听课出席数
		,t8.m_apply_num  -- 月发起设班单数
		,t9.m_exp  -- 月体验课数
		,t10.m_plan_num  -- 月试听课排课数
		,t10.m_trial_num  -- 月试听出席数
		,t11.d_trial_deal  -- 昨日试听关单量
		,t11.rc7_trial_deal  -- 近七日试听关单量
		,t11.rc7_trial_num  -- 近七日试听出席量
		,t11.rc30_trial_deal  -- 近30日试听关单量
		,t11.rc30_trial_num  -- 近30日试听出席量
		,t12.m_order  -- 月总成单数
		,t12.m_new_order  -- 月新粒子成单数
		,t12.m_oc_order  -- 月oc粒子成单数
		,t10.m_hourdiff  -- 月试听关单总时长
		,t10.m_hourdiff_notnull  -- 月支付大于关单的试听成单量
		,t12.d_order  -- 昨日订单数
		,t12.d_new_order  -- 昨日新粒子订单数
		,t12.d_oc_order  -- 昨日oc粒子订单数
		,t12.m_rec_order  -- 当月转介绍订单数
		,t1.order_number  -- 当月订单数指标
		,t12.m_order_amount  -- 当月总订单额
		,t12.d_order_amount  -- 昨日订单额
		,t12.d_rec_order  -- 昨日转介绍订单数
		,t10.m_plan_exp  -- 月邀约且出席体验课量



-- 月初抗标人数
left join (
				select  '${analyse_date}' as stats_date
					    ,sum(st.number) as number
					    ,sum(st.order_number) as order_number
				from hf_mobdb.sales_tab st
				where st.type = 'normal' and st.group_name like '%CC%'
				) as t1



-- 新中老销售人数
left join (
				select    '${analyse_date}' as stats_date
					      ,count(case when a.work_time<60 then a.user_id end) as new_sales
					      ,count(case when a.work_time>=60 and a.work_time<180 then a.user_id end) as mid_sales
					      ,count(case when a.work_time>=180 then a.user_id end) as old_sales
				from(
				            select  cdme.user_id
						            ,datediff(trunc('${analyse_date}','MM'),to_date(min(opt_time))) work_time

				            from dt_mobdb.dt_charlie_dept_month_end cdme
				            left join dw_hf_mobdb.dw_sys_change_role_log scr on scr.user_id=cdme.user_id
				            where to_date(cdme.stats_date)=current_date() and cdme.class='CC' 
				                  and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')
				                  and cdme.quarters in ('销售组员','销售组长')
				            group by cdme.user_id
				            ) as a
				) as t2 on t2.stats_date = t1.stats_date



-- 获取粒子数
left join (
			select '${analyse_date}' as stats_date
		           ,count(distinct case when to_date(a.into_pool_date)='${analyse_date}' then a.intention_id end) d_keys
		           ,count(distinct case when to_date(a.into_pool_date)='${analyse_date}' and a.is_new=1 and a.is_rec=0 then a.intention_id end) d_new_keys
		           ,count(distinct case when to_date(a.into_pool_date)='${analyse_date}' and a.is_new=0 and a.is_rec=0 then a.intention_id end) d_oc_keys
		           ,count(distinct a.intention_id) m_keys
		           ,count(distinct case when a.is_new=1 and a.is_rec=0 then a.intention_id end) m_new_keys
		           ,count(distinct case when a.is_new=0 and a.is_rec=0 then a.intention_id end) m_oc_keys										 
            from
                   (
                       select tpel.track_userid, tpel.intention_id, tpel.into_pool_date
                              ,case when to_date(s.create_time)>=trunc('${analyse_date}','MM') then 1 else 0 end is_new
                              ,case when s.coil_in in (13,22) or s.know_origin in (56,71,22,24,25,41) then 1 else 0 end is_rec
                       from dw_hf_mobdb.dw_tms_pool_exchange_log tpel
                       inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id=tpel.track_userid
	                              and to_date(cdme.stats_date)=current_date() and cdme.class='CC'
	                              and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')
                       left join dw_hf_mobdb.dw_view_user_info ui on ui.user_id=tpel.create_userid
                       left join dw_hf_mobdb.dw_view_student s on s.student_intention_id = tpel.intention_id
                       where to_date(tpel.into_pool_date)>=trunc('${analyse_date}','MM')
	                         and to_date(tpel.into_pool_date)<='${analyse_date}'
                       union
                       select tnn.user_id as track_userid, tnn.student_intention_id as intention_id, tnn.create_time as into_pool_date
                              ,case when to_date(s.create_time)>=trunc('${analyse_date}','MM') then 1 else 0 end is_new
                              ,case when s.coil_in in (13,22) or s.know_origin in (56,71,22,24,25,41) then 1 else 0 end is_rec
                       from dw_hf_mobdb.dw_tms_new_name_get_log tnn
                       left join dw_hf_mobdb.dw_view_student s on s.student_intention_id = tnn.student_intention_id
                       inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id=tnn.user_id
	                              and to_date(cdme.stats_date)=current_date() and cdme.class='CC'
	                              and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')
                       where to_date(tnn.create_time)>=trunc('${analyse_date}','MM')
	                         and to_date(tnn.create_time)<='${analyse_date}'
	                         and tnn.student_intention_id<>0
							 ) as a		
			) as t3 on t3.stats_date = t1.stats_date



-- 触碰粒子数
left join (
			select  '${analyse_date}' as stats_date
			 		,count(distinct ss.student_intention_id) as d_req   -- 昨日触碰粒子总数
                    ,count(distinct case when to_date(s.create_time)>=trunc('${analyse_date}','MM') 
                                              and s.coil_in not in (13,22) 
                                              and s.know_origin not in (56,71,22,24,25,41) 
                                         then ss.student_intention_id end) as d_new_req  -- 昨日触碰新粒子数
	                ,count(distinct case when to_date(s.create_time)<trunc('${analyse_date}','MM') 
	                                          and s.coil_in not in (13,22) 
                                              and s.know_origin not in (56,71,22,24,25,41)
                                         then ss.student_intention_id end) as d_oc_req  -- 昨日触碰oc粒子数
             from dw_hf_mobdb.dw_ss_collection_sale_roster_action ss
             inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id=ss.user_id
                        and to_date(cdme.stats_date)=current_date() and cdme.class='CC'
		                and to_date(cdme.`date`)>=trunc('${analyse_date}','MM') 
             left join dw_hf_mobdb.dw_view_student s on s.student_intention_id=ss.student_intention_id
             where to_date(ss.view_time)='${analyse_date}'
             ) as t4 on t4.stats_date = t1.stats_date



-- 天润通时通次
left join (
				select  '${analyse_date}' as stats_date
						,sum(case when to_date(tcr.end_time)='${analyse_date}' then unix_timestamp(tcr.end_time)-unix_timestamp(tcr.bridge_time) end) as d_tr_call_time  -- 昨日天润通时
				        ,count(case when to_date(tcr.end_time)='${analyse_date}' then tcr.user_id end) d_tr_call_cnt  -- 昨日天润通次
				        ,count(tcr.student_intention_id) m_tr_call_cnt  -- 月天润通次
				        ,count(case when to_date(s.create_time)>=trunc('${analyse_date}','MM')
				                         and s.coil_in not in (13,22) 
                                         and s.know_origin not in (56,71,22,24,25,41) 
                                    then tcr.student_intention_id end) m_tr_new_call_cnt  -- 月天润新粒子通次
				        ,count(case when to_date(s.create_time)<trunc('${analyse_date}','MM') 
				                         and s.coil_in not in (13,22) 
                                         and s.know_origin not in (56,71,22,24,25,41)
                                    then tcr.student_intention_id end) m_tr_oc_call_cnt  -- 月天润oc粒子通次
				        ,count(case when tcr.status=33 then tcr.student_intention_id end) m_tr_bridge_call_cnt  --月天润接通通次
				        ,count(case when to_date(s.create_time)>=trunc('${analyse_date}','MM') and tcr.status=33 
				                         and s.coil_in not in (13,22) 
                                         and s.know_origin not in (56,71,22,24,25,41)
                                    then tcr.student_intention_id end) m_tr_new_bridge_call_cnt  --月天润新粒子接通通次
				        ,count(case when to_date(s.create_time)<trunc('${analyse_date}','MM') and tcr.status=33 
				                         and s.coil_in not in (13,22) 
                                         and s.know_origin not in (56,71,22,24,25,41)
                                    then tcr.student_intention_id end) m_tr_oc_bridge_call_cnt  --月天润oc粒子接通通次
				from dw_hf_mobdb.dw_view_tms_call_record tcr
				left join dw_hf_mobdb.dw_view_student s on s.student_intention_id = tcr.student_intention_id
				inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id = tcr.user_id
				           and to_date(cdme.stats_date) = current_date() and cdme.class = 'CC'
				           and to_date(cdme.`date`) >= trunc('${analyse_date}','MM')
				where tcr.call_type = 1 -- 呼叫学生
				      and to_date(tcr.end_time) >= trunc('${analyse_date}','MM')
				      and to_date(tcr.end_time) <= '${analyse_date}'
				) as t5 on t5.stats_date = t1.stats_date



-- 工作手机通时通次
left join (
			select  '${analyse_date}' as stats_date
			        ,count(case when to_date(pr.start_time)='${analyse_date}' then pr.contact_phone end) as d_wp_call_cnt  --昨日工作手机通次
			        ,sum(case when to_date(pr.start_time)='${analyse_date}' then pr.duration end) as d_wp_call_time  --昨日工作手机通时
			        ,count(pr.contact_phone) as m_wp_call_cnt  -- 月工作手机通次
			        ,sum(pr.duration) as m_wp_call_time  --月工作手机通时
			        ,count(case when pr.on_type=1 then pr.user_id end) as m_wp_bridge_call_cnt  -- 月工作手机接通通次


			from dw_hf_mobdb.dw_phone_record pr
			inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id=pr.user_id
			           and to_date(cdme.stats_date)=current_date() and cdme.class='CC'
			           and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')
			where pr.out_type = 1
			      and to_date(pr.start_time) >= trunc('${analyse_date}','MM')
			      and to_date(pr.start_time) <= '${analyse_date}'
			      ) as t6 on t6.stats_date = t1.stats_date


-- 沟通频次
left join (
				select  '${analyse_date}' as stats_date
						,count(cr.student_intention_id) m_commu_cnt
						,count(case when to_date(s.create_time)>=trunc('${analyse_date}','MM') 
							             and s.coil_in not in (13,22) 
                                         and s.know_origin not in (56,71,22,24,25,41)
                                    then cr.student_intention_id end) m_new_commu_cnt
						,count(case when to_date(s.create_time)<trunc('${analyse_date}','MM') 
							             and s.coil_in not in (13,22) 
                                         and s.know_origin not in (56,71,22,24,25,41)
                                    then cr.student_intention_id end) m_oc_commu_cnt
				from dw_hf_mobdb.dw_view_communication_record cr
				inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id = cr.communication_person
				           and to_date(cdme.stats_date) = current_date() and cdme.class = 'CC'
				           and to_date(cdme.`date`) >= trunc('${analyse_date}','MM')
				left join dw_hf_mobdb.dw_view_student s on s.student_intention_id = cr.student_intention_id
				where to_date(cr.start_time) >= trunc('${analyse_date}','MM')
				      and to_date(cr.start_time) <= '${analyse_date}'
				      ) as t7 on t7.stats_date = t1.stats_date




-- 发起设班单
left join (
				select  '${analyse_date}' as stats_date,
				        count(distinct case when to_date(lpo.apply_time)='${analyse_date}' then lpo.student_intention_id end) as d_apply_num,
				        count(distinct lpo.student_intention_id) as m_apply_num
				from dw_hf_mobdb.dw_lesson_plan_order lpo
				left join dw_hf_mobdb.dw_lesson_relation lr on lpo.order_id=lr.order_id
				left join dw_hf_mobdb.dw_lesson_plan lp on lr.plan_id=lp.lesson_plan_id
				left join dw_hf_mobdb.dw_view_student s on s.student_intention_id=lpo.student_intention_id
				inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id=lpo.apply_user_id 
						   and to_date(cdme.stats_date)=current_date() and cdme.class='CC'
						   and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')
				where lp.lesson_type=2
					  and to_date(lpo.apply_time)>=trunc('${analyse_date}','MM')
					  and to_date(lpo.apply_time)<='${analyse_date}'
					  and s.account_type=1
					  ) as t8 on t8.stats_date = t1.stats_date


-- 体验课数
left join (
				select  '${analyse_date}' as stats_date
						,count(distinct case when to_date(lp.real_start_time)='${analyse_date}' then lp.student_id end) d_exp
						,count(distinct lp.student_id) m_exp
				from dw_hf_mobdb.dw_lesson_plan lp
				left join dw_hf_mobdb.dw_view_user_info ui on ui.user_id = lp.teacher_id
				left join dw_hf_mobdb.dw_view_user_info ui2 on ui2.phone7 = ui.phone7 and ui2.password_fk = ui.password_fk
				          and ui2.user_type <> 1
				inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id = ui2.user_id
				           and cdme.stats_date = current_date() and cdme.class = 'CC'
				           and cdme.`date` >= trunc('${analyse_date}','MM')
				where lp.lesson_type = 3 and lp.status = 3 and lp.solve_status <> 6
				      and to_date(lp.real_start_time) >= trunc('${analyse_date}','MM')
				      and to_date(lp.real_start_time) <= '${analyse_date}'
				      ) as t9 on t9.stats_date = t1.stats_date


-- 试听邀约数
left join (

				select  '${analyse_date}' as stats_date
						,count(distinct case when to_date(lp.adjust_start_time)='${analyse_date}' then lpo.student_intention_id end) as d_plan_num  -- 昨日试听邀约量
						,count(distinct case when to_date(lp.adjust_start_time)='${analyse_date}' and lp.status in (3,5) and lp.solve_status<>6 then lpo.student_intention_id end) as d_trial_num  --昨日试听出席量
						,count(distinct lpo.student_intention_id) as m_plan_num  -- 月试听邀约量
						,count(distinct case when lp2.student_id is not null then lpo.student_intention_id end) as m_plan_exp  -- 月试听邀约且出席体验课量
						,count(distinct case when lp.status in (3,5) and lp.solve_status<>6 then lpo.student_intention_id end) as m_trial_num  -- 月试听出席量
						,sum(case when (unix_timestamp(a.min_date)-unix_timestamp(lp.adjust_end_time))>0 then (unix_timestamp(a.min_date)-unix_timestamp(lp.adjust_end_time))/3600 end) m_hourdiff  -- 月关单总时长
						,count(case when (unix_timestamp(a.min_date)-unix_timestamp(lp.adjust_end_time))>0 then lpo.student_intention_id end) m_hourdiff_notnull  -- 支付大于试听的试听成单量
				from dw_hf_mobdb.dw_lesson_plan_order lpo
				left join dw_hf_mobdb.dw_lesson_relation lr on lpo.order_id=lr.order_id
				left join dw_hf_mobdb.dw_lesson_plan lp on lr.plan_id=lp.lesson_plan_id
				left join dw_hf_mobdb.dw_view_student s on s.student_intention_id=lpo.student_intention_id
				left join dw_hf_mobdb.dw_lesson_plan lp2 on lp2.student_id = lp.student_id
				          and lp2.lesson_type = 3 and lp2.status = 3 and lp2.solve_status <> 6
				inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id=lpo.apply_user_id 
						   and to_date(cdme.stats_date)=current_date() and cdme.class='CC'
						   and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')
			    left join (
			    				select max(tcp.pay_date) max_date,
				                    	   min(tcp.pay_date) min_date,
				                           tc.contract_id,
				                           tc.student_intention_id,
				                           sum(tcp.`sum`/100) real_pay_amount,
				                           max((tc.`sum`-666)*10) contract_amount,
				                           tcp.submit_user_id

				                    from dw_hf_mobdb.dw_view_tms_contract_payment tcp
				                    left join dw_hf_mobdb.dw_view_tms_contract tc on tc.contract_id = tcp.contract_id
				                    inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id = tcp.submit_user_id
				                           and to_date(cdme.stats_date)=current_date() and cdme.class = 'CC'
				                           and to_date(cdme.`date`)>=date_sub('${analyse_date}',30)
				                    where tcp.pay_status in (2,4) and tc.status<>8
				                    group by tc.contract_id, tc.student_intention_id, tcp.submit_user_id
				                    having max(tcp.pay_date)>=date_sub('${analyse_date}',30)
				                           and max(tcp.pay_date)<='${analyse_date}'
				                           and round(sum(tcp.`sum`/100),0)>=round(max((tc.`sum`-666)*10),0)
				                           ) as a on a.student_intention_id=lpo.student_intention_id 
				
				where lp.lesson_type=2
					  and to_date(lp.adjust_start_time)>=trunc('${analyse_date}','MM')
					  and to_date(lp.adjust_start_time)<='${analyse_date}'
					  and s.account_type = 1
					  ) as t10 on stats_date = t1.stats_date



-- 试听关单率
left join (
				select '${analyse_date}' as stats_date
				       ,count(distinct case when to_date(b.adjust_start_time)='${analyse_date}' then b.contract_id end) d_trial_deal  -- 昨日试听关单量
				       ,count(distinct case when to_date(b.adjust_start_time)>=date_sub('${analyse_date}',7) then b.contract_id end) rc7_trial_deal  -- 近七日试听关单量
				       ,count(distinct case when to_date(b.adjust_start_time)>=date_sub('${analyse_date}',7) then b.student_intention_id end) rc7_trial_num  -- 近七日试听出席量
				       ,count(distinct case when to_date(b.adjust_start_time)>=date_sub('${analyse_date}',30) then b.contract_id end) rc30_trial_deal  -- 近30日试听关单量
				       ,count(distinct case when to_date(b.adjust_start_time)>=date_sub('${analyse_date}',30) then b.student_intention_id end) rc30_trial_num  -- 近30日试听出席量


				from(
				      select lpo.student_intention_id
				             ,lpo.apply_user_id
				             ,lp.adjust_start_time
				             ,a.max_date
				             ,a.contract_id
				      from dw_hf_mobdb.dw_lesson_plan_order lpo
				      left join dw_hf_mobdb.dw_lesson_relation lr on lpo.order_id = lr.order_id
				      left join dw_hf_mobdb.dw_lesson_plan lp on lr.plan_id = lp.lesson_plan_id
				      left join dw_hf_mobdb.dw_view_student s on s.student_intention_id = lpo.student_intention_id
				      inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id = lpo.apply_user_id 
				                 and to_date(cdme.stats_date)=current_date() and cdme.class = 'CC'
				                 and to_date(cdme.`date`)>=date_sub('${analyse_date}',30)
				      left join (
				                    select max(tcp.pay_date) max_date,
				                    	   min(tcp.pay_date) min_date,
				                           tc.contract_id,
				                           tc.student_intention_id,
				                           sum(tcp.`sum`/100) real_pay_amount,
				                           max((tc.`sum`-666)*10) contract_amount,
				                           tcp.submit_user_id

				                    from dw_hf_mobdb.dw_view_tms_contract_payment tcp
				                    left join dw_hf_mobdb.dw_view_tms_contract tc on tc.contract_id = tcp.contract_id
				                    inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id = tcp.submit_user_id
				                           and to_date(cdme.stats_date)=current_date() and cdme.class = 'CC'
				                           and to_date(cdme.`date`)>=date_sub('${analyse_date}',30)
				                    where tcp.pay_status in (2,4) and tc.status<>8
				                    group by tc.contract_id, 
				                             tc.student_intention_id, tcp.submit_user_id
				                    having max(tcp.pay_date)>=date_sub('${analyse_date}',30)
				                           and max(tcp.pay_date)<='${analyse_date}'
				                           and round(sum(tcp.`sum`/100),0)>=round(max((tc.`sum`-666)*10),0)
				                           ) as a on a.student_intention_id=lpo.student_intention_id 
				      where lp.lesson_type = 2
				          and to_date(lpo.apply_time)>=date_sub('${analyse_date}',30)
				          and to_date(lpo.apply_time)<='${analyse_date}'
				          and lp.status in (3,5) and lp.solve_status <> 6
				          and s.account_type = 1
				          ) as b
				) as t11 on stats_date = t1.stats_date


-- 总成单数成单额
left join (
				select  '${analyse_date}' as stats_date
						,count(case when to_date(d.max_date)='${analyse_date}' then d.contract_id end) d_order  -- 昨日订单数
						,sum(case when to_date(d.max_date)='${analyse_date}' then d.real_pay_amount end) d_order_amount  -- 昨日订单额
						,count(case when to_date(d.max_date)='${analyse_date}' and d.is_rec=1 then d.contract_id end) d_rec_order  -- 昨日转介绍订单数
						,count(case when to_date(d.max_date)='${analyse_date}' and d.is_new=1 and d.is_rec=0 then d.contract_id end) d_new_order  -- 昨日新粒子订单数
						,count(case when to_date(d.max_date)='${analyse_date}' and d.is_new=0 and d.is_rec=0 then d.contract_id end) d_oc_order  -- 昨日oc粒子订单数
						,count(d.contract_id) m_order  -- 当月总订单数
						,sum(d.real_pay_amount) m_order_amount  -- 当月总订单额
						,count(case when d.is_rec=1 then d.contract_id end) m_rec_order  -- 当月转介绍订单数
				        ,count(case when d.is_new=1  and d.is_rec=0 then d.contract_id end) as m_new_order  -- 当月新粒子订单数,
				        ,count(case when d.is_new=0 and d.is_rec=0 then d.contract_id end) as m_oc_order  -- 当月oc粒子订单数

				from(

				      select max(tcp.pay_date) max_date
				             ,tc.contract_id
				             ,tc.student_intention_id
				             ,sum(tcp.`sum`/100) real_pay_amount
				             ,max((tc.`sum`-666)*10) contract_amount
				             ,tcp.submit_user_id
				             ,max(case when to_date(s.create_time)>=trunc('${analyse_date}','MM') then 1 else 0 end) is_new
				             ,max(case when s.coil_in in (13,22) or s.know_origin in (56,71,22,24,25,41) then 1 else 0 end) is_rec
				      from dw_hf_mobdb.dw_view_tms_contract_payment tcp
				      left join dw_hf_mobdb.dw_view_tms_contract tc on tc.contract_id=tcp.contract_id
				      left join dw_hf_mobdb.dw_view_student s on s.student_intention_id=tc.student_intention_id
				      inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id=tcp.submit_user_id
				                 and to_date(cdme.stats_date)=current_date() and cdme.class='CC'
				                 and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')
				      where tcp.pay_status in (2,4) and tc.status<>8
				      group by tc.contract_id, tc.student_intention_id, tcp.submit_user_id
				      having to_date(max(tcp.pay_date))>=trunc('${analyse_date}','MM')
				             and to_date(max(tcp.pay_date))<='${analyse_date}'
				             and round(sum(tcp.`sum`/100),0)>=round(max((tc.`sum`-666)*10),0)
				             ) as d 
				) as t12 on stats_date = t1.stats_date