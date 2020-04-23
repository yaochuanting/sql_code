select to_date(t1.min_into_pool_date) 首次获取时间,
       round(t1.max_score,1) 评分等级,
  		 count(t1.intention_id) as 获取量,
  		 count(case when t2.min_apply_time is not null then t1.intention_id end) as 邀约数,
  		 count(case when t3.min_adjust_start_time is not null then t1.intention_id end) as 出席数,
  		 count(case when t4.min_pay_date is not null then t1.intention_id end) as 成单数



from(
    		select tpel.intention_id, ao.max_score, min(tpel.into_pool_date) as min_into_pool_date, s.create_time
        from dw_hf_mobdb.dw_tms_pool_exchange_log tpel
        left join dw_hf_mobdb.dw_view_student s on s.student_intention_id = tpel.intention_id
        left join dw_hf_mobdb.dw_alb_ocleads_score_s1_hist ao on ao.student_intention_id = tpel.intention_id
        inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id = tpel.track_userid
                   and cdme.stats_date = current_date() and cdme.class = 'CC'
        where to_date(tpel.into_pool_date) >= date_sub(current_date(),60)
        group by tpel.intention_id, ao.max_score, s.create_time
        having to_date(s.create_time) < trunc(min(tpel.into_pool_date),'MM')
    		) as t1

left join (

                select
                                lpo.student_intention_id,
                                min(lpo.apply_time) as min_apply_time
                                                        
                from dw_hf_mobdb.dw_lesson_plan_order lpo
                left join dw_hf_mobdb.dw_lesson_relation lr on lpo.order_id = lr.order_id
                left join dw_hf_mobdb.dw_lesson_plan lp on lr.plan_id = lp.lesson_plan_id
                inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id = lpo.apply_user_id 
                           and cdme.stats_date = current_date() and cdme.class = 'CC'
                where lpo.apply_time >= date_sub(current_date(),60)
                      and lp.lesson_type = 2
                      and lp.solve_status <> 6
                group by lpo.student_intention_id
                ) as t2 on t2.student_intention_id = t1.intention_id
                           and t2.min_apply_time >= t1.min_into_pool_date

left join (

                select
                                lpo.student_intention_id,
                                min(lp.adjust_start_time) as min_adjust_start_time		  			  
                from dw_hf_mobdb.dw_lesson_plan_order lpo
                left join dw_hf_mobdb.dw_lesson_relation lr on lpo.order_id = lr.order_id
                left join dw_hf_mobdb.dw_lesson_plan lp on lr.plan_id = lp.lesson_plan_id
                inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id = lpo.apply_user_id 
                           and cdme.stats_date = current_date() and cdme.class = 'CC'
                where lp.status in (3,5) and lp.solve_status <> 6
                      and lp.lesson_type = 2
                      and to_date(lp.adjust_start_time) >= date_sub(current_date(),60)
                group by lpo.student_intention_id
                ) as t3 on t3.student_intention_id = t1.intention_id and t3.min_adjust_start_time >= t1.min_into_pool_date


left join (

             select
                    min(tcp.pay_date) min_pay_date,
                    max(tcp.pay_date) last_pay_date,
                    tcp.contract_id,  
                    s.student_intention_id,
                    sum(tcp.sum)/100 real_pay_sum, 
                    avg((tc.sum-666)*10) contract_amount
            from dw_hf_mobdb.dw_view_tms_contract_payment tcp
            left join dw_hf_mobdb.dw_view_tms_contract tc on tcp.contract_id  = tc.contract_id
            left join dw_hf_mobdb.dw_view_student s on s.student_intention_id = tc.student_intention_id
            left join dw_hf_mobdb.dw_view_user_info ui on ui.user_id = tc.submit_user_id
            inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id = tcp.submit_user_id
                       and cdme.stats_date = current_date() and cdme.class = 'CC'
            where tcp.pay_status in (2,4)
                  and ui.account_type = 1
            group by tcp.contract_id, s.student_intention_id
            having round(sum(tcp.sum/100),0) >= round(avg((tc.sum-666)*10),0)
                   and min(tcp.pay_date) >= date_sub(current_date(),60)
                   ) as t4 on t4.student_intention_id = t1.intention_id and t4.min_pay_date >= t1.min_into_pool_date


group by 首次获取时间, 评分等级
order by 评分等级