--*************************************************************************--
-- Title: Assignment06
-- Author: NJones
-- Desc: This file demonstrates how to use Views
-- Change Log: When,Who,What
-- 2017-01-01,NJones,Created File
--**************************************************************************--
Begin Try
	Use Master;
	If Exists(Select Name From SysDatabases Where Name = 'Assignment06DB_NJones')
	 Begin 
	  Alter Database [Assignment06DB_NJones] set Single_user With Rollback Immediate;
	  Drop Database Assignment06DB_NJones;
	 End
	Create Database Assignment06DB_NJones;
End Try
Begin Catch
	Print Error_Number();
End Catch
go
Use Assignment06DB_NJones;

-- Create Tables (Module 01)-- 
Create Table Categories
([CategoryID] [int] IDENTITY(1,1) NOT NULL 
,[CategoryName] [nvarchar](100) NOT NULL
);
go

Create Table Products
([ProductID] [int] IDENTITY(1,1) NOT NULL 
,[ProductName] [nvarchar](100) NOT NULL 
,[CategoryID] [int] NULL  
,[UnitPrice] [mOney] NOT NULL
);
go

Create Table Employees -- New Table
([EmployeeID] [int] IDENTITY(1,1) NOT NULL 
,[EmployeeFirstName] [nvarchar](100) NOT NULL
,[EmployeeLastName] [nvarchar](100) NOT NULL 
,[ManagerID] [int] NULL  
);
go

Create Table Inventories
([InventoryID] [int] IDENTITY(1,1) NOT NULL
,[InventoryDate] [Date] NOT NULL
,[EmployeeID] [int] NOT NULL -- New Column
,[ProductID] [int] NOT NULL
,[Count] [int] NOT NULL
);
go

-- Add Constraints (Module 02) -- 
Begin  -- Categories
	Alter Table Categories 
	 Add Constraint pkCategories 
	  Primary Key (CategoryId);

	Alter Table Categories 
	 Add Constraint ukCategories 
	  Unique (CategoryName);
End
go 

Begin -- Products
	Alter Table Products 
	 Add Constraint pkProducts 
	  Primary Key (ProductId);

	Alter Table Products 
	 Add Constraint ukProducts 
	  Unique (ProductName);

	Alter Table Products 
	 Add Constraint fkProductsToCategories 
	  Foreign Key (CategoryId) References Categories(CategoryId);

	Alter Table Products 
	 Add Constraint ckProductUnitPriceZeroOrHigher 
	  Check (UnitPrice >= 0);
End
go

Begin -- Employees
	Alter Table Employees
	 Add Constraint pkEmployees 
	  Primary Key (EmployeeId);

	Alter Table Employees 
	 Add Constraint fkEmployeesToEmployeesManager 
	  Foreign Key (ManagerId) References Employees(EmployeeId);
End
go

Begin -- Inventories
	Alter Table Inventories 
	 Add Constraint pkInventories 
	  Primary Key (InventoryId);

	Alter Table Inventories
	 Add Constraint dfInventoryDate
	  Default GetDate() For InventoryDate;

	Alter Table Inventories
	 Add Constraint fkInventoriesToProducts
	  Foreign Key (ProductId) References Products(ProductId);

	Alter Table Inventories 
	 Add Constraint ckInventoryCountZeroOrHigher 
	  Check ([Count] >= 0);

	Alter Table Inventories
	 Add Constraint fkInventoriesToEmployees
	  Foreign Key (EmployeeId) References Employees(EmployeeId);
End 
go

-- Adding Data (Module 04) -- 
Insert Into Categories 
(CategoryName)
Select CategoryName 
 From Northwind.dbo.Categories
 Order By CategoryID;
go

Insert Into Products
(ProductName, CategoryID, UnitPrice)
Select ProductName,CategoryID, UnitPrice 
 From Northwind.dbo.Products
  Order By ProductID;
go

Insert Into Employees
(EmployeeFirstName, EmployeeLastName, ManagerID)
Select E.FirstName, E.LastName, IsNull(E.ReportsTo, E.EmployeeID) 
 From Northwind.dbo.Employees as E
  Order By E.EmployeeID;
go

Insert Into Inventories
(InventoryDate, EmployeeID, ProductID, [Count])
Select '20170101' as InventoryDate, 5 as EmployeeID, ProductID, UnitsInStock
From Northwind.dbo.Products
UNIOn
Select '20170201' as InventoryDate, 7 as EmployeeID, ProductID, UnitsInStock + 10 -- Using this is to create a made up value
From Northwind.dbo.Products
UNIOn
Select '20170301' as InventoryDate, 9 as EmployeeID, ProductID, UnitsInStock + 20 -- Using this is to create a made up value
From Northwind.dbo.Products
Order By 1, 2
go

-- Show the Current data in the Categories, Products, and Inventories Tables
Select * From Categories;
go
Select * From Products;
go
Select * From Employees;
go
Select * From Inventories;
go

/********************************* Questions and Answers *********************************/

-- Question 1 (5% pts): How can you create BACIC views to show data from each table in the database.
-- NOTES: 1) Do not use a *, list out each column!
--        2) Create one view per table!
--		  3) Use SchemaBinding to protect the views from being orphaned!
CREATE VIEW vCategories
WITH SCHEMABINDING
	AS
	 Select CategoryID, CategoryName
	 FROM dbo.Categories;
GO
Create view vProducts
WITH SCHEMABINDING
	AS
	 Select ProductID, ProductName, CategoryID, UnitPrice
	 FROM dbo.Products;
GO
Create view vEmployees
WITH SCHEMABINDING
	AS
	 Select EmployeeID, EmployeeFirstName, EmployeeLastName, ManagerID
	 FROM dbo.Employees;
GO
Create view vInventories
WITH SCHEMABINDING
	AS
	 Select InventoryID, InventoryDate, EmployeeID, ProductID, Count
	 FROM dbo.Inventories;
GO

-- Question 2 (5% pts): How can you set permissions, so that the public group CANNOT select data 
-- from each table, but can select data from each view?
DENY SELECT ON Categories to PUBLIC;
DENY SELECT ON Products to PUBLIC;
DENY SELECT ON Employees to PUBLIC;
DENY SELECT ON Inventories to PUBLIC;
GO

GRANT SELECT ON vCategories to PUBLIC;
GRANT SELECT ON vProducts to PUBLIC;
GRANT SELECT ON vEmployees to PUBLIC;
GRANT SELECT ON vInventories to PUBLIC;
GO

-- Question 3 (10% pts): How can you create a view to show a list of Category and Product names, 
-- and the price of each product?
-- Order the result by the Category and Product!
CREATE VIEW vProductsByCategories
AS
    SELECT TOP 1000000
    c.CategoryName,
    p.ProductName,
    p.UnitPrice
FROM vCategories as c
    Inner JOIN vProducts as p
    on c.CategoryID = p.CategoryID
    Order by 1,2,3;
GO


-- Question 4 (10% pts): How can you create a view to show a list of Product names 
-- and Inventory Counts on each Inventory Date?
-- Order the results by the Product, Date, and Count!
CREATE VIEW vInventoriesByProductsByDates
AS
    Select top 1000000
    p.ProductName,
    I.InventoryDate,
    I.[Count]
    FROM vProducts as p
        Inner JOIN vInventories as I
        on p.ProductID  = I.ProductID
    Order by 2,1,3;
GO

-- Question 5 (10% pts): How can you create a view to show a list of Inventory Dates 
-- and the Employee that took the count?
-- Order the results by the Date and return only one row per date!
Create VIEW vInventoriesByEmployeesByDates
AS
    Select Distinct top 1000000
        I.InventoryDate,
        E. EmployeeFirstName + ' ' + E.EmployeeLastName as EmployeeName
        FROM vInventories as I
            Inner JOIN vEmployees as E
            ON I.EmployeeID = E.EmployeeID
        Order BY 1,2;
    GO
-- Here is are the rows selected from the view:

-- InventoryDate	EmployeeName
-- 2017-01-01	    Steven Buchanan
-- 2017-02-01	    Robert King
-- 2017-03-01	    Anne Dodsworth

-- Question 6 (10% pts): How can you create a view show a list of Categories, Products, 
-- and the Inventory Date and Count of each product?
-- Order the results by the Category, Product, Date, and Count!
CREATE VIEW vInventoriesByProductsByCategories
AS
    Select top 1000000
    C.CategoryName,
    P.ProductName,
    I.InventoryDate,
    I.[Count]
    FROM vInventories as i
        INNER JOIN vEmployees as E
        on I.EmployeeID = E.EmployeeID
        INNER JOIN vProducts as P
        on I.ProductID = P.ProductID
        INNER JOIN vCategories as C
        on P.CategoryID = C.CategoryID
order BY 1,2,3,4;
Go


-- Question 7 (10% pts): How can you create a view to show a list of Categories, Products, 
-- the Inventory Date and Count of each product, and the EMPLOYEE who took the count?
-- Order the results by the Inventory Date, Category, Product and Employee!
CREATE VIEW vInventoriesByProductsByEmployees
AS
    Select Top 1000000
    C.CategoryName,
    P.ProductName,
    I.InventoryDate,
    I.[Count],
    E.EmployeeFirstName + ' ' + E.EmployeeLastName as EmployeeName
    From vInventories as I
        Inner JOIN vEmployees as E
        on I.EmployeeID = E.EmployeeID
        INNER JOIN vProducts as P
        on I.ProductID = P.ProductID
        INNER JOIN vCategories as C
        on P.CategoryID = C.CategoryID
    ORDER by 3,1,2,4;
GO


-- Question 8 (10% pts): How can you create a view to show a list of Categories, Products, 
-- the Inventory Date and Count of each product, and the Employee who took the count
-- for the Products 'Chai' and 'Chang'? 
CREATE VIEW vInventoriesForChaiAndChangByEmployees
AS
    select top 1000000
    C.CategoryName,
    P.ProductName,
    I.InventoryDate,
    I.[Count],
    E.EmployeeFirstName + ' ' + E.EmployeeLastName as EmployeeName
    From vInventories as I
    Inner JOIN vEmployees as E
    on I.EmployeeID = E.EmployeeID
    Inner JOIN vProducts as P
    on I.ProductID = P.ProductID
    Inner JOIN vCategories as C
    on P.CategoryID = C.CategoryID
    Where I.ProductID in (select ProductID from Products where ProductName in ('Chai', 'Chang'))
    ORDER by 3,1,2,4
GO
-- Question 9 (10% pts): How can you create a view to show a list of Employees and the Manager who manages them?
-- Order the results by the Manager's name!
CREATE VIEW vEmployeesByManager
AS
    SELECT top 1000000
    M.EmployeeFirstName + ' ' + M.EmployeeLastName as ManagerName,
    E.EmployeeFirstName + ' ' + E.EmployeeLastName as EmployeeName
    FROM vEmployees as E
    Inner Join vEmployees as M
    on E. ManagerID = M.EmployeeID
    Order by 1,2
GO
-- Question 10 (20% pts): How can you create one view to show all the data from all four 
-- BASIC Views? Also show the Employee's Manager Name and order the data by 
-- Category, Product, InventoryID, and Employee.
CREATE VIEW vInventoriesByProductsByCategoriesByEmployees
AS
    SELECT top 1000000
    C.CategoryID,
    C.CategoryName,
    P.ProductID,
    P.ProductName,
    P.UnitPrice,
    I.InventoryID,
    I.InventoryDate,
    I.[count],
    E.EmployeeID,
    E.EmployeeFirstName + ' ' + E.EmployeeLastName as EmployeeName,
    M.EmployeeFirstName + ' ' + M.EmployeeLastName as ManagerName
    From vCategories as C
    INNER JOIN vProducts as P
    on P.CategoryID = C.CategoryID
    Inner JOIN vInventories as I
    on P.ProductID = I.InventoryID
    INNER JOIN vEmployees as E
    on I.EmployeeID = E.EmployeeID
    INNER JOIN vEmployees as M
    on E.ManagerID = M.EmployeeID
Order by 1,3,6,9
GO


-- Test your Views (NOTE: You must change the your view names to match what I have below!)
Print 'Note: You will get an error until the views are created!'
Select * From [dbo].[vCategories]
Select * From [dbo].[vProducts]
Select * From [dbo].[vInventories]
Select * From [dbo].[vEmployees]

Select * From [dbo].[vProductsByCategories]
Select * From [dbo].[vInventoriesByProductsByDates]
Select * From [dbo].[vInventoriesByEmployeesByDates]
Select * From [dbo].[vInventoriesByProductsByCategories]
Select * From [dbo].[vInventoriesByProductsByEmployees]
Select * From [dbo].[vInventoriesForChaiAndChangByEmployees]
Select * From [dbo].[vEmployeesByManager]
Select * From [dbo].[vInventoriesByProductsByCategoriesByEmployees]

/***************************************************************************************/