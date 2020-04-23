-- 3月试听失单原因
select 
        s.student_no 学生编号,
        ui.name as 提交人,
        sd.department_name as 提交人部门,
        ui2.name as 当前跟进人,
        case sf.is_Fisrst when 1 then '报名' when 2 then '失单' when 3 then '跳票' when 4 then '待定' else '试听后待反馈' end as 试听后状态,
        sf.submit_time as 反馈提交日期, 
        sf.final_feedback as 试听反馈,
        sf.content as 备注, 
        lp.adjust_start_time as 试听课开始时间,
        lp.adjust_end_time as 试听课结束时间
from hfjydb.lesson_plan_order lpo
left join hfjydb.lesson_relation lr on lpo.order_id = lr.order_id
left join hfjydb.lesson_plan lp on lr.plan_id = lp.lesson_plan_id
left join hfjydb.view_student s on s.student_intention_id = lpo.student_intention_id
left join hfjydb.submit_feedback sf on sf.order_id = lr.order_id
left join hfjydb.subject su on su.subject_id = lp.subject_id
left join hfjydb.view_user_info ui on lpo.apply_user_id = ui.user_id
left join hfjydb.view_user_info ui2 on s.track_userid = ui2.user_id
left join hfjydb.sys_user_role sur on ui.user_id=sur.user_id
left join hfjydb.sys_role sr on sur.role_id=sr.role_id
left join hfjydb.sys_department sd on sr.department_id=sd.department_id
where date(lp.adjust_start_time)>= DATE_FORMAT(DATE_SUB(CURDATE(),INTERVAL 1 day),'%Y-%m-01')
    and date(lp.adjust_start_time)<CURDATE() -- 上试听课开始时间
    and lp.lesson_type = 2 and lp.status in(3,5) and lp.solve_status<>6  -- 试听课
    and (sd.department_name like '%CC%' or sd.department_name like '%销售%') -- 限定销售
    and sf.is_Fisrst=2
    and ui2.name in(
                  '新试听后失单OC',
                  '新试听15天未成单',
                  '试听后失单OC-1',
                  '新离职人员OC',
                  '新试听前失单OC',
                  '重复数据存放名单',
                  '重复进线池',
                  '新名单废单池'
                   ) -- 8个池名单
;
