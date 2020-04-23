select      distinct
            lpo.order_id `设班单编号`,
            lpo.apply_time `设班单申请时间`, 
            lp.adjust_start_time `上课开始时间`, 
            cdme.name `申请人`, 
            cdme.job_number `申请人员工编号`,
            cdme.department_name `申请人所在组别`, 
            s.student_no `学生编号`,
            s.name `学生姓名`, 
            h.value `年级`,
            sub.subject_name `科目名称`,
            case when lpo.grade_rank=0 then '优秀' when lpo.grade_rank=1 then '中上' when lpo.grade_rank=2 then '中等' 
                 when lpo.grade_rank=3 then '中下' when lpo.grade_rank=4 then '较差' end `分数等级`,
            lpo.learning_target `学习目标`,
            otc.content `试听内容`,
            lpo.recent_scores `学科最近分数`, 
            case when lpo.is_First = 0 then '是' when lpo.is_First = 1 then  '否' end `是否首次试听`,
            case when lp2.student_id is not null then '是' else '否' end `是否上过体验课`,
            ui2.name `当前跟进人`,
            cdme2.department_name `当前跟进人组别`,
            b.start_time `销售最后沟通时间`,
            b.name `最后沟通销售姓名`,
            b.department_name `最后沟通销售组别`,
            b.content `销售最后沟通内容`,
            case when t.quarters_type =1 then '全职授课' 
                 when t.quarters_type =2 then '全职教研' 
                 when t.quarters_type =3 then '兼职教学' 
                 when t.quarters_type =4 then '实习' end `教师岗位属性`


from dw_hf_mobdb.dw_lesson_plan_order lpo 
right join dw_hf_mobdb.dw_lesson_relation lr on lpo.order_id = lr.order_id 
inner join dw_hf_mobdb.dw_lesson_plan lp on lp.lesson_plan_id = lr.plan_id
left join dw_hf_mobdb.dw_view_student s on s.student_id = lp.student_id  
left join dw_hf_mobdb.dw_order_trial_class otc on lpo.order_id = otc.order_id 
left join dw_hf_mobdb.dw_hls_ddic h on lpo.subject_grade = h.hls_ddic_id  
left join dw_hf_mobdb.dw_subject sub on sub.subject_id = lp.subject_id 
left join dw_hf_mobdb.dw_submit_feedback sf on sf.order_id = lr.order_id 
left join dw_hf_mobdb.dw_view_teacher t on lp.teacher_id = t.teacher_id
left join dw_hf_mobdb.dw_lesson_plan lp2 on lp2.student_id = s.student_id
          and lp2.lesson_type =3 and lp2.status=3 and lp2.solve_status <> 6
inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id = lpo.apply_user_id 
      and cdme.stats_date = '${analyse_date}' and cdme.class = 'CC'
left join dt_mobdb.dt_charlie_dept_month_end cdme2 on cdme2.user_id = s.track_userid
          and cdme2.stats_date = '${analyse_date}' and cdme2.class = 'CC'
left join dw_hf_mobdb.dw_view_user_info ui on ui.user_id = lp.teacher_id
left join dw_hf_mobdb.dw_view_user_info ui2 on ui2.user_id = s.track_userid
left join (
            select *
            from(
                  select date(cr.start_time) start_time, cr.student_intention_id, cr.content, 
                         cdme.name, cdme.department_name,
                         row_number() over (partition by student_intention_id order by cr.start_time desc) as rn
                  from dw_hf_mobdb.dw_view_communication_record cr
                  inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id = cr.communication_person
                             and cdme.stats_date = '${analyse_date}' and cdme.class = 'CC'
                  where date(cr.start_time) >= date_sub('${analyse_date}',90)
                        and date(cr.start_time) <= '${analyse_date}'
                             ) as a
            where rn=1
            ) as b on b.student_intention_id = lpo.student_intention_id

where date(lp.adjust_start_time)>=date_add('${analyse_date}',1)
      and date(lp.adjust_start_time)<=date_add('${analyse_date}',7)
      and s.account_type = 1
      and ui.account_type = 1
      and lpo.type=2