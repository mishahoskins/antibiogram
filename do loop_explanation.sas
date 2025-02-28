

proc sql noprint;

    select name 
    into :variable_cols separated by ' ' /*variable_cols is how many columns you're looking at*/
    from dictionary.columns 
    where libname = 'WORK' 
    and memname = 'DATASET_NAME' /*Name of your dataset, must be upper case idk why SAS is dumb sometimes*/
    and name not in ('variable_exclude');  /* Exclude any columns you don't want counted*/
quit;



%let column_number = %sysfunc(countw(&variable_cols));/*counting the number of columns you defined above*/

/*Do loop for 1 to column # select max case when col not missing (ie. first non-missing value per column)*/
%do i = 1 %to &column_number; /*1 to number of columns (defined above)*/
    %let newvariable_col = %scan(&variable_cols, &i);
    %let select_clause = &select_clause
/*Cool trick, put the comma (,) at the front so it doesn't tack an extra comma at the end of your SQL list and return an error*/
        , max(case when &newvariable_col ne '' then &newvariable_col else '' end) as &newvariable_col; 
%end;

/*test select_clause: view log here if something f's up. it's probably this.*/
%put &=select_clause; 
