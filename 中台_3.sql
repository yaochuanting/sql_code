select date_sub(curdate(), interval 1 day) stats_date,
       case when s.submit_time >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01') then 'new'
	        when s.submit_time >= date_sub(date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01'),interval 1 month) then 'sec_new'
			when year(s.submit_time) = 2019 then 'toyear_oc'
	   else 'his_oc' end key_attr,
	   count(distinct ss.student_intention_id) as req,  -- 触碰量
	   count(distinct case when tcr.id is not null then ss.student_intention_id else null end) as call_req,  -- 触碰拨打量
	   count(distinct case when tcr.status = 33 then ss.student_intention_id else null end) as bridge_req,   -- 触碰接通量
	   count(distinct case when tcr.status <> 33 and tcr.id is not null
								and timestampdiff(second, tcr.start_time, tcr.end_time) <= 5
                           then ss.student_intention_id else null end) as nobridge_wt5_req    -- 未接通且等待时间小于5秒


from hfjydb.ss_collection_sale_roster_action ss
left join bidata.charlie_dept_month_end cdme on cdme.user_id = ss.user_id
          and cdme.stats_date = curdate() and cdme.class = '销售'
		  and cdme.date >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01') 
left join hfjydb.view_student s on s.student_intention_id = ss.student_intention_id
left join hfjydb.tms_call_record tcr on ss.record_auto_id = tcr.id
          and tcr.call_type = 1 -- 打给学生
where ss.view_time >= date_format(date_sub(curdate(),interval 1 day),'%Y-%m-01') 
      and ss.view_time < curdate()
group by stats_date, key_attr