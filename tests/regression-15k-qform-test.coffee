#Compile "15158/15158_complex_includes.per"


#CheckXML
#  fileName:"15158/15158_complex_includes"  # fn alias can be used, if ommited - fn will be calculated from current test filename
#  method:"select"                          # select is default
#  query:"//textfield[@identifier='f1']/preferredsize" # Required. xpath alias can be used for query
#  sample:'<preferredsize width="32" height="22"/>'    # sample
#  timeout:20000                    # 10000 is default
#  fail:true                        # reverse alias can be used. Test results will be reversed

# if fm2 file was provided, exact path will be usedcan not be found in 
# if no extension (or per extension as default one) form will be compiled prior (once per file)
# default output path for fm2 if "./../output" or temp folder will be used if output folder in not accessible

#CheckXML
#  fileName:"15158/15158_complex_includes"
#  query:"//textfield[@identifier='f1']/preferredsize"
#  sample:'<preferredsize width="32" height="22"/>'

