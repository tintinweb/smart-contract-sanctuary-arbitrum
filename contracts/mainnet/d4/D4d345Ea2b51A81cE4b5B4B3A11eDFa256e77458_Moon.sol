/**
 *Submitted for verification at Arbiscan on 2023-04-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;



library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b <= a, errorMessage);
        return a - b;
    }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a / b;
    }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a % b;
    }
    }
}

interface GameToken{
    /**
     * @dev Mint new game token and allocate it to the specified account.
      * @param _account Token recipient address.
      * @param _newBalance New token balance.
      */
    function mintToken(address _account, uint256 _newBalance) external;
    /**
     * @dev Distribute Cakewalk (CAKE) dividends.
      * @param _amount Dividend amount.
      */
    function distributeCAKEDividends(uint256 _amount) external;
    /**
     * @dev Get the accumulative dividend income of the specified owner.
      * @param _owner Token owner address.
      * @return Accumulative dividend.
      */
    function accumulativeDividendOf(address _owner) external view returns(uint256);
}


contract Moon{
    using SafeMath for uint;
    // The start time of the GameDefi sale.
    uint256 public startTime;
    // The end time of the GameDefi sale.
    uint256 public endTime;
    // The cycle of the GameDefi sale.
    uint256 public cycle;
    uint256 private gasForProcessing;
    // Private variable holding the name of the token.
    string private moonName = "Moon";
    address private  teamAddress;
    uint256 public reserveIn = 1000e18;
    uint256 public reserveOut = 1000000e18;
    uint256 public num = 1000001000001001;
    uint256 public cycleprice = 1000e18;


    /**
    @dev Struct to store the balance information for different types of balances
    @param superBalance The balance of super node rewards
    @param smallBalance The balance of small reward node rewards
    @param everyoneBalance The balance of the rewards already distributed to everyone
    @param cycleBalance The balance of the current cycle
    */
    struct BalanceInfo{
        uint256  superBalance;
        uint256  smallBalance;
        uint256  everyoneBalance;
        uint256  cycleBalance;
    }
    /**
    @dev Struct to store the fee information for different types of fees
    @param teamRewardsFee The fee for team rewards
    @param partnerRewardsFee The fee for partner rewards
    @param superJackpotFee The fee for the super jackpot
    @param smallRewardFee The fee for small rewards
    @param everyoneRewardsFee The fee for the rewards to everyone
    @param cycleFee The fee for the current cycle
    */
    struct FeeInfo{
        uint256  teamRewardsFee;
        uint256  partnerRewardsFee;
        uint256  superJackpotFee;
        uint256  smallRewardFee;
        uint256  everyoneRewardsFee;
        uint256  cycleFee;
    }
    /**

    @dev Struct to store the announcement information
    @param newBuyAddress The address of the latest buyer
    @param queryCount The amount of keys bought in the latest purchase
    @param billboardCount The total number of billboards purchased
    @param billboardPrice The price of the billboard
    @param firstBillboardName The name of the latest billboard purchased
    @param firstBillboardAddeess The address of the person who purchased the latest billboard
    @param SMRewardsAddress The address to claim small rewards
    @param SmRewardCount The amount of small rewards to claim
    */
    struct AnnouncementInfo{
        uint256  queryCount;
        uint256  billboardCount;
        uint256  billboardPrice;
        uint256  SmRewardCount;
        uint256  theMoon;
        uint256  GameDefiCount;
        uint256  SMcount;
        address  GameTokenAddress;
        address  newBuyAddress;
        address  firstBillboardAddeess;
        address  SMRewardsAddress;
        string   firstBillboardName;
    }
    /**
    @dev Struct to store user information
    @param partnerAddress The address of the user's partner
    @param rewardsReceived The amount of rewards received by the user
    @param partnerRewards The amount of rewards received by the user's partner
    @param received The amount of keys purchased by the user
    @param SFRewards The amount of rewards the user can claim from the small reward pool
    @param SMRewards The amount of rewards the user can claim from the super jackpot pool
    @param billboardStatus The status of whether the user has purchased a billboard
    */
    struct UserInfo {
        address partnerAddress;
        uint256 partnerRewards;
        uint256 received;
        uint256 SFRewards;
        uint256 SMRewards;
        bool billboardStatus;
    }
    // A mapping to store the winner's address for each cycle
    mapping(uint256 => address) public cycleInfo; 
    // A mapping associates a string (billboard name) to an address representing the owner of the billboard.
    mapping(string => address) public UserBillboard;
    // A mapping that stores the address of the user's billboard based on its hash value
    mapping(bytes32 => address) public UserBillboardHash;
    // A mapping that stores the name of the user's billboard based on its address
    mapping(address => string) public UserBillboardAddress;
    // A mapping that stores the hash value of the user's billboard name based on its address
    mapping(address => bytes32) public UserBillboardHashAddress;
    // A mapping that stores the user's information based on their address
    mapping(address => UserInfo) public Users;

    // A mapping that stores the announcement information based on the announcement
 
    mapping(string => AnnouncementInfo) public Announcement;
    // A mapping that stores the fee information based on the fee name
 
    mapping(string => FeeInfo) public Fee;
    // A mapping that stores the balance information based on the balance name
    mapping(string => BalanceInfo) public Balance;


    constructor(
        address teamaddress_,
        address TokenDividendTrackerAddress_,
        uint256[6] memory FeeSetting_,
        uint256 gasForProcessing_
    ) payable {
        teamAddress = teamaddress_;
        Announcement[moonName].GameTokenAddress = TokenDividendTrackerAddress_;
        Fee[moonName].teamRewardsFee = FeeSetting_[0];
        Fee[moonName].partnerRewardsFee = FeeSetting_[1];
        Fee[moonName].superJackpotFee = FeeSetting_[2];
        Fee[moonName].smallRewardFee = FeeSetting_[3];
        Fee[moonName].everyoneRewardsFee = FeeSetting_[4];
        Fee[moonName].cycleFee = FeeSetting_[5];
        require(FeeSetting_[0]+FeeSetting_[1]+FeeSetting_[2]+FeeSetting_[3]+FeeSetting_[4]+FeeSetting_[5] == 100,"ERROR");
        Announcement[moonName].billboardPrice = 1e17;
        cycle = 1;
        gasForProcessing = gasForProcessing_;

    }

    receive() external payable {}
    /**
    @dev This function allows a user to stake tokens and buy a billboard with a given name.
    @param _billboardName The name of the billboard being purchased.
    @param _quantitys The quantity of tokens being staked.
    **/
    function stake(
        string memory _billboardName,
        uint256 _quantitys
    ) public payable{
        require(!isContract(msg.sender), "This function can only be called by an externally owned account.");
        require(msg.value == getAmountIn(_quantitys),"PRICE ERROR");
        require(bytes(_billboardName).length < 100,"LENGTH ERROR");
  
        if(endTime != 0 && startTime != 0){
            require(block.timestamp < endTime,"TIME ERROR");
        }
        uint256 currentTimestamp = block.timestamp;
        uint256 quantitysTokenAmount = 1e18 * _quantitys;

        if(Announcement[moonName].GameDefiCount + _quantitys > 999 && startTime == 0 && endTime == 0){
            startTime = currentTimestamp;
            endTime = currentTimestamp + 1 days;
        }
        if(endTime != 0 && (endTime - currentTimestamp) < 1 days) {
            endTime += 60;
        }
        bytes32 collisionHash = collision(_billboardName);
        address partnerAddress = UserBillboardHash[collisionHash];
        if(partnerAddress != address(0)){
            Users[msg.sender].partnerAddress = partnerAddress;
        }
        dividends();
        buyKey(_quantitys);
        GameToken(Announcement[moonName].GameTokenAddress).mintToken(msg.sender, quantitysTokenAmount);
        Announcement[moonName].GameDefiCount += _quantitys;
        Announcement[moonName].newBuyAddress = msg.sender;
        Announcement[moonName].queryCount = _quantitys;

    }

    /**
    @dev Allows a user to reinvest their accumulated dividends into the project by staking additional tokens
    @param BillboardName The name of the billboard the user wishes to stake tokens towards
    */
    function reinvestmentIncome(string memory BillboardName) external{
        if(endTime != 0 && startTime != 0){
            require(block.timestamp < endTime,"TIME ERROR");
        }
        require(GameToken(Announcement[moonName].GameTokenAddress).accumulativeDividendOf(msg.sender) > 0,"ERROR");
        require(userReceived() > 0,"ERROR");
        uint256 rewardsReceived = GameToken(Announcement[moonName].GameTokenAddress).accumulativeDividendOf(msg.sender)-
        Users[msg.sender].received;
        uint256 _quantity = getAmountOut(rewardsReceived)/1e18;
        Users[msg.sender].received += getAmountIn(_quantity);
        require(_quantity >=1 ,"QUANTITY ERROR");
        Announcement[moonName].newBuyAddress = msg.sender;
        Announcement[moonName].queryCount = _quantity;
        getAmountIn(_quantity);
        getreinvestmentIncome(BillboardName,_quantity);
    }

    /**
    @dev Allow users to reinvest their accumulated dividends to purchase more tokens and increase their potential earnings.
    @param _billboardName The name of the billboard that the user wants to purchase.
    @param _quantity The number of tokens the user wants to purchase with their accumulated dividends.
    */
    function getreinvestmentIncome(
        string memory _billboardName,
        uint256 _quantity) internal{
        if(Announcement[moonName].GameDefiCount + _quantity > 999){
            startTime = block.timestamp;
            endTime = block.timestamp + 1 days;
        }
        if(endTime != 0 && (endTime - block.timestamp) < 1 days) {
            endTime + 60;
        }
        bytes32 collisionHash  = collision(_billboardName);
        if(UserBillboardHash[collisionHash] != address(0)){
            Users[msg.sender].partnerAddress = UserBillboardHash[collisionHash];
        }
        dividend(_quantity);
        GameToken(Announcement[moonName].GameTokenAddress).mintToken((msg.sender), 1e18 * _quantity);
        Announcement[moonName].GameDefiCount += _quantity;
    }

  
    // This function allows a user to withdraw their partner rewards
    function getPartnerRewards() external{
        require(Users[msg.sender].partnerRewards  > 0,"ERROR");
        uint256 pr = Users[msg.sender].partnerRewards;
        Users[msg.sender].partnerRewards = 0;
        payable(msg.sender).transfer(pr);
    }

    /**
     * @dev Allows the user to withdraw their received dividends.
     */
    function getReceived() external{
        require(GameToken(Announcement[moonName].GameTokenAddress).accumulativeDividendOf(msg.sender) > 0,"ERROR");
        require(userReceived()  > 0,"ERROR");
        uint256 rewardsReceived = GameToken(Announcement[moonName].GameTokenAddress).accumulativeDividendOf(msg.sender)
        - Users[msg.sender].received;
        Users[msg.sender].received += rewardsReceived;
        payable(msg.sender).transfer(rewardsReceived);
    }

    // Function to retrieve the amount of dividends received by a user
    function userReceived() public view returns(uint256){
        uint256 totalReceived = GameToken(Announcement[moonName].GameTokenAddress).accumulativeDividendOf(msg.sender);
        uint256 alreadyReceived = Users[msg.sender].received;
        uint256 remaining = totalReceived - alreadyReceived;
        return remaining;
    }

    /**
    @dev Buy a billboard with a specified name.
    @param _billboardName Name of the billboard to be purchased.
    Requirements:
    Function can only be called by an externally owned account.
    Length of _billboardName should be less than 100.
    _billboardName should be equal to Announcement[moonName].firstBillboardName.
    The value sent should be equal to the newPrice of the billboard.
    _billboardName should not already exist in UserBillboard mapping.
    Effects:
    If all requirements are met, the new billboard is created with its mapping to the caller's address.
    If the billboard is not the first one, 90% of the purchase price is transferred to the last address to buy a billboard.
    The remaining 10% is transferred to the teamAddress.
    */
    function buybillboard(
        string memory _billboardName
    ) public payable{
        require(!isContract(msg.sender), "This function can only be called by an externally owned account.");
        require(bytes(_billboardName).length > 0, "Billboard name cannot be empty");
        require(bytes(_billboardName).length <= 36,"NAME ERROR");
        uint256 newPrice = billboardPriceFactory();
        require(msg.value == newPrice ,"PRICE ERROR");
        require(UserBillboard[_billboardName] == address(0),"billboardName Error");
        require(keccak256(abi.encodePacked(_billboardName)) != keccak256(abi.encodePacked("Moon")), "Invalid billboard name");
        address lastAddress = Announcement[moonName].firstBillboardAddeess;
        bytes32 collisionHash = collision(_billboardName);
        require(UserBillboardHash[collisionHash] == address(0),"HASH Error");
        Announcement[moonName].firstBillboardName = _billboardName;
        Announcement[moonName].firstBillboardAddeess = msg.sender;
        UserBillboard[_billboardName] = msg.sender;
        UserBillboardAddress[msg.sender] = _billboardName;
        UserBillboardHash[collisionHash] = msg.sender;
        UserBillboardHashAddress[msg.sender] = collisionHash;
        Users[msg.sender].billboardStatus = true;
        if(Announcement[moonName].billboardCount != 0){
            Announcement[moonName].billboardCount++;
            uint256 userbounty = (msg.value * 9e8) / 10e9;
            payable(lastAddress).transfer(msg.value - userbounty);
            payable(teamAddress).transfer(userbounty);
            Announcement[moonName].billboardPrice = newPrice;
        }else{
            Announcement[moonName].billboardCount++;
            Announcement[moonName].billboardPrice = newPrice;
            payable(teamAddress).transfer(msg.value);
        }
    }

    
    /**
    @dev Calculates the price for buying a new billboard based on the current number of billboards.
    @return The price of the new billboard in wei.
    */
    function billboardPriceFactory() public view returns(uint256){
        if(Announcement[moonName].billboardCount == 0){
            return Announcement[moonName].billboardPrice;
        }else{
            return (Announcement[moonName].billboardPrice * 2e8) / 10e8 + Announcement[moonName].billboardPrice;
        }
    }

    /**
    @dev Allows a user to help launch the project by calling this function after the launch time has passed.
    @notice Only external accounts can call this function.
    @notice The function checks if the current time is greater than the endTime and if the newBuyAddress matches the cycleInfo for the current cycle.
    @notice The function also checks if newBuyAddress is not equal to address(0).
    @notice If the caller of the function is a MultiFee contract, the function calculates the SuperFee rewards and sets the next cycle.
    @notice If the caller of the function is not a MultiFee contract, the function extends the endTime by 1 hour.
    */
    function helplaunch() public{
        require(!isContract(msg.sender), "This function can only be called by an externally owned account.");
        require(block.timestamp > endTime,"ERROR TIME");
        require(Announcement[moonName].newBuyAddress != address(0),"ERROR ADDRESS");
        uint256 gasLimit = gasleft() - 2000;
        require(gasLimit >= gasForProcessing, "ERROR GAS");
        if(isMFee()){
            cycleInfo[cycle] = Announcement[moonName].newBuyAddress;
            uint256 HFee = Balance[moonName].superBalance * (1) / (100) ;
            uint256 Sub = Balance[moonName].superBalance;
            startTime = 0;
            endTime = 0;
            Balance[moonName].superBalance = 0;
            Balance[moonName].superBalance = Balance[moonName].cycleBalance;
            Balance[moonName].cycleBalance = 0;
            cycle++;
            Announcement[moonName].GameDefiCount = 0;
            Announcement[moonName].theMoon = 0;
            Users[msg.sender].SFRewards = HFee ;
            Users[Announcement[moonName].newBuyAddress].SFRewards = Sub - HFee;
            cycleStake();
        }else{
            Announcement[moonName].theMoon++;
            endTime += 1 hours;
        }
    }



    // Allows the user to renew their billboard by paying the current price
    function renewBillboard() public payable {
        require(!isContract(msg.sender), "This function can only be called by an externally owned account.");
        require(Users[msg.sender].billboardStatus == true,"ERROR STATUS");
        uint256 newPrice = billboardPriceFactory();
        require(msg.value == newPrice ,"PRICE ERROR");
        uint256 userbounty = (msg.value * 9e8) / 10e9;
        Announcement[moonName].firstBillboardName = UserBillboardAddress[msg.sender];
        address lastBillboardAddeess = Announcement[moonName].firstBillboardAddeess;
        Announcement[moonName].firstBillboardAddeess = msg.sender;
        Announcement[moonName].billboardPrice = newPrice;
        payable(teamAddress).transfer(userbounty);
        payable(lastBillboardAddeess).transfer(msg.value - userbounty);
    }


    function dividend(uint256 _quantitys) internal {
        uint256 teamRewardsFee = Fee[moonName].teamRewardsFee;
        uint256 partnerRewardsFee = Fee[moonName].partnerRewardsFee;
        uint256 superJackpotFee = Fee[moonName].superJackpotFee;
        uint256 smallRewardFee = Fee[moonName].smallRewardFee;
        uint256 everyoneRewardsFee = Fee[moonName].everyoneRewardsFee;
        uint256 cycleFee = Fee[moonName].cycleFee;
        uint256 FIXED_POINT = 10**18;
        uint256 msgValue = getAmountIn(_quantitys);
        uint256 teamFee = (msgValue * teamRewardsFee * FIXED_POINT / 100);
        uint256 partnerFee = (msgValue * partnerRewardsFee * FIXED_POINT / 100);
        uint256 superJackpotAmount = (msgValue * superJackpotFee * FIXED_POINT / 100);
        uint256 smallRewardAmount = (msgValue * smallRewardFee * FIXED_POINT / 100);
        uint256 everyoneRewardsAmount = (msgValue * everyoneRewardsFee * FIXED_POINT / 100);
        uint256 cycleFeeAmount = (msgValue * cycleFee * FIXED_POINT / 100);
        Balance[moonName].superBalance += superJackpotAmount / FIXED_POINT;
        Balance[moonName].smallBalance += smallRewardAmount / FIXED_POINT;
        Balance[moonName].cycleBalance += cycleFeeAmount / FIXED_POINT;
        Balance[moonName].everyoneBalance += everyoneRewardsAmount / FIXED_POINT;

        payable(teamAddress).transfer(teamFee / FIXED_POINT);
        if (Users[msg.sender].partnerAddress == address(0)) {
            payable(teamAddress).transfer(partnerFee / FIXED_POINT);
        } else {
            Users[Users[msg.sender].partnerAddress].partnerRewards += partnerFee / FIXED_POINT;
        }
        if(Announcement[moonName].queryCount!=0){
            GameToken(Announcement[moonName].GameTokenAddress).distributeCAKEDividends(everyoneRewardsAmount / FIXED_POINT);
        }else{
            Balance[moonName].superBalance += everyoneRewardsAmount / FIXED_POINT;
        }
        if (isSMFee()) {
            uint256 smallRewardCount = Balance[moonName].smallBalance;
            Balance[moonName].smallBalance = 0;
            Announcement[moonName].SMcount = 0;
            Users[msg.sender].SMRewards += smallRewardCount;
            Announcement[moonName].SMRewardsAddress = msg.sender;
            Announcement[moonName].SmRewardCount = smallRewardCount;
        }

        Announcement[moonName].SMcount++;
    }


    function dividends() internal {
        uint256 teamRewardsFee = Fee[moonName].teamRewardsFee;
        uint256 partnerRewardsFee = Fee[moonName].partnerRewardsFee;
        uint256 superJackpotFee = Fee[moonName].superJackpotFee;
        uint256 smallRewardFee = Fee[moonName].smallRewardFee;
        uint256 everyoneRewardsFee = Fee[moonName].everyoneRewardsFee;
        uint256 cycleFee = Fee[moonName].cycleFee;
        uint256 FIXED_POINT = 10**18;
        uint256 msgValue = msg.value;
        uint256 teamFee = (msgValue * teamRewardsFee * FIXED_POINT / 100);
        uint256 partnerFee = (msgValue * partnerRewardsFee * FIXED_POINT / 100);
        uint256 superJackpotAmount = (msgValue * superJackpotFee * FIXED_POINT / 100);
        uint256 smallRewardAmount = (msgValue * smallRewardFee * FIXED_POINT / 100);
        uint256 everyoneRewardsAmount = (msgValue * everyoneRewardsFee * FIXED_POINT / 100);
        uint256 cycleFeeAmount = (msgValue * cycleFee * FIXED_POINT / 100);
        Balance[moonName].superBalance += superJackpotAmount / FIXED_POINT;
        Balance[moonName].smallBalance += smallRewardAmount / FIXED_POINT;
        Balance[moonName].cycleBalance += cycleFeeAmount / FIXED_POINT;
        Balance[moonName].everyoneBalance += everyoneRewardsAmount / FIXED_POINT;
        payable(teamAddress).transfer(teamFee / FIXED_POINT);
        if (Users[msg.sender].partnerAddress == address(0)) {
            payable(teamAddress).transfer(partnerFee / FIXED_POINT);
        } else {
            Users[Users[msg.sender].partnerAddress].partnerRewards += partnerFee / FIXED_POINT;
        }

        if(Announcement[moonName].queryCount!=0){
            GameToken(Announcement[moonName].GameTokenAddress).distributeCAKEDividends(everyoneRewardsAmount / FIXED_POINT);
        }else{
            Balance[moonName].superBalance += everyoneRewardsAmount / FIXED_POINT;
        }
        if (isSMFee()) {
            uint256 smallRewardCount = Balance[moonName].smallBalance;
            Balance[moonName].smallBalance = 0;
            Announcement[moonName].SMcount = 0;
            Users[msg.sender].SMRewards += smallRewardCount;
            Announcement[moonName].SMRewardsAddress = msg.sender;
            Announcement[moonName].SmRewardCount = smallRewardCount;
        }
        Announcement[moonName].SMcount++;
    }



    //Allows a user to withdraw their small reward earnings.
    function withdrawSmallRewards() public{
        require(!isContract(msg.sender), "This function can only be called by an externally owned account.");
        require(Users[msg.sender].SMRewards > 0 ,"No rewards to withdraw.");
        uint256 rewards = Users[msg.sender].SMRewards;
        Users[msg.sender].SMRewards = 0;
        payable(msg.sender).transfer(rewards);
    }

    /**
    @dev Allows the latest buyer to receive the super jackpot if applicable.
    @dev The function can only be called by an externally owned account.
    @dev The sender must be the latest buyer.
    @dev The current time must be after the end time.
    @dev The latest buyer must be correct.
    @dev If applicable, start a new cycle and distribute the jackpot to the latest buyer.
    */
    function superJackpotReceive() public{
        require(!isContract(msg.sender), "This function can only be called by an externally owned account.");
        require(msg.sender == Announcement[moonName].newBuyAddress,"Sender is not the latest buyer");
        require(block.timestamp > endTime,"Current time is not after end time");
        require(Balance[moonName].superBalance > 0,"SuperBalance Error");
        uint256 gasLimit = gasleft() - 2000;
        require(gasLimit >= gasForProcessing, "ERROR GAS");
        if(isMFee()){
            uint256 SupBa = Balance[moonName].superBalance;
            startTime = 0;
            endTime = 0;
            cycleInfo[cycle] = msg.sender;
            cycle++;
            Balance[moonName].superBalance = Balance[moonName].cycleBalance;
            Balance[moonName].cycleBalance = 0;
            Announcement[moonName].GameDefiCount = 0;
            Announcement[moonName].theMoon = 0;
            Users[msg.sender].SFRewards = SupBa;
            cycleStake();
        }else{
            Announcement[moonName].theMoon++;
            endTime += 1 hours;
        }
    }
  
    function getUserAll() public view returns(uint256){
        if(Announcement[moonName].GameDefiCount > 1000){
            return 0;
        }else{
            return  1000 - Announcement[moonName].GameDefiCount;
        }
    }
    
    function getTheMoon() public view returns(bool){
        if(Announcement[moonName].theMoon != 0){
            return false;
        }else{
            return true;
        }
    }

    function reviewSuper() public{
        require(Users[msg.sender].SFRewards > 0,"Error");
        uint256 sr = Users[msg.sender].SFRewards;
        Users[msg.sender].SFRewards = 0;
        payable(msg.sender).transfer(sr);
    }

  
    function ToMoon() public view returns(address){
        return cycleInfo[cycle - 1];
    }

    /**
     * @dev Function to check if a random number is less than the SMcount variable.
     * @return A boolean value indicating whether the condition is true or false.
     */
    function isSMFee() public view returns(bool){
        if(rand() < Announcement[moonName].SMcount ){
            return true;
        }
        return false;
    }
    /**
     * @dev Internal function that determines whether a transaction should pay a management fee.
     * @return bool Returns true if a management fee should be charged, false otherwise.
     */
    function isMFee() internal view returns(bool){
        if(rand() < 33){
            return true;
        }
        return false;
    }
    // This function generates a random number between 0 and 100 (inclusive) using the block timestamp and the previous randao value as the seed
    // It uses the keccak256 hash function to generate a pseudo-random value from the seed, and then takes the modulo 101 to get a value between 0 and 100.
    function rand() public view returns(uint8) {
        bytes32 blockHash = blockhash(block.number - 1);
        bytes32 seed = keccak256(abi.encodePacked(block.timestamp, blockHash));
        uint8 random = uint8(uint256(seed) % 101);
        return random;
    }

    /**
    @dev Internal function to check if an address is a contract.
    @param addr The address to be checked.
    @return bool Returns true if the address is a contract, false otherwise.
    */
    function isContract(address addr) private view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function cycleStake() internal {
          reserveIn = cycleprice + (100e18 * cycle);
          reserveOut = 1000000e18 ;
          uint256 newnum = (num * 2e8) / 10e8 + num;
          cycleprice = reserveIn;
          num = newnum;
    }
  
    function getAmountIn(uint256 _quantitys) public view returns (uint256) {
        uint256 amountOut = _quantitys * 1e18;
        require(amountOut > 0, "PancakeLibrary: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "PancakeLibrary: INSUFFICIENT_LIQUIDITY");
        uint numerator = reserveIn.mul(amountOut).mul(10000);
        uint denominator = reserveOut.sub(amountOut).mul(10000);
        return  (numerator / denominator).add(1);
    }

    function getAmountOut(uint amountIn) public view returns (uint amountOut) {
        require(amountIn > 0, "PancakeLibrary: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "PancakeLibrary: INSUFFICIENT_LIQUIDITY");
        uint amountInWithFee = amountIn.mul(10000);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(10000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function if_quantitys() internal {
        if(getAmountIn(1) > num*2){
            num = getAmountIn(1).div(20).mul(13);
            reserveIn = reserveIn.div(20).mul(13);
        }
    }
   
    function buyKey(uint256 _quantitys) internal {
        if_quantitys();
        uint256 money = getAmountIn(_quantitys);
        reserveIn += 1e18 * _quantitys;
        reserveOut -= money;

    }

    // Example of hash collision
    // Hash collision can occur when you pass more than one dynamic data type
    // to abi.encodePacked. In such case, you should use abi.encode instead.
    function collision(
        string memory _text
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_text));
    }


    function getTime() public view returns(uint256,uint256,uint256){
        return (block.timestamp,startTime,endTime);
    }
}