({
    doInit : function(component, event, helper){
        helper.getCurrencyName(component, event, helper);
        helper.setTodayDate(component);
        helper.getExchangeDataStartup(component, 'GBP', 'exchangerates', component.get('v.startDate'));
    },

    handleSort: function(component, event, helper) {
        component.set("v.loaded", false);
        helper.handleSort(component, event);
    },

    getDataOnClickButton : function (component, event, helper){
        let startDate = component.get("v.startDate");
        let endDate = component.get("v.endDate");
        let baseCurrency = component.find("valSelDefaultCurrency").get("v.value");
        if (startDate > endDate){
            component.find('notifLib').showNotice({
                "variant": "info",
                "header": "Something has gone wrong!",
                "message": "It defined the wrong date range."
            });
        }else {
            helper.getExchangeDataStartup(component, baseCurrency, 'exchangerates', startDate, endDate);
        }
    },

    selStartDate : function (component){
        let selectedValue =  component.get("v.startDate");
        console.log(selectedValue );
    },

    selEndDate : function (component){
        let selectedValue =  component.get("v.endDate");
        console.log(selectedValue);
    },

    selDefaultCurrency : function (component){
        let selectedValue =  component.find("valSelDefaultCurrency").get("v.value");
        console.log(selectedValue);
    }
});