yadirGetBalance <- function(Logins = NULL, Token = NULL){

   if(is.null(Token)){
     stop("Token is a require argument!")
   }

   #��� ����������� ������������ JSON ������� �-�� ������� � � ������ ���� ����� 1 �� ����������� ��� � lost
   if(length(Logins)==1){
     Logins <- list(Logins)
    }

   #��������� ���� �������
  body_list <-  list(method = "AccountManagement",
                     param  = list(Action = "Get",
                                   SelectionCriteria = list(Logins = Logins)),
                     locale = "ru",
                     token = Token)

  #��������� ���� �������
  body_json <- toJSON(body_list,auto_unbox = T, pretty=TRUE)

  #���������� � API
  answer <- POST("https://api.direct.yandex.ru/live/v4/json/", body = body_json)
  
  #����������� ��� ������
  stop_for_status(answer)
  
  #������ ���������
  dataRaw <- content(answer, "parsed", "application/json")
  
  #��� ���� �������� �� ������
  if(!is.null(dataRaw$error_code)){
    stop(paste0("Error: code - ",dataRaw$error_code, ", message - ",dataRaw$error_str, ", detail - ",dataRaw$error_detail))
  }
  
  #����������� ���������� ��������� � �������
  result <- fromJSON(content(answer, "text", "application/json"),flatten = TRUE)$data$Accounts
  
  #��������� ��� �� ������ �����������
  errors_list <- fromJSON(content(answer, "text", "application/json"),flatten = TRUE)$data$ActionsResult
  
  if(length(errors_list) > 0){
  error <- data.frame(login = errors_list$Login, do.call(rbind.data.frame, errors_list$Errors))
  packageStartupMessage(paste0("Next ",nrow(error)," account",ifelse(nrow(error) > 1, "s","")," get error with try get ballance:"), appendLF = T)
  
  for(err in 1:nrow(error)){
  packageStartupMessage(paste0("Login: ", error$login[err]), appendLF = T)
  packageStartupMessage(paste0("....Code: ", error$FaultCode[err]), appendLF = T)
  packageStartupMessage(paste0("....String: ", error$FaultString[err]), appendLF = T)  
  packageStartupMessage(paste0("....Detail: ", error$FaultDetail[err]), appendLF = T)
  }}
    
  return(result)}
