Uses cURL to get drexel TMS, for a class project.  

Uses various methods to get the full listing of classes from Drexel's TMS site, and then store them in a SQLite database.
 the subject_urls table, along with term and year.

**getDepartmentLists.pl** starts on the TMS home page and gets a listing of all the subject URLs for next year, there are about 200 per term.  These URLs are stored in the subject_URLs table, along with term and year.

**getListOfClassesFromSubjects.pl** uses that data and gets the URLs for the detailed pages.  It stores the URLs in the class_urls table, also with term and year, but also with crn.

**getListOfClasses.pl** is the equivalent for the current year.  It uses the search feature so it only has to download about 5 pages per term to get the class detail URLs.  It also stores the results in class_urls.  It should now get all the URLs for the entire current year when you run it.

**getClassDetails.pl** will get all the detailed info for each class in a given term, which for the time being is set inside the script.

I think that the search only works for the current year, and that when the fall term starts it will start working for that year. 

You should only have to run getDepartmentLists.pl once (maybe set it up to run nightly to be safe as it's pretty quick).  After that, you can run getListOfClasses.pl to update enroll numbers for the current year, and getListOfClassesFromSubjects.pl to update enroll numbers for the Fall term.  getClassDetails.pl will be quite slow and should only need to be ran once a night, or less.