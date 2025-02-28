/*Antibiogram SAS Code: Jan/Feb 2025, M. Hoskins
This code makes an antibiogram on event data from NHSN and produces a sendable Excel file.

Infectious agents to consider:
_____________________________

Enterococcus  faecalis
Escherichia coli
Klebsiella pneumoniae
Pseudomonas aeruginosa
Staphylococcus aureus 
*/
libname archive "C:\Users\mhoskins1\Desktop\Work Files\NHSN\2019-2024 Archive data"; /*2019-2024 data*/

data antibio_raw;
set archive.linelisting_antibiogram;

run;

/*Antibiogram Macro to replicate this equation:
		%S= (susceptible isolates / total isolates) x 100
*/

/*Step 1: Create a table of the 10-12 most common Pathogens identified*/

/*Add additional cleaning here if necessary*/
data antibio_path;
set antibio_raw;

	format treatment $32.;
	format pathogen_2 $32.;
		pathogen_2= ' ';

if pathogen in ('EC') then pathogen_2 = 'Escherichia coli'; 
if pathogen in ('ENTFS') then pathogen_2 = 'Enterococcus faecalis';
if pathogen in ('PA') then pathogen_2 = 'Pseudomonas aeruginosa';
if pathogen in ('KP') then pathogen_2 = 'Klebsiella pneumoniae';
if pathogen in ('SA') then pathogen_2 = 'Staphylococcus aureus';
/*add more as needed: these are defined in the macro*/

run;
/*Step 1a: Group them*/
proc sql;
create table pathogen_tot as
select
	sum (case when pathogen_2 in ('AMOX') then . else . end) as dummy "Pathogen Isolated",


	sum (case when pathogen_2 in ('Escherichia coli') then 1 else 0 end) as EC "Escherichia coli",
	sum (case when pathogen_2 in ('Klebsiella pneumoniae') then 1 else 0 end) as KP "Klebsiella pneumoniae",
	sum (case when pathogen_2 in ('Enterococcus faecalis') then 1 else 0 end) as BF "Enterococcus faecalis",
	sum (case when pathogen_2 in ('Pseudomonas aeruginosa') then 1 else 0 end) as PA "Pseudomonas aeruginosa",
	sum (case when pathogen_2 in ('Staphylococcus aureus') then 1 else 0 end) as SA "Staphylococcus aureus"
	/*add more as needed*/
from antibio_path 
where pathogen_2 not in (' ')
;
quit;
/*Rework the dummy variable to create a nice table output for pathogen totals*/
data pathogen_tot_2;
set pathogen_tot;

if dummy_2 = put(dummy, 32.) ;
dummy_2="Total # of Isolates";
run;

proc sql;
create table pathogen_tot_final as
select

	dummy_2 "Disease Reported",
	EC,
	KP,
	BF,
	PA,
	SA
from pathogen_tot_2
;
quit;

/*Step 2: This macro takes each treatment variable and creates a table that shows the % susceptible for each of the 10-12 most common Pathogens. Remember 30+ pathogens must be isolated to create an antibiogram*/

%macro antibio_all_2 (abx=);

proc sql;
create table antibio_calc_1_&abx as
select

	/*eventtype,*/
	pathogen_2 'Pathogen Isolated',
	sum (case when  &abx in ('S', 'S-DD') then 1 else 0 end) as path_&abx._SUSC_ "Pathogen + &abx Susceptible",
	sum (case when  &abx not in (' ','N') then 1 else 0 end) as path_&abx._iso_ "Pathogen + &abx Total Isolated",
	
		calculated path_&abx._SUSC_  / calculated path_&abx._iso_ as pct_susc_&abx "Percent Susceptible &abx" format percent10.1


from antibio_path
where pathogen_2 not in (' ')
	group by pathogen_2
	
	having calculated path_&abx._iso_  GE 30
;

create table antibio_calc_1a_&abx as
select 
	
	pathogen_2,
	path_&abx._iso_,
	pct_susc_&abx
	
	from antibio_calc_1_&abx
;

quit;


/*Use this to group %(# isolated)*/
data antibio_calc_grp_&abx;
set antibio_calc_1a_&abx;

label &abx._combine = "% Susceptible &abx (Total Isolated)";
	&abx._combine = cats(put(pct_susc_&abx, percent10.1), "(", put(path_&abx._iso_, 5.), ")");
;
run;
/*finalize table*/
proc sql;
create table antibio_grpfinal_&abx as
select
	pathogen_2, &abx._combine

from antibio_calc_grp_&abx
;
quit;



/*This piece transposes from columns for each treatment to columns for each pathogen: no longer used but keeping in code*/
proc transpose data=antibio_calc_1a_&abx out=antibio_calc_2_&abx;
*by pct_susc_&abx;
id pathogen_2;

run;

*proc print data=antibio_calc_2_&abx noobsrun;

%mend antibio_all_2;

/*Step 3: Run all treatments and join together into one big gross table*/
/*Run ALL treatments*/
%antibio_all_2(abx=AMK);
%antibio_all_2(abx=AMOX);
%antibio_all_2(abx=AMP);
%antibio_all_2(abx=AMPSUL);
%antibio_all_2(abx=AMXCLV);
%antibio_all_2(abx=ANID);
%antibio_all_2(abx=AZT);
%antibio_all_2(abx=CASPO);
%antibio_all_2(abx=CEFAZ);
%antibio_all_2(abx=CEFEP);
%antibio_all_2(abx=CEFOT);
%antibio_all_2(abx=CEFOX);
%antibio_all_2(abx=CEFTAR);
%antibio_all_2(abx=CEFTAVI);
%antibio_all_2(abx=CEFTAZ);
%antibio_all_2(abx=CEFTOTAZ);
%antibio_all_2(abx=CEFTRX);
%antibio_all_2(abx=CEFUR);
%antibio_all_2(abx=CHLOR);
%antibio_all_2(abx=CIPRO);
%antibio_all_2(abx=CLIND);
%antibio_all_2(abx=COL);
%antibio_all_2(abx=CTET);
%antibio_all_2(abx=DAPTO);
%antibio_all_2(abx=DORI);
%antibio_all_2(abx=DOXY);
%antibio_all_2(abx=ERTA);
%antibio_all_2(abx=ERYTH);
%antibio_all_2(abx=FLUCO);
%antibio_all_2(abx=FLUCY);
%antibio_all_2(abx=GENT);
%antibio_all_2(abx=GENTHL);
%antibio_all_2(abx=IMI);
%antibio_all_2(abx=IMIREL);
%antibio_all_2(abx=ITRA);
%antibio_all_2(abx=LEVO);
%antibio_all_2(abx=LNZ);
%antibio_all_2(abx=MERO);
%antibio_all_2(abx=MERVAB);
%antibio_all_2(abx=METH);
%antibio_all_2(abx=MICA);
%antibio_all_2(abx=MINO);
%antibio_all_2(abx=MOXI);
%antibio_all_2(abx=OX);
%antibio_all_2(abx=PB);
%antibio_all_2(abx=PENG);
%antibio_all_2(abx=PIP);
%antibio_all_2(abx=PIPTAZ);
%antibio_all_2(abx=QUIDAL);
%antibio_all_2(abx=RIF);
%antibio_all_2(abx=STREPHL);
%antibio_all_2(abx=TETRA);
%antibio_all_2(abx=TICLAV);
%antibio_all_2(abx=TIG);
%antibio_all_2(abx=TMZ);
%antibio_all_2(abx=TOBRA);
%antibio_all_2(abx=VANC);
%antibio_all_2(abx=VORI);
%antibio_all_2(abx=AZITH);
%antibio_all_2(abx=CEPH);
%antibio_all_2(abx=CLARTH);
%antibio_all_2(abx=GATI);
%antibio_all_2(abx=METRO);
%antibio_all_2(abx=OFLOX);

/*Now merge them together for one big table*/
data merge_test;
set 
antibio_grpfinal_AMK
antibio_grpfinal_AMOX
antibio_grpfinal_AMP
antibio_grpfinal_AMPSUL
antibio_grpfinal_AMXCLV
antibio_grpfinal_ANID
antibio_grpfinal_AZT
antibio_grpfinal_CASPO
antibio_grpfinal_CEFAZ
antibio_grpfinal_CEFEP
antibio_grpfinal_CEFOT
antibio_grpfinal_CEFOX
antibio_grpfinal_CEFTAR
antibio_grpfinal_CEFTAVI
antibio_grpfinal_CEFTAZ
antibio_grpfinal_CEFTOTAZ
antibio_grpfinal_CEFTRX
antibio_grpfinal_CEFUR
antibio_grpfinal_CHLOR
antibio_grpfinal_CIPRO
antibio_grpfinal_CLIND
antibio_grpfinal_COL
antibio_grpfinal_CTET
antibio_grpfinal_DAPTO
antibio_grpfinal_DORI
antibio_grpfinal_DOXY
antibio_grpfinal_ERTA
antibio_grpfinal_ERYTH
antibio_grpfinal_FLUCO
antibio_grpfinal_FLUCY
antibio_grpfinal_GENT
antibio_grpfinal_GENTHL
antibio_grpfinal_IMI
antibio_grpfinal_IMIREL
antibio_grpfinal_ITRA
antibio_grpfinal_LEVO
antibio_grpfinal_LNZ
antibio_grpfinal_MERO
antibio_grpfinal_MERVAB
antibio_grpfinal_METH
antibio_grpfinal_MICA
antibio_grpfinal_MINO
antibio_grpfinal_MOXI
antibio_grpfinal_OX
antibio_grpfinal_PB
antibio_grpfinal_PIPTAZ
antibio_grpfinal_QUIDAL
antibio_grpfinal_RIF
antibio_grpfinal_TETRA
antibio_grpfinal_TIG
antibio_grpfinal_TMZ
antibio_grpfinal_TOBRA
antibio_grpfinal_VANC
antibio_grpfinal_VORI
;

run;

/*Step 4: 
Macro #2: This takes all of the listed treatments and runs a loop on the big, joined table created above to make a condensed table eliminating blank rows and columns.
This uses max case when the antibiotic treatment is not blank or " " and loops it for every treatment column (1-55 - pathogen)*/
%macro condense_table(merge_test);
    /* Get the list of antibiotic column names*/
proc sql noprint;

    select name 
    into :abx_cols separated by ' ' 
    from dictionary.columns 
    where libname = 'WORK' 
    and memname = 'MERGE_TEST' /*Must be upper case idk why SAS is dumb sometimes*/
    and name not in ('pathogen_2');  /* Exclude the pathogen_2 column (just antibiotic prescribing) */
quit;

/*SELECT and GROUP BY clauses for each pathogen by each treatment where "cell" is not blank/missing. this is what will get repeated in the SQL below for each antibiotic*/
	/*Let statements for hardcoded values count of abx, columns of abx, group by pathogen_2*/
%let abx_count = %sysfunc(countw(&abx_cols));
%let select_clause = ;
%let group_by_clause = pathogen_2; /* Group by pathogen_2 */
/*Keep list is the list of antibiotics we're interested in keeping: Pathogen + any antibiotics we want to view*/
%let keep_list = 
	Pathogen_2
	AMK_combine
	AMP_combine
	AMPSUL_combine
	CEFAZ_combine
	CEFEP_combine
	CEFTRX_combine
	CIPRO_combine
	CLIND_combine
	ERYTH_combine
	GENT_combine
	IMI_combine
	LEVO_combine
	MERO_combine
	PIPTAZ_combine
	TOBRA_combine;
/*Do loop for 1 to abx # select max case when col not missing (ie. first non-missing value per column)*/
%do i = 1 %to &abx_count; /*1 to number of abx*/
    %let abx_col = %scan(&abx_cols, &i);
    %let select_clause = &select_clause
        , max(case when &abx_col ne '' then &abx_col else '' end) as &abx_col; /*Cool trick, put the comma (,) at the front so it doesn't tack an extra comma at the end of your SQL list and return an error*/
%end;

/*test select_clause: view log here if something f's up. it's probably this.*/
%put &=select_clause; 

/* Now run the final PROC SQL query with the generated SELECT statement */
proc sql;
    create table condensed_table as
    select &group_by_clause
        &select_clause
    from merge_test /* OG dataset name */
    group by pathogen_2;
quit;

/*Can do some cleaning here if necessary and keeping only antibiotics we're concerned with*/
data condensed_table_2;
set condensed_table (keep = &keep_list rename=(pathogen_2=pathogen_dummy));

   length pathogen_2 $64;
   pathogen_2=cats(pathogen_dummy, ': % Susceptible (# Isolates)');/*Add final piece of label to pathogens, will look nicer in output*/
   drop pathogen_dummy;

   label pathogen_2 = "Pathogen Isolated";

label AMK_combine = "Amikacin";
label AMP_combine = "Ampicillin";
label AMPSUL_combine = "Ampicillin/ Sulbactam";
label CEFAZ_combine = "Cefazolin";
label CEFEP_combine = "Cefepime";
label CEFTRX_combine = "Ceftriaxone";
label CIPRO_combine = "Ciprofloxacin";
label CLIND_combine = "Clindamycin";
label ERYTH_combine = "Erythromycin";
label GENT_combine = "Gentamicin";
label IMI_combine = "Imipenem/ Cilastatin/ Relebacam";
label LEVO_combine = "Levofloxacin";
label MERO_combine = "Meropenem/ Vaborbactam";
label PIPTAZ_combine = "Piperacillin/ Tazobactam";
label TOBRA_combine = "Tobramycin";

run;
/*Doesn't really need to be in the macro but why not*/
/*order table from most narrow to most broad antibiotics*/
proc sql;
create table condensed_table_final as
select

	pathogen_2,

	CLIND_combine,
	CEFAZ_combine,
	GENT_combine,
	TOBRA_combine,
	AMK_combine,
	CIPRO_combine,
	LEVO_combine,
	AMP_combine,
	AMPSUL_combine,
	CEFTRX_combine,
	CEFEP_combine,
	MERO_combine,
	IMI_combine,
	PIPTAZ_combine,
	ERYTH_combine

from condensed_table_2
;
quit;

%mend;

%condense_table(merge_test);
/*View table*/
proc print data=condensed_table_final noobs label;run;



/*Step 5: export*/
/*ODS export*/
title; footnote;
/*Set your output pathway here*/
ods excel file="C:\Users\mhoskins1\Desktop\Work Files\antibiogram\anitbiogram_2019 2024_test_&sysdate..xlsx" style=meadow;
ods excel options (sheet_interval = "none" sheet_name = "antibiogram_2" embedded_titles='Yes');
options missing='';
footnote;
title height=9pt justify=left "Pathogens isolated, North Carolina 2019-2024";
title2;
proc print data=pathogen_tot_final noobs label;run;

title height=8pt justify=left"Pathogen identified and susceptibility by treatment, North Carolina 2019-2024";
title2 height=8pt justify=left "*among reported events, treatment classification narrow to borad spectrum left to right";
proc print data=condensed_table_final noobs label;run;

ods excel close;

