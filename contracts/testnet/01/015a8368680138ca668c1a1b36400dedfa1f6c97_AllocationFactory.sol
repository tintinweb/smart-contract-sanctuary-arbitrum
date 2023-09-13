// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./MGH_Token.sol";
import "./MGH_Vesting.sol";
import "./MGH_CrowdSale.sol";

contract AllocationFactory is Ownable  {
    MGHToken public token;
    Vesting public mghVesting;
    CrowdSale public mghCrowdSale;
    constructor(uint _startCliff, address[] memory _addressList, uint[] memory _amountList, Vesting.AddressType[] memory _addressTypeList, address _usdcToken, address _chainlinkPriceFeed, address _chainlinkUptimeFeed){        
        require(_startCliff > block.timestamp, "AllocationFactory/constructor: startCliff must be greater than block.timestamp");
        require(
            _addressList.length > 0 
            && _addressList.length == _amountList.length 
            && _amountList.length == _addressTypeList.length, 
            "AllocationFactory/constructor: Invalid add user parameters"
        );
        token = new MGHToken();
        mghVesting = new Vesting(_startCliff, address(token), _addressList, _amountList, _addressTypeList);
        mghCrowdSale = new CrowdSale(10, address(token), _usdcToken, _chainlinkPriceFeed, _chainlinkUptimeFeed);

        uint256 vestingAmount = token.balanceOf(address(this)) * 15/100;
        token.transfer(address(mghVesting), vestingAmount);
        mghVesting.transferOwnership(msg.sender);

        uint256 crowdSaleAmount = token.balanceOf(address(this)) * 30/100;
        token.transfer(address(mghCrowdSale), crowdSaleAmount);
        mghCrowdSale.transferOwnership(msg.sender);

        token.transfer(msg.sender, token.balanceOf(address(this)));
        token.transferOwnership(msg.sender);

        emit DeployedVesting(address(mghVesting));
        emit DeployedToken(address(token));
        emit DeployedVesting(address(mghCrowdSale));
    }

    event DeployedVesting(address vestingAddress);
    event DeployedToken(address tokenAddress);
    event DeployedCrowdSale(address crowdSaleAddress);
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error ManagerOnly(address sender, address manager);
error ZeroAddress();

contract MGHToken is ERC20, Ownable {
    event MinterUpdated(address indexed minter);

    uint256 public constant oneYear = 1 days * 365;
    uint256 public constant tenYearSupplyCap = 10_000_000_000e18;
    uint256 public constant maxMintCapFraction = 2;
    uint256 public immutable timeLaunch;

    address public minter;

    constructor() ERC20("MGH Token", "MGH", 18) {
        minter = msg.sender;
        timeLaunch = block.timestamp;
    }

    function changeMinter(address newMinter) external onlyOwner {
        require(newMinter != address(0), "Zero address");
        minter = newMinter;
        emit MinterUpdated(newMinter);
    }

    function mint(address account, uint256 amount) external {
        require(msg.sender == minter, "ManagerOnly");
        require(inflationControl(amount), "Inflation control failed");
        _mint(account, amount);
    }

    function inflationControl(uint256 amount) public view returns (bool) {
        uint256 remainder = inflationRemainder();
        return (amount <= remainder);
    }

    function inflationRemainder() public view returns (uint256 remainder) {
        uint256 _totalSupply = totalSupply;
        uint256 numYears = (block.timestamp - timeLaunch) / oneYear;
        uint256 supplyCap = tenYearSupplyCap;

        if (numYears > 9) {
            numYears -= 9;
            for (uint256 i = 0; i < numYears; ++i) {
                supplyCap += (supplyCap * maxMintCapFraction) / 100;
            }
        }
        remainder = supplyCap - _totalSupply;
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function decreaseAllowance(address spender, uint256 amount) external returns (bool) {
        uint256 spenderAllowance = allowance[msg.sender][spender];

        if (spenderAllowance != type(uint256).max) {
            spenderAllowance -= amount;
            allowance[msg.sender][spender] = spenderAllowance;
            emit Approval(msg.sender, spender, spenderAllowance);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 amount) external returns (bool) {
        uint256 spenderAllowance = allowance[msg.sender][spender];

        spenderAllowance += amount;
        allowance[msg.sender][spender] = spenderAllowance;
        emit Approval(msg.sender, spender, spenderAllowance);

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Vesting is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    IERC20 public MGHToken;

    uint constant DAY = 1 days;
    uint constant MONTH = DAY * 30;
    
    uint public DEV_DURATION_VESTING_MONTH = 36;
    uint public INVESTOR_DURATION_VESTING_MONTH = 24;

    uint public durationCliff = 12 * MONTH;
    uint public cliffEnd;

    uint public totalVesting;

    struct UserVestingInfo {
        uint amount;
        uint claimed;
        AddressType addressType;
        bool isActive;
    }

    enum AddressType {
        DEVELOPER,
        INVESTOR
    }

    mapping(address => UserVestingInfo) public userVestingInfo;

    event AddUser(address indexed account, uint amount, AddressType indexed addressType);
    event Claim(address indexed account, uint amount);
    event RemoveUser(address indexed account);

    constructor (uint _startCliff, address _mghToken, address[] memory _addressList, uint[] memory _amountList, AddressType[] memory _addressTypeList) {
        require(_startCliff > block.timestamp, "Vesting/constructor: startCliff must be greater than block.timestamp");
        require(_mghToken != address(0), "Vesting/constructor: MGH token address must not be zero address");
        require(
            _addressList.length > 0 
            && _addressList.length == _amountList.length 
            && _amountList.length == _addressTypeList.length, 
            "Vesting: Invalid add user parameters"
        );

        cliffEnd = _startCliff + durationCliff;
        MGHToken = IERC20(_mghToken);

        for (uint i = 0; i < _addressList.length; i++) {
            _addUser(_addressList[i], _amountList[i], _addressTypeList[i]);
            totalVesting = totalVesting.add(_amountList[i]);
        }
    }

    modifier onlyActiveUser (address _address) {
        require(userVestingInfo[_address].isActive, "Vesting: User is not active");
        _;
    }

    modifier isPassedCliff() {
        require(block.timestamp >= cliffEnd, "Vesting: Cliff is not passed");
        _;
    }

    modifier mustNotCliffStart() {
        require(block.timestamp < cliffEnd - durationCliff, "Vesting: Cliff happened");
        _;
    }

    function removeUser(address _address) external onlyOwner onlyActiveUser(_address) {
    UserVestingInfo storage user = userVestingInfo[_address];
    uint remainingAmount = user.amount.sub(user.claimed);
    if (remainingAmount > 0) {
        MGHToken.safeTransfer(owner(), remainingAmount);
        totalVesting = totalVesting.sub(remainingAmount);
    }

    user.isActive = false;
    user.amount = 0;

    emit RemoveUser(_address);
}

    function claim() external isPassedCliff onlyActiveUser(_msgSender()){
        UserVestingInfo storage userInfo = userVestingInfo[_msgSender()];
        uint claimableAmount = _getVestingClaimableAmount(_msgSender());
        require(userInfo.claimed + claimableAmount <= userInfo.amount, "Vesting: Insufficient amount");
        userInfo.claimed += claimableAmount;
        totalVesting -= claimableAmount;
        MGHToken.safeTransfer(_msgSender(), claimableAmount);
        emit Claim(_msgSender(), claimableAmount);
    }

    function _getVestingClaimableAmount(address _address) internal view returns(uint) {
        UserVestingInfo memory userInfo = userVestingInfo[_address];
                uint timePassed = block.timestamp.sub(cliffEnd);
                uint claimedTime = timePassed / MONTH;
                uint amountToClaim;
        if(userInfo.addressType == AddressType.DEVELOPER){
            uint amountPerClaim = userInfo.amount / DEV_DURATION_VESTING_MONTH;
            amountToClaim =  claimedTime >= DEV_DURATION_VESTING_MONTH 
            ? userInfo.amount - userInfo.claimed 
            : _calcClaimableAmount(claimedTime, amountPerClaim, userInfo.claimed);
        }else{
            uint amountPerClaim = userInfo.amount / INVESTOR_DURATION_VESTING_MONTH;
            amountToClaim = claimedTime >= INVESTOR_DURATION_VESTING_MONTH 
            ? amountToClaim = userInfo.amount - userInfo.claimed 
            : _calcClaimableAmount(claimedTime, amountPerClaim, userInfo.claimed);
        }
        require(amountToClaim > 0, "Vesting: No tokens to claim");
        return amountToClaim;
    }

    function setDurationVesting(AddressType typeDuration, uint _durationMonth) external onlyOwner mustNotCliffStart {
        require(typeDuration == AddressType.DEVELOPER || typeDuration == AddressType.INVESTOR, "Vesting: Invalid type duration");
        require(_durationMonth > 0, "Vesting: Duration must greater than zero");
        if(typeDuration == AddressType.DEVELOPER){
            DEV_DURATION_VESTING_MONTH = _durationMonth;
        } 
        if(typeDuration == AddressType.INVESTOR){
            INVESTOR_DURATION_VESTING_MONTH = _durationMonth;
        }
    }

    function setDurationCliffMonths(uint _months) external onlyOwner mustNotCliffStart {
        require(_months > 0, "Vesting: Duration must greater than zero");
        uint startCliff = cliffEnd - durationCliff;
        durationCliff = _months.mul(MONTH);
        cliffEnd = startCliff.add(durationCliff);
    }

    function setStartCliff(uint _startCliff) external onlyOwner mustNotCliffStart {
        require(_startCliff > block.timestamp, "Vesting: Start must greater than block timestamp.");
        cliffEnd = _startCliff + durationCliff;
    }

    function _calcClaimableAmount(uint _claimTime, uint _amountPerClaim, uint _claimedAmount ) internal pure returns(uint) {
        uint claimableAmount = _claimTime.mul(_amountPerClaim);
        uint amountToClaim;
        if(claimableAmount > _claimedAmount){
            amountToClaim = claimableAmount - _claimedAmount;
        }
        return amountToClaim;
    }

    function _addUser(address _address, uint _amount, AddressType _type) internal {
        require(_address != address(0), "Vesting: Invalid address");
        require(userVestingInfo[_address].isActive == false, "Vesting: Address already exists");
        require(_amount >= 1000, "Vesting: Amount must be greater or equal 1000 wei");

        userVestingInfo[_address] = UserVestingInfo({
            amount: _amount,
            claimed: 0,
            addressType: _type,
            isActive: true
        });

        emit AddUser(_address, _amount, _type);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";


//Arbitrum L2 SequencerUptimeFeed mainnet: 0xFdB631F5EE196F0ed6FAa767959853A9F217697D
//Arbitrum L2 SequencerUptimeFeed Goerli testnet: 0x4da69F028a5790fCCAfe81a75C0D24f46ceCDd69
//Arbitrum L2 DatafeedPrice mainnet: 0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3
//Arbitrum L2 DatafeedPrice Goerli testnet: 0x1692Bdd32F31b831caAc1b0c9fAF68613682813b
// USDC 0xF0b6417C3d9539e716fc3247d1CD847D96b3C318
// MGH 0x60c0E9Efa828664072E97131C03c688cE61F86CA
// Cap 3000000000000000000000000000
contract CrowdSale is Ownable {
    using SafeMath for uint256;
    // Chainlink datafeed state
    AggregatorV2V3Interface internal chainlinkDataFeed;
    AggregatorV2V3Interface internal chainlinkSequencerUptimeFeed;
    uint256 private constant GRACE_PERIOD_TIME = 3600;

    uint tokenDecimal = 18;
    // Token sale parameters
    uint256 public mghPrice = 25*10**tokenDecimal/10**4; // 0.0025 USDC = 1 MGH tokens
    uint256 public cap;
    uint256 public mghSold;
    uint256 public totalUsdc;
    IERC20 public mghToken;
    IERC20 public usdcToken;
    bool public isSaleOpen = false;

    // events
    event Withdraw(address owner, uint mghAmount, uint usdcAmount);
    event Buy(address indexed buyer, uint usdcAmount, uint mghAmount);

    // modifier
    modifier onlySaleOpen() {
        require(isSaleOpen, "MGHCrowdSale: Sales is not opened");
        _;
    }

    modifier onlySaleClose() {
        require(!isSaleOpen, "MGHCrowdSale: Sales is not closed");
        _;
    }

    // Error 
    error SequencerDown();
    error GracePeriodNotOver();
    constructor(uint256 _cap, address _mghToken, address _usdcToken, address _chainlinkPriceFeed, address _chainlinkUptimeFeed) {
        require(_mghToken != address(0), "CrowdSale/constructor: MGH token address is not valid");
        require(_usdcToken != address(0), "CrowdSale/constructor: USDC token address is not valid");
        require(_chainlinkPriceFeed != address(0), "CrowdSale/constructor: Chainlink PriceFeed address is not valid");
        require(_chainlinkUptimeFeed != address(0), "CrowdSale/constructor: Chainlink UptimeFeed address is not valid");
        require(_cap > 0, "CrowdSale/constructor: Cap is greater than zero");
        cap = _cap;
        usdcToken = IERC20(_usdcToken);
        mghToken = IERC20(_mghToken);
        chainlinkDataFeed = AggregatorV2V3Interface(_chainlinkPriceFeed);
        chainlinkSequencerUptimeFeed = AggregatorV2V3Interface(_chainlinkUptimeFeed);
    }

    // Buy function
    function buy(uint _amout) external onlySaleOpen {
        require(_amout > 0, "CrowdSale: amount must be greater than zero.");
        uint mghAmount = calcTokenAmount(_amout);
        require(mghToken.balanceOf(address(this)) >= mghAmount, "CrowdSale: amount must be greater than");
        usdcToken.transferFrom(_msgSender(), address(this), _amout);
        totalUsdc = totalUsdc.add(_amout);
        mghToken.transfer(_msgSender(), mghAmount);
        mghSold = mghSold.add(mghAmount);
        emit Buy(_msgSender(), _amout, mghAmount);
    }



    // Withdraw function
    function withdraw() external onlyOwner onlySaleClose {
        uint remainMGH = mghToken.balanceOf(address(this));
        uint usdcAmount = usdcToken.balanceOf(address(this));

        if(remainMGH > 0){
            mghToken.transfer(_msgSender(), remainMGH);
        }
        usdcToken.transfer(_msgSender(), usdcAmount);
        emit Withdraw(_msgSender(), remainMGH, usdcAmount);
    }

    function calcTokenAmount(uint _amountUsdc) internal view returns(uint) {
        // usdc decimal is 6 => convert to decimal 18
        uint convertedAmount = _amountUsdc * 10**tokenDecimal / 10**6;
        uint usdcPrice = getLatestPrice();
        uint mghAmount = convertedAmount * usdcPrice / mghPrice;
        return mghAmount;
    } 

    function setIsSaleOpen(bool _isOpen) external onlyOwner {
        isSaleOpen = _isOpen;
    }

    function getLatestPrice() public view returns (uint) {
        uint dataDecimal = uint(chainlinkDataFeed.decimals());
        (,int256 answer,uint256 startedAt,,) = chainlinkSequencerUptimeFeed.latestRoundData();
        // Answer == 0: Sequencer is up
        // Answer == 1: Sequencer is down
        bool isSequencerUp = answer == 0;
        if (!isSequencerUp) {
            revert SequencerDown();
        }

        // Make sure the grace period has passed after the
        // sequencer is back up.
        uint256 timeSinceUp = block.timestamp - startedAt;
        if (timeSinceUp <= GRACE_PERIOD_TIME) {
            revert GracePeriodNotOver();
        }
        (,int data,,,) = chainlinkDataFeed.latestRoundData();
        
        return uint(data) * 10**tokenDecimal / 10**dataDecimal; // converted to demimal 18
    }

    function getBalanceOfAddresses(address _address) external view returns (uint256) {
        return mghToken.balanceOf(_address);
    }

    function getMghBalance() external view returns (uint256) {
        return mghToken.balanceOf(address(this));
    }

    // Fallback function
    fallback() external {
        revert("CrowdSale: contract does not accept Ether");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface
{
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer()
    external
    view
    returns (
      int256
    );
  
  function latestTimestamp()
    external
    view
    returns (
      uint256
    );

  function latestRound()
    external
    view
    returns (
      uint256
    );

  function getAnswer(
    uint256 roundId
  )
    external
    view
    returns (
      int256
    );

  function getTimestamp(
    uint256 roundId
  )
    external
    view
    returns (
      uint256
    );

  event AnswerUpdated(
    int256 indexed current,
    uint256 indexed roundId,
    uint256 updatedAt
  );

  event NewRound(
    uint256 indexed roundId,
    address indexed startedBy,
    uint256 startedAt
  );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}