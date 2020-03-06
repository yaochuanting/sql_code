select b.user_id,
       b.销售姓名,
		   b.销售编号,
		   b.销售等级,
		 	 b.组织架构,b.集团,b.中心,b.区,b.部门,b.组,
       b.今日是否打卡（即是否登录CRM界面）,
       case when 第一次请求时间 is null then '否' else '是' end 今日是否请求新名单,
       case when 应获新名单数-已获新名单数=0 and 应获新名单数<>0 then'是' 
            when 应获新名单数-已获新名单数>0 or 应获新名单数=0 then'否'
       end 是否已拿满新名单,
		  b.打卡时间,
			b.第一次请求时间,
			b.第一次请求到时间,
		  b.最近一次请求时间,
			b.最近一次请求到时间,
			b.已请求次数,
			b.应获新名单数,
		  b.已请求到新名单数,
			b.已获新名单数,
      b.综合转化率,
			b.产能	 
 from
	(select s.user_id,
	s.user_name 销售姓名,
	ui.job_number 销售编号,
	s.user_level 销售等级,
	s.com_rate 综合转化率,
	s.capacity	产能,
	concat(bcd.city,bcd.branch)	组织架构,
	bcd.branch'集团',
	bcd.center'中心',
        bcd.region'区',
	bcd.department'部门',
        bcd.grp'组',
	case when s.if_dingding_clock_in =1 and s.date_time>=CURDATE() then '是' else '否' end 今日是否打卡（即是否登录CRM界面）,
	s.date_time  打卡时间,
	(select min(n.create_time) from tms_new_name_get_log n where n.user_id = s.user_id and n.call_url like '%salesClientsAssign%' and n.create_time >= CURDATE())	第一次请求时间,
	(select min(n.create_time) from tms_new_name_get_log n where n.user_id = s.user_id and n.call_url like '%salesClientsAssign%' and n.return_code = 200 and n.create_time >= CURDATE())	第一次请求到时间,
	(select max(n.create_time) from tms_new_name_get_log n where n.user_id = s.user_id and n.call_url like '%salesClientsAssign%' and n.create_time >= CURDATE()) 最近一次请求时间,
	(select max(n.create_time) from tms_new_name_get_log n where n.user_id = s.user_id and n.call_url like '%salesClientsAssign%' and n.return_code = 200 and n.create_time >= CURDATE())	最近一次请求到时间,
	(select count(return_code) from tms_new_name_get_log n where n.user_id = s.user_id and n.call_url like '%salesClientsAssign%' and n.create_time >= CURDATE())	已请求次数,
	s.acquire_list_num	应获新名单数,
	(select count(DISTINCT n.student_intention_id) from tms_new_name_get_log n where n.user_id = s.user_id and n.call_url like '%salesClientsAssign%' and n.return_code = 200 and n.create_time >= CURDATE())已请求到新名单数,
	s.acquired_list_num 已获新名单数
	FROM sale_level s 
	left join  view_user_info ui on s.user_id = ui.user_id
	LEFT JOIN bidata.charlie_dept bcd on bcd.user_id=s.user_id) b