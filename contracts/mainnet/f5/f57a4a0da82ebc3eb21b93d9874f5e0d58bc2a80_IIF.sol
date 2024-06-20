/**
 *Submitted for verification at Arbiscan.io on 2024-06-20
*/

pragma solidity ^0.8.0;

    contract Initializable {

        bool private _initialized;

        bool private _initializing;

        modifier initializer() {
            require(_initializing || !_initialized, "Initializable: contract is already initialized");

            bool isTopLevelCall = !_initializing;
            if (isTopLevelCall) {
                _initializing = true;
                _initialized = true;
            }
            _;

            if (isTopLevelCall) {
                _initializing = false;
            }
        }
    }




contract IIF is Initializable {


    uint256 public idProvider;
    address public owner; 
    address public operator; 
    // uint256 public directReferalReward = 15;
    // uint256 public secondsIn90Days  =7776000; // not in use 
    uint256 public totalShareHolding;
    bool public isCollapsed;
    // uint256 public dailyDeprecationRate = 99; // * 100 actual -- >  0.99
    uint256 public poolFund;
    //


    struct user{
        uint256 userID;
        address refererAddress;
        // uint256 referalIncomeRecived;
        bool isPurchased;
        uint256 amount;
        uint256 paidPremiumAmount;
        uint256 timeOfInsurancePurchased;
        uint256 sharePurchased;
        uint256 insuranceEndTime; 
        bool isClaimed;
        uint256 LastClaimedInsuranceFund;
        bool isInsuranceActive;
        uint256 totalPremiumAddedByRefering;
        string agentRank;
    }


    mapping(uint256 => address ) public idToAddress;
    mapping(address => user) public  usersData; 
    mapping(address => uint256 ) public addressToId;
    mapping(address => bool) public isExist;
    mapping(address => bool)public isLastPurchasedWasClaimed;
    mapping(address => bool)public isLastTimePurchased;
    mapping(uint256 => uint256) public returnPrice;
    mapping(address => uint256 )public totalBuisness;
    mapping(address => uint256 )public referalRewardAvailableForClaim;

    modifier onlyOwner() {
            require(msg.sender == owner,"not Owner");
            _;
    }
    modifier onlyOperator() {
            require(msg.sender == operator,"not operator");
            _;
    }
    event buyReport(address userAddress ,uint256 userId, address referadBy, uint256 duration , uint256 amount , uint256 time,uint256 endTime,uint256 payAmount);
    event rankDetail(address user , uint256 currentValkue , string  ramk  , uint256 time, uint256 InsuranceEndTime,uint256 reward);
    event userPurchaseAndClaimedUpdateDetail( address user ,  bool purchased ,  bool claimed ,  uint256 time);
    event registerDetail(uint256 userID , address userAddress , address referalAddress );
    event userDevidentTranferdetail(address  tranferedTo, uint256 amount ,string whichType);
    event userClaimTranferdetail(address  tranferedTo, uint256 amount ,string whichType);
    event shutdownStatus (address userAddress , uint256 time , bool status);
 
    function initialize(address _owner , address _operator  ) external initializer {
        owner =  _owner;
        operator = _operator;
     
        isExist[owner] = true;
        idToAddress[1]=owner;
        addressToId[owner] =1;
        idProvider=2;


        returnPrice[1] = 972000000000000;
        returnPrice[2] = 1944280000000000;
        returnPrice[3] = 2906560000000000;
        returnPrice[4] = 3859217200000000;
        returnPrice[5] = 4802347828000000;
        returnPrice[6] = 5736047149720000;
        returnPrice[7] = 6660409478222800;
        returnPrice[8] = 7575528183440570;
        returnPrice[9] = 8481495701606170;
        returnPrice[10] = 9378403544590100;
        returnPrice[11] = 10266342309214420;
        returnPrice[12] = 11145401686052800;
        returnPrice[13] = 12015670469192200;
        returnPrice[14] = 12877236564500300;
        returnPrice[15] = 13730186998855300;
        returnPrice[16] = 14574607928866800;
        returnPrice[17] = 15410584649578100;
        returnPrice[18] = 16238201603082300;
        returnPrice[19] = 17057542387051500;
        returnPrice[20] = 17868689763181000;
        returnPrice[21] = 18671725665549200;
        returnPrice[22] = 19466731208289370;
        returnPrice[23] = 20253786696804700;
        returnPrice[24] = 21032971629836700;
        returnPrice[25] = 21804364713538300;
        returnPrice[26] = 23324086227738900;
        returnPrice[27] = 24072568165461500;
        returnPrice[28] = 24813565283806900;
        returnPrice[29] = 25547152430968800;
        returnPrice[30] = 26273403706659100;
        returnPrice[31] = 26992392469592500;
        returnPrice[32] = 27704191344896600;
        returnPrice[33] = 28408872231447700;
        returnPrice[34] = 29106506309133200;
        returnPrice[35] = 29797164046041800;
        returnPrice[36] = 30480915205581400;
        returnPrice[37] = 31157828853525600;
        returnPrice[38] = 31827973364990400;
        returnPrice[39] = 32491416431340500;
        returnPrice[40] = 33148225067027100;
        returnPrice[41] = 33798465616356800;
        returnPrice[42] = 34442203760193200;
        returnPrice[43] = 35079504522591300;
        returnPrice[44] = 35710432277365400;
        returnPrice[45] = 36335050754591700;
        returnPrice[46] = 36953423047045800;
        returnPrice[47] = 37565611616575300;
        returnPrice[48] = 38171678300409600;
        returnPrice[49] = 38771684317405500;
        returnPrice[50] = 39365690274231400;
        returnPrice[51] = 39953756171489100;
        returnPrice[52] = 40535941409774200;
        returnPrice[53] = 41112304795676500;
        returnPrice[54] = 41682904547719700;
        returnPrice[55] = 42247798302242500;
        returnPrice[56] = 42807043119220100;
        returnPrice[57] = 43360695488027900;
        returnPrice[58] = 43908811333147600;
        returnPrice[59] = 44451446019816200;
        returnPrice[60] = 44988654359618000;
        returnPrice[61] = 45520490616021800;
        returnPrice[62] = 46047983596180000;
        returnPrice[63] = 46568261224763000;
        returnPrice[64] = 47084301412515300;
        returnPrice[65] = 47595181198390200;
        returnPrice[66] = 48100952186406300;
        returnPrice[67] = 48601665464542200;
        returnPrice[68] = 49097371609896800;
        returnPrice[69] = 49588120693797800;
        returnPrice[70] = 50073962286859900;
        returnPrice[71] = 50554945463991300;
        returnPrice[72] = 51031118809351300;
        returnPrice[73] = 51502530421257800;
        returnPrice[74] = 51969227917045200;
        returnPrice[75] = 52431258437874800;
        returnPrice[76] = 52888668653496000;
        returnPrice[77] = 53341504766961100;
        returnPrice[78] = 53789812519291500;
        returnPrice[79] = 54233637194098600;
        returnPrice[80] = 54673023622157600;
        returnPrice[81] = 55108016185936000;
        returnPrice[82] = 55538658824076600;
        returnPrice[83] = 55964995035835900;
        returnPrice[84] = 56387067885477500;
        returnPrice[85] = 56804920006622700;
        returnPrice[86] = 57218593606556500;
        returnPrice[87] = 57628130470490900;
        returnPrice[88] = 58033571965786000;
        returnPrice[89] = 58434959046128200;
        returnPrice[90] = 58832332255666900;
        returnPrice[91] = 59225731733110200;
        returnPrice[92] = 59615197215779100;
        returnPrice[93] = 60000768043621300;
        returnPrice[94] = 60382483163185100;
        returnPrice[95] = 60760381131553300;
        returnPrice[96] = 61134500120237700;
        returnPrice[97] = 61504877919035400;
        returnPrice[98] = 61871551939845000;
        returnPrice[99] = 62234559220446500;
        returnPrice[100] = 62593936428242100;
    }




    // function returnAgentReward(uint256 value ,address ref) public view returns(uint256 ,  string memory){
    //     uint256  data;
       
    //     if(usersData[ref].totalPremiumAddedByRefering + value >50000000000000000 && usersData[ref].totalPremiumAddedByRefering + value <=100000000000000000 ){
    //             data = (value * 7) /100;
    //             return (data , "Bronze"); 
    //     }else  if(usersData[ref].totalPremiumAddedByRefering + value > 100000000000000000   && usersData[ref].totalPremiumAddedByRefering + value <=200000000000000000 ){
    //             data = (value * 8) /100;
    //             return (data , "Silver"); 
    //     }else  if(usersData[ref].totalPremiumAddedByRefering + value > 200000000000000000  && usersData[ref].totalPremiumAddedByRefering + value <=500000000000000000 ){
    //             data = (value * 9) /100;
    //             return (data , "Gold"); 
    //     }else  if(usersData[ref].totalPremiumAddedByRefering + value > 500000000000000000  && usersData[ref].totalPremiumAddedByRefering + value <=1500000000000000000 ){
    //             data = (value * 10) /100;
    //             return (data , "Platinum"); 
    //     }else  if(usersData[ref].totalPremiumAddedByRefering + value > 1500000000000000000  && usersData[ref].totalPremiumAddedByRefering + value <=4000000000000000000){
    //             data = (value * 11) /100;
    //             return (data , "Beryl"); 
    //     }else  if(usersData[ref].totalPremiumAddedByRefering + value > 4000000000000000000  && usersData[ref].totalPremiumAddedByRefering + value <=10000000000000000000 ){
    //             data = (value * 12) /100;
    //             return (data , "Sapphire"); 
    //     }else  if(usersData[ref].totalPremiumAddedByRefering + value > 10000000000000000000  && usersData[ref].totalPremiumAddedByRefering + value <=30000000000000000000 ){
    //             data = (value * 13) /100;
    //             return (data , "Ruby"); 
    //     }else  if(usersData[ref].totalPremiumAddedByRefering + value > 30000000000000000000   && usersData[ref].totalPremiumAddedByRefering + value <=80000000000000000000 ){
    //             data = (value * 14) /100;
    //             return (data , "Emerald"); 
    //     }else  if(usersData[ref].totalPremiumAddedByRefering + value > 80000000000000000000   && usersData[ref].totalPremiumAddedByRefering + value <=225000000000000000000 ){
    //             data = (value * 15) /100;
    //             return (data , "Diamond"); 
    //     }else  if(usersData[ref].totalPremiumAddedByRefering + value > 225000000000000000000 ){
    //             data = (value * 16) /100;
    //             return (data , "Blue Diamond"); 
    //     }else{
    //              return (0, "No Rank"); 
    //     }
    // }



 function returnAgentReward(uint256 value ,address ref) public view returns(uint256 ,  string memory){
        uint256  data;
       
        if(totalBuisness[ref] > 50000000000000000 && totalBuisness[ref] <= 100000000000000000 ){
                data = (value * 7) /100;
                return (data , "Bronze"); 
        }else  if(totalBuisness[ref] > 100000000000000000   && totalBuisness[ref] <=200000000000000000 ){
                data = (value * 8) /100;
                return (data , "Silver"); 
        }else  if(totalBuisness[ref] > 200000000000000000  && totalBuisness[ref] <=500000000000000000 ){
                data = (value * 9) /100;
                return (data , "Gold"); 
        }else  if(totalBuisness[ref] > 500000000000000000  && totalBuisness[ref] <=1500000000000000000 ){
                data = (value * 10) /100;
                return (data , "Platinum"); 
        }else  if(totalBuisness[ref] > 1500000000000000000  && totalBuisness[ref] <=4000000000000000000){
                data = (value * 11) /100;
                return (data , "Beryl"); 
        }else  if(totalBuisness[ref] > 4000000000000000000  && totalBuisness[ref] <=10000000000000000000 ){
                data = (value * 12) /100;
                return (data , "Sapphire"); 
        }else  if(totalBuisness[ref] > 10000000000000000000  && totalBuisness[ref] <=30000000000000000000 ){
                data = (value * 13) /100;
                return (data , "Ruby"); 
        }else  if(totalBuisness[ref] > 30000000000000000000   && totalBuisness[ref] <=80000000000000000000 ){
                data = (value * 14) /100;
                return (data , "Emerald"); 
        }else  if(totalBuisness[ref] > 80000000000000000000   && totalBuisness[ref] <=225000000000000000000 ){
                data = (value * 15) /100;
                return (data , "Diamond"); 
        }else  if(totalBuisness[ref] + value > 225000000000000000000 ){
                data = (value * 16) /100;
                return (data , "Blue Diamond"); 
        }else{
                 return (0, "No Rank"); 
        }
    }

    function BuyInsurance( uint256 amount , address referadBy, uint256 day) public payable{ // may be data  can be changed   bcz conditon are added according to previous  plan   
        require(isCollapsed == false,"Company Is Shutdown");
        // require(isExist[referadBy] == true, "Referal Not found");
        require(day > 0 ," day can't Be Zero" );
        require(day <= 100,"day can't Be more than 100 ");
        require(amount >0 ," Invalid Unit");
      

        if(usersData[msg.sender].isPurchased == true){
           require(usersData[msg.sender].insuranceEndTime < block.timestamp , "Previous Insurance Is Active"); 
        }
        uint256 toPay = returnPrice[day];
                toPay = ((amount*toPay));
        if(isLastTimePurchased[msg.sender]== true && isLastPurchasedWasClaimed[msg.sender] == false && isCollapsed == false){
            toPay = toPay -  (toPay*4)/100;
        }
     
        require(msg.value == toPay,"Inavlid Premium Amount");
    
        if(usersData[msg.sender].userID == 0){
            usersData[msg.sender].userID =idProvider;
            idToAddress[idProvider] = msg.sender;
            addressToId[msg.sender] = idProvider;
            isExist[msg.sender]= true;
            idProvider++;
            usersData[msg.sender].refererAddress = referadBy;
            
            // payable(referadBy).transfer((toPay*15)/100);
            // usersData[referadBy].referalIncomeRecived += (toPay*15)/100;
            emit registerDetail( usersData[msg.sender].userID ,msg.sender,usersData[msg.sender].refererAddress);
        }    

        usersData[msg.sender].amount = amount;
        usersData[msg.sender].paidPremiumAmount = toPay;
        usersData[msg.sender].timeOfInsurancePurchased = block.timestamp;
        usersData[msg.sender].sharePurchased = amount;
        usersData[msg.sender].insuranceEndTime = block.timestamp + (60*60*24*day);  // now 1 day = 1 day
        // usersData[msg.sender].insuranceEndTime = block.timestamp + (60*day); // for testnet 

        usersData[msg.sender].isInsuranceActive = true;
        usersData[msg.sender].isPurchased =true;
        isLastTimePurchased[msg.sender]= true;
        isLastPurchasedWasClaimed[msg.sender]=false;
        totalShareHolding += amount;
        totalBuisness[usersData[msg.sender].refererAddress] += toPay;
        uint256 reward; string memory rak;
        (reward , rak) = returnAgentReward(toPay,usersData[msg.sender].refererAddress);

        // payable(referadBy).transfer(reward); // comment to check non active user  by Storing in Below line 
        
        referalRewardAvailableForClaim[usersData[msg.sender].refererAddress]+= reward;

        usersData[usersData[msg.sender].refererAddress].totalPremiumAddedByRefering+= reward; 
        poolFund +=  (toPay*55)/100;

        emit rankDetail(usersData[msg.sender].refererAddress ,usersData[usersData[msg.sender].refererAddress].totalPremiumAddedByRefering, rak ,block.timestamp,usersData[msg.sender].insuranceEndTime,toPay);
        emit buyReport(msg.sender , usersData[msg.sender].userID, usersData[msg.sender].refererAddress , day , amount , block.timestamp,usersData[msg.sender].insuranceEndTime,toPay); 
    }

    function changeCompanyStatus(bool shutdown) public onlyOwner {
        isCollapsed = shutdown;
        emit shutdownStatus(msg.sender, block.timestamp, isCollapsed );
    }

    function tranferDivedentAmount(address userAddress ,  uint256 amt ) public onlyOperator {
        require(userAddress !=address(0) ," invalid Address");
        require(address(this).balance >= amt, "insufficient contract balance");
        payable(userAddress).transfer(amt);
        emit userDevidentTranferdetail(userAddress , amt ,"divedent"); 
    }

    function transferClaimIncome(address userAddress ,  uint256 amt ) public onlyOperator{
        require(isCollapsed == true,"check company status");
        require(userAddress !=address(0) ," invalid Address");
        require(address(this).balance >= amt, "insufficient contract balance");
        payable(userAddress).transfer(amt);
        emit userClaimTranferdetail( userAddress, amt , "claim");
    }
    
    function updateUserClaimedAndPurchased(address userAddr , bool IsClaimed , bool isLastPurchased ) public onlyOperator{
        isLastPurchasedWasClaimed[userAddr] = IsClaimed;
        isLastTimePurchased[msg.sender]= isLastPurchased;
        emit userPurchaseAndClaimedUpdateDetail( userAddr , isLastPurchased ,   IsClaimed , block.timestamp);
    }   
    

    function rescueFundInCaseOf(uint256 ammt) public onlyOwner {
        require(address(this).balance >= ammt, "insufficient contract balance");
        payable(msg.sender).transfer(ammt);
    }

    function returnCalculatedPrice(address user , uint256 amount ,uint256 day ) public view  returns(uint256){
        require(user != address(0),"invalid address");
        require(amount > 0 ,"invalid unit");
        require(day > 0 ,"invalid day");
        uint256 toPay = returnPrice[day];
                toPay = ((amount*toPay));
               
        if(isLastTimePurchased[user]== true && isLastPurchasedWasClaimed[user] == false && isCollapsed == false){
            toPay = toPay -  (toPay*4)/100;
        }

        return toPay  ;
    }

    function claimRewardOfReferingIncome() public{
        require(isExist[msg.sender]== true,"For claiming Income First Buy Insuarance");
        payable(msg.sender).transfer( referalRewardAvailableForClaim[msg.sender]);   
        referalRewardAvailableForClaim[msg.sender] =0;     
    }


    receive() external payable {
    }


}