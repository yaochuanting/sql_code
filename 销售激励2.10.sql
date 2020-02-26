-- 请求数
select  date_format(ss.view_time, '%Y-%m') as month
		count(distinct ss.student_intention_id) as req
from hfjydb.ss_collection_sale_roster_action ss
inner join bidata.charlie_dept_month_end cdme on cdme.user_id=ss.user_id
           and cdme.stats_date = curdate() and cdme.class='销售'
where date(ss.view_time)>='2019-12-01' and date(ss.view_time)<='2020-01-31'
group by month;


-- 邀约数
select
      date_format(b.adjust_start_time, '%Y-%m') as month,
      count(distinct b.student_intention_id) all_plan_num, -- 总试听邀约量
      count(distinct case when day(b.adjust_start_time)>=10 and day(b.adjust_start_time)<=20 then b.student_intention_id
      	             else null end) all_plan_num1,
      count(distinct(case when b.is_trial = 1 then b.student_intention_id else null end)) all_trial_num, -- 总试听出席量
      count(distinct(case when b.is_trial = 1 and day(b.adjust_start_time)>=10 and day(b.adjust_start_time)<=20
      	                  then b.student_intention_id else null end)) all_trial_num1
		
from(    
		select
				   lpo.apply_user_id, lpo.student_intention_id, s.student_no, lp.adjust_start_time,
				   (case when lp.status in (3,5) and lp.solve_status <> 6 then 1 else 0 end) is_trial		  			  
		from hfjydb.lesson_plan_order lpo
		left join hfjydb.lesson_relation lr on lpo.order_id = lr.order_id
		left join hfjydb.lesson_plan lp on lr.plan_id = lp.lesson_plan_id
		left join hfjydb.view_student s on s.student_intention_id = lpo.student_intention_id
		inner join bidata.charlie_dept_month_end cdme on cdme.user_id = lpo.apply_user_id 
				   and cdme.stats_date = '2020-01-31' and cdme.class = '销售'
		where lp.lesson_type = 2
				and date(lp.adjust_start_time) >= '2019-11-01'
				and date(lp.adjust_start_time) <= '2020-01-31'
				and s.account_type=1
		) as b
group by month;



-- 成单
select  date_format(a.last_pay_date,'%Y-%m') as month,
        count(a.contract_id) as all_deal_num,   -- 总成单量
        count(case when day(a.last_pay_date)>=10 and day(a.last_pay_date)<=20 then a.contract_id else null end) as all_deal_num1,
		sum(a.real_pay_sum) as all_deal_amount,   -- 总成单额
		sum(case when day(a.last_pay_date)>=10 and day(a.last_pay_date)<=20 then a.real_pay_sum else 0 end) as all_deal_amount1,
		count(case when (a.coil_in in (13,22) or a.know_origin in (56,71,22,24,25,41))
				   then a.contract_id else null end) as rec_deal_num,   -- 转介绍成单量
		count(case when day(a.last_pay_date)>=10 and day(a.last_pay_date)<=20
			            and (a.coil_in in (13,22) or a.know_origin in (56,71,22,24,25,41))
				   then a.contract_id else null end) as rec_deal_num1,
		sum(case when (a.coil_in in (13,22) or a.know_origin in (56,71,22,24,25,41))
				 then a.real_pay_sum else 0 end) as rec_deal_amount,   -- 转介绍成单额
		sum(case when day(a.last_pay_date)>=10 and day(a.last_pay_date)<=20
			          and (a.coil_in in (13,22) or a.know_origin in (56,71,22,24,25,41))
				 then a.real_pay_sum else 0 end) as rec_deal_amount1

from(
		select
				min(tcp.pay_date) min_pay_date,
				max(tcp.pay_date) last_pay_date,
				tcp.contract_id,  
				s.student_no,
				s.student_intention_id,
				s.submit_time,
				s.coil_in,
				s.know_origin,
				sum(tcp.sum)/100 real_pay_sum, 
				ui.name,
				ui.job_number,
				(tc.sum-666)*10 contract_amount
		from hfjydb.view_tms_contract_payment tcp
		left join hfjydb.view_tms_contract tc on tcp.contract_id  = tc.contract_id
		left join hfjydb.view_student s on s.student_intention_id = tc.student_intention_id
		left join hfjydb.view_user_info ui on ui.user_id = tc.submit_user_id
		inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tcp.submit_user_id
				   and cdme.stats_date = curdate() and cdme.class = '销售'
		where tcp.pay_status in (2,4)
			  and ui.account_type = 1
		group by tcp.contract_id
		having real_pay_sum >= contract_amount
			   and date(last_pay_date)>='2019-11-01'
			   and date(last_pay_date)<='2020-01-31'
		   ) as a
group by month