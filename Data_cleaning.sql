use cleaning_data;


SELECT * FROM layoffs;


-- 1.Remove duplicates
-- 2.Standardize data
-- 3.No values or blank values
-- 4. Remove any columns or rows

-- first a copy of the origin table

Create Table layoffs_staging like layoffs ;

Insert Into layoffs_staging 
select * from layoffs;

select * from layoffs_staging;

-- 1. Duplicates

WITH Duplicates_CTE AS 
(
Select * ,
ROW_NUMBER() OVER(
Partition BY company, location,industry,
total_laid_off,percentage_laid_off,`date`,
stage,country,funds_raised_millions) As row_num
from layoffs_staging 
)

select * from Duplicates_CTE WHERE row_num > 1;


CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


insert into layoffs_staging2 
Select * ,
ROW_NUMBER() OVER(
Partition BY company, location,industry,
total_laid_off,percentage_laid_off,`date`,
stage,country,funds_raised_millions) As row_num
from layoffs_staging;

delete from layoffs_staging2 where row_num > 1 ;

select * from layoffs_staging2;

-- 2.standardize data

-- 2.1 get rid of spaces 
Update layoffs_staging2 
set company = TRIM(company);

-- 2.2 same industry but different names
select * from layoffs_staging2 
where industry like 'Crypto%';

update layoffs_staging2 
set industry = 'Crypto'
where industry like 'Crypto%';

-- 2.3 get rid of the final . in country
select distinct Country , TRIM(TRAILING '.' FROM Country ) -- get rid offinal caracter if it is .
from layoffs_staging2 
order by 1;

update layoffs_staging2 
set country =  TRIM(TRAILING '.' FROM Country );

-- 2.4 change the type of `date` from a text to a date  
select `date`,
str_to_date(`date`,'%m/%d/%Y')
from layoffs_staging2;

Update layoffs_staging2
set `date`= str_to_date(`date`,'%m/%d/%Y');

-- 2.5 convert definition to date
ALTER TABLE layoffs_staging2
Modify column `date` DATE ; 

-- 3. Null values or blank values

-- 3.1 find nulls industries or blank 
select * 
from layoffs_staging2
where industry is null or industry = '';

-- 3.2 if it has same company and location so we're gonna give them same industry 
select t1.industry , t2.industry
from layoffs_staging2 t1
join layoffs_staging2 t2
    on t1.company = t2.company 
    and t1.location = t2.location
where (t1.industry is null or t1.industry = '')
and t2.industry is not null ;


Update layoffs_staging2
set industry = null
where industry = '';

-- now we have no blanks values in industry just nulls
Update layoffs_staging2 t1
join layoffs_staging2 t2
    on t1.company = t2.company 
set t1.industry = t2.industry
where t1.industry is null
and t2.industry is not null;

-- 4.Remove rows or columns if we need to
select *
from layoffs_staging2
where percentage_laid_off is null
and total_laid_off is null;


Delete from layoffs_staging2
where percentage_laid_off is null
and total_laid_off is null;

-- Get rid of Row_num
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;


-- THIS IS IT WE ARE DONE
select *
from layoffs_staging2;


