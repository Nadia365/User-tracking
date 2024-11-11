/*Tasks Summary:

Consider all users that purchased a subscription plan for the first time between January 1 and March 31, 2023 (inclusive).
Consider all their page interactions before their purchase date.
Remove test users (ones that paid 0 dollars).
Create aliases (nicknames) for the URLs.
Combine all the pages of each session into a single user journey string.
Export all this data as a CSV with the user_id, session_id, subscription_type, and user journey
*/ 

-- Explore the content of the databases 
SELECT *
FROM front_interactions 
LIMIT 10;

-- 
SELECT *
FROM front_visitors 
ORDER BY user_id ; 
-- 
SELECT count(*)
FROM student_purchases
ORDER BY user_id; 
-- 

/*Consider all users that purchased a subscription plan for the first time between January 1 and March 31, 2023 (inclusive).
 You can even filter out the test users (those with purchase_price of 0) directly here, considering only the
 relevant date ranges. This query should have four columns: user_id, first_purchase_date, subscription_type 
 (you can apply the actual names "Monthly", "Quarterly" and "Annual" to the numerical codes here, for clarity) 
 and purchase_price. Consider how your filtering interacts with grouping. */  
 -- 0=Monthly, 1=Quarterly, 2=Annual
 SET SESSION group_concat_max_len = 10000;
 WITH paid_users_1 AS ( 
	SELECT user_id, CAST( date_purchased AS DATE) AS first_purchase_date, 
	purchase_type,
	CASE
        WHEN purchase_type =0 THEN "Monthly"
        WHEN purchase_type =1 THEN "Quaterly"
        WHEN purchase_type =2 THEN "Annual"
        ELSE 'None'
    END AS subscription_type,
	purchase_price
	FROM student_purchases) , 
 paid_users_2 AS (
	SELECT user_id, min(first_purchase_date) AS min_purchase_date
	FROM paid_users_1
	GROUP  BY user_id
	HAVING  min_purchase_date between '2023-01-01' AND '2023-03-31')
SELECT *
FROM paid_users_1 pu1
INNER JOIN paid_users_2 pu2
ON pu1.user_id=pu2.user_id;
-- The next common table expression in the CTE structure can take all the users from the first query and
-- extract all the relevant entries from the front_interactions table. (Recall that in a statement with a
-- WITH clause, you can use all the above subqueries directly in the current one.) I would consider all 
-- columns from the interactions table except the event_name which is not relevant for this query. 
-- Be sure to include only the events before the user subscribes for the first time.
SELECT user_id, session_id,subscription_type,GROUP_CONCAT(full_name_pages SEPARATOR '-') AS user_jounrey 
FROM 
(WITH paid_users_1 AS ( 
	SELECT user_id, CAST( date_purchased AS DATE) AS first_purchase_date, 
	purchase_type,
	CASE
        WHEN purchase_type =0 THEN "Monthly"
        WHEN purchase_type =1 THEN "Quaterly"
        WHEN purchase_type =2 THEN "Annual"
        ELSE 'None'
    END AS subscription_type,
	purchase_price
	FROM student_purchases) , 
paid_users_2 AS (
	SELECT user_id, min(first_purchase_date) AS min_purchase_date
	FROM paid_users_1
	GROUP  BY user_id
	HAVING  min_purchase_date between '2023-01-01' AND '2023-03-31'),
paid_users3 AS (
	SELECT pu1.user_id, pu1.first_purchase_date , pu1.subscription_type, pu1.purchase_price 
	FROM paid_users_1 pu1
	INNER JOIN paid_users_2 pu2
	ON pu1.user_id=pu2.user_id),
paid_users_4 AS (
	SELECT pu3.user_id, pu3.first_purchase_date, pu3.subscription_type,pu3.purchase_price, 
	fi.event_destination_url, fi.event_source_url, CAST(fi.event_date AS date) as new_event_date, fi.session_id
	FROM paid_users3 pu3
    INNER JOIN front_visitors fv ON fv.user_id=pu3.user_id 
	INNER JOIN front_interactions AS fi
	ON fi.visitor_id=fv.visitor_id 
    WHERE
	fi.event_date < pu3.first_purchase_date),
paid_users_5 AS
(SELECT user_id, first_purchase_date,subscription_type,purchase_price,new_event_date,session_id,
event_source_url,
CASE 
	WHEN event_source_url='https://365datascience.com/' THEN 'Homepage' 
	WHEN event_source_url LIKE '%login%' THEN SUBSTRING_INDEX(SUBSTRING_INDEX(event_source_url,'/',-2),'/',1)
	WHEN event_source_url LIKE '%signup%' THEN SUBSTRING_INDEX(SUBSTRING_INDEX(event_source_url,'/',-2),'/',1)
	WHEN event_source_url LIKE '%resource%' THEN  SUBSTRING_INDEX(SUBSTRING_INDEX(event_source_url,'/',-2),'/',1)
	 WHEN event_source_url LIKE '%course%' THEN  SUBSTRING_INDEX(SUBSTRING_INDEX(event_source_url,'/',-2),'/',1)
	WHEN event_source_url LIKE '%career%' THEN    SUBSTRING_INDEX(SUBSTRING_INDEX(event_source_url,'/',-2),'/',1)
	WHEN event_source_url LIKE '%success%' THEN   SUBSTRING_INDEX(SUBSTRING_INDEX(event_source_url,'/',-2),'/',1)
	WHEN event_source_url LIKE '%pricing%' THEN   SUBSTRING_INDEX(SUBSTRING_INDEX(event_source_url,'/',-2),'/',1)
	WHEN event_source_url LIKE '%about%' THEN     SUBSTRING_INDEX(SUBSTRING_INDEX(event_source_url,'/',-2),'/',1)
    WHEN event_source_url LIKE '%instructors%' THEN  SUBSTRING_INDEX(SUBSTRING_INDEX(event_source_url,'/',-2),'/',1)
    WHEN event_source_url LIKE '%checkout%' AND event_source_url LIKE '%coupon%'   THEN 'Coupon'
    WHEN event_source_url LIKE '%checkout%' AND event_source_url NOT LIKE '%coupon%'   THEN SUBSTRING_INDEX(SUBSTRING_INDEX(event_source_url,'/',-2),'/',1)
    ELSE 'Others' 
    END AS event_source_url_nickname ,
event_destination_url,
CASE 
	WHEN event_destination_url='https://365datascience.com/' THEN 'Homepage' 
	WHEN event_destination_url LIKE '%login%' THEN SUBSTRING_INDEX(SUBSTRING_INDEX(event_destination_url,'/',-2),'/',1)
	WHEN event_destination_url LIKE '%signup%' THEN SUBSTRING_INDEX(SUBSTRING_INDEX(event_destination_url,'/',-2),'/',1)
	WHEN event_destination_url LIKE '%resource%' THEN  SUBSTRING_INDEX(SUBSTRING_INDEX(event_destination_url,'/',-2),'/',1)
	 WHEN event_destination_url LIKE '%course%' THEN  SUBSTRING_INDEX(SUBSTRING_INDEX(event_destination_url,'/',-2),'/',1)
	WHEN event_destination_url LIKE '%career%' THEN    SUBSTRING_INDEX(SUBSTRING_INDEX(event_destination_url,'/',-2),'/',1)
	WHEN event_destination_url LIKE '%success%' THEN   SUBSTRING_INDEX(SUBSTRING_INDEX(event_destination_url,'/',-2),'/',1)
	WHEN event_destination_url LIKE '%pricing%' THEN   SUBSTRING_INDEX(SUBSTRING_INDEX(event_destination_url,'/',-2),'/',1)
	WHEN event_destination_url LIKE '%about%' THEN     SUBSTRING_INDEX(SUBSTRING_INDEX(event_destination_url,'/',-2),'/',1)
    WHEN event_destination_url LIKE '%instructors%' THEN  SUBSTRING_INDEX(SUBSTRING_INDEX(event_destination_url,'/',-2),'/',1)
    WHEN event_destination_url LIKE '%checkout%' AND event_destination_url LIKE '%coupon%'   THEN 'Coupon'
    WHEN event_destination_url LIKE '%checkout%' AND event_destination_url NOT LIKE '%coupon%'   THEN SUBSTRING_INDEX(SUBSTRING_INDEX(event_destination_url,'/',-2),'/',1)
    ELSE 'Others' 
    END AS event_destination_url_nickname 
FROM paid_users_4 )
SELECT * , CONCAT(event_destination_url_nickname , '-', event_destination_url_nickname ) AS full_name_pages
FROM paid_users_5)  
AS t1
GROUP BY user_id , session_id, subscription_type 
ORDER BY user_id ASC, session_id ;


   
 -- 
