####updated by:吴小艳
####update time:2019-12-20
####增加流水业绩订单量及去除合同状态为废弃的

####updated by:姚传婷
####update time:2020-03-05
####修改架构，统一使用cdme表


select  cdme.class 类型, cdme.name 姓名, cdme.job_number 员编,
		sum(tcp.sum/100) 流水业绩,
		count(distinct tcp.contract_id) 流水成单量,
		cdme.department_name 所在部门

from view_tms_contract_payment tcp 
left join view_tms_contract tc on tc.contract_id=tcp.contract_id
inner join bidata.charlie_dept_month_end cdme on cdme.user_id=tc.submit_user_id
		   and cdme.stats_date=curdate() and cdme.date>=date_format(curdate(),'%Y-%m-01')
left join view_user_info u on u.user_id=tc.submit_user_id 
where date(pay_date)>=date_format(curdate(),'%Y-%m-01') and date(pay_date)<=curdate() 
	and tcp.pay_status in (2,4) 
	and tc.status <>8  -- 剔除合同废弃的
	and u.account_type = 1
group by u.user_id,u.job_number,u.name 
order by sum(tcp.sum/100) desc 
