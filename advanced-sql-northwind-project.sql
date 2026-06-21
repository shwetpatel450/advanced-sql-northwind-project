SELECT * FROM categories;
SELECT * FROM customers;
SELECT * FROM employees;
SELECT * FROM `order-details`;
SELECT * FROM orders;
SELECT * FROM products;
SELECT * FROM shippers;
SELECT * FROM suppliers;

-- 1.Show all products that are discontinued but still have units in stock. 

SELECT * FROM products
WHERE Discontinued = 1
AND UnitsInStock > 0;

-- 2.Find the top 10 most expensive products that are not discontinued. 

SELECT ProductName, UnitPrice
FROM Products
WHERE Discontinued = 0
ORDER BY UnitPrice DESC
LIMIT 10; 

-- 3.Display customer names along with the number of distinct countries they belong to. 

SELECT Companyname, COUNT(DISTINCT country)AS num_country
FROM customers
GROUP BY Companyname;

-- 4.Find employees who were hired after 1992 and are older than 50 years (based on birthdate). 

SELECT EmployeeID,
       FirstName,
       LastName
FROM Employees
WHERE STR_TO_DATE(HireDate, '%d-%m-%Y') > '1992-12-31'
  AND TIMESTAMPDIFF(
        YEAR,
        STR_TO_DATE(BirthDate, '%d-%m-%Y'),
        CURDATE()
      ) > 50;
      
-- 5.Show orders that were shipped after the required date.

SELECT *
FROM Orders
WHERE STR_TO_DATE(ShippedDate, '%d-%m-%Y')
      > STR_TO_DATE(RequiredDate, '%d-%m-%Y');

-- 6.Find the total number of orders placed in each quarter of 1996. 

SELECT
    QUARTER(STR_TO_DATE(OrderDate, '%d-%m-%Y')) AS Quarter,
    COUNT(*) AS TotalOrders
FROM Orders
WHERE YEAR(STR_TO_DATE(OrderDate, '%d-%m-%Y')) = 1996
GROUP BY QUARTER(STR_TO_DATE(OrderDate, '%d-%m-%Y'))
ORDER BY Quarter;

-- 7.Show the average freight cost per shipper for orders shipped to Germany. 

SELECT o.shipName,
       AVG(o.Freight) AS avg_freight
FROM Orders o
JOIN Shippers s
    ON o.ShipVia = s.ShipperID
WHERE o.ShipCountry = 'Germany'
GROUP BY o.shipName;
  
-- 8.Find customers who have placed orders in all three years (1996, 1997, 1998). 

SELECT CustomerID
FROM Orders
WHERE YEAR(STR_TO_DATE(OrderDate, '%d-%m-%Y')) IN (1996, 1997, 1998)
GROUP BY CustomerID
HAVING COUNT(DISTINCT YEAR(STR_TO_DATE(OrderDate, '%d-%m-%Y'))) = 3;

-- 9.Display product names that contain both 'ch' and 'ee' in their name. 

	SELECT productName
	FROM products
	WHERE productName LIKE '%ch%'
		AND productName LIKE '%ee%';

-- 10.Show the total revenue generated from each category in 1997. 

SELECT c.CategoryName, ROUND(SUM(od.UnitPrice * od.Quantity), 2)as Total_revenue
FROM categories as c 
	JOIN products as p
    ON p.CategoryID = c.CategoryID
    JOIN `order-details` as od
    ON od.productID = p.ProductID
    JOIN orders as o
    ON o.orderID = od.orderID
WHERE YEAR(str_to_date(o.orderDate, '%d-%m-%Y')) = 1997
Group by c.CategoryName;

-- 11.Find the employee who handled the highest number of orders in 1996. 

SELECT e.EmployeeID,
       e.FirstName,
       e.LastName, 
       COUNT(*)as Num_order
FROM employees as e
	JOIN orders as o
    ON o.employeeID = e.EmployeeID
WHERE YEAR(str_to_date(o.orderDate, '%d-%m-%Y')) = 1996
GROUP BY e.EmployeeID, e.FirstName, e.LastName
ORDER By COUNT(*) DESC
LIMIT 1;

-- 12.Show all orders where freight is higher than the average freight of all orders. 

SELECT orderID, freight
FROM orders
WHERE freight > 
	(SELECT AVG(freight) 
	FROM orders);
    
-- 13.Find products that have never been ordered by customers from France. 

SELECT ProductName
FROM Products
WHERE ProductID NOT IN (
    SELECT DISTINCT od.ProductID
    FROM `Order-Details` od
    JOIN Orders o
        ON o.OrderID = od.OrderID
    JOIN Customers c
        ON c.CustomerID = o.CustomerID
    WHERE c.Country = 'France'
);

-- 14.Display the top 5 customers by total spending in the year 1997. 

SELECT c.customerID, SUM(od.UnitPrice * od.quantity)as total_spend
FROM customers as c
	JOIN orders as o
    ON o.customerID = c.CustomerID
    JOIN `order-details` as od
    ON od.orderID = o.orderID
WHERE YEAR(str_to_date(o.orderDate, '%d-%m-%Y')) = 1997
GROUP BY c.CustomerID
ORDER By total_spend DESC
LIMIT 5;

-- 15.Show the difference between order date and shipped date for all orders (in days). 

SELECT orderDate, shippedDate, 
ABS(DATEDIFF(STR_TO_DATE(orderDate, '%d-%m-%Y'),
	STR_TO_DATE(shippedDate, '%d-%m-%Y')))AS day_diff
FROM orders;

-- 16.Find customers who placed more than 20 orders but have never ordered 'Chai'. 

SELECT o.CustomerID
FROM Orders o
GROUP BY o.CustomerID
HAVING COUNT(DISTINCT o.OrderID) > 20
   AND o.CustomerID NOT IN (
       SELECT DISTINCT o.CustomerID
       FROM Orders o
       JOIN `Order-Details` od
           ON o.OrderID = od.OrderID
       JOIN Products p
           ON od.ProductID = p.ProductID
       WHERE p.ProductName = 'Chai'
);

-- 17.Show the ranking of products based on total units sold across all orders. 

SELECT ProductName,
       Total_Unit,
       DENSE_RANK() OVER (ORDER BY Total_Unit DESC) AS rnk
FROM (
    SELECT p.ProductName,
           SUM(od.Quantity) AS Total_Unit
    FROM Products p
    JOIN `Order-Details` od
        ON od.ProductID = p.ProductID
    GROUP BY p.ProductID, p.ProductName
) t
ORDER BY rnk;

-- 18.Find the second highest selling product in each category.

WITH cte AS(SELECT ProductName, CategoryName,
	DENSE_RANK() 
    OVER(PARTITION BY categoryName 
		Order by Total_unit DESC)as rnk
	FROM (
		SELECT p.productName,c.categoryName,
		SUM(od.quantity)as Total_Unit
		FROM categories as c
			JOIN products as p
			ON p.CategoryID = c.CategoryID
			JOIN `order-details` as od
			ON od.productID = p.ProductID
		GROUP BY p.ProductName,c.CategoryName
	)t
)

SELECT * 
FROM cte
WHERE rnk = 2;

-- 19.Show employees and their manager's name (use self join). 

SELECT 
    e.EmployeeID,
    e.FirstName AS Employee_FirstName,
    e.LastName AS Employee_LastName,
    m.FirstName AS Manager_FirstName,
    m.LastName AS Manager_LastName
FROM Employees e
LEFT JOIN Employees m
    ON e.ReportsTo = m.EmployeeID;
    
-- 20.Display the running total of freight cost per customer ordered by order date. 

SELECT 
    CustomerID,
    OrderID,
    Freight,
    SUM(Freight) OVER (
        PARTITION BY CustomerID
        ORDER BY STR_TO_DATE(OrderDate, '%d-%m-%Y'), OrderID
    ) AS Running_Total_Freight
FROM Orders;

-- 21.Find orders that were placed on the last day of any month. 

SELECT orderID
FROM orders 
WHERE STR_TO_DATE(orderDate, '%d-%m-%Y') = LAST_DAY(STR_TO_DATE(OrderDate, '%d-%m-%Y'));


-- 22.Show the percentage contribution of each shipper in total freight charges. 

SELECT s.companyName,ROUND(SUM(o.freight), 2)as total_charge,
	ROUND(SUM(o.freight)*100/SUM(SUM(o.freight))OVER(), 2)as con_percentage
    FROM shippers as s
    JOIN orders as o
    ON o.shipVia = s.ShipperID
GROUP BY s.ShipperID, s.CompanyName;


-- 23.Find products whose price is higher than the average price of all products in their category. 

SELECT ProductName,
       UnitPrice,
       CategoryName
FROM (
    SELECT p.ProductName,
           p.UnitPrice,
           c.CategoryName,
           AVG(p.UnitPrice) OVER (PARTITION BY p.CategoryID) AS Avg_Price
    FROM Products p
    JOIN Categories c
        ON p.CategoryID = c.CategoryID
) t
WHERE UnitPrice > Avg_Price;

-- 24.Display the number of orders placed on weekends vs weekdays.

SELECT
    CASE
        WHEN DAYOFWEEK(STR_TO_DATE(OrderDate, '%d-%m-%Y')) IN (1, 7)
        THEN 'Weekend'
        ELSE 'Weekday'
    END AS Day_Type,
    COUNT(*) AS Total_Orders
FROM Orders
GROUP BY Day_Type;

-- 25.Show customers who have the same city as their ship address in at least 3 orders. 

SELECT c.CustomerID,
       c.City,
       COUNT(*) AS Matching_Orders
FROM Customers c
JOIN Orders o
    ON o.CustomerID = c.CustomerID
WHERE c.City = o.ShipCity
GROUP BY c.CustomerID, c.City
HAVING COUNT(*) >= 3;

-- 26.Find the month with the highest average order value in 1997. 

SELECT MONTHNAME(STR_TO_DATE(OrderDate, '%d-%m-%Y')) AS Month_Name,
       AVG(Order_Value) AS Avg_Order_Value
FROM (
    SELECT o.OrderID,
           o.OrderDate,
           SUM(od.UnitPrice * od.Quantity) AS Order_Value
    FROM Orders o
    JOIN `Order-Details` od
        ON o.OrderID = od.OrderID
    WHERE YEAR(STR_TO_DATE(o.OrderDate, '%d-%m-%Y')) = 1997
    GROUP BY o.OrderID, o.OrderDate
) t
GROUP BY Month_Name
ORDER BY Avg_Order_Value DESC
LIMIT 1;

-- 27.Show the top 3 employees by revenue generated through their orders.

SELECT e.employeeID, 
	CONCAT(e.firstName," ",e.LastName)as FullName,
	SUM(od.unitPrice * od.quantity)as Total_revenue
FROM employees e
	JOIN orders o
	ON o.employeeID = e.EmployeeID
	JOIN `order-details` od
	ON od.orderID = o.orderID
GROUP BY e.employeeID, e.FirstName, e.LastName
ORDER BY Total_revenue DESC
LIMIT 3;

-- 28.Find all products that were supplied by suppliers from the same country as the customer.

SELECT DISTINCT p.productName, c.country
FROM suppliers s
	JOIN products p
    ON p.SupplierID = s.SupplierID
    JOIN `order-details` od
    ON od.productID = p.ProductID
    JOIN orders o
    ON o.orderID = od.orderID
    JOIN customers c
    ON c.CustomerID = o.customerID
WHERE c.Country = s.Country;

-- 29.Display the growth percentage in sales month-over-month for the year 1997.

WITH MonthlySales AS (
    SELECT
        MONTH(STR_TO_DATE(o.OrderDate, '%d-%m-%Y')) AS Month_No,
        SUM(od.UnitPrice * od.Quantity) AS Total_Sales
    FROM Orders o
    JOIN `Order-Details` od
        ON od.OrderID = o.OrderID
    WHERE YEAR(STR_TO_DATE(o.OrderDate, '%d-%m-%Y')) = 1997
    GROUP BY MONTH(STR_TO_DATE(o.OrderDate, '%d-%m-%Y'))
)

SELECT
    Month_No,
    Total_Sales,
    ROUND(
        (Total_Sales - LAG(Total_Sales) OVER (ORDER BY Month_No))
        * 100.0
        / LAG(Total_Sales) OVER (ORDER BY Month_No),
        2
    ) AS Growth_Percentage
FROM MonthlySales
ORDER BY Month_No;

-- 30.Show orders where the freight cost is more than 10% of the total order value. 

SELECT *
FROM (
    SELECT o.OrderID,
           SUM(od.UnitPrice * od.Quantity) AS Order_Value,
           o.Freight
    FROM Orders o
    JOIN `Order-Details` od
        ON od.OrderID = o.OrderID
    GROUP BY o.OrderID, o.Freight
) t
WHERE Freight > Order_Value * 0.10;

-- 31. Find the customer with the highest number of unique products purchased.

SELECT c.CustomerID,
       c.CompanyName,
       COUNT(DISTINCT od.ProductID) AS Unique_Products
FROM Customers c
JOIN Orders o
    ON o.CustomerID = c.CustomerID
JOIN `Order-Details` od
    ON od.OrderID = o.OrderID
GROUP BY c.CustomerID, c.CompanyName
ORDER BY Unique_Products DESC
LIMIT 1;

-- 32. Show the list of employees who report to the same manager.

SELECT
    m.EmployeeID AS ManagerID,
    CONCAT(m.FirstName,' ',m.LastName) AS Manager_Name,
    CONCAT(e.FirstName,' ',e.LastName) AS Employee_Name
FROM Employees e
JOIN Employees m
    ON e.ReportsTo = m.EmployeeID
ORDER BY ManagerID;

-- 33. Find categories where the average unit price is higher than the overall average.

SELECT c.CategoryName,
       AVG(p.UnitPrice) AS Avg_Price
FROM Categories c
JOIN Products p
    ON p.CategoryID = c.CategoryID
GROUP BY c.CategoryID, c.CategoryName
HAVING AVG(p.UnitPrice) >
(
    SELECT AVG(UnitPrice)
    FROM Products
);

-- 34. Display the cumulative profit (assuming 30% margin) per customer.

SELECT
    c.CustomerID,
    c.CompanyName,
    ROUND(
        SUM(od.UnitPrice * od.Quantity) * 0.30,
        2
    ) AS Cumulative_Profit
FROM Customers c
JOIN Orders o
    ON o.CustomerID = c.CustomerID
JOIN `Order-Details` od
    ON od.OrderID = o.OrderID
GROUP BY c.CustomerID, c.CompanyName;

-- 35. Show products that have been ordered by more than 50 different customers

SELECT p.ProductName,
       COUNT(DISTINCT o.CustomerID) AS Customer_Count
FROM Products p
JOIN `Order-Details` od
    ON od.ProductID = p.ProductID
JOIN Orders o
    ON o.OrderID = od.OrderID
GROUP BY p.ProductID, p.ProductName
HAVING COUNT(DISTINCT o.CustomerID) > 50;

-- 36. Find the most frequently ordered product in each region (ship country).

WITH cte AS
(
    SELECT
        o.ShipCountry,
        p.ProductName,
        COUNT(*) AS Order_Count,
        DENSE_RANK() OVER(
            PARTITION BY o.ShipCountry
            ORDER BY COUNT(*) DESC
        ) AS rnk
    FROM Orders o
    JOIN `Order-Details` od
        ON od.OrderID = o.OrderID
    JOIN Products p
        ON p.ProductID = od.ProductID
    GROUP BY o.ShipCountry, p.ProductName
)

SELECT *
FROM cte
WHERE rnk = 1;

-- 37.Show the rank of each order based on freight cost within its ship country. 

SELECT
    OrderID,
    ShipCountry,
    Freight,
    RANK() OVER (
        PARTITION BY ShipCountry
        ORDER BY Freight DESC
    ) AS FreightRank
FROM Orders;

-- 38.Find customers who placed orders in January but not in December of the same year. 

SELECT DISTINCT
    c.CustomerID,
    c.CompanyName
FROM Customers c
JOIN Orders o
    ON c.CustomerID = o.CustomerID
WHERE MONTH(o.OrderDate) = 1
AND NOT EXISTS (
    SELECT 1
    FROM Orders o2
    WHERE o2.CustomerID = o.CustomerID
      AND YEAR(o2.OrderDate) = YEAR(o.OrderDate)
      AND MONTH(o2.OrderDate) = 12
);

-- 39.Display the total discount given per category.

SELECT
    c.CategoryID,
    c.CategoryName,
    ROUND(SUM(
        od.UnitPrice * od.Quantity * od.Discount
    ), 2) AS TotalDiscountGiven
FROM Categories c
JOIN Products p
    ON c.CategoryID = p.CategoryID
JOIN `Order-Details` od
    ON p.ProductID = od.ProductID
GROUP BY
    c.CategoryID,
    c.CategoryName
ORDER BY TotalDiscountGiven DESC;


-- 40.Show the top 5 cities with highest number of orders but lowest average freight. 

SELECT
    ShipCity,
    COUNT(OrderID) AS TotalOrders,
    ROUND(AVG(Freight), 2) AS AvgFreight
FROM Orders
GROUP BY ShipCity
ORDER BY
    COUNT(OrderID) DESC,
    AVG(Freight) ASC
LIMIT 5;

-- 41.Find orders that were delayed by more than 10 days. 

SELECT
    OrderID,
    RequiredDate,
    ShippedDate,
    DATEDIFF(
        STR_TO_DATE(ShippedDate, '%Y-%m-%d'),
        STR_TO_DATE(RequiredDate, '%Y-%m-%d')
    ) AS DelayDays
FROM Orders
WHERE DATEDIFF(
        STR_TO_DATE(ShippedDate, '%Y-%m-%d'),
        STR_TO_DATE(RequiredDate, '%Y-%m-%d')
      ) > 10;
      
-- 42.Show the percentage of orders shipped by each shipper per year.

SELECT
    YEAR(STR_TO_DATE(o.OrderDate, '%Y-%m-%d')) AS OrderYear,
    s.CompanyName AS Shipper,
    COUNT(*) AS OrdersShipped,
    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (
            PARTITION BY YEAR(STR_TO_DATE(o.OrderDate, '%Y-%m-%d'))
        ),
        2
    ) AS PercentageOfOrders
FROM Orders o
JOIN Shippers s
    ON o.ShipVia = s.ShipperID
GROUP BY
    YEAR(STR_TO_DATE(o.OrderDate, '%Y-%m-%d')),
    s.CompanyName
ORDER BY
    OrderYear,
    PercentageOfOrders DESC;
    
-- 43.Find employees who have not handled any order in 1998

SELECT
    EmployeeID,
    FirstName,
    LastName
FROM Employees e
WHERE NOT EXISTS (
    SELECT 1
    FROM Orders o
    WHERE o.EmployeeID = e.EmployeeID
      AND YEAR(CAST(o.OrderDate AS DATE)) = 1998
);

  
-- 44.Display products that were reordered (UnitsOnOrder > 0) but are discontinued.

SELECT
    ProductID,
    ProductName,
    UnitsOnOrder,
    Discontinued
FROM Products
WHERE UnitsOnOrder > 0
  AND Discontinued = 1;
  
-- 45.Show the average time gap between consecutive orders for each customer.

WITH OrderDates AS (
    SELECT
        CustomerID,
        CAST(OrderDate AS DATE) AS OrderDate,
        LAG(CAST(OrderDate AS DATE))
            OVER (
                PARTITION BY CustomerID
                ORDER BY CAST(OrderDate AS DATE)
            ) AS PrevOrderDate
    FROM Orders
)
SELECT
    CustomerID,
    AVG(
        DATEDIFF(DAY, PrevOrderDate, OrderDate) * 1.0
    ) AS AvgGapDays
FROM OrderDates
WHERE PrevOrderDate IS NOT NULL
GROUP BY CustomerID;

-- 46.Find the product with the highest variance in unit price across different orders.

SELECT
    p.ProductID,
    p.ProductName,
    VARIANCE(od.UnitPrice) AS PriceVariance
FROM `Order-Details` od
JOIN Products p
    ON od.ProductID = p.ProductID
GROUP BY
    p.ProductID,
    p.ProductName
ORDER BY PriceVariance DESC
LIMIT 1;

-- 47.Show a list of customers who only buy from one category.

SELECT
    o.CustomerID
FROM Orders o
JOIN `Order-Details` od
    ON o.OrderID = od.OrderID
JOIN Products p
    ON od.ProductID = p.ProductID
GROUP BY o.CustomerID
HAVING COUNT(DISTINCT p.CategoryID) = 1;

-- 48.Display the top 10 orders with highest (Freight / Order Value) ratio.

WITH OrderValue AS (
    SELECT
        od.OrderID,
        SUM(
            od.UnitPrice *
            od.Quantity *
            (1 - od.Discount)
        ) AS OrderTotal
    FROM `Order-Details` od
    GROUP BY od.OrderID
)
SELECT
    o.OrderID,
    o.Freight,
    ov.OrderTotal,
    o.Freight / NULLIF(ov.OrderTotal,0) AS FreightRatio
FROM Orders o
JOIN OrderValue ov
    ON o.OrderID = ov.OrderID
ORDER BY FreightRatio DESC
LIMIT 10;

-- 49.Find how many customers have placed orders worth more than $10,000 in total.

WITH CustomerSales AS (
    SELECT
        o.CustomerID,
        SUM(
            od.UnitPrice *
            od.Quantity *
            (1 - od.Discount)
        ) AS TotalSpent
    FROM Orders o
    JOIN `Order-Details` od
        ON o.OrderID = od.OrderID
    GROUP BY o.CustomerID
)
SELECT COUNT(*) AS CustomerCount
FROM CustomerSales
WHERE TotalSpent > 10000;

-- 50.Show the distribution of order values in 4 buckets.

WITH OrderValues AS (
    SELECT
        od.OrderID,
        SUM(
            od.UnitPrice *
            od.Quantity *
            (1 - od.Discount)
        ) AS OrderValue
    FROM `Order-Details` od
    GROUP BY od.OrderID
)
SELECT
    CASE
        WHEN OrderValue BETWEEN 0 AND 500
            THEN '0-500'
        WHEN OrderValue BETWEEN 501 AND 2000
            THEN '501-2000'
        WHEN OrderValue BETWEEN 2001 AND 5000
            THEN '2001-5000'
        ELSE '5001+'
    END AS ValueBucket,
    COUNT(*) AS NumberOfOrders
FROM OrderValues
GROUP BY
    CASE
        WHEN OrderValue BETWEEN 0 AND 500
            THEN '0-500'
        WHEN OrderValue BETWEEN 501 AND 2000
            THEN '501-2000'
        WHEN OrderValue BETWEEN 2001 AND 5000
            THEN '2001-5000'
        ELSE '5001+'
    END
ORDER BY MIN(OrderValue);

-- 51.Find suppliers who supply more than 5 products that are currently in stock.

SELECT
    s.SupplierID,
    s.CompanyName,
    COUNT(*) AS ProductsInStock
FROM Suppliers s
JOIN Products p
    ON s.SupplierID = p.SupplierID
WHERE p.UnitsInStock > 0
GROUP BY
    s.SupplierID,
    s.CompanyName
HAVING COUNT(*) > 5;

-- 52.Show the month-wise comparison of total sales between 1996 and 1997.

SELECT
    MONTH(CAST(o.OrderDate AS DATE)) AS MonthNo,
    SUM(
        CASE
            WHEN YEAR(CAST(o.OrderDate AS DATE)) = 1996
            THEN od.UnitPrice * od.Quantity * (1 - od.Discount)
            ELSE 0
        END
    ) AS Sales1996,
    SUM(
        CASE
            WHEN YEAR(CAST(o.OrderDate AS DATE)) = 1997
            THEN od.UnitPrice * od.Quantity * (1 - od.Discount)
            ELSE 0
        END
    ) AS Sales1997
FROM Orders o
JOIN `Order-Details` od
    ON o.OrderID = od.OrderID
WHERE YEAR(CAST(o.OrderDate AS DATE)) IN (1996,1997)
GROUP BY MONTH(CAST(o.OrderDate AS DATE))
ORDER BY MonthNo;

-- 53.Display customers who have increased their spending from 1996 to 1997.

WITH CustomerSales AS (
    SELECT
        o.CustomerID,
        YEAR(CAST(o.OrderDate AS DATE)) AS SalesYear,
        SUM(
            od.UnitPrice *
            od.Quantity *
            (1 - od.Discount)
        ) AS TotalSales
    FROM Orders o
    JOIN `Order-Details` od
        ON o.OrderID = od.OrderID
    WHERE YEAR(CAST(o.OrderDate AS DATE)) IN (1996,1997)
    GROUP BY
        o.CustomerID,
        YEAR(CAST(o.OrderDate AS DATE))
)
SELECT
    s96.CustomerID,
    s96.TotalSales AS Sales1996,
    s97.TotalSales AS Sales1997
FROM CustomerSales s96
JOIN CustomerSales s97
    ON s96.CustomerID = s97.CustomerID
WHERE s96.SalesYear = 1996
  AND s97.SalesYear = 1997
  AND s97.TotalSales > s96.TotalSales;
  
-- 54.Find the least profitable category after deducting 15% handling cost.

SELECT
    c.CategoryID,
    c.CategoryName,
    SUM(
        od.UnitPrice *
        od.Quantity *
        (1 - od.Discount)
    ) * 0.85 AS NetProfit
FROM Categories c
JOIN Products p
    ON c.CategoryID = p.CategoryID
JOIN `Order-Details` od
    ON p.ProductID = od.ProductID
GROUP BY
    c.CategoryID,
    c.CategoryName
ORDER BY NetProfit ASC
LIMIT 1;

-- 55.Show the running total of quantity sold for each product.

SELECT
    p.ProductID,
    p.ProductName,
    CAST(o.OrderDate AS DATE) AS OrderDate,
    od.Quantity,
    SUM(od.Quantity) OVER (
        PARTITION BY p.ProductID
        ORDER BY CAST(o.OrderDate AS DATE)
    ) AS RunningTotalQty
FROM Products p
JOIN `Order-Details` od
    ON p.ProductID = od.ProductID
JOIN Orders o
    ON od.OrderID = o.OrderID;

-- 56.Find orders where multiple products from the same category were purchased.

SELECT
    od.OrderID,
    p.CategoryID,
    COUNT(DISTINCT od.ProductID) AS ProductsCount
FROM `Order-Details` od
JOIN Products p
    ON od.ProductID = p.ProductID
GROUP BY
    od.OrderID,
    p.CategoryID
HAVING COUNT(DISTINCT od.ProductID) > 1;

-- 57.Display the top 5 products with highest profit margin per unit.

SELECT
    ProductID,
    ProductName,
    UnitPrice,
    UnitPrice * 0.30 AS ProfitPerUnit
FROM Products
ORDER BY ProfitPerUnit DESC
LIMIT 5;

-- 58.Show employees who handled orders from more than 10 different countries.

SELECT
    e.EmployeeID,
    e.FirstName,
    e.LastName,
    COUNT(DISTINCT o.ShipCountry) AS CountryCount
FROM Employees e
JOIN Orders o
    ON e.EmployeeID = o.EmployeeID
GROUP BY
    e.EmployeeID,
    e.FirstName,
    e.LastName
HAVING COUNT(DISTINCT o.ShipCountry) > 10;


-- 59.Find the correlation trend between discount and quantity ordered.

SELECT
    Discount,
    AVG(Quantity) AS AvgQuantity
FROM `Order-Details`
GROUP BY Discount
ORDER BY Discount;

-- 60.Show customers who have never ordered from 'Beverages' category.

SELECT
    c.CustomerID,
    c.CompanyName
FROM Customers c
WHERE NOT EXISTS (
    SELECT 1
    FROM Orders o
    JOIN `Order-Details` od
        ON o.OrderID = od.OrderID
    JOIN Products p
        ON od.ProductID = p.ProductID
    JOIN Categories cat
        ON p.CategoryID = cat.CategoryID
    WHERE o.CustomerID = c.CustomerID
      AND cat.CategoryName = 'Beverages'
);


-- 61.Display the 3rd highest order value for each customer.

WITH OrderValues AS (
    SELECT
        o.CustomerID,
        o.OrderID,
        SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS OrderValue,
        DENSE_RANK() OVER (
            PARTITION BY o.CustomerID
            ORDER BY SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) DESC
        ) AS rn
    FROM Orders o
    JOIN `Order-Details` od
        ON o.OrderID = od.OrderID
    GROUP BY o.CustomerID, o.OrderID
)
SELECT CustomerID, OrderID, OrderValue
FROM OrderValues
WHERE rn = 3;

-- 62.Find the average number of days between order placement and shipping per shipper.

SELECT
    s.CompanyName AS Shipper,
    AVG(
        DATEDIFF(
            STR_TO_DATE(o.ShippedDate, '%Y-%m-%d'),
            STR_TO_DATE(o.OrderDate, '%Y-%m-%d')
        )
    ) AS AvgShippingDays
FROM Orders o
JOIN Shippers s
    ON o.ShipVia = s.ShipperID
WHERE o.ShippedDate IS NOT NULL
GROUP BY s.CompanyName;

-- 63.Show products that were ordered in every quarter of 1997.

WITH ProductQuarter AS (
    SELECT DISTINCT
        od.ProductID,
        QUARTER(o.OrderDate) AS QuarterNo
    FROM Orders o
    JOIN `Order-Details` od
        ON o.OrderID = od.OrderID
    WHERE YEAR(o.OrderDate) = 1997
)
SELECT ProductID
FROM ProductQuarter
GROUP BY ProductID
HAVING COUNT(DISTINCT QuarterNo) = 4;


-- 64.Customer with most consistent order value (lowest variance).

WITH OrderValues AS (
    SELECT
        o.CustomerID,
        o.OrderID,
        SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS OrderValue
    FROM Orders o
    JOIN `Order-Details` od
        ON o.OrderID = od.OrderID
    GROUP BY o.CustomerID, o.OrderID
)
SELECT
    CustomerID,
    VARIANCE(OrderValue) AS OrderVariance
FROM OrderValues
GROUP BY CustomerID
ORDER BY OrderVariance
LIMIT 1;


-- 65.Year-wise total orders handled by each employee.

SELECT
    e.EmployeeID,
    CONCAT(e.FirstName, ' ', e.LastName) AS EmployeeName,
    YEAR(o.OrderDate) AS OrderYear,
    COUNT(*) AS TotalOrders
FROM Employees e
JOIN Orders o
    ON e.EmployeeID = o.EmployeeID
GROUP BY
    e.EmployeeID,
    EmployeeName,
    YEAR(o.OrderDate)
ORDER BY EmployeeID, OrderYear;


-- 66.Percentage of delayed orders.

SELECT
    ROUND(
        100 * SUM(CASE
                    WHEN ShippedDate > RequiredDate THEN 1
                    ELSE 0
                  END)
        / COUNT(*),
        2
    ) AS DelayedOrderPercentage
FROM Orders
WHERE ShippedDate IS NOT NULL;

-- 67.Most popular product combination ordered together.

SELECT
    od1.ProductID AS Product1,
    od2.ProductID AS Product2,
    COUNT(*) AS TimesOrderedTogether
FROM `Order-Details` od1
JOIN `Order-Details` od2
    ON od1.OrderID = od2.OrderID
   AND od1.ProductID < od2.ProductID
GROUP BY od1.ProductID, od2.ProductID
ORDER BY TimesOrderedTogether DESC
LIMIT 1;


-- 68.Top 10 longest gaps between consecutive orders of a customer.

WITH CustomerOrders AS (
    SELECT
        CustomerID,
        OrderDate,
        LAG(OrderDate) OVER (
            PARTITION BY CustomerID
            ORDER BY OrderDate
        ) AS PrevOrderDate
    FROM Orders
)
SELECT
    CustomerID,
    PrevOrderDate,
    OrderDate,
    DATEDIFF(OrderDate, PrevOrderDate) AS GapDays
FROM CustomerOrders
WHERE PrevOrderDate IS NOT NULL
ORDER BY GapDays DESC
LIMIT 10;


-- 69.Categories with more than 10 products having zero units on order.

SELECT
    c.CategoryID,
    c.CategoryName,
    COUNT(*) AS ProductCount
FROM Categories c
JOIN Products p
    ON c.CategoryID = p.CategoryID
WHERE p.UnitsOnOrder = 0
GROUP BY c.CategoryID, c.CategoryName
HAVING COUNT(*) > 10;


-- 70.Orders shipped late by more than 7 days in each region.

SELECT
    c.Region,
    COUNT(*) AS LateOrders
FROM Orders o
JOIN Customers c
    ON o.CustomerID = c.CustomerID
WHERE DATEDIFF(o.ShippedDate, o.RequiredDate) > 7
GROUP BY c.Region
ORDER BY LateOrders DESC;

-- 71. Show the contribution of each employee to total company revenue.

SELECT
    e.EmployeeID,
    CONCAT(e.FirstName,' ',e.LastName) AS EmployeeName,
    ROUND(
        SUM(od.UnitPrice * od.Quantity * (1 - od.Discount))
        * 100 /
        (SELECT SUM(UnitPrice * Quantity * (1 - Discount))
         FROM OrderDetails),
        2
    ) AS RevenueContributionPercent
FROM Employees e
JOIN Orders o ON e.EmployeeID = o.EmployeeID
JOIN OrderDetails od ON o.OrderID = od.OrderID
GROUP BY e.EmployeeID, EmployeeName;


-- 72. Products whose name starts with a vowel and ordered more than 30 times.

SELECT
    p.ProductID,
    p.ProductName,
    COUNT(DISTINCT od.OrderID) AS TotalOrders
FROM Products p
JOIN OrderDetails od ON p.ProductID = od.ProductID
WHERE LOWER(LEFT(p.ProductName,1)) IN ('a','e','i','o','u')
GROUP BY p.ProductID, p.ProductName
HAVING COUNT(DISTINCT od.OrderID) > 30;


-- 73. Rank shippers based on on-time delivery percentage.

SELECT
    s.CompanyName,
    ROUND(
        100 * SUM(CASE WHEN o.ShippedDate <= o.RequiredDate THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS OnTimePercent,
    RANK() OVER (
        ORDER BY
        ROUND(
            100 * SUM(CASE WHEN o.ShippedDate <= o.RequiredDate THEN 1 ELSE 0 END)
            / COUNT(*),
            2
        ) DESC
    ) AS ShipperRank
FROM Orders o
JOIN Shippers s ON o.ShipVia = s.ShipperID
WHERE o.ShippedDate IS NOT NULL
GROUP BY s.CompanyName;


-- 74. Customers who placed orders on the same month and day as their birthday.

SELECT DISTINCT
    c.CustomerID,
    c.CompanyName,
    e.BirthDate,
    o.OrderDate
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN Employees e ON o.EmployeeID = e.EmployeeID
WHERE MONTH(e.BirthDate) = MONTH(o.OrderDate)
  AND DAY(e.BirthDate) = DAY(o.OrderDate);


-- 75. Total revenue generated by each territory.

SELECT
    t.TerritoryDescription,
    SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS Revenue
FROM Territories t
JOIN EmployeeTerritories et ON t.TerritoryID = et.TerritoryID
JOIN Employees e ON et.EmployeeID = e.EmployeeID
JOIN Orders o ON e.EmployeeID = o.EmployeeID
JOIN OrderDetails od ON o.OrderID = od.OrderID
GROUP BY t.TerritoryDescription;


-- 76. Difference in average order value between weekdays and weekends.

WITH OrderValues AS (
    SELECT
        o.OrderID,
        CASE
            WHEN DAYOFWEEK(o.OrderDate) IN (1,7) THEN 'Weekend'
            ELSE 'Weekday'
        END AS DayType,
        SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS OrderValue
    FROM Orders o
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    GROUP BY o.OrderID, DayType
)
SELECT
    DayType,
    AVG(OrderValue) AS AvgOrderValue
FROM OrderValues
GROUP BY DayType;


-- 77. Top 5 products contributing more than 50% of category revenue.

WITH ProductRevenue AS (
    SELECT
        c.CategoryID,
        c.CategoryName,
        p.ProductID,
        p.ProductName,
        SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS Revenue
    FROM Categories c
    JOIN Products p ON c.CategoryID = p.CategoryID
    JOIN OrderDetails od ON p.ProductID = od.ProductID
    GROUP BY c.CategoryID,c.CategoryName,p.ProductID,p.ProductName
)
SELECT *
FROM ProductRevenue pr
WHERE Revenue > (
    SELECT 0.5 * SUM(pr2.Revenue)
    FROM ProductRevenue pr2
    WHERE pr2.CategoryID = pr.CategoryID
)
ORDER BY Revenue DESC
LIMIT 5;


-- 78. Orders where customer and ship destination country are same.

SELECT
    o.OrderID,
    c.CompanyName,
    c.Country,
    o.ShipCountry
FROM Orders o
JOIN Customers c ON o.CustomerID = c.CustomerID
WHERE c.Country = o.ShipCountry;


-- 79. Growth rate of new customers acquired each year.

WITH YearlyCustomers AS (
    SELECT
        YEAR(MIN(OrderDate)) AS FirstYear,
        CustomerID
    FROM Orders
    GROUP BY CustomerID
)
SELECT
    FirstYear,
    COUNT(*) AS NewCustomers,
    ROUND(
        (
            COUNT(*) -
            LAG(COUNT(*)) OVER(ORDER BY FirstYear)
        ) * 100.0 /
        LAG(COUNT(*)) OVER(ORDER BY FirstYear),
        2
    ) AS GrowthRate
FROM YearlyCustomers
GROUP BY FirstYear;


-- 80. Products with highest returns (high discount proxy).

SELECT
    p.ProductID,
    p.ProductName,
    COUNT(*) AS HighDiscountOrders
FROM Products p
JOIN OrderDetails od ON p.ProductID = od.ProductID
WHERE od.Discount >= 0.20
GROUP BY p.ProductID,p.ProductName
ORDER BY HighDiscountOrders DESC;


-- 81. Average, Min, Max order value.

WITH OrderValues AS (
    SELECT
        o.OrderID,
        SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS OrderValue
    FROM Orders o
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    GROUP BY o.OrderID
)
SELECT
    AVG(OrderValue) AS AvgOrderValue,
    MIN(OrderValue) AS MinOrderValue,
    MAX(OrderValue) AS MaxOrderValue
FROM OrderValues;


-- 82. Employees joined before 1993 and handled more than 100 orders.

SELECT
    e.EmployeeID,
    CONCAT(e.FirstName,' ',e.LastName) AS EmployeeName,
    COUNT(o.OrderID) AS TotalOrders
FROM Employees e
JOIN Orders o ON e.EmployeeID = o.EmployeeID
WHERE e.HireDate < '1993-01-01'
GROUP BY e.EmployeeID, EmployeeName
HAVING COUNT(o.OrderID) > 100;


-- 83. Most delayed order and associated customer.

SELECT
    o.OrderID,
    c.CompanyName,
    DATEDIFF(o.ShippedDate,o.RequiredDate) AS DelayDays
FROM Orders o
JOIN Customers c ON o.CustomerID = c.CustomerID
ORDER BY DelayDays DESC
LIMIT 1;


-- 84. Percentage of orders shipped within 3 days.

SELECT
    ROUND(
        100 *
        SUM(CASE WHEN DATEDIFF(ShippedDate,OrderDate) <= 3 THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS PercentageWithin3Days
FROM Orders
WHERE ShippedDate IS NOT NULL;


-- 85. Top 10 customers by lifetime value.

SELECT
    c.CustomerID,
    c.CompanyName,
    SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS LifetimeValue
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN OrderDetails od ON o.OrderID = od.OrderID
GROUP BY c.CustomerID,c.CompanyName
ORDER BY LifetimeValue DESC
LIMIT 10;


-- 86. Categories where average discount exceeds overall average.

SELECT
    c.CategoryID,
    c.CategoryName,
    AVG(od.Discount) AS AvgDiscount
FROM Categories c
JOIN Products p ON c.CategoryID = p.CategoryID
JOIN OrderDetails od ON p.ProductID = od.ProductID
GROUP BY c.CategoryID,c.CategoryName
HAVING AVG(od.Discount) >
(
    SELECT AVG(Discount)
    FROM OrderDetails
);


-- 87. Unique suppliers per category.

SELECT
    c.CategoryName,
    COUNT(DISTINCT p.SupplierID) AS UniqueSuppliers
FROM Categories c
JOIN Products p ON c.CategoryID = p.CategoryID
GROUP BY c.CategoryName;


-- 88. Customer with highest ratio of distinct products to total orders.

SELECT
    o.CustomerID,
    COUNT(DISTINCT od.ProductID) /
    COUNT(DISTINCT o.OrderID) AS ProductOrderRatio
FROM Orders o
JOIN OrderDetails od ON o.OrderID = od.OrderID
GROUP BY o.CustomerID
ORDER BY ProductOrderRatio DESC
LIMIT 1;


-- 89. Trend of average freight cost over years.

SELECT
    YEAR(OrderDate) AS OrderYear,
    AVG(Freight) AS AvgFreight
FROM Orders
GROUP BY YEAR(OrderDate)
ORDER BY OrderYear;


-- 90. Products never discontinued and very low stock.

SELECT
    ProductID,
    ProductName,
    UnitsInStock
FROM Products
WHERE Discontinued = 0
AND UnitsInStock < 10;


-- 91. Busiest shipping day of week.

SELECT
    DAYNAME(ShippedDate) AS ShippingDay,
    COUNT(*) AS TotalShipments
FROM Orders
WHERE ShippedDate IS NOT NULL
GROUP BY DAYNAME(ShippedDate)
ORDER BY TotalShipments DESC
LIMIT 1;


-- 92. Top 5 valuable inactive customers (no orders in 1998).

SELECT
    c.CustomerID,
    c.CompanyName,
    SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS Revenue
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN OrderDetails od ON o.OrderID = od.OrderID
GROUP BY c.CustomerID,c.CompanyName
HAVING MAX(YEAR(o.OrderDate)) < 1998
ORDER BY Revenue DESC
LIMIT 5;


-- 93. Employee impact on freight cost.

SELECT
    e.EmployeeID,
    CONCAT(e.FirstName,' ',e.LastName) AS EmployeeName,
    AVG(o.Freight) AS AvgFreight
FROM Employees e
JOIN Orders o ON e.EmployeeID = o.EmployeeID
GROUP BY e.EmployeeID, EmployeeName;


-- 94. Duplicate company names in customers and suppliers.

SELECT CompanyName
FROM (
    SELECT CompanyName FROM Customers
    UNION ALL
    SELECT CompanyName FROM Suppliers
) x
GROUP BY CompanyName
HAVING COUNT(*) > 1;


-- 95. Total sales value handled by each employee per quarter.

SELECT
    e.EmployeeID,
    CONCAT(e.FirstName,' ',e.LastName) AS EmployeeName,
    YEAR(o.OrderDate) AS OrderYear,
    QUARTER(o.OrderDate) AS QuarterNo,
    SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS SalesValue
FROM Employees e
JOIN Orders o ON e.EmployeeID = o.EmployeeID
JOIN OrderDetails od ON o.OrderID = od.OrderID
GROUP BY
    e.EmployeeID,
    EmployeeName,
    YEAR(o.OrderDate),
    QUARTER(o.OrderDate);


-- 96. Percentage of international orders.

SELECT
    ROUND(
        100 *
        SUM(CASE WHEN c.Country <> o.ShipCountry THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS InternationalOrderPercent
FROM Orders o
JOIN Customers c ON o.CustomerID = c.CustomerID;


-- 97. Product with longest duration between first and last order.

SELECT
    p.ProductID,
    p.ProductName,
    DATEDIFF(
        MAX(o.OrderDate),
        MIN(o.OrderDate)
    ) AS DurationDays
FROM Products p
JOIN OrderDetails od ON p.ProductID = od.ProductID
JOIN Orders o ON od.OrderID = o.OrderID
GROUP BY p.ProductID,p.ProductName
ORDER BY DurationDays DESC
LIMIT 1;


-- 98. Customers who ordered all products from a category.

SELECT
    o.CustomerID,
    p.CategoryID
FROM Orders o
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
GROUP BY o.CustomerID,p.CategoryID
HAVING COUNT(DISTINCT p.ProductID) =
(
    SELECT COUNT(*)
    FROM Products p2
    WHERE p2.CategoryID = p.CategoryID
);


-- 99. Efficiency of each shipper (average shipping days).

SELECT
    s.CompanyName,
    AVG(DATEDIFF(o.ShippedDate,o.OrderDate)) AS AvgShippingDays
FROM Orders o
JOIN Shippers s ON o.ShipVia = s.ShipperID
WHERE o.ShippedDate IS NOT NULL
GROUP BY s.CompanyName;


-- 100. Customer RFM Ranking.

WITH RFM AS (
    SELECT
        CustomerID,
        DATEDIFF(MAX(OrderDate), MIN(OrderDate)) AS Recency,
        COUNT(OrderID) AS Frequency,
        SUM(Freight) AS Monetary
    FROM Orders
    GROUP BY CustomerID
)
SELECT
    CustomerID,
    Recency,
    Frequency,
    Monetary,
    (
        Recency * 0.2 +
        Frequency * 0.3 +
        Monetary * 0.5
    ) AS RFMScore
FROM RFM
ORDER BY RFMScore DESC;