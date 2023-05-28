/**
 *Submitted for verification at Arbiscan on 2023-05-28
*/

// For the 0xMT Pool dAPP @ https://dapp.pool.0xmt.com
// 0xMT Main Webpage https://0xmt.com
// Main Mineable Token contract: 0xAe56c981F9bb8b07E380B209FcD1498c5876Fd4c

pragma solidity ^0.8.17;

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: Only the contract owner can call this function");
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: Invalid new owner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract PoolHelper_0xMT is Ownable {
    struct UserSettings {
        uint256 minimumPayout;
        int256 maxFeeToPayInUSDCents;
        uint256 WITHDRAWL_ALL;
        uint256 maxFeeInPercent;
    }

    mapping(address => UserSettings) public userSettings;

    UserSettings public defaultSettings;

    constructor(uint256 defaultMinimumPayout, int256 defaultMaxFeeToPayInUSDCents, uint256 defaultMaxFeeInPercent, uint256 defaultWITHDRAWL_ALL) {
        defaultSettings.minimumPayout = defaultMinimumPayout;
        defaultSettings.maxFeeToPayInUSDCents = defaultMaxFeeToPayInUSDCents;
        defaultSettings.maxFeeInPercent = defaultMaxFeeInPercent;
        defaultSettings.WITHDRAWL_ALL = defaultWITHDRAWL_ALL;
    }



    function adjustMinimumPayout(uint256 _newMinimumPayout) public {
        if(_newMinimumPayout == 0){
            _newMinimumPayout = 1;
        }
        UserSettings storage settings = userSettings[msg.sender];
        settings.minimumPayout = _newMinimumPayout;
    }


    function adjustMaxFeeToPayInUSDCents(int256 _newMaxFeeToPayInUSD) public {
         int256 newMaxFee = _newMaxFeeToPayInUSD;
    if (newMaxFee == 0) {
        newMaxFee = -1;
    }
        UserSettings storage settings = userSettings[msg.sender];
        settings.maxFeeToPayInUSDCents= newMaxFee;
    }
    

    function adjustMaxPercent(uint256 _newMaxPercent) public {
        if(_newMaxPercent == 0){
            _newMaxPercent = 1;
        }
        UserSettings storage settings = userSettings[msg.sender];
        settings.maxFeeInPercent = _newMaxPercent;
    }


    function adjustAll(int256 _newMaxFeeToPayInUSD, uint256 _newMinimumPayout, uint256 _newMaxPercent) public{
        adjustMinimumPayout(_newMinimumPayout);
        adjustMaxPercent(_newMaxPercent);
        adjustMaxFeeToPayInUSDCents(_newMaxFeeToPayInUSD);
    }


    function z_adjust_2(int256 _newMaxFeeToPayInUSD, uint256 _newMinimumPayout) public{
        adjustMinimumPayout(_newMinimumPayout);
        adjustMaxFeeToPayInUSDCents(_newMaxFeeToPayInUSD);
    }

    function z_adjust_3(uint256 _newMaxPercent, uint256 _newMinimumPayout) public{
        adjustMinimumPayout(_newMinimumPayout);
        adjustMaxPercent(_newMaxPercent);
    }





    function getUsers_MaxFeeInCents(address user) public view returns (int256 MaxFeeInCents){
        UserSettings storage settings = userSettings[user];
        if(settings.maxFeeToPayInUSDCents == 0){
            return  defaultSettings.maxFeeToPayInUSDCents;
        }
        return  userSettings[user].maxFeeToPayInUSDCents;

    }

    function getUsers_MaxPercent(address user) public view returns (uint256 MaxFeeInPercent){
        UserSettings storage settings = userSettings[user];
        if(settings.maxFeeInPercent == 0){
            return  defaultSettings.maxFeeInPercent;
        }
        return  userSettings[user].maxFeeInPercent;

    }

    function getUsers_Minimum_Payout(address user) public view returns (uint256 minimumPayout){
        UserSettings storage settings = userSettings[user];
        if(settings.minimumPayout == 0){
            return  defaultSettings.minimumPayout;
        }
        return  userSettings[user].minimumPayout;

    }


    function getUsers_WITHDRAWL_ALL_Variable(address user) public view returns (uint256 minimumPayout){
        UserSettings storage settings = userSettings[user];
        if(settings.WITHDRAWL_ALL == 0){
            return  defaultSettings.WITHDRAWL_ALL;
        }
        return  userSettings[user].WITHDRAWL_ALL;

    }

    function WITHDRAW_ALL_ASSETS() external {
        UserSettings storage settings = userSettings[msg.sender];
        settings.WITHDRAWL_ALL = block.number;
    }
    

    function updateDefaultCents_admin(int _newMaxFeeToPayInUSDCents) external onlyOwner {
        defaultSettings.maxFeeToPayInUSDCents = _newMaxFeeToPayInUSDCents;

    }


    function updateDefaultPercent_admin(uint _newMaxPercent) external onlyOwner {
        defaultSettings.maxFeeInPercent = _newMaxPercent;
    }




    function updateDefaultMinPayout_admin(uint _newMinimumPayout) external onlyOwner {
        defaultSettings.minimumPayout = _newMinimumPayout;
    }






    function updateUserCents_admin(address user, int _newMaxFeeToPayInUSDCents) external onlyOwner {
        UserSettings storage settings = userSettings[user];
        settings.maxFeeToPayInUSDCents = _newMaxFeeToPayInUSDCents;

    }


    function updateUserPercent_admin(address user, uint _newMaxPercent) external onlyOwner {
        UserSettings storage settings = userSettings[user];
        settings.maxFeeInPercent = _newMaxPercent;
    }




    function updateUserMinPayout_admin(address user, uint _newMinimumPayout) external onlyOwner {
        UserSettings storage settings = userSettings[user];
        settings.minimumPayout = _newMinimumPayout;
    }





    function updateDefaultSettings(uint256 _newMinimumPayout, int256 _newMaxFeeToPayInUSDCents, uint256 _newMaxPercent) external onlyOwner {
        defaultSettings.minimumPayout = _newMinimumPayout;
        defaultSettings.maxFeeToPayInUSDCents = _newMaxFeeToPayInUSDCents;
        defaultSettings.maxFeeInPercent = _newMaxPercent;

    }
    function updateSettings_ADMIN_For_User(address user, uint256 _newMinimumPayout, int256 _newMaxFeeToPayInUSDCents, uint256 _newMaxPercent) external onlyOwner {
        UserSettings storage settings = userSettings[user];
        settings.minimumPayout = _newMinimumPayout;
        settings.maxFeeToPayInUSDCents = _newMaxFeeToPayInUSDCents;
        settings.maxFeeInPercent = _newMaxPercent;
    }


}