/***********************************************************************************************************************
Name:APAC_Training_Automation_Test 
TestMethod: TestTrainingAutomation
Copyright © Align Tech
========================================================================================================================
Purpose:
This test class is for to coverage the flow "APAC Training Automation"
========================================================================================================================
History
VERSION         AUTHOR                          DATE                DETAIL              
1.0             Prasad SRVD                   20/04/2021         Intial Creation

***********************************************************************************************************************/
@isTest
public class APAC_Training_Automation_Test {
    public static testmethod void TestTrainingAutomation() {
        
        Id recordTypeIdTicket = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('iTero_Training').getRecordTypeId();
        Id recordTypeIdTraining = Schema.SObjectType.VCT_Training__c.getRecordTypeInfosByDeveloperName().get('VCT_Training_1').getRecordTypeId();
        Account testAccount = new Account();
        testAccount.name='Test';
        testAccount.Address_Type__c='Bill To';
        testAccount.Type='Distributor';
        testAccount.Line_of_Business__c='Invisalign';
        testAccount.phone='(000) 000-0000'; 
        testAccount.Address_Street_1__c='Test';
        testAccount.Billing_Language__c='English';
        testAccount.Account_Sub_Type__c='Distributor';
        testAccount.BillingCountry='India';
        testAccount.billingstate='Goa';
        testAccount.billingcity='Test';
        testAccount.shippingcountry='India';
        testAccount.shippingstate='Goa';
        testAccount.shippingcity='Test';
        testAccount.billingpostalcode='534350';
        testAccount.shippingpostalcode='534350';
        testAccount.Annual_Ortho_Cases__c=10;
        testAccount.Promotion_Region__c = 'APAC -India';
        insert testAccount;        
        Contact testContact = new Contact();
        testContact.Accountid=testAccount.id;
        testContact.Firstname = 'Firstname';
        testContact.lastname = 'Tes1t';
        testContact.Contact_Status__c='Active';
        testContact.Contact_Type__c='Doctor';
        testContact.Professional_Category__c='GP';
        testContact.phone='(000) 000-0000';    
        testContact.Email='Test@test11.com';
        testContact.Segmentation_Program__c='Mentoring'; //commenting for commit
        insert testContact;   
        Case testCase = new Case();
        testCase.AccountId = testAccount.id;
        testCase.ContactId=testContact.id;
        testCase.Status='Open';
        testCase.recordtypeid = recordTypeIdTicket; //comenting
        Insert testCase;
         VCT_Training__c trainingRec = new VCT_Training__c();
         trainingRec.Name='Training 1';
         trainingRec.VCT_Training_Date__c = System.today()+10;
         trainingRec.Region__c='APAC';
         trainingRec.Modules_Completed__c ='Ortho Scanning';
         trainingRec.Method_of_Training__c='Group training';
         trainingRec.Clinic_Proficiency__c='Good';
         trainingRec.recordtypeid = recordTypeIdTraining;
         trainingRec.Case__c = testCase.Id;
         trainingRec.Status__c='Scheduled';
         insert trainingRec;
    }
}
public class APAC_Training_Automation_Test1 {
    public static testmethod void TestTrainingAutomation() {
        
        Id recordTypeIdTicket = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('iTero_Training').getRecordTypeId();
        Id recordTypeIdTraining = Schema.SObjectType.VCT_Training__c.getRecordTypeInfosByDeveloperName().get('VCT_Training_1').getRecordTypeId();
        Account testAccount = new Account();
        testAccount.name='Test';
        testAccount.Address_Type__c='Bill To';
        testAccount.Type='Distributor';
        testAccount.Line_of_Business__c='Invisalign';
        testAccount.phone='(000) 000-0000'; 
        testAccount.Address_Street_1__c='Test';
        testAccount.Billing_Language__c='English';
        testAccount.Account_Sub_Type__c='Distributor';
        testAccount.BillingCountry='India';
        testAccount.billingstate='Goa';
        testAccount.billingcity='Test';
        testAccount.shippingcountry='India';
        testAccount.shippingstate='Goa';
        testAccount.shippingcity='Test';
        testAccount.billingpostalcode='534350';
        testAccount.shippingpostalcode='534350';
        testAccount.Annual_Ortho_Cases__c=10;
        testAccount.Promotion_Region__c = 'APAC -India';
        //comments in new line
        insert testAccount;        
        Contact testContact = new Contact();
        testContact.Accountid=testAccount.id;
        testContact.Firstname = 'Firstname';
        testContact.lastname = 'Tes1t';
        testContact.Contact_Status__c='Active';
        testContact.Contact_Type__c='Doctor';
        testContact.Professional_Category__c='GP';
        testContact.phone='(000) 000-0000';    
        testContact.Email='Test@test11.com';
        testContact.Segmentation_Program__c='Mentoring';
        insert testContact;   
        Case testCase = new Case();
        testCase.AccountId = testAccount.id;
        testCase.ContactId=testContact.id;
        testCase.Status='Open';
        testCase.recordtypeid = recordTypeIdTicket; //comenting
        Insert testCase;
         VCT_Training__c trainingRec = new VCT_Training__c();
         trainingRec.Name='Training 1';
         trainingRec.VCT_Training_Date__c = System.today()+10;
         trainingRec.Region__c='APAC';
         trainingRec.Modules_Completed__c ='Ortho Scanning';
         trainingRec.Method_of_Training__c='Group training';
         trainingRec.Clinic_Proficiency__c='Good';
         trainingRec.recordtypeid = recordTypeIdTraining;
         trainingRec.Case__c = testCase.Id;
         trainingRec.Status__c='Scheduled';
         insert trainingRec;
    }
}
