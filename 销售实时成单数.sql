select
t1.*,t2.抗标人数,t2.订单数指标,
(t2.订单数指标 - t1.当月总订单数)/(timestampdiff(day,curdate(),last_day(curdate()))+1) 每日需完成订单数
from(
        
        select a.class 类型, a.branch 分公司, a.center 中心, a.region 区, a.department 部, a.department_name 部门名称,
               count(case when date(a.max_pay_date) = curdate() then contract_id end) as 今日订单数,
               count(contract_id) as 当月总订单数,
               (1/DAYOFMONTH(LAST_DAY(curdate()))*DAYOFMONTH(curdate())) 月应完标率               
 
        from(
                        select  
                                cdme.class,
                                cdme.branch,
                                cdme.center,
                                cdme.region,
                                cdme.department,
                                cdme.grp,
                                cdme.department_name, 
                                tcp.contract_id,        
                                max(tcp.pay_date) as max_pay_date,
                                sum(tcp.sum/100) real_pay_sum, 
                                (tc.sum-666)*10 contract_amount

                        from view_tms_contract_payment tcp 
                        left join view_tms_contract tc on tc.contract_id = tcp.contract_id 
                        left join view_user_info ui on ui.user_id = tc.submit_user_id 
                        inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tc.submit_user_id
                                  and cdme.stats_date = curdate() and cdme.class = '销售'
                        where tcp.pay_status in (2,4) 
                              and tc.status <> 8  -- 剔除合同终止和废弃
                              and ui.account_type = 1  -- 剔除测试数据
                        group by tcp.contract_id
                        having real_pay_sum >= contract_amount
                               and max_pay_date >= date_format(curdate(),'%Y-%m-01')
                               ) as a
        group by 类型,分公司,中心,区,部,部门名称
        ) as t1


left join 
    (select     
        st.group_name 部门,
        st.number 抗标人数,
        st.order_number 订单数指标
    from bidata.sales_tab st
    where st.type = 'normal') t2 on t1.部门名称 = t2.部门
