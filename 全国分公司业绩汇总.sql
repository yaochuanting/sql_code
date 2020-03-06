####updated by: 姚传婷
####update time: 2019-10-28
####架构取数逻辑修改

####updated by: 吴小艳
####update time: 2019-12-04
####架构取数逻辑修改

####updated by: 姚传婷
####update time: 2020-3-5
####架构取数逻辑修改,统一使用cdme架构表


select a.class 维度, a.center 大区, a.region 区, a.department 部门, a.department_name 部门名称,
       b.number 抗标人数, b.achievement 业绩指标,a.mtd_performance 当月至昨日业绩,
       a.today_performance 今日业绩, a.tomonth_performance 当月合计,a.rate 月应完标率,
       (b.achievement - a.tomonth_performance)/(timestampdiff(day,curdate(),last_day(curdate()))+1) 每日需完成业绩指标

from (
        select 
                cdme.class, cdme.center, cdme.region, cdme.department, cdme.department_name,
                sum(case when date(pay_date)<=date_sub(curdate(),interval 1 day) then tcp.sum/100 else 0 end) mtd_performance,
                sum(case when date(pay_date)=curdate() then tcp.sum/100 else 0 end) today_performance,    
                sum(tcp.sum/100) tomonth_performance,
                (1/dayofmonth(last_day(curdate()))*dayofmonth(curdate())) rate

        from view_tms_contract_payment tcp 
        left join view_tms_contract tc on tc.contract_id=tcp.contract_id
        left join bidata.charlie_dept_month_end cdme on cdme.user_id=tc.submit_user_id
                  and cdme.stats_date=curdate() and cdme.date>=date_format(curdate(),'%Y-%m-01') 
        left join view_user_info ui on ui.user_id = tc.submit_user_id 
        where date(pay_date)>=date_format(curdate(),'%Y-%m-01') and date(pay_date)<=curdate()
              and tc.status<>8  -- 剔除合同废弃
              and tcp.pay_status in (2,4) 
              and ui.account_type = 1
        group by cdme.class, cdme.center, cdme.region, cdme.department, cdme.department_name
        ) as a 


left join (
            select st.group_name, sum(st.number) as number, sum(st.achievement) as achievement
            from bidata.sales_tab st
            where st.group_name like 'CC%'
            group by st.group_name
            ) as b on a.department_name= b.group_name

group by a.department_name