select x.stats_date 统计日期,
       x.region_name 区,
	   y.total_performance 总流水业绩,
	   y.new_performance 新线索流水业绩,
	   y.rate 月应完标率,
	   y.all_oc_performance 大盘oc线索流水业绩,
	   y.new_rec_performance 转介绍新线索流水业绩,
	   z.achievement 业绩指标,
	   z.staffs 月初抗标人数,
	   xx.total_performance_splm 上月同期流水业绩
	   


from (

			select  date_sub(curdate(),interval 1 day) stats_date,
					concat(ifnull(cdme.city,''),ifnull(cdme.branch,''),ifnull(cdme.center,''),ifnull(cdme.region,'')) region_name
			from bidata.charlie_dept_month_end cdme
			where cdme.stats_date = curdate()
				  and cdme.class = '销售'
				  and cdme.date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
			group by stats_date, region_name
			having region_name like '上海_区'
				   or region_name = '销售考核'
				   ) as x

left join (
              select
                      date_sub(curdate(),interval 1 day) stats_date,
                      concat(ifnull(cdme.city,''),ifnull(cdme.branch,''),ifnull(cdme.center,''),ifnull(cdme.region,'')) region_name,
                      sum(tcp.sum/100) total_performance,   -- 总流水业绩
					  dayofmonth(date_sub(curdate(),interval 1 day))/dayofmonth(last_day(date_sub(curdate(),interval 1 day))) rate, 
	                  sum(case when s.submit_time >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
                               then tcp.sum/100 else 0 end) new_performance,    -- 新线索流水业绩
	                  sum(case when s.submit_time < date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
                               then tcp.sum/100 else 0 end) all_oc_performance,    -- 大盘oc线索流水业绩
                      sum(case when s.submit_time >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
		                            and (s.coil_in in (13,22) or s.know_origin in (56,71,22,24,25,41))
                               then tcp.sum/100 else 0 end) new_rec_performance    -- 转介绍新线索流水业绩 
              from bidata.charlie_dept_month_end cdme
              left join hfjydb.view_tms_contract tc on tc.submit_user_id = cdme.user_id
                        and tc.status <> 8
              left join hfjydb.view_student s on tc.student_no =s.student_no
              left join hfjydb.view_tms_contract_payment tcp on tcp.contract_id = tc.contract_id
                        and tcp.pay_date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
		                and tcp.pay_date < curdate() and tcp.pay_status in (2,4)
              where cdme.class = '销售'
                    and cdme.stats_date = curdate()
                    and cdme.date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
              group by region_name, stats_date
			  ) as y on x.region_name = y.region_name and x.stats_date = y.stats_date

left join (
               select date_sub(curdate(),interval 1 day) stats_date,
               region_name,
               sum(achievement) as achievement,
			   sum(number) as staffs

               from(
		              select distinct cdme.department_name,
			                 concat(ifnull(cdme.city,''),ifnull(cdme.branch,''),ifnull(cdme.center,''),ifnull(cdme.region,'')) region_name,
			                 st.achievement,
							 st.number

		              from bidata.sales_tab st
		              inner join bidata.charlie_dept_month_end cdme on cdme.department_name = st.group_name
				                 and cdme.stats_date = curdate() and cdme.class = '销售'
				                 and cdme.date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
								 ) as t
               group by region_name,stats_date
			   ) as z on z.region_name = x.region_name and z.stats_date = x.stats_date

left join (
                select
                        date_sub(curdate(),interval 1 day) stats_date,
                        concat(ifnull(cdme.city,''),ifnull(cdme.branch,''),ifnull(cdme.center,''),ifnull(cdme.region,'')) region_name,
                        sum(tcp.sum/100) total_performance_splm   -- 上月同期总流水业绩    
                from bidata.charlie_dept_month_end cdme
                left join hfjydb.view_tms_contract tc on tc.submit_user_id = cdme.user_id
                          and tc.status <> 8
                left join hfjydb.view_student s on tc.student_no =s.student_no
                left join hfjydb.view_tms_contract_payment tcp on tcp.contract_id = tc.contract_id
                          and tcp.pay_date >= date_sub(date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01'),interval 1 month)
		                  and tcp.pay_date < date_sub(curdate(),interval 1 month)
		                  and tcp.pay_status in (2,4)
                where cdme.class = '销售' and cdme.stats_date = curdate()
                      and cdme.date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01')
                group by region_name, stats_date
				) as xx on xx.region_name = x.region_name and xx.stats_date = x.stats_date