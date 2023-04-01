/**
 *Submitted for verification at Arbiscan on 2023-03-29
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface NFTContract {
    function minter() external view returns (address);

    function mint(
        address _to,
        IERC20 stakeToken,
        IERC20 rewardToken,
        uint256 poolIndex
    ) external returns (uint256 tokenId);

    function burn(address _from, uint256 _tokenId) external;

    function getTokenIdsOfOwner(IERC20 stakeToken, IERC20 rewardToken, uint256 poolIndex, address _owner) external view returns (uint256[] memory);

    function ownerOf(uint256 _tokenId) external view returns (address);
}

interface FeeExemptionNFT {
    function balanceOf(address _owner) external view returns (uint256);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library StringTools {
    function toString(uint value) internal pure returns (string memory) {
        if (value == 0) {return "0";}

        uint temp = value;
        uint digits;

        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }

        return string(buffer);
    }

    function toString(bool value) internal pure returns (string memory) {
        if (value) {
            return "True";
        } else {
            return "False";
        }
    }

    function toString(address addr) internal pure returns (string memory) {
        bytes memory addressBytes = abi.encodePacked(addr);
        bytes memory stringBytes = new bytes(42);

        stringBytes[0] = '0';
        stringBytes[1] = 'x';

        for (uint i = 0; i < 20; i++) {
            uint8 leftValue = uint8(addressBytes[i]) / 16;
            uint8 rightValue = uint8(addressBytes[i]) - 16 * leftValue;

            bytes1 leftChar = leftValue < 10 ? bytes1(leftValue + 48) : bytes1(leftValue + 87);
            bytes1 rightChar = rightValue < 10 ? bytes1(rightValue + 48) : bytes1(rightValue + 87);

            stringBytes[2 * i + 3] = rightChar;
            stringBytes[2 * i + 2] = leftChar;
        }

        return string(stringBytes);
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(account)}
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success,) = recipient.call{value : amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value : weiValue}(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract StakingContract is Ownable {
    using StringTools for *;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct PoolIdentifier {
        IERC20 stakeToken;
        IERC20 rewardToken;
        uint256 poolIndex;
    }

    struct TokenInfo {
        uint256 amount;                             // How many stakeToken are associated with the NFT.
        uint256 withdrawnRewards;
        uint256 subtractableReward;
        uint256 initialDepositBlock;
        uint256 lastDepositBlock;
    }

    struct BasicPoolInfo {
        bool doesExists;
        bool hasEnded;
        IERC20 stakeToken;
        IERC20 rewardToken;
        address poolCreator;
        uint256 createBlock;                        // Block number when the pool was created
        uint256 startBlock;                         // Block number when reward distribution start
        uint256 rewardPerBlock;
        uint256 gasAmount;                          // Eth fee charged on deposits and withdrawals
        uint256 minStake;                           // Min. tokens that need to be staked
        uint256 maxStake;                           // Max. tokens that can be staked
        uint256 stakeTokenDepositFee;               // Fee (divide by 1000, so that 100 => 0.1%)
        uint256 stakeTokenWithdrawFee;              // Fee (divide by 1000, so that 100 => 0.1%)
        uint256 lockPeriod;                         // No. of blocks for which the stake tokens are locked
    }

    struct DetailedPoolInfo {
        uint256 tokensStaked;                       // Total tokens staked with the pool
        uint256 accRewardPerTokenStaked;            // (Accumulated reward per token staked) * (1e36).
        uint256 paidOut;                            // Total rewards distributed by pool
        uint256 lastRewardBlock;                    // Last block number when the accRewardPerTokenStaked was updated
        uint256 endBlock;                           // Block number when reward distribution ends
        uint256 maxStakers;
        uint256 totalStakers;
        mapping(uint256 => TokenInfo) tokenInfo;    // Info of each token that stakes with the pool
    }

    bool public hasSetNFTContract = false;
    NFTContract public nftContract = NFTContract(address(0));
    FeeExemptionNFT public feeExemptionNFT = FeeExemptionNFT(address(0));

    IERC20 public accessToken = IERC20(address(0));
    uint256 public minAccessTokenRequired = 0;
    bool public requireAccessToken = false;

    uint256 public gasAmount = 0.005 ether;
    uint256 public defaultDepositFee = 0;
    uint256 public defaultWithdrawFee = 20;
    address payable public treasury;
    mapping(IERC20 => uint256) public withdrawableFee;

    uint256 public currentPoolToBeUpdated = 0;
    uint256 public massUpdatePoolCount = 25;
    uint256 public staleBlockDuration = 1000;
    PoolIdentifier[] public activePools;
    PoolIdentifier[] public endedPools;
    mapping(IERC20 => mapping(IERC20 => mapping(uint256 => uint256))) public indicesOfActivePools;
    mapping(IERC20 => mapping(IERC20 => mapping(uint256 => uint256))) public indicesOfEndedPools;

    // Stake Token => (Reward Token => (Pool Id => BasicPoolInfo))
    mapping(IERC20 => mapping(IERC20 => uint256)) public latestPoolNumber;
    mapping(IERC20 => mapping(IERC20 => mapping(uint256 => BasicPoolInfo))) public allPoolsBasicInfo;
    mapping(IERC20 => mapping(IERC20 => mapping(uint256 => DetailedPoolInfo))) public allPoolsDetailedInfo;

    event Deposit(uint256 indexed token, IERC20 indexed stakeToken, IERC20 indexed rewardToken, uint256 poolIndex, uint256 amount);
    event Withdraw(uint256 indexed token, IERC20 indexed stakeToken, IERC20 indexed rewardToken, uint256 poolIndex, uint256 amount);
    event ReceivedReward(address indexed receiver, IERC20 indexed stakeToken, IERC20 indexed rewardToken, uint256 poolIndex, uint256 amount);
    event EmergencyWithdraw(uint256 indexed token, IERC20 indexed stakeToken, IERC20 indexed rewardToken, uint256 poolIndex, uint256 amount);

    constructor() {
        treasury = payable(msg.sender);

        activePools.push(PoolIdentifier({
            stakeToken : IERC20(address(0)),
            rewardToken : IERC20(address(0)),
            poolIndex : 0
        }));

        endedPools.push(PoolIdentifier({
            stakeToken : IERC20(address(0)),
            rewardToken : IERC20(address(0)),
            poolIndex : 0
        }));
    }

    function setNFTContract(FeeExemptionNFT _feeExemptionNFT, NFTContract _nftContract) external onlyOwner() {
        require(!hasSetNFTContract, "NFT Contract has already been set.");
        require(_nftContract != nftContract, "NFT Contract Address should be a new value");
        require(_feeExemptionNFT != feeExemptionNFT, "Fee exemption NFT Contract Address should be a new value");
        require(address(_feeExemptionNFT) != address(_nftContract), "Both NFTs cannot be same");
        require(_nftContract.minter() == address(this), "Invalid Minter.");

        nftContract = _nftContract;
        feeExemptionNFT = _feeExemptionNFT;
        hasSetNFTContract = true;
    }

    function currentBlock() external view returns (uint256) {
        return block.number;
    }

    function getActivePoolCount() external view returns (uint256) {
        return activePools.length - 1;
    }

    function getEndedPoolCount() external view returns (uint256) {
        return endedPools.length - 1;
    }

    // View function to see LP amount staked by a NFT.
    function getNFTStakedAmount(IERC20 _stakeToken, IERC20 _rewardToken, uint256 poolIndex, uint256 _token) external view returns (uint256) {
        DetailedPoolInfo storage detailedPoolInfo = allPoolsDetailedInfo[_stakeToken][_rewardToken][poolIndex];
        return detailedPoolInfo.tokenInfo[_token].amount;
    }

    function getNFTInfo(IERC20 _stakeToken, IERC20 _rewardToken, uint256 poolIndex, uint256 _token) external view returns (TokenInfo memory) {
        return allPoolsDetailedInfo[_stakeToken][_rewardToken][poolIndex].tokenInfo[_token];
    }

    // View function to see pending rewards of a token.
    function getPendingRewardsOfNFT(IERC20 _stakeToken, IERC20 _rewardToken, uint256 poolIndex, uint256 _token) public view returns (uint256) {
        BasicPoolInfo storage basicPoolInfo = allPoolsBasicInfo[_stakeToken][_rewardToken][poolIndex];
        DetailedPoolInfo storage detailedPoolInfo = allPoolsDetailedInfo[_stakeToken][_rewardToken][poolIndex];
        TokenInfo storage token = detailedPoolInfo.tokenInfo[_token];

        uint256 accRewardPerTokenStaked = detailedPoolInfo.accRewardPerTokenStaked;
        uint256 tokensStaked = detailedPoolInfo.tokensStaked;

        if (block.number > detailedPoolInfo.lastRewardBlock && tokensStaked != 0) {
            uint256 lastBlock = (block.number < detailedPoolInfo.endBlock) ? block.number : detailedPoolInfo.endBlock;
            uint256 noOfBlocks = lastBlock.sub(detailedPoolInfo.lastRewardBlock);
            uint256 newRewards = noOfBlocks.mul(basicPoolInfo.rewardPerBlock);
            accRewardPerTokenStaked = accRewardPerTokenStaked.add(newRewards.mul(1e36).div(tokensStaked));
        }

        return token.amount.mul(accRewardPerTokenStaked).div(1e36).sub(token.subtractableReward);
    }

    // View function for total reward the farm has yet to pay out.
    function getPendingRewardsOfPool(IERC20 _stakeToken, IERC20 _rewardToken, uint256 poolIndex) external view returns (uint256) {
        BasicPoolInfo storage basicPoolInfo = allPoolsBasicInfo[_stakeToken][_rewardToken][poolIndex];
        DetailedPoolInfo storage detailedPoolInfo = allPoolsDetailedInfo[_stakeToken][_rewardToken][poolIndex];
        if (block.number <= basicPoolInfo.startBlock) {
            return 0;
        }

        uint256 elapsedBlockCount = (block.number < detailedPoolInfo.endBlock) ? block.number : detailedPoolInfo.endBlock;
        elapsedBlockCount = elapsedBlockCount.sub(basicPoolInfo.startBlock);

        return (basicPoolInfo.rewardPerBlock.mul(elapsedBlockCount)).sub(detailedPoolInfo.paidOut);
    }

    function getNFTAttributes(
        IERC20 _stakeToken,
        IERC20 _rewardToken,
        uint256 poolIndex,
        uint256 tokenId
    ) external view returns (
        string memory stakedAmount,
        string memory stakeShare,
        string memory availableRewards,
        string memory withdrawnRewards
    ) {
        BasicPoolInfo storage basicPoolInfo = allPoolsBasicInfo[_stakeToken][_rewardToken][poolIndex];
        DetailedPoolInfo storage detailedPoolInfo = allPoolsDetailedInfo[_stakeToken][_rewardToken][poolIndex];
        TokenInfo storage token = detailedPoolInfo.tokenInfo[tokenId];
        require(basicPoolInfo.doesExists, "getNFTAttributes: No such pool exists!");

        uint256 stakeTokenDecimals = basicPoolInfo.stakeToken.decimals();
        uint256 rewardTokenDecimals = basicPoolInfo.rewardToken.decimals();

        stakedAmount = getDecimalString(token.amount, stakeTokenDecimals);
        stakeShare = string(abi.encodePacked(
                getDecimalString((token.amount * 10000).div(detailedPoolInfo.tokensStaked), 2),
                "%"
            )
        );
        availableRewards = getDecimalString(getPendingRewardsOfNFT(_stakeToken, _rewardToken, poolIndex, tokenId), rewardTokenDecimals);
        withdrawnRewards = getDecimalString(token.withdrawnRewards, rewardTokenDecimals);
    }

    function finishActivePool(IERC20 _stakeToken, IERC20 _rewardToken, uint256 poolIndex) internal {
        uint256 activePoolIndex = indicesOfActivePools[_stakeToken][_rewardToken][poolIndex];
        if (activePoolIndex < 1) {
            return;
        }

        indicesOfEndedPools[_stakeToken][_rewardToken][poolIndex] = endedPools.length;
        endedPools.push(activePools[activePoolIndex]);

        uint256 lastPoolIndex = activePools.length - 1;

        PoolIdentifier memory poolIdentifier = activePools[lastPoolIndex];
        activePools[activePoolIndex] = activePools[lastPoolIndex];
        indicesOfActivePools[poolIdentifier.stakeToken][poolIdentifier.rewardToken][poolIdentifier.poolIndex] = activePoolIndex;

        indicesOfActivePools[_stakeToken][_rewardToken][poolIndex] = 0;
        activePools.pop();

        latestPoolNumber[_stakeToken][_rewardToken] += 1;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // rewards are calculated per pool, so you can add the same stakeToken multiple times
    function createNewStakingPool(
        IERC20 _stakeToken,
        IERC20 _rewardToken,
        address _poolCreator,
        uint256 _rewardPerBlock,
        uint256 _minStake,
        uint256 _maxStake,
        uint256 _maxStakers
    ) public onlyOwner returns (uint256) {
        require(hasSetNFTContract, "NFT Contract not set yet.");

        if (latestPoolNumber[_stakeToken][_rewardToken] < 1) {
            latestPoolNumber[_stakeToken][_rewardToken] = 1;
        }

        uint256 poolIndex = latestPoolNumber[_stakeToken][_rewardToken];

        updatePoolStatus(_stakeToken, _rewardToken, poolIndex);
        poolIndex = latestPoolNumber[_stakeToken][_rewardToken];

        BasicPoolInfo storage basicPoolInfo = allPoolsBasicInfo[_stakeToken][_rewardToken][poolIndex];
        DetailedPoolInfo storage detailedPoolInfo = allPoolsDetailedInfo[_stakeToken][_rewardToken][poolIndex];

        require(!basicPoolInfo.doesExists, "Pool already exists.");

        basicPoolInfo.doesExists = true;
        basicPoolInfo.stakeToken = _stakeToken;
        basicPoolInfo.rewardToken = _rewardToken;
        basicPoolInfo.poolCreator = _poolCreator;
        basicPoolInfo.createBlock = block.number;
        basicPoolInfo.rewardPerBlock = _rewardPerBlock;
        basicPoolInfo.gasAmount = gasAmount;
        basicPoolInfo.minStake = _minStake;
        basicPoolInfo.maxStake = (_maxStake <= 0) ? ~uint256(0) : _maxStake;
        basicPoolInfo.stakeTokenDepositFee = defaultDepositFee;
        basicPoolInfo.stakeTokenWithdrawFee = defaultWithdrawFee;
        detailedPoolInfo.maxStakers = (_maxStakers <= 0) ? ~uint256(0) : _maxStakers;

        indicesOfActivePools[_stakeToken][_rewardToken][poolIndex] = activePools.length;
        activePools.push(PoolIdentifier(_stakeToken, _rewardToken, poolIndex));

        return poolIndex;
    }

    // Fund the pool, consequently setting the end block
    function performInitialFunding(IERC20 _stakeToken, IERC20 _rewardToken, uint256 _amount, uint256 _startBlock, uint256 _lockBlocks) public {
        uint256 poolIndex = latestPoolNumber[_stakeToken][_rewardToken];
        BasicPoolInfo storage basicPoolInfo = allPoolsBasicInfo[_stakeToken][_rewardToken][poolIndex];
        DetailedPoolInfo storage detailedPoolInfo = allPoolsDetailedInfo[_stakeToken][_rewardToken][poolIndex];

        require(basicPoolInfo.doesExists, "performInitialFunding: No such pool exists.");
        require(basicPoolInfo.startBlock == 0, "performInitialFunding: Initial funding already complete");
        require(msg.sender == basicPoolInfo.poolCreator, "performInitialFunding: Pool can only be funded by the pool creator");

        // If pool has passed max fund time, it will be ended before funding can be done.
        // Otherwise, nothing will happen based on how the updatePoolStatus function is designed.
        updatePoolStatus(_stakeToken, _rewardToken, poolIndex);
        if (basicPoolInfo.hasEnded) {
            return;
        }

        // This check ensures that caller does not set start block to be too high w.r.t. current block.
        require(_startBlock <= block.number.add(staleBlockDuration), "performInitialFunding: Start Block cannot be more than staleBlockDuration from current block.");

        IERC20 erc20 = basicPoolInfo.rewardToken;

        uint256 startTokenBalance = erc20.balanceOf(address(this));
        erc20.safeTransferFrom(address(msg.sender), address(this), _amount);
        uint256 endTokenBalance = erc20.balanceOf(address(this));
        uint256 trueDepositedTokens = endTokenBalance.sub(startTokenBalance);

        _startBlock = (_startBlock < block.number) ? block.number : _startBlock;

        detailedPoolInfo.lastRewardBlock = _startBlock;
        basicPoolInfo.startBlock = _startBlock;
        detailedPoolInfo.endBlock = _startBlock.add(trueDepositedTokens.div(basicPoolInfo.rewardPerBlock));

        require(_lockBlocks <= detailedPoolInfo.endBlock.sub(_startBlock), "Lock duration cannot be more than initial running duration of the pool.");
        basicPoolInfo.lockPeriod = _lockBlocks;
    }

    // Increase the funds the pool, consequently increasing the end block
    function increasePoolFunding(IERC20 _stakeToken, IERC20 _rewardToken, uint256 _amount) public {
        uint256 poolIndex = latestPoolNumber[_stakeToken][_rewardToken];
        BasicPoolInfo storage basicPoolInfo = allPoolsBasicInfo[_stakeToken][_rewardToken][poolIndex];
        DetailedPoolInfo storage detailedPoolInfo = allPoolsDetailedInfo[_stakeToken][_rewardToken][poolIndex];

        updatePoolStatus(_stakeToken, _rewardToken, poolIndex);

        require(basicPoolInfo.doesExists, "increasePoolFunding: No such pool exists.");
        require(block.number < detailedPoolInfo.endBlock, "increasePoolFunding: Pool closed or perform initial funding first");

        uint256 startTokenBalance = _rewardToken.balanceOf(address(this));
        _rewardToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        uint256 endTokenBalance = _rewardToken.balanceOf(address(this));
        uint256 trueDepositedTokens = endTokenBalance.sub(startTokenBalance);

        detailedPoolInfo.endBlock += trueDepositedTokens.div(basicPoolInfo.rewardPerBlock);
    }

    function getStakingNFTOfUser(address _owner, IERC20 _stakeToken, IERC20 _rewardToken, uint256 poolIndex) internal returns (uint256) {
        uint256[] memory tokenIds = nftContract.getTokenIdsOfOwner(_stakeToken, _rewardToken, latestPoolNumber[_stakeToken][_rewardToken], _owner);
        return (tokenIds.length > 0) ? tokenIds[0] : nftContract.mint(_owner, _stakeToken, _rewardToken, poolIndex);
    }

    function getDecimalString(uint256 value, uint256 decimals) internal pure returns (string memory) {
        uint256 divisor = 10 ** decimals;
        uint256 quotient = value / divisor;
        uint256 remainder = value.mod(divisor).mul(100).div(divisor);
        return string(abi.encodePacked(
                quotient.toString(),
                ".",
                ((remainder < 10) ? "0" : ""),
                remainder.toString()
            )
        );
    }

    // Deposit staking tokens to pool.
    function stakeWithPool(IERC20 _stakeToken, IERC20 _rewardToken, uint256 _amount) external payable returns (uint256 tokenId) {
        uint256 poolIndex = latestPoolNumber[_stakeToken][_rewardToken];
        BasicPoolInfo storage basicPoolInfo = allPoolsBasicInfo[_stakeToken][_rewardToken][poolIndex];
        DetailedPoolInfo storage detailedPoolInfo = allPoolsDetailedInfo[_stakeToken][_rewardToken][poolIndex];

        require(basicPoolInfo.doesExists, "stakeWithPool: No such pool exists.");
        updatePoolStatus(_stakeToken, _rewardToken, poolIndex);

        if (basicPoolInfo.hasEnded) {
            return 0;
        }
        require(basicPoolInfo.startBlock > 0, "stakeWithPool: Pool has not been funded yet.");
        require(block.number >= basicPoolInfo.startBlock, "stakeWithPool: Pool reward distribution has not been started yet.");
        require(detailedPoolInfo.totalStakers < detailedPoolInfo.maxStakers, "Max stakers reached!");
        require(msg.value >= basicPoolInfo.gasAmount, "Insufficient Value for the trx.");

        tokenId = getStakingNFTOfUser(msg.sender, _stakeToken, _rewardToken, poolIndex);
        TokenInfo storage token = detailedPoolInfo.tokenInfo[tokenId];
        require((_amount.add(token.amount) >= basicPoolInfo.minStake) && (_amount.add(token.amount) <= basicPoolInfo.maxStake), "Stake amount out of range.");

        if (requireAccessToken) {
            require(accessToken.balanceOf(msg.sender) >= minAccessTokenRequired, "Insufficient access token held by staker");
        }

        if (token.amount > 0) {
            uint256 pendingAmount = getPendingRewardsOfNFT(_stakeToken, _rewardToken, poolIndex, tokenId);
            if (pendingAmount > 0) {
                erc20RewardTransfer(msg.sender, _stakeToken, _rewardToken, poolIndex, pendingAmount);
                token.withdrawnRewards += pendingAmount;
            }
        }

        uint256 startTokenBalance = basicPoolInfo.stakeToken.balanceOf(address(this));
        basicPoolInfo.stakeToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        uint256 endTokenBalance = basicPoolInfo.stakeToken.balanceOf(address(this));
        uint256 trueDepositedTokens = endTokenBalance.sub(startTokenBalance);

        if (feeExemptionNFT.balanceOf(msg.sender) < 1) {
            uint256 depositFee = basicPoolInfo.stakeTokenDepositFee.mul(trueDepositedTokens).div(1000);
            withdrawableFee[_stakeToken] += depositFee;
            trueDepositedTokens = trueDepositedTokens.sub(depositFee);
        }

        token.amount = token.amount.add(trueDepositedTokens);
        detailedPoolInfo.tokensStaked = detailedPoolInfo.tokensStaked.add(trueDepositedTokens);
        token.subtractableReward = token.amount.mul(detailedPoolInfo.accRewardPerTokenStaked).div(1e36);

        if (token.initialDepositBlock <= 0) {
            token.initialDepositBlock = block.number;
        }
        token.lastDepositBlock = block.number;

        detailedPoolInfo.totalStakers = detailedPoolInfo.totalStakers.add(1);

        emit Deposit(tokenId, _stakeToken, _rewardToken, poolIndex, _amount);
    }

    // Withdraw staking tokens from pool.
    function unstakeFromPool(IERC20 _stakeToken, IERC20 _rewardToken, uint256 poolIndex, uint256 _amount) public payable returns (uint256) {
        uint256[] memory tokenIds = nftContract.getTokenIdsOfOwner(_stakeToken, _rewardToken, poolIndex, msg.sender);
        require(tokenIds.length > 0, "No Staking Positions NFT held by the caller.");
        unstakeFromPool(_stakeToken, _rewardToken, poolIndex, _amount, tokenIds[0]);
        return tokenIds[0];
    }

    function unstakeFromPool(IERC20 _stakeToken, IERC20 _rewardToken, uint256 poolIndex, uint256 _amount, uint256 tokenId) public payable {
        BasicPoolInfo storage basicPoolInfo = allPoolsBasicInfo[_stakeToken][_rewardToken][poolIndex];
        DetailedPoolInfo storage detailedPoolInfo = allPoolsDetailedInfo[_stakeToken][_rewardToken][poolIndex];

        require(nftContract.ownerOf(tokenId) == msg.sender, "Sender not owner of the NFT.");
        TokenInfo storage token = detailedPoolInfo.tokenInfo[tokenId];

        require(basicPoolInfo.doesExists, "unstakeFromPool: No such pool exists.");
        require(token.amount >= _amount, "unstakeFromPool: Can't withdraw more than deposited amount.");
        require(token.initialDepositBlock.add(basicPoolInfo.lockPeriod) <= block.number, "unstakeFromPool: Lock period not fulfilled");

        updatePoolStatus(_stakeToken, _rewardToken, poolIndex);

        uint256 pendingAmount = getPendingRewardsOfNFT(_stakeToken, _rewardToken, poolIndex, tokenId);
        if (pendingAmount > 0) {
            erc20RewardTransfer(msg.sender, _stakeToken, _rewardToken, poolIndex, pendingAmount);
            token.withdrawnRewards += pendingAmount;
        }

        if (_amount > 0) {
            require(msg.value >= basicPoolInfo.gasAmount, "unstakeFromPool: Correct transaction value must be sent.");

            uint256 withdrawFee = 0;
            if (feeExemptionNFT.balanceOf(msg.sender) < 1) {
                withdrawFee = basicPoolInfo.stakeTokenWithdrawFee.mul(_amount).div(1000);
                withdrawableFee[_stakeToken] = withdrawableFee[_stakeToken].add(withdrawFee);
            }

            basicPoolInfo.stakeToken.safeTransfer(address(msg.sender), _amount.sub(withdrawFee));
            detailedPoolInfo.tokensStaked = detailedPoolInfo.tokensStaked.sub(_amount);
            token.amount = token.amount.sub(_amount);

            if (token.amount <= 0) {
                detailedPoolInfo.totalStakers = detailedPoolInfo.totalStakers.sub(1);
                nftContract.burn(msg.sender, tokenId);
            }

            emit Withdraw(tokenId, _stakeToken, _rewardToken, poolIndex, _amount);
        }

        token.subtractableReward = token.amount.mul(detailedPoolInfo.accRewardPerTokenStaked).div(1e36);
    }

    // Withdraw without caring about rewards and lock period. EMERGENCY ONLY.
    function emergencyWithdraw(IERC20 _stakeToken, IERC20 _rewardToken, uint256 poolIndex) public {
        uint256[] memory tokenIds = nftContract.getTokenIdsOfOwner(_stakeToken, _rewardToken, poolIndex, msg.sender);
        require(tokenIds.length > 0, "No Staking Positions NFT held by the caller.");
        emergencyWithdraw(_stakeToken, _rewardToken, poolIndex, tokenIds[0]);
    }

    function emergencyWithdraw(IERC20 _stakeToken, IERC20 _rewardToken, uint256 poolIndex, uint256 tokenId) public {
        BasicPoolInfo storage basicPoolInfo = allPoolsBasicInfo[_stakeToken][_rewardToken][poolIndex];
        DetailedPoolInfo storage detailedPoolInfo = allPoolsDetailedInfo[_stakeToken][_rewardToken][poolIndex];

        require(nftContract.ownerOf(tokenId) == msg.sender, "Sender not owner of the NFT.");
        TokenInfo storage token = detailedPoolInfo.tokenInfo[tokenId];

        if (token.amount > 0) {
            basicPoolInfo.stakeToken.safeTransfer(address(msg.sender), token.amount);
            detailedPoolInfo.tokensStaked = detailedPoolInfo.tokensStaked.sub(token.amount);
            token.amount = 0;
            token.subtractableReward = 0;
            detailedPoolInfo.totalStakers = detailedPoolInfo.totalStakers.sub(1);

            nftContract.burn(msg.sender, tokenId);

            emit EmergencyWithdraw(tokenId, _stakeToken, _rewardToken, poolIndex, token.amount);
        }
    }

    // Transfer reward and update the paid out reward
    function erc20RewardTransfer(address _to, IERC20 _stakeToken, IERC20 _rewardToken, uint256 poolIndex, uint256 _amount) internal {
        BasicPoolInfo storage basicPoolInfo = allPoolsBasicInfo[_stakeToken][_rewardToken][poolIndex];
        DetailedPoolInfo storage detailedPoolInfo = allPoolsDetailedInfo[_stakeToken][_rewardToken][poolIndex];
        IERC20 erc20 = basicPoolInfo.rewardToken;

        try erc20.transfer(_to, _amount) {
            detailedPoolInfo.paidOut = detailedPoolInfo.paidOut.add(_amount);
            emit ReceivedReward(_to, _stakeToken, _rewardToken, poolIndex, _amount);
        } catch {}
    }

    // Updates status of the given pool.
    function updatePoolStatus(IERC20 _stakeToken, IERC20 _rewardToken, uint256 poolIndex) public {
        BasicPoolInfo storage basicPoolInfo = allPoolsBasicInfo[_stakeToken][_rewardToken][poolIndex];
        DetailedPoolInfo storage detailedPoolInfo = allPoolsDetailedInfo[_stakeToken][_rewardToken][poolIndex];

        if (basicPoolInfo.doesExists && ((basicPoolInfo.startBlock > 0) || (basicPoolInfo.createBlock < block.number.sub(staleBlockDuration)))) {
            uint256 lastRewardBlock;

            if (block.number < detailedPoolInfo.endBlock) {
                lastRewardBlock = block.number;
            } else {
                lastRewardBlock = detailedPoolInfo.endBlock;
                if (!basicPoolInfo.hasEnded) {
                    basicPoolInfo.hasEnded = true;
                    finishActivePool(_stakeToken, _rewardToken, poolIndex);
                }
            }

            if (lastRewardBlock > detailedPoolInfo.lastRewardBlock) {
                if (detailedPoolInfo.tokensStaked > 0) {
                    uint256 noOfBlocks = lastRewardBlock.sub(detailedPoolInfo.lastRewardBlock);
                    uint256 newRewards = noOfBlocks.mul(basicPoolInfo.rewardPerBlock);

                    detailedPoolInfo.accRewardPerTokenStaked = detailedPoolInfo.accRewardPerTokenStaked.add(newRewards.mul(1e36).div(detailedPoolInfo.tokensStaked));
                }

                detailedPoolInfo.lastRewardBlock = lastRewardBlock;
            }
        }
    }

    function massUpdatePoolStatus() public {
        uint256 rotateCount = 0;
        for (uint256 i = 0; i < massUpdatePoolCount; i++) {
            if (activePools.length < 2 || rotateCount >= 2) {
                return;
            }

            if (currentPoolToBeUpdated < 1 || currentPoolToBeUpdated >= activePools.length) {
                rotateCount += 1;
                currentPoolToBeUpdated = 1;
            }

            updatePoolStatus(
                activePools[currentPoolToBeUpdated].stakeToken,
                activePools[currentPoolToBeUpdated].rewardToken,
                activePools[currentPoolToBeUpdated].poolIndex
            );

            currentPoolToBeUpdated += 1;
        }
    }

    // Change no. of tokens that can stake with in a pool
    function changePoolMaxStakers(IERC20 _stakeToken, IERC20 _rewardToken, uint256 _maxStakers) public onlyOwner {
        uint256 poolIndex = latestPoolNumber[_stakeToken][_rewardToken];
        BasicPoolInfo storage basicPoolInfo = allPoolsBasicInfo[_stakeToken][_rewardToken][poolIndex];
        DetailedPoolInfo storage detailedPoolInfo = allPoolsDetailedInfo[_stakeToken][_rewardToken][poolIndex];

        require(basicPoolInfo.doesExists, "No such pool exists.");

        detailedPoolInfo.maxStakers = (_maxStakers < detailedPoolInfo.totalStakers) ? detailedPoolInfo.totalStakers : _maxStakers;
    }

    // Change deposit fee
    function changeDepositFee(IERC20 _stakeToken, IERC20 _rewardToken, uint256 fee) public onlyOwner {
        uint256 poolIndex = latestPoolNumber[_stakeToken][_rewardToken];
        BasicPoolInfo storage basicPoolInfo = allPoolsBasicInfo[_stakeToken][_rewardToken][poolIndex];

        require(basicPoolInfo.doesExists, "No such pool exists.");
        require(fee >= 0 && fee <= 20, "Invalid Fee Value");

        basicPoolInfo.stakeTokenDepositFee = fee;
    }

    function setDefaultDepositFee(uint256 fee) public onlyOwner {
        require(fee >= 0 && fee <= 20, "Invalid Fee Value");
        defaultDepositFee = fee;
    }

    // Change withdraw fee
    function changeWithdrawFee(IERC20 _stakeToken, IERC20 _rewardToken, uint256 fee) public onlyOwner {
        uint256 poolIndex = latestPoolNumber[_stakeToken][_rewardToken];
        BasicPoolInfo storage basicPoolInfo = allPoolsBasicInfo[_stakeToken][_rewardToken][poolIndex];

        require(basicPoolInfo.doesExists, "No such pool exists.");
        require(fee >= 0 && fee <= 20, "Invalid Fee Value");

        basicPoolInfo.stakeTokenWithdrawFee = fee;
    }

    function setDefaultWithdrawFee(uint256 fee) public onlyOwner {
        require(fee >= 0 && fee <= 20, "Invalid Fee Value");
        defaultWithdrawFee = fee;
    }

    // Adjusts Gas Fee
    function adjustGasGlobal(uint256 newGas) public onlyOwner {
        gasAmount = newGas;
    }

    function adjustPoolGas(IERC20 _stakeToken, IERC20 _rewardToken, uint256 newGas) public onlyOwner {
        uint256 poolIndex = latestPoolNumber[_stakeToken][_rewardToken];
        BasicPoolInfo storage basicPoolInfo = allPoolsBasicInfo[_stakeToken][_rewardToken][poolIndex];

        require(basicPoolInfo.doesExists, "No such pool exists.");

        basicPoolInfo.gasAmount = newGas;
    }

    // Treasury Management
    function changeTreasury(address payable newTreasury) public onlyOwner {
        treasury = newTreasury;
    }

    function transfer() public onlyOwner returns (bool success) {
        (success,) = treasury.call{value : address(this).balance}("");
    }

    function withdrawFees(IERC20 withdrawToken, address _to, uint256 _amount) external onlyOwner {
        require(withdrawableFee[withdrawToken] >= _amount, "Withdraw amount exceeds generated fee amount");

        if (_amount > 0) {
            withdrawToken.transfer(_to, _amount);
            withdrawableFee[withdrawToken] = withdrawableFee[withdrawToken].sub(_amount);
        }
    }

    function scrapeFees(uint256 startIndex, uint256 endIndex) external {
        uint256 len = endedPools.length;
        endIndex = (endIndex >= len) ? len - 1 : endIndex;

        for (uint256 i = ((startIndex < 1) ? 1 : startIndex); i <= endIndex && i < len; i++) {
            if (i < 1) {
                // Implies uint256 overflow
                break;
            }

            PoolIdentifier storage poolIdentifier = endedPools[i];
            BasicPoolInfo storage basicPoolInfo = allPoolsBasicInfo[poolIdentifier.stakeToken][poolIdentifier.rewardToken][poolIdentifier.poolIndex];
            DetailedPoolInfo storage detailedPoolInfo = allPoolsDetailedInfo[poolIdentifier.stakeToken][poolIdentifier.rewardToken][poolIdentifier.poolIndex];

            if (detailedPoolInfo.tokensStaked <= 0) {
                // Implies everyone has withdrawn their stake tokens, or no tokens were staked.

                uint256 maxRewardsDeposited = detailedPoolInfo.endBlock.sub(basicPoolInfo.startBlock).mul(basicPoolInfo.rewardPerBlock);
                uint256 scrapableFees = maxRewardsDeposited.sub(detailedPoolInfo.paidOut);

                if (scrapableFees > 0) {
                    detailedPoolInfo.paidOut = maxRewardsDeposited;
                    withdrawableFee[poolIdentifier.rewardToken] = withdrawableFee[poolIdentifier.rewardToken].add(scrapableFees);
                }
            }
        }
    }

    // Handling Access Token
    function setAccessToken(IERC20 _accessToken) public onlyOwner {
        require(address(_accessToken) != address(0), "Access Token cannot be zero address");
        accessToken = _accessToken;
    }

    function setRequireAccessToken(bool required) public onlyOwner {
        if (required) {
            require(address(accessToken) != address(0), "Cannot set to true while access token is zero address");
        }

        requireAccessToken = required;
    }

    function setMinAccessTokenRequired(uint256 _minAccessTokenRequired) public onlyOwner {
        minAccessTokenRequired = _minAccessTokenRequired;
    }

    // Handling mass update
    function setMassUpdatePoolCount(uint256 count) external onlyOwner {
        massUpdatePoolCount = count;
    }

    function setStaleBlockDuration(uint256 blockCount) external onlyOwner {
        require(blockCount > 0, "Block count has to be greater than 0");
        staleBlockDuration = blockCount;
    }
}