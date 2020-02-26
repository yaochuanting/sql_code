select t1.region, sum(t3.number) as 抗标人数, sum(t2.total_deal_saler) as 有成单人数,
	   (sum(t3.number)-sum(t2.total_deal_saler))/sum(t3.number) as 0单占比,
       sum(t2.deal1)/sum(t3.number) as 1单占比, sum(t2.deal2)/sum(t3.number) as 2单占比, sum(t2.deal3)/sum(t3.number) as 3单占比, sum(t2.deal4)/sum(t3.number) as 4单占比,
       sum(t2.deal5)/sum(t3.number) as 5单占比, sum(t2.deal6)/sum(t3.number) as 6单占比, sum(t2.deal7)/sum(t3.number) as 7单占比, sum(t2.deal8)/sum(t3.number) as 8单占比,
       sum(t2.deal9)/sum(t3.number) as 9单占比, sum(t2.deal1011)/sum(t3.number) as `10—11单占比`, sum(t2.deal1213)/sum(t3.number) as `12-13单占比`, sum(t2.deal1415)/sum(t3.number) as `14-15单占比`,
       sum(t2.deal5)/sum(t3.number) as `15单以上占比`   


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
					count(distinct case when b.deal_num=1 then b.submit_user_id else null end) as deal1,
					count(distinct case when b.deal_num=2 then b.submit_user_id else null end) as deal2,
					count(distinct case when b.deal_num=3 then b.submit_user_id else null end) as deal3,
					count(distinct case when b.deal_num=4 then b.submit_user_id else null end) as deal4,
					count(distinct case when b.deal_num=5 then b.submit_user_id else null end) as deal5,
					count(distinct case when b.deal_num=6 then b.submit_user_id else null end) as deal6,
					count(distinct case when b.deal_num=7 then b.submit_user_id else null end) as deal7,
					count(distinct case when b.deal_num=8 then b.submit_user_id else null end) as deal8,
					count(distinct case when b.deal_num=9 then b.submit_user_id else null end) as deal9,
					count(distinct case when b.deal_num>=10 and b.deal_num<=11 then b.submit_user_id else null end) as deal1011,
					count(distinct case when b.deal_num>=12 and b.deal_num<=13 then b.submit_user_id else null end) as deal1213,
					count(distinct case when b.deal_num>=14 and b.deal_num<=15 then b.submit_user_id else null end) as deal1415,
					count(distinct case when b.deal_num>15 then b.submit_user_id else null end) as deal15

			from(
						select a.department_name, a.submit_user_id, count(a.contract_id) as deal_num
						from(			
									select  
								            cdme.department_name, 
								            tcp.contract_id, 
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