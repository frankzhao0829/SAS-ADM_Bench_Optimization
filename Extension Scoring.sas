LIBNAME Bench "/var/blade/data2031/esiblade/zchunyou/BenchOpt/Data";


/*** Scoring based on Positions level data from Bench_Outlook file ***/ 

data Positions_RollOff (drop=Assignment_Utilization_cate) Positions_Bench (drop=Assignment_Utilization_cate);
	set BENCH.Resource_Workbook_Archive;
	
	if Data_As_Of="30SEP2015"D;
	if WAAG_Region='AMS';

	Assignment_Utilization_cate=put(Current_Month_LDSM_Assignment_Ut,3.2);
	if Assignment_Utilization_cate in ('.00','.') then output Positions_Bench;
		else output Positions_RollOff;
run;

data Positions_RollOff_2;
	format Assignment_Utilization_cate $char15. End_Month2 $char9. Start_Mon2 $char3. Industry_Vertical2 $char22.
		   Project_Demand_Type2 $char39. Group2 $char31. Project_Revenue_Type2 $char40. Job_Family2 $char30. Client_Name2 $char56.;
	set Positions_RollOff;

	flag=0;
	if Assignment_End_Date=. then End_Month2='November';
		else End_Month2=left(put(Assignment_End_Date,monname9.));
	if Assignment_Start_Date=. then Start_Mon2='Nov';
		else Start_Mon2=put(Assignment_Start_Date,monname3.);

	if Industry_Vertical not in ('COMM M&E','FINANCE INDUSTR','HLTH & LIFE SC','MFG & DIST','NULL','PUBSEC & ED','TGTD INDUSTRIES') 
			then Industry_Vertical2='NULL';
		else Industry_Vertical2=Industry_Vertical;

	if Position_Status=' ' then do;
		Position_Status='NULL';
		flag=1;
		end;

	if Project_Demand_Type in (' ','N/V','New Logo','Overhead') then Project_Demand_Type2='NULL';
		else if Project_Demand_Type in ('Add-On to Existing Project','Add on to Existing Deal – New Project') 
			then Project_Demand_Type2='Add on to Existing Deal – New Project';
		else Project_Demand_Type2=Project_Demand_Type;

	if Group in ('AMS: BI Consulting','AMS: Canada','AMS: Content Management','AMS: Data Engineering'
				,'AMS: Latin America','AMS: Practice','AMS: SOA & Integration Services','AMS: SharePoint') then Group2=Group;
		else Group2='AMS: BI Consulting';
	if Project_Revenue_Type in (' ','?','External','Overhead') then Project_Revenue_Type2='NULL';
		else Project_Revenue_Type2=Project_Revenue_Type;

	if Job_Family in ('Consulting Mgmt') then Job_Family2='Business Consulting';
		else if Job_Family in ('IT Developer/Engineer') then Job_Family2='Information Systems Architect';
		else if Job_Family in ('Application Mgmt Svc Delivery','SVC-ITO Service Delivery','SVC-Practice Principal'
							  ,'Service Segment Management') then Job_Family2='SVC-Customer Proj/Prgm';
		else if Job_Family in ('Business Consulting','College','Data Engineering','Engagement','Information Systems Architect'
							  ,'NULL','SVC-Customer Proj/Prgm','Svc Information Development','Tech Consulting') then Job_Family2=Job_Family;
		else Job_Family2='NULL';

	Assignment_Utilization_cate=put(Current_Month_LDSM_Assignment_Ut,3.2);
	if Assignment_Utilization_cate='1.0' then Assignment_Utilization_cate='1.0';
		else Assignment_Utilization_cate='less than 1.0';

	if Client_Name not in ('BHP BILLITON'
						  ,'CONTINENTAL AIRLINES INC'
						  ,'KRAFT FOODS GROUP INC'
						  ,'ALLY FINANCIAL INC'
						  ,'CVS CAREMARK CORPORATION'
						  ,'HEALTHWAYS INC'
						  ,'SYMANTEC CORPORATION'
						  ,'DPH HOLDINGS CORP'
						  ,'GOVT OF ONTARIO (FRAGMENT)'
						  ,'PROVINCE OF MANITOBA (W/O HYDRO)'
						  ,'BLACK & VEATCH HOLDING COMPANY'
						  ,'DREAMWORKS ANIMATION SKG INC'
						  ,'LOA'
						  ,'PROCTER & GAMBLE COMPANY THE'
						  ,'WAL-MART STORES INC'
						  ,'KONINKLIJKE AHOLD NV'
						  ,'RI SLED CORPORATE LOB STATE'
						  ,'ABBVIE INC'
						  ,'BLUE CROSS & BLUE SHIELD ASSOCIATION'
						  ,'OTHER INDUSTRIES / TARGETED INDUSTRIES-BUSINESS SERVICES'
						  ,'HEWLETT-PACKARD COMPANY') then Client_Name2 = 'NULL';
		else Client_Name2 = Client_Name;

	if Original_Hire_Date=. then Emp_Duration=2113;
		else Emp_Duration="31AUG2015"D-Original_Hire_Date;
	if Assignment_Start_Date=. or Assignment_End_Date=. then Assignment_Duration=337;
		else Assignment_Duration=Assignment_End_Date-Assignment_Start_Date;
run;


PROC logistic inmodel=Bench.outmodel_position; 
	score data=Positions_RollOff_2 out=Positions_RollOff_Scores; 
run;

data Positions_RollOff_Scored;
	set Positions_RollOff_Scores; 

	if flag=1 then Position_Status=' ';

	drop flag Assignment_Utilization_cate End_Month2 Start_Mon2 Industry_Vertical2 Project_Demand_Type2 Group2 Project_Revenue_Type2 
		 Job_Family2 Client_Name2 I_Extension_Probability;
	rename P_0=Probability_Position_Not_Extend P_1=Probability_Position_Extend Client_Name=Client_Name2;
run;



/*** Scoring based on Employees level data from BDR DB ***/

*Join BDR data to Roll Off data;
proc sql;
create table Employee_RollOff as
select a.*
	  ,b.Report_Date
	  ,b.Client_ID
	  ,case when b.Client_Name='ABS LEVERAGED DEMAND ACCOUNTS' then 'ABS Leveraged Demand Accounts'
			when b.Client_Name not in ('Ally Financial Inc.'
									,'BLUE SHIELD OF CALIFORNIA'
									,'CONSIP'
									,'CVS'
									,'Client HP'
									,'DELPHI CORPORATION'
									,'DHL WORLDWIDE EXPRESS'
									,'GHC OHIO-HLTH'
									,'General Motors Company'
									,'HEALTHWAYS'
									,'HEWLETT PACKARD'
									,'INPS ISTITUTO NAZ PREVIDENZA SOC'
									,'MOTORIZZAZIONE CIVILE'
									,'MULTIPLE - MANUFACTURING'
									,'MULTIPLE - OTHER'
									,'Mitsubishi UFJ Financial Group'
									,'NATIONAL ACCOUNT SERVICE COMPANY'
									,'NULL'
									,'PROCTER AND GAMBLE'
									,'SKF'
									,'TOWNHALL FRANKFURT ODER'
									,'UAL Corporation') then 'NULL' else b.Client_Name end as Client_Name
	  ,case when b.Project_Entity_Type='Others' then 'LDSM Project' else b.Project_Entity_Type end as Project_Entity_Type
	  ,case when b.Position_Role in  ('DO NOT USE - BAS-SPE-01-DC','DO NOT USE - Technology Consultant IV [00S36I]',
			'Fellow','Supervisor 1','DO NOT USE - Unspecified','Primary','Base','Core','Strategist','NULL') then 'Entry' 
			else b.Position_Role end as Position_Role
	  ,b.Position_Fill_Status_Ext
	  ,put(b.Position_Start_Month,2.) as Position_Start_Month
	  ,case when b.Practice in ('ES Horizontal','Industry Solutions','N/A','N/V','Non-Practice (ITO)') then 'NULL' 
			else b.Practice end as Practice
	  ,case when b.OTD_Rec_Type='No Position Start Date' then 'ROD Approval After Start' else b.OTD_Rec_Type end as OTD_Rec_Type
	  ,b.Project_Owning_Region 
	  ,case when b.Project_Owning_SubRegion in ('CEE','France Extended','Italy','N/V') then 'NULL' 
			else b.Project_Owning_SubRegion end as Project_Owning_SubRegion
	  ,b.Project_Owning_Country 
	  ,case when b.Demand_Status in ('Manage Volumetric Service','On Hold','Open','Pending Charter/Scope Approval','Pending Closure','Prospective'
					'Pending Plan Approval','Pending ROD Approval','Prepare Project Closure','Processing','Validate Project')
			then 'Complete' else b.Demand_Status end as Demand_Status
	  ,b.Position_Start_Date   
	  ,b.Position_End_Date 
	  ,put(month(b.Position_End_Date),2.) as Position_End_Month
	  ,case when b.Position_Start_Date=. or b.Position_End_Date=. then 446
	   	  else b.Position_End_Date - b.Position_Start_Date end as Position_Duration
	  ,b.Position_Filled_FTE   
	  ,b.Position_Allocated_FTE
	  ,case when b.Position_Allocated_FTE=0 then 0
	  	  else 100*Position_Filled_FTE/Position_Allocated_FTE end as Position_Fill_Ratio
      ,input(case when b.Days_To_Fill='NULL' then '0' else b.Days_To_Fill end,4.) as Days_To_Fill
	  
	  ,b.WRKFRC_ID
from Positions_RollOff_Scored a
	left join Bench.employee_20151012 b on a.Position_Identifier=b.Position_ID and a.Emp_ID=b.WRKFRC_ID;
quit;


PROC logistic inmodel=Bench.outmodel_employee; 
	score data=Employee_RollOff out=Employee_RollOff_Scores; 
run;

data Employee_RollOff_Scored;
	set Employee_RollOff_Scores;

    if P_1=. then P_1=0.5;
	if P_0=. then P_0=0.5;

	keep Emp_ID Position_Identifier Probability_Position_Extend P_1;
	rename P_1=Probability_Employee_Extend;
run;


*join the scored probabilities to original dataset;
proc sql;
create table Positions_RollOff_Scored as
select a.*
	  ,b.Probability_Position_Extend
	  ,b.Probability_Employee_Extend
from Positions_RollOff a
	left join Employee_RollOff_Scored b on a.Emp_ID=b.Emp_ID and a.Position_Identifier=b.Position_Identifier;
quit;

*Remove current month data in archive to remove duplicate records;
data Resource_Workbook_Archive;
	set BENCH.Resource_Workbook_Archive;

	Probability_Position_Extend=.; 	Probability_Employee_Extend=.;
	if Data_As_Of="30SEP2015"D then delete;
run;


data Positions_Bench;
	set Positions_Bench;

	Probability_Position_Extend=.; 	Probability_Employee_Extend=.;
run;

*Append current month bech employees and archive data to scored dataset;
proc append base=Positions_RollOff_Scored data=Positions_Bench;
proc append base=Positions_RollOff_Scored data=Resource_Workbook_Archive;
run;

proc sort data=Positions_RollOff_Scored out=BENCH.Resource_Workbook_Archive;
	by Data_As_Of;
run;


*Add Lag Current Month FTE to calculate historical RollOff FTE;
data resource newposition;
	format Lag_Current_Month_Ut $Char5. RollOff 8.;
	set Bench.resource_workbook_archive;

	Lag_Current_Month_Ut=' ';
	RollOff=.;

	if Emp_Name=' ' and Data_As_Of="01SEP2015"D then Data_As_Of="30SEP2015"D;

	if Emp_Name=' ' then output newposition;
		else output resource;
run;

proc sort data=resource;
	by Emp_ID Data_As_Of;
run;

data resource_lag;
	format Lag_Current_Month_Ut $Char5. Assignment_Ut_test lag_Ut_test RollOff 4.2 ;
	set resource;

	by Emp_ID Data_As_Of;

	Lag_Current_Month_Ut=lag(Current_Month_LDSM_Assignment_Ut);
	if first.Emp_ID=1 then Lag_Current_Month_Ut=Current_Month_LDSM_Assignment_Ut;

	if Current_Month_LDSM_Assignment_Ut=' ' then Assignment_Ut_test=0.00;
		else Assignment_Ut_test=input(Current_Month_LDSM_Assignment_Ut,percent5.);
	if Lag_Current_Month_Ut=' ' then lag_Ut_test=0.00;
		else lag_Ut_test=input(Lag_Current_Month_Ut,percent5.);

	if lag_Ut_test>Assignment_Ut_test then RollOff=lag_Ut_test-Assignment_Ut_test;
		else RollOff=0;

	drop lag_Ut_test Assignment_Ut_test;
run;

proc sort data=resource_lag;
	by Data_As_Of;
run;

proc append base=resource_lag data=newposition;
run;

