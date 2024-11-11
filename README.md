# Extracting User Journey Data Using SQL Project
This case study is contained within the [Skill Track project](https://learn.365datascience.com/) 
## 📕 **Table of contents**
<!--ts-->
   * 🛠️ [Overview](#️-overview)
   * 🚀 [Solutions](#-solutions)
   * 💻 [Key Highlights](#-key-highlight)
     
## 🛠️ Overview
With the **Extracting User Journey Data Case Study**, I queried data to bring insights to the following questions:
1. Consider all users that purchased a subscription plan for the first time between January 1 and March 31, 2023 (inclusive).
2. Consider all their page interactions before their purchase date.
3. Remove test users (ones that paid 0 dollars).
4. Create aliases (nicknames) for the URLs.
5. Combine all the pages of each session into a single user journey string.
6. Export all this data as a CSV with the user_id, session_id, subscription_type, and user journey

## 🛠️ Overview of the dataset
The database you’ll work with consists of three tables: **front_interactions** , **student_purchases** , and **front_visitors**.

The front_interactions  table records all visitor activity on the company’s front page, including visiting specific pages, clicks, and other interactions on said pages. The table consists of the following six fields or columns:

 -visitor_id  – (int) the ID number of the visitor
 -session_id  – (int) the session number during which the interaction took place
 -event_source_url  – (string) the URL of the page on which the given event took place
 -event_destination_url   – (string) the URL of the page when the event was completed/processed (for interactions during which the user stays on the same page, this is the same as source URL)
 -event_date   – (datetime) the exact timestamp of the event/interaction
 -event_name   – (string) an internal name of the event 


The next table is student_purchases  which contains records of user payments and the type of product they purchased. This includes all payments—even if they are subsequent recurring payments for the same subscription. Its columns contain the following:

-user_id   – (int) the ID of the user, different from the visitor_id
-purchase_id   – (int) the ID of the purchase
-purchase_type   – (int) the type of subscription purchased (0=monthly, 1=quarterly, 2=annual)
-purchase_price   – (decimal) the price the user paid in dollars
-date_purchased   – (datetime) the exact datetime of the purchase

The final table front_visitors  is the link between front_interactions and student_purchases. There are only two columns in this table:

-visitor_id   – (int) the ID of the visitor—each record has this field filled in
-user_id   – (int) the ID of the user corresponding to this visitor—many NULL values here because many visitors never made an account and so were never assigned a user_id 

## 🚀 Solutions
We will apporach this project with  WITH clause (common table expression), for the sake of a clean and readable code. 
First of all we set group_concat_max_len to 100000 to increase this limit. 
SET SESSION group_concat_max_len = 100000; 
![Question 1](https://img.shields.io/badge/Question-1-971901) 
Now comes the main query with the first subquery: paid_users. This one aims to extract all users eligible for the user journey analysis while excluding test users. Since all relevant users have purchased a subscription, I only need to look at the student_purchases table. 
```sql
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
	HAVING  min_purchase_date between '2023-01-01' AND '2023-03-31'),
paid_users3 AS (
	SELECT pu1.user_id, pu1.first_purchase_date , pu1.subscription_type, pu1.purchase_price 
	FROM paid_users_1 pu1
	INNER JOIN paid_users_2 pu2
	ON pu1.user_id=pu2.user_id)
```

Next is table_interactions. As the name suggests, this query aims to take the list of all relevant users I just described and obtain a list of all the relevant interactions they had with the front page. This data should be taken from the front_interactions table.
```sql
paid_users_4 AS (
	SELECT pu3.user_id, pu3.first_purchase_date, pu3.subscription_type,pu3.purchase_price, 
	fi.event_destination_url, fi.event_source_url, CAST(fi.event_date AS date) as new_event_date, fi.session_id
	FROM paid_users3 pu3
    INNER JOIN front_visitors fv ON fv.user_id=pu3.user_id 
	INNER JOIN front_interactions AS fi
	ON fi.visitor_id=fv.visitor_id 
    WHERE
	fi.event_date < pu3.first_purchase_date

```

The following query is table_aliases, where we rename the URLs of the pages to simple keywords like Homepage or Pricing. 
```sql
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
```

At this point, we have managed to create a list of the relevant interactions of every user. It contains the session ID during which the current interaction happens, the subscription type the user purchased, and the source and destination pages for this particular interaction. These pages are combined into one big string for every session using CONCAT() and GROUP_CONCAT() to concant the pages visited per session.
