@IsTest
private class exchangeComponentControllerTest {
    @IsTest
    static void formatDateTest() {
        Test.startTest();
        Date testDate = Date.newInstance(2021, 02, 01);
        System.assertEquals('2021-2-1', exchangeComponentController.formatDate(testDate));
        Test.stopTest();
    }

    @IsTest(SeeAllData=true)
    static void getCurrencyNamesTest (){
        Test.startTest();
        List<String> currencyNames = exchangeComponentController.getCurrencyNames();
        System.assertEquals(4, currencyNames.size());
        Test.stopTest();
    }

    @IsTest
    static void getExchangeRateBDTest(){
        Date testDate = Date.newInstance(2021, 02, 01);
        Date testDate2 = Date.newInstance(2021, 02, 02);

        List<Exchange_Rate__c> lExchangeRates = new List<Exchange_Rate__c>();

        Exchange_Rate__c testExchangeRate = new Exchange_Rate__c();
        testExchangeRate.Base_Currency__c = 'GBP';
        testExchangeRate.GBP__c = 1;
        testExchangeRate.EUR__c = 2;
        testExchangeRate.USD__c = 3;
        testExchangeRate.CAD__c = 4;
        testExchangeRate.Date__c = testDate;

        Exchange_Rate__c testExchangeRate2 = new Exchange_Rate__c();
        testExchangeRate2.Base_Currency__c = 'GBP';
        testExchangeRate2.GBP__c = 11;
        testExchangeRate2.EUR__c = 21;
        testExchangeRate2.USD__c = 31;
        testExchangeRate2.CAD__c = 41;
        testExchangeRate2.Date__c = testDate2;

        lExchangeRates.add(testExchangeRate);
        lExchangeRates.add(testExchangeRate2);
        insert lExchangeRates;

        Test.startTest();

        List<Exchange_Rate__c> exchangeRates = exchangeComponentController.getExchangeRateBD('GBP', testDate, null);
        System.assertEquals(1, exchangeRates.size());

        List<Exchange_Rate__c> exchangeRates2 = exchangeComponentController.getExchangeRateBD('GBP', testDate, testDate2);
        System.assertEquals(2, exchangeRates2.size());
        Test.stopTest();

    }

    @IsTest(SeeAllData=true)
    static void getSettingsApiTest(){
        Test.startTest();
        List<Exchange_Api__mdt> settingApitest = exchangeComponentController.getSettingsApi('exchangerates');
        System.assertEquals(1, settingApitest.size());
        Test.stopTest();
    }

    @IsTest
    static void deleteOtherRecordsTest(){
        Date testDate1 = Date.newInstance(2021, 02, 01);
        Date testDate2 = Date.newInstance(2021, 02, 02);

        List<Exchange_Rate__c> lExchangeRates = new List<Exchange_Rate__c>();

        Exchange_Rate__c testExchangeRate = new Exchange_Rate__c();
        testExchangeRate.Base_Currency__c = 'GBP';
        testExchangeRate.GBP__c = 1;
        testExchangeRate.EUR__c = 2;
        testExchangeRate.USD__c = 3;
        testExchangeRate.CAD__c = 4;
        testExchangeRate.Date__c = testDate1;

        Exchange_Rate__c testExchangeRate2 = new Exchange_Rate__c();
        testExchangeRate2.Base_Currency__c = 'GBP';
        testExchangeRate2.GBP__c = 11;
        testExchangeRate2.EUR__c = 21;
        testExchangeRate2.USD__c = 31;
        testExchangeRate2.CAD__c = 41;
        testExchangeRate2.Date__c = testDate1;

        Exchange_Rate__c testExchangeRate3 = new Exchange_Rate__c();
        testExchangeRate3.Base_Currency__c = 'GBP';
        testExchangeRate3.GBP__c = 11;
        testExchangeRate3.EUR__c = 21;
        testExchangeRate3.USD__c = 31;
        testExchangeRate3.CAD__c = 41;
        testExchangeRate3.Date__c = testDate1;

        Exchange_Rate__c testExchangeRate4 = new Exchange_Rate__c();
        testExchangeRate4.Base_Currency__c = 'GBP';
        testExchangeRate4.GBP__c = 1;
        testExchangeRate4.EUR__c = 2;
        testExchangeRate4.USD__c = 3;
        testExchangeRate4.CAD__c = 4;
        testExchangeRate4.Date__c = testDate2;

        Exchange_Rate__c testExchangeRate5 = new Exchange_Rate__c();
        testExchangeRate5.Base_Currency__c = 'GBP';
        testExchangeRate5.GBP__c = 1;
        testExchangeRate5.EUR__c = 2;
        testExchangeRate5.USD__c = 3;
        testExchangeRate5.CAD__c = 4;
        testExchangeRate5.Date__c = testDate2;

        lExchangeRates.add(testExchangeRate);
        lExchangeRates.add(testExchangeRate2);
        lExchangeRates.add(testExchangeRate3);
        lExchangeRates.add(testExchangeRate4);
        lExchangeRates.add(testExchangeRate5);
        Test.startTest();
        insert lExchangeRates;
        exchangeComponentController.deleteOtherRecords(lExchangeRates, testExchangeRate);
        Test.stopTest();
    }

    static void makeGetCalloutAllDataTestFuncOnDate(Integer var){
        Date testDate1 = Date.newInstance(2021, 02, 01);
        String webServiceName = 'exchangerates';
        String baseCurrency = 'GBP';
        String baseCurrency2 = 'EUR';
        Test.startTest();
        StaticResourceCalloutMock mockDate = new StaticResourceCalloutMock();
        mockDate.setStaticResource('currencyDate');
        mockDate.setStatusCode(200);
        mockDate.setHeader('Content-Type', 'application/json;charset=UTF-8');
        Test.setMock(HttpCalloutMock.class, mockDate);
        switch on var {
            when 1 {
                List<Exchange_Rate__c> cExchangeRatesDate = exchangeComponentController.makeGetCalloutAllData(baseCurrency, webServiceName, testDate1, null);
                System.assertEquals(1, cExchangeRatesDate.size());
            }
            when 2 {
                List<Exchange_Rate__c> cExchangeRatesDate = exchangeComponentController.makeGetCalloutAllData(baseCurrency, webServiceName, null, testDate1);
                System.assertEquals(1, cExchangeRatesDate.size());
            }
            when 3 {
                List<Exchange_Rate__c> cExchangeRatesDate = exchangeComponentController.makeGetCalloutAllData(baseCurrency, webServiceName, testDate1, testDate1);
                System.assertEquals(1, cExchangeRatesDate.size());
            }
            when 4 {
                List<Exchange_Rate__c> cExchangeRatesDate = exchangeComponentController.makeGetCalloutAllData(baseCurrency, webServiceName, Date.today(), null);
                System.assertEquals(1, cExchangeRatesDate.size());
            }
            when 5 {
                List<Exchange_Rate__c> cExchangeRatesDate = exchangeComponentController.makeGetCalloutAllData(baseCurrency2, webServiceName, testDate1, null);
                System.assertEquals(1, cExchangeRatesDate.size());
            }
            when 6 {
                List<Exchange_Rate__c> cExchangeRatesDate = exchangeComponentController.makeGetCalloutAllData(baseCurrency2, webServiceName, null, testDate1);
                System.assertEquals(1, cExchangeRatesDate.size());
            }
            when 7 {
                List<Exchange_Rate__c> cExchangeRatesDate = exchangeComponentController.makeGetCalloutAllData(baseCurrency2, webServiceName, testDate1, testDate1);
                System.assertEquals(1, cExchangeRatesDate.size());
            }
            when else {
                List<Exchange_Rate__c> cExchangeRatesDate = exchangeComponentController.makeGetCalloutAllData(baseCurrency2, webServiceName, Date.today(), null);
                System.assertEquals(1, cExchangeRatesDate.size());
            }
        }
        Test.stopTest();
    }
    @IsTest
    static void makeGetCalloutAllDataTest(){
        makeGetCalloutAllDataTestFuncOnDate(1);
    }

    @IsTest
    static void makeGetCalloutAllDataTest2(){
        makeGetCalloutAllDataTestFuncOnDate(2);
    }
    @IsTest
    static void makeGetCalloutAllDataTest3(){
        makeGetCalloutAllDataTestFuncOnDate(3);
    }

    @IsTest
    static void makeGetCalloutAllDataTest5() {
        makeGetCalloutAllDataTestFuncOnDate(4);
    }
    @IsTest
    static void makeGetCalloutAllDataTest6(){
        makeGetCalloutAllDataTestFuncOnDate(5);
    }
    @IsTest
    static void makeGetCalloutAllDataTest7(){
        makeGetCalloutAllDataTestFuncOnDate(6);
    }
    @IsTest
    static void makeGetCalloutAllDataTest8(){
        makeGetCalloutAllDataTestFuncOnDate(7);
    }

    @IsTest
    static void makeGetCalloutAllDataTest10() {
        makeGetCalloutAllDataTestFuncOnDate(8);
    }

    static void makeGetCalloutAllDataTestFunc(Integer var){
        Date testDate1 = Date.newInstance(2021, 02, 01);
        Date testDate2 = Date.newInstance(2021, 02, 02);
        String webServiceName = 'exchangerates';
        String baseCurrency = 'GBP';
        String baseCurrency2 = 'EUR';
        Test.startTest();
        StaticResourceCalloutMock mockDate = new StaticResourceCalloutMock();
        mockDate.setStaticResource('currencyPeriod');
        mockDate.setStatusCode(200);
        mockDate.setHeader('Content-Type', 'application/json;charset=UTF-8');
        Test.setMock(HttpCalloutMock.class, mockDate);
        switch on var {
            when 1 {
                List<Exchange_Rate__c> cExchangeRatesDate = exchangeComponentController.makeGetCalloutAllData(baseCurrency, webServiceName, testDate1, testDate2);
                System.assertEquals(2, cExchangeRatesDate.size());
            }
            when else {
                List<Exchange_Rate__c> cExchangeRatesDate = exchangeComponentController.makeGetCalloutAllData(baseCurrency2, webServiceName, testDate1, testDate2);
                System.assertEquals(2, cExchangeRatesDate.size());
            }
        }

    }

    @IsTest
    static void makeGetCalloutAllDataTest4(){
        makeGetCalloutAllDataTestFunc(1);
    }
    @IsTest
    static void makeGetCalloutAllDataTest9(){
        makeGetCalloutAllDataTestFunc(2);
    }

    @IsTest
    static void scheduledDataExchangeTest(){
        Test.startTest();
        StaticResourceCalloutMock mockDate = new StaticResourceCalloutMock();
        mockDate.setStaticResource('currencyDate');
        mockDate.setStatusCode(200);
        mockDate.setHeader('Content-Type', 'application/json;charset=UTF-8');
        Test.setMock(HttpCalloutMock.class, mockDate);
        SchedulableContext sc = null;
        scheduledDataExchange tsc = new scheduledDataExchange();
        tsc.execute(sc);
        Test.stopTest();
    }
}