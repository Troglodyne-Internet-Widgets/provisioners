grep 'UFW BLOCK' /var/log/syslog | grep -P 'OUT=\s+' | grep -Po '(SPT=\d+|DPT=\d+)' | sort | uniq
