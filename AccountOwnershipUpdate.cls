/**
* @Name: AccountOwnershipUpdate
* @TestMethod: AccountOwnershipUpdateTest
* @Copyright © Align Tech
* @author Align Tech
=============================================================================================================
@Purpose
To update Accounts owner and also the Treatment Team values Based on the Territories assigned
History 
VERSION         AUTHOR                          DATE                DETAIL       
2.0         Krishna swayimpa                  09/08/2019           Updated the logic to include inactive NA accounts for ownershipupdate as part of SF-5788
2.1         Mahesh Komirisetty                03/19/2020           SF-7201&SF-6397-Fixed the broken treatment team rules as per the latest sales changes
2.2         Mahesh komirisetty                05/06/2020           SF-7735-Removed the logic of assigning Collection Managers from accounts
2.3         Mahesh komirisetty                06/09/2020           SF-8053-Removed the logic of Contact owner population from account.
2.4         Mahesh Komirisetty                07/29/2020           SF-8490-Whenever the owner on the account changed and makes the Is_AccountOwner_Change__c checkbox on account to true.
2.5         Saimohan Kapilavayi               08/16/2020           SF-8607 Giving Edit access to LID owners on parent account via accountteams 
2.6         Mahesh komirisetty                12/14/2020           SF-9194-Moved Treatment team update logic to UpdateTreatmentTeamsOnAccounts util class and passing territory's related accounts to that util class to update TT codes on account
2.7         Mahesh komirisetty                12/23/2020           SF-9642-Setting the batch size when this batch class call from a button on territory.
2.8         Surya Chintala                    12/30/2020           SF-9222-Remove SA/ SAM Logic for Account Ownership - Technical Debt
2.9         Mahesh Komirisetty                01/14/2021           Checking Exclude from tretment Team condition as part of ASFDC-1522 
2.9         Mahesh Komirisetty                04/12/2021           Checking the critiria's to differenctiate the NA,LTAM && INTL accounts(SF-10231). 
*/

/**
 * $Revision: 2.0 $
 * $Date: 2019/08/09
 * $Author: Krishna swayimpa $
 * @description Updated the logic to include inactive NA accounts for ownershipupdate as part of SF-5788 
 **/
global class AccountOwnershipUpdate{   
    public static Id iteroRecordTypeId  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('iTero').getRecordTypeId();
    public static Id doctorRecordTypeID = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Doctor').getRecordTypeId();    
    public static id sfdcAdminOwnerid=System.Label.SFDC_Admin_User_Id;
    /**
     * @description performUpdateOnAccount
     * @param objList 
     * @param batchjobid
     * @return acclist
    */
    public static List<Account> performUpdateOnAccount(List<ObjectTerritory2Association> objList,id batchjobid){ 
        set<id> parentid = new set<id>();
        set<id> territoryid = new set<id>();
        List<Account> toBeUpdatedAccounts = new List<Account>();  
        //SF-8607 added below map for capturing parentid and account records 
        Map<id,Account> naAccountMap=new  Map<id,Account>();        
        List<ObjectTerritory2Association> toBeInsertObjTerritory =new list<ObjectTerritory2Association>(); 
        Map<id,id> acc2territory = new Map<Id,Id>(); 
        Map<ID, List<ID>> accToTerritory = new Map<ID, List<id>>();
        Map<id,UserTerritory2Association > usrToTerritoryMap = new Map<id,UserTerritory2Association>(); 
        // Map to store Account id and Loyalty Enrollment Record
        List<Exception_Handling__c>  exceptionList = new List<Exception_Handling__c>();
        //Added as part of SF-9194
        List<Account> accTTUpdateList=new List<Account>();        
         
        for(ObjectTerritory2Association obj: objList){
            acc2territory.put(obj.Objectid,obj.Territory2Id);
        }
        Map<Id,Territory2Type> territory2TypeNameMap = new Map<Id,Territory2Type>([SELECT DeveloperName FROM Territory2Type]); 
        // SF - 4116 :Added Promotion_Region__c field to the Query to Check while Updating Treatment Team
        // SF - 4370 :Added shippingcountry field to the Query to check Account country with the country field from custom settings.
        // Querying parent account's promotion region and shipping country.
        List<account> acclist=[select account_number__c,Account_Sub_Type__c,Territory_Assignment_Grouping__c,Name,recordtypeid,IsExcludedFromRealign,Previous_Owner_formula__c,
        Exclude_from_Treatment_Team__c ,Treatment_Team__c,Promotion_Region__c,Parent.Promotion_Region__c,Parent.ShippingCountry,ShippingCountry,parent.ownerid,
        parent.Corporate_Account__c,parent.owner.Role_On_Territory__c,ParentId,Parent.ParentId,ownerid,
        (select Territory2Id,objectId  from ObjectTerritory2Associations)  from Account where id in :acc2territory.keyset()and (Account_Status__c != 'Inactive' or Promotion_Region__c='NORTH AMERICA' or Promotion_Region__c='LATAM') ORDER BY ParentId DESC NULLS FIRST];
        //preparing the list of territory and list of all DID<>LID account
        for(Account acc: acclist){
            for(ObjectTerritory2Association objTerr: acc.ObjectTerritory2Associations){
                if(accToTerritory .get(acc.id) == null){
                    accToTerritory .put(acc.id, new list<id>());
                }
                accToTerritory .get(acc.id).add(objTerr.Territory2Id); 
                territoryid.add(objTerr.Territory2Id); 
            }
            
            //SF-8607 Capturing all NA accounts in a map
            if(acc.ParentId!=null && acc.Promotion_Region__c=='NORTH AMERICA'){
              naAccountMap.put(acc.ParentId,acc);
            } 
            if(acc.parentid!=null && acc.IsExcludedFromRealign==false){  //SF-1415
                parentid.add(acc.parentid);
            }
            //Added As part of SF-9194,SF-10231
            if(acc.Promotion_Region__c != null && (acc.Promotion_Region__c == 'NORTH AMERICA' || acc.Promotion_Region__c.Contains('LATAM')) && acc.Exclude_from_Treatment_Team__c == false){
              accTTUpdateList.add(acc);
            }
        }
        if(parentid.size()>0){
            List<ObjectTerritory2Association> parentList = [select Territory2Id,objectId  from ObjectTerritory2Association where objectId in : parentid order by Territory2.name asc];                 
            // Querying Loyalty Enrollment records for the parent Account and Building a Map of Accountid and Loyalty Enrollment Record
            for(ObjectTerritory2Association obj: parentList){
                acc2territory.put(obj.objectId  ,obj.Territory2Id);
                if(accToTerritory .get(obj.objectId) == null){
                    accToTerritory .put(obj.objectId, new list<id>());
                }
                accToTerritory.get(obj.objectId).add(obj.Territory2Id); 
                territoryid.add(obj.Territory2Id); 
            } 
        }
        Map<id,Territory2> territory2TypeIdMap= new map<id,Territory2>([Select Treatment_Team__c,Collection_Agent__c,Territory2TypeID from Territory2 where id in: territoryid]);
        
        for(UserTerritory2Association usrTerritoryObj : [Select  Territory2Id,UserId,LastModifiedDate,RoleInTerritory2 from UserTerritory2Association where IsActive = true and RoleInTerritory2 != 'Delegated TM' and Territory2Id in: territoryid order by LastModifiedDate  desc]){             
            usrToTerritoryMap.put(usrTerritoryObj.Territory2Id,usrTerritoryObj );
        }  
        //preparing the list of owner and collection manager
        for(Account acc: acclist){
            account ac = new account(id=acc.id);
            boolean isTreatmentTeamInserted=false;
            if(accToTerritory.containskey(acc.id)&&accToTerritory.get(acc.id).size()>1){
                for(id terrid :accToTerritory.get(acc.id)){
                    if(territory2TypeNameMap.get(territory2TypeIdMap.get(terrid).Territory2TypeID).DeveloperName=='Invisalign'){
                        acc2territory.put(acc.id,terrid);break;
                    }
                }   
            }                          
            //SF-9222: Removing Sales Associate condition for territory assignment. 
            if(acc.parentid!=null &&acc.IsExcludedFromRealign==false && acc2territory.containskey(acc.parentid)&&usrToTerritoryMap.containskey(acc2territory.get(acc.id)) &&
            usrToTerritoryMap.get(acc2territory.get(acc.parentid))!=null&&usrToTerritoryMap.get(acc2territory.get(acc.parentid)).RoleInTerritory2 !=null&& 
            (usrToTerritoryMap.get(acc2territory.get(acc.parentid)).RoleInTerritory2 == 'Strategic Account Manager')){
                if(acc.ownerid!=usrToTerritoryMap.get(acc2territory.get(acc.parentid)).UserId){
                    ac.ownerid = usrToTerritoryMap.get(acc2territory.get(acc.parentid)).UserId;
                    ac.IsExcludedFromRealign=True;
                    //Added as part of SF-8490
                    acc.Is_AccountOwner_Change__c=true;
                    toBeInsertObjTerritory.add(new ObjectTerritory2Association(AssociationCause='Territory2Manual', ObjectId = acc.id, Territory2Id = acc2territory.get(acc.ParentId)));                
                }
            }
            else  if(usrToTerritoryMap.get(acc2territory.get(acc.id))!=null&&(territory2TypeNameMap.get(territory2TypeIdMap.get(acc2Territory.get(acc.id)).Territory2TypeID).DeveloperName=='Invisalign'||(territory2TypeNameMap.get(territory2TypeIdMap.get(acc2Territory.get(acc.id)).Territory2TypeID).DeveloperName=='iTero'&&acc.recordtypeid==iteroRecordTypeId ))){
                if(acc.ownerid!=usrToTerritoryMap.get(acc2territory.get(acc.id)).UserId ){
                    ac.ownerid = usrToTerritoryMap.get(acc2territory.get(acc.id)).UserId;
                    //Added as part of SF-8490
                    acc.Is_AccountOwner_Change__c=true;
                } 
            }
            else  if(acc.ownerid!=sfdcAdminOwnerid){             
                ac.ownerid = sfdcAdminOwnerid;  
            }        
            if(ac.ownerid!=null&&acc.ownerid!=ac.ownerid &&acc.Previous_Owner_formula__c!=null){
                ac.Previous_Owner__c=acc.Previous_Owner_formula__c;
            }   
            // SF-5303: Assign treatment teams based on region and not excluded from treatment teams assignments.
            //Added condition as part of SF-9194,SF-10231
                //Checking Exclude from tretment Team condition as part of ASFDC-1522
                 if(acc.Promotion_Region__c != NULL && acc.Promotion_Region__c != 'NORTH AMERICA' && !acc.Promotion_Region__c.Contains('LATAM') && acc.Exclude_from_Treatment_Team__c == false){
                  // Assigning Treatment teams from territory for rest of world.  
                  if(acc2territory.containsKey(acc.id)&&territory2TypeIdMap.containsKey(acc2territory.get(acc.id))&&
                    acc.Treatment_Team__c != territory2TypeIdMap.get(acc2territory.get(acc.id)).Treatment_Team__c &&
                    territory2TypeIdMap.get(acc2territory.get(acc.id)).Treatment_Team__c!=null){    
                        ac.Treatment_Team__c= territory2TypeIdMap.get(acc2territory.get(acc.id)).Treatment_Team__c;
                        isTreatmentTeamInserted=true;
                  }                         
                }
            if(ac.ownerid !=null||isTreatmentTeamInserted){
                ac.account_number__c=acc.account_number__c;
                ac.Name=acc.Name;
                toBeUpdatedAccounts.add(ac);
            }
        }   
        if(toBeInsertObjTerritory.size()>0){
            database.insert(toBeInsertObjTerritory,false);
        }  
       //Passing account list to update treatment teams on account as part of SF-9194
       if(!accTTUpdateList.isEmpty()){
           UpdateTreatmentTeamsOnAccounts.updateTreatmentTeams(accTTUpdateList,null);
       }
        if(toBeUpdatedAccounts.size()>0){
            list<database.saveresult> dra=database.update( toBeUpdatedAccounts,false);
            exceptionList.addAll(exceptionHandlingHelper.saveResult(toBeUpdatedAccounts,dra,'AccountOwnership',batchjobid,null));
        }
       if(exceptionList!=null){
          database.upsert(exceptionList,false);
       }               
        //SF-8607 List of account share created
       List<AccountShare> acctShareList = new List<AccountShare>(); 
        List<AccountTeamMember> tobeaddedAccountTeamMember = AccountTeamManagement.performAddAccteam([SELECT Account__r.id,Account__r.Promotion_Region__c,Contact__r.account.ownerid,Contact__r.account.Promotion_Region__c,status__c,Account__r.ownerid,Contact__r.accountid FROM Shared_Contact__c where (status__c!='Inactive' and contact__r.Account.id=:Acclist) or (status__c!='Inactive' and Account__r.id=:Acclist)],[select parent.Corporate_Account__c,parentid,Parent.Promotion_Region__c,ownerid,parent.ownerid,parent.Business_Unit__c,Promotion_Region__c,Region__c from Account where id in :Acclist or parentid in : Acclist ]);       
        //SF-8607 Creating account share records for NA accounts which are present in naAccountMap
         if(naAccountMap.size()>0 && tobeaddedAccountTeamMember.size()>0){
        for(AccountTeammember atm:tobeaddedAccountTeamMember){
            if(naAccountMap.containskey(atm.AccountId)){
            AccountShare acctShare= new AccountShare();
            acctShare.AccountId = atm.AccountId;
                acctShare.UserOrGroupId = atm.userId;
                acctShare.AccountAccessLevel = 'Edit';
                acctShare.OpportunityAccessLevel='None';
            acctShareList.add(acctshare);
            atm.AccountAccessLevel='Edit';
            }
        }
       }   
       //SF-8607 Inserting accountshare records
       if(!acctShareList.isEmpty() && acctShareList.size()>0)
       { database.insert (acctShareList,false);
       }
       //SF-8607 --end
        if(tobeaddedAccountTeamMember.size()>0){ 
            database.insert (tobeaddedAccountTeamMember,false);
        } 
        //EUSFDEV-1109 return the list of account
        return acclist;
    } 
 /**
 * @description executeAccountOwnershipBatch
 * @return batchprocessid
 * @param territoryId
 */
    webservice static id executeAccountOwnershipBatch(Id territoryId){ 
        //SF-9642-Setting the batch size when this batch class call from a button on territory.       
        ID batchprocessid=Database.executeBatch(new BatchAccountOwnerUpdate (territoryId),Integer.valueOf(Batch_Jobs_Execution__c.getInstance('Account Ownership Batch').Batch_size__c));
        return batchprocessid;
    } 
}