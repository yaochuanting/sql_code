
select x.stats_date `统计日期`,
       x.region_name `区`,
	   round(sum(y.total_performance),2) as `总流水业绩`,
	   sum(z.staffs) as `月初抗标人数`,
	   round(sum(y.total_performance) / sum(z.staffs),2) as `人效流水`,
	   round(sum(xx.total_performance_splm),2) as `上月同期流水业绩`,
	   round(((sum(y.total_performance) - sum(xx.total_performance_splm))/sum(xx.total_performance_splm))* 100,2) as `流水环比增长率`,
	   round(sum(y.new_performance),2) as `新线索流水业绩`,
	   round(sum(y.new_performance) / sum(y.total_performance)* 100,2) as `新线索业绩占比`,
	   round(sum(y.all_oc_performance),2) as `大盘oc线索流水业绩`,
	   round(sum(y.all_oc_performance) / sum(y.total_performance)* 100,2) as `大盘oc业绩占比`,
	   round(sum(y.new_rec_performance),2) as `转介绍新线索流水业绩`,
	   round(sum(y.new_rec_performance) / sum(y.new_performance)* 100,2) as `转介绍业绩占比`
from (

			select  distinct '${analyse_date}' stats_date,
					concat(coalesce(cdme.center,''),coalesce(cdme.region,'')) region_name
			from dt_mobdb.dt_charlie_dept_month_end cdme
			where cdme.stats_date = current_date()
				  and cdme.class = 'CC'
				  and cdme.`date` >= trunc('${analyse_date}','MM')
			      and cdme.department_name like 'CC%'
				   ) as x

left join (
              select
                      '${analyse_date}' stats_date,
                      concat(coalesce(cdme.center,''),coalesce(cdme.region,'')) region_name,
                      sum(tcp.sum/100) total_performance,   -- 总流水业绩
					  day('${analyse_date}')/day(last_day('${analyse_date}')) rate, 
	                  sum(case when s.submit_time >= trunc('${analyse_date}','MM')
                               then tcp.sum/100 else 0 end) new_performance,    -- 新线索流水业绩
	                  sum(case when s.submit_time < trunc('${analyse_date}','MM')
                               then tcp.sum/100 else 0 end) all_oc_performance,    -- 大盘oc线索流水业绩
                      sum(case when s.submit_time >= trunc('${analyse_date}','MM')
		                            and (s.coil_in in (13,22) or s.know_origin in (56,71,22,24,25,41))
                               then tcp.sum/100 else 0 end) new_rec_performance    -- 转介绍新线索流水业绩 
              from dt_mobdb.dt_charlie_dept_month_end cdme
              left join dw_hf_mobdb.dw_view_tms_contract tc on tc.submit_user_id = cdme.user_id
                        and tc.status <> 8
              left join dw_hf_mobdb.dw_view_student s on tc.student_no =s.student_no
              left join dw_hf_mobdb.dw_view_tms_contract_payment tcp on tcp.contract_id = tc.contract_id
                        and to_date(tcp.pay_date) >= trunc('${analyse_date}','MM')
		                    and to_date(tcp.pay_date) < current_date() 
                        and tcp.pay_status in (2,4)
              where cdme.class = 'CC'
                    and cdme.stats_date = current_date()
                    and cdme.`date` >= trunc('${analyse_date}','MM')
              group by concat(coalesce(cdme.center,''),coalesce(cdme.region,''))
			  ) as y on x.region_name = y.region_name and x.stats_date = y.stats_date

left join (
               select '${analyse_date}' stats_date,
               region_name,
               sum(achievement) as achievement,
			         sum(number) as staffs

               from(
		              select distinct cdme.department_name,
			                 concat(coalesce(cdme.center,''),coalesce(cdme.region,'')) region_name,
			                 st.achievement,
							         st.number
		              from hf_mobdb.sales_tab st
		              inner join dt_mobdb.dt_charlie_dept_month_end cdme on cdme.department_name = st.group_name
				                 and cdme.stats_date = current_date() and cdme.class = 'CC'
				                 and cdme.`date` >= trunc('${analyse_date}','MM')
								 ) as t
               group by region_name
			   ) as z on z.region_name = x.region_name and z.stats_date = x.stats_date

left join (
                select
                        '${analyse_date}' stats_date,
                        concat(coalesce(cdme.center,''),coalesce(cdme.region,'')) region_name,
                        sum(tcp.sum/100) total_performance_splm   -- 上月同期总流水业绩    
                from dt_mobdb.dt_charlie_dept_month_end cdme
                left join dw_hf_mobdb.dw_view_tms_contract tc on tc.submit_user_id = cdme.user_id
                          and tc.status <> 8
                left join dw_hf_mobdb.dw_view_student s on tc.student_no =s.student_no
                left join dw_hf_mobdb.dw_view_tms_contract_payment tcp on tcp.contract_id = tc.contract_id
                          and to_date(tcp.pay_date) >= add_months(trunc('${analyse_date}','MM'), -1)
		                      and to_date(tcp.pay_date) < add_months(current_date(), -1)
		                      and tcp.pay_status in (2,4)
                where cdme.class = 'CC' and cdme.stats_date = current_date()
                      and cdme.`date` >= add_months(trunc('${analyse_date}','MM'),-1)
                group by concat(coalesce(cdme.center,''),coalesce(cdme.region,''))
				) as xx on xx.region_name = x.region_name and xx.stats_date = x.stats_date
group by x.stats_date,x.region_name