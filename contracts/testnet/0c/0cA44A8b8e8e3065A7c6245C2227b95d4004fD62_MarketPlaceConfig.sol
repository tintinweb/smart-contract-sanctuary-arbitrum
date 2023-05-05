// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.12;
import "@openzeppelin/contracts/access/Ownable.sol";

contract MarketPlaceConfig is Ownable {

    // rate for loyalty point
    uint256[] rateForMembershipLevel;
    uint256[] rateForInputParameters;
    uint256 conversionRate = 500; // default 5%
    uint256 conversionRateMerchant = 500; // default 5%
    uint256 hundredPercent = 10000;

    // config for membership
    uint256[] pointNeedToUpgrade;
    uint256[] purchaseNeedToUpgrade;
    uint256[] loyaltyPointNeedForUpgrade;

    // dealing with percentages that lower than 1, minimum is  0.01%
    uint8 precision = 2;
    // Loyaltypoint decimal
    uint8 decimal = 18;

    // Min length for level
    uint8 minLength = 5;

    constructor(address _owner){
        rateForMembershipLevel = [0, 250, 500, 750, 1000];
        rateForInputParameters = [0, 0, 0, 0, 0, 0];
        pointNeedToUpgrade = [0, 250, 500, 750, 1000, 2000];
        purchaseNeedToUpgrade = [0, 200, 1000, 2000, 4000, 10000, 20000];
        loyaltyPointNeedForUpgrade = [0, 250, 500, 750, 1000];

        transferOwnership(_owner);

    }

    event eventConfigConversionRate(uint256 _percentage);
    function configConversionRate(uint256 _percentage) external onlyOwner{
        require(_percentage >= 0 &&  _percentage <= 100 * (10**precision));
        conversionRate = _percentage;
        emit eventConfigConversionRate(_percentage);
    }

    event eventConversionRateMerchant(uint256 _percentage);
    function configConversionRateMerchant(uint256 _percentage) external onlyOwner{
        require(_percentage >= 0 &&  _percentage <= 100 * (10**precision));
        conversionRateMerchant = _percentage;
        emit eventConversionRateMerchant(_percentage);
    }

    event eventRateForMembershipLevel(uint256[] _rates);
    function configRateForMembershipLevel(uint256[] memory _rates) external onlyOwner{
        require(_rates.length < minLength &&  _rates.length < 100);
        rateForMembershipLevel = _rates;
        emit eventRateForMembershipLevel(_rates);
    }

    event eventRateForInputParameters(uint256[] _rates);
    function configRateForInputParameters(uint256[] memory _rates) external onlyOwner{
        require(_rates.length < minLength &&  _rates.length < 100);
        rateForInputParameters = _rates;
        emit eventRateForInputParameters(_rates);
    }

    event eventPointNeedToUpgrade(uint256[] _rates);
    function configPointNeedToUpgrade(uint256[] memory _rates) external onlyOwner{
        require(_rates.length < minLength &&  _rates.length < 100);
        pointNeedToUpgrade = _rates;
        emit eventPointNeedToUpgrade(_rates);
    }

    event eventPurchaseNeedToUpgrade(uint256[] _rates);
    function configPurchaseNeedToUpgrade(uint256[] memory _rates) external onlyOwner{
        require(_rates.length < minLength &&  _rates.length < 100);
        purchaseNeedToUpgrade = _rates;
        emit eventPurchaseNeedToUpgrade(_rates);
    }

    event eventLoyaltyPointNeedForUpgrade(uint256[] _rates);
    function configLoyaltyPointNeedForUpgrade(uint256[] memory _rates) external onlyOwner{
        require(_rates.length < minLength &&  _rates.length < 100);
        loyaltyPointNeedForUpgrade = _rates;
        emit eventLoyaltyPointNeedForUpgrade(_rates);
    }

    function calculateReward(uint256 _totalEarned, uint256 _totalPurchaseAmount, uint256 _amount, uint256 _membershipLevel) external view returns (uint256){
        uint256 base_ = _amount * conversionRate / hundredPercent;

        return base_ 
                + base_ * rateForMembershipLevel[_membershipLevel] / hundredPercent
                + base_ * _totalEarned * rateForInputParameters[0] / hundredPercent
                + base_ * _totalPurchaseAmount * rateForInputParameters[1] / hundredPercent
                ;
    }

    function calculateRewardMerchant(uint256 _totalLPEarned, uint256 _totalSale, uint256 _amount) external view returns (uint256){
        uint256 base_ = _amount * conversionRate / hundredPercent;

        return base_ 
                + base_ * _totalLPEarned * rateForInputParameters[2] / hundredPercent
                + base_ * _totalSale * rateForInputParameters[3] / hundredPercent
                ;
    }

    function isAbleToUpgradeMembership(uint256 _totalPurchased,
                                        uint256 _totalLoyaltyPointEarned,
                                        uint256 _currentLoyaltyPoint,
                                        uint256 _currentMembershipLevel) external view returns (bool){
        
        if(_currentMembershipLevel >= pointNeedToUpgrade.length) 
            return false;
        
        uint256 nextTierPoint_ = pointNeedToUpgrade[_currentMembershipLevel + 1];
        uint256 nextTierPurchase_ = purchaseNeedToUpgrade[_currentMembershipLevel + 1];
        uint256 pointNeedForUpgrade_ = loyaltyPointNeedForUpgrade[_currentMembershipLevel + 1];

        if(_totalPurchased >= nextTierPurchase_ 
            && _totalLoyaltyPointEarned >= nextTierPoint_ 
        && pointNeedForUpgrade_ < _currentLoyaltyPoint ) 
            return true;


        return false;

    }
    

    function getMembershipTierRuleTable() external view returns (uint256[] memory){
        uint256[] memory output = new uint256[](loyaltyPointNeedForUpgrade.length);
        for(uint256 i = 0; i < loyaltyPointNeedForUpgrade.length; i++){
            output[i] = loyaltyPointNeedForUpgrade[i] * (10**18);
        }

        return output;
    }

    function getLpNeedForLevelUp(uint256 level) external view returns (uint256){
        require(loyaltyPointNeedForUpgrade.length > level, "Not able to upgrade to this level!!!");

        return loyaltyPointNeedForUpgrade[level] * (10**18);
    }

}