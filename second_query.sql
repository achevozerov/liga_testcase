/* Тут я уже решил использовать with чтобы не писать нечитаемых подзапросов как в предыдущей задаче */
WITH ClientOrderAdditionalInfoWithOrderType AS (
	/* Без таблицы не очень понятно что такое тестовый заказ, предположу что это что-то вроде OrderType == 'test' */
	SELECT t1."ClientOrderID", t1."code", t1."value", t2."value" orderType
	FROM public."ClientOrderAdditionalInfo" t1
	/* Джойним таблицу на саму себя чтобы проще было отфильтровать тестовые заказы */
	LEFT JOIN public."ClientOrderAdditionalInfo" t2 ON t1."ClientOrderID" = t2."ClientOrderID" AND t2.code = 'OrderType'
	WHERE t1.code = 'Platform'
), 
/* Здесь запрос получает таблицу заказов пользователей с OrderType для фильтрации тестовых заказов */
clients_table_with_test AS (
	SELECT  
		*
	FROM public."ClientOrder" t1
	INNER JOIN ClientOrderAdditionalInfoWithOrderType t2 ON t1."ID" = t2."ClientOrderID"
	/* IS NULL здесь для того чтобы не отбрасывать те заказы где не указан OrderType */
	WHERE t2."ordertype" != 'test' OR t2."ordertype" IS NULL
),
/* В результате этого запроса получаем всех пользователей и все существующие категории+платформы */
CategoriesPlatformsByAllUsers AS (
	SELECT 
		t1."ClientOrderID",
		t1."categoryLvl1",
		t2."value",
		t2."ClientID",
		max(t2."Date") OVER (PARTITION BY t2."ClientID") - min(t2."Date") OVER (PARTITION BY t2."ClientID") as "date_diff"
	FROM public."ClientOrderItems" t1
	INNER JOIN clients_table_with_test t2 ON t1."ClientOrderID" = t2."ID"
),
/* 
	Далее по сути предфинальная таблица с отмеченными рангами пользователей отсортироварованными по возрастанию
	Самый маленький date_diff в паре категории и платформы - 1 место
*/
TableWithRanks AS (
	SELECT 
		t1."categoryLvl1",
		t1."value",
		t1."ClientID",
		rank() OVER (PARTITION BY t1."categoryLvl1", t1."value" ORDER BY t1."date_diff" ASC) user_rank
	FROM CategoriesPlatformsByAllUsers t1
)

SELECT 
	*
FROM TableWithRanks
WHERE "user_rank" <= 3