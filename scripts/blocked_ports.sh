grep 'UFW BLOCK' /var/log/syslog | awk '{print $19}' | sed 's/DPT=//' | sort | uniq
