// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "./Vault.sol";
import "./Controller.sol";
import "./interfaces/IPlugin.sol";

// imports
import "@openzeppelin/contracts/access/Ownable.sol";
import "@layerzerolabs/solidity-examples/contracts/interfaces/ILayerZeroReceiver.sol";
import "@layerzerolabs/solidity-examples/contracts/interfaces/ILayerZeroEndpoint.sol";
import "@layerzerolabs/solidity-examples/contracts/interfaces/ILayerZeroUserApplicationConfig.sol";


contract MozBridge is Ownable, ILayerZeroReceiver, ILayerZeroUserApplicationConfig {
    //---------------------------------------------------------------------------
    // CONSTANTS
    uint16 internal constant TYPE_REQUEST_SNAPSHOT = 1;
    uint16 internal constant TYPE_REPORT_SNAPSHOT  = 2;
    uint16 internal constant TYPE_REQUEST_SETTLE   = 3;
    uint16 internal constant TYPE_REPORT_SETTLE    = 4;
    uint16 internal constant TYPE_STAKE_ASSETS     = 5;
    uint16 internal constant TYPE_UNSTAKE_ASSETS   = 6;

    uint16 internal constant TYPE_ACTION_RETRY = 7;
    uint16 internal constant TYPE_SNAPSHOT_RETRY = 8;
    uint16 internal constant TYPE_SETTLE_RETRY = 9;
    uint16 internal constant TYPE_REPORT_SNAPSHOT_RETRY = 10;
    uint16 internal constant TYPE_REPORT_SETTLE_RETRY = 11;

    //---------------------------------------------------------------------------
    // STRUCTS
    struct LzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    struct Snapshot {
        uint256 depositRequestAmount;
        uint256 withdrawRequestAmountMLP;
        uint256 totalStablecoin;
        uint256 totalMozaicLp; // Mozaic "LP"
        uint256[] amounts;
    }

    //---------------------------------------------------------------------------
    // VARIABLES
    ILayerZeroEndpoint public immutable layerZeroEndpoint;
    
    uint16 public immutable mainChainId;

    Vault public  vault;
    
    Controller public controller;
    
    mapping(uint16 => bytes) public bridgeLookup;
    
    mapping(uint16 => mapping(uint16 => uint256)) public gasLookup;
    
    bool public useLayerZeroToken;
    
    //---------------------------------------------------------------------------
    // EVENTS
    event ReceiveMsg(
        uint16 _srcChainId,
        address _from,
        uint16 _funType,
        bytes _payload
    );

    event SendMsg(
        uint16 _chainId,
        uint16 _type,
        bytes lookup
    );

    event Revert(
        uint16 bridgeFunctionType,
        uint16 chainId,
        bytes srcAddress,
        uint256 nonce
    );

    //---------------------------------------------------------------------------
    // MODIFIERS
    modifier onlyVault() {
        require(msg.sender == address(vault), "MozBridge: Not vault");
        _;
    }
    modifier onlyController() {
        require(msg.sender == address(controller), "MozBridge: Not controller");
        _;
    }

    //---------------------------------------------------------------------------
    // CONSTRUCTOR
    constructor(
        address _lzEndpoint,
        uint16 _mainchainId
    ) {
        require(_mainchainId > 0, "MozBridge: Invalid chainID");
        require(_lzEndpoint != address(0x0), "MozBridge: _lzEndpoint cannot be 0x0");
        layerZeroEndpoint = ILayerZeroEndpoint(_lzEndpoint);
        mainChainId = _mainchainId;
    }

    //---------------------------------------------------------------------------
    // EXTERNAL FUNCTIONS

    function lzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) external override {
        require(msg.sender == address(layerZeroEndpoint), "MozBridge: only LayerZero endpoint can call lzReceive");
        require(
            _srcAddress.length == bridgeLookup[_srcChainId].length && keccak256(_srcAddress) == keccak256(bridgeLookup[_srcChainId]),
            "MozBridge: bridge does not match"
        );

        address from;
        assembly {
            from := mload(add(_srcAddress, 20))
        }

        uint16 functionType;
        assembly {
            functionType := mload(add(_payload, 32))
        }

        if (functionType == TYPE_REQUEST_SNAPSHOT) {
            require(_srcChainId == mainChainId, "MozBridge: message must come from main chain");
            ( ,uint256 _updateNum) = abi.decode(_payload, (uint16,  uint256));
            try vault.reportSnapshot(_srcChainId, _srcAddress, _nonce, _updateNum) {
            } catch {
                bytes memory payload = abi.encode(TYPE_SNAPSHOT_RETRY, _updateNum);
                vault.setRevertLookup(_srcChainId, _srcAddress, _nonce, payload);
                emit Revert(TYPE_SNAPSHOT_RETRY, _srcChainId, _srcAddress, _nonce);
            }
        } else if (functionType == TYPE_REPORT_SNAPSHOT) {
            ( , MozBridge.Snapshot memory _snapshot, uint256 _updateNum) = abi.decode(_payload, (uint16, MozBridge.Snapshot, uint256));
            controller.updateSnapshot(_srcChainId, _snapshot, _updateNum);
        } else if(functionType == TYPE_REQUEST_SETTLE) {
            require(_srcChainId == mainChainId, "MozBridge: message must come from main chain");
            ( , uint256 totalCoinMD, uint256 totalMLP, uint256 _updateNum) = abi.decode(_payload, (uint16, uint256, uint256, uint256));
            try vault.reportSettled(_srcChainId, _srcAddress, _nonce, totalCoinMD, totalMLP, _updateNum) {
            } catch {
                bytes memory payload = abi.encode(TYPE_SETTLE_RETRY, totalCoinMD, totalMLP, _updateNum);
                vault.setRevertLookup(_srcChainId, _srcAddress, _nonce, payload);
                emit Revert(TYPE_SETTLE_RETRY, _srcChainId, _srcAddress, _nonce);
            }
        } else if(functionType == TYPE_REPORT_SETTLE) {
            ( , uint256 _updateNum) = abi.decode(_payload, (uint16, uint256));
            controller.settleReport(_srcChainId, _updateNum);
        }else if (functionType == TYPE_STAKE_ASSETS) {
            ( , uint8 _pluginId, bytes memory __payload) = abi.decode(_payload, (uint16, uint8, bytes));
            vault.execute(_srcChainId, _srcAddress, _nonce, _pluginId, IPlugin.ActionType.Stake, __payload);
        } else if (functionType == TYPE_UNSTAKE_ASSETS) {
            ( , uint8 _pluginId, bytes memory __payload) = abi.decode(_payload, (uint16, uint8, bytes));
            vault.execute(_srcChainId, _srcAddress, _nonce, _pluginId, IPlugin.ActionType.Unstake, __payload);
        }

        emit ReceiveMsg(_srcChainId, from, functionType, _payload);
    }

    //------------------------------------CONFIGURATION------------------------------------
    
    // Set Local Vault
    function setVault(address _vault) external onlyOwner {
        require(_vault != address(0x0), "ERROR: Invaild address");
        vault = Vault(payable (_vault));
    }
    
    // Set Controller    
    function setController(address payable _controller) public onlyOwner {
        require(_controller != address(0), "ERROR: Invalid address");
        controller =  Controller(_controller);
    }

    //Set gas amount
    function setGasAmount(
        uint16 _chainId,
        uint16 _functionType,
        uint256 _gasAmount
    ) external onlyOwner {
        require(_functionType >= 1 && _functionType <= 6, "MozBridge: invalid _functionType");
        gasLookup[_chainId][_functionType] = _gasAmount;
    }

    // Set BridgeLookups
    function setBridge(uint16 _chainId, bytes calldata _bridgeAddress) external onlyOwner {
        require(_chainId > 0, "MozBridge: Set bridge error");
        bridgeLookup[_chainId] = _bridgeAddress;
    }

    // Clear the stored payload and resume
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external override onlyOwner {
        layerZeroEndpoint.forceResumeReceive(_srcChainId, _srcAddress);
    }

    // set if use layerzero token
    function setUseLayerZeroToken(bool enable) external onlyOwner {
        useLayerZeroToken = enable;
    }

    // generic config for user Application
    function setConfig(
        uint16 _version,
        uint16 _chainId,
        uint256 _configType,
        bytes calldata _config
    ) external override onlyOwner {
        layerZeroEndpoint.setConfig(_version, _chainId, _configType, _config);
    }

    function setSendVersion(uint16 version) external override onlyOwner {
        layerZeroEndpoint.setSendVersion(version);
    }

    function setReceiveVersion(uint16 version) external override onlyOwner {
        layerZeroEndpoint.setReceiveVersion(version);
    }

    //---------------------------------LOCAL CHAIN FUNCTIONS--------------------------------

    // Send snapshot request to local chains (Only called on Mainchain)
    function requestSnapshot(uint16 _dstChainId, uint256 _updateNum, address payable _refundAddress ) external payable onlyController {
        require(_dstChainId > 0, "MozBridge: Invalid ChainId");
        require(_refundAddress != address(0x0), "MozBridge: Invalid address");
        
        bytes memory payload = abi.encode(TYPE_REQUEST_SNAPSHOT, _updateNum);
        LzTxObj memory lzTxObj = LzTxObj(0, 0, "0x");
        _call(_dstChainId, TYPE_REQUEST_SNAPSHOT, payable(_refundAddress), lzTxObj, payload);
    }

    // Report snapshot details to Controller (Olny called on Localchains)
    function reportSnapshot(
        MozBridge.Snapshot memory _snapshot,
        uint256 _updateNum,
        address payable _refundAddress
        // Vault.Snapshot memory _snapshot
    ) external payable onlyVault {
        bytes memory payload = abi.encode(TYPE_REPORT_SNAPSHOT, _snapshot, _updateNum);
        LzTxObj memory lzTxObj = LzTxObj(0, 0, "0x");
        _call(mainChainId, TYPE_REPORT_SNAPSHOT, payable(_refundAddress), lzTxObj, payload);
    }

    // Send settle request to local chains (Only called on Mainchain)
    function requestSettle(uint16 _dstChainId, uint256  totalCoinMD, uint256 totalMLP, uint256 _updateNum, address payable _refundAddress ) external payable onlyController {
        require(_dstChainId > 0, "MozBridge: Invalid ChainId");
        require(_refundAddress != address(0x0), "MozBridge: Invalid address");
        
        bytes memory payload = abi.encode(TYPE_REQUEST_SETTLE, totalCoinMD, totalMLP, _updateNum);
        LzTxObj memory lzTxObj = LzTxObj(0, 0, "0x");
        _call(_dstChainId, TYPE_REQUEST_SETTLE, payable(_refundAddress), lzTxObj, payload);
    }

    // Send settle report to Controller (Only called on Localchains)
    function reportSettled(uint256 _updateNum, address payable _refundAddress ) external payable onlyVault {
        require(_refundAddress != address(0x0), "MozBridge: Invalid address");
        bytes memory payload = abi.encode(TYPE_REPORT_SETTLE, _updateNum);
        LzTxObj memory lzTxObj = LzTxObj(0, 0, "0x");
        _call(mainChainId, TYPE_REPORT_SETTLE, payable(_refundAddress), lzTxObj, payload);

    }

    // Send the execute request to plugin.
    function requestExecute(uint16 _dstChainId, uint8 _pluginId, uint16 executeType, bytes memory _payload, address payable _refundAddress) external payable onlyController {
        require(_dstChainId > 0, "MozBridge: Invalid ChainId");
        require(_refundAddress != address(0x0), "MozBridge: Invalid address");
        bytes memory payload = abi.encode(executeType, _pluginId, _payload);
        LzTxObj memory lzTxObj = LzTxObj(0, 0, "0x");
        _call(_dstChainId, executeType, payable(_refundAddress), lzTxObj, payload);
    }

    // Get and return the snapshot of the local vault
    // Used to get the snapshot of main chain
    // Only used in main chain Bridge
    function takeSnapshot() external onlyController returns (Snapshot memory) {
        return vault.takeSnapshot();
    }

    // Settle the deposit and withdraw requests of the mainchain vault
    // Used to settle requests of main chain
    // Only used in main chain Bridge
    function setSettle(uint256  totalCoinMD, uint256 totalMLP) external onlyController {
        vault.settleRequests(totalCoinMD, totalMLP);
    }

    // Execute the action in mainchain vault
    // Used to execute actions on main chain
    function execute(uint8 _pluginId, IPlugin.ActionType _actionType, bytes memory _payload) external onlyController() {
        vault.execute(mainChainId, bridgeLookup[mainChainId], 0, _pluginId, _actionType, _payload);
    }
    
    //---------------------------------------------------------------------------
    // PUBLIC FUNCTIONS
    function quoteLayerZeroFee(
        uint16 _chainId,
        uint16 _msgType,
        LzTxObj memory _lzTxParams,
        bytes memory _payload
    ) public view returns (uint256 _nativeFee, uint256 _zroFee) {   
        bytes memory payload = "";
        if (_msgType == TYPE_REQUEST_SNAPSHOT) {
            payload = abi.encode(TYPE_REQUEST_SNAPSHOT, _payload);
        }
        else if (_msgType == TYPE_REPORT_SNAPSHOT) {
            payload = abi.encode(TYPE_REPORT_SNAPSHOT, _payload);
        }
        else if (_msgType == TYPE_REQUEST_SETTLE) {
            payload = abi.encode(TYPE_REQUEST_SETTLE, _payload);
        }
        else if (_msgType == TYPE_REPORT_SETTLE) {
            payload = abi.encode(TYPE_REPORT_SETTLE, _payload);
        }
        else if (_msgType == TYPE_STAKE_ASSETS) {
            payload = abi.encode(TYPE_STAKE_ASSETS, _payload);
        }
        else if (_msgType == TYPE_UNSTAKE_ASSETS) {
            payload = abi.encode(TYPE_UNSTAKE_ASSETS, _payload);
        }
        else {
            revert("MozBridge: unsupported function type");
        }
        
        bytes memory _adapterParams = _txParamBuilder(_chainId, _msgType, _lzTxParams);
        return layerZeroEndpoint.estimateFees(_chainId, address(this), payload, useLayerZeroToken, _adapterParams);
    }

    //---------------------------------------------------------------------------
    // INTERNAL FUNCTIONS
    function txParamBuilderType1(uint256 _gasAmount) internal pure returns (bytes memory) {
        uint16 txType = 1;
        return abi.encodePacked(txType, _gasAmount);
    }

    function txParamBuilderType2(
        uint256 _gasAmount,
        uint256 _dstNativeAmount,
        bytes memory _dstNativeAddr
    ) internal pure returns (bytes memory) {
        uint16 txType = 2;
        return abi.encodePacked(txType, _gasAmount, _dstNativeAmount, _dstNativeAddr);
    }

    function _txParamBuilder(
        uint16 _chainId,
        uint16 _type,
        LzTxObj memory _lzTxParams
    ) internal view returns (bytes memory) {
        bytes memory lzTxParam;
        address dstNativeAddr;
        {
            bytes memory dstNativeAddrBytes = _lzTxParams.dstNativeAddr;
            assembly {
                dstNativeAddr := mload(add(dstNativeAddrBytes, 20))
            }
        }

        uint256 totalGas = gasLookup[_chainId][_type] + _lzTxParams.dstGasForCall;
        if (_lzTxParams.dstNativeAmount > 0 && dstNativeAddr != address(0x0)) {
            lzTxParam = txParamBuilderType2(totalGas, _lzTxParams.dstNativeAmount, _lzTxParams.dstNativeAddr);
        } else {
            lzTxParam = txParamBuilderType1(totalGas);
        }

        return lzTxParam;
    }

    function _call(
        uint16 _dstChainId,
        uint16 _type,
        address payable _refundAddress,
        LzTxObj memory _lzTxParams,
        bytes memory _payload
    ) internal {
        require(bridgeLookup[_dstChainId].length > 0, "MozBridge: Invalid bridgeLookup");
        bytes memory lzTxParamBuilt = _txParamBuilder(_dstChainId, _type, _lzTxParams);
        layerZeroEndpoint.send{value: msg.value}(
            _dstChainId,
            bridgeLookup[_dstChainId],
            _payload,
            payable(_refundAddress),
            address(this),
            lzTxParamBuilt
        );
        emit SendMsg(_dstChainId, _type, bridgeLookup[_dstChainId]);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

// libraries
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./MozBridge.sol";
import "./MozaicLP.sol";
import "./interfaces/IPlugin.sol";

/// @title  Vault
/// @notice Vault Contract
/// @dev    Vault Contract is responsible for accept deposit and withdraw requests and interact with the plugins and controller.
contract Vault is Ownable {
    using SafeERC20 for IERC20;

    /// @notice Used to define the config of the plugins.
    struct pluginConfig {
        address pluginAddr;
        address pluginReward;
    }

    /// @notice Used to define the request model.
    struct Request {
        address user;
        address token;
    }

    /// @notice Used to store the deposit and withdraw requests.
    struct RequestBuffer {
        Request[] depositRequestList;
        mapping (address => mapping (address => uint256)) depositRequestLookup;
        mapping (address => uint256) depositAmountPerToken; // token => amountLD
        mapping (address => uint256) depositAmountPerUser;
        uint256 totalDepositAmount;
        Request[] withdrawRequestList;
        mapping (address => mapping (address => uint256)) withdrawRequestLookup;
        mapping (address => uint256) withdrawAmountPerToken; // token => amountMLP
        mapping (address => uint256) withdrawAmountPerUser;
        uint256 totalWithdrawAmount;
    }
    uint16 internal constant TYPE_REQUEST_SNAPSHOT = 1;
    uint16 internal constant TYPE_REPORT_SNAPSHOT  = 2;
    uint16 internal constant TYPE_REQUEST_SETTLE   = 3;
    uint16 internal constant TYPE_REPORT_SETTLE    = 4;
    uint16 internal constant TYPE_STAKE_ASSETS     = 5;
    uint16 internal constant TYPE_UNSTAKE_ASSETS   = 6;

    uint16 internal constant TYPE_ACTION_RETRY          = 7;
    uint16 internal constant TYPE_SNAPSHOT_RETRY        = 8;
    uint16 internal constant TYPE_SETTLE_RETRY          = 9;
    uint16 internal constant TYPE_REPORT_SNAPSHOT_RETRY = 10;
    uint16 internal constant TYPE_REPORT_SETTLE_RETRY   = 11;



    /* ========== STATE VARIABLES ========== */

    /// @notice The mozaic bridge contract address that is used to implement cross chain operations.
    address public mozBridge;

    /// @notice The mozaic LP token contract that is used to mint LP tokens to liquidity providers.
    address public mozLP;
    
    /// @notice The chain identifier of this vault.
    uint16 public immutable chainId;

    /// @notice The total amount of satablecoin with mozaic decimal.
    uint256 public totalCoinMD;

    /// @notice The total amount of mozaic LP token.
    uint256 public totalMLP;

    /// @notice Array of requset buffer to store the deposit and withdraw requests.
    RequestBuffer[2] public Buffer;
    
    /// @notice Array of tokens accepted in this vault.
    address[] public acceptingTokens;

    /// @notice Return whether a token is accepted. If token is accepted, return true.
    mapping (address => bool) public tokenMap;

    /// @notice Return the plugin config for a plugin id 
    mapping (uint8 => pluginConfig) public supportedPlugins;

    /// @notice Supported plugin ids.
    uint8[] public pluginIds;
    
    /// @notice The flag used to convert pending request buffer to staged request buffer.
    bool public bufferFlag = false;
    
    /// @notice Mozaic token decimal.
    uint8 public constant MOZAIC_DECIMALS = 6;
    
    /// @notice Address of admin
    address public admin;

    /// @notice Return the revertLookup payload for chainid, srcAddress and nonce
    mapping(uint16 => mapping(bytes => mapping(uint256 => bytes))) public revertLookup; //[chainId][srcAddress][nonce]

    /// @notice The snapshot of the localvault
    MozBridge.Snapshot public localSnapshot;

    /// @notice Current updated Number
    uint256 public updateNum;

    /// @notice The Address of fee treasury
    address payable public treasury;

    /// @notice The Address of lifi contract
    address public lifiContract;

    address private NATIVE_TOKEN;

    /// @notice The deciaml cache (token address => token decimal)
    mapping(address => uint8) private decimalsCache;
    
    /* ========== EVENTS =========== */
    event DepositRequestAdded (
        address indexed _depositor,
        address indexed _token,
        uint16 indexed _chainId,
        uint256 _amountLD
    );

    event WithdrawRequestAdded (
        address indexed _withdrawer,
        address indexed _token,
        uint16 indexed _chainId,
        uint256 _amountMLP
    );

    event DepositRequsetSettled();

    event WithdrawRequestSettled();

    event TakeSnapshot(
        uint256 totalStablecoin,
        uint256 totalMozaicLp,
        uint256 depositRequestAmount,
        uint256 withdrawRequestAmountMLP
    );

    event AddPlugin(
        uint8 indexed _pluginId,
        address indexed _pluginAddr,
        address indexed _pluginReward
    );

    event RemovePlugin(
        uint8 indexed _pluginId
    );

    event AddToken(address _token);

    event RemoveToken(address _token);

    event ActionExecuted(uint16 _srcChainId, bytes indexed _srcAddress, uint64 _nonce, uint8 _pluginId, IPlugin.ActionType _actionType);

    event SnapshotReported(uint16 _srcChainId, bytes indexed _srcAddress, uint64 _nonce, MozBridge.Snapshot indexed _snapshot, uint256 _updateNum);
    
    event SettleReported(uint16 _srcChainId, bytes indexed _srcAddress, uint64 _nonce, uint256 _updateNum);

    event Revert(uint16 bridgeFunctionType, uint16 chainId, bytes srcAddress, uint256 nonce);

    event RetryRevert(uint16 bridgeFunctionType, uint16 chainId, bytes srcAddress, uint256 nonce);

    /* ========== MODIFIERS ========== */

    /// @notice Modifier to check if caller is the bridge.
    modifier onlyBridge() {
        require(msg.sender == mozBridge, "Vault: Invalid bridge");
        _;
    }
    /// @notice Modifier to check if caller is the admin.
    modifier onlyAdmin() {
        require(msg.sender == admin, "Vault: Invalid address");
        _;
    }

    /* ========== CONFIGURATION ========== */
    constructor(uint16 _chainId)  {
        require(_chainId > 0, "Vault: Invalid chainid");
        chainId = _chainId;
    }

    /// @notice Set the mozaic bridge of the vault.
    /// @param  _mozBridge - The address of the bridge being setted.
    function setBridge(address _mozBridge) public onlyOwner {
        require(_mozBridge != address(0), "Vault: Invalid address");
        mozBridge = _mozBridge;
    }

    /// @notice Set the mozaic LP token contract of the vault.
    /// @param  _mozLP - The address of the mozaic LP token contract being setted.
    function setMozaicLP(address _mozLP) public onlyOwner {
        require(_mozLP != address(0), "Vault: Invalid address");
        mozLP = _mozLP;
    }

    /// @notice Set the treasury of the Valult.
    /// @param _treasury - The address of the treasury being setted.
    function setTreasury(address payable _treasury) public onlyOwner {
        require(_treasury != address(0), "Vault: Invalid address");
        treasury = _treasury;
    }

    /// @notice Add the plugin with it's config to the vault.
    /// @param  _pluginId - The id of the plugin being setted.
    /// @param  _pluginAddr - The address of plugin being setted.
    /// @param  _pluginReward - The address of plugin reward token.
    function addPlugin(uint8 _pluginId, address _pluginAddr, address _pluginReward) public onlyOwner {
        require(_pluginId > 0, "Vault: Invalid id");
        require(_pluginAddr != address(0x0), "Vault: Invalid address");
        require(_pluginReward != address(0x0), "Vault: Invalid address");
        for(uint256 i = 0; i < pluginIds.length; ++i) {
            if(pluginIds[i] == _pluginId) revert("Vault: Plugin id already exist");
            if(supportedPlugins[pluginIds[i]].pluginAddr == _pluginAddr) revert("Vault: Plugin already exist");
        }
        pluginIds.push(_pluginId);
        supportedPlugins[_pluginId].pluginAddr = _pluginAddr;
        supportedPlugins[_pluginId].pluginReward = _pluginReward;

        emit AddPlugin(_pluginId, _pluginAddr, _pluginReward);
    }

    /// @notice Remove the plugin with it's id.
    /// @param  _pluginId - The id of the plugin being removed.
    function removePlugin(uint8 _pluginId) public onlyOwner {
        require(_pluginId > 0, "Vault: Invalid id");
        for(uint256 i = 0; i < pluginIds.length; ++i) {
            if(pluginIds[i] == _pluginId) {
                pluginIds[i] = pluginIds[pluginIds.length - 1]; 
                pluginIds.pop();
                delete supportedPlugins[_pluginId];
                emit RemovePlugin(_pluginId);
                return;
            }
        }
        revert("Vault: Plugin id doesn't exist.");
    }

    /// @notice Add the token address to the list of accepted token addresses.
    function addToken(address _token) external onlyOwner {
        if(tokenMap[_token] == false) {
            tokenMap[_token] = true;
            acceptingTokens.push(_token);
            emit AddToken(_token);
        }
    }
    /// @notice Remove the token address from the list of accepted token addresses.
    function removeToken(address _token) external onlyOwner {
        if(tokenMap[_token] == true) {
            tokenMap[_token] = false;
            for(uint256 i = 0; i < acceptingTokens.length; ++i) {
                if(acceptingTokens[i] == _token) {
                    acceptingTokens[i] = acceptingTokens[acceptingTokens.length - 1];
                    acceptingTokens.pop();
                    emit RemoveToken(_token);
                    return;
                }
            }
        }
        revert("Vault: Non accepted token.");
    }

    /// @notice Set the admin of the vault which can withdraw and deposit token.
    function setAdmin(address _admin) external onlyOwner {
        require(_admin != address(0x0), "Vault: Invaild address");
        admin = _admin;
    }

    function setLifi(address _lifi) external onlyOwner {
        require(_lifi != address(0x0), "Vault: Invaild address");
        lifiContract = _lifi;
    }
    ///@notice Deposit token with specified amount.
    function depositToken(address _token, uint256 _amount) external onlyAdmin {
        require(isAcceptingToken(_token), "Vault: Invalid token");
        require(_amount != 0, "Vault: Invalid amount");
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
    }

    function bridgeViaLifi(
        address _srcToken,
        uint256 _amount,
        bytes calldata _data
    ) external payable onlyAdmin {
        require(
            address(lifiContract) != address(0),
            "Lifi: zero address"
        );

        bool isNative = _srcToken == NATIVE_TOKEN;
        if (!isNative) {
            IERC20(_srcToken).safeIncreaseAllowance(address(lifiContract), _amount);
        }

        (bool success, ) = isNative
            ? lifiContract.call{value: _amount + msg.value}(_data)
            : lifiContract.call{value: msg.value}(_data);

        require(success, "Lifi: call failed");
    }

    /* ========== BRIDGE FUNCTIONS ========== */

    /// @notice Execute actions of the certain plugin.
    /// @param _pluginId - the destination plugin identifier
    /// @param _actionType -  the action identifier of plugin action
    /// @param _payload - a custom bytes payload to send to the destination contract
    function execute(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, uint8 _pluginId, IPlugin.ActionType _actionType, bytes memory _payload) public onlyBridge {
        require(_pluginId > 0 && supportedPlugins[_pluginId].pluginAddr != address(0x0) && supportedPlugins[_pluginId].pluginReward != address(0x0), "Vault: Invalid id");
        if(_actionType == IPlugin.ActionType.Stake) {
            (uint256 _amountLD, address _token) = abi.decode(_payload, (uint256, address));
            IERC20(_token).safeApprove(supportedPlugins[_pluginId].pluginAddr, 0);
            IERC20(_token).approve(supportedPlugins[_pluginId].pluginAddr, _amountLD);
        }
        if(MozBridge(mozBridge).mainChainId() == _srcChainId) {
            IPlugin(supportedPlugins[_pluginId].pluginAddr).execute(_actionType, _payload);
            emit ActionExecuted(_srcChainId, _srcAddress, _nonce, _pluginId, _actionType);
        }
        else {
            try IPlugin(supportedPlugins[_pluginId].pluginAddr).execute(_actionType, _payload) {
                emit ActionExecuted(_srcChainId, _srcAddress, _nonce, _pluginId, _actionType);
            } catch {
                revertLookup[_srcChainId][_srcAddress][_nonce] = abi.encode(
                    TYPE_ACTION_RETRY,
                    _pluginId, 
                    _actionType,
                    _payload
                );
                emit Revert(TYPE_ACTION_RETRY, _srcChainId, _srcAddress, _nonce);
            }
        }
    }

    /// @notice Report snapshot of the vault to the controller.
    function reportSnapshot(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        uint256 _updateNum
    ) public onlyBridge {
        MozBridge.Snapshot memory _snapshot;
        if(updateNum == _updateNum) {
            _snapshot = localSnapshot;
        }
        else {
            _snapshot = _takeSnapshot();
            localSnapshot = _snapshot;
            updateNum = _updateNum;
        }
        bytes memory payload = abi.encode(_snapshot, _updateNum);
        (uint256 _nativeFee, ) = MozBridge(mozBridge).quoteLayerZeroFee(MozBridge(mozBridge).mainChainId(), TYPE_REPORT_SNAPSHOT, MozBridge.LzTxObj(0, 0, "0x"), payload);
        try MozBridge(mozBridge).reportSnapshot{value: _nativeFee}(_snapshot, _updateNum, payable(address(this))) {
            emit SnapshotReported(_srcChainId, _srcAddress, _nonce, _snapshot, _updateNum);
        } catch {
            revertLookup[_srcChainId][_srcAddress][_nonce] = abi.encode(TYPE_REPORT_SNAPSHOT_RETRY, _snapshot, _updateNum);
            emit Revert(TYPE_REPORT_SNAPSHOT_RETRY, _srcChainId, _srcAddress, _nonce);
        }
    }

    /// @notice Report that the vault is settled.
    function reportSettled(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        uint256 _totalCoinMD,
        uint256 _totalMLP,
        uint256 _updateNum
    ) public onlyBridge {
        _preSettle(_totalCoinMD, _totalMLP);
        _settleRequests();
        bytes memory payload = abi.encode(_updateNum);
        (uint256 _nativeFee, ) = MozBridge(mozBridge).quoteLayerZeroFee(MozBridge(mozBridge).mainChainId(), TYPE_REPORT_SETTLE, MozBridge.LzTxObj(0, 0, "0x"), payload);
        try MozBridge(mozBridge).reportSettled{value: _nativeFee}(_updateNum, payable(address(this))) {
            emit SettleReported(_srcChainId, _srcAddress, _nonce, _updateNum);
        } catch {
            revertLookup[_srcChainId][_srcAddress][_nonce] = abi.encode(TYPE_REPORT_SETTLE_RETRY, _updateNum);
            emit Revert(TYPE_REPORT_SETTLE_RETRY, _srcChainId, _srcAddress, _nonce);
        }
    }

    /// @notice Retry reverted actions.
    function retryRevert(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce
    ) external payable {
        bytes memory payload = revertLookup[_srcChainId][_srcAddress][_nonce];
        require(payload.length > 0, "Vault: no retry revert");

        // empty it
        revertLookup[_srcChainId][_srcAddress][_nonce] = "";

        uint16 functionType;
        assembly {
            functionType := mload(add(payload, 32))
        }

        if (functionType == TYPE_ACTION_RETRY) {
            (, uint8 _pluginId, IPlugin.ActionType _actionType, bytes memory _payload) = abi.decode(
                payload,
                (uint16, uint8, IPlugin.ActionType, bytes)
            );
            IPlugin(supportedPlugins[_pluginId].pluginAddr).execute(_actionType, _payload);
        }
        // for retrying the swapRemote. if it fails again, retry
        else if (functionType == TYPE_REPORT_SNAPSHOT_RETRY) {
            (, MozBridge.Snapshot memory _snapshot, uint256 _updateNum) = abi.decode(
                payload,
                (uint16, MozBridge.Snapshot, uint256)
            );
            MozBridge(mozBridge).reportSnapshot{value: msg.value}(_snapshot, _updateNum, payable(address(msg.sender)));
        } else if (functionType == TYPE_REPORT_SETTLE_RETRY){
            (, uint256 _updateNum) = abi.decode(
                payload,
                (uint16, uint256)
            );
            MozBridge(mozBridge).reportSettled{value: msg.value}(_updateNum, payable(address(msg.sender)));
        } else if (functionType == TYPE_SNAPSHOT_RETRY){
            (, uint256 _updateNum) = abi.decode(
                payload,
                (uint16, uint256)
            );
            MozBridge.Snapshot memory _snapshot = _takeSnapshot();
            MozBridge(mozBridge).reportSnapshot{value: msg.value}(_snapshot, _updateNum, payable(address(msg.sender)));
        } else if (functionType == TYPE_SETTLE_RETRY){
            (, uint256 _totalCoinMD, uint256 _totalMLP, uint256 _updateNum) = abi.decode(
                payload,
                (uint16, uint256, uint256, uint256)
            );
            _preSettle(_totalCoinMD, _totalMLP);
            _settleRequests();
            MozBridge(mozBridge).reportSettled{value: msg.value}(_updateNum, payable(address(msg.sender)));
        } else {
            revert("Value: invalid function type");
        }
        emit RetryRevert(functionType, _srcChainId, _srcAddress, _nonce);
    }

    /// @notice set the Revert Lookup
    function setRevertLookup(        
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint256 _nonce,
        bytes memory _payload
    ) public onlyBridge {
        revertLookup[_srcChainId][_srcAddress][_nonce] = _payload;
    }

    /// @notice Get the snapshot of current vault and return the snapshot.
    /// @dev Only used in main chain Vault
    function takeSnapshot() public onlyBridge returns (MozBridge.Snapshot memory snapshot) {
        return _takeSnapshot();
    }

    /// @notice Settle the requests with the total amount of the stablecoin and total amount of mozaic LP token.
    /// @dev Only used in main chain Vault
    function settleRequests(uint256 _totalCoinMD, uint256 _totalMLP) public onlyBridge {
        _preSettle(_totalCoinMD, _totalMLP);
        _settleRequests();
    }
    /* ========== USER FUNCTIONS ========== */
    
    /// @notice Add deposit request to the vault.
    /// @param _amountLD - The amount of the token to be deposited.
    /// @param _token - The address of the token  to be deposited.
    function addDepositRequest(uint256 _amountLD, address _token, address depositor) external {
        require(isAcceptingToken(_token), "Vault: Invalid token");
        require(_amountLD != 0, "Vault: Invalid amount");
        address _depositor = depositor;

        // Transfer token from depositer to vault.
        IERC20(_token).safeTransferFrom(_depositor, address(this), _amountLD);

        // Get the pending buffer
        RequestBuffer storage _pendingBuffer = _requests(false);
        
        // Check if the user has already deposited with this token.
        bool exists = false;
        for(uint i = 0; i < _pendingBuffer.depositRequestList.length; ++i) {    
            Request memory req = _pendingBuffer.depositRequestList[i];
            if(req.user == _depositor && req.token == _token) {
                exists = true;
                break;
            }
        }
        if(!exists) {
            Request memory req;
            req.user = _depositor;
            req.token = _token;
            _pendingBuffer.depositRequestList.push(req);
        }

        // Convert local decimal to mozaic decimal.
        uint256 _amountMD = convertLDtoMD(_token, _amountLD);

        _pendingBuffer.depositRequestLookup[_depositor][_token] = _pendingBuffer.depositRequestLookup[_depositor][_token] + _amountMD;
        _pendingBuffer.depositAmountPerToken[_token] = _pendingBuffer.depositAmountPerToken[_token] + _amountMD;
        _pendingBuffer.depositAmountPerUser[_depositor] = _pendingBuffer.depositAmountPerUser[_depositor] + _amountMD;
        _pendingBuffer.totalDepositAmount = _pendingBuffer.totalDepositAmount + _amountMD;
        emit DepositRequestAdded(_depositor, _token, chainId, _amountMD);
    }

    /// @notice Add withdraw request to the vault.
    /// @param _amountMLP - The amount of the mozaic LP token used to withdraw token.
    /// @param _token - The address of the token to be withdrawn.
    function addWithdrawRequest(uint256 _amountMLP, address _token, address withdrawer) external {
        require(isAcceptingToken(_token), "Vault: Invalid token");
        require(_amountMLP != 0, "Vault: Invalid amount");
        
        address _withdrawer = withdrawer;

        require(MozaicLP(mozLP).balanceOf(_withdrawer) >= _amountMLP, "Vault: Low LP token balance");

        // Get the pending buffer and staged buffer.
        RequestBuffer storage _pendingBuffer = _requests(false);

        IERC20(mozLP).safeTransferFrom(_withdrawer, address(this), _amountMLP);

        // Check if the user has already withdrawed with this token.
        bool exists = false;
        for(uint i = 0; i < _pendingBuffer.withdrawRequestList.length; ++i) {
            Request memory req = _pendingBuffer.withdrawRequestList[i];
            if(req.user == _withdrawer && req.token == _token) {
                exists = true;
                break;
            }
        }
        if(!exists) {
            Request memory req;
            req.user = _withdrawer;
            req.token = _token;
            _pendingBuffer.withdrawRequestList.push(req);
        }
        _pendingBuffer.withdrawRequestLookup[_withdrawer][_token] = _pendingBuffer.withdrawRequestLookup[_withdrawer][_token] + _amountMLP;
        _pendingBuffer.withdrawAmountPerUser[_withdrawer] = _pendingBuffer.withdrawAmountPerUser[_withdrawer] + _amountMLP;
        _pendingBuffer.withdrawAmountPerToken[_token] = _pendingBuffer.withdrawAmountPerToken[_token] + _amountMLP;
        _pendingBuffer.totalWithdrawAmount = _pendingBuffer.totalWithdrawAmount + _amountMLP;

        emit WithdrawRequestAdded(_withdrawer, _token, chainId, _amountMLP);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /// @notice Returns the pending request buffer or staged request buffer according to the param.
    /// @param _staged - false -> pending buffer, true -> staged buffer
    function _requests(bool _staged) internal view returns (RequestBuffer storage) {
        return _staged ? (bufferFlag ? Buffer[1] : Buffer[0]) : (bufferFlag ? Buffer[0] : Buffer[1]);
    }
    
    /// @notice Take snapshot from the vault and return the snapshot.
    function _takeSnapshot() internal returns (MozBridge.Snapshot memory snapshot) {
        require(_requests(true).totalDepositAmount == 0, "Still processing requests");
        require(_requests(true).totalWithdrawAmount == 0, "Still processing requests");

        // Switch pending request buffer to staged request buffer.
        bufferFlag = !bufferFlag;

        // Get the total amount of stablecoin in vault with mozaic decimal.
        uint256 _totalAssetMD;
        for(uint256 i = 0; i < acceptingTokens.length; ++i) {
            uint256 amountLD = IERC20(acceptingTokens[i]).balanceOf(address(this));
            uint256 amountMD = convertLDtoMD(acceptingTokens[i], amountLD);
            _totalAssetMD = _totalAssetMD + amountMD; 
        }

        // Get total amount of stablecoin of plugin.
        uint256 _totalStablecoinMD;
        snapshot.amounts = new uint256[](pluginIds.length);

        for(uint256 i = 0; i < pluginIds.length; ++i) {
            address plugin = supportedPlugins[pluginIds[i]].pluginAddr;
            bytes memory _payload = abi.encode(acceptingTokens);
            bytes memory response = IPlugin(plugin).execute(IPlugin.ActionType.GetTotalAssetsMD, _payload); 
            _totalStablecoinMD = _totalStablecoinMD + abi.decode(response, (uint256));
            
            address rewardToken = supportedPlugins[pluginIds[i]].pluginReward;
            uint256 rewardAmount = IERC20(rewardToken).balanceOf(address(this));
            // Add the plugin data to snapshot.
            snapshot.amounts[i] = convertLDtoMD(rewardToken, rewardAmount);
        }
        // // Configure and return snapshot.
        snapshot.totalStablecoin = _totalAssetMD + _totalStablecoinMD - _requests(true).totalDepositAmount;
        snapshot.totalMozaicLp = IERC20(mozLP).totalSupply();
        snapshot.depositRequestAmount = _requests(true).totalDepositAmount;
        snapshot.withdrawRequestAmountMLP = _requests(true).totalWithdrawAmount;
        emit TakeSnapshot(
            snapshot.totalStablecoin,
            snapshot.totalMozaicLp,
            snapshot.depositRequestAmount,
            snapshot.withdrawRequestAmountMLP
        );
    }

    /// @notice Set the total amount of stablecoin and total amount of mozaic LP token.
    function _preSettle(uint256 _totalCoinMD, uint256 _totalMLP) internal {
        totalCoinMD = _totalCoinMD;
        totalMLP = _totalMLP;
    }

    /// @notice Switch the pending requests to the staged requests and settle the staged requests.  
    function _settleRequests() internal  {
        // for all deposit requests, mint MozaicLp
        RequestBuffer storage _reqs = _requests(true);
        for (uint i; i < _reqs.depositRequestList.length; ++i) {
            Request storage request = _reqs.depositRequestList[i];
            uint256 _depositAmountMD = _reqs.depositRequestLookup[request.user][request.token];
            if (_depositAmountMD == 0) {
                continue;
            }

            // Calculate the amount of mozaic LP token to be minted.
            uint256 _amountMLPToMint = amountMDtoMLP(_depositAmountMD);

            // Mint moazic LP token.
            MozaicLP(mozLP).mint(request.user, _amountMLPToMint);

            // Reduce Handled Amount from Buffer
            _reqs.totalDepositAmount = _reqs.totalDepositAmount - _depositAmountMD;
            _reqs.depositAmountPerUser[request.user] = _reqs.depositAmountPerUser[request.user] - _depositAmountMD;
            _reqs.depositAmountPerToken[request.token] = _reqs.depositAmountPerToken[request.token] - _depositAmountMD;
            _reqs.depositRequestLookup[request.user][request.token] = _reqs.depositRequestLookup[request.user][request.token] - _depositAmountMD;
        }
        require(_reqs.totalDepositAmount == 0, "Has unsettled deposit amount.");
        delete _reqs.depositRequestList;

        emit DepositRequsetSettled();
        // for all withdraw requests, give tokens
        for (uint i; i < _reqs.withdrawRequestList.length; ++i) {
            Request storage request = _reqs.withdrawRequestList[i];
            uint256 _withdrawAmountMLP = _reqs.withdrawRequestLookup[request.user][request.token];
            if (_withdrawAmountMLP == 0) {
                continue;
            }
            // Calculate the amount of mozaic LP token to be burned and the amount of token to be redeem.
            uint256 _coinAmountMDtoGive = amountMLPtoMD(_withdrawAmountMLP);
            uint256 _coinAmountLDtoGive = convertMDtoLD(request.token, _coinAmountMDtoGive);
            uint256 _vaultBalanceLD = IERC20(request.token).balanceOf(address(this));
            uint256 _mlpToBurn = _withdrawAmountMLP;
            if (_vaultBalanceLD < _coinAmountLDtoGive) {
                // The vault does not have enough balance. Only give as much as it has.
                _mlpToBurn = _withdrawAmountMLP * _vaultBalanceLD / _coinAmountLDtoGive;
                _coinAmountLDtoGive = _vaultBalanceLD;
                IERC20(mozLP).safeTransfer(request.user, _withdrawAmountMLP - _mlpToBurn);
            }

            // Burn moazic LP token.
            MozaicLP(mozLP).burn(address(this), _mlpToBurn);

            // Transfer token to the user.
            IERC20(request.token).safeTransfer(request.user, _coinAmountLDtoGive);
            // Reduce Handled Amount from Buffer
            _reqs.totalWithdrawAmount = _reqs.totalWithdrawAmount - _withdrawAmountMLP;
            _reqs.withdrawAmountPerUser[request.user] = _reqs.withdrawAmountPerUser[request.user] - _withdrawAmountMLP;
            _reqs.withdrawAmountPerToken[request.token] = _reqs.withdrawAmountPerToken[request.token] - _withdrawAmountMLP;
            _reqs.withdrawRequestLookup[request.user][request.token] = _reqs.withdrawRequestLookup[request.user][request.token] - _withdrawAmountMLP;
        }
        require(_reqs.totalWithdrawAmount == 0, "Has unsettled withdrawal amount.");
        delete _reqs.withdrawRequestList;
        emit WithdrawRequestSettled();
    }

    /* ========== VIEW FUNCTIONS ========== */

    /// @notice Whether the token is accepted token or not.
    /// @param _token - The address of token.
    function isAcceptingToken(address _token) public view returns (bool) {
        return tokenMap[_token];
    }

    /// @notice Get the deposit amount with specified user and token
    function getDepositAmount(bool _staged, address _user, address _token) public view returns (uint256) {
        return _requests(_staged).depositRequestLookup[_user][_token];
    }

    /// @notice Get the withdraw amount with specified user and token
    function getWithdrawAmount(bool _staged, address _user, address _token) public view returns (uint256) {
        return _requests(_staged).withdrawRequestLookup[_user][_token];
    }

    /// @notice Get the deposit request with the index
    function getDepositRequest(bool _staged, uint256 _index) public view returns (Request memory) {
        return _requests(_staged).depositRequestList[_index];
    }

    /// @notice Get the withdraw request with the index
    function getWithdrawRequest(bool _staged, uint256 _index) public view returns (Request memory) {
        return _requests(_staged).withdrawRequestList[_index];
    }

    /// @notice Get the total deposit amount
    function getTotalDepositAmount(bool _staged) public view returns (uint256) {
        return _requests(_staged).totalDepositAmount;
    }

    /// @notice Get the total withdraw amount
    function getTotalWithdrawAmount(bool _staged) public view returns (uint256) {
        return _requests(_staged).totalWithdrawAmount;
    }

    /// @notice Get the length of deposit requests
    function getDepositRequestListLength(bool _staged) public view returns (uint256) {
        return _requests(_staged).depositRequestList.length;
    }
    /// @notice Get the length of withdraw requests
    function getWithdrawRequestListLength(bool _staged) public view returns (uint256) {
        return _requests(_staged).withdrawRequestList.length;
    }

    /// @notice Get the address of plugin with it's id
    function getPluginAddress(uint8 id) public view returns (address) {
        return supportedPlugins[id].pluginAddr;
    }

    /// @notice Get the address of plugin reward with it's id
    function getPluginReward(uint8 id) public view returns (address) {
        return supportedPlugins[id].pluginReward;
    }
    
    /// @notice Get the depoist amount per token
    function getDepositAmountPerToken(bool _staged, address _token) public view returns (uint256) {
        return _requests(_staged).depositAmountPerToken[_token];
    }

    /// @notice Get the withdraw amount per token
    function getWithdrawAmountPerToken(bool _staged, address _token) public view returns (uint256) {
        return _requests(_staged).withdrawAmountPerToken[_token];
    }

    /// @notice Get the depoist amount per user
    function getDepositAmountPerUser(bool _staged, address _user) public view returns (uint256) {
        return _requests(_staged).depositAmountPerUser[_user];
    }

    /// @notice Get the withdraw amount per user
    function getWithdrawAmountPerUser(bool _staged, address _user) public view returns (uint256) {
        return _requests(_staged).depositAmountPerUser[_user];
    }

    /// @notice Get the number of plugins.
    function getNumberOfPlugins() public view returns (uint256) {
        return pluginIds.length;
    }

    /// Convert functions

    /// @notice Convert local decimal to mozaic decimal.
    /// @param _token - The address of the token to be converted.
    /// @param _amountLD - the token amount represented with local decimal.
    function convertLDtoMD(address _token, uint256 _amountLD) public view returns (uint256) {
        uint8 _localDecimals = IERC20Metadata(_token).decimals();
        if (MOZAIC_DECIMALS >= _localDecimals) {
            return _amountLD * (10**(MOZAIC_DECIMALS - _localDecimals));
        } else {
            return _amountLD / (10**(_localDecimals - MOZAIC_DECIMALS));
        }
    }

    /// @notice Convert mozaic decimal to local decimal.
    /// @param _token - The address of the token to be converted.
    /// @param _amountMD - the token amount represented with mozaic decimal.
    function convertMDtoLD(address _token, uint256 _amountMD) public view returns (uint256) {
        uint8 _localDecimals = IERC20Metadata(_token).decimals();
        if (MOZAIC_DECIMALS >= _localDecimals) {
            return _amountMD / (10**(MOZAIC_DECIMALS - _localDecimals));
        } else {
            return _amountMD * (10**(_localDecimals - MOZAIC_DECIMALS));
        }
    }

    /// @notice Convert Mozaic decimal amount to mozaic LP decimal amount.
    /// @param _amountMD - the token amount represented with mozaic decimal.
    function amountMDtoMLP(uint256 _amountMD) public view returns (uint256) {
        if (totalCoinMD == 0) {
            return _amountMD;
        } else {
            return _amountMD * totalMLP / totalCoinMD;
        }
    }
    
    /// @notice Convert mozaic LP decimal amount to Mozaic decimal amount.
    /// @param _amountMLP - the mozaic LP token amount.
    function amountMLPtoMD(uint256 _amountMLP) public view returns (uint256) {
        if (totalMLP == 0) {
            return _amountMLP;
        } else {
            return _amountMLP * totalCoinMD / totalMLP;
        }
    }
    
    receive() external payable {}
    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
    function withdraw(uint256 _amount) public onlyOwner {
        // get the amount of Ether stored in this contract
        uint amount = address(this).balance;
        require(amount >= _amount, "Vault: Invalid withdraw amount.");
        // send Ether to owner
        // Owner can receive Ether since the address of owner is payable
        (bool success, ) = treasury.call{value: _amount}("");
        require(success, "Vault: Failed to send Ether");
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

// imports
import "./MozBridge.sol";
import "./Vault.sol";
import "./interfaces/IPlugin.sol";

// libraries
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title  Mozaic Controller
/// @notice Mozaic Controller Contract  
/// @dev    The Mozaic Controller performs Mozaic operations to enforce the Archimedes's guidance
///         against the APY(Annual Percentage Yield) of the pools.
contract Controller is Ownable {
    
    /// @notice The main status of the protocol 
    enum ProtocolStatus {
        IDLE,
        SNAPSHOTTING,
        OPTIMIZING,
        SETTLING
    }

    uint16 internal constant TYPE_REQUEST_SNAPSHOT = 1;
    uint16 internal constant TYPE_REPORT_SNAPSHOT  = 2;
    uint16 internal constant TYPE_REQUEST_SETTLE   = 3;
    uint16 internal constant TYPE_REPORT_SETTLE    = 4;
    uint16 internal constant TYPE_STAKE_ASSETS     = 5;
    uint16 internal constant TYPE_UNSTAKE_ASSETS   = 6;

    /// @notice Address that is responsible for executing main actions.
    address public master;
    
    /// @notice Address that is used to implement the cross chain operations.
    MozBridge public mozBridge;
    
    /* ========== STATE VARIABLES ========== */

    /// @notice Array of the all supported chain ids.
    uint16[] public supportedChainIds;

    /// @notice Main chain identifier of this protocol.
    uint16 public immutable mainChainId;
    
    /// @notice The total amount of satable coin with mozaic decimal.
    uint256 public totalCoinMD;

    /// @notice The total amount of mozaic LP token.
    uint256 public totalMLP;

    /// @notice Return a snapshot data from given chain id.
    mapping (uint16 => MozBridge.Snapshot) public snapshotReported;

    /// @notice The current activated status.
    ProtocolStatus public protocolStatus;

    /// @notice Returns the flag if snapshot reported. (updateNum -> chainId -> flag)
    mapping(uint256 => mapping(uint16 => bool)) public snapshotFlag;

    /// @notice Returns the flag if settle reported. (updateNum -> chainId -> flag)
    mapping(uint256 => mapping(uint16 => bool)) public settleFlag;

    /// @notice Current updated state number.
    uint256 public updateNum;

    /// @notice The address of the treasury
    address payable public treasury;

    /* ========== MODIFIERS ========== */

    /// @notice Modifier to check if caller is the master.
    modifier onlyMaster() {
        require(msg.sender == master, "Controller: Invalid caller");
        _;
    }

    /// @notice Modifier to check if caller is the bridge.
    modifier onlyBridge() {
        require(msg.sender == address(mozBridge), "Controller: Invalid caller");
        _;
    }

    /* ========== EVENTS ========== */

    event UpdateAssetState(uint256 _updateNum);
    event SettleAllVaults(uint256 _updateNum);
    event ExecuteActions(IPlugin.ActionType _action);
    /* ========== CONSTRUCTOR ========== */
    
    constructor(
        uint16 _mainChainId
    ) {
        require(_mainChainId > 0, "Controller: Invalid chainid");
        mainChainId = _mainChainId;
        supportedChainIds.push(mainChainId);
    }

    /* ========== CONFIGURATION ========== */

    /// @notice Set the bridge of the controller
    /// @param _mozBridge - The address of the bridge being setted.
    function setBridge(address payable _mozBridge) public onlyOwner {
        require(_mozBridge != address(0), "Controller: Invalid address");
        mozBridge = MozBridge(payable (_mozBridge));
    }

    /// @notice Set the master of the controller.
    /// @param _master - The address of the master being setted.
    function setMaster(address _master) public onlyOwner {
        require(_master != address(0), "Controller: Invalid address");
        master = _master;
    }

    /// @notice Set the treasury of the controller.
    /// @param _treasury - The address of the treasury being setted.
    function setTreasury(address payable _treasury) public onlyOwner {
        require(_treasury != address(0), "Controller: Invalid address");
        treasury = _treasury;
    }

    /// @notice Add chain identifier to list of supported chain identifer.
    /// @param  _chainId - The identifier of the chain being added.
    function setChainId(uint16 _chainId) public onlyOwner {
        require(_chainId > 0, "Controller: Invalid chainID");
        if(isAcceptingChainId(_chainId)) revert("Controller: chainId alreay exist");
        supportedChainIds.push(_chainId);
    }

    /// @notice Romove chain identifier from the list of chain identifier.
    /// @param  _chainId - The identifier of the chain being removed.
    function removeChainId(uint16 _chainId) public onlyOwner {
        require(_chainId > 0, "Controller: Invalid chainID");
        for(uint256 i = 0; i < supportedChainIds.length; ++i) {
            if(_chainId == supportedChainIds[i]) {
                supportedChainIds[i] = supportedChainIds[supportedChainIds.length - 1];
                supportedChainIds.pop();
                return;
            }
        }
        revert("Controller: chainId doesn't exist");
    }

    /* ========== BRIDGE FUNCTIONS ========== */

    /// @notice Update the snapshot of the certain chain.
    /// @param  _srcChainId - The source chain identifier of snapshot being updated.
    /// @param  _snapshot - The snapshot from the local chain.
    function updateSnapshot(uint16 _srcChainId, MozBridge.Snapshot memory _snapshot, uint256 _updateNum) external onlyBridge {
        _updateSnapshot(_srcChainId, _snapshot, _updateNum);
    }

    /// @notice Accept report from the vaults.
    function settleReport(uint16 _srcChainId, uint256 _updateNum) external onlyBridge {
        _settleReport(_srcChainId, _updateNum);
    }

    /* ========== MASTER FUNCTIONS ========== */

    /// @notice Send the requsets to the local vaults to get the snapshot.
    function updateAssetState() external onlyMaster {
        require(protocolStatus == ProtocolStatus.IDLE, "Controller: Protocal must be IDLE");
        updateNum++;
        // update protocol status to `SNAPSHOPPING`
        protocolStatus = ProtocolStatus.SNAPSHOTTING;
        for(uint16 i = 0; i < supportedChainIds.length; ++i) {
            if(mainChainId == supportedChainIds[i]) {
                MozBridge.Snapshot memory _snapshot = mozBridge.takeSnapshot();
                _updateSnapshot(mainChainId, _snapshot, updateNum);
            } else {
                bytes memory payload = abi.encode(updateNum);
                (uint256 _nativeFee, ) = mozBridge.quoteLayerZeroFee(supportedChainIds[i], TYPE_REQUEST_SNAPSHOT, MozBridge.LzTxObj(0, 0, "0x"), payload);
                mozBridge.requestSnapshot{value: _nativeFee}(supportedChainIds[i], updateNum, payable(address(this)));
            }
        }
        emit UpdateAssetState(updateNum);
    }

    /// @notice Settle the deposit and withdraw request in local vaults with total coin amount and total mozaic LP token amount.
    function settleAllVaults() external onlyMaster {
        require(protocolStatus == ProtocolStatus.OPTIMIZING, "Controller: Protocal must be OPTIMIZING");
        // update the protocol status to `SETTING`
        protocolStatus = ProtocolStatus.SETTLING;
        for(uint i = 0; i < supportedChainIds.length; ++i) {
            // if there is no requests, doesn't settle on vault.
            if(snapshotReported[supportedChainIds[i]].depositRequestAmount == 0 && snapshotReported[supportedChainIds[i]].withdrawRequestAmountMLP == 0) {
                _settleReport(supportedChainIds[i], updateNum);
                continue;
            } 
            // settle the vaults
            if(supportedChainIds[i] == mainChainId) {
                mozBridge.setSettle(totalCoinMD, totalMLP);
                _settleReport(mainChainId, updateNum);
            } else {
                bytes memory payload = abi.encode(totalCoinMD, totalMLP, updateNum);
                (uint256 _nativeFee, ) = mozBridge.quoteLayerZeroFee(supportedChainIds[i], TYPE_REQUEST_SETTLE, MozBridge.LzTxObj(0, 0, "0x"), payload);
                mozBridge.requestSettle{value: _nativeFee}(supportedChainIds[i], totalCoinMD, totalMLP, updateNum, payable(address(this)));
            }
        }
        emit SettleAllVaults(updateNum);
    }

    /// @notice Execute the action in certain local vault.
    /// @param _dstChainId - the destination chain identifier
    /// @param _pluginId - the destination plugin identifier
    /// @param _action -  the action identifier of plugin action
    /// @param _payload - a custom bytes payload to send to the destination contract
    function executeActions(uint16 _dstChainId, uint8 _pluginId, IPlugin.ActionType _action, bytes memory _payload) external onlyMaster {
        if(_dstChainId ==  mainChainId) {
            mozBridge.execute(_pluginId, _action, _payload);
        }
        else {
            uint16 executeType;
            if(_action == IPlugin.ActionType.Stake) {
                executeType = TYPE_STAKE_ASSETS;
            } else if(_action == IPlugin.ActionType.Unstake) {
                executeType = TYPE_UNSTAKE_ASSETS;
            } else {
                revert("Controller: Invalid action type");
            }
            bytes memory payload = abi.encode(_pluginId, _payload);
            (uint256 _nativeFee, ) = mozBridge.quoteLayerZeroFee(_dstChainId, executeType, MozBridge.LzTxObj(0, 0, "0x"), payload);
            mozBridge.requestExecute{value: _nativeFee}(_dstChainId, _pluginId, executeType, _payload, payable(address(this)));
        }
        emit ExecuteActions(_action);
    }

    /// @notice Send the requsets to a certain local vault to get the snapshot.
    function requestSnapshot(uint16 _chainId) external onlyMaster {
        require(protocolStatus == ProtocolStatus.SNAPSHOTTING, "Controller: Protocal must be SNAPSHOTTING");
        require(isAcceptingChainId(_chainId),"Controller: Invalid chainId");
        if(_chainId == mainChainId) {
            MozBridge.Snapshot memory _snapshot = mozBridge.takeSnapshot();
            _updateSnapshot(mainChainId, _snapshot, updateNum);
        } else {
            bytes memory payload = abi.encode(updateNum);
            (uint256 _nativeFee, ) = mozBridge.quoteLayerZeroFee(_chainId, TYPE_REQUEST_SNAPSHOT, MozBridge.LzTxObj(0, 0, "0x"), payload);
            mozBridge.requestSnapshot{value: _nativeFee}(_chainId, updateNum, payable(address(this)));
        }
    }

    /// @notice Settle the deposit and withdraw request in a certain local vault with total coin amount and total mozaic LP token amount.
    function requestSettle(uint16 _chainId) external onlyMaster {
        require(protocolStatus == ProtocolStatus.SETTLING, "Controller: Protocal must be SETTLING");
        require(isAcceptingChainId(_chainId),"Controller: Invalid chainId");
        // if there is no requests, doesn't settle on vault.
        if(snapshotReported[_chainId].depositRequestAmount == 0 && snapshotReported[_chainId].withdrawRequestAmountMLP == 0) {
            _settleReport(_chainId, updateNum);
            return;
        }
        if(_chainId == mainChainId) {
            mozBridge.setSettle(totalCoinMD, totalMLP);
            _settleReport(mainChainId, updateNum);
        } else {
            bytes memory payload = abi.encode(totalCoinMD, totalMLP, updateNum);
            (uint256 _nativeFee, ) = mozBridge.quoteLayerZeroFee(_chainId, TYPE_REQUEST_SETTLE, MozBridge.LzTxObj(0, 0, "0x"), payload);
            mozBridge.requestSettle{value: _nativeFee}(_chainId, totalCoinMD, totalMLP, updateNum, payable(address(this)));
        }

    }
    
    /* ========== VIEW FUNCTIONS ========== */

    /// @notice Return the snapshot for a chain identifier.
    /// @dev    Used to return & access the certain snapshot struct in solidity
    function getSnapshotData(uint16 _chainId) public view returns (MozBridge.Snapshot memory ){
        return snapshotReported[_chainId];
    }

    /// @notice Whether chain identifer is supported.
    function isAcceptingChainId(uint16 _chainId) public view returns (bool) {
        for(uint256 i = 0; i < supportedChainIds.length; ++i) {
            if(_chainId == supportedChainIds[i]) return true;
        }
        return false;
    }

    /// @notice Check if snapshop of a certain chainId is reported .
    function isSnapshotReported(uint16 _chainId) public view returns (bool) {
        require(isAcceptingChainId(_chainId), "Controller: Invalid chainId");
        return snapshotFlag[updateNum][_chainId];
    }

    /// @notice Check if certain chainId is settled.
    function isSettleReported(uint16 _chainId) public view returns (bool) {
        require(isAcceptingChainId(_chainId), "Controller: Invalid chainId");
        return settleFlag[updateNum][_chainId];
    }

    /// @notice Get the length of supported chains.
    function getNumberOfChains() public view returns (uint256) {
        return supportedChainIds.length;
    }
    /* ========== INTERNAL FUNCTIONS ========== */
    
    /// @notice Update the snapshot of the certain chain.
    /// @param  _srcChainId - The source chain identifier of snapshot being updated.
    /// @param  _snapshot - The snapshot to be setted.
    /// @param  _updateNum - ddd.
    function _updateSnapshot(uint16 _srcChainId, MozBridge.Snapshot memory _snapshot, uint256 _updateNum) internal {
        if(updateNum != _updateNum) return;
        if(snapshotFlag[_updateNum][_srcChainId] == true) return;
        snapshotFlag[_updateNum][_srcChainId] = true;
        snapshotReported[_srcChainId] = _snapshot;
        // check if all vaults reported their snapshot
        if(_checkSnapshot()) {
            _updateStats();
            // update protocol status to `OPTIMIZING`
            protocolStatus = ProtocolStatus.OPTIMIZING;
        }
    }

    /// @notice Accept settle reports from the local vaults.
    function _settleReport(uint16 _srcchainId, uint256 _updateNum) internal {
        if(updateNum != _updateNum) return;
        if(settleFlag[updateNum][_srcchainId] == true) return;
        settleFlag[updateNum][_srcchainId] = true;
        // check if all vaults are settled
        if(_checkSettle()) {
            // update protocol status to `IDLE`
            protocolStatus = ProtocolStatus.IDLE;
        }
    }
    
    /// @notice Update stats with the snapshots from all local vaults.
    function _updateStats() internal {
        totalCoinMD = 0;
        totalMLP = 0;
        // Calculate the total amount of stablecoin and mozaic LP token.
        for (uint i; i < supportedChainIds.length ; ++i) {
            MozBridge.Snapshot memory report = snapshotReported[supportedChainIds[i]];
            totalCoinMD = totalCoinMD + report.totalStablecoin;
            totalMLP = totalMLP + report.totalMozaicLp;
        }
    }

    /// @notice Check if get shapshots from all supported chains.
    function _checkSnapshot() internal view returns (bool) {
      for(uint256 i = 0; i < supportedChainIds.length; ++i) {
        if(snapshotFlag[updateNum][supportedChainIds[i]] == false) return false;
      }
      return true;
    }

    /// @notice Check if get settle reports from all supported chains.
    function _checkSettle() internal view returns (bool) {
      for(uint256 i = 0; i < supportedChainIds.length; ++i) {
        if(settleFlag[updateNum][supportedChainIds[i]] == false) return false;
      }
      return true;
    }

    receive() external payable {}
    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
    function withdraw(uint256 _amount) public onlyOwner {
        // get the amount of Ether stored in this contract
        uint amount = address(this).balance;
        require(amount >= _amount, "Controller: Invalid withdraw amount.");
        // send Ether to owner
        // Owner can receive Ether since the address of owner is payable
        (bool success, ) = treasury.call{value: _amount}("");
        require(success, "Controller: Failed to send Ether");
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface IPlugin {
    enum ActionType {
        // Action types
        Stake,
        Unstake,
        GetStakedAmountLD,
        GetTotalAssetsMD
    }

    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    function execute(ActionType _actionType, bytes calldata _payload) external returns (bytes memory);
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

pragma solidity >=0.5.0;

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(uint16 _dstChainId, bytes calldata _destination, bytes calldata _payload, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(uint16 _srcChainId, bytes calldata _srcAddress, address _dstAddress, uint64 _nonce, uint _gasLimit, bytes calldata _payload) external;

    // @notice get the inboundNonce of a lzApp from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(uint16 _dstChainId, address _userApplication, bytes calldata _payload, bool _payInZRO, bytes calldata _adapterParam) external view returns (uint nativeFee, uint zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(uint16 _version, uint16 _chainId, address _userApplication, uint _configType) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication) external view returns (uint16);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

// imports
import "@layerzerolabs/solidity-examples/contracts/token/oft/v2/OFTV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MozaicLP is Ownable, OFTV2 {
    address public vault;

    constructor(
        address _layerZeroEndpoint,
        uint8 _sharedDecimals
    ) OFTV2("Mozaic LPToken", "mozLP", _sharedDecimals, _layerZeroEndpoint) {
    }

    modifier onlyVault() {
        require(vault == _msgSender(), "OnlyVault: caller is not the vault");
        _;
    }

    function setVault(address _vault) public onlyOwner {
        require(_vault != address(0), "ERROR: Invalid address");
        vault = _vault;
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function mint(address _account, uint256 _amount) public onlyVault {
        _mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) public onlyVault {
        _burn(_account, _amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
        return functionCall(target, data, "Address: low-level call failed");
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./BaseOFTV2.sol";

contract OFTV2 is BaseOFTV2, ERC20 {

    uint internal immutable ld2sdRate;

    constructor(string memory _name, string memory _symbol, uint8 _sharedDecimals, address _lzEndpoint) ERC20(_name, _symbol) BaseOFTV2(_sharedDecimals, _lzEndpoint) {
        uint8 decimals = decimals();
        require(_sharedDecimals <= decimals, "OFT: sharedDecimals must be <= decimals");
        ld2sdRate = 10 ** (decimals - _sharedDecimals);
    }

    /************************************************************************
    * public functions
    ************************************************************************/
    function circulatingSupply() public view virtual override returns (uint) {
        return totalSupply();
    }

    function token() public view virtual override returns (address) {
        return address(this);
    }

    /************************************************************************
    * internal functions
    ************************************************************************/
    function _debitFrom(address _from, uint16, bytes32, uint _amount) internal virtual override returns (uint) {
        address spender = _msgSender();
        if (_from != spender) _spendAllowance(_from, spender, _amount);
        _burn(_from, _amount);
        return _amount;
    }

    function _creditTo(uint16, address _toAddress, uint _amount) internal virtual override returns (uint) {
        _mint(_toAddress, _amount);
        return _amount;
    }

    function _transferFrom(address _from, address _to, uint _amount) internal virtual override returns (uint) {
        address spender = _msgSender();
        // if transfer from this contract, no need to check allowance
        if (_from != address(this) && _from != spender) _spendAllowance(_from, spender, _amount);
        _transfer(_from, _to, _amount);
        return _amount;
    }

    function _ld2sdRate() internal view virtual override returns (uint) {
        return ld2sdRate;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OFTCoreV2.sol";
import "./IOFTV2.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

abstract contract BaseOFTV2 is OFTCoreV2, ERC165, IOFTV2 {

    constructor(uint8 _sharedDecimals, address _lzEndpoint) OFTCoreV2(_sharedDecimals, _lzEndpoint) {
    }

    /************************************************************************
    * public functions
    ************************************************************************/
    function sendFrom(address _from, uint16 _dstChainId, bytes32 _toAddress, uint _amount, LzCallParams calldata _callParams) public payable virtual override {
        _send(_from, _dstChainId, _toAddress, _amount, _callParams.refundAddress, _callParams.zroPaymentAddress, _callParams.adapterParams);
    }

    function sendAndCall(address _from, uint16 _dstChainId, bytes32 _toAddress, uint _amount, bytes calldata _payload, uint64 _dstGasForCall, LzCallParams calldata _callParams) public payable virtual override {
        _sendAndCall(_from, _dstChainId, _toAddress, _amount, _payload, _dstGasForCall, _callParams.refundAddress, _callParams.zroPaymentAddress, _callParams.adapterParams);
    }

    /************************************************************************
    * public view functions
    ************************************************************************/
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IOFTV2).interfaceId || super.supportsInterface(interfaceId);
    }

    function estimateSendFee(uint16 _dstChainId, bytes32 _toAddress, uint _amount, bool _useZro, bytes calldata _adapterParams) public view virtual override returns (uint nativeFee, uint zroFee) {
        return _estimateSendFee(_dstChainId, _toAddress, _amount, _useZro, _adapterParams);
    }

    function estimateSendAndCallFee(uint16 _dstChainId, bytes32 _toAddress, uint _amount, bytes calldata _payload, uint64 _dstGasForCall, bool _useZro, bytes calldata _adapterParams) public view virtual override returns (uint nativeFee, uint zroFee) {
        return _estimateSendAndCallFee(_dstChainId, _toAddress, _amount, _payload, _dstGasForCall, _useZro, _adapterParams);
    }

    function circulatingSupply() public view virtual override returns (uint);

    function token() public view virtual override returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../../lzApp/NonblockingLzApp.sol";
import "../../../util/ExcessivelySafeCall.sol";
import "./ICommonOFT.sol";
import "./IOFTReceiverV2.sol";

abstract contract OFTCoreV2 is NonblockingLzApp {
    using BytesLib for bytes;
    using ExcessivelySafeCall for address;

    uint public constant NO_EXTRA_GAS = 0;

    // packet type
    uint8 public constant PT_SEND = 0;
    uint8 public constant PT_SEND_AND_CALL = 1;

    uint8 public immutable sharedDecimals;

    bool public useCustomAdapterParams;
    mapping(uint16 => mapping(bytes => mapping(uint64 => bool))) public creditedPackets;

    /**
     * @dev Emitted when `_amount` tokens are moved from the `_sender` to (`_dstChainId`, `_toAddress`)
     * `_nonce` is the outbound nonce
     */
    event SendToChain(uint16 indexed _dstChainId, address indexed _from, bytes32 indexed _toAddress, uint _amount);

    /**
     * @dev Emitted when `_amount` tokens are received from `_srcChainId` into the `_toAddress` on the local chain.
     * `_nonce` is the inbound nonce.
     */
    event ReceiveFromChain(uint16 indexed _srcChainId, address indexed _to, uint _amount);

    event SetUseCustomAdapterParams(bool _useCustomAdapterParams);

    event CallOFTReceivedSuccess(uint16 indexed _srcChainId, bytes _srcAddress, uint64 _nonce, bytes32 _hash);

    event NonContractAddress(address _address);

    // _sharedDecimals should be the minimum decimals on all chains
    constructor(uint8 _sharedDecimals, address _lzEndpoint) NonblockingLzApp(_lzEndpoint) {
        sharedDecimals = _sharedDecimals;
    }

    /************************************************************************
    * public functions
    ************************************************************************/
    function callOnOFTReceived(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes32 _from, address _to, uint _amount, bytes calldata _payload, uint _gasForCall) public virtual {
        require(_msgSender() == address(this), "OFTCore: caller must be OFTCore");

        // send
        _amount = _transferFrom(address(this), _to, _amount);
        emit ReceiveFromChain(_srcChainId, _to, _amount);

        // call
        IOFTReceiverV2(_to).onOFTReceived{gas: _gasForCall}(_srcChainId, _srcAddress, _nonce, _from, _amount, _payload);
    }

    function setUseCustomAdapterParams(bool _useCustomAdapterParams) public virtual onlyOwner {
        useCustomAdapterParams = _useCustomAdapterParams;
        emit SetUseCustomAdapterParams(_useCustomAdapterParams);
    }

    /************************************************************************
    * internal functions
    ************************************************************************/
    function _estimateSendFee(uint16 _dstChainId, bytes32 _toAddress, uint _amount, bool _useZro, bytes memory _adapterParams) internal view virtual returns (uint nativeFee, uint zroFee) {
        // mock the payload for sendFrom()
        bytes memory payload = _encodeSendPayload(_toAddress, _ld2sd(_amount));
        return lzEndpoint.estimateFees(_dstChainId, address(this), payload, _useZro, _adapterParams);
    }

    function _estimateSendAndCallFee(uint16 _dstChainId, bytes32 _toAddress, uint _amount, bytes memory _payload, uint64 _dstGasForCall, bool _useZro, bytes memory _adapterParams) internal view virtual returns (uint nativeFee, uint zroFee) {
        // mock the payload for sendAndCall()
        bytes memory payload = _encodeSendAndCallPayload(msg.sender, _toAddress, _ld2sd(_amount), _payload, _dstGasForCall);
        return lzEndpoint.estimateFees(_dstChainId, address(this), payload, _useZro, _adapterParams);
    }

    function _nonblockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual override {
        uint8 packetType = _payload.toUint8(0);

        if (packetType == PT_SEND) {
            _sendAck(_srcChainId, _srcAddress, _nonce, _payload);
        } else if (packetType == PT_SEND_AND_CALL) {
            _sendAndCallAck(_srcChainId, _srcAddress, _nonce, _payload);
        } else {
            revert("OFTCore: unknown packet type");
        }
    }

    function _send(address _from, uint16 _dstChainId, bytes32 _toAddress, uint _amount, address payable _refundAddress, address _zroPaymentAddress, bytes memory _adapterParams) internal virtual returns (uint amount) {
        _checkAdapterParams(_dstChainId, PT_SEND, _adapterParams, NO_EXTRA_GAS);

        (amount,) = _removeDust(_amount);
        amount = _debitFrom(_from, _dstChainId, _toAddress, amount); // amount returned should not have dust
        require(amount > 0, "OFTCore: amount too small");

        bytes memory lzPayload = _encodeSendPayload(_toAddress, _ld2sd(amount));
        _lzSend(_dstChainId, lzPayload, _refundAddress, _zroPaymentAddress, _adapterParams, msg.value);

        emit SendToChain(_dstChainId, _from, _toAddress, amount);
    }

    function _sendAck(uint16 _srcChainId, bytes memory, uint64, bytes memory _payload) internal virtual {
        (address to, uint64 amountSD) = _decodeSendPayload(_payload);
        if (to == address(0)) {
            to = address(0xdead);
        }

        uint amount = _sd2ld(amountSD);
        amount = _creditTo(_srcChainId, to, amount);

        emit ReceiveFromChain(_srcChainId, to, amount);
    }

    function _sendAndCall(address _from, uint16 _dstChainId, bytes32 _toAddress, uint _amount, bytes memory _payload, uint64 _dstGasForCall, address payable _refundAddress, address _zroPaymentAddress, bytes memory _adapterParams) internal virtual returns (uint amount) {
        _checkAdapterParams(_dstChainId, PT_SEND_AND_CALL, _adapterParams, _dstGasForCall);

        (amount,) = _removeDust(_amount);
        amount = _debitFrom(_from, _dstChainId, _toAddress, amount);
        require(amount > 0, "OFTCore: amount too small");

        // encode the msg.sender into the payload instead of _from
        bytes memory lzPayload = _encodeSendAndCallPayload(msg.sender, _toAddress, _ld2sd(amount), _payload, _dstGasForCall);
        _lzSend(_dstChainId, lzPayload, _refundAddress, _zroPaymentAddress, _adapterParams, msg.value);

        emit SendToChain(_dstChainId, _from, _toAddress, amount);
    }

    function _sendAndCallAck(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual {
        (bytes32 from, address to, uint64 amountSD, bytes memory payloadForCall, uint64 gasForCall) = _decodeSendAndCallPayload(_payload);

        bool credited = creditedPackets[_srcChainId][_srcAddress][_nonce];
        uint amount = _sd2ld(amountSD);

        // credit to this contract first, and then transfer to receiver only if callOnOFTReceived() succeeds
        if (!credited) {
            amount = _creditTo(_srcChainId, address(this), amount);
            creditedPackets[_srcChainId][_srcAddress][_nonce] = true;
        }

        if (!_isContract(to)) {
            emit NonContractAddress(to);
            return;
        }

        // workaround for stack too deep
        uint16 srcChainId = _srcChainId;
        bytes memory srcAddress = _srcAddress;
        uint64 nonce = _nonce;
        bytes memory payload = _payload;
        bytes32 from_ = from;
        address to_ = to;
        uint amount_ = amount;
        bytes memory payloadForCall_ = payloadForCall;

        // no gas limit for the call if retry
        uint gas = credited ? gasleft() : gasForCall;
        (bool success, bytes memory reason) = address(this).excessivelySafeCall(gasleft(), 150, abi.encodeWithSelector(this.callOnOFTReceived.selector, srcChainId, srcAddress, nonce, from_, to_, amount_, payloadForCall_, gas));

        if (success) {
            bytes32 hash = keccak256(payload);
            emit CallOFTReceivedSuccess(srcChainId, srcAddress, nonce, hash);
        } else {
            // store the failed message into the nonblockingLzApp
            _storeFailedMessage(srcChainId, srcAddress, nonce, payload, reason);
        }
    }

    function _isContract(address _account) internal view returns (bool) {
        return _account.code.length > 0;
    }

    function _checkAdapterParams(uint16 _dstChainId, uint16 _pkType, bytes memory _adapterParams, uint _extraGas) internal virtual {
        if (useCustomAdapterParams) {
            _checkGasLimit(_dstChainId, _pkType, _adapterParams, _extraGas);
        } else {
            require(_adapterParams.length == 0, "OFTCore: _adapterParams must be empty.");
        }
    }

    function _ld2sd(uint _amount) internal virtual view returns (uint64) {
        uint amountSD = _amount / _ld2sdRate();
        require(amountSD <= type(uint64).max, "OFTCore: amountSD overflow");
        return uint64(amountSD);
    }

    function _sd2ld(uint64 _amountSD) internal virtual view returns (uint) {
        return _amountSD * _ld2sdRate();
    }

    function _removeDust(uint _amount) internal virtual view returns (uint amountAfter, uint dust) {
        dust = _amount % _ld2sdRate();
        amountAfter = _amount - dust;
    }

    function _encodeSendPayload(bytes32 _toAddress, uint64 _amountSD) internal virtual view returns (bytes memory) {
        return abi.encodePacked(PT_SEND, _toAddress, _amountSD);
    }

    function _decodeSendPayload(bytes memory _payload) internal virtual view returns (address to, uint64 amountSD) {
        require(_payload.toUint8(0) == PT_SEND && _payload.length == 41, "OFTCore: invalid payload");

        to = _payload.toAddress(13); // drop the first 12 bytes of bytes32
        amountSD = _payload.toUint64(33);
    }

    function _encodeSendAndCallPayload(address _from, bytes32 _toAddress, uint64 _amountSD, bytes memory _payload, uint64 _dstGasForCall) internal virtual view returns (bytes memory) {
        return abi.encodePacked(
            PT_SEND_AND_CALL,
            _toAddress,
            _amountSD,
            _addressToBytes32(_from),
            _dstGasForCall,
            _payload
        );
    }

    function _decodeSendAndCallPayload(bytes memory _payload) internal virtual view returns (bytes32 from, address to, uint64 amountSD, bytes memory payload, uint64 dstGasForCall) {
        require(_payload.toUint8(0) == PT_SEND_AND_CALL, "OFTCore: invalid payload");

        to = _payload.toAddress(13); // drop the first 12 bytes of bytes32
        amountSD = _payload.toUint64(33);
        from = _payload.toBytes32(41);
        dstGasForCall = _payload.toUint64(73);
        payload = _payload.slice(81, _payload.length - 81);
    }

    function _addressToBytes32(address _address) internal pure virtual returns (bytes32) {
        return bytes32(uint(uint160(_address)));
    }

    function _debitFrom(address _from, uint16 _dstChainId, bytes32 _toAddress, uint _amount) internal virtual returns (uint);

    function _creditTo(uint16 _srcChainId, address _toAddress, uint _amount) internal virtual returns (uint);

    function _transferFrom(address _from, address _to, uint _amount) internal virtual returns (uint);

    function _ld2sdRate() internal view virtual returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "./ICommonOFT.sol";

/**
 * @dev Interface of the IOFT core standard
 */
interface IOFTV2 is ICommonOFT {

    /**
     * @dev send `_amount` amount of token to (`_dstChainId`, `_toAddress`) from `_from`
     * `_from` the owner of token
     * `_dstChainId` the destination chain identifier
     * `_toAddress` can be any size depending on the `dstChainId`.
     * `_amount` the quantity of tokens in wei
     * `_refundAddress` the address LayerZero refunds if too much message fee is sent
     * `_zroPaymentAddress` set to address(0x0) if not paying in ZRO (LayerZero Token)
     * `_adapterParams` is a flexible bytes array to indicate messaging adapter services
     */
    function sendFrom(address _from, uint16 _dstChainId, bytes32 _toAddress, uint _amount, LzCallParams calldata _callParams) external payable;

    function sendAndCall(address _from, uint16 _dstChainId, bytes32 _toAddress, uint _amount, bytes calldata _payload, uint64 _dstGasForCall, LzCallParams calldata _callParams) external payable;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./LzApp.sol";
import "../util/ExcessivelySafeCall.sol";

/*
 * the default LayerZero messaging behaviour is blocking, i.e. any failed message will block the channel
 * this abstract class try-catch all fail messages and store locally for future retry. hence, non-blocking
 * NOTE: if the srcAddress is not configured properly, it will still block the message pathway from (srcChainId, srcAddress)
 */
abstract contract NonblockingLzApp is LzApp {
    using ExcessivelySafeCall for address;

    constructor(address _endpoint) LzApp(_endpoint) {}

    mapping(uint16 => mapping(bytes => mapping(uint64 => bytes32))) public failedMessages;

    event MessageFailed(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes _payload, bytes _reason);
    event RetryMessageSuccess(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes32 _payloadHash);

    // overriding the virtual function in LzReceiver
    function _blockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual override {
        (bool success, bytes memory reason) = address(this).excessivelySafeCall(gasleft(), 150, abi.encodeWithSelector(this.nonblockingLzReceive.selector, _srcChainId, _srcAddress, _nonce, _payload));
        // try-catch all errors/exceptions
        if (!success) {
            _storeFailedMessage(_srcChainId, _srcAddress, _nonce, _payload, reason);
        }
    }

    function _storeFailedMessage(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload, bytes memory _reason) internal virtual {
        failedMessages[_srcChainId][_srcAddress][_nonce] = keccak256(_payload);
        emit MessageFailed(_srcChainId, _srcAddress, _nonce, _payload, _reason);
    }

    function nonblockingLzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) public virtual {
        // only internal transaction
        require(_msgSender() == address(this), "NonblockingLzApp: caller must be LzApp");
        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    //@notice override this function
    function _nonblockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual;

    function retryMessage(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) public payable virtual {
        // assert there is message to retry
        bytes32 payloadHash = failedMessages[_srcChainId][_srcAddress][_nonce];
        require(payloadHash != bytes32(0), "NonblockingLzApp: no stored message");
        require(keccak256(_payload) == payloadHash, "NonblockingLzApp: invalid payload");
        // clear the stored message
        failedMessages[_srcChainId][_srcAddress][_nonce] = bytes32(0);
        // execute the message. revert if it fails again
        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
        emit RetryMessageSuccess(_srcChainId, _srcAddress, _nonce, payloadHash);
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.7.6;

library ExcessivelySafeCall {
    uint256 constant LOW_28_MASK =
    0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeCall(
        address _target,
        uint256 _gas,
        uint16 _maxCopy,
        bytes memory _calldata
    ) internal returns (bool, bytes memory) {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success := call(
            _gas, // gas
            _target, // recipient
            0, // ether value
            add(_calldata, 0x20), // inloc
            mload(_calldata), // inlen
            0, // outloc
            0 // outlen
            )
        // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
        // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
        // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeStaticCall(
        address _target,
        uint256 _gas,
        uint16 _maxCopy,
        bytes memory _calldata
    ) internal view returns (bool, bytes memory) {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success := staticcall(
            _gas, // gas
            _target, // recipient
            add(_calldata, 0x20), // inloc
            mload(_calldata), // inlen
            0, // outloc
            0 // outlen
            )
        // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
        // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
        // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /**
     * @notice Swaps function selectors in encoded contract calls
     * @dev Allows reuse of encoded calldata for functions with identical
     * argument types but different names. It simply swaps out the first 4 bytes
     * for the new selector. This function modifies memory in place, and should
     * only be used with caution.
     * @param _newSelector The new 4-byte selector
     * @param _buf The encoded contract args
     */
    function swapSelector(bytes4 _newSelector, bytes memory _buf)
    internal
    pure
    {
        require(_buf.length >= 4);
        uint256 _mask = LOW_28_MASK;
        assembly {
        // load the first word of
            let _word := mload(add(_buf, 0x20))
        // mask out the top 4 bytes
        // /x
            _word := and(_word, _mask)
            _word := or(_newSelector, _word)
            mstore(add(_buf, 0x20), _word)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Interface of the IOFT core standard
 */
interface ICommonOFT is IERC165 {

    struct LzCallParams {
        address payable refundAddress;
        address zroPaymentAddress;
        bytes adapterParams;
    }

    /**
     * @dev estimate send token `_tokenId` to (`_dstChainId`, `_toAddress`)
     * _dstChainId - L0 defined chain id to send tokens too
     * _toAddress - dynamic bytes array which contains the address to whom you are sending tokens to on the dstChain
     * _amount - amount of the tokens to transfer
     * _useZro - indicates to use zro to pay L0 fees
     * _adapterParam - flexible bytes array to indicate messaging adapter services in L0
     */
    function estimateSendFee(uint16 _dstChainId, bytes32 _toAddress, uint _amount, bool _useZro, bytes calldata _adapterParams) external view returns (uint nativeFee, uint zroFee);

    function estimateSendAndCallFee(uint16 _dstChainId, bytes32 _toAddress, uint _amount, bytes calldata _payload, uint64 _dstGasForCall, bool _useZro, bytes calldata _adapterParams) external view returns (uint nativeFee, uint zroFee);

    /**
     * @dev returns the circulating amount of tokens on current chain
     */
    function circulatingSupply() external view returns (uint);

    /**
     * @dev returns the address of the ERC20 token
     */
    function token() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

interface IOFTReceiverV2 {
    /**
     * @dev Called by the OFT contract when tokens are received from source chain.
     * @param _srcChainId The chain id of the source chain.
     * @param _srcAddress The address of the OFT token contract on the source chain.
     * @param _nonce The nonce of the transaction on the source chain.
     * @param _from The address of the account who calls the sendAndCall() on the source chain.
     * @param _amount The amount of tokens to transfer.
     * @param _payload Additional data with no specified format.
     */
    function onOFTReceived(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes32 _from, uint _amount, bytes calldata _payload) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ILayerZeroReceiver.sol";
import "../interfaces/ILayerZeroUserApplicationConfig.sol";
import "../interfaces/ILayerZeroEndpoint.sol";
import "../util/BytesLib.sol";

/*
 * a generic LzReceiver implementation
 */
abstract contract LzApp is Ownable, ILayerZeroReceiver, ILayerZeroUserApplicationConfig {
    using BytesLib for bytes;

    // ua can not send payload larger than this by default, but it can be changed by the ua owner
    uint constant public DEFAULT_PAYLOAD_SIZE_LIMIT = 10000;

    ILayerZeroEndpoint public immutable lzEndpoint;
    mapping(uint16 => bytes) public trustedRemoteLookup;
    mapping(uint16 => mapping(uint16 => uint)) public minDstGasLookup;
    mapping(uint16 => uint) public payloadSizeLimitLookup;
    address public precrime;

    event SetPrecrime(address precrime);
    event SetTrustedRemote(uint16 _remoteChainId, bytes _path);
    event SetTrustedRemoteAddress(uint16 _remoteChainId, bytes _remoteAddress);
    event SetMinDstGas(uint16 _dstChainId, uint16 _type, uint _minDstGas);

    constructor(address _endpoint) {
        lzEndpoint = ILayerZeroEndpoint(_endpoint);
    }

    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) public virtual override {
        // lzReceive must be called by the endpoint for security
        require(_msgSender() == address(lzEndpoint), "LzApp: invalid endpoint caller");

        bytes memory trustedRemote = trustedRemoteLookup[_srcChainId];
        // if will still block the message pathway from (srcChainId, srcAddress). should not receive message from untrusted remote.
        require(_srcAddress.length == trustedRemote.length && trustedRemote.length > 0 && keccak256(_srcAddress) == keccak256(trustedRemote), "LzApp: invalid source sending contract");

        _blockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    // abstract function - the default behaviour of LayerZero is blocking. See: NonblockingLzApp if you dont need to enforce ordered messaging
    function _blockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual;

    function _lzSend(uint16 _dstChainId, bytes memory _payload, address payable _refundAddress, address _zroPaymentAddress, bytes memory _adapterParams, uint _nativeFee) internal virtual {
        bytes memory trustedRemote = trustedRemoteLookup[_dstChainId];
        require(trustedRemote.length != 0, "LzApp: destination chain is not a trusted source");
        _checkPayloadSize(_dstChainId, _payload.length);
        lzEndpoint.send{value: _nativeFee}(_dstChainId, trustedRemote, _payload, _refundAddress, _zroPaymentAddress, _adapterParams);
    }

    function _checkGasLimit(uint16 _dstChainId, uint16 _type, bytes memory _adapterParams, uint _extraGas) internal view virtual {
        uint providedGasLimit = _getGasLimit(_adapterParams);
        uint minGasLimit = minDstGasLookup[_dstChainId][_type] + _extraGas;
        require(minGasLimit > 0, "LzApp: minGasLimit not set");
        require(providedGasLimit >= minGasLimit, "LzApp: gas limit is too low");
    }

    function _getGasLimit(bytes memory _adapterParams) internal pure virtual returns (uint gasLimit) {
        require(_adapterParams.length >= 34, "LzApp: invalid adapterParams");
        assembly {
            gasLimit := mload(add(_adapterParams, 34))
        }
    }

    function _checkPayloadSize(uint16 _dstChainId, uint _payloadSize) internal view virtual {
        uint payloadSizeLimit = payloadSizeLimitLookup[_dstChainId];
        if (payloadSizeLimit == 0) { // use default if not set
            payloadSizeLimit = DEFAULT_PAYLOAD_SIZE_LIMIT;
        }
        require(_payloadSize <= payloadSizeLimit, "LzApp: payload size is too large");
    }

    //---------------------------UserApplication config----------------------------------------
    function getConfig(uint16 _version, uint16 _chainId, address, uint _configType) external view returns (bytes memory) {
        return lzEndpoint.getConfig(_version, _chainId, address(this), _configType);
    }

    // generic config for LayerZero user Application
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external override onlyOwner {
        lzEndpoint.setConfig(_version, _chainId, _configType, _config);
    }

    function setSendVersion(uint16 _version) external override onlyOwner {
        lzEndpoint.setSendVersion(_version);
    }

    function setReceiveVersion(uint16 _version) external override onlyOwner {
        lzEndpoint.setReceiveVersion(_version);
    }

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external override onlyOwner {
        lzEndpoint.forceResumeReceive(_srcChainId, _srcAddress);
    }

    // _path = abi.encodePacked(remoteAddress, localAddress)
    // this function set the trusted path for the cross-chain communication
    function setTrustedRemote(uint16 _srcChainId, bytes calldata _path) external onlyOwner {
        trustedRemoteLookup[_srcChainId] = _path;
        emit SetTrustedRemote(_srcChainId, _path);
    }

    function setTrustedRemoteAddress(uint16 _remoteChainId, bytes calldata _remoteAddress) external onlyOwner {
        trustedRemoteLookup[_remoteChainId] = abi.encodePacked(_remoteAddress, address(this));
        emit SetTrustedRemoteAddress(_remoteChainId, _remoteAddress);
    }

    function getTrustedRemoteAddress(uint16 _remoteChainId) external view returns (bytes memory) {
        bytes memory path = trustedRemoteLookup[_remoteChainId];
        require(path.length != 0, "LzApp: no trusted path record");
        return path.slice(0, path.length - 20); // the last 20 bytes should be address(this)
    }

    function setPrecrime(address _precrime) external onlyOwner {
        precrime = _precrime;
        emit SetPrecrime(_precrime);
    }

    function setMinDstGas(uint16 _dstChainId, uint16 _packetType, uint _minGas) external onlyOwner {
        require(_minGas > 0, "LzApp: invalid minGas");
        minDstGasLookup[_dstChainId][_packetType] = _minGas;
        emit SetMinDstGas(_dstChainId, _packetType, _minGas);
    }

    // if the size is 0, it means default size limit
    function setPayloadSizeLimit(uint16 _dstChainId, uint _size) external onlyOwner {
        payloadSizeLimitLookup[_dstChainId] = _size;
    }

    //--------------------------- VIEW FUNCTION ----------------------------------------
    function isTrustedRemote(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool) {
        bytes memory trustedSource = trustedRemoteLookup[_srcChainId];
        return keccak256(trustedSource) == keccak256(_srcAddress);
    }
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
    internal
    pure
    returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
        // Get a location of some free memory and store it in tempBytes as
        // Solidity does for memory variables.
            tempBytes := mload(0x40)

        // Store the length of the first bytes array at the beginning of
        // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

        // Maintain a memory counter for the current write location in the
        // temp bytes array by adding the 32 bytes for the array length to
        // the starting location.
            let mc := add(tempBytes, 0x20)
        // Stop copying when the memory counter reaches the length of the
        // first bytes array.
            let end := add(mc, length)

            for {
            // Initialize a copy counter to the start of the _preBytes data,
            // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
            // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
            // Write the _preBytes data into the tempBytes memory 32 bytes
            // at a time.
                mstore(mc, mload(cc))
            }

        // Add the length of _postBytes to the current length of tempBytes
        // and store it as the new length in the first 32 bytes of the
        // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

        // Move the memory counter back from a multiple of 0x20 to the
        // actual end of the _preBytes data.
            mc := end
        // Stop copying when the memory counter reaches the new combined
        // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

        // Update the free-memory pointer by padding our last write location
        // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
        // next 32 byte block, then round down to the nearest multiple of
        // 32. If the sum of the length of the two arrays is zero then add
        // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
            add(add(end, iszero(add(length, mload(_preBytes)))), 31),
            not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
        // Read the first 32 bytes of _preBytes storage, which is the length
        // of the array. (We don't need to use the offset into the slot
        // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
        // Arrays of 31 bytes or less have an even value in their slot,
        // while longer arrays have an odd value. The actual length is
        // the slot divided by two for odd values, and the lowest order
        // byte divided by two for even values.
        // If the slot is even, bitwise and the slot with 255 and divide by
        // two to get the length. If the slot is odd, bitwise and the slot
        // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
        // slength can contain both the length and contents of the array
        // if length < 32 bytes so let's prepare for that
        // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
            // Since the new array still fits in the slot, we just need to
            // update the contents of the slot.
            // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                _preBytes.slot,
                // all the modifications to the slot are inside this
                // next block
                add(
                // we can just add to the slot contents because the
                // bytes we want to change are the LSBs
                fslot,
                add(
                mul(
                div(
                // load the bytes from memory
                mload(add(_postBytes, 0x20)),
                // zero all bytes to the right
                exp(0x100, sub(32, mlength))
                ),
                // and now shift left the number of bytes to
                // leave space for the length in the slot
                exp(0x100, sub(32, newlength))
                ),
                // increase length by the double of the memory
                // bytes length
                mul(mlength, 2)
                )
                )
                )
            }
            case 1 {
            // The stored value fits in the slot, but the combined value
            // will exceed it.
            // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

            // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

            // The contents of the _postBytes array start 32 bytes into
            // the structure. Our first read should obtain the `submod`
            // bytes that can fit into the unused space in the last word
            // of the stored array. To get this, we read 32 bytes starting
            // from `submod`, so the data we read overlaps with the array
            // contents by `submod` bytes. Masking the lowest-order
            // `submod` bytes allows us to add that value directly to the
            // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                sc,
                add(
                and(
                fslot,
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                ),
                and(mload(mc), mask)
                )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
            // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
            // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

            // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

            // Copy over the first `submod` bytes of the new data as in
            // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
    internal
    pure
    returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
                tempBytes := mload(0x40)

            // The first word of the slice result is potentially a partial
            // word read from the original array. To read it, we calculate
            // the length of that partial word and start copying that many
            // bytes into the array. The first word we copy will start with
            // data we don't care about, but the last `lengthmod` bytes will
            // land at the beginning of the contents of the new array. When
            // we're done copying, we overwrite the full first word with
            // the actual length of the slice.
                let lengthmod := and(_length, 31)

            // The multiplication in the next line is necessary
            // because when slicing multiples of 32 bytes (lengthmod == 0)
            // the following copy loop was copying the origin's length
            // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                // The multiplication in the next line has the same exact purpose
                // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

            //update free-memory pointer
            //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
            //zero out the 32 bytes slice we are about to return
            //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

        // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
            // cb is a circuit breaker in the for loop since there's
            //  no said feature for inline assembly loops
            // cb = 1 - don't breaker
            // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                    // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
            // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
    internal
    view
    returns (bool)
    {
        bool success = true;

        assembly {
        // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
        // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

        // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                    // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                        // unsuccess:
                            success := 0
                        }
                    }
                    default {
                    // cb is a circuit breaker in the for loop since there's
                    //  no said feature for inline assembly loops
                    // cb = 1 - don't breaker
                    // cb = 0 - break
                        let cb := 1

                    // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                    // the next line is the loop condition:
                    // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                            // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
            // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}