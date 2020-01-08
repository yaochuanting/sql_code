-- T-1当月所有销售信息
select cd.date, cd.user_id, ui.job_number, ui.`name`, cd.department_name, cd.city, cd.branch, cd.center, cd.region, cd.department, cd.grp
from bidata.charlie_dept_history cd
LEFT JOIN view_user_info ui on ui.user_id = cd.user_id
where cd.department_name not like '%学管%'
and cd.date >= date_sub(date_add(LAST_DAY(date_sub(curdate(), interval 1 day)),interval 1 day), interval 1 month)
and cd.date < curdate();


-- 每天的总通时总通次
select 
		date(tcr.end_time) date, 
		tcr.user_id, 
		sum(timestampdiff(second,bridge_time,end_time)) call_time,
		count(*) total_call_count,
		count(tcr.bridge_time) connected_call_count
from view_tms_call_record tcr
where tcr.call_type = 1 ## 呼叫学生
and tcr.end_time >= date_sub(date_add(LAST_DAY(date_sub(curdate(), interval 1 day)),interval 1 day), interval 1 month)-- 当月1号
and tcr.end_time < CURDATE()
group by date(tcr.end_time), tcr.user_id;




-- 邀约学生数 ,一位学生可能被多次邀约,选择时间最近的一次邀约
select aa.apply_time date, aa.user_id, count(aa.student_intention_id) trial_invite_num
from
    (
   select date(max(lpo.apply_time)) apply_time, lpo.apply_user_id user_id, lpo.student_intention_id
     from lesson_plan_order lpo
    where lpo.apply_time >= date_sub(date_add(LAST_DAY(date_sub(curdate(), interval 1 day)),interval 1 day), interval 1 month)
      and lpo.apply_time < CURDATE()
    GROUP BY lpo.student_intention_id, lpo.apply_user_id
    ) aa
group by aa.apply_time, aa.user_id;




-- 试听排课数,实际试听量,试听取消量,试听成单数
select
    aa.adjust_start_time date, aa.apply_user_id user_id, count(aa.student_intention_id) trial_plan_num,
    sum(case when trial_or_not > 0 then 1 else 0 end) trial_num,
    count(aa.student_intention_id) - sum(case when trial_or_not > 0 then 1 else 0 end) trial_absence_num,
    sum(case when deal_or_not > 0 then 1 else 0 end) trial_deal_num
from
    (select
        max(date(lp.adjust_start_time)) adjust_start_time,
        s.student_intention_id,
        lpo.apply_user_id,
        sum(case when lp.status in (3, 5) and lp.solve_status <> 6 then 1 else 0 end) trial_or_not,
        ## 是否成单
        sum(case when
            (select count(tc.contract_id)
            from
                view_tms_contract tc
            left join view_tms_contract_payment tcp on tc.contract_id = tcp.contract_id
            where tc.student_intention_id = s.student_intention_id
                and tc.submit_user_id = lpo.apply_user_id
                and tcp.pay_status in (2,4)
                and tc.status not in (7,8)
                and tc.submit_time > lp.adjust_start_time
            ) > 0 then 1
            else 0
            end
        ) deal_or_not
    from
        lesson_plan_order lpo
    right join lesson_relation lr on lpo.order_id = lr.order_id
    inner join lesson_plan lp on lp.lesson_plan_id=lr.plan_id
    LEFT JOIN view_student s on s.student_id=lp.student_id
    where lp.adjust_start_time >= date_sub(date_add(LAST_DAY(date_sub(curdate(), interval 1 day)),interval 1 day), interval 1 month)
      and lp.adjust_start_time < curdate()
      and lp.lesson_type = 2
    group by lpo.apply_user_id,s.student_intention_id
    )aa
group by aa.apply_user_id,aa.adjust_start_time;



-- 体验上课量,体验排课量,体验课跳票量
select
    aa.adjust_start_time date, aa.opt_user user_id,
    sum(case when aa.exp_or_not>0 then 1 else 0 end ) exp_attend_num,
    count(case when aa.exp_or_not>0 then 1 else 0 end ) exp_plan_num,
    count(case when aa.exp_or_not>0 then 1 else 0 end )-sum(case when aa.exp_or_not>0 then 1 else 0 end ) exp_absence_num
from
    (
    select lph.opt_user,lp.student_id,date(max(lp.adjust_start_time)) adjust_start_time,
      sum(case when lp.status = 3 and lp.solve_status <> 6 then 1 else 0 end) exp_or_not
    from lesson_plan lp
    left join tms_lesson_plan_history lph on lp.lesson_plan_id= lph.lesson_plan_id
    where lp.lesson_type=3 ## 体验课
      and lp.adjust_start_time >= date_sub(date_add(LAST_DAY(date_sub(curdate(), interval 1 day)),interval 1 day), interval 1 month)
      and lp.adjust_start_time < curdate()
    group by lp.student_id,lph.opt_user
    )aa
group by aa.adjust_start_time,aa.opt_user;


-- 试听且体验学生数
select
		aa.adjust_start_time date,
		aa.apply_user_id user_id,
		sum(case when aa.exp_or_not > 0 then 1 else 0 end) trial_and_exp_num
from
    (select
        date(max(lp.adjust_start_time)) adjust_start_time,
        s.student_intention_id,
        lpo.apply_user_id,
        sum(case when (lp.student_id in (select distinct lp.student_id
                      from lesson_plan lp
                      where lp.lesson_type=3
                        and lp.adjust_start_time >= date_sub(date_add(LAST_DAY(date_sub(curdate(), interval 1 day)),interval 1 day), interval 1 month)
                        and lp.adjust_start_time < curdate())
                   ) then 1 else 0 end
        ) exp_or_not
    from lesson_plan_order lpo
    right join lesson_relation lr on lpo.order_id = lr.order_id
    inner join lesson_plan lp on lp.lesson_plan_id=lr.plan_id
    LEFT JOIN view_student s on s.student_id=lp.student_id
    where lp.adjust_start_time >= date_sub(date_add(LAST_DAY(date_sub(curdate(), interval 1 day)),interval 1 day), interval 1 month)
    and lp.adjust_start_time < curdate()
    and lp.lesson_type = 2
    GROUP BY s.student_intention_id,lpo.apply_user_id
    ) aa
group by aa.adjust_start_time, aa.apply_user_id;




-- 成单总数,成单总金额
select
		last_pay_date date,
		submit_user_id user_id,
		count(DISTINCT a.contract_id) deals_num,
		sum(real_pay_sum) deals_amount
from
    (select
        tc.submit_user_id,
        max(date(tcp.pay_date)) last_pay_date,
        tc.contract_id,
        sum(tcp.sum)/100 real_pay_sum,
        (tc.sum-666)*10 contract_amount
    from hfjydb.view_tms_contract_payment tcp
    left join hfjydb.view_tms_contract tc on tcp.contract_id  = tc.contract_id
    where tcp.pay_status in (2,4)
        and tc.status not in (7, 8)
    group by tcp.contract_id
    ) a
where real_pay_sum >= contract_amount
    and last_pay_date >= date_sub(date_add(LAST_DAY(date_sub(curdate(), interval 1 day)),interval 1 day), interval 1 month)
    and last_pay_date < CURDATE()
GROUP BY last_pay_date, submit_user_id;

-- 新线索量
select a.get_date date, a.communication_person user_id, a.`新线索量` new_keys_num
from
    (
    select
        date(date) get_date, communication_person, count(1)  '新线索量'
    from
        bidata.charlie_new_keys
    where date >= date_sub(date_add(LAST_DAY(date_sub(curdate(), interval 1 day)),interval 1 day), interval 1 month)
        and date < CURDATE()
    group by get_date, communication_person
    ) a;

-- OC线索量
select
		date(into_pool_date) date,
		track_userid user_id,
		count(distinct intention_id) oc_keys_num
from tms_pool_exchange_log tpel
where into_pool_date >= date_sub(date_add(LAST_DAY(date_sub(curdate(), interval 1 day)),interval 1 day), interval 1 month)
    and into_pool_date < CURDATE()
    and
        ## 自关联取最新记录的那个沟通人
        (select name
        from view_user_info
        where user_id =
            (select track_userid
            from tms_pool_exchange_log
            where intention_id = tpel.intention_id and id < tpel.id
            order by id desc
            limit 1)
        ) like '%OC%'
group by date, track_userid
having track_userid is not null;



-- 全款成单数,全款成单额
select
		aa.date, aa.user_id,
		sum(aa.is_full) full_num,
		sum(aa.full_amount) full_amount
from
    (
    select
        max(a.date) date,a.user_id,a.contract_id,
        (case when sum(a.method)=0 then 1 else 0 end) is_full,
        (case when sum(a.method)=0 then a.amount else 0 end) full_amount,
        a.contract_amount
    from
        (select
            date(tcp.pay_date) date,
            tc.submit_user_id user_id,
            tcp.contract_id,
            (case when tcp.pay_method_new in (select code from bidata.gen_dict where description = '分期' and type = 'pay_method_new') then 1 else 0 end ) method,
            (tcp.sum)/100 amount,
            (tc.sum-666)*10 contract_amount
        from view_tms_contract_payment tcp
        left join view_tms_contract tc on tcp.contract_id=tc.contract_id
        where tcp.pay_date >= date_sub(date_add(LAST_DAY(date_sub(curdate(), interval 1 day)),interval 1 day), interval 1 month)
        and tcp.pay_date < CURDATE()
        and tcp.pay_status in (2,4)
        and tc.status not in (7, 8)
        )a
    group by a.contract_id
    having sum(a.amount) >=a.contract_amount
    )aa
group by aa.date,aa.user_id;


-- 转介绍成单量,转介绍成单量
select
		last_pay_date date,
		submit_user_id user_id,
		count(a.contract_id) rec_deal_num,
		sum(real_pay_sum) rec_deal_amount
from 
		(select 
        tcp.submit_user_id,
        max(date(tcp.pay_date)) last_pay_date,
        tc.contract_id,
        sum(tcp.sum)/100 real_pay_sum,
        (tc.sum-666)*10 contract_amount
    from hfjydb.view_tms_contract_payment tcp
    left join hfjydb.view_tms_contract tc on tcp.contract_id  = tc.contract_id
    left join view_student s on s.student_intention_id = tc.student_intention_id
    where tcp.pay_status in (2,4)
        and tc.status not in (7, 8)
        ## 转介绍的条件
        and (s.coil_in in (13,22,27) or s.know_origin in (56,71,22,24,25,41))
		group by tcp.contract_id
		) a
where real_pay_sum >= contract_amount
    and last_pay_date >= date_sub(date_add(LAST_DAY(date_sub(curdate(), interval 1 day)),interval 1 day), interval 1 month)
    and last_pay_date < CURDATE()
GROUP BY last_pay_date, submit_user_id;
