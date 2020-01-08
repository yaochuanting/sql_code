



-- 谢启所有10月分配的线索，线索的上一个归属人、线索的获得者、线索分配操作时间、是否成单、
-- 成单时间、成单生成人、成单是否分配班主任、班主任姓名

select s.student_no '学生编号',ui.name '线索的获得者',(select name from view_user_info 
where user_id =(select track_userid from tms_pool_exchange_log where intention_id=tpel.intention_id
and id<tpel.id order by id desc limit 1)) '线索的上一个归属人',tpel.into_pool_date '线索分配操作时间',
(case when (select count(1) from view_tms_contract 
where student_intention_id=tpel.intention_id and status in(3,4,5,6,7,9))>0 then '是' else '否' end) '是否成单',
(select group_concat(submit_time) from view_tms_contract 
where student_intention_id=tpel.intention_id and status in(3,4,5,6,7,9) ) '合同生成时间',
(select group_concat(name) from view_user_info where user_id in(select submit_user_id from view_tms_contract 
where student_intention_id=tpel.intention_id and status in(3,4,5,6,7,9) ) )'合同生成人',ui3.name '班主任姓名'


from tms_pool_exchange_log tpel left join view_user_info ui on tpel.track_userId=ui.user_id
left join view_student s on tpel.intention_id=s.student_intention_id
left Join view_user_info ui3 on s.by_assistant=ui3.user_id
where tpel.create_userId=95518 and tpel.into_pool_date between '2018-10-01' and '2018-11-01'


--
select name, user_id
FROM view_user_info
where job_number = 'S003006'





#### 引用自:
#### title:所有10月分配的线索，线索的上一个归属人、线索的获得者、线索分配操作时间、是否成单、成单时间、成单生成人、成单是否分配班主任、班主任姓名
#### 执行时间:40s,新脱敏库hfjy
#### 日期:2018-12-10
#### created by:付朝阳
#### update by: 
#### checked by: 

select s.student_no '学生编号',tpel.into_pool_date '线索分配操作时间',ui.name '线索分配操作人',ui.user_id,

(select name from view_user_info where user_id =(select track_userid from tms_pool_exchange_log 
where intention_id=tpel.intention_id and into_pool_date<tpel.into_pool_date order by id desc limit 1) and name not Like '%测试%' ) '线索前一个跟进人',
ui2.name '被分配人',

(select (submit_time) from view_tms_contract 
where student_intention_id=tpel.intention_id and status in(3,4,5,6,7,9) 
ORDER BY submit_time desc limit 1) '合同生成时间',

(select su.name
from view_tms_contract stc
left join view_user_info su on stc.submit_user_id = su.user_id
where student_intention_id=tpel.intention_id and stc.status in(3,4,5,6,7,9) and su.name not Like '%测试%' 
ORDER BY stc.submit_time desc limit 1) '合同生成人',


(case when (select count(1) from lesson_plan where student_id=s.student_id and lesson_type=1 
and status in(3,5) and solve_status<>6 )>0 then '是' else '否' end) '是否开课',
(select name from view_user_info where user_id = s.by_assistant and  name not Like '%测试%') '班主任姓名'

from tms_pool_exchange_log tpel left join view_student s on tpel.intention_id=s.student_intention_id
left Join view_user_info ui on tpel.create_userid=ui.user_id
left Join view_user_info ui2 on tpel.track_userid=ui2.user_id

where tpel.into_pool_date between '2018-11-30' and '2018-12-07' and tpel.role_code in('XS-ZZ','XS-ZY','XS-JL')
and ui2.name not like '%测试%' and  ui2.name not like '%OC%' 
and ui2.name not in('数据待分配','2016年线索','试听15天未成单-3','废单池')
and ui.name not Like '%测试%' 


-- and ui.user_id = 431086
-- and s.student_no in
-- ( 59561736, 76052353, 71297251, 10427690, 79468363, 16888044, 83391272, 39456497, 77190858, 31160998, 35081564, 60041789, 96161811, 20454218, 97170135, 46173569, 78939039, 43782997, 55369748, 91239167, 66424511, 19825442, 58460746, 99138312, 33197601, 58513591, 44123317, 78716463, 97036683)
-- 



















