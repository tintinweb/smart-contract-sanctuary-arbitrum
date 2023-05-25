/**
 *Submitted for verification at Arbiscan on 2023-05-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
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

contract PayoutContract is Ownable {


    
    event MinimumPayoutAdjusted(address indexed user, uint256 newMinimumPayout, uint256 oldMinimum);
    event MaxFeeToPayInUSDCentsAdjusted(address indexed user, int256 newMaxFeeToPayInUSDCents, int256 oldMaxFee);
    event MaxPercentAdjusted(address indexed user, uint256 newMaxPercent, uint256 oldMaxPercent);
    event WithdrawAllAssets(address indexed user, uint256 block, uint256 oldBlock);



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







    function adjustMinimumPayout(uint256 _newMinimumPayout) external {
        if(_newMinimumPayout == 0){
            _newMinimumPayout = 1;
        }
        UserSettings storage settings = userSettings[msg.sender];

         emit MinimumPayoutAdjusted(msg.sender, _newMinimumPayout, userSettings[msg.sender].minimumPayout);

        settings.minimumPayout = _newMinimumPayout;
    }


    function adjustMaxFeeToPayInUSDCents(int256 _newMaxFeeToPayInUSD) external {
         int256 newMaxFee = _newMaxFeeToPayInUSD;
    if (newMaxFee == 0) {
        newMaxFee = -1;
    }

    emit MaxFeeToPayInUSDCentsAdjusted(msg.sender, newMaxFee, userSettings[msg.sender].maxFeeToPayInUSDCents);

    userSettings[msg.sender].maxFeeToPayInUSDCents= newMaxFee;
    }

    
    function adjustMaxPercent(uint256 _newMaxPercent) external {
        if(_newMaxPercent == 0){
            _newMaxPercent = 1;
        }
        UserSettings storage settings = userSettings[msg.sender];

    emit MaxPercentAdjusted(msg.sender, _newMaxPercent, userSettings[msg.sender].maxFeeInPercent);
        settings.maxFeeInPercent = _newMaxPercent;
    }


    function WITHDRAW_ALL_ASSETS() external {
        UserSettings storage settings = userSettings[msg.sender];
    emit WithdrawAllAssets(msg.sender, block.number, userSettings[msg.sender].WITHDRAWL_ALL);
        settings.WITHDRAWL_ALL = block.number;
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
        if(settings.maxFeeInPercent == 0){
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