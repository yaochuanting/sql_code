select  t1.cc_order_num,  --  `CC-新签订单数指标`
		t1.cr_order_num,  -- `CR-新签订单数指标`, 
		t1.cc_order_num+t1.cr_order_num as total_order_num,  -- `订单量指标`
 		t2.cc_deal_num,  --  `CC-新签订单数`, 
 		t2.cr_new_deal,  --  `CR-新签订单数`, 
 		t2.cc_deal_num+t2.cr_new_deal as total_deal_num,  -- `总新签订单量`,
 		t2.lm_deal_num,  --  `上月同期新签订单数`,
 		t2.cc_deal_num+t2.cr_deal_num-t2.lm_deal_num as order_num_dif, -- `环比增量`,
        (1/dayofmonth(last_day('${analyse_date}'))*dayofmonth('${analyse_date}')) as time_sched  -- `时间进度`
		

from (
			select '${analyse_date}' as stats_date,
                    sum(case when lt.class='CC' and lt.type='新签' then lt.order_num end) as cc_order_num,
                    sum(case when lt.class='CR' and lt.type='新签' then lt.order_num end) as cr_order_num
			from hf_mobdb.load_target lt
			where lt.year = year('${analyse_date}')
                  and lt.month = month('${analyse_date}')
			) as t1


left join (
			select  '${analyse_date}' as stats_date,
                    count(case when a.class='CC' and date(a.last_pay_date)>=trunc('${analyse_date}','MM') then a.contract_id end) as cc_deal_num,
			        count(case when a.class='CR' and a.new_sign=1 and date(a.last_pay_date)>=trunc('${analyse_date}','MM') then a.contract_id end) as cr_deal_num,
			        count(case when date(a.last_pay_date)<=date_add(add_months(date_add('${analyse_date}',1),-1),-1) and new_sign=1 then a.contract_id end) as lm_deal_num

			from(

					select  max(tcp.pay_date) last_pay_date,
							tcp.contract_id, 
							s.student_intention_id,
							cdme.department_name,
                            cdme.class,
                            tc.new_sign,
							sum(tcp.sum)/100 real_pay_sum, 
							avg((tc.sum-666)*10) contract_amount
					from dw_hf_mobdb.dw_view_tms_contract_payment tcp
					left join dw_hf_mobdb.dw_view_tms_contract tc on tcp.contract_id  = tc.contract_id
					left join dw_hf_mobdb.dw_view_student s on s.student_intention_id = tc.student_intention_id
					left join dw_hf_mobdb.dw_view_user_info ui on ui.user_id = tc.submit_user_id
					inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id = tcp.submit_user_id
							   and cdme.stats_date = current_date() 
                               and cdme.`date` >=trunc('${analyse_date}','MM')
					where tcp.pay_status in (2,4)
						  and ui.account_type = 1
						  and tc.status <> 8
					group by tcp.contract_id, s.student_intention_id, cdme.department_name, cdme.class, tc.new_sign
					having round(sum(tcp.sum)/100) >= round(avg((tc.sum-666)*10))
						   and date(last_pay_date) >= trunc('${analyse_date}','MM')
						   and date(last_pay_date) <= '${analyse_date}'
						   ) as a
                           ) as t2 on t2.stats_date = t1.stats_date