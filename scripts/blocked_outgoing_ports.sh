grep 'UFW BLOCK' /var/log/syslog | grep -P 'IN=\s+' | grep -Po '(SPT=\d+|DPT=\d+)' | sort | uniq
