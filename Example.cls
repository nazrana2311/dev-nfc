/*
* @author Original: Tarun Solanki (502386765)
* @date   Original: 28 July 2015
* @description: Class to send oppty field details in JSON format to PEGA system.
*/
public class SfdcToMyOrdersCtrl {
    /*
    * @author Original: Tarun Solanki (502386765)
    * @date   Original: 28 July 2015
    * @description: Method to send oppty field details in JSON format to PEGA system.
    */

    @future(callout=true)
    public static void postOnOpptyFieldsUpdate(Set<Id> opptyIDset) {
        //Call post Oppty Fields on Myorders
        postOnOpptyFieldsonMyOrders(opptyIDset, false);

    }
    // US6517 : adding below method with isBatch parameter to cover myOrders notification from batch clas
    public static void postOnOpptyFieldsonMyOrders(Set<Id> opptyIDset, Boolean isBatch) {
        //To log in System Event Logs if any Error
        System_Event_Log__c sLog;
        SystemEventLogDML sLogDML = new SystemEventLogDML();

        // Prepare data...

        list<OpptyRequestProperty> lstFieldsProperty = new list<OpptyRequestProperty>();
        //Query limits update
        for (Opportunity objRecord : [select Id,LastModifiedDate,Opportunity_Num__c from Opportunity where ID IN :opptyIDset LIMIT :(Limits.getLimitQueryRows() - Limits.getQueryRows())]) {
            OpptyRequestProperty objSendRequestProp;
            if (isBatch) {
                // US6517 Notification to be sent to MYOrders. BatchOpportunityMyOrdersUpdateFlag(class calling this section of code) 
                //As callouts cannot be made after update of oppty sending current system time as opportunity's lastmodified time
                objSendRequestProp = new OpptyRequestProperty(objRecord.id, objRecord.Opportunity_Num__c, convertDateTimetoString(system.now()));
            } else {
                objSendRequestProp = new OpptyRequestProperty(objRecord.id, objRecord.Opportunity_Num__c, convertDateTimetoString(objRecord.LastModifiedDate));
            }
            system.debug('PrintList+++' + lstFieldsProperty);
            lstFieldsProperty.add(objSendRequestProp);
        }

        // Serialize the list of SendRequestProperty objects.

        String jsonOpptyValues = JSON.serializePretty(lstFieldsProperty);

        //Modify to send data in pega format
        String modifyjsonOpptyValues = '{"records":' + jsonOpptyValues + '}';


        IntegrationUtility.TokenData tokenData = IntegrationUtility.GetOAuth('myProject to myOrders Opty', 'My Projects'); // get token to enter GE network -
        String token = tokenData.token;

        HttpRequest req = new HttpRequest();

        //Integration_General_Settings__c serviceReqSettings;
        //get the end point URL from custom setting
        //serviceReqSettings = Integration_General_Settings__c.getValues('Opportunity_To_MyOrders');
        String endPoint = tokenData.configuration.Endpoint__c;
        req.setMethod('POST');
        req.setHeader('content-type', 'application/json');
        String authorizationHeader = 'Bearer ' + token;
        req.setHeader('Authorization', authorizationHeader);
        req.setTimeout(60000); // Set timeout to 60 sec
        req.setEndpoint(endPoint);
        req.setBody(modifyjsonOpptyValues);

        Http http = new Http();
        HTTPResponse resp = new HTTPResponse();

        try {
            if (!test.isrunningtest()) {
                system.debug('Request****' + req);
                resp = http.send(req);
            }
            if (resp != null && resp.getStatusCode() == 200) {
                sLog = sLogDML.generateIntegrationSysLog('SfdcToMyOrdersCtrl.postOnOpptyFieldsUpdate', 'Sucesss:' + resp.getStatus(), resp.getStatus(), slogDml.EvtType[2], UserInfo.getUserId(), '', modifyjsonOpptyValues, resp.getBody(), 'MyOrder');
                insert sLog;
            } else {
                sLog = sLogDML.generateIntegrationSysLog('SfdcToMyOrdersCtrl.postOnOpptyFieldsUpdate', 'Error:' + resp.getStatus(), resp.getStatus(), slogDml.EvtType[3], UserInfo.getUserId(), '', modifyjsonOpptyValues, resp.getBody(), 'MyOrder');
                insert sLog;
            }

        } catch (exception e) {
            sLog = sLogDML.generateIntegrationSysLog('SfdcToMyOrdersCtrl.postOnOpptyFieldsUpdate', 'Error: ' + e.getMessage(), '', slogDml.EvtType[3], UserInfo.getUserId(), '', modifyjsonOpptyValues, '', 'MyOrder');
            insert sLog;
        }

    }    
    /*
  * @author Original: Tarun Solanki (502386765)
  * @date   Original: 28 July 2015
  * @description: Method to convert datetime to PEGA system require string format
  */
    public static string convertDateTimetoString(datetime objDateTime) {
        String retValue;
        DateTime dInputDate = objDateTime;

        String day = (String.valueOf(dInputDate.day()).length() == 1) ? '0' + String.valueOf(dInputDate.day()) : String.valueOf(dInputDate.day()) ;
        String month = (String.valueOf(dInputDate.month()).length() == 1) ? '0' + String.valueOf(dInputDate.month()) : String.valueOf(dInputDate.month()) ;
        String hour = (String.valueOf(dInputDate.hour()).length() == 1) ? '0' + String.valueOf(dInputDate.hour()) : String.valueOf(dInputDate.hour()) ;
        String minute = (String.valueOf(dInputDate.minute()).length() == 1) ? '0' + String.valueOf(dInputDate.minute()) : String.valueOf(dInputDate.minute()) ;
        String second = (String.valueOf(dInputDate.second()).length() == 1) ? '0' + String.valueOf(dInputDate.second()) : String.valueOf(dInputDate.second()) ;
        String Year = String.valueOf(dInputDate.Year());

        //default added GMT because PEGA require in this format, and we added default GMT because by default salesforce stores date in GMT format
        retValue = Year + month + day + 'T' + hour + minute + second + '.000' + ' GMT';
        return retValue;
    }
    //Property class for Oppty fields detail
    public class OpptyRequestProperty {

        String OPPORTUNITY_ID;
        String OPPORTUNITY_NUM;
        String SFDC_CHANGE_TS;

        public OpptyRequestProperty(String opptyId, String opptyNum, String lastModifiedDate) {

            OPPORTUNITY_ID = opptyId;
            OPPORTUNITY_NUM = opptyNum;
            SFDC_CHANGE_TS = lastModifiedDate;

        }
    }  
}