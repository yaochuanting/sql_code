select  e.*, date_format(e.生效日期,'%Y-%m') 生效年月,
        case when e.department_name like '%销售%' or e.department_name like '%CC%' then '销售部'
             when e.department_name like '%学管%' or e.department_name like '%CR%' then '学管部'
        else '代理' end as '架构部门',
       (e.合同金额-e.课时成本) 毛利,
       (e.合同金额-e.课时成本)/e.合同金额 毛利率,
	    case when e.支付金额>=e.合同金额 then 1 else 0 end 是否支付完成
from(

		select  tc.contract_id 合同编号,
                tc.student_no 学生编号,
			    tc.effective_date 生效日期,
			    max(case when ddic.value='预初' then '初一' else ddic.value end) 报名年级,
			    max(tc.period) 购买课时数,
			    max(case when tc.period>=0 and tc.period<60 then '30'
				         when tc.period>=60 and tc.period<90 then '60'
						 when tc.period>=90 and tc.period<120 then '90'
						 when tc.period>=120 and tc.period<180 then '120'
			    	else '180' end) 课时分段,
			    max(tc.donate_period) 赠送课时数,
                sum(tcp.sum/100) 支付金额,
			    avg((tc.sum-666)*10) 合同金额,
			    min(tcp.pay_date)  首次支付日期,
			    max(case when tc.new_sign =1 then '新签'
			         	 when tc.new_sign =0 then '续费'
				    else '其他' end) 合同类型,
			    cdme.department 部门名称,
			    ((tc.period+tc.donate_period)*tc.minute_per_period)/40 换算后课时数,
			    case when ddic.value='小一' then ((tc.period+tc.donate_period)*tc.minute_per_period)/40*56.58 
			         when ddic.value='小二' then ((tc.period+tc.donate_period)*tc.minute_per_period)/40*56.58
					 when ddic.value='小三' then ((tc.period+tc.donate_period)*tc.minute_per_period)/40*56.58
					 when ddic.value='小四' then ((tc.period+tc.donate_period)*tc.minute_per_period)/40*56.58
					 when ddic.value='小五' then ((tc.period+tc.donate_period)*tc.minute_per_period)/40*56.58
					 when ddic.value='小六' then ((tc.period+tc.donate_period)*tc.minute_per_period)/40*56.58
					 when ddic.value='初一' then ((tc.period+tc.donate_period)*tc.minute_per_period)/40*59.12
					 when ddic.value='初二' then ((tc.period+tc.donate_period)*tc.minute_per_period)/40*59.12
					 when ddic.value='初三' then ((tc.period+tc.donate_period)*tc.minute_per_period)/40*59.12
					 when ddic.value='高一' then ((tc.period+tc.donate_period)*tc.minute_per_period)/40*68.99
					 when ddic.value='高二' then ((tc.period+tc.donate_period)*tc.minute_per_period)/40*68.99
					 when ddic.value='高三' then ((tc.period+tc.donate_period)*tc.minute_per_period)/40*68.99
			    else  ((tc.period+tc.donate_period)*tc.minute_per_period)/40*59.12 end 课时成本
			  					
		from dw_hf_mobdb.dw_view_tms_contract tc
		left join dw_hf_mobdb.dw_view_tms_contract_payment tcp on tc.contract_id=tcp.contract_id
		left join dw_hf_mobdb.dw_hls_ddic ddic on ddic.code=tc.grade and ddic.type='ST009'
		left join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id = tc.submit_user_id
		          and cdme.stats_date = current_date() and cdme.class = 'CC'
		          and to_date(cdme.`date`) >= trunc(date_sub(current_date(),1),'MM')
		left join (	
		     		 	select  tc.student_intention_id,
						        min(tc.effective_date) as min_effective_date
			            from dw_hf_mobdb.dw_view_tms_contract tc
			            left join dw_hf_mobdb.dw_view_tms_contract_payment tcp on tc.contract_id=tcp.contract_id
						where year(tc.effective_date) >= 2018 and tcp.pay_status in (2, 4)
					    group by tc.student_intention_id
					    ) as a on tc.student_intention_id = a.student_intention_id

		where   year(tc.effective_date)>=2018 and tc.effective_date is not null
			    and tcp.pay_status in (2, 4) and tc.new_sign <>	2
				and tc.student_name not like '%测试%' and  tc.contract_id not like '%s%'
		group by tc.contract_id, tc.student_no, tc.effective_date, cdme.department
		) as e

where (e.合同金额-e.课时成本)/e.合同金额 between -1 and 1 and e.生效日期 < current_date()
order by e.生效日期