select 	case when t1.max_score >= 0.9 then '>=0.9'
             when t1.max_score >= 0.8 then '[0.8,0.9)'
             when t1.max_score >= 0.7 then '[0.7,0.8)'
             when t1.max_score >= 0.6 then '[0.6,0.7)'
             when t1.max_score >= 0.5 then '[0.5,0.6)'
             when t1.max_score >= 0.4 then '[0.4,0.5)'
             when t1.max_score >= 0.3 then '[0.3,0.4)'
             when t1.max_score >= 0.2 then '[0.2,0.3)'
             when t1.max_score >= 0.1 then '[0.1,0.2)'
          else '[0,0.1)' end level,
  		count(t1.intention_id) as 获取量,
  		count(case when t2.min_apply_time is not null then t1.intention_id end) as 邀约数,
  		count(case when t3.min_adjust_start_time is not null then t1.intention_id end) as 出席数,
  		count(case when t4.min_pay_date is not null then t1.intention_id end) as 成单数



from(
		select tpel.intention_id, ao.max_score, min(tpel.into_pool_date) as min_into_pool_date, s.submit_time
		from hfjydb.tms_pool_exchange_log tpel
		left join hfjydb.view_student s on s.student_intention_id = tpel.intention_id
		left join dt_mobdb.alb_ocleads_score_s1_hist ao on ao.student_intention_id = tpel.intention_id
		inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tpel.track_userid
		           and cdme.stats_date = curdate() and cdme.class = '销售'
		where date(tpel.into_pool_date) >= '2020-02-01' and date(tpel.into_pool_date) <= '2020-02-13'
		group by tpel.intention_id
		having s.submit_time < date_format(min_into_pool_date,'%Y-%m-01')
		) as t1

left join (

                select
                                lpo.student_intention_id,
                                min(lpo.apply_time) as min_apply_time
                                                        
                from hfjydb.lesson_plan_order lpo
                left join hfjydb.lesson_relation lr on lpo.order_id = lr.order_id
                left join hfjydb.lesson_plan lp on lr.plan_id = lp.lesson_plan_id
                inner join bidata.charlie_dept_month_end cdme on cdme.user_id = lpo.apply_user_id 
                           and cdme.stats_date = curdate() and cdme.class = '销售'
                where lpo.apply_time >= '2020-02-01'
                      and lp.lesson_type = 2
                      and lp.solve_status <> 6
                group by lpo.student_intention_id
                ) as t2 on t2.student_intention_id = t1.intention_id
                           and t2.min_apply_time >= t1.min_into_pool_date

left join (

                select
                                lpo.student_intention_id,
                                min(lp.adjust_start_time) as min_adjust_start_time		  			  
                from hfjydb.lesson_plan_order lpo
                left join hfjydb.lesson_relation lr on lpo.order_id = lr.order_id
                left join hfjydb.lesson_plan lp on lr.plan_id = lp.lesson_plan_id
                inner join bidata.charlie_dept_month_end cdme on cdme.user_id = lpo.apply_user_id 
                           and cdme.stats_date = curdate() and cdme.class = '销售'
                where lp.status in (3,5) and lp.solve_status <> 6
                      and lp.lesson_type = 2
                      and date(lp.adjust_start_time) >= '2020-02-01'
                group by lpo.student_intention_id
                ) as t3 on t3.student_intention_id = t1.intention_id
                           and t3.min_adjust_start_time >= t1.min_into_pool_date


left join (

             select
                    min(tcp.pay_date) min_pay_date,
                    max(tcp.pay_date) last_pay_date,
                    tcp.contract_id,  
                    s.student_intention_id,
                    sum(tcp.sum)/100 real_pay_sum, 
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
                   and min_pay_date >= '2020-02-01'
                   ) as t4 on t4.student_intention_id = t1.intention_id
                              and t4.min_pay_date >= t1.min_into_pool_date


group by level
order by level desc