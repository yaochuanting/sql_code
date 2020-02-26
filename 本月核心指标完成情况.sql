select  date_sub('2019-12-01',interval 1 day) as stats_date,
        t1.department_name 部门, 
        t1.region 区,
        t1.department 部,
        t2.number 月初抗标人数,t2.order_number 订单数指标, t3.tomonth_order 当月完成订单数, t3.lastmonth_order 上月同期订单数,
        t3.tomonth_amount 当月完成订单额, t3.lastmonth_amount 上月同期订单额, t3.total_deal_saler 当月出单销售人数, t3.tomonth_rec_order 当月转介绍订单数, t4.new_rec_keys 当月转介绍线索量

from(

      select cdme.class, cdme.branch, cdme.center, 
             case when cdme.department_name like '销售考核_组' then '考核部'
                  when cdme.department_name like '%待分配部%' then '待分配部'
             else cdme.region end region,
             case when cdme.department_name like '销售考核_组' then cdme.grp 
                  when cdme.department_name like '%待分配%' then '待分配部'
             else cdme.department end department,
             cdme.department_name
      from bidata.charlie_dept_month_end cdme 
      where cdme.stats_date = curdate() and cdme.class = '销售'
            and cdme.department_name like '销售_区_部'
            or cdme.department_name like '销售考核_组'
      group by cdme.department_name
      ) as t1

left join (
            select  st.group_name,
                    st.number,
                    st.order_number,
                    st.manager
            from bidata.sales_tab st
            where st.type = 'normal' and st.group_name like '%销售%'
            ) as t2 on t2.group_name=t1.department_name


left join (
            select a.department_name,
                   count(case when date(a.max_pay_date)>=date_sub(date_format(date_sub('2019-12-01',interval 1 day),'%Y-%m-01'),interval 1 month)
                                   and date(a.max_pay_date)<=date_sub(date_sub('2019-12-01',interval 1 day),interval 1 month)
                              then a.contract_id else null end) as lastmonth_order,
                   count(case when date(a.max_pay_date)>=date_format(date_sub('2019-12-01',interval 1 day),'%Y-%m-01')
                                   and date(a.max_pay_date)<=date_sub('2019-12-01',interval 1 day)
                              then a.contract_id else null end) as tomonth_order,
                   count(case when date(a.max_pay_date)>=date_format(date_sub('2019-12-01',interval 1 day),'%Y-%m-01')
                                   and date(a.max_pay_date)<=date_sub('2019-12-01',interval 1 day) 
                                   and (a.coil_in in (13,22) or a.know_origin in (56,71,22,24,25,41))
                              then a.contract_id else null end) as tomonth_rec_order,
                   sum(case when date(a.max_pay_date)>=date_sub(date_format(date_sub('2019-12-01',interval 1 day),'%Y-%m-01'),interval 1 month)
                                 and date(a.max_pay_date)<=date_sub(date_sub('2019-12-01',interval 1 day),interval 1 month)
                            then a.contract_amount else 0 end) as lastmonth_amount ,
                   sum(case when date(a.max_pay_date)>=date_format(date_sub('2019-12-01',interval 1 day),'%Y-%m-01')
                                 and date(a.max_pay_date)<=date_sub('2019-12-01',interval 1 day)
                            then a.contract_amount else 0 end) as tomonth_amount,
                   count(distinct case when date(a.max_pay_date)>=date_format(date_sub('2019-12-01',interval 1 day),'%Y-%m-01')
                                            and date(a.max_pay_date)<=date_sub('2019-12-01',interval 1 day)
                                       then a.submit_user_id end) as total_deal_saler

         
            from(
                            select  
                                    cdme.department_name, 
                                    tcp.contract_id,
                                    tc.submit_user_id,
                                    s.coil_in,
                                    s.know_origin,        
                                    max(tcp.pay_date) as max_pay_date,
                                    sum(tcp.sum/100) real_pay_sum, 
                                    (tc.sum-666)*10 contract_amount
                            from hfjydb.view_tms_contract_payment tcp
                            left join hfjydb.view_tms_contract tc on tc.contract_id = tcp.contract_id 
                            left join hfjydb.view_user_info ui on ui.user_id = tc.submit_user_id
                            left join hfjydb.view_student s on s.student_intention_id = tc.student_intention_id
                            inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tc.submit_user_id
                                       and cdme.stats_date = curdate() and cdme.class = '销售'    
                            where tcp.pay_status in (2,4) 
                                  and tc.status <> 8  -- 剔除合同终止和废弃
                                  and ui.account_type = 1  -- 剔除测试数据
                            group by tcp.contract_id
                            having real_pay_sum >= contract_amount 
                                   and date(max_pay_date) >= date_sub(date_format(date_sub('2019-12-01',interval 1 day),'%Y-%m-01'),interval 1 month)
                                   and date(max_pay_date) <= date_sub('2019-12-01',interval 1 day)
                                    ) as a
            group by a.department_name
            ) as t3 on t3.department_name=t1.department_name


left join (
              select 
                      cdme.department_name,
                      count(distinct case when s.submit_time >= date_format(date_sub('2019-12-01',interval 1 day),'%Y-%m-01')
                                               and (s.coil_in in (13,22) or s.know_origin in (56,71,22,24,25,41))
                                          then intention_id end) new_rec_keys  -- 获取新转介绍新线索量                     
              from
                   (
                       select tpel.track_userid, tpel.intention_id, tpel.into_pool_date, ui.name distri_user
                       from hfjydb.tms_pool_exchange_log tpel
                       inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tpel.track_userid
                                and cdme.stats_date = curdate() and cdme.class = '销售'
                       left join hfjydb.view_user_info ui on ui.user_id = tpel.create_userid
                       where date(tpel.into_pool_date) >= date_format(date_sub('2019-12-01',interval 1 day),'%Y-%m-01')
                           and date(tpel.into_pool_date) <= date_sub('2019-12-01',interval 1 day)
                       union
                       select tnn.user_id as track_userid, tnn.student_intention_id as intention_id, tnn.create_time as into_pool_date, 'OC分配账号' distri_user
                       from hfjydb.tms_new_name_get_log tnn
                       inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tnn.user_id
                                and cdme.stats_date = curdate() and cdme.class = '销售'
                       where date(tnn.create_time) >= date_format(date_sub('2019-12-01',interval 1 day),'%Y-%m-01')
                             and date(tnn.create_time) <= date_sub('2019-12-01',interval 1 day)
                             and student_intention_id <> 0
                             ) as a              

               left join hfjydb.view_student s on s.student_intention_id = a.intention_id
               left join bidata.charlie_dept_month_end cdme on cdme.user_id = a.track_userid
                         and cdme.stats_date = curdate() and cdme.class='销售'

               group by department_name
               ) as t4 on t4.department_name=t1.department_name

where not(t2.group_name is null and t3.department_name is null)