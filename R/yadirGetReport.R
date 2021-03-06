yadirGetReport <- function(ReportType = "CAMPAIGN_PERFORMANCE_REPORT", 
                           DateRangeType = "LAST_MONTH", 
                           DateFrom = NULL, 
                           DateTo = NULL, 
                           FieldNames = c("CampaignName","Impressions","Clicks","Cost"), 
                           FilterList = NULL,
                           IncludeVAT = "NO",
                           IncludeDiscount = "NO",
                           Login = NULL,
                           Token = NULL){
  
  #���������� ������ �����
  Fields <- paste0("<FieldNames>",FieldNames, "</FieldNames>", collapse = "")
  
  #��������� ������
  if(!is.null(FilterList)){
    fil_list <- NA
    filt <- FilterList
    for(fil in filt){
      fil_list <- paste0(fil_list[!is.na(fil_list)],
                         paste0("<Filter>",
                                paste0("<Field>",strsplit(fil ," ")[[1]][1], "</Field>"),
                                paste0("<Operator>",strsplit(fil ," ")[[1]][2], "</Operator>"),
                                paste0("<Values>",strsplit(fil ," ")[[1]][3], "</Values>"),"</Filter>"))
    }}
  
  #��������� ���� �������
  queryBody <- paste0('
                      <ReportDefinition xmlns="http://api.direct.yandex.com/v5/reports">
                      <SelectionCriteria>',
                      ifelse(DateRangeType == "CUSTOM_DATE",paste0("<DateFrom>",DateFrom,"</DateFrom>","<DateTo>",DateTo,"</DateTo>") ,"" ),
                      ifelse(is.null(FilterList),"",fil_list),
                      '
                      </SelectionCriteria>',
                      Fields,'
                      <ReportName>',paste0("MyReport ", Sys.time()),'</ReportName>
                      <ReportType>',ReportType,'</ReportType>
                      <DateRangeType>',DateRangeType ,'</DateRangeType>
                      <Format>TSV</Format>
                      <IncludeVAT>',IncludeVAT,'</IncludeVAT>
                      <IncludeDiscount>',IncludeDiscount,'</IncludeDiscount>
                      </ReportDefinition>')
  
  #������ �������������� dataframe
  result <- data.frame()
  
  for(login in Login){
    #������ ��������� � ��� ����� ������ � ������
    packageStartupMessage("-----------------------------------------------------------")
    packageStartupMessage(paste0("�������� ������ �� ",login))
    #���������� ������ �� ������ �������
    answer <- POST("https://api.direct.yandex.com/v5/reports", body = queryBody, add_headers(Authorization = paste0("Bearer ",Token), 'Accept-Language' = "ru", 'Client-Login' = login, returnMoneyInMicros = "false", processingMode = "auto"))
    
    if(answer$status_code == 400){
      packageStartupMessage(paste0(login," - ",xml_text(content(answer, "parsed","text/xml",encoding = "UTF-8"))))
      packageStartupMessage("������ � ���������� ������� ���� ��������� ����������� �� ���������� �������� ��� ������� � �������. � ���� ������ ��������������� ��������� �� ������, �������������� ������ � ��������� ��� �����.")
      next
    }
    
    if(answer$status_code == 500){
      packageStartupMessage(paste0(login," - ",xml_text(content(answer, "parsed","text/xml",encoding = "UTF-8"))))
      packageStartupMessage("��� ������������ ������ ��������� ������ �� �������. ���� ��� ����� ������ ������ �� ������� �������� �������, ���������� ������������ ����� ������. ���� ������ �����������, ���������� � ������ ���������.")
      next
    }
    
    if(answer$status_code == 201){
      packageStartupMessage("����� ������� ��������� � ������� �� ������������ � ������ ������.", appendLF = F)
    }
    
    if(answer$status_code == 202){
      packageStartupMessage("������������ ������ ��� �� ���������.", appendLF = F)
    }
    
    
    while(answer$status_code != 200){
      answer <- POST("https://api.direct.yandex.com/v5/reports", body = queryBody, add_headers(Authorization = paste0("Bearer ",Token), 'Accept-Language' = "ru", 'Client-Login' = login, returnMoneyInMicros = "false", processingMode = "auto"))
      packageStartupMessage(".", appendLF = F)
      if(answer$status_code == 500){
        stop("��� ������������ ������ ��������� ������ �� �������. ���� ��� ����� ������ ������ �� ������� �������� �������, ���������� ������������ ����� ������. ���� ������ �����������, ���������� � ������ ���������.")
      }
      
      Sys.sleep(5)
    }
    
    if(answer$status_code == 200){
      #�������� ������ �������� �����
      names_col <- strsplit(read.csv(text = content(answer, "text"), sep = "\n", stringsAsFactors = F)[1,], "\t")[[1]]
      #�������� ������
      dataRaw <- read.csv(text = content(answer, "text"), sep = "\n", stringsAsFactors = F)[-1,]
      #��������� �������������� �������
      df_new <- read.csv(text = dataRaw,header = F, sep = "\t", col.names = names_col)
      
      #�������� ��������� �� ����� �� ������
      if(is.null(nrow(df_new[-nrow(df_new),]))){
        packageStartupMessage("��� ������ �� ������ ������� ������, ����������� ��������� �������� ������ � ������ ��� ��, ����� ���� ��������� �������.")
        next
      }
      #����� �������� �����
      #names(df_new) <- names_col
      #������� ������ ������
      #df_new <- df_new[-nrow(df_new),]
      packageStartupMessage("����� ������� ����������� � ������� � ���� ������.", appendLF = T)
      
      #���������� � ���������� ������.
      packageStartupMessage(paste0("���������� ������������� ������� ������� ���������� ��������� ��� ��������� � ������ ���������: ",answer$headers$requestid), appendLF = T)
      
      #��������� �����
      if(length(Login) > 1){
        df_new$login <- login}
      
      #������� ������ ������
      df_new <- df_new[!grepl("Total rows", df_new[,1]),]
      #������������ ������ ������ � ��������������� ���� ������
      result <- rbind(result, df_new)
      #��������� ����
    }
  }
  #���������� ���������� ������
  return(result)
}