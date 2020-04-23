select a.student_no, a.student_name, a.plan_submit_dept, a.adjust_start_time, a.adjust_end_time,
       a.track_sale, a.lesson_status, a.fd_submit_time, a.final_feedback, a.content, a.subject_name,
       a.plan_submit_sale, a.lesson_plan_id

from(
      select    lp.lesson_plan_id,
                s.student_no,
                s.name as student_name,
                ui.name as plan_submit_sale,
                sd.department_name as plan_submit_dept,
                lp.adjust_start_time,
                lp.adjust_end_time,
                ui2.name as track_sale,
                case when sf.is_Fisrst=1 then '报名'
                     when sf.is_Fisrst=2 then '失单'
                     when sf.is_Fisrst=3 then '跳票'
                     when sf.is_Fisrst=4 then '待定'
                else '试听后待反馈' end  as lesson_status,
                sf.submit_time as fd_submit_time, 
                sf.final_feedback,
                sf.content,
                su.subject_name,
                rank() over (partition by lpo.student_intention_id order by lp.adjust_start_time desc) as rk1,
                rank() over (partition by concat(lpo.student_intention_id,lp.adjust_start_time) order by sf.submit_time desc) as rk2
      from dw_hf_mobdb.dw_lesson_plan_order lpo
      left join dw_hf_mobdb.dw_lesson_relation lr on lpo.order_id = lr.order_id
      left join dw_hf_mobdb.dw_lesson_plan lp on lr.plan_id = lp.lesson_plan_id
      left join dw_hf_mobdb.dw_view_student s on s.student_intention_id = lpo.student_intention_id
      left join dw_hf_mobdb.dw_submit_feedback sf on sf.order_id = lr.order_id
      left join dw_hf_mobdb.dw_subject su on su.subject_id = lp.subject_id
      left join dw_hf_mobdb.dw_view_user_info ui on lpo.apply_user_id = ui.user_id
      left join dw_hf_mobdb.dw_view_user_info ui2 on s.track_userid = ui2.user_id
      left join dw_hf_mobdb.dw_sys_user_role sur on ui.user_id=sur.user_id
      left join dw_hf_mobdb.dw_sys_role sr on sur.role_id=sr.role_id
      left join dw_hf_mobdb.dw_sys_department sd on sr.department_id=sd.department_id
      where to_date(lp.adjust_start_time) >= trunc('${analyse_date}','MM')
            and to_date(lp.adjust_start_time) <= date_sub('${analyse_date}',1) 
            and lp.lesson_type = 2 and lp.status in(3,5) and lp.solve_status <> 6  -- 完成试听课
            and sd.department_name like 'CC%'
      	    and ui2.name <> '已报名学员' -- 去除当前已成单的
            ) as a
where rk1 = 1 and rk2 = 1