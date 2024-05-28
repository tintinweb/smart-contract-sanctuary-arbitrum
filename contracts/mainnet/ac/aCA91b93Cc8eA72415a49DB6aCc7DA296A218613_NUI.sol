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
pragma solidity 0.8.22;

import { ExeData } from "../lib/GenStructs.sol";

interface INRI {
    //
    function updateExecutionDate(bytes32 _identifier, uint8 _tau) external;
    function createPosition(bytes32 _identifier, uint40 _nextExecution) external;
    function closePosition(bytes32 _identifier, bytes32 _identifierLast) external;
    //
    function positionDetail(bytes32 _identifier) external view returns (ExeData memory);
    //
    function resolverRunning() external view returns (bool);
    function maxDcaExecutable() external view returns (uint40);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

library DateTime {
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 constant SECONDS_PER_HOUR = 60 * 60;
    uint256 constant SECONDS_PER_MINUTE = 60;

    function getHour(uint256 _timestamp) private pure returns (uint256) {
        uint256 secs = _timestamp % SECONDS_PER_DAY;
        return secs / SECONDS_PER_HOUR;
    }

    function getMinute(uint256 _timestamp) private pure returns (uint256) {
        uint256 secs = _timestamp % SECONDS_PER_HOUR;
        return secs / SECONDS_PER_MINUTE;
    }

    function getSecond(uint256 _timestamp) private pure returns (uint256) {
        return _timestamp % SECONDS_PER_MINUTE;
    }

    function subHours(uint256 _timestamp, uint256 _hours) private pure returns (uint256) {
        return _timestamp - _hours * SECONDS_PER_HOUR;
    }

    function subMinutes(uint256 _timestamp, uint256 _minutes) private pure returns (uint256) {
        return _timestamp - _minutes * SECONDS_PER_MINUTE;
    }

    function subSeconds(uint256 _timestamp, uint256 _seconds) private pure returns (uint256) {
        return _timestamp - _seconds;
    }
    /**
     * @notice  Generate midnight timestamp (Sunday MM DD, YYYY 00:00:00).
     * @param   _timestamp  block timestamp.
     * @return  uint256  midnight timestamp.
     */
    function getMidnightTimestamp(uint256 _timestamp) internal pure returns (uint256) {
        uint256 midnightTimestap = subHours(_timestamp, getHour(_timestamp));
        midnightTimestap = subMinutes(midnightTimestap, getMinute(_timestamp));
        return subSeconds(midnightTimestap, getSecond(_timestamp));

    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

library GenFuntions {
    function getIdentifier(address _user, address _srcToken, address _dstToken) internal pure returns (bytes32){
        return keccak256(abi.encodePacked(_user, _srcToken, _dstToken));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

struct UserData {
    bool toBeClosed;
    bytes32 identifier;
    address owner;
    address receiver;
    address srcToken;
    address dstToken;
    uint8 tau;
    uint40 exeRequired; //0 = Unlimited
    uint256 srcAmount;
    uint256 limitOrderBuy; //USD (precision 6 dec)
}
struct UserDetail {
    address receiver;
    uint8 tau;
    uint40 nextExecution;
    uint40 lastExecution;
    uint256 limitOrderBuy; //USD (precision 6 dec)
}
struct UserDca {
    bool toBeClosed;
    bytes32 identifier;
    address srcToken;
    address dstToken;
    uint16 code;
    uint40 dateCreation; //sec
    uint40 exeRequired;
    uint40 exePerformed;
    uint256 srcAmount;
}
struct ExeData {
    uint8 onGoing;
    uint8 errCount;
    uint8 limitCount;
    uint16 code;
    uint40 dateCreation; //sec
    uint40 nextExecution; //sec
    uint40 lastExecution; //sec
    uint40 exePerformed;
    uint256 fundTransferred;
}
struct ResolverData {
    bool toBeClosed;
    bool allowOk;
    bool balanceOk;
    address owner;
    address receiver;
    address srcToken;
    address dstToken;
    uint8 srcDecimals;
    uint8 dstDecimals;
    uint8 onGoing;
    uint256 srcAmount;
    uint256 limitOrderBuy; //USD (precision 6 dec)
}
struct StoredData {
    uint256 timestamp;
    uint256 tokenValue; //USD (precision 6 dec)
    uint256 tokenAmount;
}
struct QueueData {
    bytes32 identifier;
    address owner;
    address receiver;
    address srcToken;
    address dstToken;
    uint8 tau;
    uint40 exeRequired; //0 = Unlimited
    uint40 dateCreation; //sec **
    uint40 nextExecution; //sec **
    uint256 srcAmount;
    uint256 limitOrderBuy; //USD (precision 6 dec)
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import { UserData, UserDca, UserDetail, ExeData, QueueData } from "./lib/GenStructs.sol";
import { GenFuntions } from "./lib/GenFunctions.sol";
import { IERC20 } from "./interfaces/IERC20.sol";
import { INRI } from "./interfaces/INRI.sol";
import { DateTime } from "./lib/DateTime.sol";

error NotAuthorized();

/**
 * @author  Nebula Labs for Neon Protocol.
 * @title   User Interface for the App.
 */
contract NUI {
    UserData[] private dcaConfiguration;
    QueueData[] private dcaQueue;
    mapping (bytes32 => uint40) private dcaPosition;
    mapping (bytes32 => uint40) private queuePosition;
    mapping (bytes32 => bool) private positionCreated;
    mapping (bytes32 => bool) private positionInQueue;
    mapping (uint40 => uint40) public positionPerExecution;
    mapping (address => uint40) public userTotalDca;
    mapping (address => uint40) public userTotalQueue;
    mapping (address => mapping (address => uint256)) private userAllowance;
    address public NRI;
    uint40 public totalDCAs;
    uint256 public protocolAllTimeDCAs;

    uint8 constant private MIN_TAU = 1;
    uint24 constant private TIME_BASE = 1 days;
    address immutable public ADMIN;

    modifier onlyNRI(){
        if(msg.sender != NRI) revert NotAuthorized();
        _;
    }
    modifier onlyAdmin(){
        require(msg.sender == ADMIN, "Not Authorized");
        _;
    }

    constructor(){
        ADMIN = msg.sender;
    }

    /* WRITE METHODS*/
    function init(address _NRI) external {
        require(NRI == address(0), "Already initialize");
        NRI = _NRI;
    }
    /**
     * @notice  Create DCA position.
     * @param   _receiver  address where will send token (0x0 = Caller).
     * @param   _srcToken  ERC20 address token to sell.
     * @param   _dstToken  ERC20 address token to buy.
     * @param   _tau  frequency of execution.
     * @param   _exeRequired  number of execution required (0 = Unlimited).
     * @param   _exeStart  when execution should start (0 = Now, 1 = Now+Tau, xx = Start Date).
     * @param   _srcAmount  amount of srcToken to sell.
     * @param   _limitOrderBuy  limit order to buy in USD to be added with 6 dec of precision (price <= _limitOrderBuy).
     */
    function createDCA(
        address _receiver,
        address _srcToken,
        address _dstToken,
        uint8 _tau,
        uint40 _exeRequired,
        uint40 _exeStart,
        uint256 _srcAmount,
        uint256 _limitOrderBuy
    ) external {
        uint40 nextExecution;
        require(_srcToken != _dstToken, "SrcToken and DestToken are identical");
        require(_isERC20(_dstToken), "DstToken not an ERC20 contract");//srcToken already check on line 79-80.
        require(_tau >= MIN_TAU, "Frequency under the limit");
        bytes32 identifier = GenFuntions.getIdentifier(msg.sender, _srcToken, _dstToken);
        require(!positionCreated[identifier] && !positionInQueue[identifier], "DCA already created");
        require(_exeRequired != 0, "Execution required is 0");
        userAllowance[msg.sender][_srcToken] = (_srcAmount * _exeRequired) + userAllowance[msg.sender][_srcToken];
        require(IERC20(_srcToken).allowance(msg.sender, NRI) >= userAllowance[msg.sender][_srcToken], "Insufficient approval");
        require(IERC20(_srcToken).balanceOf(msg.sender) >= _srcAmount, "Insufficient amount");
        address receiver = _receiver == address(0) ? msg.sender : _receiver;
        if(_exeStart == 0){
            nextExecution = uint40(DateTime.getMidnightTimestamp(block.timestamp));
        }else if(_exeStart == 1){
            nextExecution  = uint40(DateTime.getMidnightTimestamp(block.timestamp + (_tau * TIME_BASE)));
        }else{
            require(_exeStart > uint40(block.timestamp), "Execution start must be greater than the current time");
            nextExecution = uint40(DateTime.getMidnightTimestamp(_exeStart));
        }
        require(positionPerExecution[nextExecution] < INRI(NRI).maxDcaExecutable(), "Max capacity reached, Please try later or select another day");
        manageQueue();
        if(INRI(NRI).resolverRunning()){//Create Queue
            queuePosition[identifier] = uint40(dcaQueue.length);
            positionInQueue[identifier] = true;
            _addQueue(identifier, msg.sender, receiver, _srcToken, _dstToken, _tau, _exeRequired, nextExecution, _srcAmount, _limitOrderBuy);
        }else{//Create DCA           
            dcaPosition[identifier] = totalDCAs;
            positionCreated[identifier] = true;
            INRI(NRI).createPosition(identifier, nextExecution);
            _addDca(identifier, msg.sender, receiver, _srcToken, _dstToken, _tau, _exeRequired, _srcAmount, _limitOrderBuy);
        }
        unchecked {
            ++positionPerExecution[nextExecution];
        }
    }
    /**
     * @notice  Close DCA position.
     * @param   _identifier  position identifier.
     */
    function closeDCA(bytes32 _identifier) external {
        uint40 position;
        if(positionInQueue[_identifier]){//Close Queue by User
            position = queuePosition[_identifier];
            require(msg.sender == dcaQueue[position].owner, "Not authorized");
            _delQueuePosition(_identifier, uint40(dcaQueue.length));
        }else{
            position = dcaPosition[_identifier];
            require(msg.sender == dcaConfiguration[position].owner, "Not authorized");
            if(INRI(NRI).resolverRunning()){//Resolver will close DCA
                require(!dcaConfiguration[position].toBeClosed, "Request already submitted");
                dcaConfiguration[position].toBeClosed = true;
            }else{//Close DCA by User
                _closeDca(_identifier, msg.sender, true);
            }
        }
    }
    /**
     * @notice  Close position with "executionCompletion".
     * @dev     Only NRI.
     * @param   _identifier  position identifier.
     * @param   _user  address position owner.
     */
    function closePosition(bytes32 _identifier, address _user) external onlyNRI {
        _closeDca(_identifier, _user, false);
    }
    /**
     * @notice  Skip execution to next due date.
     * @param   _identifier  position identifier.
     */
    function skipExecution(bytes32 _identifier) external {
        uint40 position = dcaPosition[_identifier];
        require(msg.sender == dcaConfiguration[position].owner, "Not authorized");
        INRI(NRI).updateExecutionDate(_identifier, dcaConfiguration[position].tau);
    }
    /**
     * @notice  Queue-based DCA creation.
     */
    function manageQueue() public {
        if (!INRI(NRI).resolverRunning()) {
            uint40 length = uint40(dcaQueue.length);
            for(uint40 i; i < length; ++i){
                if (positionPerExecution[dcaQueue[i].nextExecution] >= INRI(NRI).maxDcaExecutable()) continue;
                dcaPosition[dcaQueue[i].identifier] = totalDCAs;
                positionCreated[dcaQueue[i].identifier] = true;
                INRI(NRI).createPosition(dcaQueue[i].identifier, dcaQueue[i].nextExecution);
                _addDca(dcaQueue[i].identifier, dcaQueue[i].owner, dcaQueue[i].receiver, dcaQueue[i].srcToken, dcaQueue[i].dstToken, dcaQueue[i].tau, dcaQueue[i].exeRequired, dcaQueue[i].srcAmount, dcaQueue[i].limitOrderBuy);
                positionInQueue[dcaQueue[i].identifier] = false;
                unchecked {
                    --userTotalQueue[dcaQueue[i].owner];
                }
            }
            delete dcaQueue;
        }
    }
    /**
     * @notice  If necessary, empty the queue.
     * @dev     Only Admin.
     * @param   _length  number of data to empty.
     */
    function purgeQueue(uint40 _length) external onlyAdmin {
        for(uint40 i; i < _length; ++i){
            unchecked {
                --userTotalQueue[dcaQueue[i].owner];
            }
            dcaQueue.pop();
        }
    }
    /**
     * @notice  Update total position per execution.
     * @param   _timeToDelete  slot to --.
     * @param   _timeToUpdate  slot to ++.
     */
    function updatePositionPerExecution(uint40 _timeToDelete, uint40 _timeToUpdate) external onlyNRI {
        unchecked {
            --positionPerExecution[_timeToDelete];
            if(_timeToUpdate != 0) { 
                ++positionPerExecution[_timeToUpdate];
            }
        }
    }
    /**
     * @notice  Remove allowance already used.
     * @param   _id  position.
     */
    function updateAllowance(uint40 _id) external onlyNRI {
        userAllowance[dcaConfiguration[_id].owner][dcaConfiguration[_id].srcToken] -= dcaConfiguration[_id].srcAmount;
    }
    /* VIEW METHODS*/
    /**
     * @notice  Obtain DCA configuration information.
     * @dev     Only NRI.
     * @param   _id  array position.
     * @return  UserData  configuration data.
     */
    function userData(uint40 _id) external view onlyNRI returns (UserData memory){
        return dcaConfiguration[_id];
    }
    /**
     * @notice  Basic information of Caller's active DCAs.
     * @return  UserDca[] basic DCA information.
     */
    function userDcas() external view returns (UserDca[] memory){
        UserDca[] memory resultData = new UserDca[](userTotalDca[msg.sender]);
        ExeData memory exeInfo;
        uint40 idx;
        for(uint40 i; i < totalDCAs; ++i){
            if(dcaConfiguration[i].owner == msg.sender){
                exeInfo = INRI(NRI).positionDetail(dcaConfiguration[i].identifier);
                resultData[idx] = UserDca(
                    dcaConfiguration[i].toBeClosed,
                    dcaConfiguration[i].identifier,
                    dcaConfiguration[i].srcToken,
                    dcaConfiguration[i].dstToken,
                    exeInfo.code,
                    exeInfo.dateCreation,
                    dcaConfiguration[i].exeRequired,
                    exeInfo.exePerformed,
                    dcaConfiguration[i].srcAmount
                );
                unchecked {
                    ++idx;
                }
            }
        }
        return resultData;
    }
    /**
     * @notice  Basic information of Caller's active Queue.
     * @return  UserDca[] basic DCA information.
     */
    function userQueue() external view returns (UserDca[] memory){
        UserDca[] memory resultData = new UserDca[](userTotalQueue[msg.sender]);
        uint40 idx; 
        uint40 queue = uint40(dcaQueue.length);
        for(uint40 i; i < queue; ++i){
            if(dcaQueue[i].owner == msg.sender){
                resultData[idx] = UserDca(
                    false,
                    dcaQueue[i].identifier,
                    dcaQueue[i].srcToken,
                    dcaQueue[i].dstToken,
                    0,
                    dcaQueue[i].dateCreation,
                    dcaQueue[i].exeRequired,
                    0,
                    dcaConfiguration[i].srcAmount
                );
                unchecked {
                    ++idx;
                }
            }
        }
        return resultData;
    }
    /**
     * @notice  Detailed information of the Caller's individual DCA.
     * @param   _identifier  position identifier.
     * @return  UserDetail  Detailed information.
     */
    function userDcaDetail(bytes32 _identifier) external view returns (UserDetail memory){
        uint40 position = dcaPosition[_identifier];
        ExeData memory exeInfo;
        require(msg.sender == dcaConfiguration[position].owner, "Not authorized");
        exeInfo = INRI(NRI).positionDetail(dcaConfiguration[position].identifier);
        return UserDetail(
            dcaConfiguration[position].receiver,
            dcaConfiguration[position].tau,
            exeInfo.nextExecution,
            exeInfo.lastExecution,
            dcaConfiguration[position].limitOrderBuy
        );
    }
    /**
     * @notice  Manage user allowance required.
     * @param   _srcToken  ERC20 address token to sell.
     * @param   _srcAmount  amount of srcToken to sell.
     * @param   _exeRequired  number of execution required.
     * @return  incr  (false = approve, true = increase).
     * @return  allowRequired  amount required for allowance.
     */
    function checkUserAllowance(address _srcToken, uint256 _srcAmount, uint40 _exeRequired) external view returns (bool incr, uint256 allowRequired){
        require(_exeRequired != 0, "Execution required is 0");
        uint256 ERC20Allowance = IERC20(_srcToken).allowance(msg.sender, NRI);
        if(ERC20Allowance >= userAllowance[msg.sender][_srcToken]){
            incr = true;
            allowRequired = (ERC20Allowance - userAllowance[msg.sender][_srcToken]) >= (_srcAmount * _exeRequired) ? 0 : (_srcAmount * _exeRequired);
        }else{
            allowRequired = (userAllowance[msg.sender][_srcToken] + (_srcAmount * _exeRequired));
        }
    }
    function isPositionFree(address _srcToken, address _dstToken) external view returns (bool){
        bytes32 identifier = GenFuntions.getIdentifier(msg.sender, _srcToken, _dstToken);
        return (!positionCreated[identifier]);
    }
    /* PRIVATE METHODS*/
    /**
     * @dev   Don't need to check "if already closed", because revert with panic error not having the array element.
     */
    function _closeDca(bytes32 _identifier, address _user, bool _byUser) private {
        uint256 allowanceToRemove;
        ExeData memory exeInfo;
        uint40 position = dcaPosition[_identifier];
        positionCreated[_identifier] = false;
        bytes32 identifierLast = GenFuntions.getIdentifier(dcaConfiguration[totalDCAs - 1].owner, dcaConfiguration[totalDCAs - 1].srcToken, dcaConfiguration[totalDCAs - 1].dstToken);
        exeInfo = INRI(NRI).positionDetail(dcaConfiguration[position].identifier);
        if(_byUser){ unchecked { --positionPerExecution[exeInfo.nextExecution]; }}
        allowanceToRemove = (dcaConfiguration[position].srcAmount * (dcaConfiguration[position].exeRequired - exeInfo.exePerformed));
        uint256 currentAllowance = userAllowance[dcaConfiguration[position].owner][dcaConfiguration[position].srcToken];
        userAllowance[dcaConfiguration[position].owner][dcaConfiguration[position].srcToken] -= currentAllowance >= allowanceToRemove ? allowanceToRemove : currentAllowance;
        if(_identifier != identifierLast){
            dcaConfiguration[dcaPosition[_identifier]] = dcaConfiguration[dcaPosition[identifierLast]];
            dcaPosition[identifierLast] = dcaPosition[_identifier];
        }
        dcaPosition[_identifier] = 0;
        dcaConfiguration.pop();
        INRI(NRI).closePosition(_identifier, identifierLast);
        unchecked {
            --totalDCAs;
            --userTotalDca[_user];
        }
    }
    function _delQueuePosition(bytes32 _identifier, uint40 _totalQueue) private {
        positionInQueue[_identifier] = false;
        unchecked {
            --userTotalQueue[dcaQueue[queuePosition[_identifier]].owner];
            --positionPerExecution[dcaQueue[queuePosition[_identifier]].nextExecution];
        }
        bytes32 identifierLast = GenFuntions.getIdentifier(dcaQueue[_totalQueue - 1].owner, dcaQueue[_totalQueue - 1].srcToken, dcaQueue[_totalQueue - 1].dstToken);
        if(_identifier != identifierLast){
            dcaQueue[queuePosition[_identifier]] = dcaQueue[queuePosition[identifierLast]];
            queuePosition[identifierLast] = queuePosition[_identifier];
        }
        queuePosition[_identifier] = 0;
        dcaQueue.pop();
    }
    function _addDca(
        bytes32 _indetifier,
        address _owner,
        address _receiver,
        address _srcToken,
        address _dstToken,
        uint8 _tau,
        uint40 _exeRequired,
        uint256 _srcAmount,
        uint256 _limitOrderBuy
    ) private {
        dcaConfiguration.push(UserData(
            false,
            _indetifier,
            _owner,
            _receiver,
            _srcToken,
            _dstToken,
            _tau,
            _exeRequired,
            _srcAmount,
            _limitOrderBuy
        ));
        unchecked {
            ++totalDCAs;
            ++userTotalDca[_owner];
            ++protocolAllTimeDCAs;
        }
    }
    function _addQueue(
        bytes32 _indetifier,
        address _owner,
        address _receiver,
        address _srcToken,
        address _dstToken,
        uint8 _tau,
        uint40 _exeRequired,
        uint40 _nextExecution,
        uint256 _srcAmount,
        uint256 _limitOrderBuy
    ) private {
        dcaQueue.push(QueueData(
            _indetifier,
            _owner,
            _receiver,
            _srcToken,
            _dstToken,
            _tau,
            _exeRequired,
            uint40(block.timestamp),
            _nextExecution,
            _srcAmount,
            _limitOrderBuy
        ));
        unchecked {
            ++userTotalQueue[_owner];
        }
    }
    function _isERC20(address _tokenAddress) private view returns (bool) {
        try IERC20(_tokenAddress).totalSupply() returns (uint256) {
            return true;
        } catch {
            return false;
        }
    }
}