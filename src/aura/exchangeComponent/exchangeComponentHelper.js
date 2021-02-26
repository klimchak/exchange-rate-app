({
    // получение и вывод в атрибуту обозначений валюты
    getCurrencyName : function (component){
        let action = component.get("c.getCurrencyNames");
        action.setCallback(this, $A.getCallback(function (response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                let arrCurrencyName = response.getReturnValue();
                let columnsArray = [{label: 'Date records', fieldName: 'Date__c', type: 'Date', sortable: true}];
                // цикл для формирования объекта столбцов таблицы
                for (let i = 0; i < arrCurrencyName.length; i++){
                    let column = {};
                    column.label = arrCurrencyName[i];
                    column.fieldName = arrCurrencyName[i] + '__c';
                    column.type = 'currency';
                    column.sortable = true;
                    column.typeAttributes = { currencyCode: arrCurrencyName[i], maximumSignificantDigits: 5 };
                    columnsArray.push(column);
                }
                component.set('v.columns', columnsArray);
                component.set('v.currencyNameList', arrCurrencyName);
            }
        }));
        $A.enqueueAction(action);
    },

    // вывод данных при первой загрузке компонента
    getExchangeDataStartup : function(component, baseCurrency, serviceName, dateStart, dateEnd){
        component.set("v.loaded", false);
        let action = component.get("c.makeGetCalloutAllData");
        action.setParams({"baseCurrency" : baseCurrency, 'serviceName' : serviceName, "dateStart" : dateStart, "dateEnd" : dateEnd});
        action.setCallback(this, $A.getCallback(function (response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                let obj = response.getReturnValue();
                let arrCurrencyData = [];
                // получение div для изменения высоты добавлением класса
                let box = document.getElementById("boxTable");
                // сборка данных для таблицы при множестве строк
                if ((dateStart != dateEnd) && dateStart != null && dateEnd != null){;
                for (let i = 0; i < obj.length; i++){
                    let dateString = new Date(Date.parse(obj[i].Date__c)).toISOString();
                    obj[i].Date__c = dateString.slice(0, 10);
                    arrCurrencyData.push(obj[i]);
                }
                    if (!box.classList.contains("boxTable")){
                        box.classList.add('boxTable');
                    }
                }
                else { // при одной строке
                    let dateString = new Date(Date.parse(obj[0].Date__c)).toISOString();
                    obj[0].Date__c = dateString.slice(0, 10);
                    arrCurrencyData.push(obj[0]);
                    box.classList.remove('boxTable');
                }
                component.set("v.dataExchange", arrCurrencyData);
                component.set("v.loaded", true);
            } else if (state === "ERROR") {
                component.find('notifLib').showNotice({
                    "variant": "info",
                    "header": "Something has gone wrong!",
                    "message": JSON.stringify(response)
                });
                console.error(JSON.stringify(response));
            }
        }));
        $A.enqueueAction(action);

    },

    setTodayDate : function (component){
        let todayDate = $A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
        component.set('v.startDate', todayDate);
        component.set('v.nowDate', todayDate);
    },

    handleSort: function(component, event) {
        let sortedBy = event.getParam('fieldName');
        let sortDirection = event.getParam('sortDirection');
        let cloneData = component.get("v.dataExchange");
        cloneData.sort((this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1)));
        component.set('v.dataExchange', cloneData);
        component.set('v.sortDirection', sortDirection);
        component.set('v.sortedBy', sortedBy);
        component.set("v.loaded", true);
    },

    sortBy: function(field, reverse, primer) {
        let key = primer
            ? function(x) {
                return primer(x[field]);
            }
            : function(x) {
                return x[field];
            };
        return function(a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    },

});