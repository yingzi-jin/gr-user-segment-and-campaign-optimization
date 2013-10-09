/*************************************************************************************

	RF分布のトレンド調査
	画面変更対象か否かでユーザを分類
	Native/Webまではユーザを分類せず全体で見る
	比較視点は,
		(1)画面変化に伴う効果測定, 
		(2)対象ユーザ/非対象ユーザ間の比較

**************************************************************************************/

/****************************************************************

(1/3)Recency分布推移

****************************************************************/
declare @cdate date
declare @sql varchar(max)
set @cdate = cast('2012-12-01' as date)
--print @cdate, convert(varchar, @cdate, 112)
--truncate table norikazu_myapp_recency

while @cdate <= cast(dateadd(day, -2, getdate()) as date)
begin

	set @sql = 'insert into norikazu_myapp_recency '
			+ '	select '
			+ '''' + convert(varchar, @cdate, 112) + ''' as [cdate], '
			+ '		case when right([user_id],1) in(6,7) then 1 when right([user_id],2) in(56,57) then 1 else 0 end as [target_flg], '
			+ '		[recency], '
			+ '		count(distinct [user_id]) as [uu] '
			+ '	from( '
			+ '		select '
			+ '			[user_id], '
			+ '			case '
			+ '				when datediff(day, [last_access],' + '''' + convert(varchar, @cdate, 112) + ''') <= 3 then  + ''01_0-3days'''
			+ '				when datediff(day, [last_access],' + '''' + convert(varchar, @cdate, 112) + ''') <= 7 then  + ''02_4-7days'''
			+ '				when datediff(day, [last_access],' + '''' + convert(varchar, @cdate, 112) + ''') <= 14 then + ''03_8-14days'''
			+ '				when datediff(day, [last_access],' + '''' + convert(varchar, @cdate, 112) + ''') <= 30 then + ''04_15-30days'''
			+ '				when datediff(day, [last_access],' + '''' + convert(varchar, @cdate, 112) + ''') <= 60 then + ''05_31-60days'''
			+ '				when datediff(day, [last_access],' + '''' + convert(varchar, @cdate, 112) + ''') <= 90 then + ''06_61-90days'''
			+ '				else + ''07_91days+ '''
			+ '			end as [recency] '
			+ '		from '
			+ '			[summary].[dbo].[last_login_' + convert(varchar, @cdate, 112) + ']'
			+ '	) t '
			+ '	group by '
			+ '		case when right([user_id],1) in(6,7) then 1 when right([user_id],2) in(56,57) then 1 else 0 end, '
			+ '		[recency] '
	execute(@sql)
	--	
	set @cdate = dateadd(day, 1, @cdate)

end
--32min


/****************************************************************

(2/3)Frequency分布

****************************************************************/
select *
into #norikazu_tmp_app_all
from
(
	select * from summary.dbo.app_all_201302
	union select * from summary.dbo.app_all_201303
	union select * from summary.dbo.app_all_201304
) t
--15min, (254585079 行処理されました)


declare @cdate date
set @cdate = cast('2013-02-15' as date)
while @cdate <= cast(dateadd(day, -2, getdate()) as date)
begin

	insert into
		norikazu_myapp_freq	
	select
		@cdate															as [cdate],
		avg([play_cnt])													as [avg_play_cnt],
		avg(case when [target_flg] = 1 then [play_cnt] else null end)	as [avg_play_cnt_target],
		avg(case when [target_flg] = 0 then [play_cnt] else null end)	as [avg_play_cnt_nontarget],
		avg([app_cnt])													as [avg_app_cnt],
		avg(case when [target_flg] = 1 then [app_cnt] else null end)	as [avg_app_cnt_target],
		avg(case when [target_flg] = 0 then [app_cnt] else null end)	as [avg_app_cnt_nontarget]
	from
	(
		select
			[user_id],
			case when right([user_id],1) in(6,7) then 1 else 0 end as [target_flg],
			count(*)*1.0 as [play_cnt],
			count(distinct [application_id])*1.0 as [app_cnt]
		from
			#norikazu_tmp_app_all
		where
			[date] between dateadd(day, -7, @cdate) and @cdate
		and	[category] in(2,4,16)
		group by
			[user_id]
	) t

	--
	print @cdate
	set @cdate = dateadd(day, 1, @cdate)

end


/****************************************************************

(3/3)Frequency分布 : SP限定

****************************************************************/
select * 
into #norikazu_tmp_app_all
from
(
	select * from summary.dbo.app_all_201302
	union select * from summary.dbo.app_all_201303
	union select * from summary.dbo.app_all_201304
) t
where category = 2
--15min, (207704644 行処理されました)

declare @cdate date
set @cdate = cast('2013-02-15' as date)
while @cdate <= cast(dateadd(day, -2, getdate()) as date)
begin

	insert into
		norikazu_myapp_freq_spweb
	select
		@cdate															as [cdate],
		avg([play_cnt])													as [avg_play_cnt],
		avg(case when [target_flg] = 1 then [play_cnt] else null end)	as [avg_play_cnt_target],
		avg(case when [target_flg] = 0 then [play_cnt] else null end)	as [avg_play_cnt_nontarget],
		avg([app_cnt])													as [avg_app_cnt],
		avg(case when [target_flg] = 1 then [app_cnt] else null end)	as [avg_app_cnt_target],
		avg(case when [target_flg] = 0 then [app_cnt] else null end)	as [avg_app_cnt_nontarget]
	from
	(
		select
			[user_id],
			case when right([user_id],2) in(56,57) then 1 else 0 end as [target_flg],
			count(*)*1.0 as [play_cnt],
			count(distinct [application_id])*1.0 as [app_cnt]
		from
			#norikazu_tmp_app_all
		where
			[date] between dateadd(day, -7, @cdate) and @cdate
		group by
			[user_id]
	) t

	--
	print @cdate
	set @cdate = dateadd(day, 1, @cdate)

end



/*************************************************************************************

	基礎数値の集計用データ収集
	クリックしやすいユーザの特徴(今回は直近未ログイン日数)で最適化へ
	比較軸はapp_top vs. click usersかな

*************************************************************************************/
--(1/2) gamesnet
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[norikazu_myapp_gamesnet]') AND type in (N'U'))
DROP TABLE [dbo].[norikazu_myapp_gamesnet]
select
	*
into
	norikazu_myapp_gamesnet
from
(
	select * from mitsuda_analytics.dbo.log_access_view_gamesnet_201303
	union all select * from mitsuda_analytics.dbo.log_access_view_gamesnet_201304
) t
where
	region = 'JP' 
and(
		query_string like '%ggpmygame=myapp_%'
	or	query_string like '%ggpmygamemyapprecommend%'
	or	query_string like '%ggpmygame=announcement%'
	or	query_string like '%ggpmygame=%'	--設定ミスのため臨時対応
	or	query_string like '%ggpmygame=popularapp_%'
	or	query_string like '%ggpmygame=preregistered_%'
	or	query_string like '%ggppreregister=mygames_%'
	or	query_string like '%ggpmygame=newapp_%'
)
--(222053 行処理されました)


--(2/2) appsnet
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[norikazu_myapp_appsnet]') AND type in (N'U'))
DROP TABLE [dbo].[norikazu_myapp_appsnet]
select
	*
into
	norikazu_myapp_appsnet
from
(
	select * from mitsuda_analytics.dbo.log_access_view_appsnet_201303
	union all select * from mitsuda_analytics.dbo.log_access_view_appsnet_201304
) t
where
	region = 'JP' 
and(
		query_string like '%ggpmygame=myapp_%'
	or	query_string like '%ggpmygamemyapprecommend%'
	or	query_string like '%ggpmygame=announcement%'
	or	query_string like '%ggpmygame=%'	--設定ミスのため臨時対応
	or	query_string like '%ggpmygame=popularapp_%'
	or	query_string like '%ggpmygame=preregistered_%'
	or	query_string like '%ggppreregister=mygames_%'
	or	query_string like '%ggpmygame=newapp_%'
)
--(1170309 行処理されました)
--(1175942 行処理されました)
--(1234704 行処理されました)

select MIN(date)
from mitsuda_analytics.dbo.log_access_view_appsnet_201303
where query_string like '%ggpmygame=%'



select
	[date],
	datepart(year, [record_time])	as [year],
	datepart(month, [record_time])	as [month],
	datepart(day, [record_time])	as [day],
	datepart(hour,[record_time])	as [hour],
	case
		when [query_string] like '%ggpmygame=myapp_more%' then '02_マイアプリもっと見る'
		when [query_string] like '%ggpmygame=myapp_%' then '01_マイアプリ'
		when [query_string] like '%ggpmygame=announcement_more%' then '04_お知らせもっと見る'
		when [query_string] like '%ggpmygame=announcement_%' then '03_お知らせ'		
		when [query_string] like '%ggpmygame=popularapp_%' then '05_友だちに人気のアプリ'
		when [query_string] like '%ggpmygame=preregistered_more%' then '07_事前登録済みもっと見る'
		when [query_string] like '%ggpmygame=preregistered_%' then '06_事前登録済み'
		when [query_string] like '%ggppreregister=mygames_more%' then '09_事前登録中もっと見る'
		when [query_string] like '%ggppreregister=mygames_%' then '08_事前登録中'
		when [query_string] like '%ggpmygame=newapp_more%' then '11_新着もっと見る'
		when [query_string] like '%ggpmygame=newapp_%' then '10_新着'
		when [query_string] like '%ggpmygame=%' then '03_お知らせ'
		else '12_その他不明'
	end as [part],
	count(*) as [clck],
	COUNT(distinct [user_id]) as [click_uu]
into
	norikazu_myapp_click
from
(
	select user_id,query_string,date,record_time from norikazu_myapp_gamesnet
	union
	select user_id,query_string,date,record_time from norikazu_myapp_appsnet
) t
group by
	[date],
	datepart(year, [record_time]),
	datepart(month, [record_time]),
	datepart(day, [record_time]),
	datepart(hour,[record_time]),
	case
		when [query_string] like '%ggpmygame=myapp_more%' then '02_マイアプリもっと見る'
		when [query_string] like '%ggpmygame=myapp_%' then '01_マイアプリ'
		when [query_string] like '%ggpmygame=announcement_more%' then '04_お知らせもっと見る'
		when [query_string] like '%ggpmygame=announcement_%' then '03_お知らせ'		
		when [query_string] like '%ggpmygame=popularapp_%' then '05_友だちに人気のアプリ'
		when [query_string] like '%ggpmygame=preregistered_more%' then '07_事前登録済みもっと見る'
		when [query_string] like '%ggpmygame=preregistered_%' then '06_事前登録済み'
		when [query_string] like '%ggppreregister=mygames_more%' then '09_事前登録中もっと見る'
		when [query_string] like '%ggppreregister=mygames_%' then '08_事前登録中'
		when [query_string] like '%ggpmygame=newapp_more%' then '11_新着もっと見る'
		when [query_string] like '%ggpmygame=newapp_%' then '10_新着'
		when [query_string] like '%ggpmygame=%' then '03_お知らせ'
		else '12_その他不明'
	end



