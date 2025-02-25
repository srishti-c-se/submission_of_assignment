-- Ensuring no existing tables before creating new ones
DROP TABLE IF EXISTS INVOICE_ORDERS;
DROP TABLE IF EXISTS INVOICE;
DROP TABLE IF EXISTS ORDER_LINE;
DROP TABLE IF EXISTS ORDERS;
DROP TABLE IF EXISTS SUPPLIERS;

-- Assumptions
-- Phone number is considered as multivalued attribute because a supplier can have multiple phone numbers (telephone, mobile) 
-- Suppliers can have both a telephone and a mobile number with no country code.
-- A telephone number is of 7 digits, does not start with zero, and is numeric.
-- A mobile number is also 8 digits, does not start with zero, and is numeric.
-- If there are to contact numbers one is considered to be home and the other mobile
CREATE TABLE SUPPLIERS ( 
    SUPPLIER_ID            INT IDENTITY(1,1) NOT NULL, -- Primary Key
    SUPPLIER_NAME          VARCHAR(100) NOT NULL,
	SUPP_CONTACT_NAME      VARCHAR(100)  NOT NULL,
    SUPPLIER_ADDRESS       VARCHAR(255) NOT NULL,
	SUPPLIER_TOWN_VILLAGE  VARCHAR (100),
    SUPP_TELEPHONE_NUMBER  CHAR(7) NULL, -- Adjusting to CHAR(7) for exact 7 digits
    SUPP_MOBILE_NUMBER     CHAR(8) NULL, -- Adjusting to CHAR(8) for exact 8 digits
    SUPPLIER_EMAIL         VARCHAR(100) UNIQUE NOT NULL,
	CONSTRAINT pk_supplier_id PRIMARY KEY (SUPPLIER_ID),
	CONSTRAINT chk_phone_number CHECK (
		-- If telephone number exists, it should be 7 digits, numeric, and NOT start with zero
		(SUPP_TELEPHONE_NUMBER IS NULL OR 
		 LEN(SUPP_TELEPHONE_NUMBER) IN (7, 8) AND SUPP_TELEPHONE_NUMBER LIKE '[1-9]%' AND SUPP_TELEPHONE_NUMBER NOT LIKE '%[^0-9]%')
		AND
		-- If mobile number exists, it should be 8 digits, numeric, and NOT start with zero
		(SUPP_MOBILE_NUMBER IS NULL OR 
		 LEN(SUPP_MOBILE_NUMBER) IN (7, 8) AND SUPP_MOBILE_NUMBER LIKE '[1-9]%' AND SUPP_MOBILE_NUMBER NOT LIKE '%[^0-9]%')
	),
	CONSTRAINT chk_email CHECK (
        SUPPLIER_EMAIL LIKE '%_@_%._%' -- Email validation
    )
);


-- Assumptions
--An order can be placed for multiple products.
CREATE TABLE ORDERS (
    ORDER_REF			VARCHAR(20) NOT NULL,
    ORDER_DATE			DATE NOT NULL,
    ORDER_TOTAL_AMOUNT	DECIMAL(12,2) CHECK (ORDER_TOTAL_AMOUNT >= 0),
    SUPPLIER_ID			INT NOT NULL, -- Foreign Key
	CONSTRAINT pk_order_ref PRIMARY KEY (ORDER_REF),
	CONSTRAINT chk_order_ref 
		CHECK (ORDER_REF LIKE 'PO%'),
    CONSTRAINT fk_supplier_id FOREIGN KEY (SUPPLIER_ID) REFERENCES SUPPLIERS(SUPPLIER_ID) ON DELETE CASCADE ON UPDATE CASCADE
);


--Each order line represents an individual product in an order.
--An order status can be "Open," "Closed," "Received," or "Cancelled."
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'ORDER_LINE')
BEGIN
	CREATE TABLE ORDER_LINE (
		ORDER_LINE_ID			INT IDENTITY(1,1) NOT NULL,
		PRODUCT_DESCRIPTION     VARCHAR(255) NULL,
		ORDER_LINE_AMOUNT		DECIMAL(12,2) CHECK (ORDER_LINE_AMOUNT >= 0),
		ORDER_STATUS			VARCHAR(20) CHECK (ORDER_STATUS IN ('Open', 'Closed', 'Received', 'Cancelled')),
		ORDER_REF				VARCHAR(20) NOT NULL, -- Foreign Key
		CONSTRAINT pk_order_line_id PRIMARY KEY (ORDER_LINE_ID),
		CONSTRAINT fk_order_ref FOREIGN KEY (ORDER_REF) REFERENCES ORDERS(ORDER_REF) ON DELETE CASCADE
	);
END

---------------------------------------------------------------------------
--One invoice can pay multiple order lines
--One order line can be paid in multiple invoices (partial payments)
--Tracks multiple payments for a single invoice
--Allows one invoice to be paid on different dates with different amounts
----------------------------------------------------------------------------

--An invoice can pay multiple order lines
CREATE TABLE INVOICE (
	INVOICE_ID			INT IDENTITY(1,1) NOT NULL,
    INVOICE_REF			VARCHAR(20) NOT NULL,
    INVOICE_DATE		DATE,
	CONSTRAINT pk_id_ref PRIMARY KEY (INVOICE_ID),
	CONSTRAINT chk_invoice_ref 
			CHECK (INVOICE_REF LIKE 'INV_PO%'),
);


-- Each invoice can be linked to multiple order lines(different products can be payed in one invoice).
-- Partial payments can be done (one product paid in different invoices)
-- Invoice references start with "INV_PO".
-- Invoice status is either "Paid" or "Pending."
-- An invoice may have a hold reason if it is pending
CREATE TABLE INVOICE_ORDERS (
	INVOICE_ID				INT NOT NULL,
    INVOICE_REF				VARCHAR(20),
    ORDER_LINE_ID			INT NOT NULL, -- Foreign Key
    INVOICE_STATUS			VARCHAR(20) CHECK (INVOICE_STATUS IN ('Paid', 'Pending')),
    INVOICE_HOLD_REASON		VARCHAR(255),
    INVOICE_AMOUNT			DECIMAL(12,2) CHECK (INVOICE_AMOUNT >= 0) CONSTRAINT def_amount DEFAULT 0 ,
    INVOICE_DESCRIPTION		VARCHAR(255),
    CONSTRAINT pk_invoice_orders PRIMARY KEY (INVOICE_ID, ORDER_LINE_ID, INVOICE_AMOUNT),
	CONSTRAINT fk_invoice FOREIGN KEY (INVOICE_ID) REFERENCES INVOICE(INVOICE_ID) ON DELETE CASCADE,
    CONSTRAINT fk_Order_line FOREIGN KEY (ORDER_LINE_ID) REFERENCES ORDER_LINE(ORDER_LINE_ID) ON DELETE CASCADE
);
