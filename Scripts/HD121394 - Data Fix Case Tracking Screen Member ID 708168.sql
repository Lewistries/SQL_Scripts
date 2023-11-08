-- **************************************************************************************************************************************************
--	https://dsthelpdesk.dst.local/hpd30/Ticket/ShowTicket.aspx?TicketNumber=121394
-- HD121394 - Data Fix Case Tracking Screen Member ID 708168
-- Please change the request status and disability case status to canceled for the case with the Date of disability of 4/28/2022 and retirement date of 8/1/2022
-- **************************************************************************************************************************************************


BEGIN TRY
	BEGIN TRANSACTION;
	PRINT 'TRANSACTION(S) STARTED...';
	-- ***********************************************************************************************
	-- BEGIN SQL STATEMENT(S) - DONT PUT GO STATEMENTS IN YOUR SQL STATEMENTS!
	-- ***********************************************************************************************

	DECLARE	@UpdateUserId		VARCHAR(85) 	=	'HD121394\Sean.Lewis';
	DECLARE	@JournalText		VARCHAR(2000) 	=	'HD121394  - Changed disability case status to cancelled.';
	DECLARE @DisabilityCaseId	INT				=	72672;
	DECLARE @RequestId			INT				=	9531300;
	DECLARE	@PersonId			INT				=	708168;
	DECLARE @CancelStatusCode	VARCHAR(10)		=	'CANC';
	
	IF NOT EXISTS	(
						SELECT TOP 1 DISABILITY_CASE_ID 
						FROM DISABILITY_CASE_STATUS_HISTORY 
						WHERE DISABILITY_CASE_ID = @DisabilityCaseId 
						AND STATUS_CODE= @CancelStatusCode 
						AND CREATE_USER_ID = @UpdateUserId
					)
		BEGIN;

			PRINT 'Add disability status history';
			INSERT INTO DISABILITY_CASE_STATUS_HISTORY 
			(
				[DISABILITY_CASE_ID], 
				[STATUS_CODE], 
				[CREATE_USER_ID], 
				[CREATE_DATETIME]
			)
			VALUES 
			(
				@DisabilityCaseId, 
				@CancelStatusCode, 
				@UpdateUserId, 
				CURRENT_TIMESTAMP
			);

			PRINT 'Update disability case status';
			UPDATE DISABILITY_CASE
			SET 
				[STATUS_CODE] = @CancelStatusCode,
				[STATUS_DATE] = CURRENT_TIMESTAMP,
				[UPDATE_USER_ID] = @UpdateUserId,
				[UPDATE_DATETIME] = CURRENT_TIMESTAMP
			WHERE [DISABILITY_CASE_ID] = @DisabilityCaseId;

			PRINT 'Add Disability Case Comment';
			INSERT INTO DISABILITY_CASE_COMMENT 
			(
				[DISABILITY_CASE_ID], 
				[COMMENTS_TEXT], 
				[CREATE_USER_ID], 
				[CREATE_DATETIME], 
				[UPDATE_USER_ID], 
				[UPDATE_DATETIME], 
				[STATUS_CODE]
			)
			 VALUES 
			(
				@DisabilityCaseId, 
				@JournalText, 
				@UpdateUserId, 
				CURRENT_TIMESTAMP, 
				@UpdateUserId, 
				CURRENT_TIMESTAMP, 
				@CancelStatusCode
			);

			PRINT 'Update request';
			UPDATE REQUEST
			SET 
				[STATUS_CODE] = @CancelStatusCode,
				[STATUS_DATE] = CURRENT_TIMESTAMP,
				[UPDATE_USER_ID] = @UpdateUserId,
				[UPDATE_DATETIME] = CURRENT_TIMESTAMP,
				[COMMENTS] = COALESCE(COMMENTS, '') + ' ' + @JournalText 
			WHERE [REQUEST_ID] = @RequestId
			;

			PRINT'------------------------------------------------------------------------------------';
			PRINT'INSERT PERSON JOURNAL';		
			PRINT'------------------------------------------------------------------------------------';		
			INSERT INTO PERSON_JOURNAL
				(
				PERSON_ID, 
				JOURNAL_DATETIME, 
				PERSON_JOURNAL_COMMENTS,
				SOURCE_CODE, 
				CREATING_MODULE_CODE, 
				JOURNAL_ENTRY_TYPE_CODE, 
				CREATE_USER_ID, 
				CREATE_DATETIME, 
				UPDATE_USER_ID, 
				UPDATE_DATETIME
				)
			SELECT DISTINCT
				PERSON_ID,
				CURRENT_TIMESTAMP, 
				@JournalText, 
				'MANUAL', 
				'MANUAL', 
				'COMM',
				@UpdateUserId, 
				CURRENT_TIMESTAMP, 
				@UpdateUserId, 
				CURRENT_TIMESTAMP
			FROM PERSON p
			Where person_id = @PersonID
			;
		
			PRINT 'Done';
			PRINT '';
	
		END;
	ELSE
	BEGIN;
		PRINT 'Script already executed.';
		PRINT '';
	END;

	-- *********************************************************************************************************
	-- END SQL STATEMENT(S)
	-- *********************************************************************************************************
		
	-- Commit all transactions
	IF @@TRANCOUNT > 0
	BEGIN;
		WHILE @@TRANCOUNT > 0
		BEGIN;
			COMMIT TRANSACTION;
			PRINT 'Transaction Committed...';
		END;
		
		PRINT 'Transaction(s) complete.';
		PRINT 'SQL statement(s) successfully committed.';
	END;
END TRY

-- Catch runtime errors
BEGIN CATCH
	DECLARE @ErrorMessage VARCHAR(2044);
	SET @ErrorMessage = ERROR_MESSAGE() + '  See line number ' + CAST(ERROR_LINE() AS VARCHAR(256)) + '.';
	PRINT 'Runtime Error!  See error message below.';
	
	-- Rollback open transactions
	IF @@TRANCOUNT > 0 
	BEGIN;
		PRINT 'Transaction(s) rolling back...';
		ROLLBACK TRANSACTION;
		PRINT 'Transaction(s) successfully rolled back.';
		PRINT 'Transaction(s) complete.';
	END;
	
	-- Force errors in current windows so user is aware that the script did not run properly
	RAISERROR(@ErrorMessage,16,1);
END CATCH;
GO

-- Handle Compilation Errors (Not caught by Try Catch)
IF @@TRANCOUNT > 0 
BEGIN;
	PRINT 'Compilation Error!  See error message above.';
	
	-- Rollback all open transactions
	PRINT 'Transaction(s) rolling back...';
	ROLLBACK TRANSACTION;
	PRINT 'Transaction(s) successfully rolled back.';
	PRINT 'Transaction(s) complete.';
	PRINT '';
END;
GO