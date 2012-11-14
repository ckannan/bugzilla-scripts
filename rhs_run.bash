cd /export/ckannan/home-ckannan/bugzilla/scripts/py_charts/Charts/Storage/

# 2.1 data
/usr/bin/perl rhs_run_xmlrpc.pl ckannan@redhat.com redhat | tee rhs_priority.csv  
# 2.1 2.2 future data
/usr/bin/perl rhs_ALL_run_xmlrpc.pl ckannan@redhat.com redhat | tee rhs_ALL_priority.csv  
echo ===============================================================
echo "generating graphs"
#/usr/bin/perl rhs_net_new_every_week.pl
/usr/bin/perl rhs_cumul_every_week.pl
/usr/bin/perl rhs_cumul_every_week_high_urgent.pl  

/usr/bin/perl rhs_ALL_cumul_every_week.pl
/usr/bin/perl rhs_ALL_cumul_every_week_high_urgent.pl  
