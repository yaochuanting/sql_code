select  c.provincename,
		c.cityname,
		count(tcr.student_intention_id) as call_cnt,
        count(case when tcr.status=33 then tcr.student_intention_id else null end) as bridge_cnt,
        count(tcr.student_intention_id)/count(case when tcr.status=33 then tcr.student_intention_id else null end) as bridge_rate

from hfjydb.view_tms_call_record tcr
left join hfjydb.view_student s on s.student_intention_id=tcr.student_intention_id
left join hfjydb.map_phone_city c on c.phone7=left(s.phone,7)
inner join bidata.charlie_dept_month_end cdme on cdme.user_id=tcr.user_id
           and cdme.class='销售' and cdme.stats_date=curdate()
where date(tcr.start_time)>='2019-09-01' 
      and date(tcr.start_time) < curdate()
      and tcr.call_type=1
      and tcr.student_intention_id is not null 
group by cityname