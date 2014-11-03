####################################################################
# Purpose: Rename the ISAPI redirect log so log rotation will group 
#			activities that occurr in the same timeframe
#
# Description: This can only be done if IIS is stopped so the
#				so the application must be stopped
#
# This file authored at St. Louis Community College
# dgioia3@stlcc.edu
####################################################################
[string]$strDatestamp=(get-date -uformat %Y-%m-%d).ToString()
rename-item -path "$env:blackboard_home\logs\isapi_redirect.log" -NewName "bb-isapi_redirect-$strDatestamp.txt"
# eof