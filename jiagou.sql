select 
    CURDATE() as date,ui.user_id,ui.name,ui.job_number_new job_number,sr.role_id,sr.role_code,sr.role_name,sd.department_id,sd.department_name,sd.pid,
    
    


    (case when locate('管培',sd.department_name) = 1  OR sd.department_name like '%CC%' or sd.department_name like '%CR%'
           then '上海'
      else left(sd.department_name,2) end) city,

(case 
        when locate('销售',sd.department_name) >0 then '销售'
      when locate('学管',sd.department_name) >0 then '学管'
      else null
end) branch,

(case
        when sd.department_name like 'CC_大区%' then substring(sd.department_name,locate('CC',sd.department_name),locate('大区',sd.department_name)+1)
      when sd.department_name like 'CC考核%' then 'CC考核区'
      when sd.department_name like '%CC入职培训部%' then 'CC入职培训部'
      when sd.department_name in('CC考核区','CC其他部门') then sd.department_name
end) center,

(case when sd.department_name like 'CC_大区%' then substring(sd.department_name,locate('大区',sd.department_name)+2,locate('区',sd.department_name,locate('大区',sd.department_name)+2)-locate('区',sd.department_name))
      else null
      end) region,

(case when (sd.department_name like 'CC_大区%' or sd.department_name like 'CC考核区%') and sd.department_name not like 'CC_大区'  then substring(sd.department_name,locate('区',sd.department_name,locate('大区',sd.department_name)+2)+1)
      when sd.department_name='CC考核区待分配部' then '待分配部'
      when sd.department_name like '%部CR%组' then substring(sd.department_name,1,locate('部',sd.department_name))
      when sd.department_name like '%CR入职培训部' or sd.department_name like '上海__入职培训部' then '入职培训部'
      when sd.department_name like 'CR考核_部' or sd.department_name='CR培训部' then sd.department_name
      when  sd.department_name like '在线事业部CR%'  then '在线事业部CR'
      when sd.department_name like 'CR_部%' then substring(sd.department_name,3,locate('部',sd.department_name)-locate('CR',sd.department_name)-1)
      else null
end) department,

(case when sd.department_name like '%部CR%组' then substring(sd.department_name,locate('CR',sd.department_name))
     -- when locate('考核',sd.department_name) > 0 and sd.department_name not like 'CC%' then substring(sd.department_name,locate('考核',sd.department_name)+2,10)
     -- when locate('班销',sd.department_name) > 0 then substring(sd.department_name,locate('班销',sd.department_name)+2,locate('组',sd.department_name)-locate('班销',sd.department_name)-1)
       -- when locate('上海学管',sd.department_name) > 0  then substring(sd.department_name,locate('中心',sd.department_name)+2,locate('组',sd.department_name)-locate('中心',sd.department_name)-1)
      when locate('北京学管',sd.department_name) > 0  then substring(sd.department_name,locate('学管',sd.department_name)+2,locate('组',sd.department_name)-locate('学管',sd.department_name))
     -- when locate('精英学院',sd.department_name) > 0 then substring(sd.department_name,locate('部',sd.department_name)+1,4)
      when locate('组',sd.department_name) > 0 then substring(sd.department_name,locate('部',sd.department_name)+1,locate('组',sd.department_name)-locate('部',sd.department_name)+1)
end) grp,




















    
    case when sd.department_name like '%学管%' or sd.department_name like '%CR%' then 0 else 1 end tag,
    CURRENT_TIMESTAMP() as update_time

from 
	(select *,
        REPLACE(REPLACE(REPLACE(REPLACE(job_number,CHAR(13),''),CHAR(10),''),CHAR(9),''),' ','') as job_number_new
    from view_user_info) ui  ##去除水平制表符换行回车
left join sys_user_role sur on ui.user_id=sur.user_id
left join sys_role sr on sur.role_id=sr.role_id
left join sys_department sd on sr.department_id=sd.department_id
where  
    (ui.status in (1,2) -- 账号状态 （0  '禁用'  1  '可用'  2  '手机已认证'）
    and ui.user_type = 2 -- 员工账号
    and ui.account_type = 1 -- 非测试账号
    and sd.department_name regexp '学管|考核|销售|管培|海小|CC|CR' and sd.department_name not regexp '离职|OC|测试|存放|讲座|学科|黄妈|沪江' 
    and ui.name not regexp 'OC|测试|存放|退费|名单|小单组|未成单' and (ui.job_number not regexp '^A.+|^V.+|^T.+' or ui.job_number is null))
or ui.user_id =21053 ##加上倪婷婷
