
WITH 
	Segmentationfm (CustomerID,Frequency, Monetary ,f_score, m_score )
		AS (
		 SELECT 
			*,NTILE(5) OVER(ORDER BY Count_Transactions ) AS f_score ,
			  NTILE(5) OVER(ORDER BY Profits) AS m_score
		 FROM 
			(
			   SELECT DISTINCT
				  customerid, Count(invoiceno) Over ( Partition by customerid 
								rows between unbounded preceding and unbounded following) AS Count_Transactions,
				  Round(SUM(Quantity*unitprice) Over ( Partition by customerid 
								rows between unbounded preceding and unbounded following)) AS Profits
			   FROM online_retail 
			   WHERE invoiceno NOT LIKE 'C%' 
			) AS X
		 WHERE customerid NOT LIKE ''	
		 )
		 
   ,SegmentationR (CustomerID,Recency,r_score)
		AS (
			 SELECT
			   *, NTILE(5) OVER (ORDER BY Recency DESC) AS r_score 
			 FROM
				(
				  SELECT 
					customerid, ('2011-12-12' - max(to_date(invoicedate, 'MM/DD/YYYY'))) AS Recency 
				  FROM online_retail 
				  WHERE invoiceno NOT LIKE 'C%' 
				  GROUP BY customerid 
				) AS Z
			WHERE customerid NOT LIKE ''
			)
SELECT *, 	CASE WHEN r_score IN(4,5) AND fm_score IN (4,5) THEN 'Champions'
	   	 WHEN (r_score = 5 AND fm_score = 2) OR (r_score = 4 AND fm_score = 2) 
		   	 OR (r_score = 3 AND fm_score = 3) OR (r_score = 4 AND fm_score = 3) THEN 'Potential Loyalists'
		 WHEN (r_score = 5 AND fm_score = 3) OR (r_score = 4 AND fm_score = 4) 
			 OR (r_score = 3 AND fm_score = 5) OR (r_score = 3 AND fm_score = 4) THEN 'Loyal Customers'
		 WHEN r_score = 5 AND fm_score = 1 THEN 'Recent Customers'
		 WHEN r_score IN(3,4) AND fm_score = 1 THEN 'Promising'
		 WHEN (r_score = 3 AND fm_score = 2) OR (r_score = 2 AND fm_score = 3) 
			 OR (r_score = 2 AND fm_score = 2) THEN 'Customers Needing Attention'
		 WHEN (r_score = 2 AND fm_score = 5) OR (r_score = 2 AND fm_score = 4) 
			 OR (r_score = 1 AND fm_score = 3) THEN 'At Risk'
		 WHEN r_score = 1 AND fm_score IN (4,5) THEN 'Cant Lose Them'
		 WHEN r_score = 1 AND fm_score = 2 THEN 'Hibernation'
		 WHEN r_score = 1 AND fm_score = 1 THEN 'Lost'
		 ELSE 'others'
		 END AS Cust_segment 
FROM
  (	
	SELECT Segmentationfm.customerID, Recency, Frequency, Monetary, r_score, ((f_score+m_score)/2) AS fm_score
   
FROM Segmentationfm
JOIN SegmentationR
ON Segmentationfm.customerid = SegmentationR.customerid
	  ) AS N
	  

	  


