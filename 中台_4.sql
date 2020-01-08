select 
       date_sub(curdate(), interval 1 day) stats_date,
	   case when s.submit_time >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01') then 'new'
	        when s.submit_time >= date_sub(date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01'),interval 1 month) then 'sec_new'
			when year(s.submit_time)= 2019 then 'toyear_oc' else 'his_oc' end key_attr,
       count(distinct a.intention_id) get_keys, -- 获取线索量
	   count(distinct case when t.distri_type = 'manual' then a.intention_id end) manual_get_keys, -- 手动获取线索量
	   count(distinct case when b.is_bridge = 1 then a.intention_id end) bridge_keys, -- 线索接通量
	   count(distinct case when t.distri_type = 'manual' and b.is_bridge = 1 then a.intention_id end) bridge_manual_keys, -- 手动分配线索接通量
	   count(distinct case when t.distri_type = 'manual' and b.is_bridge is not null then a.intention_id end) call_manual_keys, -- 手动分配线索拨打量
       count(distinct case when c.contract_id is not null then a.intention_id end) deal_num,  -- 线索成单量
	   count(distinct case when c.contract_id is not null and t.distri_type = 'manual' then a.intention_id end) manual_deal_num,  -- 手动分配线索成单量
	   sum(case when c.contract_id is not null then c.real_pay_sum else 0 end) deal_amount,  -- 线索成单额、
	   sum(case when c.contract_id is not null and t.distri_type = 'manual' then c.real_pay_sum else 0 end) manual_deal_amount  -- 线索成单额
									 
from
( 
        select tpel.intention_id
        from hfjydb.tms_pool_exchange_log tpel
        inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tpel.track_userid
	         and cdme.stats_date = curdate() and cdme.class = '销售'
	         and cdme.date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
        left join hfjydb.view_user_info ui on ui.user_id = tpel.create_userid
        where tpel.into_pool_date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
	          and tpel.into_pool_date < curdate()
		group by tpel.intention_id
		) as a	 -- a表：当月所有入销售库的线索						 
left join (
                  select t2.intention_id, t2.distri_user,
                         case when t2.distri_user in ('OC分配账号','自动分配销售') then 'auto' else 'manual' end as distri_type

                  from(

                              select tpel.intention_id, tpel.into_pool_date, ui.name as distri_user
				              from hfjydb.tms_pool_exchange_log tpel
				              inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tpel.track_userid
						                 and cdme.stats_date = curdate() and cdme.class = '销售'
						                 and cdme.date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
				              left join hfjydb.view_user_info ui on ui.user_id = tpel.create_userid
				              where tpel.into_pool_date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
					                and tpel.into_pool_date < curdate()
					                ) as t2 -- t2表：当月每条入库记录：包含id 和入池时间，以及分配人
		
		
                  inner join(		
		
	                                        select tpel.intention_id, min(tpel.into_pool_date) as min_into_pool_date
											from hfjydb.tms_pool_exchange_log tpel
											inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tpel.track_userid
													   and cdme.stats_date = curdate() and cdme.class = '销售'
													   and cdme.date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
											where tpel.into_pool_date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
												  and tpel.into_pool_date < curdate()
							                group by tpel.intention_id
											) as t3 on t2.into_pool_date = t3.min_into_pool_date
											           and t2.intention_id = t3.intention_id    -- t3表：每条入库线索的首次入库时间
				  group by t2.intention_id
                  ) as t on t.intention_id = a.intention_id
 
left join (
            select bb.student_intention_id,max(bb.max_bridge_time) max_bridge_time, bb.is_bridge

            from 

						 (select
								 tcr.student_intention_id,
								 case when tcr.status = 33 then 1 else 0 end is_bridge,
								 max(timestampdiff(second, bridge_time, end_time)) max_bridge_time
						 from hfjydb.view_tms_call_record tcr
						 inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tcr.user_id
									and cdme.stats_date = curdate() and cdme.class = '销售'
									and cdme.date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
						 where tcr.end_time >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
							   and tcr.end_time < curdate()
							   and call_type = 1 -- 打给学生
							   -- and tcr.status = 33 -- 接通
						 group by tcr.student_intention_id
					
						 union all
					
						 select
								 wr.student_intention_id,
								 case when on_type = 1 then 1 else 0 end is_bridge,
								 max(calling_seconds) max_bridge_time
						 from  bidata.will_work_phone_call_recording wr
						 inner join bidata.charlie_dept_month_end cdme on cdme.user_id = wr.user_id
									and cdme.stats_date = curdate() and cdme.class = '销售' 
									and cdme.date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
						 where wr.begin_time < curdate()
							   and wr.begin_time >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
							   -- and on_type = 1 -- 接通
						 group by wr.student_intention_id) as bb
			 group by bb.student_intention_id) as b on b.student_intention_id = a.intention_id

left join (select
							min(tcp.pay_date) min_pay_date,
							max(tcp.pay_date) last_pay_date,
							tcp.contract_id,  
							s.student_intention_id,
							s.submit_time,
							sum(tcp.sum)/100 real_pay_sum,
							(tc.sum-666)*10 contract_amount
		  from hfjydb.view_tms_contract_payment tcp
		  left join hfjydb.view_tms_contract tc on tcp.contract_id  = tc.contract_id
		  left join hfjydb.view_student s on s.student_intention_id = tc.student_intention_id
		  left join hfjydb.view_user_info ui on ui.user_id = tc.submit_user_id
		  inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tcp.submit_user_id
					 and cdme.stats_date = curdate() and cdme.class = '销售'
					 and cdme.date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
		  where tcp.pay_status in (2,4)
				and ui.account_type = 1
		  group by tcp.contract_id
		  having real_pay_sum >= contract_amount
				 and last_pay_date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
				 and last_pay_date < curdate()
				 ) as c on c.student_intention_id = a.intention_id
						   
left join hfjydb.view_student s on s.student_intention_id = a.intention_id
group by stats_date, key_attr