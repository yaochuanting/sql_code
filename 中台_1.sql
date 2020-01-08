select
        date_sub(curdate(),interval 1 day) stats_date,
        sum(tcp.sum/100) performance,   -- 流水业绩
		case when s.submit_time >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01') then 'new'
		     when s.submit_time >= date_sub(date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01'),interval 1 month) then 'sec_new'
		else 'oc' end key_attr
	    

from bidata.charlie_dept_month_end cdme
left join hfjydb.view_tms_contract tc on tc.submit_user_id = cdme.user_id
          and tc.status <> 8
left join hfjydb.view_student s on tc.student_no =s.student_no
left join hfjydb.view_tms_contract_payment tcp on tcp.contract_id = tc.contract_id
          and tcp.pay_date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
		  and tcp.pay_date < curdate()
		  and tcp.pay_status in (2,4)
where cdme.class = '销售'
      and cdme.stats_date = curdate()
      and cdme.date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
group by stats_date, key_attr