
####线索提交至待分配 1
select
    student_intention_id,
    min(submit_time) min_submit_time, -- '最早线索提交时间'
    track_userid
from 
    view_student
group by student_intention_id
having min(submit_time) >= '2019-01-01' and min(submit_time) < curdate();


####首次拨打 2 
select
    tcr.student_intention_id,
    min(tcr.end_time) min_end_time, -- '首次拨打时间'
    tcr.user_id
from 
    view_tms_call_record tcr
left join view_user_info ui on ui.user_id = tcr.user_id
where tcr.call_type = 1 -- 1. 呼叫学生  2.呼叫老师 3.其他呼叫
    and ui.account_type = 1 
    and ui.name not like '%测试%' 
group by tcr.student_intention_id
having min(tcr.end_time) >= '2019-01-01' and min(tcr.end_time) < curdate();


####销售获取名单 3
select
    min(date) min_date, -- `获取名单时间`
    intention_id,
    communication_person
from bidata.charlie_new_keys
group by intention_id
having min(date) >= '2019-01-01' and min(date) < curdate();


####首次接通 4 
select
    tcr.student_intention_id,
    min(tcr.bridge_time)  min_bridge_time, -- 首次接通时间
    tcr.user_id
from
    view_tms_call_record tcr
left join view_user_info ui on ui.user_id = tcr.user_id
where tcr.status = 33  -- 30:座席未接听 31:座席接听 32:客户未接听 33:双方接听
    and tcr.call_type = 1  -- 1.呼叫学生 2.呼叫老师 3.其他呼叫
    and ui.account_type = 1 
    and ui.name not like '%测试%'
group by tcr.student_intention_id
having min(tcr.bridge_time) >= '2019-01-01' and min(tcr.bridge_time) < curdate();


####首次有效沟通 5 
select
    tcr.student_intention_id,
    min(tcr.bridge_time) min_effective_call_start_time, -- 首次有效沟通开始时间
    min(tcr.end_time) min_effective_call_end_time, -- 首次有效沟通结束时间
    timestampdiff(second,tcr.bridge_time,tcr.end_time) call_duration, -- 首次有效沟通通话时间
    tcr.user_id
from 
    view_tms_call_record tcr
left join view_user_info ui on ui.user_id = tcr.user_id
where tcr.status = 33
    and tcr.call_type = 1
    and timestampdiff(second,tcr.bridge_time,tcr.end_time) >= 60
    and ui.account_type = 1 
    and ui.name not like '%测试%'
group by tcr.student_intention_id
having min(tcr.bridge_time) >= '2019-01-01' and min(tcr.bridge_time) < curdate();


####试听邀约 6 
select
    lpo.student_intention_id,
    min(lpo.apply_time) min_apply_time, -- '最早申请设班单的时间'
    lpo.apply_user_id
from 
    lesson_plan_order lpo
left join view_user_info ui on ui.user_id = lpo.apply_user_id
where ui.account_type = 1 
    and ui.name not like '%测试%'
group by lpo.student_intention_id
having min(lpo.apply_time) >= '2019-01-01' and  min(lpo.apply_time) < curdate();


####排试听课 7 
select
    s.student_intention_id,
    max(lp.adjust_start_time) min_adjust_start_time -- '试听课最后排课时间'
from
    lesson_plan lp
left join view_student s on lp.student_id = s.student_id
left join view_user_info ui on ui.user_id = s.student_id
where lp.lesson_type=2
    and ui.account_type = 1 
    and ui.name not like '%测试%'
group by s.student_intention_id
having  max(lp.adjust_start_time) >= '2019-01-01' and max(lp.adjust_start_time) < curdate();


####排体验课 8 
select
    s.student_intention_id,
    max(lp.adjust_start_time) min_adjust_start_time, -- '体验课最后排课时间'
    lp.student_id,
    lph.opt_user    
from
    lesson_plan lp
left join view_student s on lp.student_id = s.student_id
left join tms_lesson_plan_history lph on lp.lesson_plan_id= lph.lesson_plan_id
left join view_user_info ui on ui.user_id = lph.opt_user
where lp.lesson_type=3
    and ui.account_type = 1 
    and ui.name not like '%测试%'
group by s.student_intention_id
having max(lp.adjust_start_time) >= '2019-01-01' and max(lp.adjust_start_time) < curdate();


####实际试听 9 
select
    s.student_intention_id,
    max(lp.adjust_start_time) max_adjust_start_time, -- '试听课实际上课时间'
    lp.student_id,
    lpo.apply_user_id
from 
    lesson_plan lp
left join view_student s on lp.student_id = s.student_id
left join lesson_relation lr on lp.lesson_plan_id = lr.plan_id
left join lesson_plan_order lpo on lr.order_id = lpo.order_id
left join view_user_info ui on ui.user_id = lpo.apply_user_id
where lp.lesson_type = 2
    and lp.status in (3, 5) 
    and lp.solve_status <> 6
    and ui.account_type = 1 
    and ui.name not like '%测试%'
group by s.student_intention_id
having max(lp.adjust_start_time) >= '2019-01-01' and  max(lp.adjust_start_time) < curdate();

####提交成单 10 
select
    tc.student_intention_id,
    tc.contract_id,
    min(tc.submit_time) min_submit_time, -- 最早提交成单时间
    tc.submit_user_id
from 
    view_tms_contract tc
left join view_user_info ui on tc.submit_user_id = ui.user_id
left join view_student s on tc.student_intention_id = s.student_intention_id
left join lesson_plan lp on s.student_id = lp.student_id
where  tc.submit_time > lp.adjust_start_time
    and ui.account_type = 1 
    and ui.name not like '%测试%'
group by tc.student_intention_id,tc.contract_id
having min(tc.submit_time) >= '2019-01-01' and min(tc.submit_time) < curdate();


####添加付款记录 11 
select
    tc.student_intention_id,
    tcp.contract_id,
    min(tcp.submit_time) min_submit_time, -- 最早添加付款记录的时间
    tcp.submit_user_id
from 
    view_tms_contract_payment tcp
left join view_user_info ui on tcp.submit_user_id = ui.user_id
left join view_tms_contract tc on tcp.contract_id = tc.contract_id
where ui.account_type = 1 
    and ui.name not like '%测试%'
group by tc.student_intention_id,tc.contract_id
having min(tcp.submit_time) >= '2019-01-01' and min(tcp.submit_time) < curdate();


####首次付款 12 
select
    tc.student_intention_id, 
    tcp.contract_id,
    min(tcp.pay_date) min_pay_date, -- 首次付款日期
    tcp.submit_user_id
from 
    view_tms_contract_payment tcp
left join view_user_info ui on tcp.submit_user_id = ui.user_id
left join view_tms_contract tc on tcp.contract_id = tc.contract_id
where tcp.pay_status in (2,4)
    and tc.`status` not in (7,8)
    and ui.account_type = 1 
    and ui.name not like '%测试%'
group by tc.student_intention_id,tc.contract_id
having  min(tcp.pay_date) >= '2019-01-01'and min(tcp.pay_date) < curdate();

####付完全款 13 
select 
	aa.student_intention_id,
    aa.contract_id,
	max(aa.pay_date) max_pay_date -- 付完全款日期
from 
    (
    select 
        a.student_intention_id student_intention_id, 
        a.contract_id contract_id,
        a.pay_date pay_date,
        sum(a.amount) sum_amount,
        a.contract_amount contract_amount
    from 
        (
        select
            tc.student_intention_id student_intention_id, 
            tcp.contract_id contract_id,
            tcp.pay_date pay_date,
            (tcp.sum)/100 amount,  
	        (tc.sum-666)*10 contract_amount 
        from view_tms_contract_payment tcp
        left join view_user_info ui on tcp.submit_user_id = ui.user_id
        left join view_tms_contract tc on tcp.contract_id=tc.contract_id
        where tcp.pay_status in (2,4)
	        and tc.`status` not in (7,8) 
            and tcp.pay_date >= '2019-01-01'
            and tcp.pay_date < curdate()
            and ui.account_type = 1 
            and ui.name not like '%测试%'	 
        ) a
    group by a.contract_id
    having sum(a.amount) >= a.contract_amount
    )aa
group by aa.student_intention_id;


####家长签署电子合同 14 
select
    tc.student_intention_id, 
    min(tca.signup_time) min_signup_time, -- 电子合同最早签署时间
	tc.contract_id,
    tc.submit_user_id
from 
    view_tms_contract_paper tca
left join view_tms_contract tc on tca.contract_id = tc.contract_id
left join view_user_info ui on tc.submit_user_id = ui.user_id
where tca.type = 1
    and tca.status = 3  -- 1待发送、2等待他人签署、3已签署、5已废弃 '
    and tca.signup_time >= '2019-01-01'
    and tca.signup_time < curdate()
    and ui.account_type = 1 
    and ui.name not like '%测试%'
group by tc.student_intention_id,tc.contract_id
having min(tca.signup_time);


####第一堂课消课完成 15 
select
    min(lp.real_end_time)  min_real_end_time, -- 正式课第一堂课消课完成时间 (仅限于合同流程没有走完,手动排课)
    s.student_intention_id
from 
    lesson_plan lp
left join view_student s on lp.student_id = s.student_id
left join view_user_info ui on s.student_intention_id = ui.user_id
where lp.status in (3,5) 
    and lp.solve_status <> 6
    and lp.lesson_type = 1
    and ui.account_type = 1 
    and ui.name not like '%测试%'
group by s.student_intention_id
having min(lp.real_end_time) >= '2019-01-01' and min(lp.real_end_time) < curdate();


####合同课时消耗完毕 16 
select
	t.student_intention_id,
    t.max_real_end_time,
	t.contract_id,
    t.submit_user_id
from
    (select 
            tc.student_intention_id,
            tc.contract_id,
            tc.period + ifnull(tc.donate_period,0)-ifnull(sum(lp.class_period),0) as rest, ###剩余课时
            max(lp.real_end_time) max_real_end_time,
			min(lp.real_end_time) min_real_end_time,
            tc.submit_user_id
    from 
        view_tms_contract tc 
    left join lesson_plan lp on lp.contract_id = tc.contract_id 
        and lp.lesson_type=1
        and lp.status<>0  -- 0 不可用 1 待授课 2 授课中 3已授课 4已设置课件 5未用系统 6预排课   
        and lp.solve_status = 5   -- 1：初始值；2：老师确认班主任未确认；3：班主任确认老师未确认 4：上报异常 5：管理员确认或老师班主任都确认 6：取消 
    where -- tc.big_type_id = 1 
        tc.status not in (7,8)     -- 1创建 2审核 3待确认 4生效 5执行 6暂停 7终止 8废弃 9合同课时取消   
        and tc.teacher_level is not null  -- 1.资深名师 2.教学总监
    group by tc.contract_id
    )t
left join view_user_info ui on t.submit_user_id = ui.user_id
where t.rest = 0
    and ui.account_type = 1 
    and ui.name not like '%测试%'
group by t.student_intention_id
having  t.max_real_end_time >= '2019-01-01'
    and t.max_real_end_time < curdate();

####合同终止 17
select 
    tc.student_intention_id,
    max(tcoh.operate_time) max_time
from
    view_tms_contract tc
left join  tms_contract_operate_history tcoh on tc.contract_id = tcoh.contract_id
where tc.status = 7
group by tc.student_intention_id,tc.contract_id
having max_time >= '2019-01-01' and max_time < curdate();
