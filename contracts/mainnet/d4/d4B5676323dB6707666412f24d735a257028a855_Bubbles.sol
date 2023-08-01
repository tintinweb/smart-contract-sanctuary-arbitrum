// SPDX-License-Identifier: MIT

// Echoes - ERC20
// Redefining the efficiency of the Reflection token model through a dynamic framework. Experience a whole new era of Echonomics.
// Telegram: https://t.me/EchoesERC20
// Twitter: https://twitter.com/Echoes_erc
// Website: https://www.echoes-erc.com

pragma solidity ^0.8.19;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Bubbles is IERC20, Ownable {
    using SafeMath for uint256;
    /* -------------------------------------------------------------------------- */
    /*                                   events                                   */
    /* -------------------------------------------------------------------------- */
    event EventStart(string evt);
    event EventFinish(string evt, uint256 amountReflectionAccumulated);
    event ReflectAccumulated(
        uint256 amountAdded,
        uint256 totalAmountAccumulated
    );
    event ReflectDistributed(uint256 amountDistributer);
    event ReflectNotification(string message);
    event ModeChanged(string mode);
    event HolderMinimumChanged(uint256 newMinimum);
    event LogInfo(string info);
    event LogError(string error);

    /* -------------------------------------------------------------------------- */
    /*                                  constants                                 */
    /* -------------------------------------------------------------------------- */
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;

    uint256 constant MAX_FEE = 10;

    /* -------------------------------------------------------------------------- */
    /*                                   states                                   */
    /* -------------------------------------------------------------------------- */
    IUniswapV2Router02 public constant UNISWAP_V2_ROUTER =
        IUniswapV2Router02(0xcDAeC65495Fa5c0545c5a405224214e3594f30d8);
    address public immutable UNISWAP_V2_PAIR;

    struct Fee {
        uint8 reflection;
        uint8 teamOracle;
        uint8 lp;
        uint8 burn;
        uint128 total;
    }

    struct HolderInfo {
        uint256 balance;
        uint256 eventReflection;
        uint256 baseReflection;
        uint256 holdingTime;
        uint256 lastBuy;
        uint256 lastSell;
        uint256 keyIndex;
        bool isHolder;
    }

    string _name = "Bubbles";
    string _symbol = "Bubbles";

    uint256 _totalSupply = 100_000_000 ether;

    uint256 public _swapThreshold = (_totalSupply * 2) / 10000;

    uint256 public _minSupplyHolding = 300_000 ether; // ?

    mapping(address => uint256) public _balances;
    mapping(address => uint256) public _baseReflection;
    mapping(address => uint256) public _eventReflection;
    mapping(address => uint256) public _historyReflectionTransfered;
    mapping(address => uint256) public _holdingTime;
    mapping(address => uint256) public _lastBuy;
    mapping(address => uint256) public _lastSell;
    mapping(address => uint256) public _keyIndex;
    mapping(address => bool) public _isHolder;

    address[] public addressesParticipantEvent;
    address[] public holderAddresses;

    uint256 public totalReflections = 0;
    uint256 public eventReflectedToken = 0;
    uint256 public normalReflectedToken = 0;
    uint256 public totalRemainder = 0;

    string public currentTokenMode = "chill";
    string public nextTokenMode = "ngmi";
    uint256 public lastTimeMode = 0;
    uint256 public lastTimeGenesis = 0;
    string public eventNameInProgress = "";
    bool public eventInProgress = false;
    string[] public eventHistory;
    string[] public modeHistory;
    uint256 public eventTokenAmountDistributedBatching;
    uint256 public timeEventStart = 0;
    uint256 public timeEventStop = 0;
    uint256 public highestReflectionEventValue = 0;
    uint256 public highestReflectionEventTime = 0;
    string public highestReflectionEventName = "";

    mapping(address => mapping(address => uint256)) _allowances;

    bool public enableTrading = false;
    bool public enableAutoAdjust = false;
    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isReflectionExempt;

    Fee public chill =
        Fee({reflection: 2, teamOracle: 1, lp: 1, burn: 2, total: 5});

    Fee public ngmiBuy =
        Fee({reflection: 4, teamOracle: 1, lp: 0, burn: 0, total: 5});
    Fee public ngmiSell =
        Fee({reflection: 5, teamOracle: 1, lp: 0, burn: 7, total: 13});

    Fee public apeBuy =
        Fee({reflection: 0, teamOracle: 1, lp: 0, burn: 0, total: 1});
    Fee public apeSell =
        Fee({reflection: 3, teamOracle: 1, lp: 0, burn: 2, total: 6});

    Fee public buyFee;
    Fee public sellFee;

    address private teamOracleFeeReceiver;
    address private lpFeeReceiver;
    address private airDropAddress;

    address private msAddress;

    bool public claimingFees = true;
    bool inSwap;
    mapping(address => bool) public blacklists;

    /* -------------------------------------------------------------------------- */
    /*                                  modifiers                                 */
    /* -------------------------------------------------------------------------- */
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    /* -------------------------------------------------------------------------- */
    /*                                 constructor                                */
    /* -------------------------------------------------------------------------- */
    constructor() {
        // create uniswap pair
        address _uniswapPair = IUniswapV2Factory(UNISWAP_V2_ROUTER.factory())
            .createPair(address(this), UNISWAP_V2_ROUTER.WETH());
        UNISWAP_V2_PAIR = _uniswapPair;

        _allowances[address(this)][address(UNISWAP_V2_ROUTER)] = type(uint256)
            .max;
        _allowances[address(this)][msg.sender] = type(uint256).max;

        teamOracleFeeReceiver = address(
            0x24f12A42219ce3635FBEeE5CAC5902579440392f
        ); // 0x57458ac14b039cFa4F80740591A0DFe527D0260a
        lpFeeReceiver = address(0x3e98Da13E184Ea1467639bF642f804144539694D); // 0xCF035a92cB2A8e115D59D01b66FEBb6c4F35ABA9
        airDropAddress = address(0x9fb3D5758c820e17fFAb0E074fc8568eBe3518d5); // 0xD73D1BF6131f0E9b01fCd31FF0aB4F81029d026E

        isFeeExempt[msg.sender] = true;
        isFeeExempt[teamOracleFeeReceiver] = true;
        isFeeExempt[lpFeeReceiver] = true;
        isFeeExempt[airDropAddress] = true;
        isFeeExempt[ZERO] = true;
        isFeeExempt[DEAD] = true;

        isReflectionExempt[address(this)] = true;
        isReflectionExempt[address(UNISWAP_V2_ROUTER)] = true;
        isReflectionExempt[_uniswapPair] = true;
        isReflectionExempt[msg.sender] = true;
        isReflectionExempt[teamOracleFeeReceiver] = true;
        isReflectionExempt[lpFeeReceiver] = true;
        isReflectionExempt[airDropAddress] = true;
        isReflectionExempt[ZERO] = true;
        isReflectionExempt[DEAD] = true;

        buyFee = chill;
        sellFee = chill;

        uint256 distribute = (_totalSupply * 55) / 100;
        _balances[msg.sender] = distribute;
        emit Transfer(address(0), msg.sender, distribute);

        distribute = (_totalSupply * 15) / 100;
        _balances[teamOracleFeeReceiver] = distribute;
        emit Transfer(address(0), teamOracleFeeReceiver, distribute);

        distribute = (_totalSupply * 30) / 100;
        _balances[airDropAddress] = distribute;
        emit Transfer(address(0), airDropAddress, distribute);

        lastTimeMode = block.timestamp;
        emit ModeChanged(currentTokenMode);
    }

    receive() external payable {}

    /* -------------------------------------------------------------------------- */
    /*                                    ERC20                                   */
    /* -------------------------------------------------------------------------- */
    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            require(
                _allowances[sender][msg.sender] >= amount,
                "ERC20: insufficient allowance"
            );
            _allowances[sender][msg.sender] =
                _allowances[sender][msg.sender] -
                amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

    /* -------------------------------------------------------------------------- */
    /*                                    views                                   */
    /* -------------------------------------------------------------------------- */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function balanceOf(address account) public view override returns (uint256) {
        uint256 balanceNormalReflection = 0;
        if (isHolder(account)) {
            if (holderAddresses.length > 0 && normalReflectedToken > 0) {
                uint256 baseReflection = 0;
                if (_baseReflection[account] > 0) {
                    baseReflection = _baseReflection[account];
                }
                uint256 calculatePersonnalReflection = normalReflectedToken /
                    holderAddresses.length;
                if (calculatePersonnalReflection > baseReflection) {
                    balanceNormalReflection =
                        calculatePersonnalReflection -
                        baseReflection;
                }
            }
        }

        uint256 totalBalance = _balances[account];
        if (balanceNormalReflection > 0) {
            totalBalance += balanceNormalReflection;
        }
        uint256 eventBalance = _eventReflection[account];
        if (eventBalance > 0) {
            totalBalance += eventBalance;
        }

        return totalBalance;
    }

    function getHolderNormalReflection(
        address account
    ) public view returns (uint256) {
        uint256 balanceNormalReflection = 0;
        if (isHolder(account)) {
            if (holderAddresses.length > 0 && normalReflectedToken > 0) {
                uint256 baseReflection = 0;
                if (_baseReflection[account] > 0) {
                    baseReflection = _baseReflection[account];
                }
                uint256 calculatePersonnalReflection = normalReflectedToken /
                    holderAddresses.length;
                if (calculatePersonnalReflection > baseReflection) {
                    balanceNormalReflection =
                        calculatePersonnalReflection -
                        baseReflection;
                }
            }
        }
        return balanceNormalReflection;
    }

    function getHolderEventReflection(
        address account
    ) public view returns (uint256) {
        return _eventReflection[account];
    }

    function getHolderHistoryReflectionTransfered(
        address account
    ) public view returns (uint256) {
        return _historyReflectionTransfered[account];
    }

    function allowance(
        address holder,
        address spender
    ) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply - balanceOf(DEAD) - balanceOf(ZERO);
    }

    function isHolder(address holderAddress) public view returns (bool) {
        if (isReflectionExempt[holderAddress] || blacklists[holderAddress]) {
            return false;
        }
        return _balances[holderAddress] >= _minSupplyHolding;
    }

    function isHolderInArray(address holderAddress) public view returns (bool) {
        return _isHolder[holderAddress];
    }

    function addressToString(
        address _address
    ) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(_address)));
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(42);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   owners                                   */
    /* -------------------------------------------------------------------------- */

    function setMode(
        string calldata modeName,
        string calldata nextMode
    ) external {
        require(
            msg.sender == owner() || msg.sender == teamOracleFeeReceiver,
            "Forbidden"
        );

        if (compareStrings(modeName, "chill")) {
            buyFee = chill;
            sellFee = chill;
        } else if (compareStrings(modeName, "ngmi")) {
            buyFee = ngmiBuy;
            sellFee = ngmiSell;
        } else if (compareStrings(modeName, "ape")) {
            buyFee = apeBuy;
            sellFee = apeSell;
        }

        currentTokenMode = modeName;
        nextTokenMode = nextMode;

        modeHistory.push(modeName);
        if (modeHistory.length > 10) {
            delete modeHistory[0];
            for (uint i = 0; i < modeHistory.length - 1; i++) {
                modeHistory[i] = modeHistory[i + 1];
            }
            modeHistory.pop();
        }
        lastTimeMode = block.timestamp;
        emit ModeChanged(modeName);
    }

    function switchNextMode() external {
        require(
            msg.sender == owner() || msg.sender == teamOracleFeeReceiver,
            "Forbidden"
        );

        string memory modeName = nextTokenMode;
        string memory nextMode = "";
        if (compareStrings(nextTokenMode, "chill")) {
            if (compareStrings(currentTokenMode, "ngmi")) {
                nextMode = "ape";
            } else {
                nextMode = "ngmi";
            }
        } else {
            nextMode = "chill";
        }

        if (compareStrings(modeName, "chill")) {
            buyFee = chill;
            sellFee = chill;
        } else if (compareStrings(modeName, "ngmi")) {
            buyFee = ngmiBuy;
            sellFee = ngmiSell;
        } else if (compareStrings(modeName, "ape")) {
            buyFee = apeBuy;
            sellFee = apeSell;
        }

        currentTokenMode = modeName;
        nextTokenMode = nextMode;

        modeHistory.push(modeName);
        if (modeHistory.length > 10) {
            delete modeHistory[0];
            for (uint i = 0; i < modeHistory.length - 1; i++) {
                modeHistory[i] = modeHistory[i + 1];
            }
            modeHistory.pop();
        }
        lastTimeMode = block.timestamp;
        emit ModeChanged(modeName);
    }

    function getModeHistoryList() external view returns (string[] memory) {
        return modeHistory;
    }

    function getCurrentMode() external view returns (string memory) {
        return currentTokenMode;
    }

    function getNextMode() external view returns (string memory) {
        return nextTokenMode;
    }

    function getLastTimeMode() external view returns (uint256) {
        return lastTimeMode;
    }

    function getHighestReflectionEventValue() external view returns (uint256) {
        return highestReflectionEventValue;
    }

    function getHighestReflectionEventName()
        external
        view
        returns (string memory)
    {
        return highestReflectionEventName;
    }

    function getHighestReflectionEventTime() external view returns (uint256) {
        return highestReflectionEventTime;
    }

    function getHolder(
        address holderAddress
    ) external view returns (HolderInfo memory) {
        HolderInfo memory holder;
        holder.balance = _balances[holderAddress];
        holder.baseReflection = _baseReflection[holderAddress];
        holder.eventReflection = _eventReflection[holderAddress];
        holder.holdingTime = _holdingTime[holderAddress];
        holder.lastBuy = _lastBuy[holderAddress];
        holder.lastSell = _lastSell[holderAddress];
        holder.keyIndex = _keyIndex[holderAddress];
        holder.isHolder = _isHolder[holderAddress];
        return holder;
    }

    function getArrayHolder() external view returns (address[] memory) {
        return holderAddresses;
    }

    function getArrayParticipant() external view returns (address[] memory) {
        return addressesParticipantEvent;
    }

    function stopEvent() external {
        require(
            msg.sender == owner() || msg.sender == teamOracleFeeReceiver,
            "Forbidden"
        );
        require(
            eventInProgress == true,
            "There is not event started actually."
        );
        if (eventReflectedToken > highestReflectionEventValue) {
            highestReflectionEventValue = eventReflectedToken;
            highestReflectionEventTime = block.timestamp;
            highestReflectionEventName = eventNameInProgress;
        }
        emit EventFinish(eventNameInProgress, eventReflectedToken);
        eventNameInProgress = "";
        eventInProgress = false;
        eventTokenAmountDistributedBatching = 0;
        timeEventStop = block.timestamp;
    }

    function startEventName(
        string calldata eventName,
        address[] calldata selectedAddresses
    ) external {
        require(
            msg.sender == owner() || msg.sender == teamOracleFeeReceiver,
            "Forbidden"
        );
        require(
            eventInProgress == false,
            "Please finish the event before start another one."
        );
        delete addressesParticipantEvent;
        addressesParticipantEvent = selectedAddresses;
        eventNameInProgress = eventName;
        eventInProgress = true;
        eventHistory.push(eventName);
        if (eventHistory.length > 10) {
            delete eventHistory[0];
            for (uint i = 0; i < eventHistory.length - 1; i++) {
                eventHistory[i] = eventHistory[i + 1];
            }
            eventHistory.pop();
        }
        timeEventStart = block.timestamp;
        if (compareStrings(eventName, "genesis")) {
            lastTimeGenesis = block.timestamp;
        }
        emit EventStart(eventName);
    }

    function getEventHistoryList() external view returns (string[] memory) {
        return eventHistory;
    }

    function getEventTimeStart() external view returns (uint256) {
        return timeEventStart;
    }

    function getEventTimeStop() external view returns (uint256) {
        return timeEventStop;
    }

    function getLastTimeGenesis() external view returns (uint256) {
        return lastTimeGenesis;
    }

    function shouldDistributeEventReflections(
        address[] calldata batchingParticipants,
        bool isLastCall
    ) external returns (bool) {
        require(
            msg.sender == owner() || msg.sender == teamOracleFeeReceiver,
            "Forbidden"
        );
        require(
            eventInProgress == false,
            "Please finish the event before distribute."
        );

        uint256 totalParticipantsEvent = addressesParticipantEvent.length;

        if (eventReflectedToken < totalParticipantsEvent) {
            totalRemainder = totalRemainder + eventReflectedToken;
            eventReflectedToken = 0;
            emit ReflectNotification(
                "[NOT_ENOUGH_TOKENS] Not enough tokens to distribute to every participant, tokens will be send randomly in a special event."
            );
            return false;
        }

        uint256 reflectionsPerHolder = eventReflectedToken.div(
            totalParticipantsEvent
        );
        for (uint i = 0; i < batchingParticipants.length; i++) {
            address participant = batchingParticipants[i];
            if (isHolder(participant)) {
                _eventReflection[participant] = _eventReflection[participant]
                    .add(reflectionsPerHolder);
            } else {
                totalRemainder = totalRemainder + reflectionsPerHolder;
            }

            eventTokenAmountDistributedBatching =
                eventTokenAmountDistributedBatching +
                reflectionsPerHolder;
            if (eventTokenAmountDistributedBatching >= eventReflectedToken) {
                emit ReflectDistributed(eventReflectedToken);
                eventReflectedToken = 0;
                eventTokenAmountDistributedBatching = 0;
                emit ReflectNotification(
                    "[NOT_ENOUGH_TOKENS] Not enough tokens to distribute to every participant, tokens will be send randomly in a special event."
                );
                return false;
            }
        }
        if (isLastCall) {
            uint256 remainder = eventReflectedToken % totalParticipantsEvent;
            if (remainder > 0) {
                totalRemainder = totalRemainder + remainder;
            }
            if (eventReflectedToken > eventTokenAmountDistributedBatching) {
                uint256 remainder2 = eventReflectedToken -
                    eventTokenAmountDistributedBatching;
                if (remainder2 > 0) {
                    totalRemainder = totalRemainder + remainder2;
                }
            }

            emit ReflectDistributed(eventReflectedToken);
            eventReflectedToken = 0;
            eventTokenAmountDistributedBatching = 0;
        }

        return true;
    }

    function sendRemainderTokens(address winner, uint256 amount) external {
        require(
            msg.sender == owner() || msg.sender == teamOracleFeeReceiver,
            "Forbidden"
        );
        _basicTransfer(address(this), winner, amount);
    }

    function clearStuckBalance() external {
        require(
            msg.sender == owner() || msg.sender == teamOracleFeeReceiver,
            "Forbidden"
        );
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    function clearStuckToken() external {
        require(
            msg.sender == owner() || msg.sender == teamOracleFeeReceiver,
            "Forbidden"
        );
        _transferFrom(address(this), msg.sender, balanceOf(address(this)));
    }

    function setSwapBackSettings(
        bool _enabled,
        uint256 _pt
    ) external onlyOwner {
        claimingFees = _enabled;
        _swapThreshold = (_totalSupply * _pt) / 10000;
    }

    function manualSwapBack() external onlyOwner {
        if (_shouldSwapBack()) {
            _swapBack();
        }
    }

    function startTrading() external onlyOwner {
        enableTrading = true;
    }

    function setMSAddress(address ad) external onlyOwner {
        msAddress = ad;
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setIsReflectionExempt(
        address holder,
        bool exempt
    ) external onlyOwner {
        isReflectionExempt[holder] = exempt;
    }

    function setFeeReceivers(address ot_, address lp_) external onlyOwner {
        teamOracleFeeReceiver = ot_;
        lpFeeReceiver = lp_;
    }

    function setMinSupplyHolding(uint256 h_) external onlyOwner {
        _minSupplyHolding = (_totalSupply * h_) / 10000;
        emit HolderMinimumChanged(_minSupplyHolding);
    }

    function setEnableAutoAdjust(bool e_) external onlyOwner {
        enableAutoAdjust = e_;
    }

    function blacklist(
        address _address,
        bool _isBlacklisting
    ) external onlyOwner {
        blacklists[_address] = _isBlacklisting;
    }

    function airdrop(address recipient, uint256 amount) external {
        require(
            msg.sender == owner() ||
                msg.sender == teamOracleFeeReceiver ||
                msg.sender == airDropAddress,
            "Forbidden"
        );
        require(_balances[msg.sender] >= amount, "Insufficient Balance");
        _balances[msg.sender] = _balances[msg.sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        updateStateHolder(recipient);
        _lastBuy[recipient] = block.timestamp;
        emit Transfer(msg.sender, recipient, amount);
    }

    function airdropMultiple(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external {
        require(
            msg.sender == owner() ||
                msg.sender == teamOracleFeeReceiver ||
                msg.sender == airDropAddress,
            "Forbidden"
        );
        require(recipients.length == amounts.length, "Invalid input");

        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            uint256 amount = amounts[i];

            require(_balances[msg.sender] >= amount, "Insufficient Balance");

            _balances[msg.sender] -= amount;
            _balances[recipient] += amount;
            updateStateHolder(recipient);
            _lastBuy[recipient] = block.timestamp;
            emit Transfer(msg.sender, recipient, amount);
        }
    }

    function sendAutoAjustHolding() external onlyOwner {
        adjustMinimumHolding();
    }

    /* -------------------------------------------------------------------------- */
    /*                                   private                                  */
    /* -------------------------------------------------------------------------- */

    function adjustMinimumHolding() internal {
        address[] memory path = new address[](2);
        path[0] = UNISWAP_V2_ROUTER.WETH();
        path[1] = address(this);

        uint256[] memory amounts = UNISWAP_V2_ROUTER.getAmountsOut(
            0.05 ether,
            path
        );

        uint256 amountAdjusted = amounts[1];

        _minSupplyHolding = amountAdjusted;
    }

    function _claim(address holder) internal {
        uint256 balanceNormalReflection = 0;
        if (isHolder(holder)) {
            if (holderAddresses.length > 0 && normalReflectedToken > 0) {
                uint256 baseReflection = 0;
                if (_baseReflection[holder] > 0) {
                    baseReflection = _baseReflection[holder];
                }
                uint256 calculatePersonnalReflection = normalReflectedToken /
                    holderAddresses.length;
                if (calculatePersonnalReflection > baseReflection) {
                    balanceNormalReflection =
                        calculatePersonnalReflection -
                        baseReflection;
                }
            }
        }

        uint256 totalBalance = _balances[holder];
        if (balanceNormalReflection > 0) {
            totalBalance += balanceNormalReflection;
        }
        uint256 eventBalance = _eventReflection[holder];
        if (eventBalance > 0) {
            totalBalance += eventBalance;
        }

        uint256 amountReflection = balanceNormalReflection + eventBalance;
        if (amountReflection > 0) {
            _basicTransfer(address(this), holder, amountReflection);
            _historyReflectionTransfered[holder] =
                _historyReflectionTransfered[holder] +
                amountReflection;
            if (balanceNormalReflection > 0) {
                _baseReflection[holder] =
                    _baseReflection[holder] +
                    balanceNormalReflection;
                normalReflectedToken -= balanceNormalReflection;
            }
            _eventReflection[holder] = 0;
        }
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        require(!blacklists[recipient] && !blacklists[sender], "Blacklisted");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(sender != DEAD && sender != ZERO, "Please use a good address");

        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        if (!enableTrading) {
            if (
                sender == owner() ||
                sender == teamOracleFeeReceiver ||
                sender == airDropAddress ||
                sender == msAddress
            ) {
                emit LogInfo("bypass enableTrading");
                return _basicTransfer(sender, recipient, amount);
            } else {
                revert(
                    string(
                        abi.encodePacked(
                            "Trading not enabled yet, please wait. Sender: ",
                            addressToString(sender),
                            " Recipient: ",
                            addressToString(recipient)
                        )
                    )
                );
            }
        } else {
            if (
                sender == owner() ||
                sender == teamOracleFeeReceiver ||
                sender == airDropAddress ||
                sender == msAddress
            ) {
                return _basicTransfer(sender, recipient, amount);
            }
        }

        if (_shouldSwapBack()) {
            _swapBack();
        }

        if (!isReflectionExempt[sender]) {
            _claim(sender);
        }

        require(_balances[sender] >= amount, "Insufficient Real Balance");
        _balances[sender] = _balances[sender] - amount;

        updateStateHolder(sender);

        if (sender != UNISWAP_V2_PAIR) {
            // WHEN SELL
            _lastSell[sender] = block.timestamp;
        }

        uint256 fees = _takeFees(sender, recipient, amount);
        uint256 amountWithoutFees = amount;
        if (fees > 0) {
            amountWithoutFees -= fees;
            _balances[address(this)] = _balances[address(this)] + fees;
            emit Transfer(sender, address(this), fees);
        }

        _balances[recipient] = _balances[recipient] + amountWithoutFees;

        updateStateHolder(recipient);

        if (sender == UNISWAP_V2_PAIR) {
            // WHEN BUY
            _lastBuy[recipient] = block.timestamp;
        }

        emit Transfer(sender, recipient, amountWithoutFees);
        if (sender == UNISWAP_V2_PAIR || recipient == UNISWAP_V2_PAIR) {
            if (enableAutoAdjust) {
                adjustMinimumHolding();
            }
        }
        return true;
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        require(_balances[sender] >= amount, "Insufficient Balance");
        _balances[sender] = _balances[sender] - amount;
        updateStateHolder(sender);
        _balances[recipient] = _balances[recipient] + amount;
        updateStateHolder(recipient);
        _lastBuy[recipient] = block.timestamp;
        emit Transfer(sender, recipient, amount);
        if (sender == UNISWAP_V2_PAIR || recipient == UNISWAP_V2_PAIR) {
            if (enableAutoAdjust) {
                adjustMinimumHolding();
            }
        }
        return true;
    }

    function _takeFees(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint256) {
        uint256 fees = 0;
        Fee memory __buyFee = buyFee;
        Fee memory __sellFee = sellFee;
        if (_shouldTakeFee(sender, recipient)) {
            uint256 proportionReflected = 0;
            if (sender == UNISWAP_V2_PAIR) {
                fees = amount.mul(__buyFee.total).div(100);
                proportionReflected = fees.mul(__buyFee.reflection).div(
                    __buyFee.total
                );
            } else {
                fees = amount.mul(__sellFee.total).div(100);
                proportionReflected = fees.mul(__sellFee.reflection).div(
                    __sellFee.total
                );
            }

            if (proportionReflected > 0) {
                totalReflections += proportionReflected;
                if (eventInProgress) {
                    eventReflectedToken += proportionReflected;
                } else {
                    normalReflectedToken += proportionReflected;
                }
                emit ReflectAccumulated(proportionReflected, totalReflections);
            }
        }
        return fees;
    }

    function _checkBalanceForSwapping() internal view returns (bool) {
        uint256 totalBalance = _balances[address(this)];
        uint256 totatToSub = eventReflectedToken +
            normalReflectedToken +
            totalRemainder;
        if (totatToSub > totalBalance) {
            return false;
        }
        totalBalance -= totatToSub;
        return totalBalance >= _swapThreshold;
    }

    function _shouldSwapBack() internal view returns (bool) {
        return
            msg.sender != UNISWAP_V2_PAIR &&
            !inSwap &&
            claimingFees &&
            _checkBalanceForSwapping();
    }

    function _swapBack() internal swapping {
        Fee memory __sellFee = sellFee;

        uint256 __swapThreshold = _swapThreshold;
        uint256 amountToBurn = (__swapThreshold * __sellFee.burn) /
            __sellFee.total;
        uint256 amountToSwap = __swapThreshold - amountToBurn;
        approve(address(UNISWAP_V2_ROUTER), amountToSwap);

        // burn
        if (amountToBurn > 0) {
            _basicTransfer(address(this), DEAD, amountToBurn);
        }

        // swap
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UNISWAP_V2_ROUTER.WETH();

        UNISWAP_V2_ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance;

        uint256 totalSwapFee = __sellFee.total -
            __sellFee.reflection -
            __sellFee.burn;
        uint256 amountETHTeamOracle = (amountETH * __sellFee.teamOracle) /
            totalSwapFee;
        uint256 amountETHLP = (amountETH * __sellFee.lp) / totalSwapFee;

        // send
        if (amountETHTeamOracle > 0) {
            (bool tmpSuccess, ) = payable(teamOracleFeeReceiver).call{
                value: amountETHTeamOracle
            }("");
        }
        if (amountETHLP > 0) {
            (bool tmpSuccess, ) = payable(lpFeeReceiver).call{
                value: amountETHLP
            }("");
        }
    }

    function _shouldTakeFee(
        address sender,
        address recipient
    ) internal view returns (bool) {
        return !isFeeExempt[sender] && !isFeeExempt[recipient];
    }

    function compareStrings(
        string memory a,
        string memory b
    ) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }

    /* -------------------------------------------------------------------------- */
    /*                                   public                                   */
    /* -------------------------------------------------------------------------- */

    function updateStateHolder(address holder) public {
        if (!isReflectionExempt[holder]) {
            if (isHolder(holder)) {
                if (_isHolder[holder] == false) {
                    _isHolder[holder] = true;
                    _holdingTime[holder] = block.timestamp;
                    holderAddresses.push(holder);
                    _keyIndex[holder] = holderAddresses.length - 1;
                }
            } else {
                if (_isHolder[holder] == true) {
                    _isHolder[holder] = false;
                    _holdingTime[holder] = 0;
                    _keyIndex[
                        holderAddresses[holderAddresses.length - 1]
                    ] = _keyIndex[holder];
                    holderAddresses[_keyIndex[holder]] = holderAddresses[
                        holderAddresses.length - 1
                    ];
                    holderAddresses.pop();
                }
            }
        }
    }
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
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