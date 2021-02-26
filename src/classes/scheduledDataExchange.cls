global class scheduledDataExchange implements Schedulable, Database.AllowsCallouts {
    global void execute(SchedulableContext SC) {
        String baseCurrency = 'GBP';
        String serviceName = 'exchangerates';
        makeGetCurrencyData(baseCurrency, serviceName);
    }

    @Future(Callout=true)
    public static void makeGetCurrencyData(String baseCurrency, String serviceName) {
        List<Exchange_Rate__c> listCurrency = exchangeComponentController.makeGetCalloutAllData(baseCurrency, serviceName, Date.today(), null);
        List<Exchange_Rate__c> dataInBase = [SELECT Id FROM Exchange_Rate__c WHERE Date__c = :listCurrency[0].Date__c AND Base_Currency__c = :baseCurrency];
        if (dataInBase.size() == 0) {
            insert listCurrency;
        }
    }
}