/**
 *Submitted for verification at Arbiscan.io on 2024-03-08
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;










contract ArbitrumActionsUtilAddresses {
    address internal constant DFS_REG_CONTROLLER_ADDR = 0x6F6DaE1bCB60F67B2Cb939dBE565e8fD03F6F002;
    address internal constant SUB_STORAGE_ADDR = 0x24ab68395660b910BfBF1cc88BaA316BA06354eE;
    address internal constant TRANSIENT_STORAGE = 0x48cdE7c1f67fF11A62F6b4272166AB60EFB48C1F;

    address internal constant REGISTRY_ADDR = 0xBF1CaC12DB60819Bfa71A328282ecbc1D40443aA;
    address internal constant DFS_LOGGER_ADDR = 0xE6f9A5C850dbcD12bc64f40d692F537250aDEC38;
    address internal constant PROXY_AUTH_ADDR = 0xF3A8479538319756e100C386b3E60BF783680d8f;

    // not yet implemented
    address internal constant LSV_PROXY_REGISTRY_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
}







contract ActionsUtilHelper is ArbitrumActionsUtilAddresses {
}







contract ArbitrumAuthAddresses {
    address internal constant ADMIN_VAULT_ADDR = 0xd47D8D97cAd12A866900eEc6Cde1962529F25351;
    address internal constant DSGUARD_FACTORY_ADDRESS = 0x5261abC3a94a6475D0A1171daE94A5f84fbaEcD2;
    address internal constant ADMIN_ADDR = 0x6AFEA85cFAB61e3a55Ad2e4537252Ec05796BEfa;
    address internal constant PROXY_AUTH_ADDRESS = 0xF3A8479538319756e100C386b3E60BF783680d8f;
    address internal constant MODULE_AUTH_ADDRESS = 0xb3D6b7F561C1F250bF7f0F00eFD19FAE6cE533dd;
}







contract AuthHelper is ArbitrumAuthAddresses {
}








contract AdminVault is AuthHelper {
    address public owner;
    address public admin;

    error SenderNotAdmin();

    constructor() {
        owner = msg.sender;
        admin = ADMIN_ADDR;
    }

    /// @notice Admin is able to change owner
    /// @param _owner Address of new owner
    function changeOwner(address _owner) public {
        if (admin != msg.sender){
            revert SenderNotAdmin();
        }
        owner = _owner;
    }

    /// @notice Admin is able to set new admin
    /// @param _admin Address of multisig that becomes new admin
    function changeAdmin(address _admin) public {
        if (admin != msg.sender){
            revert SenderNotAdmin();
        }
        admin = _admin;
    }

}







interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint256 digits);
    function totalSupply() external view returns (uint256 supply);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}







library Address {
    //insufficient balance
    error InsufficientBalance(uint256 available, uint256 required);
    //unable to send value, recipient may have reverted
    error SendingValueFail();
    //insufficient balance for call
    error InsufficientBalanceForCall(uint256 available, uint256 required);
    //call to non-contract
    error NonContractCall();
    
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        uint256 balance = address(this).balance;
        if (balance < amount){
            revert InsufficientBalance(balance, amount);
        }

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        if (!(success)){
            revert SendingValueFail();
        }
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        uint256 balance = address(this).balance;
        if (balance < value){
            revert InsufficientBalanceForCall(balance, value);
        }
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        if (!(isContract(target))){
            revert NonContractCall();
        }

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
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
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
    }
}










contract AdminAuth is AuthHelper {
    using SafeERC20 for IERC20;

    AdminVault public constant adminVault = AdminVault(ADMIN_VAULT_ADDR);

    error SenderNotOwner();
    error SenderNotAdmin();

    modifier onlyOwner() {
        if (adminVault.owner() != msg.sender){
            revert SenderNotOwner();
        }
        _;
    }

    modifier onlyAdmin() {
        if (adminVault.admin() != msg.sender){
            revert SenderNotAdmin();
        }
        _;
    }

    /// @notice withdraw stuck funds
    function withdrawStuckFunds(address _token, address _receiver, uint256 _amount) public onlyOwner {
        if (_token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            payable(_receiver).transfer(_amount);
        } else {
            IERC20(_token).safeTransfer(_receiver, _amount);
        }
    }

    /// @notice Destroy the contract
    /// @dev Deprecated method, selfdestruct will soon just send eth
    function kill() public onlyAdmin {
        selfdestruct(payable(msg.sender));
    }
}








contract DFSRegistry is AdminAuth {
    error EntryAlreadyExistsError(bytes4);
    error EntryNonExistentError(bytes4);
    error EntryNotInChangeError(bytes4);
    error ChangeNotReadyError(uint256,uint256);
    error EmptyPrevAddrError(bytes4);
    error AlreadyInContractChangeError(bytes4);
    error AlreadyInWaitPeriodChangeError(bytes4);

    event AddNewContract(address,bytes4,address,uint256);
    event RevertToPreviousAddress(address,bytes4,address,address);
    event StartContractChange(address,bytes4,address,address);
    event ApproveContractChange(address,bytes4,address,address);
    event CancelContractChange(address,bytes4,address,address);
    event StartWaitPeriodChange(address,bytes4,uint256);
    event ApproveWaitPeriodChange(address,bytes4,uint256,uint256);
    event CancelWaitPeriodChange(address,bytes4,uint256,uint256);

    struct Entry {
        address contractAddr;
        uint256 waitPeriod;
        uint256 changeStartTime;
        bool inContractChange;
        bool inWaitPeriodChange;
        bool exists;
    }

    mapping(bytes4 => Entry) public entries;
    mapping(bytes4 => address) public previousAddresses;

    mapping(bytes4 => address) public pendingAddresses;
    mapping(bytes4 => uint256) public pendingWaitTimes;

    /// @notice Given an contract id returns the registered address
    /// @dev Id is keccak256 of the contract name
    /// @param _id Id of contract
    function getAddr(bytes4 _id) public view returns (address) {
        return entries[_id].contractAddr;
    }

    /// @notice Helper function to easily query if id is registered
    /// @param _id Id of contract
    function isRegistered(bytes4 _id) public view returns (bool) {
        return entries[_id].exists;
    }

    /////////////////////////// OWNER ONLY FUNCTIONS ///////////////////////////

    /// @notice Adds a new contract to the registry
    /// @param _id Id of contract
    /// @param _contractAddr Address of the contract
    /// @param _waitPeriod Amount of time to wait before a contract address can be changed
    function addNewContract(
        bytes4 _id,
        address _contractAddr,
        uint256 _waitPeriod
    ) public onlyOwner {
        if (entries[_id].exists){
            revert EntryAlreadyExistsError(_id);
        }

        entries[_id] = Entry({
            contractAddr: _contractAddr,
            waitPeriod: _waitPeriod,
            changeStartTime: 0,
            inContractChange: false,
            inWaitPeriodChange: false,
            exists: true
        });

        emit AddNewContract(msg.sender, _id, _contractAddr, _waitPeriod);
    }

    /// @notice Reverts to the previous address immediately
    /// @dev In case the new version has a fault, a quick way to fallback to the old contract
    /// @param _id Id of contract
    function revertToPreviousAddress(bytes4 _id) public onlyOwner {
        if (!(entries[_id].exists)){
            revert EntryNonExistentError(_id);
        }
        if (previousAddresses[_id] == address(0)){
            revert EmptyPrevAddrError(_id);
        }

        address currentAddr = entries[_id].contractAddr;
        entries[_id].contractAddr = previousAddresses[_id];

        emit RevertToPreviousAddress(msg.sender, _id, currentAddr, previousAddresses[_id]);
    }

    /// @notice Starts an address change for an existing entry
    /// @dev Can override a change that is currently in progress
    /// @param _id Id of contract
    /// @param _newContractAddr Address of the new contract
    function startContractChange(bytes4 _id, address _newContractAddr) public onlyOwner {
        if (!entries[_id].exists){
            revert EntryNonExistentError(_id);
        }
        if (entries[_id].inWaitPeriodChange){
            revert AlreadyInWaitPeriodChangeError(_id);
        }

        entries[_id].changeStartTime = block.timestamp; // solhint-disable-line
        entries[_id].inContractChange = true;

        pendingAddresses[_id] = _newContractAddr;

        emit StartContractChange(msg.sender, _id, entries[_id].contractAddr, _newContractAddr);
    }

    /// @notice Changes new contract address, correct time must have passed
    /// @param _id Id of contract
    function approveContractChange(bytes4 _id) public onlyOwner {
        if (!entries[_id].exists){
            revert EntryNonExistentError(_id);
        }
        if (!entries[_id].inContractChange){
            revert EntryNotInChangeError(_id);
        }
        if (block.timestamp < (entries[_id].changeStartTime + entries[_id].waitPeriod)){// solhint-disable-line
            revert ChangeNotReadyError(block.timestamp, (entries[_id].changeStartTime + entries[_id].waitPeriod));
        }

        address oldContractAddr = entries[_id].contractAddr;
        entries[_id].contractAddr = pendingAddresses[_id];
        entries[_id].inContractChange = false;
        entries[_id].changeStartTime = 0;

        pendingAddresses[_id] = address(0);
        previousAddresses[_id] = oldContractAddr;

        emit ApproveContractChange(msg.sender, _id, oldContractAddr, entries[_id].contractAddr);
    }

    /// @notice Cancel pending change
    /// @param _id Id of contract
    function cancelContractChange(bytes4 _id) public onlyOwner {
        if (!entries[_id].exists){
            revert EntryNonExistentError(_id);
        }
        if (!entries[_id].inContractChange){
            revert EntryNotInChangeError(_id);
        }

        address oldContractAddr = pendingAddresses[_id];

        pendingAddresses[_id] = address(0);
        entries[_id].inContractChange = false;
        entries[_id].changeStartTime = 0;

        emit CancelContractChange(msg.sender, _id, oldContractAddr, entries[_id].contractAddr);
    }

    /// @notice Starts the change for waitPeriod
    /// @param _id Id of contract
    /// @param _newWaitPeriod New wait time
    function startWaitPeriodChange(bytes4 _id, uint256 _newWaitPeriod) public onlyOwner {
        if (!entries[_id].exists){
            revert EntryNonExistentError(_id);
        }
        if (entries[_id].inContractChange){
            revert AlreadyInContractChangeError(_id);
        }

        pendingWaitTimes[_id] = _newWaitPeriod;

        entries[_id].changeStartTime = block.timestamp; // solhint-disable-line
        entries[_id].inWaitPeriodChange = true;

        emit StartWaitPeriodChange(msg.sender, _id, _newWaitPeriod);
    }

    /// @notice Changes new wait period, correct time must have passed
    /// @param _id Id of contract
    function approveWaitPeriodChange(bytes4 _id) public onlyOwner {
        if (!entries[_id].exists){
            revert EntryNonExistentError(_id);
        }
        if (!entries[_id].inWaitPeriodChange){
            revert EntryNotInChangeError(_id);
        }
        if (block.timestamp < (entries[_id].changeStartTime + entries[_id].waitPeriod)){ // solhint-disable-line
            revert ChangeNotReadyError(block.timestamp, (entries[_id].changeStartTime + entries[_id].waitPeriod));
        }

        uint256 oldWaitTime = entries[_id].waitPeriod;
        entries[_id].waitPeriod = pendingWaitTimes[_id];
        
        entries[_id].inWaitPeriodChange = false;
        entries[_id].changeStartTime = 0;

        pendingWaitTimes[_id] = 0;

        emit ApproveWaitPeriodChange(msg.sender, _id, oldWaitTime, entries[_id].waitPeriod);
    }

    /// @notice Cancel wait period change
    /// @param _id Id of contract
    function cancelWaitPeriodChange(bytes4 _id) public onlyOwner {
        if (!entries[_id].exists){
            revert EntryNonExistentError(_id);
        }
        if (!entries[_id].inWaitPeriodChange){
            revert EntryNotInChangeError(_id);
        }

        uint256 oldWaitPeriod = pendingWaitTimes[_id];

        pendingWaitTimes[_id] = 0;
        entries[_id].inWaitPeriodChange = false;
        entries[_id].changeStartTime = 0;

        emit CancelWaitPeriodChange(msg.sender, _id, oldWaitPeriod, entries[_id].waitPeriod);
    }
}







abstract contract DSAuthority {
    function canCall(
        address src,
        address dst,
        bytes4 sig
    ) public view virtual returns (bool);
}







contract DSAuthEvents {
    event LogSetAuthority(address indexed authority);
    event LogSetOwner(address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority public authority;
    address public owner;

    constructor() {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_) public auth {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_) public auth {
        authority = authority_;
        emit LogSetAuthority(address(authority));
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig), "Not authorized");
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(address(0))) {
            return false;
        } else {
            return authority.canCall(src, address(this), sig);
        }
    }
}







contract DSNote {
    event LogNote(
        bytes4 indexed sig,
        address indexed guy,
        bytes32 indexed foo,
        bytes32 indexed bar,
        uint256 wad,
        bytes fax
    ) anonymous;

    modifier note {
        bytes32 foo;
        bytes32 bar;

        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
        }

        emit LogNote(msg.sig, msg.sender, foo, bar, msg.value, msg.data);

        _;
    }
}








abstract contract DSProxy is DSAuth, DSNote {
    DSProxyCache public cache; // global cache for contracts

    constructor(address _cacheAddr) {
        if (!(setCache(_cacheAddr))){
            require(isAuthorized(msg.sender, msg.sig), "Not authorized");
        }
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    // use the proxy to execute calldata _data on contract _code
    function execute(bytes memory _code, bytes memory _data)
        public
        payable
        virtual
        returns (address target, bytes32 response);

    function execute(address _target, bytes memory _data)
        public
        payable
        virtual
        returns (bytes32 response);

    //set new cache
    function setCache(address _cacheAddr) public payable virtual returns (bool);
}

contract DSProxyCache {
    mapping(bytes32 => address) cache;

    function read(bytes memory _code) public view returns (address) {
        bytes32 hash = keccak256(_code);
        return cache[hash];
    }

    function write(bytes memory _code) public returns (address target) {
        assembly {
            target := create(0, add(_code, 0x20), mload(_code))
            switch iszero(extcodesize(target))
                case 1 {
                    // throw if contract failed to deploy
                    revert(0, 0)
                }
        }
        bytes32 hash = keccak256(_code);
        cache[hash] = target;
    }
}







interface ISafe {
    enum Operation {
        Call,
        DelegateCall
    }

    function setup(
        address[] calldata _owners,
        uint256 _threshold,
        address to,
        bytes calldata data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver
    ) external;

    function execTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures
    ) external payable returns (bool success);

    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes memory data,
        Operation operation
    ) external returns (bool success);

    function checkSignatures(
        bytes32 dataHash,
        bytes memory data,
        bytes memory signatures
    ) external view;

    function checkNSignatures(
        address executor,
        bytes32 dataHash,
        bytes memory /* data */,
        bytes memory signatures,
        uint256 requiredSignatures
    ) external view;

    function approveHash(bytes32 hashToApprove) external;

    function domainSeparator() external view returns (bytes32);

    function getTransactionHash(
        address to,
        uint256 value,
        bytes calldata data,
        Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    ) external view returns (bytes32);

    function nonce() external view returns (uint256);

    function setFallbackHandler(address handler) external;

    function getOwners() external view returns (address[] memory);

    function isOwner(address owner) external view returns (bool);

    function getThreshold() external view returns (uint256);

    function enableModule(address module) external;

    function isModuleEnabled(address module) external view returns (bool);

    function disableModule(address prevModule, address module) external;

    function getModulesPaginated(
        address start,
        uint256 pageSize
    ) external view returns (address[] memory array, address next);
}







interface IDSProxyFactory {
    function isProxy(address _proxy) external view returns (bool);
}







contract ArbitrumProxyFactoryAddresses {
    address internal constant PROXY_FACTORY_ADDR = 0x5a15566417e6C1c9546523066500bDDBc53F88C7;
}







contract DSProxyFactoryHelper is ArbitrumProxyFactoryAddresses {
}









contract CheckWalletType is DSProxyFactoryHelper {
    function isDSProxy(address _proxy) public view returns (bool) {
        return IDSProxyFactory(PROXY_FACTORY_ADDR).isProxy(_proxy);
    }
}







contract DefisaverLogger {
    event RecipeEvent(
        address indexed caller,
        string indexed logName
    );

    event ActionDirectEvent(
        address indexed caller,
        string indexed logName,
        bytes data
    );

    function logRecipeEvent(
        string memory _logName
    ) public {
        emit RecipeEvent(msg.sender, _logName);
    }

    function logActionDirectEvent(
        string memory _logName,
        bytes memory _data
    ) public {
        emit ActionDirectEvent(msg.sender, _logName, _data);
    }
}













abstract contract ActionBase is AdminAuth, ActionsUtilHelper, CheckWalletType {
    event ActionEvent(
        string indexed logName,
        bytes data
    );

    DFSRegistry public constant registry = DFSRegistry(REGISTRY_ADDR);

    DefisaverLogger public constant logger = DefisaverLogger(
        DFS_LOGGER_ADDR
    );

    //Wrong sub index value
    error SubIndexValueError();
    //Wrong return index value
    error ReturnIndexValueError();

    /// @dev Subscription params index range [128, 255]
    uint8 public constant SUB_MIN_INDEX_VALUE = 128;
    uint8 public constant SUB_MAX_INDEX_VALUE = 255;

    /// @dev Return params index range [1, 127]
    uint8 public constant RETURN_MIN_INDEX_VALUE = 1;
    uint8 public constant RETURN_MAX_INDEX_VALUE = 127;

    /// @dev If the input value should not be replaced
    uint8 public constant NO_PARAM_MAPPING = 0;

    /// @dev We need to parse Flash loan actions in a different way
    enum ActionType { FL_ACTION, STANDARD_ACTION, FEE_ACTION, CHECK_ACTION, CUSTOM_ACTION }

    /// @notice Parses inputs and runs the implemented action through a user wallet
    /// @dev Is called by the RecipeExecutor chaining actions together
    /// @param _callData Array of input values each value encoded as bytes
    /// @param _subData Array of subscribed vales, replaces input values if specified
    /// @param _paramMapping Array that specifies how return and subscribed values are mapped in input
    /// @param _returnValues Returns values from actions before, which can be injected in inputs
    /// @return Returns a bytes32 value through user wallet, each actions implements what that value is
    function executeAction(
        bytes memory _callData,
        bytes32[] memory _subData,
        uint8[] memory _paramMapping,
        bytes32[] memory _returnValues
    ) public payable virtual returns (bytes32);

    /// @notice Parses inputs and runs the single implemented action through a user wallet
    /// @dev Used to save gas when executing a single action directly
    function executeActionDirect(bytes memory _callData) public virtual payable;

    /// @notice Returns the type of action we are implementing
    function actionType() public pure virtual returns (uint8);


    //////////////////////////// HELPER METHODS ////////////////////////////

    /// @notice Given an uint256 input, injects return/sub values if specified
    /// @param _param The original input value
    /// @param _mapType Indicated the type of the input in paramMapping
    /// @param _subData Array of subscription data we can replace the input value with
    /// @param _returnValues Array of subscription data we can replace the input value with
    function _parseParamUint(
        uint _param,
        uint8 _mapType,
        bytes32[] memory _subData,
        bytes32[] memory _returnValues
    ) internal pure returns (uint) {
        if (isReplaceable(_mapType)) {
            if (isReturnInjection(_mapType)) {
                _param = uint(_returnValues[getReturnIndex(_mapType)]);
            } else {
                _param = uint256(_subData[getSubIndex(_mapType)]);
            }
        }

        return _param;
    }


    /// @notice Given an addr input, injects return/sub values if specified
    /// @param _param The original input value
    /// @param _mapType Indicated the type of the input in paramMapping
    /// @param _subData Array of subscription data we can replace the input value with
    /// @param _returnValues Array of subscription data we can replace the input value with
    function _parseParamAddr(
        address _param,
        uint8 _mapType,
        bytes32[] memory _subData,
        bytes32[] memory _returnValues
    ) internal view returns (address) {
        if (isReplaceable(_mapType)) {
            if (isReturnInjection(_mapType)) {
                _param = address(bytes20((_returnValues[getReturnIndex(_mapType)])));
            } else {
                /// @dev The last two values are specially reserved for proxy addr and owner addr
                if (_mapType == 254) return address(this); // wallet address
                if (_mapType == 255) return fetchOwnersOrWallet(); // owner if 1/1 wallet or the wallet itself

                _param = address(uint160(uint256(_subData[getSubIndex(_mapType)])));
            }
        }

        return _param;
    }

    /// @notice Given an bytes32 input, injects return/sub values if specified
    /// @param _param The original input value
    /// @param _mapType Indicated the type of the input in paramMapping
    /// @param _subData Array of subscription data we can replace the input value with
    /// @param _returnValues Array of subscription data we can replace the input value with
    function _parseParamABytes32(
        bytes32 _param,
        uint8 _mapType,
        bytes32[] memory _subData,
        bytes32[] memory _returnValues
    ) internal pure returns (bytes32) {
        if (isReplaceable(_mapType)) {
            if (isReturnInjection(_mapType)) {
                _param = (_returnValues[getReturnIndex(_mapType)]);
            } else {
                _param = _subData[getSubIndex(_mapType)];
            }
        }

        return _param;
    }

    /// @notice Checks if the paramMapping value indicated that we need to inject values
    /// @param _type Indicated the type of the input
    function isReplaceable(uint8 _type) internal pure returns (bool) {
        return _type != NO_PARAM_MAPPING;
    }

    /// @notice Checks if the paramMapping value is in the return value range
    /// @param _type Indicated the type of the input
    function isReturnInjection(uint8 _type) internal pure returns (bool) {
        return (_type >= RETURN_MIN_INDEX_VALUE) && (_type <= RETURN_MAX_INDEX_VALUE);
    }

    /// @notice Transforms the paramMapping value to the index in return array value
    /// @param _type Indicated the type of the input
    function getReturnIndex(uint8 _type) internal pure returns (uint8) {
        if (!(isReturnInjection(_type))){
            revert SubIndexValueError();
        }

        return (_type - RETURN_MIN_INDEX_VALUE);
    }

    /// @notice Transforms the paramMapping value to the index in sub array value
    /// @param _type Indicated the type of the input
    function getSubIndex(uint8 _type) internal pure returns (uint8) {
        if (_type < SUB_MIN_INDEX_VALUE){
            revert ReturnIndexValueError();
        }
        return (_type - SUB_MIN_INDEX_VALUE);
    }

    function fetchOwnersOrWallet() internal view returns (address) {
        if (isDSProxy(address(this))) 
            return DSProxy(payable(address(this))).owner();

        // if not DSProxy, we assume we are in context of Safe
        address[] memory owners = ISafe(address(this)).getOwners();
        return owners.length == 1 ? owners[0] : address(this);
    }
}







abstract contract DSGuard {
    function canCall(
        address src_,
        address dst_,
        bytes4 sig
    ) public view virtual returns (bool);

    function permit(
        bytes32 src,
        bytes32 dst,
        bytes32 sig
    ) public virtual;

    function forbid(
        bytes32 src,
        bytes32 dst,
        bytes32 sig
    ) public virtual;

    function permit(
        address src,
        address dst,
        bytes32 sig
    ) public virtual;

    function forbid(
        address src,
        address dst,
        bytes32 sig
    ) public virtual;
}

abstract contract DSGuardFactory {
    function newGuard() public virtual returns (DSGuard guard);
}









contract DSProxyPermission is AuthHelper {

    bytes4 public constant EXECUTE_SELECTOR = bytes4(keccak256("execute(address,bytes)"));

    /// @notice Called in the context of DSProxy to authorize an address
    /// @param _contractAddr Address which will be authorized
    function giveProxyPermission(address _contractAddr) public {
        address currAuthority = address(DSAuth(address(this)).authority());
        DSGuard guard = DSGuard(currAuthority);

        if (currAuthority == address(0)) {
            guard = DSGuardFactory(DSGUARD_FACTORY_ADDRESS).newGuard();
            DSAuth(address(this)).setAuthority(DSAuthority(address(guard)));
        }

        if (!guard.canCall(_contractAddr, address(this), EXECUTE_SELECTOR)) {
            guard.permit(_contractAddr, address(this), EXECUTE_SELECTOR);
        }
    }

    /// @notice Called in the context of DSProxy to remove authority of an address
    /// @param _contractAddr Auth address which will be removed from authority list
    function removeProxyPermission(address _contractAddr) public {
        address currAuthority = address(DSAuth(address(this)).authority());

        // if there is no authority, that means that contract doesn't have permission
        if (currAuthority == address(0)) {
            return;
        }

        DSGuard guard = DSGuard(currAuthority);
        guard.forbid(_contractAddr, address(this), EXECUTE_SELECTOR);
    }
}








contract SafeModulePermission {

    address public constant SENTINEL_MODULES = address(0x1);

    /// @notice Called in the context of Safe to authorize module
    /// @param _moduleAddr Address of module which will be authorized
    /// @dev Can't enable the same module twice
    function enableModule(address _moduleAddr) public {
        if(!ISafe(address(this)).isModuleEnabled(_moduleAddr)) {
            ISafe(address(this)).enableModule(_moduleAddr);
        }
    }

    /// @notice Called in the context of Safe to remove authority of module
    /// @param _moduleAddr Address of module which will be removed from authority list
    function disableLastModule(address _moduleAddr) public {
        ISafe(address(this)).disableModule(SENTINEL_MODULES, _moduleAddr);
    }
}







contract ArbitrumCoreAddresses {
    address internal constant REGISTRY_ADDR = 0xBF1CaC12DB60819Bfa71A328282ecbc1D40443aA;
    address internal constant DEFISAVER_LOGGER = 0xE6f9A5C850dbcD12bc64f40d692F537250aDEC38;
    address internal constant MODULE_AUTH_ADDR = 0xb3D6b7F561C1F250bF7f0F00eFD19FAE6cE533dd;

    address internal constant RECIPE_EXECUTOR_ADDR = 0xe775c59e5662597bcE8aB4432C06380709554883;
    address internal constant SUB_STORAGE_ADDR = 0x24ab68395660b910BfBF1cc88BaA316BA06354eE;
    address internal constant BUNDLE_STORAGE_ADDR = 0x8332F2a50A9a6C85a476e1ea33031681291cB694;
    address internal constant STRATEGY_STORAGE_ADDR = 0x6aeA695fcd0655650323e9dc5f80Ac0b15A91Da2;

    address internal constant PROXY_AUTH_ADDR = 0xF3A8479538319756e100C386b3E60BF783680d8f;
}







contract CoreHelper is ArbitrumCoreAddresses {
}









contract StrategyModel {
        
    /// @dev Group of strategies bundled together so user can sub to multiple strategies at once
    /// @param creator Address of the user who created the bundle
    /// @param strategyIds Array of strategy ids stored in StrategyStorage
    struct StrategyBundle {
        address creator;
        uint64[] strategyIds;
    }

    /// @dev Template/Class which defines a Strategy
    /// @param name Name of the strategy useful for logging what strategy is executing
    /// @param creator Address of the user which created the strategy
    /// @param triggerIds Array of identifiers for trigger - bytes4(keccak256(TriggerName))
    /// @param actionIds Array of identifiers for actions - bytes4(keccak256(ActionName))
    /// @param paramMapping Describes how inputs to functions are piped from return/subbed values
    /// @param continuous If the action is repeated (continuos) or one time
    struct Strategy {
        string name;
        address creator;
        bytes4[] triggerIds;
        bytes4[] actionIds;
        uint8[][] paramMapping;
        bool continuous;
    }

    /// @dev List of actions grouped as a recipe
    /// @param name Name of the recipe useful for logging what recipe is executing
    /// @param callData Array of calldata inputs to each action
    /// @param subData Used only as part of strategy, subData injected from StrategySub.subData
    /// @param actionIds Array of identifiers for actions - bytes4(keccak256(ActionName))
    /// @param paramMapping Describes how inputs to functions are piped from return/subbed values
    struct Recipe {
        string name;
        bytes[] callData;
        bytes32[] subData;
        bytes4[] actionIds;
        uint8[][] paramMapping;
    }

    /// @dev Actual data of the sub we store on-chain
    /// @dev In order to save on gas we store a keccak256(StrategySub) and verify later on
    /// @param walletAddr Address of the users smart wallet/proxy
    /// @param isEnabled Toggle if the subscription is active
    /// @param strategySubHash Hash of the StrategySub data the user inputted
    struct StoredSubData {
        bytes20 walletAddr; // address but put in bytes20 for gas savings
        bool isEnabled;
        bytes32 strategySubHash;
    }

    /// @dev Instance of a strategy, user supplied data
    /// @param strategyOrBundleId Id of the strategy or bundle, depending on the isBundle bool
    /// @param isBundle If true the id points to bundle, if false points directly to strategyId
    /// @param triggerData User supplied data needed for checking trigger conditions
    /// @param subData User supplied data used in recipe
    struct StrategySub {
        uint64 strategyOrBundleId;
        bool isBundle;
        bytes[] triggerData;
        bytes32[] subData;
    }
}









contract StrategyStorage is StrategyModel, AdminAuth {

    Strategy[] public strategies;
    bool public openToPublic = false;

    error NoAuthToCreateStrategy(address,bool);
    event StrategyCreated(uint256 indexed strategyId);

    modifier onlyAuthCreators {
        if (adminVault.owner() != msg.sender && openToPublic == false) {
            revert NoAuthToCreateStrategy(msg.sender, openToPublic);
        }

        _;
    }

    /// @notice Creates a new strategy and writes the data in an array
    /// @dev Can only be called by auth addresses if it's not open to public
    /// @param _name Name of the strategy useful for logging what strategy is executing
    /// @param _triggerIds Array of identifiers for trigger - bytes4(keccak256(TriggerName))
    /// @param _actionIds Array of identifiers for actions - bytes4(keccak256(ActionName))
    /// @param _paramMapping Describes how inputs to functions are piped from return/subbed values
    /// @param _continuous If the action is repeated (continuos) or one time
    function createStrategy(
        string memory _name,
        bytes4[] memory _triggerIds,
        bytes4[] memory _actionIds,
        uint8[][] memory _paramMapping,
        bool _continuous
    ) public onlyAuthCreators returns (uint256) {
        strategies.push(Strategy({
                name: _name,
                creator: msg.sender,
                triggerIds: _triggerIds,
                actionIds: _actionIds,
                paramMapping: _paramMapping,
                continuous : _continuous
        }));

        emit StrategyCreated(strategies.length - 1);

        return strategies.length - 1;
    }

    /// @notice Switch to determine if bundles can be created by anyone
    /// @dev Callable only by the owner
    /// @param _openToPublic Flag if true anyone can create bundles
    function changeEditPermission(bool _openToPublic) public onlyOwner {
        openToPublic = _openToPublic;
    }

    ////////////////////////////// VIEW METHODS /////////////////////////////////

    function getStrategy(uint _strategyId) public view returns (Strategy memory) {
        return strategies[_strategyId];
    }
    function getStrategyCount() public view returns (uint256) {
        return strategies.length;
    }

    function getPaginatedStrategies(uint _page, uint _perPage) public view returns (Strategy[] memory) {
        Strategy[] memory strategiesPerPage = new Strategy[](_perPage);

        uint start = _page * _perPage;
        uint end = start + _perPage;

        end = (end > strategies.length) ? strategies.length : end;

        uint count = 0;
        for (uint i = start; i < end; i++) {
            strategiesPerPage[count] = strategies[i];
            count++;
        }

        return strategiesPerPage;
    }

}












contract BundleStorage is StrategyModel, AdminAuth, CoreHelper {

    DFSRegistry public constant registry = DFSRegistry(REGISTRY_ADDR);

    StrategyBundle[] public bundles;
    bool public openToPublic = false;

    error NoAuthToCreateBundle(address,bool);
    error DiffTriggersInBundle(uint64[]);

    event BundleCreated(uint256 indexed bundleId);

    modifier onlyAuthCreators {
        if (adminVault.owner() != msg.sender && openToPublic == false) {
            revert NoAuthToCreateBundle(msg.sender, openToPublic);
        }

        _;
    }

    /// @dev Checks if the triggers in strategies are the same (order also relevant)
    /// @dev If the caller is not owner we do additional checks, we skip those checks for gas savings
    modifier sameTriggers(uint64[] memory _strategyIds) {
        if (msg.sender != adminVault.owner()) {
            Strategy memory firstStrategy = StrategyStorage(STRATEGY_STORAGE_ADDR).getStrategy(_strategyIds[0]);

            bytes32 firstStrategyTriggerHash = keccak256(abi.encode(firstStrategy.triggerIds));

            for (uint256 i = 1; i < _strategyIds.length; ++i) {
                Strategy memory s = StrategyStorage(STRATEGY_STORAGE_ADDR).getStrategy(_strategyIds[i]);

                if (firstStrategyTriggerHash != keccak256(abi.encode(s.triggerIds))) {
                    revert DiffTriggersInBundle(_strategyIds);
                }
            }
        }

        _;
    }

    /// @notice Adds a new bundle to array
    /// @dev Can only be called by auth addresses if it's not open to public
    /// @dev Strategies need to have the same number of triggers and ids exists
    /// @param _strategyIds Array of strategyIds that go into a bundle
    function createBundle(
        uint64[] memory _strategyIds
    ) public onlyAuthCreators sameTriggers(_strategyIds) returns (uint256) {

        bundles.push(StrategyBundle({
            creator: msg.sender,
            strategyIds: _strategyIds
        }));

        emit BundleCreated(bundles.length - 1);

        return bundles.length - 1;
    }

    /// @notice Switch to determine if bundles can be created by anyone
    /// @dev Callable only by the owner
    /// @param _openToPublic Flag if true anyone can create bundles
    function changeEditPermission(bool _openToPublic) public onlyOwner {
        openToPublic = _openToPublic;
    }

    ////////////////////////////// VIEW METHODS /////////////////////////////////

    function getStrategyId(uint256 _bundleId, uint256 _strategyIndex) public view returns (uint256) {
        return bundles[_bundleId].strategyIds[_strategyIndex];
    }

    function getBundle(uint _bundleId) public view returns (StrategyBundle memory) {
        return bundles[_bundleId];
    }
    function getBundleCount() public view returns (uint256) {
        return bundles.length;
    }

    function getPaginatedBundles(uint _page, uint _perPage) public view returns (StrategyBundle[] memory) {
        StrategyBundle[] memory bundlesPerPage = new StrategyBundle[](_perPage);
        uint start = _page * _perPage;
        uint end = start + _perPage;

        end = (end > bundles.length) ? bundles.length : end;

        uint count = 0;
        for (uint i = start; i < end; i++) {
            bundlesPerPage[count] = bundles[i];
            count++;
        }

        return bundlesPerPage;
    }

}












contract SubStorage is StrategyModel, AdminAuth, CoreHelper {
    error SenderNotSubOwnerError(address, uint256);
    error SubIdOutOfRange(uint256, bool);

    event Subscribe(uint256 indexed subId, address indexed walletAddr, bytes32 indexed subHash, StrategySub subStruct);
    event UpdateData(uint256 indexed subId, bytes32 indexed subHash, StrategySub subStruct);
    event ActivateSub(uint256 indexed subId);
    event DeactivateSub(uint256 indexed subId);

    DFSRegistry public constant registry = DFSRegistry(REGISTRY_ADDR);

    StoredSubData[] public strategiesSubs;

    /// @notice Checks if subId is init. and if the sender is the owner
    modifier onlySubOwner(uint256 _subId) {
        if (address(strategiesSubs[_subId].walletAddr) != msg.sender) {
            revert SenderNotSubOwnerError(msg.sender, _subId);
        }
        _;
    }

    /// @notice Checks if the id is valid (points to a stored bundle/sub)
    modifier isValidId(uint256 _id, bool _isBundle) {
        if (_isBundle) {
            if (_id > (BundleStorage(BUNDLE_STORAGE_ADDR).getBundleCount() - 1)) {
                revert SubIdOutOfRange(_id, _isBundle);
            }
        } else {
            if (_id > (StrategyStorage(STRATEGY_STORAGE_ADDR).getStrategyCount() - 1)) {
                revert SubIdOutOfRange(_id, _isBundle);
            }
        }

        _;
    }

    /// @notice Adds users info and records StoredSubData, logs StrategySub
    /// @dev To save on gas we don't store the whole struct but rather the hash of the struct
    /// @param _sub Subscription struct of the user (is not stored on chain, only the hash)
    function subscribeToStrategy(
        StrategySub memory _sub
    ) public isValidId(_sub.strategyOrBundleId, _sub.isBundle) returns (uint256) {

        bytes32 subStorageHash = keccak256(abi.encode(_sub));

        strategiesSubs.push(StoredSubData(
            bytes20(msg.sender),
            true,
            subStorageHash
        ));

        uint256 currentId = strategiesSubs.length - 1;

        emit Subscribe(currentId, msg.sender, subStorageHash, _sub);

        return currentId;
    }

    /// @notice Updates the users subscription data
    /// @dev Only callable by wallet who created the sub.
    /// @param _subId Id of the subscription to update
    /// @param _sub Subscription struct of the user (needs whole struct so we can hash it)
    function updateSubData(
        uint256 _subId,
        StrategySub calldata _sub
    ) public onlySubOwner(_subId) isValidId(_sub.strategyOrBundleId, _sub.isBundle)  {
        StoredSubData storage storedSubData = strategiesSubs[_subId];

        bytes32 subStorageHash = keccak256(abi.encode(_sub));

        storedSubData.strategySubHash = subStorageHash;

        emit UpdateData(_subId, subStorageHash, _sub);
    }

    /// @notice Enables the subscription for execution if disabled
    /// @dev Must own the sub. to be able to enable it
    /// @param _subId Id of subscription to enable
    function activateSub(
        uint _subId
    ) public onlySubOwner(_subId) {
        StoredSubData storage sub = strategiesSubs[_subId];

        sub.isEnabled = true;

        emit ActivateSub(_subId);
    }

    /// @notice Disables the subscription (will not be able to execute the strategy for the user)
    /// @dev Must own the sub. to be able to disable it
    /// @param _subId Id of subscription to disable
    function deactivateSub(
        uint _subId
    ) public onlySubOwner(_subId) {
        StoredSubData storage sub = strategiesSubs[_subId];

        sub.isEnabled = false;

        emit DeactivateSub(_subId);
    }

    ///////////////////// VIEW ONLY FUNCTIONS ////////////////////////////

    function getSub(uint _subId) public view returns (StoredSubData memory) {
        return strategiesSubs[_subId];
    }

    function getSubsCount() public view returns (uint256) {
        return strategiesSubs.length;
    }
}






abstract contract IFlashLoanBase{
    
    struct FlashLoanParams {
        address[] tokens;
        uint256[] amounts;
        uint256[] modes;
        address onBehalfOf;
        address flParamGetterAddr;
        bytes flParamGetterData;
        bytes recipeData;
    }
}






abstract contract ITrigger {
    function isTriggered(bytes memory, bytes memory) public virtual returns (bool);
    function isChangeable() public virtual returns (bool);
    function changedSubData(bytes memory) public virtual returns (bytes memory);
}

















/**
* @title Entry point into executing recipes/checking triggers directly and as part of a strategy
* @dev RecipeExecutor can be used in two scenarios:
* 1) Execute a recipe manually through user's wallet by calling executeRecipe()
*    Here, users can also execute a recipe with a flash loan action. To save on space, the flow will be explained in the next scenario
*
*                                                                                                                       ┌────────────────┐
*                                                                                                                   ┌───┤  1st Action    │
*                                                                                                                   │   └────────────────┘
*                                                                                                                   │
*   Actor                    ┌──────────────┐                    ┌────────────────┐                                 │   ┌────────────────┐
*    ┌─┐                     │              │   Delegate call    │                │    Delegate call each action    ├───┤  2nd Action    │
*    └┼┘                     │              │   - executeRecipe()│                │         - executeAction()       │   └────────────────┘
*  ── │ ──  ─────────────────┤ Smart Wallet ├────────────────────┤ Recipe Executor├─────────────────────────────────┤
*    ┌┴┐                     │              │                    │                │                                 │    . . .
*    │ │                     │              │                    │                │                                 │
*                            └──────────────┘                    └────────────────┘                                 │   ┌────────────────┐
*                                                                                                                   └───┤  nth Action    │
*                                                                                                                       └────────────────┘
*
* 
* 2) Execute a recipe as part of a defi saver strategy system
*
*                             check:
*                             - bot is approved                           check:                 ┌───────────────────────┐
*                             - sub data hash                             msg.sender =           │  SafeModuleAuth       │
*                             - sub is enabled                            strategyExecutor       │ - call tx on safe     │
*  ┌─────┐  executeStrategy() ┌──────────────────┐       callExecute()    ┌────────────┐    IS   │   wallet from module  │
*  │ Bot ├───────────────────►│ StrategyExecutor ├───────────────────────►│   IAuth    ├─────────┼───────────────────────┼────┐
*  └─────┘  pass params:      └──────────────────┘                        └────────────┘         │  ProxyAuth            │    │
*          - subId                                                      user gives permission    │ - call execute on     │    │
*          - strategyIndex                                              to Auth contract to      │   DSProxy             │    │
*          - triggerCallData[]                                          execute tx through       └───────────────────────┘    │
*          - actionsCallData[]                                          smart wallet                                          │
*          - SubscriptionData                                                                                                 │
*                                                                                                                             │
*                                                                                                ┌────────────────────────┐   │
*                                                                                                │      Smart Wallet      │◄──┴─────────────────┐
*                   ┌──────────────┐                                                             └───────────┬────────────┘                     │
*                   │  1st Action  ├───┐                                                                     │            ▲                     │
*                   └──────────────┘   │                                                                     │Delegate    └──────────────────┐  │
*                                      │    Delegate call                                                    │  call                         │  │
*                   ┌──────────────┐   │    each action                   ┌────────────┐                     ▼                               │  │
*                   │  2nd Action  │   │    - executeAction() ┌──┐        │1st Action  │         ┌────────────────────────┐                  │  │
*                   └──────────────┘   ├──────────────────────┤NO├────────┤is Flashloan├─────────┤     Recipe Executor    │                  │  │
*                          ...         │                      └──┘        │  Action?   │         └────────────────────────┘                  │  │
*                   ┌──────────────┐   │                                  └──────┬─────┘              check if triggers                      │  │
*                   │  nth Action  ├───┘                    ┌───────┐            │                       are valid                           │  │
*                   └──────────────┘            ┌───────────┤  YES  ├────────────┘                                                           │  │
*                                               │           └───────┘                                                                        │  │
*                                               ▼                                                                                            │  │
*                                        ┌──────────────┐       giveWalletPermission             ┌────────────────────────┐                  │  │
*                                        │              ├───────────────────────────────────────►│       Permission       │                  │  │
*                                        │              │                                        └────────────────────────┘                  │  │
*                                        │              │                                  -for safe -> enable FL action as module           │  │
*                                        │              │                                  -for dsproxy -> enable FL action to call execute  │  │
*                                        │              │                                                                                    │  │
*                                        │              │                                                                                    │  │
*                                        │              │                          ┌────────┐      Borrow funds    ┌────────┐                │  │
*                                        │              │                          │        ├─────────────────────►│External│                │  │
*                                        │              │                          │        │      Callback fn     │   FL   │                │  │
*                                        │              │                          │        │◄─────────────────────┤ Source │                │  │
*                                        │              │                          │        │                      └────────┘                │  │
*                                        │              │                          │        │                                                │  │
*                                        │              │                          │        ├────────────────────────────────────────────────┘  │
*                                        │   parse FL   │   directly call:         │   FL   │      Send borrowed funds to smart wallet          │
*                                        │     and      │   executeAction()        │ Action │                                                   │
*                                        │   execute    ├─────────────────────────►│        │                                                   │
*                                        │              │                          │        │      Call back the _executeActionsFromFL on       │
*                                        │              │                          │        │      RecipeExecutor through Smart Wallet.         │
*                                        │              │                          │        │      We can call wallet from FL action because    │
*                                        │              │                          │        │      we gave it approval earlier.                 │
*                                        │              │                          │        │      Actions are executed as regular starting     │
*                                        │              │                          │        │      from second action.                          │
*                                        │              │                          │        ├───────────────────────────────────────────────────┘
*                                        │              │                          │        │
*                                        │              │                          └────┬───┘                      ┌────────┐
*                                        │              │                               │    Return borrowed funds │External│
*                                        │              │                               └─────────────────────────►│   FL   │
*                                        │              │                                                          │ Source │
*                                        │              │                                                          └────────┘
*                                        │              │
*                                        │              │
*                                        │              │       removeWalletPermission            ┌────────────────────────┐
*                                        │              ├────────────────────────────────────────►│       Permission       │
*                                        │              │                                         └────────────────────────┘
*                                        └──────────────┘
*
*
*
*/
contract RecipeExecutor is StrategyModel, DSProxyPermission, SafeModulePermission, AdminAuth, CoreHelper, CheckWalletType {
    DFSRegistry public constant registry = DFSRegistry(REGISTRY_ADDR);

    /// @dev Function sig of ActionBase.executeAction()
    bytes4 public constant EXECUTE_ACTION_SELECTOR = 
        bytes4(keccak256("executeAction(bytes,bytes32[],uint8[],bytes32[])"));

    /// For strategy execution all triggers must be active
    error TriggerNotActiveError(uint256);

    /// @notice Called directly through user wallet to execute a recipe
    /// @dev This is the main entry point for Recipes executed manually
    /// @param _currRecipe Recipe to be executed
    function executeRecipe(Recipe calldata _currRecipe) public payable {
        _executeActions(_currRecipe);
    }

    /// @notice Called by user wallet through the auth contract to execute a recipe & check triggers
    /// @param _subId Id of the subscription we want to execute
    /// @param _actionCallData All input data needed to execute actions
    /// @param _triggerCallData All input data needed to check triggers
    /// @param _strategyIndex Which strategy in a bundle, need to specify because when sub is part of a bundle
    /// @param _sub All the data related to the strategies Recipe
    function executeRecipeFromStrategy(
        uint256 _subId,
        bytes[] calldata _actionCallData,
        bytes[] calldata _triggerCallData,
        uint256 _strategyIndex,
        StrategySub memory _sub
    ) public payable {
        Strategy memory strategy;

        {   // to handle stack too deep
            uint256 strategyId = _sub.strategyOrBundleId;

            // fetch strategy if inside of bundle
            if (_sub.isBundle) {
                strategyId = BundleStorage(BUNDLE_STORAGE_ADDR).getStrategyId(strategyId, _strategyIndex);
            }

            strategy = StrategyStorage(STRATEGY_STORAGE_ADDR).getStrategy(strategyId);
        }

        // check if all the triggers are true
        (bool triggered, uint256 errIndex) 
            = _checkTriggers(strategy, _sub, _triggerCallData, _subId, SUB_STORAGE_ADDR);
        
        if (!triggered) {
            revert TriggerNotActiveError(errIndex);
        }

        // if this is a one time strategy
        if (!strategy.continuous) {
            SubStorage(SUB_STORAGE_ADDR).deactivateSub(_subId);
        }

        // format recipe from strategy
        Recipe memory currRecipe = Recipe({
            name: strategy.name,
            callData: _actionCallData,
            subData: _sub.subData,
            actionIds: strategy.actionIds,
            paramMapping: strategy.paramMapping
        });

        _executeActions(currRecipe);
    }

    /// @notice Checks if all the triggers are true
    function _checkTriggers(
        Strategy memory strategy,
        StrategySub memory _sub,
        bytes[] calldata _triggerCallData,
        uint256 _subId,
        address _storageAddr
    ) internal returns (bool, uint256) {
        bytes4[] memory triggerIds = strategy.triggerIds;

        bool isTriggered;
        address triggerAddr;
        uint256 i;

        for (i = 0; i < triggerIds.length; ++i) {
            triggerAddr = registry.getAddr(triggerIds[i]);

            isTriggered = ITrigger(triggerAddr).isTriggered(
                _triggerCallData[i],
                _sub.triggerData[i]
            );

            if (!isTriggered) return (false, i);

            // after execution triggers flag-ed changeable can update their value
            if (ITrigger(triggerAddr).isChangeable()) {
                _sub.triggerData[i] = ITrigger(triggerAddr).changedSubData(_sub.triggerData[i]);
                SubStorage(_storageAddr).updateSubData(_subId, _sub);
            }
        }

        return (true, i);
    }

    /// @notice This is the callback function that FL actions call
    /// @dev FL function must be the first action and repayment is done last
    /// @param _currRecipe Recipe to be executed
    /// @param _flAmount Result value from FL action
    function _executeActionsFromFL(Recipe calldata _currRecipe, bytes32 _flAmount) public payable {
        bytes32[] memory returnValues = new bytes32[](_currRecipe.actionIds.length);
        returnValues[0] = _flAmount; // set the flash loan action as first return value

        // skips the first actions as it was the fl action
        for (uint256 i = 1; i < _currRecipe.actionIds.length; ++i) {
            returnValues[i] = _executeAction(_currRecipe, i, returnValues);
        }
    }

    /// @notice Runs all actions from the recipe
    /// @dev FL action must be first and is parsed separately, execution will go to _executeActionsFromFL
    /// @param _currRecipe Recipe to be executed
    function _executeActions(Recipe memory _currRecipe) internal {
        address firstActionAddr = registry.getAddr(_currRecipe.actionIds[0]);

        bytes32[] memory returnValues = new bytes32[](_currRecipe.actionIds.length);

        if (isFL(firstActionAddr)) {
             _parseFLAndExecute(_currRecipe, firstActionAddr, returnValues);
        } else {
            for (uint256 i = 0; i < _currRecipe.actionIds.length; ++i) {
                returnValues[i] = _executeAction(_currRecipe, i, returnValues);
            }
        }

        /// log the recipe name
        DefisaverLogger(DEFISAVER_LOGGER).logRecipeEvent(_currRecipe.name);
    }

    /// @notice Gets the action address and executes it
    /// @dev We delegate context of user's wallet to action contract
    /// @param _currRecipe Recipe to be executed
    /// @param _index Index of the action in the recipe array
    /// @param _returnValues Return values from previous actions
    function _executeAction(
        Recipe memory _currRecipe,
        uint256 _index,
        bytes32[] memory _returnValues
    ) internal returns (bytes32 response) {

        address actionAddr = registry.getAddr(_currRecipe.actionIds[_index]);

        response = delegateCallAndReturnBytes32(
            actionAddr, 
            abi.encodeWithSelector(
                EXECUTE_ACTION_SELECTOR,
                _currRecipe.callData[_index],
                _currRecipe.subData,
                _currRecipe.paramMapping[_index],
                _returnValues
            )
        );
    }

    /// @notice Prepares and executes a flash loan action
    /// @dev It adds to the first input value of the FL, the recipe data so it can be passed on
    /// @dev FL action is executed directly, so we need to give it permission to call back RecipeExecutor in context of user's wallet
    /// @param _currRecipe Recipe to be executed
    /// @param _flActionAddr Address of the flash loan action
    /// @param _returnValues An empty array of return values, because it's the first action
    function _parseFLAndExecute(
        Recipe memory _currRecipe,
        address _flActionAddr,
        bytes32[] memory _returnValues
    ) internal {

        bool isDSProxy = isDSProxy(address(this));

        isDSProxy ? giveProxyPermission(_flActionAddr) : enableModule(_flActionAddr);

        // encode data for FL
        bytes memory recipeData = abi.encode(_currRecipe, address(this));
        IFlashLoanBase.FlashLoanParams memory params = abi.decode(
            _currRecipe.callData[0],
            (IFlashLoanBase.FlashLoanParams)
        );
        params.recipeData = recipeData;
        _currRecipe.callData[0] = abi.encode(params);

        /// @dev FL action is called directly so that we can check who the msg.sender of FL is
        ActionBase(_flActionAddr).executeAction(
            _currRecipe.callData[0],
            _currRecipe.subData,
            _currRecipe.paramMapping[0],
            _returnValues
        );

        isDSProxy ? removeProxyPermission(_flActionAddr) : disableLastModule(_flActionAddr);
    }

    /// @notice Checks if the specified address is of FL type action
    /// @param _actionAddr Address of the action
    function isFL(address _actionAddr) internal pure returns (bool) {
        return ActionBase(_actionAddr).actionType() == uint8(ActionBase.ActionType.FL_ACTION);
    }

    function delegateCallAndReturnBytes32(address _target, bytes memory _data) internal returns (bytes32 response) {
        require(_target != address(0));

        // call contract in current context
        assembly {
            let succeeded := delegatecall(sub(gas(), 5000), _target, add(_data, 0x20), mload(_data), 0, 32)
            
            // load delegatecall output
            response := mload(0)
            
            // throw if delegatecall failed
            if eq(succeeded, 0) {
                revert(0, 0)
            }
        }
    }
}