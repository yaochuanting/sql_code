select now() as 更新时间, t1.region as 大区, sum(t3.number) as 抗标人数, sum(t2.total_deal_saler) as 有成单人数,
	   sum(t3.number)-sum(t2.total_deal_saler) as 0单,
       sum(t2.deal1) as 1单, sum(t2.k_deal1) as 绩效1单, sum(t2.deal2) as 2单, sum(t2.k_deal2) as 绩效2单,
       sum(t2.deal3) as 3单, sum(t2.k_deal3) as 绩效3单, sum(t2.deal4) as 4单, sum(t2.k_deal4) as 绩效4单,
       sum(t2.deal5) as 5单, sum(t2.k_deal5) as 绩效5单, sum(t2.deal6) as 6单, sum(t2.k_deal6) as 绩效6单, 
       sum(t2.deal7) as 7单, sum(t2.k_deal7) as 绩效7单, sum(t2.deal8) as 8单, sum(t2.k_deal8) as 绩效8单,
       sum(t2.deal9) as 9单, sum(t2.k_deal9) as 绩效9单, sum(t2.deal1011) as `10-11单`, sum(t2.k_deal1011) as `绩效10-11单`, 
       sum(t2.deal1213) as `12-13单`, sum(t2.k_deal1213) as `绩效12-13单`, sum(t2.deal1415) as `14-15单`, sum(t2.k_deal1415) as `绩效14-15单`,
       sum(t2.deal15) as `15单+`, sum(t2.k_deal15) as `绩效15单+`  


from (
		select cdme.class, cdme.branch, cdme.center, 
                     case when cdme.department_name like '销售考核_组' then '考核部'
                          when cdme.department_name like '%待分配部%' then '待分配部'
                     else concat(cdme.city,cdme.region) end region,
                     case when cdme.department_name like '销售考核_组' then cdme.grp 
                          when cdme.department_name like '%待分配%' then '待分配部'
                     else cdme.department end department,
                     cdme.department_name
              from bidata.charlie_dept_month_end cdme 
              where cdme.stats_date = curdate() and cdme.class = '销售'
                    and cdme.department_name like '销售_区%'
                    or cdme.department_name like '销售考核%'
              group by cdme.department_name
              ) as t1

left join (
			select  b.department_name,
					count(b.submit_user_id) as total_deal_saler,
					count(distinct case when b.deal_num=1 then b.submit_user_id end) as deal1,
					count(distinct case when b.k_deal_num=1 then b.submit_user_id end) as k_deal1,
					count(distinct case when b.deal_num=2 then b.submit_user_id end) as deal2,
					count(distinct case when b.k_deal_num=2 then b.submit_user_id end) as k_deal2,
					count(distinct case when b.deal_num=3 then b.submit_user_id end) as deal3,
					count(distinct case when b.k_deal_num=3 then b.submit_user_id end) as k_deal3,
					count(distinct case when b.deal_num=4 then b.submit_user_id end) as deal4,
					count(distinct case when b.k_deal_num=4 then b.submit_user_id end) as k_deal4,
					count(distinct case when b.deal_num=5 then b.submit_user_id end) as deal5,
					count(distinct case when b.k_deal_num=5 then b.submit_user_id end) as k_deal5,
					count(distinct case when b.deal_num=6 then b.submit_user_id end) as deal6,
					count(distinct case when b.k_deal_num=6 then b.submit_user_id end) as k_deal6,
					count(distinct case when b.deal_num=7 then b.submit_user_id end) as deal7,
					count(distinct case when b.k_deal_num=7 then b.submit_user_id end) as k_deal7,
					count(distinct case when b.deal_num=8 then b.submit_user_id end) as deal8,
					count(distinct case when b.k_deal_num=8 then b.submit_user_id end) as k_deal8,
					count(distinct case when b.deal_num=9 then b.submit_user_id end) as deal9,
					count(distinct case when b.k_deal_num=9 then b.submit_user_id end) as k_deal9,
					count(distinct case when b.deal_num>=10 and b.deal_num<=11 then b.submit_user_id end) as deal1011,
					count(distinct case when b.k_deal_num>=10 and b.k_deal_num<=11 then b.submit_user_id end) as k_deal1011,
					count(distinct case when b.deal_num>=12 and b.deal_num<=13 then b.submit_user_id end) as deal1213,
					count(distinct case when b.k_deal_num>=12 and b.k_deal_num<=13 then b.submit_user_id end) as k_deal1213,
					count(distinct case when b.deal_num>=14 and b.deal_num<=15 then b.submit_user_id end) as deal1415,
					count(distinct case when b.k_deal_num>=14 and b.k_deal_num<=15 then b.submit_user_id end) as k_deal1415,
					count(distinct case when b.deal_num>15 then b.submit_user_id end) as deal15,
					count(distinct case when b.k_deal_num>15 then b.submit_user_id end) as k_deal15

			from(
						select a.department_name, a.submit_user_id, count(a.contract_id) as deal_num, sum(a.k_num) as k_deal_num
						from(			
									select  
								            cdme.department_name, 
								            tcp.contract_id, 
								            case when tc.period >= 60 then 1 else 0.5 end k_num,
								            tc.submit_user_id,       
								            max(tcp.pay_date) as max_pay_date,
								            sum(tcp.sum/100) real_pay_sum, 
								            (tc.sum-666)*10 contract_amount
								    from hfjydb.view_tms_contract_payment tcp
								    left join hfjydb.view_tms_contract tc on tc.contract_id = tcp.contract_id 
								    left join hfjydb.view_user_info ui on ui.user_id = tc.submit_user_id 
								    inner join bidata.charlie_dept_month_end cdme on cdme.user_id = tc.submit_user_id
								               and cdme.stats_date = curdate() and cdme.class = '销售'    
								    where tcp.pay_status in (2,4) 
								          and tc.status <> 8  -- 剔除合同终止和废弃
								          and ui.account_type = 1  -- 剔除测试数据
								    group by tcp.contract_id
								    having real_pay_sum >= contract_amount 
								           and date(max_pay_date) >= date_format(curdate(),'%Y-%m-01')
								           and date(max_pay_date) <= curdate()
								           ) as a
						group by a.department_name, a.submit_user_id
						) as b
			group by b.department_name
			) as t2 on t2.department_name=t1.department_name

left join (
			select     
                st.group_name,
                st.number,
                st.order_number,
                st.manager
            from bidata.sales_tab st
            where st.type = 'normal'
                  and st.group_name like '%销售%'
                  ) as t3 on t3.group_name=t1.department_name
where not(t2.department_name is null and t3.group_name is null)
group by t1.region 
order by (sum(t3.number)-sum(t2.total_deal_saler))/sum(t3.number)