/*****************************************************

	セグメント情報(抽出前状態)

*****************************************************/
select
	user_id,
	1 as uu,
	coin,
	coin_kbn,
	reg_days,
	case when reg_days < 60   then '01_60日未満' when reg_days < 180  then '02_180日未満' when reg_days < 720  then '03_2年未満' when reg_days < 1440 then '04_4年未満' when reg_days >=1440 then '05_4年以上' end reg_days_kbn,
	cust_days,
	case when cust_days < 60   then '01_60日未満' when cust_days < 180  then '02_180日未満' when cust_days < 720  then '03_2年未満' when cust_days < 1440 then '04_4年未満' when cust_days >=1440 then '05_4年以上' end cust_days_kbn,
	recency_last_spend,
	case when recency_last_spend < 14   then '01_14日未満' when recency_last_spend < 30  then '02_30日未満' when recency_last_spend < 90  then '03_90日未満' when recency_last_spend < 180 then '04_180日未満' when recency_last_spend >=180 then '05_180日以上' end recency_last_spend_kbn,
	last_age,
	sex,
	coin_naruto
into
	#segment
from
(
	select
		user_id,
		coin,
		case when coin >= 30000 then '01_30000円以上' when coin >= 9000 then '02_9000円以上' else '03_9000円未満' end as coin_kbn,
--		datediff(d, reg_date, cast(dateadd(d, -2, getdate()) as date)) as reg_days,
		datediff(d, reg_date, '2013-04-30') as reg_days,
		datediff(d, reg_date, last_spend_date) as cust_days,
--		datediff(d, last_spend_date, dateadd(d, -2, cast(getdate() as date))) as recency_last_spend,
		datediff(d, last_spend_date, '2013-04-30') as recency_last_spend,
		last_age,
		sex,
		coin_naruto
	from
	(
		select	user_id, sum(coin_nondeveloper) as coin, min(reg_date) as reg_date, max(date) as last_spend_date, max(age) as last_age, max(sex) as sex, 
				sum(case when application_id=55166 then coin_nondeveloper else 0 end) as coin_naruto 
		from
		(
			select * from mitsuda_analytics.dbo.log_platform_ggp_spend_spend_201302
			union all select * from mitsuda_analytics.dbo.log_platform_ggp_spend_spend_201303
			union all select * from mitsuda_analytics.dbo.log_platform_ggp_spend_spend_201304
--			union all select * from mitsuda_analytics.dbo.log_platform_ggp_spend_spend_201305
--			union all select * from mitsuda_analytics.dbo.log_platform_ggp_spend_spend_201306
		) t1
		where region='JP' and type in(-16010, -4010, -2010) --and datediff(d, date, cast(dateadd(d, -2, getdate()) as date)) < 90
		group by user_id
	) t2
) t
--(1378785 行処理されました)


/*****************************************************

	休眠復帰率評価 with セグメント別

*****************************************************/
--ユーザアプリ別デバイスマスタ
select device, user_id, application_id
into #m_users_app_device
from
(
	select 'sp' as device, user_id, application_id 
	from
	(
		select * from summary.dbo.app_all_201206 where application_id in(2676,112,55166,1242,56359,98)
		union all select * from summary.dbo.app_all_201207 where application_id in(2676,112,55166,1242,56359,98)
		union all select * from summary.dbo.app_all_201208 where application_id in(2676,112,55166,1242,56359,98)
		union all select * from summary.dbo.app_all_201209 where application_id in(2676,112,55166,1242,56359,98)
		union all select * from summary.dbo.app_all_201210 where application_id in(2676,112,55166,1242,56359,98)
		union all select * from summary.dbo.app_all_201211 where application_id in(2676,112,55166,1242,56359,98)
		union all select * from summary.dbo.app_all_201212 where application_id in(2676,112,55166,1242,56359,98)
		union all select * from summary.dbo.app_all_201301 where application_id in(2676,112,55166,1242,56359,98)
		union all select * from summary.dbo.app_all_201302 where application_id in(2676,112,55166,1242,56359,98)
		union all select * from summary.dbo.app_all_201303 where application_id in(2676,112,55166,1242,56359,98)
		union all select * from summary.dbo.app_all_201304 where application_id in(2676,112,55166,1242,56359,98)
		union all select * from summary.dbo.app_all_201305 where application_id in(2676,112,55166,1242,56359,98)
	) t
	group by user_id, application_id
) t1
--8min,(8404933 行処理されました)


--配信成功ユーザの分割(2deviceは2rowsへ)
select t.user_id, t.app_id, t.app_name, m.device
into #success_device
from
(
	--配信成功(5282778rows)
	select distinct 'gandum' as app_name, 2676 as app_id, user_id from norikazu_slp0612_success_gandum
	union all select distinct 'kaizoku' as app_name, 112 as app_id, user_id from norikazu_slp0612_success_kaizoku
	union all select distinct 'kaizoku' as app_name, 112 as app_id, user_id from norikazu_slp0612_success_kaizoku_none
	union all select distinct 'naruto' as app_name, 55166 as app_id, user_id from norikazu_slp0612_success_naruto
	union all select distinct 'seisen' as app_name, 1242 as app_id, user_id from norikazu_slp0612_success_seisen
	union all select distinct 'tails' as app_name, 56359 as app_id, user_id from norikazu_slp0612_success_tails
	union all select distinct 'tanken' as app_name, 98 as app_id, user_id from norikazu_slp0612_success_tanken
) t
left join
	#m_users_app_device m
on t.user_id=m.user_id and t.app_id=m.application_id
--(5282778 行処理されました)



/* 配信成功当日プレイユーザwith当日復帰ユーザの中で */
select device, app_name, user_id
into #fukki_after_zero_days
from
(
	select distinct 'sp' as device, 'gandum' as app_name, user_id from summary.dbo.app_all_201305 p where application_id=2676 and date=dateadd(d,0,'2013-05-10') and exists(select 1 from norikazu_slp0612_fukki_gandum f where p.user_id=f.user_id)
	union all select distinct 'sp' as device, 'kaizoku' as app_name, user_id from summary.dbo.app_all_201305 p where application_id=112 and date=dateadd(d,0,'2013-05-24') and exists(select 1 from norikazu_slp0612_fukki_kaizoku f where p.user_id=f.user_id)
	union all select distinct 'sp' as device, 'naruto' as app_name, user_id from summary.dbo.app_all_201305 p where application_id=55166 and date=dateadd(d,0,'2013-05-14') and exists(select 1 from norikazu_slp0612_fukki_naruto f where p.user_id=f.user_id)
	union all select distinct 'sp' as device, 'seisen' as app_name, user_id from summary.dbo.app_all_201305 p where application_id=1242 and date=dateadd(d,0,'2013-05-23') and exists(select 1 from norikazu_slp0612_fukki_seisen f where p.user_id=f.user_id)
	union all select distinct 'sp' as device, 'tails' as app_name, user_id from summary.dbo.app_all_201305 p where application_id=56359 and date=dateadd(d,0,'2013-05-28') and exists(select 1 from norikazu_slp0612_fukki_tails f where p.user_id=f.user_id)
	union all select distinct 'sp' as device, 'tanken' as app_name, user_id from summary.dbo.app_all_201305 p where application_id=98 and date=dateadd(d,0,'2013-05-26') and exists(select 1 from norikazu_slp0612_fukki_tanken f where p.user_id=f.user_id)
) t
--(45738 行処理されました)


/* 配信成功後7日目プレイユーザwith当日復帰ユーザの中で +*/
select device, app_name, user_id
into #fukki_after_7days
from
(
	select distinct 'sp' as device, 'gandum' as app_name, user_id from summary.dbo.app_all_201305 p where application_id=2676 and date=dateadd(d,7,'2013-05-10') and exists(select 1 from norikazu_slp0612_fukki_gandum f where p.user_id=f.user_id)
	union all select distinct 'sp' as device, 'kaizoku' as app_name, user_id from summary.dbo.app_all_201305 p where application_id=112 and date=dateadd(d,7,'2013-05-24') and exists(select 1 from norikazu_slp0612_fukki_kaizoku f where p.user_id=f.user_id)
	union all select distinct 'sp' as device, 'naruto' as app_name, user_id from summary.dbo.app_all_201305 p where application_id=55166 and date=dateadd(d,7,'2013-05-14') and exists(select 1 from norikazu_slp0612_fukki_naruto f where p.user_id=f.user_id)
	union all select distinct 'sp' as device, 'seisen' as app_name, user_id from summary.dbo.app_all_201305 p where application_id=1242 and date=dateadd(d,7,'2013-05-23') and exists(select 1 from norikazu_slp0612_fukki_seisen f where p.user_id=f.user_id)
	union all select distinct 'sp' as device, 'tails' as app_name, user_id from summary.dbo.app_all_201306 p where application_id=56359 and date=dateadd(d,7,'2013-05-28') and exists(select 1 from norikazu_slp0612_fukki_tails f where p.user_id=f.user_id)
	union all select distinct 'sp' as device, 'tanken' as app_name, user_id from summary.dbo.app_all_201306 p where application_id=98 and date=dateadd(d,7,'2013-05-26') and exists(select 1 from norikazu_slp0612_fukki_tanken f where p.user_id=f.user_id)
) t
--(18306 行処理されました)









/* 配信成功当日クリックユーザの1wk消費 */
select t.user_id, t.app_id, t.app_name, m.device
into #fukki_device
from
(
	--配信成功(5282778rows)
	select distinct 'gandum' as app_name, 2676 as app_id, user_id from norikazu_slp0612_fukki_gandum
	union all select distinct 'kaizoku' as app_name, 112 as app_id, user_id from norikazu_slp0612_fukki_kaizoku
	union all select distinct 'naruto' as app_name, 55166 as app_id, user_id from norikazu_slp0612_fukki_naruto
	union all select distinct 'seisen' as app_name, 1242 as app_id, user_id from norikazu_slp0612_fukki_seisen
	union all select distinct 'tails' as app_name, 56359 as app_id, user_id from norikazu_slp0612_fukki_tails
	union all select distinct 'tanken' as app_name, 98 as app_id, user_id from norikazu_slp0612_fukki_tanken
) t
left join
	#m_users_app_device m
on t.user_id=m.user_id and t.app_id=m.application_id
--(128280 行処理されました)

select distinct user_id from #fukki_device where device='sp' and app_name='gandum'
--28126

select user_id, date, application_id, coin_nondeveloper as coin
into #spend
from
(
	select * from mitsuda_analytics.dbo.log_platform_ggp_spend_spend_201305 where application_id in(2676,112,55166,1242,56359,98) and region='JP' and type in(-16010, -4010, -2010) 
	union all select * from mitsuda_analytics.dbo.log_platform_ggp_spend_spend_201306 where application_id in(2676,112,55166,1242,56359,98) and region='JP' and type in(-16010, -4010, -2010)
) t
--(5016006 行処理されました)

select device, app_name, user_id, coin
into #fukki_after_spend
from
(
	select distinct 'sp' as device,'gandum' as app_name,user_id,sum(coin) as coin from #spend s where application_id=2676 and date between '2013-05-10' and dateadd(d,6,'2013-05-10') and exists(select 1 from #fukki_device f where f.app_name='gandum' and f.device='sp' and s.user_id=f.user_id) group by user_id
	union all select distinct 'sp' as device,'kaizoku' as app_name,user_id,sum(coin) as coin from #spend s where application_id=112 and date between '2013-05-24' and dateadd(d,6,'2013-05-24') and exists(select 1 from #fukki_device f where f.app_name='kaizoku' and f.device='sp' and s.user_id=f.user_id) group by user_id
	union all select distinct 'sp' as device,'naruto' as app_name,user_id,sum(coin) as coin from #spend s where application_id=55166 and date between '2013-05-14' and dateadd(d,6,'2013-05-14') and exists(select 1 from #fukki_device f where f.app_name='naruto' and f.device='sp' and s.user_id=f.user_id) group by user_id
	union all select distinct 'sp' as device,'seisen' as app_name,user_id,sum(coin) as coin from #spend s where application_id=1242 and date between '2013-05-23' and dateadd(d,6,'2013-05-23') and exists(select 1 from #fukki_device f where f.app_name='seisen' and f.device='sp' and s.user_id=f.user_id) group by user_id
	union all select distinct 'sp' as device,'tails' as app_name,user_id,sum(coin) as coin from #spend s where application_id=56359 and date between '2013-05-28' and dateadd(d,6,'2013-05-28') and exists(select 1 from #fukki_device f where f.app_name='tails' and f.device='sp' and s.user_id=f.user_id) group by user_id
	union all select distinct 'sp' as device,'tanken' as app_name,user_id,sum(coin) as coin from #spend s where application_id=98 and date between '2013-05-26' and dateadd(d,6,'2013-05-26') and exists(select 1 from #fukki_device f where f.app_name='tanken' and f.device='sp' and s.user_id=f.user_id) group by user_id
) t
--(22271 行処理されました)

/*
--seisen
select date,count(distinct user_id) as uu
from summary.dbo.app_all_201305 a 
where application_id=1242 and exists(select 1 from norikazu_slp0612_success_seisen s where a.user_id=s.user_id)
group by date
order by date

--gandum
select date,count(distinct user_id) as uu
from summary.dbo.app_all_201305 a 
where application_id=2676 and exists(select 1 from norikazu_slp0612_success_gandum s where a.user_id=s.user_id)
group by date
order by date

--naruto
select date,count(distinct user_id) as uu
from summary.dbo.app_all_201305 a 
where application_id=55166 --and exists(select 1 from norikazu_slp0612_success_naruto s where a.user_id=s.user_id)
group by date
order by date

select date,count(distinct user_id) as uu
from summary.dbo.fp_app_all_201305 a 
where application_id=55166 and exists(select 1 from norikazu_slp0612_success_naruto s where a.user_id=s.user_id)
group by date
order by date
*/



/* 配信当日新規インストールユーザによる消費 */
select device, app_name, user_id
into #newusers
from
(
	select distinct 'sp' as device, 'gandum' as app_name, user_id from mitsuda_analytics.dbo.log_platform_ggp_lifecycle_lifecycle_201305 where region='JP' and event_type=1 and device in(2,4,16) and application_id=2676 and date='2013-05-10'
	union all select distinct 'sp' as device, 'kaizoku' as app_name, user_id from mitsuda_analytics.dbo.log_platform_ggp_lifecycle_lifecycle_201305 where region='JP' and event_type=1 and device in(2,4,16) and application_id=112 and date='2013-05-24'
	union all select distinct 'sp' as device, 'naruto' as app_name, user_id from mitsuda_analytics.dbo.log_platform_ggp_lifecycle_lifecycle_201305 where region='JP' and event_type=1 and device in(2,4,16) and application_id=55166 and date='2013-05-14'
	union all select distinct 'sp' as device, 'seisen' as app_name, user_id from mitsuda_analytics.dbo.log_platform_ggp_lifecycle_lifecycle_201305 where region='JP' and event_type=1 and device in(2,4,16) and application_id=1242 and date='2013-05-23'
	union all select distinct 'sp' as device, 'tails' as app_name, user_id from mitsuda_analytics.dbo.log_platform_ggp_lifecycle_lifecycle_201305 where region='JP' and event_type=1 and device in(2,4,16) and application_id=56359 and date='2013-05-28'
	union all select distinct 'sp' as device, 'tanken' as app_name, user_id from mitsuda_analytics.dbo.log_platform_ggp_lifecycle_lifecycle_201305 where region='JP' and event_type=1 and device in(2,4,16) and application_id=98 and date='2013-05-26'
) t
where not exists(select 1 from #success_device sd where t.user_id=sd.user_id)
--(2013 行処理されました)

select device, app_name, user_id, coin
into #newusersspend
from
(
	select distinct 'sp' as device,'gandum' as app_name,user_id,sum(coin) as coin from #spend s where application_id=2676 and date between '2013-05-10' and dateadd(d,6,'2013-05-10') and exists(select 1 from #newusers n where s.user_id=n.user_id and n.app_name='gandum' and n.device='sp') group by user_id
	union all select distinct 'sp' as device,'kaizoku' as app_name,user_id,sum(coin) as coin from #spend s where application_id=112 and date between '2013-05-24' and dateadd(d,6,'2013-05-24') and exists(select 1 from #newusers n where s.user_id=n.user_id and n.app_name='kaizoku' and n.device='sp') group by user_id
	union all select distinct 'sp' as device,'naruto' as app_name,user_id,sum(coin) as coin from #spend s where application_id=55166 and date between '2013-05-14' and dateadd(d,6,'2013-05-14') and exists(select 1 from #newusers n where s.user_id=n.user_id and n.app_name='naruto' and n.device='sp') group by user_id
	union all select distinct 'sp' as device,'seisen' as app_name,user_id,sum(coin) as coin from #spend s where application_id=1242 and date between '2013-05-23' and dateadd(d,6,'2013-05-23') and exists(select 1 from #newusers n where s.user_id=n.user_id and n.app_name='seisen' and n.device='sp') group by user_id
	union all select distinct 'sp' as device,'tails' as app_name,user_id,sum(coin) as coin from #spend s where application_id=56359 and date between '2013-05-28' and dateadd(d,6,'2013-05-28') and exists(select 1 from #newusers n where s.user_id=n.user_id and n.app_name='tails' and n.device='sp') group by user_id
	union all select distinct 'sp' as device,'tanken' as app_name,user_id,sum(coin) as coin from #spend s where application_id=98 and date between '2013-05-26' and dateadd(d,6,'2013-05-26') and exists(select 1 from #newusers n where s.user_id=n.user_id and n.app_name='tanken' and n.device='sp') group by user_id
) t
--(254 行処理されました)


/* 集計用 */
drop table norikazu_slp0612_res_v2_bench_new
select n.*, 1 as uu_new, isnull(s.coin,0) as coin, case when s.coin is not null then 1 else 0 end as uu_spend
into norikazu_slp0612_res_v2_bench_new
from #newusers n
left join #newusersspend s
on n.device = s.device and n.app_name=s.app_name and n.user_id=s.user_id


drop table norikazu_slp0612_res_v2
select
	s.app_name,
	s.device,
	s.user_id,
	1 as uu_success,	--app_name/device単位のUU
	case when f.user_id is not null then 1 else 0 end as uu_fukki_click,
	case when fz.user_id is not null then 1 else 0 end as uu_fukki_click_play,	
	case when f7.user_id is not null then 1 else 0 end as uu_fukki_7days,
	seg.coin,
	seg.coin_naruto,
	rank() over(order by seg.coin_naruto desc) * 1.0 / count(*) over() as position_naruto, 
	seg.coin_kbn,
	seg.reg_days,
	seg.reg_days_kbn,
	seg.cust_days,
	seg.cust_days_kbn,
	seg.recency_last_spend,
	seg.recency_last_spend_kbn,
	seg.sex,
	seg.last_age,
	spend.coin as coin_after_fukki,
	case when spend.coin is not null then 1 else 0 end as uu_coin_after_fukki
into
	norikazu_slp0612_res_v2
from
	#success_device s
left join
(
	--当日復帰(click)
	select distinct 'gandum' as app_name, user_id from norikazu_slp0612_fukki_gandum
	union all select distinct 'kaizoku' as app_name, user_id from norikazu_slp0612_fukki_kaizoku
	union all select distinct 'naruto' as app_name, user_id from norikazu_slp0612_fukki_naruto
	union all select distinct 'seisen' as app_name, user_id from norikazu_slp0612_fukki_seisen
	union all select distinct 'tails' as app_name, user_id from norikazu_slp0612_fukki_tails
	union all select distinct 'tanken' as app_name, user_id from norikazu_slp0612_fukki_tanken
) f
on s.app_name = f.app_name and s.user_id = f.user_id
left join
	#fukki_after_zero_days fz
on s.app_name = fz.app_name and s.user_id = fz.user_id
left join
	#fukki_after_7days f7
on s.app_name = f7.app_name and s.user_id = f7.user_id and s.device=f7.device
left join
	#segment seg
on s.user_id = seg.user_id
left join
	#fukki_after_spend spend
on s.user_id = spend.user_id and s.device = spend.device and s.app_name=spend.app_name
left join
	#newusers n
on s.user_id = n.user_id and  s.device = n.device and s.app_name=n.app_name
--(5282778 行処理されました)

