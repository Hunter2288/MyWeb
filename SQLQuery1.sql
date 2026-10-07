IF DB_ID('OrdersDb') IS NULL
CREATE DATABASE OrdersDb

GO
USE OrdersDb;

GO 

CREATE TABLE Customers (
	id INT IDENTITY(1,1) PRIMARY KEY,
	FullName NVARCHAR(50) NOT NULL,
	Email NVARCHAR(100) NOT NULL CONSTRAINT UQ_Customers_Email UNIQUE (Email),
	Phone NVARCHAR(100) NULL,

	CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
	CreatedBy NVARCHAR(100) NULL,
	UpdatedAt DATETIME2 NULL,
	UpdatedBy NVARCHAR(100) NULL,
	IsDeleted BIT NOT NULL DEFAULT 0
); 
GO

CREATE TABLE Orders (
	id INT IDENTITY(1,1) PRIMARY KEY,
	id_Customers INT NOT NULL,

	CONSTRAINT FK_Orders_Customers FOREIGN KEY (id_Customers) REFERENCES Customers(id),

	Status  NVARCHAR(50) NOT NULL CHECK (Status IN ('Submitted', 'AwaitingValidation', 'StockConfirmed','Paid', 'Shipped', 'Cancelled')) DEFAULT 'Submitted',
	OrderDate DATETIME2  NOT NULL DEFAULT SYSUTCDATETIME(),
	TotalAmount DECIMAL(18,2) NOT NULL CONSTRAINT CHK_Orders_TotalAmount CHECK (TotalAmount>= 0) DEFAULT 0,

	CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
	CreatedBy NVARCHAR(100) NULL,
	UpdatedAt DATETIME2 NULL,
	UpdatedBy NVARCHAR(100) NULL,
	IsDeleted BIT NOT NULL DEFAULT 0,
	RowVersion  ROWVERSION
);
GO

CREATE TABLE OrderDetails(
	OrderID INT PRIMARY KEY,
	CONSTRAINT FK_OrderDetails_Orders FOREIGN KEY (OrderID) REFERENCES Orders(id) ON DELETE CASCADE,
	ShippingAddress NVARCHAR(400) NOT NULL,
	Comment NVARCHAR(1000) NULL
);
GO

CREATE TABLE Products (
	ProductID INT NOT NULL PRIMARY KEY,
	Name NVARCHAR(200) NOT NULL,
	Price DECIMAL(18,2) NOT NULL CONSTRAINT CHK_Products_Price CHECK (Price > 0), 
	Stock INT NOT NULL CONSTRAINT CHK_Products_Stock CHECK (Stock >= 0),
	UpdatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

CREATE TABLE OrderItems(
	OrderID INT NOT NULL,
	ProductID INT NOT NULL, 
	CONSTRAINT PK_Order_Product PRIMARY KEY (OrderID, ProductID),
	CONSTRAINT FK_OrderItems_Orders FOREIGN KEY (OrderID) REFERENCES Orders(id) ON DELETE CASCADE,
	CONSTRAINT FK_OrderItems_Products FOREIGN KEY (ProductID) REFERENCES Products(ProductID),

	ProductName NVARCHAR(200) NOT NULL,
	UnitPrice DECIMAL(18,2) NOT NULL CONSTRAINT CHK_OrderItems_UnitPrice CHECK (UnitPrice> 0),
	Discount DECIMAL(18,2) NOT NULL CONSTRAINT CHK_OrderItems_Discount CHECK (Discount>= 0) DEFAULT 0, 
	Units INT NOT NULL CONSTRAINT CHK_OrderItems_Units CHECK (Units > 0)
);
GO

CREATE TABLE OrderStatusHistory(
	id INT IDENTITY(1,1) NOT NULL PRIMARY KEY, 
	OrderId INT NOT NULL,

	CONSTRAINT FK_OrderStatusHistory_Orders FOREIGN KEY (OrderID) REFERENCES Orders(id),
	OldStatus NVARCHAR(50) CHECK (OldStatus IS NULL OR OldStatus IN ('Submitted', 'AwaitingValidation', 'StockConfirmed','Paid', 'Shipped', 'Cancelled')) ,
	NewStatus NVARCHAR(50) NOT NULL CHECK (NewStatus IN ('Submitted', 'AwaitingValidation', 'StockConfirmed','Paid', 'Shipped', 'Cancelled')),
	ChangedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
	ChangedBy NVARCHAR(100) NOT NULL
);
GO

CREATE TABLE PaymentRecords (
	id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
	OrderId INT NOT NULL,

	CONSTRAINT FK_PaymentRecords_Orders FOREIGN KEY (OrderID) REFERENCES Orders(id),
	Amount DECIMAL(18,2) NOT NULL CONSTRAINT CHK_PaymentRecords_Amount CHECK (Amount > 0),
	Method NVARCHAR(50) NOT NULL CHECK (Method IN ('Card','Cash','Transfer')),
	Status NVARCHAR(50) NOT NULL CHECK (Status IN ('Pending','Completed','Failed','Refunded')) DEFAULT 'Pending',
	PaidAt DATETIME2 NULL
);
GO


IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Orders_CustomerId_Status' AND object_id = OBJECT_ID('dbo.Orders'))
    CREATE INDEX IX_Orders_CustomerId_Status ON dbo.Orders (id_Customers, Status);
GO
 
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Orders_Active' AND object_id = OBJECT_ID('dbo.Orders'))
    CREATE INDEX IX_Orders_Active ON dbo.Orders (id_Customers) WHERE IsDeleted = 0;
GO
 
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Orders_OrderDate' AND object_id = OBJECT_ID('dbo.Orders'))
    CREATE INDEX IX_Orders_OrderDate ON dbo.Orders (OrderDate DESC);
GO
 
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_OrderItems_ProductId' AND object_id = OBJECT_ID('dbo.OrderItems'))
    CREATE INDEX IX_OrderItems_ProductId ON dbo.OrderItems (ProductId);
GO
 
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_OrderStatusHistory_OrderId_ChangedAt' AND object_id = OBJECT_ID('dbo.OrderStatusHistory'))
    CREATE INDEX IX_OrderStatusHistory_OrderId_ChangedAt ON dbo.OrderStatusHistory (OrderId, ChangedAt);
GO
 
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_PaymentRecords_OrderId' AND object_id = OBJECT_ID('dbo.PaymentRecords'))
    CREATE INDEX IX_PaymentRecords_OrderId ON dbo.PaymentRecords (OrderId);
GO
 
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_Customers_Phone' AND object_id = OBJECT_ID('dbo.Customers'))
    CREATE UNIQUE INDEX UX_Customers_Phone ON dbo.Customers (Phone) WHERE Phone IS NOT NULL;
GO


