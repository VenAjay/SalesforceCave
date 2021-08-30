public class AccountHierarchyHandler{
    //New changes related to Account hierarchy
    public static Map<Id, Integer> accountIdLevelMap=new Map<Id, Integer>();
    public static Map<Id, Account> accountDetailsMap=new Map<Id, Account>();
    public static Map<Id, list<Account>> parentChildLinkedListMap=new Map<Id, list<Account>>();
    public static list<Account> accountHierarchyList=new list<Account>();


    public static String getMasterAccountId(String currAcctId){
        system.debug('------currAcctId-------'+currAcctId);
        Boolean isTopLevelAccount = false;
        String cParentId;
        while (!isTopLevelAccount) {
            Account acct = [select Id, 
                                    ParentId, 
                                    Parent.ParentId, 
                                    Parent.Parent.ParentId, 
                                    Parent.Parent.Parent.ParentId, 
                                    Parent.Parent.Parent.Parent.ParentId, 
                                    Parent.Parent.Parent.Parent.Parent.ParentId 
                                    From Account where Id = :currAcctId limit 1];
            if (acct.ParentID != null) { //level -0
                cParentId = acct.ParentID;
                if(acct.Parent.ParentId!=null){ //level -1
                    cParentId = acct.Parent.ParentId;
                    if(acct.Parent.Parent.ParentId!=null){ //level -2
                        cParentId = acct.Parent.Parent.ParentId;
                        if(acct.Parent.Parent.Parent.ParentId!=null){ //level -3
                            cParentId = acct.Parent.Parent.Parent.ParentId;
                            if(acct.Parent.Parent.Parent.Parent.ParentId!=null){ //level -4
                                cParentId = acct.Parent.Parent.Parent.Parent.ParentId;
                                if(acct.Parent.Parent.Parent.Parent.Parent.ParentId!=null){ //level -5
                                    cParentId = acct.Parent.Parent.Parent.Parent.Parent.ParentId;
                                }
                            }
                        }
                    }
                }
                currAcctId = cParentId;
            } else {
                isTopLevelAccount = true;
            }
        }
        return currAcctId;
    }
    
    public static List<Account> getChildAccountsInHierarchy(Id parentAcctId) {
        
        Boolean endTraversing = false;
        Integer accountLevel = 0;
    
        // declare all other variables as used below
        String query;
        list<String> parentIdList=new list<String>();
        parentIdList.add(parentAcctId);
        list<Account> acctList;
        
        while(!endTraversing) {
    
            // observe closely at the WHERE clause, that's the key
    
            if(accountLevel == 0) {
               query = 'select Id,Name, ParentId from Account WHERE Id IN :parentIdList';
            } else {
               query = 'select Id,Name, ParentId from Account WHERE ParentId IN :parentIdList';
            }
            acctList = Database.query(query);
            
            if(acctList.size() == 0 ) {
               endTraversing = true;
            } else {
               parentIdList.clear();
               acctList.sort();
               Account a;
               for(Integer i = 0; i < acctList.size(); i++ ) {
                   a = acctList.get(i);
                   parentIdList.add(a.Id);
                    
                   // populate the account id and level and details maps to be later used
                   accountIdLevelMap.put(a.Id, accountLevel);
                   accountDetailsMap.put(a.Id, a);
    
                   if(accountLevel > 0) {
                       // create the map of parent and related child accounts
                       // this is the key part of the iteration which takes
                       // care of adding the parent and related child
                       if(parentChildLinkedListMap.get(a.ParentId) == null) {
                           parentChildLinkedListMap.put(a.ParentId, new List<Account>()); 
                       }
                       parentChildLinkedListMap.get(a.ParentId).add(a);
                       parentChildLinkedListMap.get(a.ParentId).sort();
                    }
               }
               accountLevel++;
            }
        }
    
        // populate the list in the way they appear in the hierarchy
        addChildAccountsToList(parentAcctId);
        return accountHierarchyList;
    }

    private static void addChildAccountsToList(Id parentAccountId) {
        Account a = accountDetailsMap.get(parentAccountId);
        accountHierarchyList.add(a);
        
        // get all associated child accounts for this parent from the map populated
        // then call the method recursively till the last node of the account is reached
        // this step takes care of adding the accounts in the return list in order of
        // their appearance
        List<Account> childAccounts = parentChildLinkedListMap.get(parentAccountId);
        if(childAccounts != null) {
            childAccounts.sort();
            for(Account acct : childAccounts) {
                // recursion
                addChildAccountsToList(acct.Id);
            }
        }
        
        // finally return to get out from the stack
        return;
    }
}