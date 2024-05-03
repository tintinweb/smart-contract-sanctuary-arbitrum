// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import "./Address.sol";
import "./Context.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./SafeERC20.sol";

contract Proxy {
    // masterCopy always needs to be first declared variable, to ensure that it is at the same location in the contracts to which calls are delegated.
    // To reduce deployment costs this variable is internal and needs to be retrieved via `getStorageAt`

    constructor(address _masterCopy) {
        require(_masterCopy != address(0), "Invalid master copy address provided");
        bytes32 slot = _IMPLEMENTATION_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, _masterCopy)
        }
    }

    bytes32 private constant _IMPLEMENTATION_SLOT = 0x6b75c6e3b92dbabf77414617df2d64d6a835b7a3fb3409b21218efb3ac232a7f;

    receive() external payable {}
    /// @dev Fallback function forwards all transactions and returns all received return data.
    fallback() external payable {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let _masterCopy := and(sload(slot), 0xffffffffffffffffffffffffffffffffffffffff)
            // 0xa619486e == keccak("masterCopy()"). The value is right padded to 32-bytes with 0s
            if eq(calldataload(0), 0xa619486e00000000000000000000000000000000000000000000000000000000) {
                mstore(0, _masterCopy)
                return(0, 0x20)
            }
            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(gas(), _masterCopy, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if eq(success, 0) {
                revert(0, returndatasize())
            }
            return(0, returndatasize())
        }
    }
}

interface ILaunchpad {
    function initOwner() external;
    function initializePresale(address, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external;
    function initializeLock(uint256, uint256, uint256, uint256, uint256, address, address, address, address) external;
    function endInit() external;
    function transferOwnership(address) external;
    function updateInfo(string[] memory) external;
    function enableWhiteList(uint256) external;

    function presaleType() external view returns(string memory);
    function logoUrl() external view returns(string memory);
    function token() external view returns(address);
    function buyToken() external view returns(address);
    function total() external view returns(uint256);
    function rate() external view returns(uint256);
    function softCap() external view returns(uint256);
    function hardCap() external view returns(uint256);
    function maxBuy() external view returns(uint256);
    function whiteListEnableTime() external view returns(uint256);
    function totalDepositedBalance() external view returns(uint256);
    function liquidity() external view returns(uint256);
    function lockPeriod() external view returns(uint256);
    function presaleStartTimestamp() external view returns(uint256);
    function presaleEndTimestamp() external view returns(uint256);
    function refundable() external view returns(bool);
    function claimable() external view returns(bool);
    function whitelist() external view returns(string memory);

}

interface IFairLaunch {
    function initOwner() external;
    function initializePresale(address, address, uint256, uint256, uint256, uint256, uint256) external;
    function initializeLock(uint256, uint256, uint256, uint256, address, address, address) external;
    function endInit() external;
    function transferOwnership(address) external;
    function updateInfo(string[] memory) external;
    function enableWhiteList(uint256) external;
}

contract Manager is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant FEE_PERCENT_DIVIDOR = 1000;
    uint256 public constant VESTING_PERCENT_DIVIDOR = 10000;
    uint256 public DEFAULT_MAIN_FEE_OPTION_1 = 50;
    uint256 public DEFAULT_TOKEN_FEE_OPTION_1 = 0;
    uint256 public DEFAULT_MAIN_FEE_OPTION_2 = 20;
    uint256 public DEFAULT_TOKEN_FEE_OPTION_2 = 20;

    address payable public feeAddress;
    uint256 public serviceFee = 1 ether;
    mapping(address => bool) public routers;
    address public presale;
    address public fairPresale;
    address public locker;

    struct Contribution {
        address addr;
        address owner;
        address token;
        uint256 createTime;
        bool isLaunchpad;
    }

    struct LaunchpadInfo {
        string presaleType;
        address addr;
        string logoUrl;
        address token;
        address buyToken;
        uint256 total;
        uint256 rate;
        uint256 softCap;
        uint256 hardCap;
        uint256 maxBuy;
        uint256 amount;
        uint256 liquidity;
        uint256 lockTime;
        uint256 startTime;
        uint256 endTime;
        string whitelist;
        uint256 whiteListEnableTime;
        bool refundable;
        bool claimable;
    }

    Contribution[] public contributions;
    mapping(address => Contribution[]) public userContributions;

    event NewLaunchpadCreated(address indexed user, address indexed launchpad);

    constructor(
        address payable _feeAddress,
        address _presale,
        address _fairPresale,
        address _locker
    ) {
        feeAddress = _feeAddress;
        presale = _presale;
        fairPresale = _fairPresale;
        locker = _locker;
    }

    // _values[0] = startTime,
    // _values[1] = endTime,
    // _values[2] = softCap,
    // _values[3] = hardCap,
    // _values[4] = minBuy,
    // _values[5] = maxBuy,
    // _values[6] = rate,
    // _values[7] = listingRate,
    // _values[8] = liquidity,
    // _values[9] = lockPeriod,
    // _values[10] = mainFee,
    // _values[11] = tokenFee,
    // _addresses[0] = token,
    // _addresses[1] = buyToken,
    // _addresses[2] = router,
    // _addresses[3] = backAddress,
    // _strings[0] = _info,
    // _strings[1] = _logoUrl,
    // _strings[2] = _website,
    // _strings[3] = _facebook,
    // _strings[4] = _twitter,
    // _strings[5] = _github,
    // _strings[6] = _telegram,
    // _strings[7] = _instagram,
    // _strings[8] = _discord,
    // _strings[9] = _reddit,
    // _strings[10] = _youtube,
    // _strings[11] = _whitelist
    // _options[0] = whitelistOption
    // _options[1] = feeOption
    // _options[2] = listingOption

    function createNewLaunchpad(uint256[] memory _values, address[] memory _addresses, string[] memory _strings, bool[] memory _options) public payable returns(address){
        require(msg.value >= serviceFee, "should pay creation fee");
        Address.sendValue(feeAddress, serviceFee);
        if(msg.value > serviceFee)
            Address.sendValue(payable(msg.sender), msg.value - serviceFee);

        bytes32 salt = keccak256(abi.encodePacked(_addresses[0], msg.sender, block.timestamp));
        Proxy newContract = new Proxy{salt: salt}(presale);
        address launchpad = address(newContract);

        uint256[] memory values = _values;
        address[] memory addresses = _addresses;
        string[] memory strings = _strings;

        // check input param's validation
        require(!_options[2] || routers[addresses[2]], "router is not registered");
        require(values[0] > block.timestamp, "startTime should be after than now");
        require(values[0] < values[1], "startTime should be before than endTime");
        require(values[2] < values[3], "softcap should be less than hardcap");
        require(values[2] >= values[3] / 4, "softcap must be greater than or equal 25% of hardcap");
        require(values[4] > 0, "minBuy should be greater than 0");
        require(values[4] < values[5], "minBuy should be less than maxBuy");
        require(values[6] > 0, "presale rate can't be zero");
        require(!_options[2] || values[7] > 0, "listing rate can't be zero");
        require(!_options[2] || values[8] >= 500, "liquidity must be more than 50%");
        require(!_options[2] || values[8] <= 1000, "liquidity must be less than 100%");
        require(!_options[2] || values[9] >= 30 days, "lock time must be longer than 30 days");

        uint256 tokenAmount = values[3].mul(values[6]).mul(FEE_PERCENT_DIVIDOR + values[11]).div(FEE_PERCENT_DIVIDOR) + values[3].mul(values[7]).mul(FEE_PERCENT_DIVIDOR - values[10]).div(FEE_PERCENT_DIVIDOR).mul(values[8]).div(FEE_PERCENT_DIVIDOR);
        
        uint256 beforeBalance = IERC20(addresses[0]).balanceOf(launchpad);
        uint256 decimals = 18;
        if (addresses[1] != address(0)) {
            decimals = IERC20Metadata(addresses[1]).decimals();
        }
        IERC20(addresses[0]).safeTransferFrom(msg.sender, launchpad, tokenAmount.div(10**decimals));
        require(IERC20(addresses[0]).balanceOf(launchpad) - beforeBalance >= tokenAmount.div(10**decimals), "invalid token transfer");

        ILaunchpad(launchpad).initOwner();
        ILaunchpad(launchpad).initializePresale(addresses[0], addresses[1], values[0], values[1], values[2], values[3], values[4], values[5], values[6]);
        ILaunchpad(launchpad).initializeLock(values[7], values[9], values[10], values[11], values[8], addresses[2], locker, feeAddress, addresses[3]);
        ILaunchpad(launchpad).updateInfo(strings);
        // if whitelist option enabled
        if(_options[0])
            ILaunchpad(launchpad).enableWhiteList(values[1]);
        // if fee option is mainfee = 5 and tokenfee = 0
        if(_options[1])
            require(values[10] == DEFAULT_MAIN_FEE_OPTION_1 && values[11] == DEFAULT_TOKEN_FEE_OPTION_1, "invalid fee value");
        else
            require(values[10] == DEFAULT_MAIN_FEE_OPTION_2 && values[11] == DEFAULT_TOKEN_FEE_OPTION_2, "invalid fee values");

        ILaunchpad(launchpad).endInit();

        ILaunchpad(launchpad).transferOwnership(msg.sender);
        contributions.push(Contribution({
            addr: launchpad,
            owner: msg.sender,
            token: addresses[0],
            createTime: block.timestamp,
            isLaunchpad: true
        }));
        userContributions[msg.sender].push(Contribution({
            addr: launchpad,
            owner: msg.sender,
            token: addresses[0],
            createTime: block.timestamp,
            isLaunchpad: true
        }));

        emit NewLaunchpadCreated(msg.sender, launchpad);

        return launchpad;
    }

    // _values[0] = startTime,
    // _values[1] = endTime,
    // _values[2] = softCap,
    // _values[3] = total,
    // _values[4] = liquidity,
    // _values[5] = lockPeriod,
    // _values[6] = mainFee,
    // _values[7] = tokenFee,
    // _values[8] = maxBuy,
    // _addresses[0] = token,
    // _addresses[1] = buyToken,
    // _addresses[2] = router,
    // _strings[0] = _info,
    // _strings[1] = _logoUrl,
    // _strings[2] = _website,
    // _strings[3] = _facebook,
    // _strings[4] = _twitter,
    // _strings[5] = _github,
    // _strings[6] = _telegram,
    // _strings[7] = _instagram,
    // _strings[8] = _discord,
    // _strings[9] = _reddit,
    // _strings[10] = _youtube,
    // _strings[11] = _whitelist,
    // _options[0] = feeOption
    // _options[2] = whitelistOption

    function createNewFairLaunch(uint256[] memory _values, address[] memory _addresses, string[] memory _strings, bool[] memory options) public payable returns(address){
        require(msg.value >= serviceFee, "should pay creation fee");
        Address.sendValue(feeAddress, serviceFee);
        if(msg.value > serviceFee)
            Address.sendValue(payable(msg.sender), msg.value - serviceFee);

        bytes32 salt = keccak256(abi.encodePacked(_addresses[0], msg.sender, block.timestamp));
        Proxy newContract = new Proxy{salt: salt}(fairPresale);
        address launchpad = address(newContract);
        
        uint256[] memory values = _values;
        address[] memory addresses = _addresses;

        require(routers[addresses[2]], "router is not registered");
        require(values[0] > block.timestamp, "startTime should be after than now");
        require(values[0] + 7 days > values[1], "The duration between startTime and endTime must be less than 7 days");
        require(values[0] < values[1], "startTime should be before than endTime");
        require(values[3] > 0, "total can't be zero");
        require(values[4] >= 500, "liquidity must be more than 50%");
        require(values[4] <= 1000, "liquidity must be less than 100%");
        require(values[5] >= 30 days, "lock time must be longer than 30 days");

        IFairLaunch(launchpad).initOwner();
        IFairLaunch(launchpad).initializePresale(addresses[0], addresses[1], values[0], values[1], values[2], values[3], values[8]);
        IFairLaunch(launchpad).initializeLock(values[5], values[6], values[7], values[4], addresses[2], locker, feeAddress);
        IFairLaunch(launchpad).updateInfo(_strings);
        // if fee option is mainfee = 5 and tokenfee = 0
        if(options[0])
            require(values[6] == DEFAULT_MAIN_FEE_OPTION_1 && values[7] == DEFAULT_TOKEN_FEE_OPTION_1, "invalid fee value"); 
        else
            require(values[6] == DEFAULT_MAIN_FEE_OPTION_2 && values[7] == DEFAULT_TOKEN_FEE_OPTION_2, "invalid fee values");

        // if whitelist option enabled
        if(options[1])
            ILaunchpad(launchpad).enableWhiteList(values[1]);

        uint256 tokenAmount = values[3] + values[3].mul((FEE_PERCENT_DIVIDOR - values[6]).mul(values[4]) + values[7].mul(FEE_PERCENT_DIVIDOR)).div(FEE_PERCENT_DIVIDOR * FEE_PERCENT_DIVIDOR);
        
        uint256 beforeBalance = IERC20(addresses[0]).balanceOf(launchpad);
        IERC20(addresses[0]).safeTransferFrom(msg.sender, launchpad, tokenAmount);
        require(IERC20(addresses[0]).balanceOf(launchpad) - beforeBalance >= tokenAmount, "invalid token transfer");

        IFairLaunch(launchpad).endInit();

        IFairLaunch(launchpad).transferOwnership(msg.sender); 
        contributions.push(Contribution({
            addr: launchpad,
            owner: msg.sender,
            token: _addresses[0],
            createTime: block.timestamp,
            isLaunchpad: false
        }));
        userContributions[msg.sender].push(Contribution({
            addr: launchpad,
            owner: msg.sender,
            token: _addresses[0],
            createTime: block.timestamp,
            isLaunchpad: false
        }));

        emit NewLaunchpadCreated(msg.sender, launchpad);

        return launchpad;
    }

    function setPresaleAddress(address _presale) public onlyOwner {
        require(_presale != address(0), "cannot be zero address");
        presale = _presale;
    }

    function setFairPresaleAddress(address _fairPresale) public onlyOwner {
        require(_fairPresale != address(0), "cannot be zero address");
        fairPresale = _fairPresale;
    }

    function setLockerAddress(address _addr) public onlyOwner {
        locker = _addr;
    }

    function setFeeAddress(address payable _addr) public onlyOwner {
        feeAddress = _addr;
    }

    function setServiceFee(uint256 _fee) public onlyOwner {
        serviceFee = _fee;
    }

    function updateConfig(uint256 mainFee_1, uint256 mainFee_2, uint256 tokenFee_1, uint256 tokenFee_2) public onlyOwner {
        DEFAULT_MAIN_FEE_OPTION_1 = mainFee_1;
        DEFAULT_TOKEN_FEE_OPTION_1 = tokenFee_1;
        DEFAULT_MAIN_FEE_OPTION_2 = mainFee_2;
        DEFAULT_TOKEN_FEE_OPTION_2 = tokenFee_2;
    }

    function setRouterAddress(address _addr, bool _en) public onlyOwner {
        routers[_addr] = _en;
    }

    function getUserContributionsLength(address user) external view returns (uint256) {
        return userContributions[user].length;
    }

    function getLaunchpads(uint256 size, uint256 cursor) public view returns(LaunchpadInfo[] memory) {
        uint256 length = size;

        if (length > contributions.length - cursor) {
            length = contributions.length - cursor;
        }

        LaunchpadInfo[] memory launchpads = new LaunchpadInfo[](length);

        for (uint256 i = 0; i < length; i++) {
            launchpads[i].presaleType = ILaunchpad(contributions[cursor + i].addr).presaleType();
            launchpads[i].addr = contributions[cursor + i].addr;
            launchpads[i].logoUrl = ILaunchpad(contributions[cursor + i].addr).logoUrl();
            launchpads[i].token = ILaunchpad(contributions[cursor + i].addr).token();
            launchpads[i].buyToken = ILaunchpad(contributions[cursor + i].addr).buyToken();
            launchpads[i].total = ILaunchpad(contributions[cursor + i].addr).total();
            launchpads[i].rate = ILaunchpad(contributions[cursor + i].addr).rate();
            launchpads[i].hardCap = ILaunchpad(contributions[cursor + i].addr).hardCap();
            launchpads[i].softCap = ILaunchpad(contributions[cursor + i].addr).softCap();
            launchpads[i].maxBuy = ILaunchpad(contributions[cursor + i].addr).maxBuy();
            launchpads[i].amount = ILaunchpad(contributions[cursor + i].addr).totalDepositedBalance();
            launchpads[i].liquidity = ILaunchpad(contributions[cursor + i].addr).liquidity();
            launchpads[i].lockTime = ILaunchpad(contributions[cursor + i].addr).lockPeriod();
            launchpads[i].startTime = ILaunchpad(contributions[cursor + i].addr).presaleStartTimestamp();
            launchpads[i].endTime = ILaunchpad(contributions[cursor + i].addr).presaleEndTimestamp();
            launchpads[i].refundable = ILaunchpad(contributions[cursor + i].addr).refundable();
            launchpads[i].claimable = ILaunchpad(contributions[cursor + i].addr).claimable();
            launchpads[i].whiteListEnableTime = ILaunchpad(contributions[cursor + i].addr).whiteListEnableTime();
            launchpads[i].whitelist = ILaunchpad(contributions[cursor + i].addr).whitelist();
        }

        return launchpads;
    }

    function getContributionsLength() external view returns (uint256) {
        return contributions.length;
    }

}