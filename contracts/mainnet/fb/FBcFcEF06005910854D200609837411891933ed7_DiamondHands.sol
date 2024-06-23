// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/ReentrancyGuard.sol)

pragma solidity ^0.8.20;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IERC20 {
    function decimals() external view returns (uint8);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IUniswapV2Router {
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
}

contract DiamondHands is ReentrancyGuard {
    uint8 internal decimalsOfUSD;
    uint8 public depositFee;
    uint8 public withdrawalFee;
    uint32 public id;
    uint256 public unclaimedRevenue;
    address internal owner;
    address internal WETH;
    address internal USD;
    address internal uniswapV2Factory;
    address internal uniswapV2Router;

    struct Holding {
        bool isActive;
        bool isPureEther;
        uint256 amount;
        uint256 holdAtTimestamp;
        uint256 holdUntilTimestamp; // can be 0
        uint256 holdAtPriceInWETH; // can be 0
        uint256 holdUntilPriceInWETH; // can be 0
        uint256 holdAtPriceInUSD; // can be 0
        uint256 holdUntilPriceInUSD; // can be 0
        address token;
        address user;
    }

    mapping(address => uint32[]) ids;
    mapping(uint32 => Holding) holdings;

    mapping(bytes32 => address) refcodes;
    mapping(address => bytes32) referrals;
    mapping(address => address) whosReferred;
    mapping(address => uint32) totalRefs;
    mapping(address => uint256) totalRefGains;

    event InHold(bool indexed isPureEther, uint256 holdAtTimestamp);
    event UntilDate(uint256 holdUntilTimestamp);
    event UntilPriceWETH(uint256 holdAtPriceInWETH, uint256 holdUntilPriceInWETH);
    event UntilPriceUSD(uint256 holdAtPriceInUSD, uint256 holdUntilPriceInUSD);
    event Revenues(address indexed inviter, uint256 refShare, uint256 serviceShare);

    constructor(uint8 _decimalsOfUSD, address _WETH, address _USD, address _uniswapV2Factory, address _uniswapV2Router) {
        decimalsOfUSD = _decimalsOfUSD;
        depositFee = 2;
        withdrawalFee = 2;
        owner = msg.sender;
        WETH = _WETH;
        USD = _USD;
        uniswapV2Factory = _uniswapV2Factory;
        uniswapV2Router = _uniswapV2Router;
    }

    // Holdings

    function newHoldingEther(
        uint256 freezeAmount,
        uint256 freezeForSeconds, // can be 0
        uint256 freezeForX, // can be 0
        string memory refcode // pass anything if theres no refcode
    ) public payable nonReentrant {
        uint256 etherFee = getEtherDepositFee(freezeAmount);

        require(msg.value >= freezeAmount + etherFee, "Not enough ether fee included");
        require(msg.value > 0, "Amount to freeze hasnt provided");
        require(freezeForSeconds > 0 || freezeForX > 0, "Any type of freeze hasnt provided");

        // Distribute the fees
        distributeDepositFees(refcode, etherFee);

        // Init freeze
        id++;
        holdings[id].isPureEther = true;
        holdings[id].holdAtTimestamp = block.timestamp;
        emit InHold(true, block.timestamp);

        // Optional time related freeze
        if (freezeForSeconds > 0) {
            uint256 deadline = block.timestamp + freezeForSeconds;
            holdings[id].holdUntilTimestamp = deadline;
            emit UntilDate(deadline);
        }

        // Optional price related freeze
        if (freezeForX > 0) {
            require(freezeForX > 100, "Can freeze only for growth, where +1% is 101 and so on");
            uint256 currentPriceWETH = getTokenPriceV2(USD, 1 * 10**decimalsOfUSD, true);
            uint256 targetPriceWETH = currentPriceWETH * 100 / freezeForX;
            if (currentPriceWETH == 0) revert("WETH price of USD token is equal to 0");
            // store wei from 1 USD price = 258740411587277 wei = 0.000258740411587277 WETH
            // calc USD price on UI like 1 / 0.000258740411587277 WETH = 3864.87 USD/WETH
            holdings[id].holdAtPriceInWETH = currentPriceWETH;
            holdings[id].holdUntilPriceInWETH = targetPriceWETH;
            emit UntilPriceWETH(currentPriceWETH, targetPriceWETH);
        }

        // Store holder info
        ids[msg.sender].push(id);
        holdings[id].isActive = true;
        holdings[id].amount = freezeAmount;
        holdings[id].user = msg.sender;
    }

    function newHoldingToken(
        address token, 
        uint256 freezeAmount, 
        uint256 freezeForSeconds, // can be 0
        uint256 freezeForX, // can be 0
        bool isPriceGrowthGoalInUSD, // can be false
        string memory refcode // pass anything if theres no refcode
    ) public payable nonReentrant {
        uint8 decimals = IERC20(token).decimals();
        uint256 etherFee = getTokenDepositFee(token, freezeAmount);

        require(msg.value >= etherFee * 97 / 100, "Not enough ether fee included");
        require(freezeAmount > 0, "Amount to freeze hasnt provided");
        require(freezeForSeconds > 0 || freezeForX > 0, "Any type of freeze hasnt provided");

        // Transfer tokens
        IERC20(token).transferFrom(msg.sender, address(this), freezeAmount);

        // Distribute the fees
        distributeDepositFees(refcode, etherFee);

        // Init freeze
        id++;
        holdings[id].holdAtTimestamp = block.timestamp;
        emit InHold(true, block.timestamp);

        // Optional time related freeze
        if (freezeForSeconds > 0) {
            uint256 deadline = block.timestamp + freezeForSeconds;
            holdings[id].holdUntilTimestamp = deadline;
            emit UntilDate(deadline);
        }

        // Optional price related freeze
        if (freezeForX > 0) {
            require(freezeForX > 100, "Can freeze only for growth, where +1% is 101 and so on");
            uint256 currentPriceWETH = getTokenPriceV2(token, 1 * 10**decimals, true);
            uint256 targetPriceWETH = currentPriceWETH * freezeForX / 100;
            if (currentPriceWETH == 0) revert("WETH price of token is equal to 0");
            if (isPriceGrowthGoalInUSD) {
                uint256 currentPriceUSD = getTokenPriceV2(USD, currentPriceWETH, false);
                uint256 targetPriceUSD = currentPriceUSD * freezeForX / 100;
                if (currentPriceUSD == 0) revert("Microcaps (priced less than 0.000001 USD) are unsupported for USD target");
                // but microcaps still can be held with ETH target price
                holdings[id].holdAtPriceInUSD = currentPriceUSD;
                holdings[id].holdUntilPriceInUSD = targetPriceUSD;
                emit UntilPriceUSD(currentPriceUSD, targetPriceUSD);
            } else {
                holdings[id].holdAtPriceInWETH = currentPriceWETH;
                holdings[id].holdUntilPriceInWETH = targetPriceWETH;
                emit UntilPriceWETH(currentPriceWETH, targetPriceWETH);
            }
        }

        // Store holder info
        ids[msg.sender].push(id);
        holdings[id].isActive = true;
        holdings[id].amount = freezeAmount;
        holdings[id].token = token;
        holdings[id].user = msg.sender;
    }

    function withdrawHoldingToken(uint32 _id) public payable nonReentrant {
        uint8 decimals = IERC20(holdings[_id].token).decimals();
        uint256 currentPriceWETH = getTokenPriceV2(holdings[_id].token, 1 * 10**decimals, true);
        uint256 currentPriceUSD = getTokenPriceV2(USD, currentPriceWETH, false);
        uint256 etherFee = getTokenWithdrawalFee(holdings[_id].token, holdings[_id].amount);

        require(msg.value >= etherFee * 97 / 100, "Not enough ether fee included");
        require(holdings[_id].isActive == true, "Nothing to withdraw");

        // Deactivate
        holdings[_id].isActive = false;

        // Distribute the fees
        distributeWithdrawalFees(_id, etherFee);

        // Check eligibility
        if (holdings[_id].holdUntilTimestamp > 0 && block.timestamp > holdings[_id].holdUntilTimestamp) {
            IERC20(holdings[_id].token).transfer(holdings[_id].user, holdings[_id].amount);
            return;
        } else if (holdings[_id].holdUntilPriceInUSD > 0 && currentPriceUSD > holdings[_id].holdUntilPriceInUSD && currentPriceUSD != 0) {
            IERC20(holdings[_id].token).transfer(holdings[_id].user, holdings[_id].amount);
            return;
        } else if (holdings[_id].holdUntilPriceInWETH > 0 && currentPriceWETH > holdings[_id].holdUntilPriceInWETH && currentPriceWETH != 0) {
            IERC20(holdings[_id].token).transfer(holdings[_id].user, holdings[_id].amount);
            return;
        } else {
            revert("Target unlock date or price of held token hasnt reached yet");
        }
    }

    function withdrawHoldingEther(uint32 _id) public payable nonReentrant {
        uint256 currentPriceWETH = getTokenPriceV2(USD, 1 * 10**decimalsOfUSD, true);
        uint256 etherFee = getEtherWithdrawalFee(holdings[_id].amount);

        require(msg.value >= etherFee, "Not enough ether fee included");
        require(holdings[_id].isActive == true, "Nothing to withdraw");

        // Deactivate
        holdings[_id].isActive = false;

        // Distribute the fees
        distributeWithdrawalFees(_id, etherFee);

        // Check eligibility
        address payable holder = payable(holdings[_id].user);
        if (holdings[_id].holdUntilTimestamp > 0 && block.timestamp > holdings[_id].holdUntilTimestamp) {
            holder.transfer(holdings[_id].amount);
            return;
        } else if (holdings[_id].holdUntilPriceInWETH > 0 && currentPriceWETH > holdings[_id].holdUntilPriceInWETH && currentPriceWETH != 0) {
            holder.transfer(holdings[_id].amount);
            return;
        } else {
            revert("Target unlock date or USD price of held ether hasnt reached yet");
        }
    }

    // Getters

    function getTokenPriceV2(address token, uint256 tokenAmount, bool isTokenSell) public view returns (uint256) {
        address pair = IUniswapV2Factory(uniswapV2Factory).getPair(WETH, token);
        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(pair).getReserves();
        (address token0) = IUniswapV2Pair(pair).token0();

        (uint112 wethReserve, uint112 tokenReserve) = token0 == WETH ? (reserve0, reserve1) : (reserve1, reserve0);

        return IUniswapV2Router(uniswapV2Router).getAmountOut(
            tokenAmount, 
            isTokenSell ? tokenReserve : wethReserve, 
            isTokenSell ? wethReserve : tokenReserve
        );
    }

    function getEtherDepositFee(uint256 etherAmount) public view returns (uint256) {
        uint256 fee = etherAmount * depositFee / 100;
        return fee;
    }

    function getEtherWithdrawalFee(uint256 etherAmount) public view returns (uint256) {
        uint256 fee = etherAmount * withdrawalFee / 100;
        return fee;
    }

    function getTokenDepositFee(address token, uint256 tokenAmount) public view returns (uint256) {
        uint256 currentPrice = getTokenPriceV2(token, tokenAmount, true);
        uint256 fee = currentPrice * depositFee / 100;
        return fee;
    }

    function getTokenWithdrawalFee(address token, uint256 tokenAmount) public view returns (uint256) {
        uint256 currentPrice = getTokenPriceV2(token, tokenAmount, true);
        uint256 fee = currentPrice * withdrawalFee / 100;
        return fee;
    }

    function getHoldingInfo(uint32 _id) external view returns (Holding memory) {
        return holdings[_id];
    }

    function getHoldingIds(address userAddress) external view returns (uint32[] memory) {
        return ids[userAddress];
    }

    // Refcodes

    function createMyRefcode(string memory refCode) public {
        bytes32 encoded = stringToBytes32(refCode);
        require(refcodes[encoded] == address(0), "This refCode is already taken");
        require(referrals[msg.sender] == bytes32(0), "This address already has a refcode");
        refcodes[encoded] = msg.sender;
        referrals[msg.sender] = encoded;
    }

    function getRefAddressByRefCode(string memory refCode) public view returns (address refAddress) {
        bytes32 encoded = stringToBytes32(refCode);
        return refcodes[encoded];
    }

    function getRefCodeByAddress(address userAddress) public view returns (bytes32) {
        return referrals[userAddress];
    }

    function getReferral(address userAddress) public view returns (address) {
        return whosReferred[userAddress];
    }

    function getTotalRefs(address userAddress) public view returns (uint32) {
        return totalRefs[userAddress];
    }

    function getTotalRefGains(address userAddress) public view returns (uint256) {
        return totalRefGains[userAddress];
    }

    function stringToBytes32(string memory str) public pure returns (bytes32 result) {
        require(bytes(str).length <= 32, "Refcode string is too long");
        assembly {
            result := mload(add(str, 32))
        }
    }

    function distributeDepositFees(string memory refcode, uint256 etherFee) private {
        bool isAbleForRefReward;
        uint256 serviceShare = etherFee;
        uint256 discountShare = etherFee * 20 / 100;
        uint256 refShare = etherFee * 30 / 100;
        address payable inviter = payable(whosReferred[msg.sender]);
        address payable pendingInvite = payable(getRefAddressByRefCode(refcode));
        if (inviter != address(0) && inviter != msg.sender) isAbleForRefReward = true;
        if (inviter == address(0) && pendingInvite != address(0)) {
            totalRefs[inviter]++;
            whosReferred[msg.sender] = pendingInvite;
            inviter = pendingInvite;
            isAbleForRefReward = true;
        }
        if (isAbleForRefReward) {
            inviter.transfer(refShare);
            payable(msg.sender).transfer(discountShare);
            totalRefGains[inviter] += refShare;
            serviceShare = etherFee * 50 / 100;
        }
        unclaimedRevenue += serviceShare;
        emit Revenues(inviter, isAbleForRefReward ? refShare : 0, serviceShare);
    }

    function distributeWithdrawalFees(uint32 _id, uint256 etherFee) private {
        bool isAbleForRefReward;
        uint256 serviceShare = etherFee;
        uint256 refShare = msg.value * 30 / 100;
        address payable inviter = payable(whosReferred[holdings[_id].user]);
        if (inviter != address(0)) {
            isAbleForRefReward = true;
            inviter.transfer(refShare);
            serviceShare -= etherFee * 30 / 100;
            totalRefGains[inviter] += refShare;
        }
        unclaimedRevenue += serviceShare;
        emit Revenues(inviter, isAbleForRefReward ? refShare : 0, serviceShare);
    }

    // Service

    function setFees(uint8 newDepositFee, uint8 newWithdrawalFee) public {
        require(msg.sender == owner);
        require(newDepositFee < 5 && newWithdrawalFee < 5, "Max possible fee is 5%");
        depositFee = newDepositFee;
        withdrawalFee = newWithdrawalFee;
    }

    function changeOwner(address newOwner) public {
        require(msg.sender == owner);
        owner = newOwner;
    }

    function withdrawCollectedFees(uint256 amount) public {
        require(msg.sender == owner);
        require(amount <= unclaimedRevenue, "Desired amount is more than unclaimed revenue");
        unclaimedRevenue -= amount;
        payable(owner).transfer(amount);
    }
}