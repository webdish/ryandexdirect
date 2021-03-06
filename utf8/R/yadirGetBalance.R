yadirGetBalance <- function(Logins = NULL, Token = NULL){

   if(is.null(Token)){
     stop("Token is a require argument!")
   }

   #Для правильного формирования JSON смотрим к-во логинов и в случае если логин 1 то преобразуем его в lost
   if(length(Logins)==1){
     Logins <- list(Logins)
    }

   #Формируем тело запроса
  body_list <-  list(method = "AccountManagement",
                     param  = list(Action = "Get",
                                   SelectionCriteria = list(Logins = Logins)),
                     locale = "ru",
                     token = Token)

  #Формируем тело запроса
  body_json <- toJSON(body_list,auto_unbox = T, pretty=TRUE)

  #Обращаемся к API
  answer <- POST("https://api.direct.yandex.ru/live/v4/json/", body = body_json)
  
  #Оставливаем при ошибке
  stop_for_status(answer)
  
  #парсим результат
  dataRaw <- content(answer, "parsed", "application/json")
  
  #Ещё одна проверка на ошибки
  if(!is.null(dataRaw$error_code)){
    stop(paste0("Error: code - ",dataRaw$error_code, ", message - ",dataRaw$error_str, ", detail - ",dataRaw$error_detail))
  }
  
  #Преобразуем полученный результат в таблицу
  result <- fromJSON(content(answer, "text", "application/json"),flatten = TRUE)$data$Accounts
  
  #Проверяем все ли логины загрузились
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
