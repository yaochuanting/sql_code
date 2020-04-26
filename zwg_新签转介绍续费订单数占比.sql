select  t2.cc_new_sign_order  -- CC-新签订单数指标
        ,t2.cr_new_sign_order  -- CR-转介绍订单数指标
        ,t2.cc_new_sign_amount  -- CC-新签订单额指标
        ,t2.cr_new_sign_amount  -- CR-转介绍订单额指标
        ,t2.cr_xf_amount  -- CR-续费订单额指标
        ,(1/dayofmonth(last_day('${analyse_date}'))*dayofmonth('${analyse_date}')) as time_shred  -- 时间进度
        ,t1.cc_total_deal_num  -- CC-总订单数
        ,t1.cc_total_deal_amount  -- CC-总订单额
        ,t1.cc_new_deal_num  -- CC-市场新粒子订单数
        ,t1.cc_new_deal_amount  -- CC-市场新粒子订单额
        ,t1.cc_oc_deal_num  -- CC-市场oc粒子订单数
        ,t1.cc_oc_deal_amount  -- CC-市场oc粒子订单额
        ,t1.cc_rec_deal_num  -- CC-转介绍订单数
        ,t1.cc_rec_deal_amount  -- CC-转介绍订单额
        ,t1.cc_new_rec_deal_num  -- CC-新转介绍订单数
        ,t1.cr_total_deal_num  -- CR-总订单数
        ,t1.cr_total_deal_amount  -- CR-总订单额
        ,t1.cr_rec_deal_num  -- CR-转介绍订单数
        ,t1.cr_rec_deal_amount  -- CR-转介绍订单额
        ,t1.cr_xf_deal_num  -- CR-续费订单数
        ,t1.cr_xf_deal_amount  -- CR-续费订单额



        

from(

        select  '${analyse_date}' as stats_date
                ,count(case when a.class='CC' then a.contract_id end) as cc_total_deal_num  -- `CC-总订单数`
                ,sum(case when a.class='CC' then a.real_pay_sum end) as cc_total_deal_amount  -- `CC-总订单额`
                ,count(case when a.class='CC' and a.is_new=1 and a.is_rec=0 then a.contract_id end) as cc_new_deal_num  -- `CC-市场新粒子订单数`
                ,sum(case when a.class='CC' and a.is_new=1 and a.is_rec=0 then a.real_pay_sum end) as cc_new_deal_amount  -- `CC-市场新粒子订单额`
                ,count(case when a.class='CC' and a.is_new=0 and a.is_rec=0 then a.contract_id end) as cc_oc_deal_num  -- `CC-市场oc粒子订单数`
                ,sum(case when a.class='CC' and a.is_new=0 and a.is_rec=0 then a.real_pay_sum end) as cc_oc_deal_amount  -- `CC-市场oc粒子订单额`
                ,count(case when a.class='CC' and a.is_rec=1 then a.contract_id end) as cc_rec_deal_num  -- `CC-转介绍订单数`
                ,sum(case when a.class='CC' and a.is_rec=1 then a.real_pay_sum end) as cc_rec_deal_amount  -- `CC-转介绍订单额`
                ,count(case when a.class='CC' and a.is_rec=1 and a.is_new=1 then a.contract_id end) as cc_new_rec_deal_num  -- `CC-新转介绍订单数`
                ,count(case when a.class='CR' then a.contract_id end) as cr_total_deal_num  -- `CR-总订单数`
                ,sum(case when a.class='CR' then a.real_pay_sum end) as cr_total_deal_amount  -- `CR-总订单额`
                ,count(case when a.class='CR' and a.new_sign=1 then a.contract_id end) as cr_rec_deal_num  -- `CR-转介绍订单数`
                ,sum(case when a.class='CR' and a.new_sign=1 then a.real_pay_sum end) as cr_rec_deal_amount  -- `CR-转介绍订单额`
                ,count(case when a.class='CR' and a.new_sign=0 then a.contract_id end) as cr_xf_deal_num  -- `CR-续费订单数`
                ,sum(case when a.class='CR' and a.new_sign=0 then a.real_pay_sum end) as cr_xf_deal_amount  -- `CR-续费订单额`

        from(

                select  
                        max(tcp.pay_date) last_pay_date,
                        tc.new_sign,
                        tcp.contract_id,  
                        s.student_intention_id,
                        max(case when s.create_time >= trunc('${analyse_date}','MM') then 1 else 0 end) is_new,
                        max(case when s.coil_in in (13,22) or s.know_origin in (56,71,22,24,25,41) then 1 else 0 end) is_rec,
                        cdme.department_name,
                        cdme.class,
                        sum(tcp.`sum`)/100 real_pay_sum, 
                        avg((tc.`sum`-666)*10) contract_amount
                from dw_hf_mobdb.dw_view_tms_contract_payment tcp
                left join dw_hf_mobdb.dw_view_tms_contract tc on tcp.contract_id  = tc.contract_id
                left join dw_hf_mobdb.dw_view_student s on s.student_intention_id = tc.student_intention_id
                left join dw_hf_mobdb.dw_view_user_info ui on ui.user_id = tc.submit_user_id
                inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.user_id = tcp.submit_user_id
                        and cdme.stats_date = current_date()
                        and cdme.`date` >= trunc('${analyse_date}','MM')
                where tcp.pay_status in (2,4)
                    and ui.account_type = 1
                    and tc.status <> 8
                group by tcp.contract_id, tc.new_sign, s.student_intention_id, cdme.department_name, cdme.class
                having round(sum(tcp.`sum`)/100) >= round(avg((tc.`sum`-666)*10))
                    and date(last_pay_date) >= trunc('${analyse_date}','MM')
                    and date(last_pay_date) <= '${analyse_date}'
                    ) as a
                    ) as t1

left join (
            select '${analyse_date}' as stats_date
                    ,sum(case when type='新签' and class='CC' then order_num end) cc_new_sign_order
                    ,sum(case when type='新签' and class='CR' then order_num end) cr_new_sign_order
                    ,sum(case when type='新签' and class='CC' then order_amount end) cc_new_sign_amount
                    ,sum(case when type='新签' and class='CR' then order_amount end) cr_new_sign_amount
                    ,sum(case when type='续费' and class='CR' then order_amount end) cr_xf_amount
            from hf_mobdb.load_target 
            where year = year('${analyse_date}') and month = month('${analyse_date}')

                    ) as t2 on t2.stats_date = t1.stats_date
