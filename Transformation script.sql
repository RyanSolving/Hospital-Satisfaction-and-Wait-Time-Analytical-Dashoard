SELECT TOP 5 *
FROM PatientVisit

/* Clean dataset */ 
/* 01: Check for null */ 
SELECT
	COUNT (CASE WHEN date is null THEN 1 END) AS Null_Date,
	COUNT (CASE WHEN patient_id IS NULL THEN 1 END) AS Null_Patient_ID,
	COUNT (CASE WHEN patient_gender IS NULL THEN 1 END) AS Null_patient_gender, 
	COUNT (CASE WHEN patient_sat_score IS NULL THEN 1 END) AS Null_patient_sat_score, 
	COUNT (CASE WHEN patient_first_inital IS NULL THEN 1 END) AS Null_patient_first_inital, 
	COUNT (CASE WHEN patient_last_name IS NULL THEN 1 END) AS Null_patient_last_name, 
	COUNT (CASE WHEN patient_race IS NULL THEN 1 END) AS Null_patient_race, 
	COUNT (CASE WHEN patient_admin_flag IS NULL THEN 1 END) AS Null_patient_admin_flag, 
	COUNT (CASE WHEN patient_waittime IS NULL THEN 1 END) AS Null_patient_waittime, 
	COUNT (CASE WHEN department_referral IS NULL THEN 1 END) AS Null_department_referral
FROM PatientVisit

/* Comment: Patient_sat_score contained the most highest number of null values. Next step: To check whether it's missing at random or missing not at random */ 
-- Check for satisfactory score
SELECT 
	MAX(patient_sat_score) AS Max_score, 
	MIN(patient_sat_score) AS Min_score,
	ROUND((COUNT (CASE WHEN patient_sat_score IS NULL THEN 1 END))/COUNT(*),3) AS Percentage_null
FROM PatientVisit


/* Comment: The score ranged from 0 to 10, and the its null values accounted for small percentage of total rows. 
Next step: It's safe to imputate these null values with median value without causing any further bias.
*/ 
WITH MedianCalculation AS (
	SELECT 
		DISTINCT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY patient_sat_score) OVER() AS MedianValue 
	FROM PatientVisit
	WHERE patient_sat_score IS NOT NULL
)
UPDATE PatientVisit
SET patient_sat_score = (SELECT MedianValue FROM MedianCalculation) 
WHERE patient_sat_score IS NULL


/* 02: Check for duplication */
WITH CountRow AS (
SELECT
	*, 
	ROW_NUMBER() OVER (
		PARTITION BY date, patient_id, patient_first_inital, patient_last_name 
		ORDER BY date) as RowNum
FROM PatientVisit
) 
SELECT
	*
FROM CountRow 
WHERE RowNum > 1

/* Comment: There's no duplication */ 

/* Create column date and timestamp */
ALTER TABLE PatientVisit
ADD
	extract_date DATE NULL, 
	extract_time TIME NULL

UPDATE PatientVisit
SET 
	extract_date = CAST(date as date), 
	extract_time = CAST(date as time)

/* Create new column named "full_name" then delete "first" and "last name" columns*/ 
ALTER TABLE PatientVisit 
ADD 
	patient_full_name NVARCHAR(100) NULL 

UPDATE PatientVisit 
SET 
	patient_full_name = CONCAT(patient_first_inital,' ', patient_last_name) 

ALTER TABLE PatientVisit 
DROP COLUMN 
	patient_first_inital,
	patient_last_name;