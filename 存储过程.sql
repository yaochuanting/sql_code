CREATE DEFINER=`shenyuqing`@`%` PROCEDURE `dm_touch`()
begin

insert into tmp_mobdb.yct_ss_collection_score_daily (view_time, student_intention_id, user_id, record_auto_id, score, score_pct)

select ss.view_time, 
       ss.student_intention_id, 
			 ss.user_id, 
			 ss.record_auto_id,
			 h.cur_score,
			 h.cur_score_percentile
from hfjydb.ss_collection_sale_roster_action ss
inner join dt_mobdb.alb_ocleads_score_s1_v2_hist h on h.student_intention_id = ss.student_intention_id
where date(ss.view_time) = date_sub(curdate(),interval 1 day);

end