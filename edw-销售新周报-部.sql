-- 部维度

select  date_sub(curdate(),interval 1 day) as stats_date,
        t1.department_name 部门, 
        t2.number 月初抗标人数,
        t2.order_number 订单数指标,
        t3.tomonth_order 当月完成订单数, 
        t3.lastmonth_order 上月同期订单数,
        t3.tomonth_k_order 当月绩效订单数, 
        t3.lastmonth_k_order 上月同期绩效订单数, 
        t3.tomonth_amount 当月完成订单额, 
        t3.lastmonth_amount 上月同期订单额, 
        t3.total_deal_saler 当月出单销售人数, 
        t3.tomonth_rec_order 当月转介绍订单数, t4.new_rec_keys 当月转介绍线索量


-- 销售架构
from(

      select cdme.department_name
      from dt_mobdb.dt_charlie_dept_month_end cdme 
      where cdme.stats_date='${analyse_date}' and cdme.class='CC'
            and cdme.department_name like 'CC%'
            and cdme.`date`>=trunc('${analyse_date}','MM')
      group by cdme.department_name
      ) as t1



-- 销售抗标
left join (
            select  st.group_name,
                    st.number,
                    st.order_number,
                    st.manager
            from hf_mobdb.sales_tab st
            where st.type = 'normal' and st.group_name like 'CC%'
            ) as t2 on t2.group_name=t1.department_name


-- 销售订单数
left join (
            select a.department_name,
                   sum(case when a.time_type=1 then a.k_order end) as lastmonth_k_order,
                   count(case when a.time_type=2 then a.contract_id end) as tomonth_order,
                   count(case when a.time_type=1 then a.contract_id end) as lastmonth_order,
                   sum(case when a.time_type=2 then a.k_order end) as tomonth_k_order,
                   count(case when a.time_type=2 and a.is_rec=1 then a.contract_id end) as tomonth_rec_order,
                   sum(case when a.time_type=1 then a.contract_amount end) as lastmonth_amount ,
                   sum(case when a.time_type=2 then a.contract_amount end) as tomonth_amount,
                   count(distinct case when a.time_type=2 then a.submit_user_id end) as total_deal_saler

         
            from(
                            select  
                                    cdme.department_name, 
                                    tcp.contract_id,
                                    tc.submit_user_id,
                                    case when to_date(max(tcp.pay_date))>=trunc(date_sub(trunc('${analyse_date}','MM'),1),'MM') and to_date(max(tcp.pay_date))<=date_sub(trunc('${analyse_date}','MM'),1) then 1
                                         when to_date(max(tcp.pay_date))>=trunc('${analyse_date}','MM') and to_date(max(tcp.pay_date))<='${analyse_date}' then 2
                                    else 3 end time_type,
                                    avg(case when s.coil_in in (13,22) or s.know_origin in (56,71,22,24,25,41) then 1 else 0 end) is_rec,
                                    avg(case when tc.period>=60 then 1 else 0.5 end) k_order,       
                                    max(tcp.pay_date) as max_pay_date,
                                    sum(tcp.sum/100) real_pay_sum, 
                                    avg((tc.sum-666)*10) contract_amount
                            from dw_hf_mobdb.dw_view_tms_contract_payment tcp
                            left join dw_hf_mobdb.dw_view_tms_contract tc on tc.contract_id = tcp.contract_id 
                            left join dw_hf_mobdb.dw_view_user_info ui on ui.user_id = tc.submit_user_id
                            left join dw_hf_mobdb.dw_view_student s on s.student_intention_id = tc.student_intention_id
                            inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id = tc.submit_user_id
                                       and to_date(cdme.stats_date)='${analyse_date}' and cdme.class = 'CC'    
                                       and to_date(cdme.`date`)>=trunc('${analyse_date}','MM')
                            where tcp.pay_status in (2,4) 
                                  and tc.status<>8  -- 剔除合同终止和废弃
                                  and ui.account_type=1  -- 剔除测试数据
                            group by cdme.department_name, tcp.contract_id, tc.submit_user_id
                            having round(sum(tcp.sum/100),0)>= round(avg((tc.sum-666)*10),0)
                                   and to_date(max_pay_date)>=trunc(date_sub(trunc('${analyse_date}','MM'),1),'MM')
                                   and to_date(max_pay_date)<='${analyse_date}'
                                    ) as a
            group by a.department_name
            ) as t3 on t3.department_name=t1.department_name

-- 获取的转介绍新线索量
left join (
              select 
                      cdme.department_name,
                      count(distinct case when s.submit_time>=trunc('${analyse_date}','MM') and (s.coil_in in (13,22) or s.know_origin in (56,71,22,24,25,41)) then intention_id end) new_rec_keys  -- 获取新转介绍新线索量                     
              from
                   (
                       select tpel.track_userid, tpel.intention_id, tpel.into_pool_date
                       from dw_hf_mobdb.dw_tms_pool_exchange_log tpel
                       inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id = tpel.track_userid
                                and cdme.stats_date = '${analyse_date}' and cdme.class = 'CC'
                                and cdme.`date`>=trunc('${analyse_date}','MM')
                       left join dw_hf_mobdb.dw_view_user_info ui on ui.user_id = tpel.create_userid
                       where to_date(tpel.into_pool_date)>=trunc('${analyse_date}','MM')
                           and to_date(tpel.into_pool_date)<='${analyse_date}'
                       union
                       select tnn.user_id as track_userid, tnn.student_intention_id as intention_id, tnn.create_time as into_pool_date
                       from dw_hf_mobdb.dw_tms_new_name_get_log tnn
                       inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id = tnn.user_id
                                and cdme.stats_date='${analyse_date}' and cdme.class = 'CC'
                       where to_date(tnn.create_time)>=trunc('${analyse_date}','MM')
                             and to_date(tnn.create_time)<='${analyse_date}'
                             and student_intention_id<>0
                             ) as a              

               left join dw_hf_mobdb.dw_view_student s on s.student_intention_id = a.intention_id
               left join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id = a.track_userid
                         and cdme.stats_date='${analyse_date}' and cdme.class='CC'
                         and cdme.`date`>='${analyse_date}'

               group by cdme.department_name
               ) as t4 on t4.department_name=t1.department_name

where not(t2.group_name is null and t3.department_name is null)