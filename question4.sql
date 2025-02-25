CREATE PROCEDURE sp_SupplierOrderSummary
AS
BEGIN
	BEGIN TRY
        BEGIN TRANSACTION;

		SELECT 
		    -- Supplier region (town or village)
		    tblSupp.SUPPLIER_TOWN_VILLAGE AS Region,
		    
		    -- Extract numeric part before dash and numeric part after dash, combine as decimal
			CASE
			    WHEN CHARINDEX('-', tblOrd.ORDER_REF) > 0 THEN
			        -- If there's a dash, extract the part before the dash (get only the number before '-')
			        CAST(SUBSTRING(tblOrd.ORDER_REF, 3, CHARINDEX('-', tblOrd.ORDER_REF) - 3) AS INT)
			    ELSE
			        -- If there's no dash, remove 'PO' and return only the numeric part
			        CAST(SUBSTRING(tblOrd.ORDER_REF, 3, LEN(tblOrd.ORDER_REF) - 2) AS INT)
			END AS OrderReference,
		           
		    -- Format order period 
		    FORMAT(tblOrd.ORDER_DATE, 'yyyy-MM') AS OrderPeriod,
		    
		    -- Supplier name 
			CONCAT(
		        UPPER(SUBSTRING(tblSupp.SUPPLIER_NAME, 1, 1)), 
		        LOWER(SUBSTRING(tblSupp.SUPPLIER_NAME, 2, LEN(tblSupp.SUPPLIER_NAME)))
		    ) AS SupplierName,

		    FORMAT(tblOrd.ORDER_TOTAL_AMOUNT, 'N2') AS OrderTotalAmount,
		    
		    -- Order status
		    tblLine.ORDER_STATUS AS OrderStatus,
		    
		    tblInvoice.INVOICE_REF AS InvoiceReference,

		   FORMAT(SUM(tblInvoiceAmount.INVOICE_AMOUNT), 'N2') AS Invoice_Total_Amount,

		CASE 
		        WHEN COUNT(DISTINCT tblInvoiceAmount.INVOICE_STATUS) = 1 
		             AND MAX(tblInvoiceAmount.INVOICE_STATUS) = 'Paid' THEN 'No Action'
		        WHEN COUNT(DISTINCT tblInvoiceAmount.INVOICE_STATUS) > 1 
		             AND 'Pending' IN (SELECT INVOICE_STATUS FROM INVOICE_ORDERS WHERE ORDER_LINE_ID = tblLine.ORDER_LINE_ID) THEN 'To follow up'
		        ELSE 'To verify'
		    END AS Action


		FROM 
		    SUPPLIERS tblSupp
		INNER JOIN 
		    ORDERS tblOrd ON tblSupp.SUPPLIER_ID = tblOrd.SUPPLIER_ID
		INNER JOIN 
		    ORDER_LINE tblLine ON tblOrd.ORDER_REF = tblLine.ORDER_REF
		LEFT JOIN 
		    INVOICE_ORDERS tblInvoiceAmount ON tblLine.ORDER_LINE_ID = tblInvoiceAmount.ORDER_LINE_ID
		LEFT JOIN 
		    INVOICE tblInvoice ON tblInvoiceAmount.INVOICE_ID = tblInvoice.INVOICE_ID
		
		-- Group by Supplier region (town or village)
		GROUP BY 
		    tblSupp.SUPPLIER_TOWN_VILLAGE,
		    tblOrd.ORDER_REF,
		    tblOrd.ORDER_DATE,
		    tblOrd.ORDER_TOTAL_AMOUNT,
		    tblSupp.SUPPLIER_NAME,
		    tblLine.ORDER_STATUS,
		    tblInvoice.INVOICE_REF,
			tblLine.ORDER_LINE_ID 
		-- Order by region and order total amount
		ORDER BY 
		    tblSupp.SUPPLIER_TOWN_VILLAGE,
		    OrderTotalAmount DESC;
		COMMIT TRANSACTION;
		END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        PRINT 'Error Occurred: ' + ERROR_MESSAGE();
        THROW; 
    END CATCH
END
