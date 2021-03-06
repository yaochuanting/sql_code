select  now() as 更新时间,
        t.department_name as 部门, t.manager as 经理, t.number as 月初抗标人数,
        t.order_number as 订单数指标, t.tomonth_order as 当月总订单数, t.k_tomonth_order as 当月绩效订单数,
        (1/dayofmonth(last_day(curdate()))*dayofmonth(curdate())) as 月应完标率,
        t.tomonth_amount as 当月总订单额,
        t.apply_num as 当月申请设班单量, t.plan_num as 试听邀约量, t.trial_num as 试听出席量,
        t.new_deal_num as 新粒子成单量, t.new_keys as 新粒子数




from(        


        select  t3.class, t3.region, t3.department, t3.department_name, t2.manager,
                t2.order_number, t1.tomonth_order, t1.k_tomonth_order,
                t1.tomonth_amount, t2.number,
                t4.apply_num, t5.plan_num, t5.trial_num,
                t6.new_deal_num, t6.new_deal_amount, t7.new_keys


        from( 
              select cdme.class, cdme.center, cdme.region, cdme.department, cdme.department_name
              from bidata.charlie_dept_month_end cdme 
              where cdme.stats_date = curdate() and cdme.class = 'CC'
                    and cdme.department_name like 'CC%'
              group by cdme.department_name
              ) as t3

        left join (
                    select a.department_name,
                           count(a.contract_id) as tomonth_order,
                           sum(a.k_num) as k_tomonth_order,
                           sum(a.contract_amount) as tomonth_amount          
                 
                    from(
                                    select  
                                            cdme.department_name, 
                                            tcp.contract_id,
                                            case when tc.period >= 60 then 1 else 0.5 end k_num,
                                            max(tcp.pay_date) as max_pay_date,
                                            sum(tcp.sum/100) real_pay_sum, 
                                            (tc.sum-666)*10 contract_amount
                                    from hfjydb.view_tms_contract_payment tcp
                                    left join hfjydb.view_tms_contract tc on tc.contract_id = tcp.contract_id 
                                    left join hfjydb.view_user_info ui on ui.user_id = tc.submit_user_id 
                                    inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tc.submit_user_id
                                               and cdme.stats_date = curdate() and cdme.class = 'CC'    
                                    where tcp.pay_status in (2,4) 
                                          and tc.status <> 8  -- 剔除合同终止和废弃
                                          and ui.account_type = 1  -- 剔除测试数据
                                    group by tcp.contract_id
                                    having real_pay_sum >= contract_amount 
                                           and date(max_pay_date) >= date_format(curdate(),'%Y-%m-01')
                                           and date(max_pay_date) <= curdate()
                                            ) as a
                group by a.department_name
                ) as t1 on t1.department_name = t3.department_name


        left join 
            (select     
                st.group_name,
                st.number,
                st.order_number,
                st.manager
            from bidata.sales_tab st
            where st.type = 'normal'
        ) t2 on t3.department_name = t2.group_name


        left join(
                    select  count(distinct lpo.student_intention_id) as apply_num, cdme.department_name
                    from hfjydb.lesson_plan_order lpo
                    left join hfjydb.lesson_relation lr on lpo.order_id = lr.order_id
                    left join hfjydb.lesson_plan lp on lr.plan_id = lp.lesson_plan_id
                    left join hfjydb.view_student s on s.student_intention_id = lpo.student_intention_id
                    inner join bidata.charlie_dept_month_end cdme on cdme.user_id = lpo.apply_user_id 
                           and cdme.stats_date = curdate() and cdme.class = 'CC'
                    where lp.lesson_type = 2
                        and date(lpo.apply_time) >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
                        and date(lpo.apply_time) <= curdate()
                        and s.account_type = 1
                    group by department_name
                    ) as t4 on t4.department_name=t3.department_name


        left join(
                    select  aa.department_name,
                            count(distinct aa.student_intention_id) as plan_num,
                            count(distinct case when aa.is_trial=1 then aa.student_intention_id else null end) as trial_num
                    from(
                          select lpo.apply_user_id, lpo.student_intention_id, 
                          cdme.department_name,
                          case when lp.status in (3,5) and lp.solve_status <> 6 then 1 else 0 end as is_trial
                                    
                          from hfjydb.lesson_plan_order lpo
                          left join hfjydb.lesson_relation lr on lpo.order_id = lr.order_id
                          left join hfjydb.lesson_plan lp on lr.plan_id = lp.lesson_plan_id
                          left join hfjydb.view_student s on s.student_intention_id = lpo.student_intention_id
                          inner join bidata.charlie_dept_month_end cdme on cdme.user_id = lpo.apply_user_id 
                                 and cdme.stats_date = curdate() and cdme.class = 'CC'
                          where lp.lesson_type = 2
                               and date(lp.adjust_start_time) >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
                               and date(lp.adjust_start_time) <= curdate()
                               and s.account_type = 1
                               ) as aa
                    group by aa.department_name
                    ) as t5 on t5.department_name=t3.department_name

        left join (
                    select  bb.department_name,
                            count(bb.contract_id) as new_deal_num,
                            sum(bb.real_pay_sum) as new_deal_amount

                    from(   
                          select  max(tcp.pay_date) last_pay_date,
                                  tcp.contract_id,  
                                  s.student_intention_id,
                                  cdme.department_name,
                                  sum(tcp.sum)/100 real_pay_sum, 
                                  (tc.sum-666)*10 contract_amount
                          from hfjydb.view_tms_contract_payment tcp
                          left join hfjydb.view_tms_contract tc on tcp.contract_id  = tc.contract_id
                          left join hfjydb.view_student s on s.student_intention_id = tc.student_intention_id
                          left join hfjydb.view_user_info ui on ui.user_id = tc.submit_user_id
                          inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tcp.submit_user_id
                                 and cdme.stats_date = curdate() and cdme.class = 'CC'
                          where tcp.pay_status in (2,4)
                              and ui.account_type = 1
                              and s.submit_time >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
                              and tc.status <> 8
                          group by tcp.contract_id
                          having real_pay_sum >= contract_amount
                               and date(last_pay_date) >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
                               and date(last_pay_date) <= curdate()
                               ) as bb
                    group by bb.department_name
                    ) as t6 on t6.department_name=t3.department_name


        left join(
                    select  cc.department_name,
                            count(distinct cc.intention_id) as new_keys   
                    from(
                          select cdme.department_name, tpel.track_userid, tpel.intention_id, tpel.into_pool_date
                                from hfjydb.tms_pool_exchange_log tpel
                                left join hfjydb.view_student s on s.student_intention_id=tpel.intention_id
                                inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tpel.track_userid
                                         and cdme.stats_date = curdate() and cdme.class = 'CC'
                                where date(tpel.into_pool_date) >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
                                    and date(tpel.into_pool_date) <= curdate()
                                    and s.submit_time>=date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
                                union all
                                select cdme.department_name, tnn.user_id as track_userid, tnn.student_intention_id as intention_id, tnn.create_time as into_pool_date
                                from hfjydb.tms_new_name_get_log tnn
                                left join hfjydb.view_student s on s.student_intention_id=tnn.student_intention_id
                                inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tnn.user_id
                                         and cdme.stats_date = curdate() and cdme.class = 'CC'
                                where date(tnn.create_time) >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
                                    and date(tnn.create_time) <= curdate()
                                    and tnn.student_intention_id <> 0
                                    and s.submit_time>=date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
                                    ) as cc
                    group by cc.department_name
                    ) as t7 on t7.department_name=t3.department_name



        where not(t1.department_name is null and t2.group_name is null)

        ) as t

order by (t.tomonth_order/t.order_number) desc