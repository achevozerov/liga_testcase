/* В основном запросе превращаем столбец с разницей даты для каждого клиента в скаляр со средним значением */
SELECT AVG(date_diff) as "mean_date_diff"
FROM (
	/* Во втором подзапросе считаем разницу в датах между первым и вторым заказом по каждому клиенту*/
	SELECT  
		DISTINCT max("Date") OVER (PARTITION BY "ClientID") - min("Date") OVER (PARTITION BY "ClientID") as "date_diff"
	FROM (
		/* Первый подзапрос используем для нумерации номера заказа по клиенту */
		SELECT 
			"ID", 
			"Date", 
			"ClientID",
			row_number() OVER (PARTITION BY "ClientID" ORDER BY "Date" DESC) AS "row_num"
		FROM public."ClientOrder"
	) as t2
	WHERE "row_num" < 3
) as t3
