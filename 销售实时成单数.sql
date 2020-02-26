select  t.*,
        @curRank := @curRank + 1 AS rank

from(        


        select  t3.class as 类型, t3.region as 区, t3.department as 部, t3.department_name as 部门名称, t2.manager as 经理,
                t2.order_number as 订单数指标, t1.lastmonth_order as 上月同期订单数,
                t1.tomonth_order as 当月总订单数, t1.k_tomonth_order as 当月绩效订单数,
                t1.tomonth_amount as 当月总订单额,
                t1.today_order as 今日订单数, t1.k_today_order as 今日绩效订单数,
                t1.achieve_rate as 月应完标率, t2.number as 抗标人数

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
                    and cdme.department_name like '销售_区%'
                    or cdme.department_name like '销售考核%'
              group by cdme.department_name
              ) as t3

        left join (
                    select a.department_name,
                           count(case when a.is_tomonth=0 then a.contract_id end) as lastmonth_order,
                           count(case when date(max_pay_date)=curdate() then a.contract_id end) as today_order,
                           sum(case when date(max_pay_date)=curdate() then a.k_order_num end) k_today_order,
                           count(case when a.is_tomonth=1 then a.contract_id end) as tomonth_order,
                           sum(case when a.is_tomonth=1 then a.k_order_num end) as k_tomonth_order,
                           sum(case when a.is_tomonth=1 then a.contract_amount end) as tomonth_amount,
                           (1/dayofmonth(last_day(curdate()))*dayofmonth(curdate())) achieve_rate             
                 
                    from(
                                    select  
                                            cdme.department_name, 
                                            tcp.contract_id,
                                            case when tc.period >= 60 then 1 else 0.5 end as k_order_num, 
                                            case when date(max(tcp.pay_date)) <= date_sub(curdate(),interval 1 month) then 0
                                                 when date(max(tcp.pay_date)) >= date_format(curdate(),'%Y-%m-01') then 1
                                            else null end as is_tomonth,
                                            max(tcp.pay_date) as max_pay_date,
                                            sum(tcp.sum/100) real_pay_sum, 
                                            (tc.sum-666)*10 contract_amount
                                    from hfjydb.view_tms_contract_payment tcp
                                    left join hfjydb.view_tms_contract tc on tc.contract_id = tcp.contract_id 
                                    left join hfjydb.view_user_info ui on ui.user_id = tc.submit_user_id 
                                    inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tc.submit_user_id
                                               and cdme.stats_date = curdate() and cdme.class = '销售'
                                               and cdme.date >= date_format(curdate(),'%Y-%m-01')  
                                    where tcp.pay_status in (2,4) 
                                          and tc.status <> 8  -- 剔除合同终止和废弃
                                          and ui.account_type = 1  -- 剔除测试数据
                                    group by tcp.contract_id
                                    having real_pay_sum >= contract_amount 
                                           and date(max_pay_date) >= date_sub(date_format(curdate(),'%Y-%m-01'),interval 1 month)
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

        where not(t1.department_name is null and t2.group_name is null)

        ) as t,  (select @curRank := 0) p

order by (t.当月绩效订单数/t.订单数指标) desc