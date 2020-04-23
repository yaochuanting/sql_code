-- 架构
select  cdme.center, 
        cdme.region,
        cdme.department,
        cdme.department_name
from dt_mobdb.dt_charlie_dept_month_end cdme 
where to_date(cdme.stats_date)='${analyse_date}'
	  and cdme.class='CC' and cdme.department_name like 'CC%'
	  and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')
group by cdme.center, cdme.region, cdme.department, cdme.department_name


-- 粒子获取数
select cdme.department_name, 
       count(distinct case when to_date(tpel.into_pool_date)='${analyse_date}' then tpel.intention_id end) d_keys,
       count(distinct case when to_date(tpel.into_pool_date)='${analyse_date}' and to_date(s.create_time)>=trunc('${analyse_date}','MM') then tpel.intention_id end) d_new_keys,
       count(distinct case when date(tpel.into_pool_date)='${analyse_date}' and to_date(s.create_time)<trunc('${analyse_date}','MM') then tpel.intention_id end) d_oc_keys,
       count(distinct tpel.intention_id) m_keys,
       count(distinct case when to_date(s.create_time)>=trunc('${analyse_date}','MM') then tpel.intention_id end) m_new_keys,
       count(distinct case when to_date(s.create_time)<trunc('${analyse_date}','MM') then tpel.intention_id end) m_oc_keys
from dw_hf_mobdb.dw_tms_pool_exchange_log tpel
left join dw_hf_mobdb.dw_view_student s on s.student_intention_id=tpel.intention_id
inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id=tpel.track_userid
           and cdme.class='CC' and to_date(cdme.stats_date)='${analyse_date}'
           and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')
where to_date(tpel.into_pool_date)>=trunc('${analyse_date}','MM')
      and to_date(tpel.into_pool_date)<='${analyse_date}'
      and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')
group by cdme.department_name



-- 设班单发起数
select  cdme.department_name,
        count(distinct case when to_date(lpo.apply_time)='${analyse_date}' then lpo.student_intention_id end) as d_apply_num,
        count(distinct lpo.student_intention_id) as m_apply_num
from dw_hf_mobdb.dw_lesson_plan_order lpo
left join dw_hf_mobdb.dw_lesson_relation lr on lpo.order_id=lr.order_id
left join dw_hf_mobdb.dw_lesson_plan lp on lr.plan_id=lp.lesson_plan_id
left join dw_hf_mobdb.dw_view_student s on s.student_intention_id=lpo.student_intention_id
inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id=lpo.apply_user_id 
		   and to_date(cdme.stats_date)='${analyse_date}' and cdme.class='CC'
		   and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')
where lp.lesson_type=2
	  and to_date(lpo.apply_time)>=trunc('${analyse_date}','MM')
	  and to_date(lpo.apply_time)<='${analyse_date}'
	  and s.account_type=1
group by cdme.department_name



-- 排课数
select  cdme.department_name,
		count(distinct case when to_date(lp.adjust_start_time)='${analyse_date}' then lpo.student_intention_id end) as d_plan_num,
		count(distinct lpo.student_intention_id) as m_plan_num,
		count(distinct case when lp.status in (3,5) and lp.solve_status<>6 then lpo.student_intention_id end) as m_trial_num
from dw_hf_mobdb.dw_lesson_plan_order lpo
left join dw_hf_mobdb.dw_lesson_relation lr on lpo.order_id=lr.order_id
left join dw_hf_mobdb.dw_lesson_plan lp on lr.plan_id=lp.lesson_plan_id
left join dw_hf_mobdb.dw_view_student s on s.student_intention_id=lpo.student_intention_id
inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id=lpo.apply_user_id 
		   and to_date(cdme.stats_date)='${analyse_date}' and cdme.class='CC'
		   and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')
where lp.lesson_type=2
	  and to_date(lp.adjust_start_time)>=trunc('${analyse_date}','MM')
	  and to_date(lp.adjust_start_time)<='${analyse_date}'
	  and s.account_type = 1
group by cdme.department_name



-- 天润通时通次
select  cdme.department_name,
		sum(unix_timestamp(tcr.end_time, 'yyyy-MM-dd HH:mm:ss')-unix_timestamp(tcr.bridge_time, 'yyyy-MM-dd HH:mm:ss'))/3600 as d_tcr_call_time,
        count(*) d_tcr_call_cnt
from dw_hf_mobdb.dw_view_tms_call_record tcr
inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id=tcr.user_id
           and to_date(cdme.stats_date)='${analyse_date}' and cdme.class='CC'
           and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')
where tcr.call_type = 1 -- 呼叫学生
      and to_date(tcr.end_time)='${analyse_date}'
group by cdme.department_name


-- 工作手机通时通次
select  cdme.department_name,
        count(student_intention_id) as d_wp_call_cnt,
        sum(calling_seconds)/3600 as d_wp_call_time
from dw_hf_mobdb.dw_will_work_phone_call_recording wr
inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id=wr.user_id
           and to_date(cdme.stats_date)='${analyse_date}' and cdme.class='CC'
           and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')
where is_call_out = 'True'
      and to_date(wr.begin_time)='${analyse_date}'
group by cdme.department_name


-- 工作手机t-1数据
select  cdme.department_name,
        count(pr.contact_phone) as d_wp_call_cnt,
        sum(pr.duration)/3600 as d_wp_call_time
from dw_hf_mobdb.dw_phone_record pr
inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id=pr.user_id
           and to_date(cdme.stats_date)='${analyse_date}' and cdme.class='CC'
           and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')
where pr.out_type = 1
      and to_date(pr.start_time)='${analyse_date}'
group by cdme.department_name

