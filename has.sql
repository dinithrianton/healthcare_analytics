-- Linkedin Learning | SQL for Healthcare Professionals | Final Project: Healthcare Analytics Scenario


-- Demographics and Diagnosis Scenario 
WITH demos AS
(
SELECT Patients.patient_id, (strftime('%Y','now') - strftime('%Y',date_of_birth)) - (strftime('%m-%d','now') < strftime('%m-%d',date_of_birth)) AS age, gender, diagnosis
FROM Patients
INNER JOIN Outpatient_Visits
ON Patients.patient_id = Outpatient_Visits.patient_id
)

SELECT 
CASE
WHEN age BETWEEN 0 AND 17 THEN 'Pediatric'
WHEN age BETWEEN 18 AND 64 THEN 'Adult'
WHEN age > 64 THEN 'Senior'
END AS age_group,
gender, diagnosis, COUNT(patient_id) AS patient_count
FROM demos
GROUP BY age_group, gender, diagnosis

SELECT age_group, gender, diagnosis, patient_count, SUM(patient_count) OVER(PARTITION BY diagnosis) as total_diagnosed, ROUND(CAST(patient_count AS FLOAT) / CAST(SUM(patient_count) OVER(PARTITION BY diagnosis) AS FLOAT) * 100,1) AS percentage_diagnosed
FROM patient_demos


-- Appointments Scenario
SELECT strftime('%H',appointment_time) as hour_of_day, COUNT(visit_id) AS appointment_count
FROM Appointments
WHERE hour_of_day IS NOT NULL
GROUP BY hour_of_day
ORDER BY appointment_count DESC

SELECT hour_of_day, appointment_count, ROUND(CAST(appointment_count AS FLOAT) / CAST(SUM(appointment_count) OVER() AS FLOAT) * 100,1) AS percentage_count, RANK() OVER(ORDER BY appointment_count DESC) as activity_rank
FROM app_times


-- Laboratory Scenario
SELECT test_name, COUNT(result_id) as test_count
FROM Lab_Results  
GROUP BY test_name
ORDER BY test_count DESC

SELECT test_name, test_count, ROUND(CAST(test_count AS FLOAT) / CAST(SUM(test_count) OVER() AS FLOAT) * 100,1) AS test_percentage, RANK() OVER(ORDER BY test_count DESC) as order_rank
FROM tests 


-- Laboratory with Risk Scenario
SELECT Patients.patient_id, patient_name, test_date, result_value
FROM Patients
INNER JOIN Outpatient_Visits
ON Patients.patient_id = Outpatient_Visits.patient_id
INNER JOIN Lab_Results
ON Outpatient_Visits.visit_id = Lab_Results.visit_id
WHERE test_name = 'Fasting Blood Sugar' AND (result_value < 70 OR result_value > 100)
ORDER BY test_date

SELECT patient_id, patient_name, result_value, test_date, lag(test_date,1) OVER(PARTITION BY patient_id) AS last_test_date,
CASE 
WHEN lag(test_date,1) OVER(PARTITION BY patient_id) IS NOT NULL THEN lag(result_value,1) OVER(PARTITION BY patient_id) 
END AS last_result_value, 
ROUND(result_value - lag(result_value,1) OVER(PARTITION BY patient_id),2) AS result_difference,
CASE WHEN result_value < 70 THEN 'Low Blood Sugar'
WHEN result_value > 100 THEN 'High Blood Sugar'
END AS result_condition
FROM blood_sugar
ORDER BY patient_name


-- Risk Scenario
SELECT
CASE
WHEN smoker_status = 'Y' AND (diagnosis = 'Hypertension' OR diagnosis = 'Diabetes') THEN 'High Risk'
WHEN smoker_status = 'N' AND (diagnosis = 'Hypertension' OR diagnosis = 'Diabetes') THEN 'Medium Risk'
ELSE 'Low Risk'
END AS risk_category,
COUNT(Patients.patient_id) AS patient_count
FROM Patients
INNER JOIN Outpatient_Visits
ON Patients.patient_id = Outpatient_Visits.patient_id
GROUP BY risk_category

SELECT risk_category, patient_count, ROUND(CAST(patient_count AS FLOAT) / CAST(SUM(patient_count) OVER() AS FLOAT) * 100,1) AS percentage
FROM risks


-- Readmission Scenario
SELECT initial.patient_id as patient_id, initial.visit_date as initial_visit_date, initial.reason_for_visit as initial_reason_for_visit, read.visit_date as read_visit_date, read.reason_for_visit as read_reason_for_visit, CAST(julianday(read.visit_date) - julianday(initial.visit_date) AS INT) AS gap_in_days
FROM
Outpatient_Visits initial 
INNER JOIN Outpatient_Visits read
ON initial.patient_id = read.patient_id
WHERE julianday(read.visit_date) > julianday(initial.visit_date) AND (julianday(read.visit_date) - julianday(initial.visit_date) <=30)

SELECT patient_id, initial_visit_date, initial_reason_for_visit, read_visit_date, read_reason_for_visit, gap_in_days, gap_in_days - CAST(AVG(gap_in_days) OVER()AS INT) AS deviation_from_average 
FROM read







