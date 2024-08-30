## full_analysis.sql ##
--- The E-mail tab date format from the CSV and transferred incorrectly as string and causing issues converting. Need to extract the date from string, convert to Timestamp then into Date and then covert to match

CREATE OR REPLACE TABLE `my-sql-projects-432315.Novart_Project.E-mail_converted` AS
SELECT
    Rep,
    `Detail Group`,
    `Status Open`,
    `Status Click`,
    PARSE_DATE('%m/%d/%y', FORMAT_TIMESTAMP('%m/%d/%y', TIMESTAMP(`Sent Date`))) AS `Sent Date`,
    `Account: External ID`
FROM `my-sql-projects-432315.Novart_Project. E-mail`; ## UPDATED DATE COLUMN FORMATTING

## Updating EVENTS table DATE formatting 

CREATE OR REPLACE TABLE `my-sql-projects-432315.Novart_Project.Events_converted` AS
SELECT 
    Brand
    ,`Event: Event Type`
    ,`Event: Location`
    ,PARSE_DATE('%m/%d/%y', FORMAT_TIMESTAMP('%m/%d/%y', TIMESTAMP(`Event: End Time`))) AS`Event: End Time`
    ,Role
FROM `my-sql-projects-432315.Novart_Project.Events`;  --note: all tables updated to correct DATE format--

## checking unique primary key in Calls table ##

SELECT COUNT (*) AS `Account ID`
,Brand
,`Call Method`

FROM `my-sql-projects-432315.Novart_Project.Calls`
GROUP BY Brand, `Call Method`
HAVING `Account ID` >=1;

SELECT
COUNT (DISTINCT `Account ID`) AS AccountID
,Brand
,`Call Method`

FROM `my-sql-projects-432315.Novart_Project.Calls`
GROUP BY Brand, `Call Method`
HAVING AccountID >=1;
-- multiple account ids so not unique -- good results to highlight spread of activity --

## breakdown for brand and call method using COUNT ##

SELECT 
    Brand,
    `Call Method`,
    COUNT(*) AS total_calls
FROM 
    `my-sql-projects-432315.Novart_Project.Calls`
GROUP BY 
    Brand, `Call Method`
ORDER BY 
    Brand, `Call Method`;


## breakdown for Events table using COUNT

SELECT 
Brand
,`Event: Event Type`
,`Event: Location`
,Role
,COUNT (*) AS total_events
FROM `my-sql-projects-432315.Novart_Project.Events_converted` 
GROUP BY 
Brand
,`Event: Event Type`
,`Event: Location`
,Role
ORDER BY
Brand
,`Event: Event Type`
,`Event: Location`
,Role;

--Good results but could clean up Event Location ONLINE -- 

SELECT 
    Brand,
    `Event: Event Type`,
    CASE 
        WHEN LOWER(`Event: Location`) LIKE '%online%' THEN 'Online'
        WHEN LOWER(`Event: Location`) LIKE '%ms teams%' THEN 'Online'
        WHEN LOWER(`Event: Location`) LIKE '%mst%' THEN 'Online'
        ELSE `Event: Location`
    END AS `Standardized Location`,
    Role,
    COUNT(*) AS total_events
FROM 
    `my-sql-projects-432315.Novart_Project.Events_converted`
GROUP BY 
    Brand,
    `Event: Event Type`,
    `Standardized Location`,
    Role
ORDER BY 
    Brand,
    `Event: Event Type`,
    `Standardized Location`,
    Role;

# To analyse the results for emails,the main challenge is the lack of a Brand column in the E-mail_converted table, which is preventing making direct comparisons with the Calls table. 
## Additionally, the Impact Score table isn’t providing clarity either.
### Joining the Calls and E-mail_converted tables based on Rep and Account ID seems the best approach to associate the Brand from the Calls table with the corresponding records in the E-mail_converted table. 

CREATE OR REPLACE TABLE `my-sql-projects-432315.Novart_Project.E-mail_with_brand` AS
SELECT 
    e.Rep,
    c.Brand,
    e.`Detail Group`,
    e.`Status Open`,
    e.`Status Click`,
    e.`Sent Date`,
    e.`Account: External ID` AS `Account ID`
FROM 
    `my-sql-projects-432315.Novart_Project.E-mail_converted` e
INNER JOIN 
    `my-sql-projects-432315.Novart_Project.Calls` c
ON 
    e.Rep = c.Rep 
    AND e.`Account: External ID` = c.`Account ID`; # created new table E-mail_with_brand. Used INNER JOIN to remove NULL values . 4747 email records that do not have a corresponding match in the Calls table are irrelevant as Brand unavailable to analyse, therefore removed 

# TOTAL EMAILS BY BRAND 

SELECT 
Brand
,COUNT (*) AS total_emails
FROM `my-sql-projects-432315.Novart_Project.E-mail_with_brand`
GROUP BY Brand
ORDER BY Brand; #saved query total_emails_by_brand

# Compare Emails and Calls by Brand

SELECT 
Brand
,SUM(total_calls) AS total_calls
,SUM(total_emails) AS total_emails
FROM ( #subquery for calls

    SELECT 
        Brand
        ,COUNT(*) AS total_calls
        ,0 AS total_emails
        FROM `my-sql-projects-432315.Novart_Project.Calls`
        GROUP BY Brand

    UNION ALL
        --subquery for E-mail

        SELECT
        Brand
        ,0 AS total_calls
        ,COUNT (*) AS total_emails
        FROM `my-sql-projects-432315.Novart_Project.E-mail_with_brand`
        GROUP BY Brand
)
GROUP BY Brand
ORDER BY Brand
;

--- Now working on the events table -- count events by brand and type

SELECT 
Brand
,`Event: Event Type`
,COUNT(*) AS total_events
FROM `my-sql-projects-432315.Novart_Project.Events`
GROUP BY Brand,`Event: Event Type`
ORDER BY Brand,`Event: Event Type`; #saved query as total_events_by_brand_and_type

--Query to Analyze Events Over Time -- Time Analysis

SELECT
Brand
,EXTRACT(MONTH FROM `Event: End Time`) AS event_month
,COUNT (*) AS total_events
FROM `my-sql-projects-432315.Novart_Project.Events_converted` 
GROUP BY Brand, event_month
ORDER BY Brand, event_month; #saved query as total_events_over_time

---Non-Personal table: Digital Engagement - Portal Conversion ---

SELECT
Brand
,SUM(CASE WHEN `Activity Method grouped`= 'Portal Visitors' THEN Count ELSE 0 END) AS total_visits
,SUM(CASE WHEN `Activity Method grouped` = 'Portal Conversion' THEN Count ELSE 0 END) AS total_conversions
FROM `my-sql-projects-432315.Novart_Project.Non_personal` 
GROUP BY Brand
ORDER BY Brand; #saved query as total_portal_conversions

--Digital Engagement: Summary of Overall Non-Personal Engagement (incl e-mails)--

SELECT
Brand
,`Activity Method grouped`
,SUM(Count) AS total_interactions
FROM `my-sql-projects-432315.Novart_Project.Non_personal` 
GROUP BY Brand, `Activity Method grouped`
ORDER BY Brand, `Activity Method grouped`; #saved query as Summary_Non-Personal_DigitalEngagement