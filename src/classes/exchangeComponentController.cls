public with sharing class exchangeComponentController {

    // форматирование строки для запроса
    public static String formatDate(Date d) {
        return d.year() + '-' + d.month() + '-' + d.day();
    }

    // удаление лишних записей на одну дату с такой же базовой валютой
    public static void deleteOtherRecords (List<Exchange_Rate__c> dataList, Exchange_Rate__c oneRecord){
        for (Integer i = 0; i < dataList.size(); i++){
            if (dataList[0].Base_Currency__c == oneRecord.Base_Currency__c && dataList[0].Date__c == oneRecord.Date__c) {
                dataList.remove(i);
            }
        }
        delete dataList;
    }

    public static String getCurrencyOnRestQuery (Boolean eurOnBase){
        String currencyOnRestQuery = '';
        List<String> currencyNames = getCurrencyNames();
        for (Integer i = 0; i < currencyNames.size(); i++){
            if (eurOnBase == true && currencyNames[i] == 'EUR') {
                continue;
            }
            if ((i+1) == currencyNames.size()) {
                currencyOnRestQuery += currencyNames[i];
            }else {
                currencyOnRestQuery += currencyNames[i] + ',';
            }
        }
        return currencyOnRestQuery;
    }

    // основной метод получения, отдачи и сохранения в базе данных по курсу валюты
    @AuraEnabled
    public static List<Exchange_Rate__c> makeGetCalloutAllData(String baseCurrency, String serviceName, Date dateStart, Date dateEnd) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        // перевод даты в строку для запроса
        String dateStartString, dateEndString;
        if (dateStart != null) {
            dateStartString = formatDate(dateStart);
        }
        if (dateEnd != null) {
            dateEndString = formatDate(dateEnd);
        }
        // получение данных сервиса
        List<Exchange_Api__mdt> settingApi = getSettingsApi(serviceName);
            // формирование строки запроса в соостветствии с входными данными для сервиса без api_key
            if (dateStart != null && dateStart != Date.today() && dateEnd == null) {
                // т.к. сервис не хочет отдавать значение евро (1), когда евро базовая валюта,
                // выполняется проверка на базовую валюту в каждом варианте формирования запроса
                if (baseCurrency == 'EUR') {
                    request.setEndpoint(settingApi[0].Base_URL__c +
                            dateStartString +
                            '?base=' +
                            baseCurrency +
                            '&symbols=' + getCurrencyOnRestQuery(true));
                }else {
                    request.setEndpoint(settingApi[0].Base_URL__c +
                            dateStartString +
                            '?base=' +
                            baseCurrency +
                            '&symbols=' + getCurrencyOnRestQuery(false));
                }
            }
            else if (dateStart == null && dateEnd != null && dateEnd != Date.today()) {
                if (baseCurrency == 'EUR') {
                    request.setEndpoint(settingApi[0].Base_URL__c +
                            dateEndString +
                            '?base=' +
                            baseCurrency +
                            '&symbols=' + getCurrencyOnRestQuery(true));
                }else {
                    request.setEndpoint(settingApi[0].Base_URL__c +
                            dateEndString +
                            '?base=' +
                            baseCurrency +
                            '&symbols=' + getCurrencyOnRestQuery(false));
                }
            }
            else if (dateStart == dateEnd && dateStart != Date.today()) {
                if (baseCurrency == 'EUR') {
                    request.setEndpoint(settingApi[0].Base_URL__c +
                            dateStartString +
                            '?base=' +
                            baseCurrency +
                            '&symbols=' + getCurrencyOnRestQuery(true));
                }else {
                    request.setEndpoint(settingApi[0].Base_URL__c +
                            dateStartString +
                            '?base=' +
                            baseCurrency +
                            '&symbols=' + getCurrencyOnRestQuery(false));
                }
            }
            else if ((dateStart != null && dateEnd != null) && (dateStart != dateEnd)) {
                if (baseCurrency == 'EUR') {
                    request.setEndpoint(settingApi[0].Base_URL__c + 'history?start_at=' +
                            dateStartString +
                            '&end_at=' + dateEndString + '&base=' +
                            baseCurrency +
                            '&symbols=' + getCurrencyOnRestQuery(true));
                }else {
                    request.setEndpoint(settingApi[0].Base_URL__c + 'history?start_at=' +
                            dateStartString +
                            '&end_at=' + dateEndString + '&base=' +
                            baseCurrency +
                            '&symbols=' + getCurrencyOnRestQuery(false));
                }
            }
            else{
                if (baseCurrency == 'EUR') {
                    request.setEndpoint(settingApi[0].Base_URL__c +
                            'latest' +
                            '?base=' +
                            baseCurrency +
                            '&symbols=' + getCurrencyOnRestQuery(true));
                }else {
                    request.setEndpoint(settingApi[0].Base_URL__c +
                            'latest' +
                            '?base=' +
                            baseCurrency +
                            '&symbols=' + getCurrencyOnRestQuery(false));
                }
            }
            request.setMethod('GET');
            HttpResponse response = http.send(request);
            String respString = response.getBody();
            Map<String, Object> resultsAll = (Map<String, Object>) JSON.deserializeUntyped(respString);
            Map<String, Object> resultsRates = (Map<String, Object>) resultsAll.get('rates');   // для проверки наличия и количества записей в базе
            List<Exchange_Rate__c> listCurrency = new List<Exchange_Rate__c>();
            //сравнение результата и, если необходимо, запись в базу
                if (dateStart == dateEnd || (dateStart == null && dateEnd != null) || (dateStart != null && dateEnd == null)) {
                    List<Exchange_Rate__c> dataList = getExchangeRateBD(baseCurrency, Date.valueOf((String) resultsAll.get('date')), null);
                    // формируем данные
                    listCurrency = getExchangeData(resultsAll, baseCurrency, false, response);
                    if (dataList.size() > resultsRates.size() && dataList.size() > 1) {
                        deleteOtherRecords(dataList, listCurrency[0]);
                    }else if (dataList.size() == 0){
                        insert listCurrency;
                    }
                }else {
                    List<Exchange_Rate__c> dataList = getExchangeRateBD(baseCurrency, dateStart, dateEnd);
                    // формируем данные
                    listCurrency = getExchangeData(resultsAll, baseCurrency, true, response);
                    // клон массива для проверки и вставки(удаления) в базу
                    List<Exchange_Rate__c> listCurrencyForBase = listCurrency.deepClone();
                    if (dataList.size() > resultsRates.size()) {
                        delete dataList;
                        insert listCurrencyForBase;
                    }else {
                        for (Integer j = 0; j < dataList.size(); j++){
                            for (Integer i = 0; i < listCurrencyForBase.size(); i++){
                                if (listCurrencyForBase[i].Base_Currency__c == dataList[j].Base_Currency__c && listCurrencyForBase[i].Date__c == dataList[j].Date__c) {
                                    listCurrencyForBase.remove(i);
                                }
                            }
                        }
                        if (listCurrency.size() != 0) {
                            insert listCurrencyForBase;
                        }
                    }

                }
            return listCurrency;
    }

    // функция динамического формирования листаа объектов на основе полей
    public static List<Exchange_Rate__c> getExchangeData (Map<String, Object> resultsAll, String baseCurrency, Boolean manyRecords, HttpResponse response){
        List<Exchange_Rate__c> listCurrency = new List<Exchange_Rate__c>();
        // получение полей объекта Exchange_Rate__c
        String SobjectApiName = 'Exchange_Rate__c';
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Map<String, Schema.SObjectField> fieldMap = schemaMap.get(SobjectApiName).getDescribe().fields.getMap();
        // Запись лога
        Log__c logRecord = new Log__c();
        logRecord.Status_Code__c = '' + response.getStatusCode();
        logRecord.Response_Body__c = (String) response.getBody();
        insert logRecord;
        // false - значит на дату
        if (manyRecords == false) {
            // представление данных запроса
            Map<String, Object> resultsRates = (Map<String, Object>) resultsAll.get('rates');
            // создание нового объекта для записи в базу
            Exchange_Rate__c oneRecord = new Exchange_Rate__c();
            for(String fieldName : fieldMap.keyset())
            {
                if (fieldName.contains('__c') && !fieldName.contains('log') && !fieldName.contains('base') && !fieldName.contains('date') ) {
                    // приведение строки к имени свойства объекта
                    String str = fieldName.replace('__c', '');
                    str = str.toUpperCase();
                    // костыль с евро
                    if (baseCurrency == 'EUR' && str == 'EUR') {
                        oneRecord.put(fieldName, 1);
                    }else {
                        oneRecord.put(fieldName, resultsRates.get(str));
                    }
                }
            }
            // считаем что поля даты и базовой валюты неименны, потому хардкодим
            oneRecord.put('Date__c',  Date.valueOf((String)resultsAll.get('date')));
            oneRecord.put('Base_Currency__c', (String) baseCurrency);
            oneRecord.put('Log__c', logRecord.Id);
            listCurrency.add(oneRecord);
        }else if (manyRecords == true) { // true - диапазон значений
            Map<String, Object> resultsRates = (Map<String, Object>) resultsAll.get('rates');
            for (String date_x : resultsRates.keySet()) {
                Map<String, Object> rateMap = (Map<String, Object>) resultsRates.get(date_x);
                Exchange_Rate__c curCurrency = new Exchange_Rate__c();
                for(String fieldName : fieldMap.keyset())
                {
                    if (fieldName.contains('__c') && !fieldName.contains('log') && !fieldName.contains('base') && !fieldName.contains('date') ) {
                        // приведение строки к имени свойства объекта
                        String str = fieldName.replace('__c', '');
                        str = str.toUpperCase();
                        // костыль с евро
                        if (baseCurrency == 'EUR' && str == 'EUR') {
                            curCurrency.put(fieldName, 1);
                        }else {
                            curCurrency.put(fieldName, rateMap.get(str));
                        }

                    }
                }
                // считаем что поля даты и базовой валюты неименны, потому хардкодим
                curCurrency.Base_Currency__c = (String) baseCurrency;
                curCurrency.Date__c = Date.valueOf(date_x);
                curCurrency.Log__c = logRecord.Id;
                listCurrency.add(curCurrency);
            }
        }
        return listCurrency;
    }

    // получение сокращений валюты для пользователя
    @AuraEnabled
    public static List<String> getCurrencyNames(){
        List<String> currencyNames = new List<String>();
        String SobjectApiName = 'Exchange_Rate__c';
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Map<String, Schema.SObjectField> fieldMap = schemaMap.get(SobjectApiName).getDescribe().fields.getMap();
        for(String fieldName : fieldMap.keyset())
        {
            if (fieldName.contains('__c') && !fieldName.contains('log') && !fieldName.contains('base') && !fieldName.contains('date') ) {
                // приведение строки к имени свойства объекта
                String str = fieldName.replace('__c', '');
                str = str.toUpperCase();
                currencyNames.add(str);
            }
        }
        return currencyNames;
    }

    //    получение записей, хранимых в базе для сравнения и. при необходимости. добавления новых
    public static List<Exchange_Rate__c> getExchangeRateBD (String baseCurrency, Date dateStart, Date dateEnd){
        List<String> currencyNames = getCurrencyNames();
        String nameFields = '';
        for (Integer i = 0; i < currencyNames.size(); i++){
                nameFields += currencyNames[i] + '__c, ';
        }
        if (dateStart != null && dateEnd != null && dateStart != dateEnd) {
            List<Exchange_Rate__c> data = Database.query('SELECT Base_Currency__c, ' + nameFields + ' Date__c FROM Exchange_Rate__c WHERE Date__c >= :dateStart AND Date__c <= :dateEnd AND Base_Currency__c = :baseCurrency');
                return data;
        }else {
            List<Exchange_Rate__c> data = Database.query('SELECT Base_Currency__c, ' + nameFields + ' Date__c FROM Exchange_Rate__c WHERE Date__c = :dateStart AND Base_Currency__c = :baseCurrency');
                return data;
        }
    }

    //    получение данных api для формирования строки запроса
    public static List<Exchange_Api__mdt> getSettingsApi(String serviceName){
        List<Exchange_Api__mdt> settingApi = [SELECT Api_Key__c, Base_URL__c FROM Exchange_Api__mdt WHERE Name__c = :serviceName];
        return settingApi;
    }
}