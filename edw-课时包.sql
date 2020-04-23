select  to_date(a.effective_date) as `effective_date`,
		substr(from_unixtime(unix_timestamp(a.effective_date)),1,7) as `effective_month`,
		a.period_class,
		sum(a.real_pay_sum) as `total_deal_amount`,
		count(a.contract_id) as `total_deal_num`

        
from(
		select  tc.contract_id,
				tc.effective_date,
			    avg(case when tc.period>=0 and tc.period<60 then '30'
						 when tc.period>=60 and tc.period<90 then '60'
						 when tc.period>=90 and tc.period<120 then '90'
						 when tc.period>=120 and tc.period<180 then '120'
					else '180' end) period_class,
			    sum(tcp.sum/100) real_pay_sum,
			    avg((tc.sum-666)*10) contract_amount
			  					
		from dw_hf_mobdb.dw_view_tms_contract tc
		left join dw_hf_mobdb.dw_view_tms_contract_payment tcp on tc.contract_id=tcp.contract_id
		left join dw_hf_mobdb.dw_view_user_info ui on ui.user_id = tc.submit_user_id
		left join dw_hf_mobdb.dw_sys_user_role sur on ui.user_id=sur.user_id
		left join dw_hf_mobdb.dw_sys_role sr on sur.role_id=sr.role_id
		left join dw_hf_mobdb.dw_sys_department sd on sr.department_id=sd.department_id

		where   to_date(tc.effective_date) >= '2018-01-01'
		        and tc.effective_date is not null
				and (sd.department_name like '%CC%' or sd.department_name like '%销售%')
				and ui.account_type = 1
				and tcp.pay_status in (2, 4)
				and to_date(tc.effective_date) <= '${analyse_date}'
		group by tc.contract_id, tc.effective_date, tc.period
		) as a

group by substr(from_unixtime(unix_timestamp(a.effective_date)),1,7), to_date(a.effective_date), a.period_class