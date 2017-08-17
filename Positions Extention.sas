LIBNAME Bench "/var/blade/data2031/esiblade/zchunyou/BenchOpt/Data";


proc sort data=Bench.position_extension out=Positions;
	by Descending Time_Stamp Project_Name Position_Name Primary_Role Descending Assignment_Start_Date;
run;

data Positions2;
	format Assignment_Utilization_cate $char15. End_Month2 $char9. Start_Mon2 $char3. Industry_Vertical2 $char22.
		   Project_Demand_Type2 $char39. Group2 $char31. Project_Revenue_Type2 $char40. Job_Family2 $char30. Client_Name2 $char56.;
	set Positions;

	by Descending Time_Stamp Project_Name Position_Name Primary_Role Descending Assignment_Start_Date;

	where Time_Stamp <> "30SEP2015"D;
	if first.Assignment_Start_Date=1;

	if End_Month='Aug' then End_Month2='August';
		else if End_Month='Dec-14' then End_Month2='December';
		else if End_Month='Nov-14' then End_Month2='November';
		else if End_Month='Oct-14' then End_Month2='October';
		else if End_Month='Sep-14' then End_Month2='September';
		else End_Month2=End_Month;
	if Start_Month in ('1/0/1900','Jan-00') then Start_Mon2='Nov';
		else Start_Mon2=substr(Start_Month,1,3);
	*if Job_Level in (' ','ADV','MG1','MG2','N/A','SEN') then Job_Level2='NULL';
	if Industry_Vertical in (' ','N/V','n/v','LOA','PUB+T426:AQ426SEC & ED','Client HP') then Industry_Vertical2='NULL';
		else Industry_Vertical2=Industry_Vertical;
	if Position_Status=' ' then Position_Status='NULL';
	if Project_Demand_Type in (' ','N/V','New Logo','Overhead') then Project_Demand_Type2='NULL';
		else Project_Demand_Type2=Project_Demand_Type;
	/*if Project_Delivery_Org in (' ','N/V','ABS - Other','ABS-GM','USPS-State and Local Government') then Project_Delivery_Org2='NULL';
		else if Project_Delivery_Org='ABS-US-CMS-Communications and Media Solutions' then Project_Delivery_Org='ABS-US-CME-Communications, Media & Entertainment';
		else if Project_Delivery_Org in ('ITO Portfolio Lifecycle Management',
										'ITO-Enterprise Cloud Services',
										'ITO-Global Production Operations',
										'ITO-Regional Delivery AMS',
										'ITO-Workplace Services') then Project_Delivery_Org='ITO';
	*/
	if Group in ('AMS: Engagement Management','AMS: Leaders','AMS: Practice - Mexico') then Group2='AMS: BI Consulting';
		else Group2=Group;
	if Project_Revenue_Type in (' ','?','External','Overhead') then Project_Revenue_Type2='NULL';
		else Project_Revenue_Type2=Project_Revenue_Type;
	*if Internal_External_Project in (' ','?') then Internal_External_Project2='NULL';
	if Job_Family in(' ','Customer Solution Center-Techn','Field Technical Support','Marketing Analytics and Opera'
						,'Marketing  Analytics and Opera','Business Analysis','Process & Capabilities') then Job_Family2='NULL';
		else if Job_Family in ('Consulting Mgmt') then Job_Family2='Business Consulting';
		else if Job_Family in ('IT Developer/Engineer') then Job_Family2='Information Systems Architect';
		else if Job_Family in ('Application Mgmt Svc Delivery','SVC-ITO Service Delivery','SVC-Practice Principal'
							  ,'Service Segment Management') then Job_Family2='SVC-Customer Proj/Prgm';
		else Job_Family2=Job_Family;
	if Extension_Probability<0.5 then Extension_Probability=0;
		else if Extension_Probability>0.5 then Extension_Probability=1;
		else if Extension_Probability then delete;

	Assignment_Utilization_cate=put(Assignment_Utilization,3.2);
	if Assignment_Utilization_cate='1.0' then Assignment_Utilization_cate='1.0';
		else Assignment_Utilization_cate='less than 1.0';

	if WAAG_Region='AMS';

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

/*
proc freq data=positions (drop=Emp_ID Emp_Name WRaP_Available_From_Date Assignment_Start_Date Assignment_End_Date Project_Name 
  Position_Name Position_Identifier Bus_Level5 Rpt_Level5__Mgr Rpt_Level4_Mgr Employee_Email Company_Senority_Date Original_Hire_Date);
run;

proc freq data=positions2 (drop=Emp_ID Emp_Name WRaP_Available_From_Date Assignment_Start_Date Assignment_End_Date Project_Name 
  Position_Name Position_Identifier Bus_Level5 Rpt_Level5__Mgr Rpt_Level4_Mgr Employee_Email Company_Senority_Date Original_Hire_Date);
run;

proc freq data=positions2;
	table Start_Month;
run;

proc contents data=Positions2; run;
*/

ods graphics on;
PROC logistic data=Positions2 plots(only)=(roc oddsratio(range=clip)) plots(MAXPOINTS=NONE) 
													/*outest=Bench.VelEst_position*/ outmodel=Bench.outmodel_position; 
	class Assignment_Utilization_cate End_Month2 Start_Mon2 Group2 Industry_Vertical2 Client_Name2 Job_Family2 
		  Position_Status Project_Demand_Type2 Project_Revenue_Type2/ param=ref;
	MODEL Extension_Probability(event='1') = Assignment_Utilization_cate End_Month2 Start_Mon2 Group2 Industry_Vertical2 Client_Name2 
		  Job_Family2 Position_Status Project_Demand_Type2 Project_Revenue_Type2 Emp_Duration 
		  Assignment_Duration / stb lackfit firth;
RUN;
QUIT;
ods graphics off;
