-- Check Replication for missing columns. 
	declare 
		@CurrentExtractID int = 1,
		@CurrentPublication nvarchar(255),
		@PublisherDB nvarchar(255),
		@CurrentArticle nvarchar(255),
		@sqlcmd nvarchar(max);
 
	declare @Articles table (
		ExtractID int identity(1,1) not null,
		ServerName nvarchar(255),
		Publication nvarchar(255),
		PublisherDB nvarchar(255),
		Article nvarchar(255)
	);
 
	declare @ArticleColumns table (
		ExtractID int,
		ColumnID int,
		ColumnName sysname,
		Published bit,
		PublisherType sysname,
		SubscriberType sysname
	);
 
	set nocount on;
 
	insert into @Articles (ServerName, Publication, PublisherDB, Article)
	select 
		ss.srvname,
		p.publication,
		a.publisher_db,
		a.article
	from distribution.dbo.MSpublications p
	inner join distribution.dbo.MSarticles a on (
		a.publisher_id = p.publisher_id
		and a.publication_id = p.publication_id
		and a.publisher_db = p.publisher_db
	)
	inner join master.dbo.sysservers ss on (ss.srvid = p.publisher_id)
	order by 
		ss.srvname,
		p.publication,
		a.publisher_db,
		a.article;
 
	while (@CurrentExtractID <= (select count(*) from @Articles))
	begin
		select @CurrentPublication = Publication, @PublisherDB = PublisherDB, @CurrentArticle = Article from @Articles where ExtractID = @CurrentExtractID;
 
		begin try
			set @sqlcmd = 'exec [' + @PublisherDB + '].dbo.sp_helparticlecolumns @publication = ''' + @CurrentPublication + ''', @article = ''' + @CurrentArticle + ''';';
			insert into @ArticleColumns (ColumnID, ColumnName, Published, PublisherType, SubscriberType)
			exec sp_executesql @sqlcmd;
			update @ArticleColumns set ExtractID = @CurrentExtractID where ExtractID is null;
			print 'Extracted detail from: ' + @CurrentPublication + ', Article: ' + @CurrentArticle;
		end try
		begin catch
			print 'Unable to extracted detail from: ' + @CurrentPublication + ', Article: ' + @CurrentArticle;
		end catch
		set @CurrentExtractID = @CurrentExtractID + 1;
	end
 
	select 
		a.ServerName,
		a.Publication,
		a.PublisherDB, 
		a.Article,
		ac.ColumnName,
		ac.Published
	from @Articles a
	left join @ArticleColumns ac on (a.ExtractID = ac.ExtractID)
	-- where ac.Published = 0 -- Show only missing columns
	order by isnull(ac.Published, 2), a.ExtractID;
 
	set nocount off;