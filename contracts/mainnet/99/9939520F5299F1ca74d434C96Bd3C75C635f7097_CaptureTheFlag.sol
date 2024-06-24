/**
 *Submitted for verification at Arbiscan.io on 2024-06-24
*/

/**
 *Submitted for verification at Arbiscan.io on 2024-06-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);


    event Approval(address indexed owner, address indexed spender, uint256 value);


    function totalSupply() external view returns (uint256);


    function balanceOf(address account) external view returns (uint256);


    function transfer(address to, uint256 amount) external returns (bool);


    function allowance(address owner, address spender) external view returns (uint256);


    function approve(address spender, uint256 amount) external returns (bool);


    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

abstract contract ReentrancyGuard {
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = NOT_ENTERED;
    }

    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    error OwnableUnauthorizedAccount(address account);
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract CaptureTheFlag is Ownable(msg.sender), ReentrancyGuard {
    IERC20 public token;
    address public currentFlagHolder;
    address[] public flagHolders;
    mapping(address => uint256) public flagCaptureTimes;
    uint256 public capturePrice;
    uint256 public lastCaptureTimestamp;

    address constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    event FlagCaptured(address indexed player, uint256 captureTime);

    constructor(IERC20 _token, uint256 _prize) {
        token = _token;
        currentFlagHolder = address(0);
        lastCaptureTimestamp = block.timestamp;
        capturePrice = _prize;
    }

    function captureFlag() external nonReentrant {
        require(currentFlagHolder != msg.sender, "You already hold the flag");
        require(token.transferFrom(msg.sender, BURN_ADDRESS, capturePrice), "Transfer failed");

        if (currentFlagHolder != address(0)) {
            flagCaptureTimes[currentFlagHolder] += block.timestamp - lastCaptureTimestamp;
        }

        currentFlagHolder = msg.sender;
        lastCaptureTimestamp = block.timestamp;

        if (flagCaptureTimes[currentFlagHolder] == 0) {
            flagHolders.push(currentFlagHolder);
        }

        emit FlagCaptured(currentFlagHolder, lastCaptureTimestamp);
    }

    function getTime(address _player) external view returns (uint256) {
        if (_player == currentFlagHolder) {
            return block.timestamp - lastCaptureTimestamp + flagCaptureTimes[_player];
        } else {
            return flagCaptureTimes[_player];
        }
    }

    function getPlayers(uint256 _index) external view returns (address) {
        return flagHolders[_index];
    }

    function getPlayersLength() external view returns (uint256) {
        return flagHolders.length;
    }

    function setPrize(uint256 _newPrize) external onlyOwner {
        capturePrice = _newPrize;
    }

    function deleteData() external onlyOwner {
        currentFlagHolder = address(0);
        lastCaptureTimestamp = block.timestamp;

        for (uint256 i = 0; i <= flagHolders.length - 1; i++) {
            flagCaptureTimes[flagHolders[i]] = 0;
        }

        delete flagHolders;
    }

    function getTop10Holders() external view returns (address[] memory, uint256[] memory) {
    uint256 length = flagHolders.length;
    address[] memory topHolders = new address[](length);
    uint256[] memory topTimes = new uint256[](length);

    for (uint256 i = 0; i < length; i++) {
        address holder = flagHolders[i];
        uint256 time = flagCaptureTimes[holder];
        if (holder == currentFlagHolder) {
            time += block.timestamp - lastCaptureTimestamp;
        }
        topHolders[i] = holder;
        topTimes[i] = time;
    }

    // Sort holders based on topTimes descending
    for (uint256 i = 0; i < length - 1; i++) {
        for (uint256 j = i + 1; j < length; j++) {
            if (topTimes[i] < topTimes[j]) {
                uint256 tempTime = topTimes[i];
                topTimes[i] = topTimes[j];
                topTimes[j] = tempTime;

                address tempHolder = topHolders[i];
                topHolders[i] = topHolders[j];
                topHolders[j] = tempHolder;
            }
        }
    }

    // Prepare result arrays for top 10 holders and times
    uint256 resultLength = length < 10 ? length : 10;
    address[] memory resultHolders = new address[](resultLength);
    uint256[] memory resultTimes = new uint256[](resultLength);

    // Copy top 10 holders and times to result arrays
    for (uint256 i = 0; i < resultLength; i++) {
        resultHolders[i] = topHolders[i];
        resultTimes[i] = topTimes[i];
    }

    return (resultHolders, resultTimes);
}
}