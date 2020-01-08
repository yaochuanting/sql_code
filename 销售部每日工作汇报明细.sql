

-- 销售部门信息
select curdate() stats_date,cdme.date, cdme.user_id, cdme.job_number, cdme.`name`, cdme.department_name,
(case when ifnull(ui.reg_date,(select ulc.first_commu_time from bidata.will_user_list_crm ulc
where ulc.user_id = cdme.user_id and ulc.stats_date = curdate())) < date_sub(curdate(),interval 60 day) then '老人' else '新人' end) new_or_old,

(case when cdme.department_name like '上海销售第一集团军%' then '上海第一集团军'
    when cdme.department_name like '上海销售分公司%' then '上海分公司'
    when cdme.department_name like '上海销售第四集团军%' then '上海第四集团军'
    when cdme.department_name like '江苏销售%' then '江苏分公司'
    when cdme.department_name like '销售_区%' then  left(cdme.department_name,locate('区',cdme.department_name))
    else '其他' end) company,
cdme.city, cdme.branch, cdme.center, cdme.region,cdme.department, cdme.grp
from bidata.charlie_dept_month_end cdme
left join view_user_info ui on ui.user_id = cdme.user_id
where cdme.class ='销售'
and cdme.stats_date = curdate()
and cdme.date >= DATE_FORMAT(curdate() -interval 1 day,'%Y-%m-01')
and cdme.date <= curdate();

-- 销售昨日的流水业绩

select 
tc.submit_user_id user_id,sum(tcp.sum/100) performance_day
from view_tms_contract_payment tcp
left join view_tms_contract tc on tc.contract_id = tcp.contract_id
where date(tcp.pay_date) =date_sub(curdate(),interval 1 day)
and tcp.pay_status in (2,4) and tc.status not in (7,8)
GROUP BY user_id;


-- 销售当月至昨日的流水业绩
select 
tc.submit_user_id user_id,sum(tcp.sum/100) performance_month
from view_tms_contract_payment tcp
left join view_tms_contract tc on tc.contract_id = tcp.contract_id
where date(tcp.pay_date) >= DATE_FORMAT(curdate() -interval 1 day,'%Y-%m-01')
and date(tcp.pay_date) < CURDATE()
and tcp.pay_status in (2,4) and tc.status not in (7,8)
GROUP BY user_id;



-- 销售昨日新线索
select
slt.user_id,

(select acquired_list_num from sale_list_distribute_detail x join
(select max(id) id from sale_list_distribute_detail 
where update_time >= date_sub(curdate(),interval 1 day) and update_time < curdate()
group by user_id) y on x.id = y.id 
where x.user_id = slt.user_id) auto_dtr_num,  ##自动获取名单量
(select count(distinct cnk.intention_id)
	from bidata.charlie_new_keys cnk
	where cnk.opt_user<> 'OC分配账号' and stat_date = date_sub(curdate(),interval 1 day)
	and cnk.communication_person=slt.user_id) hand_dtr_num  ##手动分配名单量


from sale_level_total slt left join view_user_info ui on  ui.user_id=slt.user_id
left join sys_user_role sur  on ui.user_id=sur.user_id
left join sys_role sr  on sur.role_id=sr.role_id
left join sys_department sd on sr.department_id=sd.department_id
where  date(slt.last_update_time) = date_sub(curdate(),interval 1 day)

group by slt.user_id;

-- 销售当月至昨日新线索
select
slt.user_id,

(select sum(a.num)

    from
    (select x.user_id, (acquired_a_list_num + acquired_b_list_num + acquired_c_list_num + acquired_d_list_num) num from sale_list_distribute_detail x

    join
        (select max(id) id from sale_list_distribute_detail
        where update_time >= DATE_FORMAT(curdate() -interval 1 day,'%Y-%m-01') and update_time < curdate()
        group by user_id,date(update_time)) y on x.id = y.id )a

where a.user_id = slt.user_id
group by a.user_id

) auto_dtr_num_month,  ##自动获取名单量


(select count(distinct cnk.intention_id)
from bidata.charlie_new_keys cnk
where cnk.opt_user<> 'OC分配账号' and cnk.stat_date >= DATE_FORMAT(curdate() -interval 1 day,'%Y-%m-01')
and cnk.stat_date < curdate()  and cnk.communication_person=slt.user_id ) hand_dtr_num_month  ##手动分配名单量


from sale_level_total slt
left join view_user_info ui on  ui.user_id=slt.user_id
left join sys_user_role sur  on ui.user_id=sur.user_id
left join sys_role sr  on sur.role_id=sr.role_id
left join sys_department sd on sr.department_id=sd.department_id
where  date(slt.last_update_time) >= DATE_FORMAT(curdate() -interval 1 day,'%Y-%m-01') and  date(slt.last_update_time) < curdate()
group by slt.user_id;




-- 销售每月试听邀约学生中多少上了体验课,排试听课的人数,实际试听人数
select
		aa.apply_user_id user_id,
        count(distinct aa.student_intention_id) plan_num,
		sum(case when aa.exp_or_not > 0 then 1 else 0 end) trial_and_exp_num,
        sum(case when aa.trial_or_not > 0 then 1 else 0 end) trial_num
from
(select
			lpo.student_intention_id,
			lpo.apply_user_id,
			sum(case when (lp.student_id in (select distinct student_id
										from lesson_plan  
										where lesson_type=3 and status = 3 and solve_status <> 6
										and adjust_start_time >= DATE_FORMAT(curdate() -interval 1 day,'%Y-%m-01')
										and adjust_start_time < curdate())
						  ) then 1 else 0 end
			   ) exp_or_not,
            sum(case when (lp.student_id in (select distinct student_id
										from lesson_plan 
										where lesson_type=2 and status in(3,5) and solve_status <> 6 
											and adjust_start_time >= DATE_FORMAT(curdate() -interval 1 day,'%Y-%m-01')

											and adjust_start_time < curdate())
						  ) then 1 else 0 end) trial_or_not

	from lesson_plan_order lpo
	right join lesson_relation lr on lpo.order_id = lr.order_id
	inner join lesson_plan lp on lp.lesson_plan_id=lr.plan_id
	where lp.adjust_start_time >= DATE_FORMAT(curdate() -interval 1 day,'%Y-%m-01')
	and lp.adjust_start_time < curdate()
	and lp.lesson_type = 2
	GROUP BY lpo.student_intention_id,lpo.apply_user_id
) aa
group by aa.apply_user_id;

-- 当月试听且成单的学生数
select
    aa.apply_user_id user_id, 
    sum( deal_or_not) trial_deal_num ##试听成单数
from
    (select
        lpo.student_intention_id,
        lpo.apply_user_id,
        (case when (select count(a.student_intention_id)  
                    from
                      (select tc.submit_user_id,                      
                       tc.student_intention_id,
					   tc.submit_time,
                       date(max(tcp.pay_date)) last_pay_date,
                       sum(tcp.sum)/100 real_pay_sum,
                       (tc.sum-666)*10 contract_amount
                       from hfjydb.view_tms_contract_payment tcp
                       left join hfjydb.view_tms_contract tc on tcp.contract_id  = tc.contract_id
                       where tcp.pay_status in (2,4) and tc.`status` not in(7,8)
                       group by tcp.contract_id 
                       having real_pay_sum >= contract_amount)a
                       where a.submit_user_id = lpo.apply_user_id
					   and a.student_intention_id = lpo.student_intention_id
					   and a.submit_time > lp.adjust_start_time
                       and last_pay_date >= DATE_FORMAT(curdate() -interval 1 day,'%Y-%m-01')
                       and last_pay_date < CURDATE()
                       ) > 0 then 1 else 0 end) deal_or_not  
    from lesson_plan_order lpo
    right join lesson_relation lr on lpo.order_id = lr.order_id
    inner join lesson_plan lp on lp.lesson_plan_id=lr.plan_id
    where lp.adjust_start_time >= DATE_FORMAT(curdate() -interval 1 day,'%Y-%m-01')
    and lp.adjust_start_time < curdate()
    and lp.lesson_type = 2 and lp.status in(3,5) and lp.solve_status <> 6
    group by lpo.apply_user_id,lpo.student_intention_id
        )aa
group by aa.apply_user_id;

-- 销售当月至昨日转介绍线索量
select 
tpel.track_userid user_id,
count(distinct s.student_intention_id) rec_num
from view_student s
left join tms_pool_exchange_log tpel on tpel.intention_id = s.student_intention_id
where  (s.coil_in in (13,22,27) or s.know_origin in (56,71,22,24,25,41))
and tpel.into_pool_date >= DATE_FORMAT(curdate() -interval 1 day,'%Y-%m-01') 
and tpel.into_pool_date < curdate()
group by tpel.track_userid;


-- 销售当月总成单数
select
        a.submit_user_id user_id,
        count(DISTINCT a.student_intention_id) deals_num, ##成单学生数
        sum(a.real_pay_sum) deals_amount ##成单额
from
(select
        tc.submit_user_id,
        date(max(tcp.pay_date)) last_pay_date,
        tc.contract_id,
        tc.student_intention_id,
        sum(tcp.sum)/100 real_pay_sum,
        (tc.sum-666)*10 contract_amount
from hfjydb.view_tms_contract_payment tcp
left join hfjydb.view_tms_contract tc on tcp.contract_id  = tc.contract_id
where tcp.pay_status in (2,4) 
    and tc.`status` not in(7,8)
group by tcp.contract_id
) a
where a.real_pay_sum >= a.contract_amount
and a.last_pay_date >= DATE_FORMAT(curdate() -interval 1 day,'%Y-%m-01')
and a.last_pay_date < CURDATE()
GROUP BY user_id;




-- 销售当月转介绍成单数
select
		a.submit_user_id user_id,
		count(distinct a.student_intention_id) rec_deal_num,
		sum(a.real_pay_sum) rec_deal_amount
from 
		(select 
					tcp.submit_user_id, 
					date(max(tcp.pay_date)) last_pay_date,
					tc.contract_id,
                    tc.student_intention_id,
					sum(tcp.sum)/100 real_pay_sum, 
					(tc.sum-666)*10 contract_amount
			from hfjydb.view_tms_contract_payment tcp
			left join hfjydb.view_tms_contract tc on tcp.contract_id  = tc.contract_id
            left join view_student s on s.student_intention_id = tc.student_intention_id
			where tcp.pay_status in (2,4) 
				and tc.`status` not in (7,8) 
				and (s.coil_in in (13,22,27) or s.know_origin in (56,71,22,24,25,41))
			group by tcp.contract_id
		) a
where a.real_pay_sum >= a.contract_amount
	and a.last_pay_date >= DATE_FORMAT(curdate() -interval 1 day,'%Y-%m-01')
	and a.last_pay_date < CURDATE()
GROUP BY user_id;
