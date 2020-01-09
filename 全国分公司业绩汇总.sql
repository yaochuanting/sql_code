select
a.*,b.抗标人数,b.业绩指标,
(b.业绩指标 - a.当月合计)/(timestampdiff(day,curdate(),last_day(curdate()))+1) 每日需完成业绩指标
from(
        select  
                cdme.class 类型,
                cdme.branch 分公司,
                cdme.center 中心,
                case when cdme.department_name like "%考核%" then "考核" 
                     when cdme.department_name like "%学管%" then "学管" else cdme.region end 区,       
                cdme.department 部门,
                cdme.grp 组,
                cdme.department_name 部门名称,       
                sum(case when pay_date >= date_format(curdate(),'%Y-%m-01') and pay_date < curdate() then tcp.sum/100 else 0 end) 当月至昨日, 
                sum(case when date(pay_date) = curdate() then tcp.sum/100 else 0 end) 今日业绩, 
                (1/DAYOFMONTH(LAST_DAY(curdate()))*DAYOFMONTH(curdate())) 月应完标率, 
                sum(tcp.sum/100) 当月合计 
        from view_tms_contract_payment tcp 
        left join view_tms_contract tc on tc.contract_id = tcp.contract_id 
        left join view_user_info ui on ui.user_id = tc.submit_user_id 
        inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tc.submit_user_id
                  and cdme.stats_date = curdate() and cdme.class = '销售'
        where date(pay_date) between date_format(curdate(),'%Y-%m-01') and curdate() 
              and tcp.pay_status in (2,4) 
              and tc.status <> 8  -- 剔除合同终止和废弃
              and ui.account_type = 1  -- 剔除测试数据
        group by 类型, 区, 部门, 部门名称) as a

left join 
    (select     
        st.group_name 部门,
        st.number 抗标人数,
        st.achievement 业绩指标
    from bidata.sales_tab st
    where st.type = 'normal') b on  a.部门名称 = b.部门
