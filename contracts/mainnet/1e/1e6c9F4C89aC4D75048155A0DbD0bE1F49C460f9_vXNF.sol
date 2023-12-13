// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAxelarGateway } from '../interfaces/IAxelarGateway.sol';
import { IAxelarExecutable } from '../interfaces/IAxelarExecutable.sol';

contract AxelarExecutable is IAxelarExecutable {
    IAxelarGateway public immutable gateway;

    constructor(address gateway_) {
        if (gateway_ == address(0)) revert InvalidAddress();

        gateway = IAxelarGateway(gateway_);
    }

    function execute(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external {
        bytes32 payloadHash = keccak256(payload);

        if (!gateway.validateContractCall(commandId, sourceChain, sourceAddress, payloadHash))
            revert NotApprovedByGateway();

        _execute(sourceChain, sourceAddress, payload);
    }

    function executeWithToken(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) external {
        bytes32 payloadHash = keccak256(payload);

        if (
            !gateway.validateContractCallAndMint(
                commandId,
                sourceChain,
                sourceAddress,
                payloadHash,
                tokenSymbol,
                amount
            )
        ) revert NotApprovedByGateway();

        _executeWithToken(sourceChain, sourceAddress, payload, tokenSymbol, amount);
    }

    function _execute(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) internal virtual {}

    function _executeWithToken(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAxelarGateway } from './IAxelarGateway.sol';

interface IAxelarExecutable {
    error InvalidAddress();
    error NotApprovedByGateway();

    function gateway() external view returns (IAxelarGateway);

    function execute(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external;

    function executeWithToken(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// This should be owned by the microservice that is paying for gas.
interface IAxelarGasService {
    error NothingReceived();
    error InvalidAddress();
    error NotCollector();
    error InvalidAmounts();

    event GasPaidForContractCall(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event GasPaidForContractCallWithToken(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasPaidForContractCall(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasPaidForContractCallWithToken(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event GasPaidForExpressCallWithToken(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasPaidForExpressCallWithToken(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event GasAdded(
        bytes32 indexed txHash,
        uint256 indexed logIndex,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasAdded(bytes32 indexed txHash, uint256 indexed logIndex, uint256 gasFeeAmount, address refundAddress);

    event ExpressGasAdded(
        bytes32 indexed txHash,
        uint256 indexed logIndex,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeExpressGasAdded(
        bytes32 indexed txHash,
        uint256 indexed logIndex,
        uint256 gasFeeAmount,
        address refundAddress
    );

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payGasForContractCall(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payGasForContractCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payNativeGasForContractCall(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundAddress
    ) external payable;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payNativeGasForContractCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address refundAddress
    ) external payable;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payGasForExpressCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payNativeGasForExpressCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address refundAddress
    ) external payable;

    function addGas(
        bytes32 txHash,
        uint256 txIndex,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    function addNativeGas(
        bytes32 txHash,
        uint256 logIndex,
        address refundAddress
    ) external payable;

    function addExpressGas(
        bytes32 txHash,
        uint256 txIndex,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    function addNativeExpressGas(
        bytes32 txHash,
        uint256 logIndex,
        address refundAddress
    ) external payable;

    function collectFees(
        address payable receiver,
        address[] calldata tokens,
        uint256[] calldata amounts
    ) external;

    function refund(
        address payable receiver,
        address token,
        uint256 amount
    ) external;

    function gasCollector() external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAxelarGateway {
    /**********\
    |* Errors *|
    \**********/

    error NotSelf();
    error NotProxy();
    error InvalidCodeHash();
    error SetupFailed();
    error InvalidAuthModule();
    error InvalidTokenDeployer();
    error InvalidAmount();
    error InvalidChainId();
    error InvalidCommands();
    error TokenDoesNotExist(string symbol);
    error TokenAlreadyExists(string symbol);
    error TokenDeployFailed(string symbol);
    error TokenContractDoesNotExist(address token);
    error BurnFailed(string symbol);
    error MintFailed(string symbol);
    error InvalidSetMintLimitsParams();
    error ExceedMintLimit(string symbol);

    /**********\
    |* Events *|
    \**********/

    event TokenSent(
        address indexed sender,
        string destinationChain,
        string destinationAddress,
        string symbol,
        uint256 amount
    );

    event ContractCall(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload
    );

    event ContractCallWithToken(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload,
        string symbol,
        uint256 amount
    );

    event Executed(bytes32 indexed commandId);

    event TokenDeployed(string symbol, address tokenAddresses);

    event ContractCallApproved(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        address indexed contractAddress,
        bytes32 indexed payloadHash,
        bytes32 sourceTxHash,
        uint256 sourceEventIndex
    );

    event ContractCallApprovedWithMint(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        address indexed contractAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        bytes32 sourceTxHash,
        uint256 sourceEventIndex
    );

    event TokenMintLimitUpdated(string symbol, uint256 limit);

    event OperatorshipTransferred(bytes newOperatorsData);

    event Upgraded(address indexed implementation);

    /********************\
    |* Public Functions *|
    \********************/

    function sendToken(
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata symbol,
        uint256 amount
    ) external;

    function callContract(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload
    ) external;

    function callContractWithToken(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount
    ) external;

    function isContractCallApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash
    ) external view returns (bool);

    function isContractCallAndMintApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external view returns (bool);

    function validateContractCall(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash
    ) external returns (bool);

    function validateContractCallAndMint(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external returns (bool);

    /***********\
    |* Getters *|
    \***********/

    function authModule() external view returns (address);

    function tokenDeployer() external view returns (address);

    function tokenMintLimit(string memory symbol) external view returns (uint256);

    function tokenMintAmount(string memory symbol) external view returns (uint256);

    function allTokensFrozen() external view returns (bool);

    function implementation() external view returns (address);

    function tokenAddresses(string memory symbol) external view returns (address);

    function tokenFrozen(string memory symbol) external view returns (bool);

    function isCommandExecuted(bytes32 commandId) external view returns (bool);

    function adminEpoch() external view returns (uint256);

    function adminThreshold(uint256 epoch) external view returns (uint256);

    function admins(uint256 epoch) external view returns (address[] memory);

    /*******************\
    |* Admin Functions *|
    \*******************/

    function setTokenMintLimits(string[] calldata symbols, uint256[] calldata limits) external;

    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata setupParams
    ) external;

    /**********************\
    |* External Functions *|
    \**********************/

    function setup(bytes calldata params) external;

    function execute(bytes calldata input) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library StringToAddress {
    error InvalidAddressString();

    function toAddress(string memory addressString) internal pure returns (address) {
        bytes memory stringBytes = bytes(addressString);
        uint160 addressNumber = 0;
        uint8 stringByte;

        if (stringBytes.length != 42 || stringBytes[0] != '0' || stringBytes[1] != 'x') revert InvalidAddressString();

        for (uint256 i = 2; i < 42; ++i) {
            stringByte = uint8(stringBytes[i]);

            if ((stringByte >= 97) && (stringByte <= 102)) stringByte -= 87;
            else if ((stringByte >= 65) && (stringByte <= 70)) stringByte -= 55;
            else if ((stringByte >= 48) && (stringByte <= 57)) stringByte -= 48;
            else revert InvalidAddressString();

            addressNumber |= uint160(uint256(stringByte) << ((41 - i) << 2));
        }
        return address(addressNumber);
    }
}

library AddressToString {
    function toString(address addr) internal pure returns (string memory) {
        bytes memory addressBytes = abi.encodePacked(addr);
        uint256 length = addressBytes.length;
        bytes memory characters = '0123456789abcdef';
        bytes memory stringBytes = new bytes(2 + addressBytes.length * 2);

        stringBytes[0] = '0';
        stringBytes[1] = 'x';

        for (uint256 i; i < length; ++i) {
            stringBytes[2 + i * 2] = characters[uint8(addressBytes[i] >> 4)];
            stringBytes[3 + i * 2] = characters[uint8(addressBytes[i] & 0x0f)];
        }
        return string(stringBytes);
    }
}

// SPDX-License-Identifier: BUSL-1.1

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
    function send(
        uint16 _dstChainId,
        bytes calldata _destination,
        bytes calldata _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        address _dstAddress,
        uint64 _nonce,
        uint _gasLimit,
        bytes calldata _payload
    ) external;

    // @notice get the inboundNonce of a receiver from a source chain which could be EVM or non-EVM chain
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
    function estimateFees(
        uint16 _dstChainId,
        address _userApplication,
        bytes calldata _payload,
        bool _payInZRO,
        bytes calldata _adapterParam
    ) external view returns (uint nativeFee, uint zroFee);

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
    function getConfig(
        uint16 _version,
        uint16 _chainId,
        address _userApplication,
        uint _configType
    ) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication) external view returns (uint16);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
}

// SPDX-License-Identifier: BUSL-1.1

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

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
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
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
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
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
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
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
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

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
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
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

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.18;

/*
 * @title IBurnableToken Interface
 *
 * @notice This interface defines a basic burn function for ERC20-like tokens.
 * Implementing contracts should fire a Transfer event with the burn address (0x0)
 * as the recipient when a burn occurs, in accordance with the ERC20 standard.
 *
 * Co-Founders:
 * - Simran Dhillon: [email protected]
 * - Hardev Dhillon: [email protected]
 * - Dayana Plaz: [email protected]
 *
 * Official Links:
 * - Twitter: https://twitter.com/xenify_io
 * - Telegram: https://t.me/xenify_io
 * - Website: https://xenify.io
 *
 * Disclaimer:
 * This contract aligns with the principles of the Fair Crypto Foundation, promoting self-custody, transparency, consensus-based
 * trust, and permissionless value exchange. There are no administrative access keys, underscoring our commitment to decentralization.
 * Engaging with this contract involves technical and legal risks. Users must conduct their own due diligence and ensure compliance
 * with local laws and regulations. The software is provided "AS-IS," without warranties, and the co-founders and developers disclaim
 * all liability for any vulnerabilities, exploits, errors, or breaches that may occur. By using this contract, users accept all associated
 * risks and this disclaimer. The co-founders, developers, or related parties will not bear liability for any consequences of non-compliance.
 *
 * Redistribution and Use:
 * Redistribution, modification, or repurposing of this contract, in whole or in part, is strictly prohibited without express written
 * approval from all co-founders. Approval requests must be sent to the official email addresses of the co-founders, ensuring responses
 * are received directly from these addresses. Proposals for redistribution, modification, or repurposing must include a detailed explanation
 * of the intended changes or uses and the reasons behind them. The co-founders reserve the right to request additional information or
 * clarification as necessary. Approval is at the sole discretion of the co-founders and may be subject to conditions to uphold the
 * project’s integrity and the values of the Fair Crypto Foundation. Failure to obtain express written approval prior to any redistribution,
 * modification, or repurposing will result in a breach of these terms and immediate legal action.
 *
 * Copyright and License:
 * Copyright © 2023 Xenify (Simran Dhillon, Hardev Dhillon, Dayana Plaz). All rights reserved.
 * This software is provided 'as is' and may be used by the recipient. No permission is granted for redistribution,
 * modification, or repurposing of this contract. Any use beyond the scope defined herein may be subject to legal action.
 */
interface IBurnableToken {

    /// --------------------------------- EXTERNAL FUNCTION --------------------------------- \\\

    /**
     * @notice Destroys `amount` tokens from `user`, reducing the total supply.
     * @dev This operation is irreversible. Implementations should emit an ERC20 Transfer event
     * with to set to the zero address. Implementations should also enforce necessary conditions
     * such as allowance and balance checks.
     * @param user The account to burn tokens from.
     * @param amount The amount of tokens to be burned.
     */
    function burn(
        address user,
        uint256 amount
    ) external;

    /// ------------------------------------------------------------------------------------- \\\
}

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.18;

/*
 * @title IBurnRedeemable Interface
 *
 * @notice This interface defines the methods related to redeemable tokens that can be burned.
 *
 * Co-Founders:
 * - Simran Dhillon: [email protected]
 * - Hardev Dhillon: [email protected]
 * - Dayana Plaz: [email protected]
 *
 * Official Links:
 * - Twitter: https://twitter.com/xenify_io
 * - Telegram: https://t.me/xenify_io
 * - Website: https://xenify.io
 *
 * Disclaimer:
 * This contract aligns with the principles of the Fair Crypto Foundation, promoting self-custody, transparency, consensus-based
 * trust, and permissionless value exchange. There are no administrative access keys, underscoring our commitment to decentralization.
 * Engaging with this contract involves technical and legal risks. Users must conduct their own due diligence and ensure compliance
 * with local laws and regulations. The software is provided "AS-IS," without warranties, and the co-founders and developers disclaim
 * all liability for any vulnerabilities, exploits, errors, or breaches that may occur. By using this contract, users accept all associated
 * risks and this disclaimer. The co-founders, developers, or related parties will not bear liability for any consequences of non-compliance.
 *
 * Redistribution and Use:
 * Redistribution, modification, or repurposing of this contract, in whole or in part, is strictly prohibited without express written
 * approval from all co-founders. Approval requests must be sent to the official email addresses of the co-founders, ensuring responses
 * are received directly from these addresses. Proposals for redistribution, modification, or repurposing must include a detailed explanation
 * of the intended changes or uses and the reasons behind them. The co-founders reserve the right to request additional information or
 * clarification as necessary. Approval is at the sole discretion of the co-founders and may be subject to conditions to uphold the
 * project’s integrity and the values of the Fair Crypto Foundation. Failure to obtain express written approval prior to any redistribution,
 * modification, or repurposing will result in a breach of these terms and immediate legal action.
 *
 * Copyright and License:
 * Copyright © 2023 Xenify (Simran Dhillon, Hardev Dhillon, Dayana Plaz). All rights reserved.
 * This software is provided 'as is' and may be used by the recipient. No permission is granted for redistribution,
 * modification, or repurposing of this contract. Any use beyond the scope defined herein may be subject to legal action.
 */
interface IBurnRedeemable {

    /// -------------------------------------- EVENTS --------------------------------------- \\\

    /**
     * @notice Emitted when a user redeems tokens.
     * @dev This event emits the details about the redemption process.
     * @param user The address of the user who performed the redemption.
     * @param xenContract The address of the XEN contract involved in the redemption.
     * @param tokenContract The address of the token contract involved in the redemption.
     * @param xenAmount The amount of XEN redeemed by the user.
     * @param tokenAmount The amount of tokens redeemed by the user.
     */
    event Redeemed(
        address indexed user,
        address indexed xenContract,
        address indexed tokenContract,
        uint256 xenAmount,
        uint256 tokenAmount
    );

    /// --------------------------------- EXTERNAL FUNCTION --------------------------------- \\\

    /**
     * @notice Called when a token is burned by a user.
     * @dev Handles any logic related to token burning for redeemable tokens.
     * Implementations should be cautious of reentrancy attacks.
     * @param user The address of the user who burned the token.
     * @param amount The amount of the token burned.
     */
    function onTokenBurned(
        address user,
        uint256 amount
    ) external;

    /// ------------------------------------------------------------------------------------- \\\
}

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.18;

import {ILayerZeroReceiver} from "@layerzerolabs/lz-evm-sdk-v1-0.7/contracts/interfaces/ILayerZeroReceiver.sol";
import {IWormholeReceiver} from  "./IWormholeReceiver.sol";
import {IBurnRedeemable} from  "./IBurnRedeemable.sol";

/*
 * @title vXNF Contract
 *
 * @notice This interface outlines functions for the vXNF token, an ERC20 token with bridging and burning capabilities.
 *
 * Co-Founders:
 * - Simran Dhillon: [email protected]
 * - Hardev Dhillon: [email protected]
 * - Dayana Plaz: [email protected]
 *
 * Official Links:
 * - Twitter: https://twitter.com/xenify_io
 * - Telegram: https://t.me/xenify_io
 * - Website: https://xenify.io
 *
 * Disclaimer:
 * This contract aligns with the principles of the Fair Crypto Foundation, promoting self-custody, transparency, consensus-based
 * trust, and permissionless value exchange. There are no administrative access keys, underscoring our commitment to decentralization.
 * Engaging with this contract involves technical and legal risks. Users must conduct their own due diligence and ensure compliance
 * with local laws and regulations. The software is provided "AS-IS," without warranties, and the co-founders and developers disclaim
 * all liability for any vulnerabilities, exploits, errors, or breaches that may occur. By using this contract, users accept all associated
 * risks and this disclaimer. The co-founders, developers, or related parties will not bear liability for any consequences of non-compliance.
 *
 * Redistribution and Use:
 * Redistribution, modification, or repurposing of this contract, in whole or in part, is strictly prohibited without express written
 * approval from all co-founders. Approval requests must be sent to the official email addresses of the co-founders, ensuring responses
 * are received directly from these addresses. Proposals for redistribution, modification, or repurposing must include a detailed explanation
 * of the intended changes or uses and the reasons behind them. The co-founders reserve the right to request additional information or
 * clarification as necessary. Approval is at the sole discretion of the co-founders and may be subject to conditions to uphold the
 * project’s integrity and the values of the Fair Crypto Foundation. Failure to obtain express written approval prior to any redistribution,
 * modification, or repurposing will result in a breach of these terms and immediate legal action.
 *
 * Copyright and License:
 * Copyright © 2023 Xenify (Simran Dhillon, Hardev Dhillon, Dayana Plaz). All rights reserved.
 * This software is provided 'as is' and may be used by the recipient. No permission is granted for redistribution,
 * modification, or repurposing of this contract. Any use beyond the scope defined herein may be subject to legal action.
 */
interface IvXNF is
    IBurnRedeemable,
    IWormholeReceiver,
    ILayerZeroReceiver
{
    /// -------------------------------------- ERRORS --------------------------------------- \\\

    /**
     * @notice This error is thrown when only the team is allowed to call a function.
     */
    error OnlyTeamAllowed();

    /**
     * @notice This error is thrown when XNF address is already set.
     */
    error XNFIsAlreadySet();

    /**
     * @notice This error is thrown when the fee provided is insufficient.
     */
    error InsufficientFee();

    /**
     * @notice This error is thrown when the caller is not verified.
     */
    error NotVerifiedCaller();

    /**
     * @notice This error is thrown when only the relayer is allowed to call a function.
     */
    error OnlyRelayerAllowed();

    /**
     * @notice This error is thrown when the address length is invalid or less than the expected length.
     */
    error InvalidAddressLength();

    /**
     * @notice This error is thrown when the source address is invalid.
     */
    error InvalidSourceAddress();

    /**
     * @notice This error is thrown when the hex string length is not even.
     */
    error HexStringLengthNotEven();

    /**
     * @notice This error is thrown when the provided Ether is not enough to cover the estimated gas fee.
     */
    error InsufficientFeeForWormhole();

    /**
     * @notice This error is thrown when the Wormhole source address is invalid.
     */
    error InvalidWormholeSourceAddress();

    /**
     * @notice This error is thrown when the LayerZero source address is invalid.
     */
    error InvalidLayerZeroSourceAddress();

    /**
     * @notice This error is thrown when a Wormhole message has already been processed.
     */
    error WormholeMessageAlreadyProcessed();

    /// ------------------------------------- ENUMS ----------------------------------------- \\\

    /**
     * @notice Enum to represent the different bridges available.
     * @dev LayerZero = 1, Axelar = 2, Wormhole = 3.
     */
    enum BridgeId {
        LayerZero,
        Axelar,
        Wormhole
    }

    /// -------------------------------------- EVENTS --------------------------------------- \\\

    /**
     * @notice Emitted when vXNF tokens are bridged to another chain.
     * @param from Address on the source chain that initiated the bridge.
     * @param burnedAmount Amount of vXNF tokens burned for the bridge.
     * @param bridgeId Identifier for the bridge used
     * @param outgoingChainId ID of the destination chain.
     * @param to Address on the destination chain to receive the tokens.
     */
    event vXNFBridgeTransfer(
        address indexed from,
        uint256 burnedAmount,
        BridgeId indexed bridgeId,
        bytes outgoingChainId,
        address indexed to
    );

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Emitted when vXNF tokens are received from a bridge.
     * @param to Address that receives the minted vXNF tokens.
     * @param mintAmount Amount of vXNF tokens minted.
     * @param bridgeId Identifier for the bridge used
     * @param incomingChainId ID of the source chain.
     * @param from Address on the source chain that initiated the bridge.
     */
    event vXNFBridgeReceive(
        address indexed to,
        uint256 mintAmount,
        BridgeId indexed bridgeId,
        bytes incomingChainId,
        address indexed from
    );

    /// --------------------------------- EXTERNAL FUNCTIONS -------------------------------- \\\

    /**
     * @notice Sets the XNF contract address.
     * @dev This function is called by the team to set XNF contract address.
     * Function can be called only once.
     * @param _XNF The XNF contract address.
     * @param _ratio The ratio between vXNF and XNF used for minting and burning.
     */
    function setXNFAndRatio(address _XNF, uint256 _ratio) external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Burns the specified amount of XNF tokens and mints an equivalent amount of vXNF tokens.
     * @param _amount Amount of XNF tokens to burn.
     */
    function burnXNF(uint256 _amount) external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Burns the specified amount of XNF tokens and bridges them via the LayerZero network.
     * @dev Burns the XNF tokens from the sender's address and then initiates a bridge operation using the LayerZero network.
     * @param _amount The amount of XNF tokens to burn and bridge.
     * @param dstChainId The Chain ID of the destination chain on the LayerZero network.
     * @param to The recipient address on the destination chain.
     * @param feeRefundAddress Address to refund any excess fees.
     * @param zroPaymentAddress Address of the ZRO token holder who would pay for the transaction.
     * @param adapterParams Parameters for custom functionality, e.g., receiving airdropped native gas from the relayer on the destination.
     */
    function burnAndBridgeViaLayerZero(
        uint256 _amount,
        uint16 dstChainId,
        address to,
        address payable feeRefundAddress,
        address zroPaymentAddress,
        bytes calldata adapterParams
    ) external payable;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Burns the specified amount of XNF tokens and bridges them via the Axelar network.
     * @dev Burns the XNF tokens from the sender's address and then initiates a bridge operation using the Axelar network.
     * @param _amount The amount of XNF tokens to burn and bridge.
     * @param dstChainId The target chain where tokens should be bridged to on the Axelar network.
     * @param to The recipient address on the destination chain.
     * @param feeRefundAddress Address to refund any excess fees.
     */
    function burnAndBridgeViaAxelar(
        uint256 _amount,
        string calldata dstChainId,
        address to,
        address payable feeRefundAddress
    ) external payable;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Burns the specified amount of XNF tokens and bridges them via the Wormhole network.
     * @dev Burns the XNF tokens from the sender's address and then initiates a bridge operation using the Wormhole network.
     * @param _amount The amount of XNF tokens to burn and bridge.
     * @param targetChain The ID of the target chain on the Wormhole network.
     * @param to The recipient address on the destination chain.
     * @param feeRefundAddress Address to refund any excess fees.
     * @param gasLimit The gas limit for the transaction on the destination chain.
     */
    function burnAndBridgeViaWormhole(
        uint256 _amount,
        uint16 targetChain,
        address to,
        address payable feeRefundAddress,
        uint256 gasLimit
    ) external payable;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Burns a specific amount of vXNF tokens from a user's address.
     * @dev Allows an external entity to burn tokens from a user's address, provided they have the necessary allowance.
     * @param _user The address from which the vXNF tokens will be burned.
     * @param _amount The amount of vXNF tokens to burn.
     */
    function burn(
        address _user,
        uint256 _amount
    ) external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Bridges tokens to another chain via LayerZero.
     * @dev Encodes destination and contract addresses, checks Ether sent against estimated gas,
     * then triggers the LayerZero endpoint to bridge tokens.
     * @param _dstChainId ID of the target chain on LayerZero.
     * @param from Sender's address on the source chain.
     * @param to Recipient's address on the destination chain.
     * @param _amount Amount of tokens to bridge.
     * @param feeRefundAddress Address for any excess fee refunds.
     * @param _zroPaymentAddress Address of the ZRO token holder covering transaction fees.
     * @param _adapterParams Additional parameters for custom functionalities.
     */
    function bridgeViaLayerZero(
        uint16 _dstChainId,
        address from,
        address to,
        uint256 _amount,
        address payable feeRefundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) external payable;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Bridges tokens to another chain via Axelar.
     * @dev Encodes sender's address and amount, then triggers the Axelar gateway to bridge tokens.
     * @param destinationChain ID of the target chain on Axelar.
     * @param from Sender's address on the source chain.
     * @param to Recipient's address on the destination chain.
     * @param _amount Amount of tokens to bridge.
     * @param feeRefundAddress Address for any excess fee refunds.
     */
    function bridgeViaAxelar(
        string calldata destinationChain,
        address from,
        address to,
        uint256 _amount,
        address payable feeRefundAddress
    ) external payable;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Bridges tokens to another chain via Wormhole.
     * @dev Estimates gas for the Wormhole bridge, checks Ether sent, then triggers the Wormhole relayer.
     * @param targetChain ID of the target chain on Wormhole.
     * @param from Sender's address on the source chain.
     * @param to Recipient's address on the destination chain.
     * @param _amount Amount of tokens to bridge.
     * @param feeRefundAddress Address for any excess fee refunds.
     * @param _gasLimit Gas limit for the transaction on the destination chain.
     */
    function bridgeViaWormhole(
        uint16 targetChain,
        address from,
        address to,
        uint256 _amount,
        address payable feeRefundAddress,
        uint256 _gasLimit
    ) external payable;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Estimates the bridging fee on LayerZero.
     * @dev Uses the `estimateFees` method of the endpoint contract.
     * @param _dstChainId ID of the destination chain on LayerZero.
     * @param from Sender's address on the source chain.
     * @param to Recipient's address on the destination chain.
     * @param _amount Amount of tokens to bridge.
     * @param _payInZRO If false, user pays the fee in native token.
     * @param _adapterParam Parameters for adapter services.
     * @return nativeFee Estimated fee in native tokens.
     */
    function estimateGasForLayerZero(
        uint16 _dstChainId,
        address from,
        address to,
        uint256 _amount,
        bool _payInZRO,
        bytes calldata _adapterParam
    ) external view returns (uint256 nativeFee);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Estimates the bridging fee on Wormhole.
     * @dev Uses the `quoteEVMDeliveryPrice` method of the wormholeRelayer contract.
     * @param targetChain ID of the destination chain on Wormhole.
     * @param _gasLimit Gas limit for the transaction on the destination chain.
     * @return cost Estimated fee for the operation.
     */
    function estimateGasForWormhole(
        uint16 targetChain,
        uint256 _gasLimit
    ) external view returns (uint256 cost);

    /// ------------------------------------------------------------------------------------- \\\
}

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.18;

/*
 * @title IWormholeReceiver Interface
 *
 * @notice Interface for a contract which can receive Wormhole messages.
 *
 * Co-Founders:
 * - Simran Dhillon: [email protected]
 * - Hardev Dhillon: [email protected]
 * - Dayana Plaz: [email protected]
 *
 * Official Links:
 * - Twitter: https://twitter.com/xenify_io
 * - Telegram: https://t.me/xenify_io
 * - Website: https://xenify.io
 *
 * Disclaimer:
 * This contract aligns with the principles of the Fair Crypto Foundation, promoting self-custody, transparency, consensus-based
 * trust, and permissionless value exchange. There are no administrative access keys, underscoring our commitment to decentralization.
 * Engaging with this contract involves technical and legal risks. Users must conduct their own due diligence and ensure compliance
 * with local laws and regulations. The software is provided "AS-IS," without warranties, and the co-founders and developers disclaim
 * all liability for any vulnerabilities, exploits, errors, or breaches that may occur. By using this contract, users accept all associated
 * risks and this disclaimer. The co-founders, developers, or related parties will not bear liability for any consequences of non-compliance.
 *
 * Redistribution and Use:
 * Redistribution, modification, or repurposing of this contract, in whole or in part, is strictly prohibited without express written
 * approval from all co-founders. Approval requests must be sent to the official email addresses of the co-founders, ensuring responses
 * are received directly from these addresses. Proposals for redistribution, modification, or repurposing must include a detailed explanation
 * of the intended changes or uses and the reasons behind them. The co-founders reserve the right to request additional information or
 * clarification as necessary. Approval is at the sole discretion of the co-founders and may be subject to conditions to uphold the
 * project’s integrity and the values of the Fair Crypto Foundation. Failure to obtain express written approval prior to any redistribution,
 * modification, or repurposing will result in a breach of these terms and immediate legal action.
 *
 * Copyright and License:
 * Copyright © 2023 Xenify (Simran Dhillon, Hardev Dhillon, Dayana Plaz). All rights reserved.
 * This software is provided 'as is' and may be used by the recipient. No permission is granted for redistribution,
 * modification, or repurposing of this contract. Any use beyond the scope defined herein may be subject to legal action.
 */
interface IWormholeReceiver {

    /// --------------------------------- EXTERNAL FUNCTION --------------------------------- \\\

    /**
     * @notice Called by the WormholeRelayer contract to deliver a Wormhole message to this contract.
     *
     * @dev This function should be implemented to include access controls to ensure that only
     *      the Wormhole Relayer contract can invoke it.
     *
     *      Implementations should:
     *      - Maintain a mapping of received `deliveryHash`s to prevent duplicate message delivery.
     *      - Verify the authenticity of `sourceChain` and `sourceAddress` to prevent unauthorized or malicious calls.
     *
     * @param payload The arbitrary data included in the message by the sender.
     * @param additionalVaas Additional VAAs that were requested to be included in this delivery.
     *                       Guaranteed to be in the same order as specified by the sender.
     * @param sourceAddress The Wormhole-formatted address of the message sender on the originating chain.
     * @param sourceChain The Wormhole Chain ID of the originating blockchain.
     * @param deliveryHash The VAA hash of the deliveryVAA, used to prevent duplicate delivery.
     *
     * Warning: The provided VAAs are NOT verified by the Wormhole core contract prior to this call.
     *          Always invoke `parseAndVerify()` on the Wormhole core contract to validate the VAAs before trusting them.
     */
    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory additionalVaas,
        bytes32 sourceAddress,
        uint16 sourceChain,
        bytes32 deliveryHash
    ) external payable;

    /// ------------------------------------------------------------------------------------- \\\
}

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.18;

/**
 * @title IWormholeRelayer Interface
 *
 * @notice This project allows developers to build cross-chain applications powered by Wormhole without needing to
 * write and run their own relaying infrastructure. We implement the IWormholeRelayer interface that allows users to
 * request a delivery provider to relay a payload (and/or additional VAAs) to a chain and address of their choice.
 *
 * Co-Founders:
 * - Simran Dhillon: [email protected]
 * - Hardev Dhillon: [email protected]
 * - Dayana Plaz: [email protected]
 *
 * Official Links:
 * - Twitter: https://twitter.com/xenify_io
 * - Telegram: https://t.me/xenify_io
 * - Website: https://xenify.io
 *
 * Disclaimer:
 * This contract aligns with the principles of the Fair Crypto Foundation, promoting self-custody, transparency, consensus-based
 * trust, and permissionless value exchange. There are no administrative access keys, underscoring our commitment to decentralization.
 * Engaging with this contract involves technical and legal risks. Users must conduct their own due diligence and ensure compliance
 * with local laws and regulations. The software is provided "AS-IS," without warranties, and the co-founders and developers disclaim
 * all liability for any vulnerabilities, exploits, errors, or breaches that may occur. By using this contract, users accept all associated
 * risks and this disclaimer. The co-founders, developers, or related parties will not bear liability for any consequences of non-compliance.
 *
 * Redistribution and Use:
 * Redistribution, modification, or repurposing of this contract, in whole or in part, is strictly prohibited without express written
 * approval from all co-founders. Approval requests must be sent to the official email addresses of the co-founders, ensuring responses
 * are received directly from these addresses. Proposals for redistribution, modification, or repurposing must include a detailed explanation
 * of the intended changes or uses and the reasons behind them. The co-founders reserve the right to request additional information or
 * clarification as necessary. Approval is at the sole discretion of the co-founders and may be subject to conditions to uphold the
 * project’s integrity and the values of the Fair Crypto Foundation. Failure to obtain express written approval prior to any redistribution,
 * modification, or repurposing will result in a breach of these terms and immediate legal action.
 *
 * Copyright and License:
 * Copyright © 2023 Xenify (Simran Dhillon, Hardev Dhillon, Dayana Plaz). All rights reserved.
 * This software is provided 'as is' and may be used by the recipient. No permission is granted for redistribution,
 * modification, or repurposing of this contract. Any use beyond the scope defined herein may be subject to legal action.
 */

/// ------------------------------------- STRUCTURE ------------------------------------- \\\


/**
 * @notice VaaKey identifies a wormhole message.
 * @custom:member chainId Wormhole chain ID of the chain where this VAA was emitted from.
 * @custom:member emitterAddress Address of the emitter of the VAA, in Wormhole bytes32 format.
 * @custom:member sequence Sequence number of the VAA.
 */
struct VaaKey {
    uint16 chainId;
    bytes32 emitterAddress;
    uint64 sequence;
}

/// ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| \\\

/**
 * @title IWormholeRelayerBase
 * @notice Interface for basic Wormhole Relayer operations.
 */
interface IWormholeRelayerBase {

    /// -------------------------------------- EVENT ---------------------------------------- \\\

    /**
     * @notice Emitted when a Send operation is executed.
     * @param sequence The sequence of the send event.
     * @param deliveryQuote The delivery quote for the send operation.
     * @param paymentForExtraReceiverValue The payment value for the additional receiver.
     */
    event SendEvent(
        uint64 indexed sequence,
        uint256 deliveryQuote,
        uint256 paymentForExtraReceiverValue
    );

    /// --------------------------------- EXTERNAL FUNCTION --------------------------------- \\\

    /**
     * @notice Fetches the registered Wormhole Relayer contract for a given chain ID.
     * @param chainId The chain ID to fetch the relayer contract for.
     * @return The address of the registered Wormhole Relayer contract for the given chain ID.
     */
    function getRegisteredWormholeRelayerContract(uint16 chainId)
        external
        view returns (bytes32);
}

/// ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| \\\

/**
 * @title IWormholeRelayerSend
 * @notice The interface to request deliveries.
 */
interface IWormholeRelayerSend is IWormholeRelayerBase {

    /// --------------------------------- EXTERNAL FUNCTIONS -------------------------------- \\\

    /**
     * @notice Publishes an instruction for the default delivery provider
     * to relay a payload to the address `targetAddress` on chain `targetChain`
     * with gas limit `gasLimit` and `msg.value` equal to `receiverValue`
     *
     * `targetAddress` must implement the IWormholeReceiver interface.
     *
     * This function must be called with `msg.value` equal to `quoteEVMDeliveryPrice(targetChain, receiverValue, gasLimit)`.
     *
     * Any refunds (from leftover gas) will be paid to the delivery provider. In order to receive the refunds, use the `sendPayloadToEvm` function
     * with `refundChain` and `refundAddress` as parameters.
     *
     * @param targetChain in Wormhole Chain ID format.
     * @param targetAddress address to call on targetChain (that implements IWormholeReceiver).
     * @param payload arbitrary bytes to pass in as parameter in call to `targetAddress`.
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units).
     * @param gasLimit gas limit with which to call `targetAddress`.
     * @return sequence sequence number of published VAA containing delivery instructions.
     */
    function sendPayloadToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 gasLimit
    ) external payable returns (uint64 sequence);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Publishes an instruction for the default delivery provider.
     * to relay a payload to the address `targetAddress` on chain `targetChain`
     * with gas limit `gasLimit` and `msg.value` equal to `receiverValue`.
     *
     * Any refunds (from leftover gas) will be sent to `refundAddress` on chain `refundChain`
     * `targetAddress` must implement the IWormholeReceiver interface.
     *
     * This function must be called with `msg.value` equal to `quoteEVMDeliveryPrice(targetChain, receiverValue, gasLimit)`.
     *
     * @param targetChain in Wormhole Chain ID format.
     * @param targetAddress address to call on targetChain (that implements IWormholeReceiver).
     * @param payload arbitrary bytes to pass in as parameter in call to `targetAddress`.
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units).
     * @param gasLimit gas limit with which to call `targetAddress`. Any units of gas unused will be refunded according to the
     *        `targetChainRefundPerGasUnused` rate quoted by the delivery provider.
     * @param refundChain The chain to deliver any refund to, in Wormhole Chain ID format.
     * @param refundAddress The address on `refundChain` to deliver any refund to.
     * @return sequence sequence number of published VAA containing delivery instructions.
     */
    function sendPayloadToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 gasLimit,
        uint16 refundChain,
        address refundAddress
    ) external payable returns (uint64 sequence);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Publishes an instruction for the default delivery provider
     * to relay a payload and VAAs specified by `vaaKeys` to the address `targetAddress` on chain `targetChain`
     * with gas limit `gasLimit` and `msg.value` equal to `receiverValue`
     *
     * `targetAddress` must implement the IWormholeReceiver interface
     *
     * This function must be called with `msg.value` equal to `quoteEVMDeliveryPrice(targetChain, receiverValue, gasLimit)`
     *
     * Any refunds (from leftover gas) will be paid to the delivery provider. In order to receive the refunds, use the `sendVaasToEvm` function
     * with `refundChain` and `refundAddress` as parameters
     *
     * @param targetChain in Wormhole Chain ID format
     * @param targetAddress address to call on targetChain (that implements IWormholeReceiver)
     * @param payload arbitrary bytes to pass in as parameter in call to `targetAddress`
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param gasLimit gas limit with which to call `targetAddress`.
     * @param vaaKeys Additional VAAs to pass in as parameter in call to `targetAddress`
     * @return sequence sequence number of published VAA containing delivery instructions
     */
    function sendVaasToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 gasLimit,
        VaaKey[] memory vaaKeys
    ) external payable returns (uint64 sequence);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Publishes an instruction for the default delivery provider
     * to relay a payload and VAAs specified by `vaaKeys` to the address `targetAddress` on chain `targetChain`
     * with gas limit `gasLimit` and `msg.value` equal to `receiverValue`
     *
     * Any refunds (from leftover gas) will be sent to `refundAddress` on chain `refundChain`
     * `targetAddress` must implement the IWormholeReceiver interface
     *
     * This function must be called with `msg.value` equal to `quoteEVMDeliveryPrice(targetChain, receiverValue, gasLimit)`
     *
     * @param targetChain in Wormhole Chain ID format
     * @param targetAddress address to call on targetChain (that implements IWormholeReceiver)
     * @param payload arbitrary bytes to pass in as parameter in call to `targetAddress`
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param gasLimit gas limit with which to call `targetAddress`. Any units of gas unused will be refunded according to the
     *        `targetChainRefundPerGasUnused` rate quoted by the delivery provider
     * @param vaaKeys Additional VAAs to pass in as parameter in call to `targetAddress`
     * @param refundChain The chain to deliver any refund to, in Wormhole Chain ID format
     * @param refundAddress The address on `refundChain` to deliver any refund to
     * @return sequence sequence number of published VAA containing delivery instructions
     */
    function sendVaasToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 gasLimit,
        VaaKey[] memory vaaKeys,
        uint16 refundChain,
        address refundAddress
    ) external payable returns (uint64 sequence);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Publishes an instruction for the delivery provider at `deliveryProviderAddress`
     * to relay a payload and VAAs specified by `vaaKeys` to the address `targetAddress` on chain `targetChain`
     * with gas limit `gasLimit` and `msg.value` equal to
     * receiverValue + (arbitrary amount that is paid for by paymentForExtraReceiverValue of this chain's wei) in targetChain wei.
     *
     * Any refunds (from leftover gas) will be sent to `refundAddress` on chain `refundChain`
     * `targetAddress` must implement the IWormholeReceiver interface
     *
     * This function must be called with `msg.value` equal to
     * quoteEVMDeliveryPrice(targetChain, receiverValue, gasLimit, deliveryProviderAddress) + paymentForExtraReceiverValue
     *
     * @param targetChain in Wormhole Chain ID format
     * @param targetAddress address to call on targetChain (that implements IWormholeReceiver)
     * @param payload arbitrary bytes to pass in as parameter in call to `targetAddress`
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param paymentForExtraReceiverValue amount (in current chain currency units) to spend on extra receiverValue
     *        (in addition to the `receiverValue` specified)
     * @param gasLimit gas limit with which to call `targetAddress`. Any units of gas unused will be refunded according to the
     *        `targetChainRefundPerGasUnused` rate quoted by the delivery provider
     * @param refundChain The chain to deliver any refund to, in Wormhole Chain ID format
     * @param refundAddress The address on `refundChain` to deliver any refund to
     * @param deliveryProviderAddress The address of the desired delivery provider's implementation of IDeliveryProvider
     * @param vaaKeys Additional VAAs to pass in as parameter in call to `targetAddress`
     * @param consistencyLevel Consistency level with which to publish the delivery instructions - see
     *        https://book.wormhole.com/wormhole/3_coreLayerContracts.html?highlight=consistency#consistency-levels
     * @return sequence sequence number of published VAA containing delivery instructions
     */
    function sendToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 paymentForExtraReceiverValue,
        uint256 gasLimit,
        uint16 refundChain,
        address refundAddress,
        address deliveryProviderAddress,
        VaaKey[] memory vaaKeys,
        uint8 consistencyLevel
    ) external payable returns (uint64 sequence);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Publishes an instruction for the delivery provider at `deliveryProviderAddress`
     * to relay a payload and VAAs specified by `vaaKeys` to the address `targetAddress` on chain `targetChain`
     * with `msg.value` equal to
     * receiverValue + (arbitrary amount that is paid for by paymentForExtraReceiverValue of this chain's wei) in targetChain wei.
     *
     * Any refunds (from leftover gas) will be sent to `refundAddress` on chain `refundChain`
     * `targetAddress` must implement the IWormholeReceiver interface
     *
     * This function must be called with `msg.value` equal to
     * quoteDeliveryPrice(targetChain, receiverValue, encodedExecutionParameters, deliveryProviderAddress) + paymentForExtraReceiverValue
     *
     * @param targetChain in Wormhole Chain ID format
     * @param targetAddress address to call on targetChain (that implements IWormholeReceiver), in Wormhole bytes32 format
     * @param payload arbitrary bytes to pass in as parameter in call to `targetAddress`
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param paymentForExtraReceiverValue amount (in current chain currency units) to spend on extra receiverValue
     *        (in addition to the `receiverValue` specified)
     * @param encodedExecutionParameters encoded information on how to execute delivery that may impact pricing
     *        e.g. for version EVM_V1, this is a struct that encodes the `gasLimit` with which to call `targetAddress`
     * @param refundChain The chain to deliver any refund to, in Wormhole Chain ID format
     * @param refundAddress The address on `refundChain` to deliver any refund to, in Wormhole bytes32 format
     * @param deliveryProviderAddress The address of the desired delivery provider's implementation of IDeliveryProvider
     * @param vaaKeys Additional VAAs to pass in as parameter in call to `targetAddress`
     * @param consistencyLevel Consistency level with which to publish the delivery instructions - see
     *        https://book.wormhole.com/wormhole/3_coreLayerContracts.html?highlight=consistency#consistency-levels
     * @return sequence sequence number of published VAA containing delivery instructions
     */
    function send(
        uint16 targetChain,
        bytes32 targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 paymentForExtraReceiverValue,
        bytes memory encodedExecutionParameters,
        uint16 refundChain,
        bytes32 refundAddress,
        address deliveryProviderAddress,
        VaaKey[] memory vaaKeys,
        uint8 consistencyLevel
    ) external payable returns (uint64 sequence);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Performs the same function as a `send`, except:
     * 1)  Can only be used during a delivery (i.e. in execution of `receiveWormholeMessages`)
     * 2)  Is paid for (along with any other calls to forward) by (any msg.value passed in) + (refund leftover from current delivery)
     * 3)  Only executes after `receiveWormholeMessages` is completed (and thus does not return a sequence number)
     *
     * The refund from the delivery currently in progress will not be sent to the user; it will instead
     * be paid to the delivery provider to perform the instruction specified here
     *
     * Publishes an instruction for the same delivery provider (or default, if the same one doesn't support the new target chain)
     * to relay a payload to the address `targetAddress` on chain `targetChain`
     * with gas limit `gasLimit` and with `msg.value` equal to `receiverValue`
     *
     * The following equation must be satisfied (sum_f indicates summing over all forwards requested in `receiveWormholeMessages`):
     * (refund amount from current execution of receiveWormholeMessages) + sum_f [msg.value_f]
     * >= sum_f [quoteEVMDeliveryPrice(targetChain_f, receiverValue_f, gasLimit_f)]
     *
     * The difference between the two sides of the above inequality will be added to `paymentForExtraReceiverValue` of the first forward requested
     *
     * Any refunds (from leftover gas) from this forward will be paid to the same refundChain and refundAddress specified for the current delivery.
     *
     * @param targetChain in Wormhole Chain ID format
     * @param targetAddress address to call on targetChain (that implements IWormholeReceiver), in Wormhole bytes32 format
     * @param payload arbitrary bytes to pass in as parameter in call to `targetAddress`
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param gasLimit gas limit with which to call `targetAddress`.
     */
    function forwardPayloadToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 gasLimit
    ) external payable;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Performs the same function as a `send`, except:
     * 1)  Can only be used during a delivery (i.e. in execution of `receiveWormholeMessages`)
     * 2)  Is paid for (along with any other calls to forward) by (any msg.value passed in) + (refund leftover from current delivery)
     * 3)  Only executes after `receiveWormholeMessages` is completed (and thus does not return a sequence number)
     *
     * The refund from the delivery currently in progress will not be sent to the user; it will instead
     * be paid to the delivery provider to perform the instruction specified here
     *
     * Publishes an instruction for the same delivery provider (or default, if the same one doesn't support the new target chain)
     * to relay a payload and VAAs specified by `vaaKeys` to the address `targetAddress` on chain `targetChain`
     * with gas limit `gasLimit` and with `msg.value` equal to `receiverValue`
     *
     * The following equation must be satisfied (sum_f indicates summing over all forwards requested in `receiveWormholeMessages`):
     * (refund amount from current execution of receiveWormholeMessages) + sum_f [msg.value_f]
     * >= sum_f [quoteEVMDeliveryPrice(targetChain_f, receiverValue_f, gasLimit_f)]
     *
     * The difference between the two sides of the above inequality will be added to `paymentForExtraReceiverValue` of the first forward requested
     *
     * Any refunds (from leftover gas) from this forward will be paid to the same refundChain and refundAddress specified for the current delivery.
     *
     * @param targetChain in Wormhole Chain ID format
     * @param targetAddress address to call on targetChain (that implements IWormholeReceiver), in Wormhole bytes32 format
     * @param payload arbitrary bytes to pass in as parameter in call to `targetAddress`
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param gasLimit gas limit with which to call `targetAddress`.
     * @param vaaKeys Additional VAAs to pass in as parameter in call to `targetAddress`
     */
    function forwardVaasToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 gasLimit,
        VaaKey[] memory vaaKeys
    ) external payable;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Performs the same function as a `send`, except:
     * 1)  Can only be used during a delivery (i.e. in execution of `receiveWormholeMessages`)
     * 2)  Is paid for (along with any other calls to forward) by (any msg.value passed in) + (refund leftover from current delivery)
     * 3)  Only executes after `receiveWormholeMessages` is completed (and thus does not return a sequence number)
     *
     * The refund from the delivery currently in progress will not be sent to the user; it will instead
     * be paid to the delivery provider to perform the instruction specified here
     *
     * Publishes an instruction for the delivery provider at `deliveryProviderAddress`
     * to relay a payload and VAAs specified by `vaaKeys` to the address `targetAddress` on chain `targetChain`
     * with gas limit `gasLimit` and with `msg.value` equal to
     * receiverValue + (arbitrary amount that is paid for by paymentForExtraReceiverValue of this chain's wei) in targetChain wei.
     *
     * Any refunds (from leftover gas) will be sent to `refundAddress` on chain `refundChain`
     * `targetAddress` must implement the IWormholeReceiver interface
     *
     * The following equation must be satisfied (sum_f indicates summing over all forwards requested in `receiveWormholeMessages`):
     * (refund amount from current execution of receiveWormholeMessages) + sum_f [msg.value_f]
     * >= sum_f [quoteEVMDeliveryPrice(targetChain_f, receiverValue_f, gasLimit_f, deliveryProviderAddress_f) + paymentForExtraReceiverValue_f]
     *
     * The difference between the two sides of the above inequality will be added to `paymentForExtraReceiverValue` of the first forward requested
     *
     * @param targetChain in Wormhole Chain ID format
     * @param targetAddress address to call on targetChain (that implements IWormholeReceiver), in Wormhole bytes32 format
     * @param payload arbitrary bytes to pass in as parameter in call to `targetAddress`
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param paymentForExtraReceiverValue amount (in current chain currency units) to spend on extra receiverValue
     *        (in addition to the `receiverValue` specified)
     * @param gasLimit gas limit with which to call `targetAddress`. Any units of gas unused will be refunded according to the
     *        `targetChainRefundPerGasUnused` rate quoted by the delivery provider
     * @param refundChain The chain to deliver any refund to, in Wormhole Chain ID format
     * @param refundAddress The address on `refundChain` to deliver any refund to, in Wormhole bytes32 format
     * @param deliveryProviderAddress The address of the desired delivery provider's implementation of IDeliveryProvider
     * @param vaaKeys Additional VAAs to pass in as parameter in call to `targetAddress`
     * @param consistencyLevel Consistency level with which to publish the delivery instructions - see
     *        https://book.wormhole.com/wormhole/3_coreLayerContracts.html?highlight=consistency#consistency-levels
     */
    function forwardToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 paymentForExtraReceiverValue,
        uint256 gasLimit,
        uint16 refundChain,
        address refundAddress,
        address deliveryProviderAddress,
        VaaKey[] memory vaaKeys,
        uint8 consistencyLevel
    ) external payable;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Performs the same function as a `send`, except:
     * 1)  Can only be used during a delivery (i.e. in execution of `receiveWormholeMessages`)
     * 2)  Is paid for (along with any other calls to forward) by (any msg.value passed in) + (refund leftover from current delivery)
     * 3)  Only executes after `receiveWormholeMessages` is completed (and thus does not return a sequence number)
     *
     * The refund from the delivery currently in progress will not be sent to the user; it will instead
     * be paid to the delivery provider to perform the instruction specified here
     *
     * Publishes an instruction for the delivery provider at `deliveryProviderAddress`
     * to relay a payload and VAAs specified by `vaaKeys` to the address `targetAddress` on chain `targetChain`
     * with `msg.value` equal to
     * receiverValue + (arbitrary amount that is paid for by paymentForExtraReceiverValue of this chain's wei) in targetChain wei.
     *
     * Any refunds (from leftover gas) will be sent to `refundAddress` on chain `refundChain`
     * `targetAddress` must implement the IWormholeReceiver interface
     *
     * The following equation must be satisfied (sum_f indicates summing over all forwards requested in `receiveWormholeMessages`):
     * (refund amount from current execution of receiveWormholeMessages) + sum_f [msg.value_f]
     * >= sum_f [quoteDeliveryPrice(targetChain_f, receiverValue_f, encodedExecutionParameters_f, deliveryProviderAddress_f) + paymentForExtraReceiverValue_f]
     *
     * The difference between the two sides of the above inequality will be added to `paymentForExtraReceiverValue` of the first forward requested
     *
     * @param targetChain in Wormhole Chain ID format
     * @param targetAddress address to call on targetChain (that implements IWormholeReceiver), in Wormhole bytes32 format
     * @param payload arbitrary bytes to pass in as parameter in call to `targetAddress`
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param paymentForExtraReceiverValue amount (in current chain currency units) to spend on extra receiverValue
     *        (in addition to the `receiverValue` specified)
     * @param encodedExecutionParameters encoded information on how to execute delivery that may impact pricing
     *        e.g. for version EVM_V1, this is a struct that encodes the `gasLimit` with which to call `targetAddress`
     * @param refundChain The chain to deliver any refund to, in Wormhole Chain ID format
     * @param refundAddress The address on `refundChain` to deliver any refund to, in Wormhole bytes32 format
     * @param deliveryProviderAddress The address of the desired delivery provider's implementation of IDeliveryProvider
     * @param vaaKeys Additional VAAs to pass in as parameter in call to `targetAddress`
     * @param consistencyLevel Consistency level with which to publish the delivery instructions - see
     *        https://book.wormhole.com/wormhole/3_coreLayerContracts.html?highlight=consistency#consistency-levels
     */
    function forward(
        uint16 targetChain,
        bytes32 targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 paymentForExtraReceiverValue,
        bytes memory encodedExecutionParameters,
        uint16 refundChain,
        bytes32 refundAddress,
        address deliveryProviderAddress,
        VaaKey[] memory vaaKeys,
        uint8 consistencyLevel
    ) external payable;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Requests a previously published delivery instruction to be redelivered
     * (e.g. with a different delivery provider)
     *
     * This function must be called with `msg.value` equal to
     * quoteEVMDeliveryPrice(targetChain, newReceiverValue, newGasLimit, newDeliveryProviderAddress)
     *
     *  @notice *** This will only be able to succeed if the following is true **
     *         - newGasLimit >= gas limit of the old instruction
     *         - newReceiverValue >= receiver value of the old instruction
     *         - newDeliveryProvider's `targetChainRefundPerGasUnused` >= old relay provider's `targetChainRefundPerGasUnused`
     *
     * @param deliveryVaaKey VaaKey identifying the wormhole message containing the
     *        previously published delivery instructions
     * @param targetChain The target chain that the original delivery targeted. Must match targetChain from original delivery instructions
     * @param newReceiverValue new msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param newGasLimit gas limit with which to call `targetAddress`. Any units of gas unused will be refunded according to the
     *        `targetChainRefundPerGasUnused` rate quoted by the delivery provider, to the refund chain and address specified in the original request
     * @param newDeliveryProviderAddress The address of the desired delivery provider's implementation of IDeliveryProvider
     * @return sequence sequence number of published VAA containing redelivery instructions
     *
     * @notice *** This will only be able to succeed if the following is true **
     *         - newGasLimit >= gas limit of the old instruction
     *         - newReceiverValue >= receiver value of the old instruction
     *         - newDeliveryProvider's `targetChainRefundPerGasUnused` >= old relay provider's `targetChainRefundPerGasUnused`
     */
    function resendToEvm(
        VaaKey memory deliveryVaaKey,
        uint16 targetChain,
        uint256 newReceiverValue,
        uint256 newGasLimit,
        address newDeliveryProviderAddress
    )
        external
        payable
        returns (uint64 sequence);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Requests a previously published delivery instruction to be redelivered
     *
     *
     * This function must be called with `msg.value` equal to
     * quoteDeliveryPrice(targetChain, newReceiverValue, newEncodedExecutionParameters, newDeliveryProviderAddress)
     *
     * @param deliveryVaaKey VaaKey identifying the wormhole message containing the
     *        previously published delivery instructions
     * @param targetChain The target chain that the original delivery targeted. Must match targetChain from original delivery instructions
     * @param newReceiverValue new msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param newEncodedExecutionParameters new encoded information on how to execute delivery that may impact pricing
     *        e.g. for version EVM_V1, this is a struct that encodes the `gasLimit` with which to call `targetAddress`
     * @param newDeliveryProviderAddress The address of the desired delivery provider's implementation of IDeliveryProvider
     * @return sequence sequence number of published VAA containing redelivery instructions
     *
     *  @notice *** This will only be able to succeed if the following is true **
     *         - (For EVM_V1) newGasLimit >= gas limit of the old instruction
     *         - newReceiverValue >= receiver value of the old instruction
     *         - (For EVM_V1) newDeliveryProvider's `targetChainRefundPerGasUnused` >= old relay provider's `targetChainRefundPerGasUnused`
     */
    function resend(
        VaaKey memory deliveryVaaKey,
        uint16 targetChain,
        uint256 newReceiverValue,
        bytes memory newEncodedExecutionParameters,
        address newDeliveryProviderAddress
    )
        external
        payable
        returns (uint64 sequence);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Returns the price to request a relay to chain `targetChain`, using the default delivery provider
     *
     * @param targetChain in Wormhole Chain ID format
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param gasLimit gas limit with which to call `targetAddress`.
     * @return nativePriceQuote Price, in units of current chain currency, that the delivery provider charges to perform the relay
     * @return targetChainRefundPerGasUnused amount of target chain currency that will be refunded per unit of gas unused,
     *         if a refundAddress is specified
     */
    function quoteEVMDeliveryPrice(
        uint16 targetChain,
        uint256 receiverValue,
        uint256 gasLimit
    )
        external
        view
        returns (uint256 nativePriceQuote, uint256 targetChainRefundPerGasUnused);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Returns the price to request a relay to chain `targetChain`, using delivery provider `deliveryProviderAddress`
     *
     * @param targetChain in Wormhole Chain ID format
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param gasLimit gas limit with which to call `targetAddress`.
     * @param deliveryProviderAddress The address of the desired delivery provider's implementation of IDeliveryProvider
     * @return nativePriceQuote Price, in units of current chain currency, that the delivery provider charges to perform the relay
     * @return targetChainRefundPerGasUnused amount of target chain currency that will be refunded per unit of gas unused,
     *         if a refundAddress is specified
     */
    function quoteEVMDeliveryPrice(
        uint16 targetChain,
        uint256 receiverValue,
        uint256 gasLimit,
        address deliveryProviderAddress
    )
        external
        view
        returns (
        uint256 nativePriceQuote,
        uint256 targetChainRefundPerGasUnused
        );

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Returns the price to request a relay to chain `targetChain`, using delivery provider `deliveryProviderAddress`
     *
     * @param targetChain in Wormhole Chain ID format
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param encodedExecutionParameters encoded information on how to execute delivery that may impact pricing
     *        e.g. for version EVM_V1, this is a struct that encodes the `gasLimit` with which to call `targetAddress`
     * @param deliveryProviderAddress The address of the desired delivery provider's implementation of IDeliveryProvider
     * @return nativePriceQuote Price, in units of current chain currency, that the delivery provider charges to perform the relay
     * @return encodedExecutionInfo encoded information on how the delivery will be executed
     *        e.g. for version EVM_V1, this is a struct that encodes the `gasLimit` and `targetChainRefundPerGasUnused`
     *             (which is the amount of target chain currency that will be refunded per unit of gas unused,
     *              if a refundAddress is specified)
     */
    function quoteDeliveryPrice(
        uint16 targetChain,
        uint256 receiverValue,
        bytes memory encodedExecutionParameters,
        address deliveryProviderAddress
    )
        external
        view
        returns (
        uint256 nativePriceQuote,
        bytes memory encodedExecutionInfo
        );

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Returns the (extra) amount of target chain currency that `targetAddress`
     * will be called with, if the `paymentForExtraReceiverValue` field is set to `currentChainAmount`
     *
     * @param targetChain in Wormhole Chain ID format
     * @param currentChainAmount The value that `paymentForExtraReceiverValue` will be set to
     * @param deliveryProviderAddress The address of the desired delivery provider's implementation of IDeliveryProvider
     * @return targetChainAmount The amount such that if `targetAddress` will be called with `msg.value` equal to
     *         receiverValue + targetChainAmount
     */
    function quoteNativeForChain(
        uint16 targetChain,
        uint256 currentChainAmount,
        address deliveryProviderAddress
    )
        external
        view
        returns (uint256 targetChainAmount);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Returns the address of the current default delivery provider
     * @return deliveryProvider The address of (the default delivery provider)'s contract on this source
     *   chain. This must be a contract that implements IDeliveryProvider.
     */
    function getDefaultDeliveryProvider()
        external
        view
        returns (address deliveryProvider);
}

/// ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| \\\

/**
 * @title IWormholeRelayerDelivery
 * @notice The interface to execute deliveries. Only relevant for Delivery Providers
 */
interface IWormholeRelayerDelivery is IWormholeRelayerBase {

    /// -------------------------------------- ENUMS ---------------------------------------- \\\

    /**
     * @notice Represents the possible statuses of a delivery.
     */
    enum DeliveryStatus {
        SUCCESS,
        RECEIVER_FAILURE,
        FORWARD_REQUEST_FAILURE,
        FORWARD_REQUEST_SUCCESS
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Represents the possible statuses of a refund after a delivery attempt.
     */
    enum RefundStatus {
        REFUND_SENT,
        REFUND_FAIL,
        CROSS_CHAIN_REFUND_SENT,
        CROSS_CHAIN_REFUND_FAIL_PROVIDER_NOT_SUPPORTED,
        CROSS_CHAIN_REFUND_FAIL_NOT_ENOUGH
    }

    /// -------------------------------------- EVENT ---------------------------------------- \\\

    /**
     * @custom:member recipientContract - The target contract address
     * @custom:member sourceChain - The chain which this delivery was requested from (in wormhole
     *     ChainID format)
     * @custom:member sequence - The wormhole sequence number of the delivery VAA on the source chain
     *     corresponding to this delivery request
     * @custom:member deliveryVaaHash - The hash of the delivery VAA corresponding to this delivery
     *     request
     * @custom:member gasUsed - The amount of gas that was used to call your target contract
     * @custom:member status:
     *   - RECEIVER_FAILURE, if the target contract reverts
     *   - SUCCESS, if the target contract doesn't revert and no forwards were requested
     *   - FORWARD_REQUEST_FAILURE, if the target contract doesn't revert, forwards were requested,
     *       but provided/leftover funds were not sufficient to cover them all
     *   - FORWARD_REQUEST_SUCCESS, if the target contract doesn't revert and all forwards are covered
     * @custom:member additionalStatusInfo:
     *   - If status is SUCCESS or FORWARD_REQUEST_SUCCESS, then this is empty.
     *   - If status is RECEIVER_FAILURE, this is `RETURNDATA_TRUNCATION_THRESHOLD` bytes of the
     *       return data (i.e. potentially truncated revert reason information).
     *   - If status is FORWARD_REQUEST_FAILURE, this is also the revert data - the reason the forward failed.
     *     This will be either an encoded Cancelled, DeliveryProviderReverted, or DeliveryProviderPaymentFailed error
     * @custom:member refundStatus - Result of the refund. REFUND_SUCCESS or REFUND_FAIL are for
     *     refunds where targetChain=refundChain; the others are for targetChain!=refundChain,
     *     where a cross chain refund is necessary
     * @custom:member overridesInfo:
     *   - If not an override: empty bytes array
     *   - Otherwise: An encoded `DeliveryOverride`
     */
    event Delivery(
        address indexed recipientContract,
        uint16 indexed sourceChain,
        uint64 indexed sequence,
        bytes32 deliveryVaaHash,
        DeliveryStatus status,
        uint256 gasUsed,
        RefundStatus refundStatus,
        bytes additionalStatusInfo,
        bytes overridesInfo
    );

    /// --------------------------------- EXTERNAL FUNCTION --------------------------------- \\\

    /**
     * @notice The delivery provider calls `deliver` to relay messages as described by one delivery instruction
     *
     * The delivery provider must pass in the specified (by VaaKeys[]) signed wormhole messages (VAAs) from the source chain
     * as well as the signed wormhole message with the delivery instructions (the delivery VAA)
     *
     * The messages will be relayed to the target address (with the specified gas limit and receiver value) iff the following checks are met:
     * - the delivery VAA has a valid signature
     * - the delivery VAA's emitter is one of these WormholeRelayer contracts
     * - the delivery provider passed in at least enough of this chain's currency as msg.value (enough meaning the maximum possible refund)
     * - the instruction's target chain is this chain
     * - the relayed signed VAAs match the descriptions in container.messages (the VAA hashes match, or the emitter address, sequence number pair matches, depending on the description given)
     *
     * @param encodedVMs - An array of signed wormhole messages (all from the same source chain
     *     transaction)
     * @param encodedDeliveryVAA - Signed wormhole message from the source chain's WormholeRelayer
     *     contract with payload being the encoded delivery instruction container
     * @param relayerRefundAddress - The address to which any refunds to the delivery provider
     *     should be sent
     * @param deliveryOverrides - Optional overrides field which must be either an empty bytes array or
     *     an encoded DeliveryOverride struct
     */
    function deliver(
        bytes[] memory encodedVMs,
        bytes memory encodedDeliveryVAA,
        address payable relayerRefundAddress,
        bytes memory deliveryOverrides
    ) external payable;
}

/// ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| \\\

/**
 * @title IWormholeRelayer
 * @notice Interface for the primary Wormhole Relayer which aggregates the functionalities of the Delivery and Send interfaces.
 */
interface IWormholeRelayer is
    IWormholeRelayerDelivery,
    IWormholeRelayerSend {}

    // Bound chosen by the following formula: `memoryWord * 4 + selectorSize`.
    // This means that an error identifier plus four fixed size arguments should be available to developers.
    // In the case of a `require` revert with error message, this should provide 2 memory word's worth of data.
    uint256 constant RETURNDATA_TRUNCATION_THRESHOLD = 132;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * Errors related to conversion and validation of EVM addresses.
     */
    error NotAnEvmAddress(bytes32);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * Errors related to unauthorized access or usage.
     */
    error RequesterNotWormholeRelayer();

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * Errors for when there are issues with the overrides provided.
     */
    error InvalidOverrideGasLimit();
    error InvalidOverrideReceiverValue();
    error InvalidOverrideRefundPerGasUnused();

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * Errors related to the state and progress of the WormholeRelayer's operations.
     */
    error NoDeliveryInProgress();
    error ReentrantDelivery(address msgSender, address lockedBy);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * Errors related to funding and refunds.
     */
    error InsufficientRelayerFunds(uint256 msgValue, uint256 minimum);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * Errors related to the VAA (signed wormhole message) validation.
     */
    error VaaKeysDoNotMatchVaas(uint8 index);
    error VaaKeysLengthDoesNotMatchVaasLength(uint256 keys, uint256 vaas);
    error InvalidEmitter(bytes32 emitter, bytes32 registered, uint16 chainId);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * Errors related to payment values and delivery prices.
     */
    error RequestedGasLimitTooLow();
    error DeliveryProviderCannotReceivePayment();
    error InvalidMsgValue(uint256 msgValue, uint256 totalFee);
    error DeliveryProviderDoesNotSupportTargetChain(address relayer, uint16 chainId);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * Errors for when there are issues with forwarding or delivery.
     */
    error InvalidVaaKeyType(uint8 parsed);
    error InvalidDeliveryVaa(string reason);
    error InvalidPayloadId(uint8 parsed, uint8 expected);
    error InvalidPayloadLength(uint256 received, uint256 expected);
    error ForwardRequestFromWrongAddress(address msgSender, address deliveryTarget);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * Errors related to relaying instructions and target chains.
     */
    error TargetChainIsNotThisChain(uint16 targetChain);
    error ForwardNotSufficientlyFunded(uint256 amountOfFunds, uint256 amountOfFundsNeeded);

    /// ------------------------------------------------------------------------------------- \\\

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.18;

import {StringToAddress, AddressToString} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/AddressString.sol";
import {IAxelarGasService} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol";
import {AxelarExecutable} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol";
import {ILayerZeroEndpoint} from "@layerzerolabs/lz-evm-sdk-v1-0.7/contracts/interfaces/ILayerZeroEndpoint.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IWormholeRelayer} from "./interfaces/IWormholeRelayer.sol";
import {IBurnRedeemable} from "./interfaces/IBurnRedeemable.sol";
import {IBurnableToken} from "./interfaces/IBurnableToken.sol";
import {IvXNF} from "./interfaces/IvXNF.sol";

/*
 * @title vXNF Contract
 *
 * @notice Represents the vXNF token, an ERC20 token with bridging and burning capabilities.
 *
 * Co-Founders:
 * - Simran Dhillon: [email protected]
 * - Hardev Dhillon: [email protected]
 * - Dayana Plaz: [email protected]
 *
 * Official Links:
 * - Twitter: https://twitter.com/xenify_io
 * - Telegram: https://t.me/xenify_io
 * - Website: https://xenify.io
 *
 * Disclaimer:
 * This contract aligns with the principles of the Fair Crypto Foundation, promoting self-custody, transparency, consensus-based
 * trust, and permissionless value exchange. There are no administrative access keys, underscoring our commitment to decentralization.
 * Engaging with this contract involves technical and legal risks. Users must conduct their own due diligence and ensure compliance
 * with local laws and regulations. The software is provided "AS-IS," without warranties, and the co-founders and developers disclaim
 * all liability for any vulnerabilities, exploits, errors, or breaches that may occur. By using this contract, users accept all associated
 * risks and this disclaimer. The co-founders, developers, or related parties will not bear liability for any consequences of non-compliance.
 *
 * Redistribution and Use:
 * Redistribution, modification, or repurposing of this contract, in whole or in part, is strictly prohibited without express written
 * approval from all co-founders. Approval requests must be sent to the official email addresses of the co-founders, ensuring responses
 * are received directly from these addresses. Proposals for redistribution, modification, or repurposing must include a detailed explanation
 * of the intended changes or uses and the reasons behind them. The co-founders reserve the right to request additional information or
 * clarification as necessary. Approval is at the sole discretion of the co-founders and may be subject to conditions to uphold the
 * project’s integrity and the values of the Fair Crypto Foundation. Failure to obtain express written approval prior to any redistribution,
 * modification, or repurposing will result in a breach of these terms and immediate legal action.
 *
 * Copyright and License:
 * Copyright © 2023 Xenify (Simran Dhillon, Hardev Dhillon, Dayana Plaz). All rights reserved.
 * This software is provided 'as is' and may be used by the recipient. No permission is granted for redistribution,
 * modification, or repurposing of this contract. Any use beyond the scope defined herein may be subject to legal action.
 */
contract vXNF is
    IvXNF,
    ERC20,
    ERC165,
    AxelarExecutable
{

    /// ------------------------------------- LIBRARYS ------------------------------------- \\\

    /**
     * @notice Utility library to convert a string representation into an address.
     */
    using StringToAddress for string;

    /**
     * @notice Utility library to convert an address into its string representation.
     */
    using AddressToString for address;

    /// ------------------------------------ VARIABLES ------------------------------------- \\\

    /**
     * @notice Immutable team address used for setting XNF address.
     */
    address public team;

    /**
     * @notice Address of the vXNF token in a string format.
     */
    string public vXNFAddress;

    /**
     * @notice Ratio used for token conversions.
     */
    uint256 public RATIO;

    /// ------------------------------------ INTERFACES ------------------------------------- \\\

    /**
     * @notice Interface to interact with address of the XNF token contract.
     */
    IBurnableToken public XNF;

    /**
     * @notice Interface to interact with LayerZero endpoint for bridging operations.
     */
    ILayerZeroEndpoint public immutable ENDPOINT;

    /**
     * @notice Interface to interact with Axelar gas service for estimating transaction fees.
     */
    IAxelarGasService public immutable GAS_SERVICE;

    /**
     * @notice Interface to interact with Wormhole relayer for bridging operations.
     */
    IWormholeRelayer public immutable WORMHOLE_RELAYER;

    /// ------------------------------------- MAPPING --------------------------------------- \\\

    /**
     * @notice Mapping to prevent replay attacks by storing processed delivery hashes.
     */
    mapping (bytes32 => bool) public seenDeliveryVaaHashes;

    /// ------------------------------------- MODIFIER -------------------------------------- \\\

    /**
     * @notice Modifier to protect against replay attacks.
     * @dev Ensures that a given delivery hash from the Wormhole relayer has not been processed before.
     * If it hasn't, the hash is marked as seen to prevent future replay attacks.
     * @param deliveryHash The delivery hash received from the Wormhole relayer.
     */
    modifier replayProtect(bytes32 deliveryHash) {
        if (seenDeliveryVaaHashes[deliveryHash]) {
            revert WormholeMessageAlreadyProcessed();
        }
        seenDeliveryVaaHashes[deliveryHash] = true;
        _;
    }

    /// ------------------------------------ CONSTRUCTOR ------------------------------------ \\\

    /**
     * @notice Constructs the vXNF token and initialises its dependencies.
     * @dev Sets up the vXNF token with references to other contracts like Axelar gateway, gas service,
     * LayerZero endpoint, and Wormhole relayer. Also computes the string representation of the vXNF contract address.
     * @param _ratio The ratio between vXNF and XNF used for minting and burning.
     * @param _XNF The address of the XNF token.
     * @param _gateway Address of the Axelar gateway contract.
     * @param _gasService Address of the Axelar gas service contract.
     * @param _endpoint Address of the LayerZero endpoint contract.
     * @param _wormholeRelayer Address of the Wormhole relayer contract.
     * @param _teamAddress Address of the teams wallet.
     */
    constructor(
        uint256 _ratio,
        address _XNF,
        address _gateway,
        address _gasService,
        address _endpoint,
        address _wormholeRelayer,
        address _teamAddress
    ) payable ERC20("vXNF", "vXNF") AxelarExecutable(_gateway) {
        XNF = IBurnableToken(_XNF);
        GAS_SERVICE = IAxelarGasService(_gasService);
        ENDPOINT = ILayerZeroEndpoint(_endpoint);
        WORMHOLE_RELAYER = IWormholeRelayer(_wormholeRelayer);
        vXNFAddress = address(this).toString();
        RATIO = _ratio;
        team = _teamAddress;
    }

    /// --------------------------------- EXTERNAL FUNCTIONS -------------------------------- \\\

    /**
     * @notice A hook triggered post token burning. It currently has no implementation but can be overridden.
     * @dev Complies with the IBurnRedeemable interface. Extend this function for additional logic after token burning.
     */
    function onTokenBurned(
        address,
        uint256
    ) external override {}

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Burns a specified quantity of XNF tokens and then mints an equivalent quantity of vXNF tokens to the burner.
     * @dev This function burns XNF tokens and mints vXNF in accordance to the defined RATIO.
     * @param _amount The volume of XNF tokens to burn.
     */
    function burnXNF(uint256 _amount)
        external
        override
    {
        XNF.burn(msg.sender, _amount);
        uint256 amt;
        unchecked {
            amt = _amount / RATIO;
        }
        _mint(msg.sender, amt);
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Burns the specified amount of XNF tokens and bridges them via the LayerZero network.
     * @dev Burns the XNF tokens from the sender's address and then initiates a bridge operation using the LayerZero network.
     * @param _amount The amount of XNF tokens to burn and bridge.
     * @param dstChainId The Chain ID of the destination chain on the LayerZero network.
     * @param to The recipient address on the destination chain.
     * @param feeRefundAddress Address to refund any excess fees.
     * @param zroPaymentAddress Address of the ZRO token holder who would pay for the transaction.
     * @param adapterParams Parameters for custom functionality, e.g., receiving airdropped native gas from the relayer on the destination.
     */
    function burnAndBridgeViaLayerZero(
        uint256 _amount,
        uint16 dstChainId,
        address to,
        address payable feeRefundAddress,
        address zroPaymentAddress,
        bytes calldata adapterParams
    )
        external
        payable
        override
    {
        XNF.burn(msg.sender, _amount);
        uint256 amt;
        unchecked {
            amt = _amount / RATIO;
        }
        _mint(msg.sender, amt);
        bridgeViaLayerZero(dstChainId, msg.sender, to, amt, feeRefundAddress, zroPaymentAddress, adapterParams);
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Burns the specified amount of XNF tokens and bridges them via the Axelar network.
     * @dev Burns the XNF tokens from the sender's address and then initiates a bridge operation using the Axelar network.
     * @param _amount The amount of XNF tokens to burn and bridge.
     * @param dstChainId The target chain where tokens should be bridged to on the Axelar network.
     * @param to The recipient address on the destination chain.
     * @param feeRefundAddress Address to refund any excess fees.
     */
    function burnAndBridgeViaAxelar(
        uint256 _amount,
        string calldata dstChainId,
        address to,
        address payable feeRefundAddress
    )
        external
        payable
        override
    {
        XNF.burn(msg.sender, _amount);
        uint256 amt;
        unchecked {
            amt = _amount / RATIO;
        }
        _mint(msg.sender, amt);
        bridgeViaAxelar(dstChainId, msg.sender, to, amt, feeRefundAddress);
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Burns the specified amount of XNF tokens and bridges them via the Wormhole network.
     * @dev Burns the XNF tokens from the sender's address and then initiates a bridge operation using the Wormhole network.
     * @param _amount The amount of XNF tokens to burn and bridge.
     * @param targetChain The ID of the target chain on the Wormhole network.
     * @param to The recipient address on the destination chain.
     * @param feeRefundAddress Address to refund any excess fees.
     * @param gasLimit The gas limit for the transaction on the destination chain.
     */
    function burnAndBridgeViaWormhole(
        uint256 _amount,
        uint16 targetChain,
        address to,
        address payable feeRefundAddress,
        uint256 gasLimit
    )
        external
        payable
        override
    {
        XNF.burn(msg.sender, _amount);
        uint256 amt;
        unchecked {
            amt = _amount / RATIO;
        }
        _mint(msg.sender, amt);
        bridgeViaWormhole(targetChain, msg.sender, to, amt, feeRefundAddress, gasLimit);
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Burns a specific amount of vXNF tokens from a user's address.
     * @dev Allows an external entity to burn tokens from a user's address, provided they have the necessary allowance.
     * @param _user The address from which the vXNF tokens will be burned.
     * @param _amount The amount of vXNF tokens to burn.
     */
    function burn(
        address _user,
        uint256 _amount
    )
        external
        override
    {
        if (_user != msg.sender)
            _spendAllowance(_user, msg.sender, _amount);
        _burn(_user, _amount);
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Receives vXNF tokens via the LayerZero bridge.
     * @dev Handles the receipt of vXNF tokens that have been bridged from another chain using the LayerZero network.
     * @param _srcChainId The Chain ID of the source chain on the LayerZero network.
     * @param _srcAddress The address on the source chain from which the vXNF tokens were sent.
     * @param _payload The encoded data containing details about the bridging operation, including the recipient address and amount.
     */
    function lzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64,
        bytes memory _payload
    )
        external
        override
    {
        if (address(ENDPOINT) != msg.sender) {
            revert NotVerifiedCaller();
        }
        if (address(this) != address(uint160(bytes20(_srcAddress)))) {
            revert InvalidLayerZeroSourceAddress();
        }
        (address from, address to, uint256 _amount) = abi.decode(
            _payload,
            (address, address, uint256)
        );
        _mint(to, _amount);
        emit vXNFBridgeReceive(to, _amount, BridgeId.LayerZero, abi.encode(_srcChainId), from);
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Receives tokens via the Wormhole bridge.
     * @dev This function is called by the Wormhole relayer to mint tokens after they've been bridged from another chain.
     * Only the Wormhole relayer can call this function. The function decodes the user address and amount from the payload,
     * and then mints the respective amount of tokens to the user's address.
     * @param payload The encoded data containing user address and amount.
     * @param sourceAddress The address of the caller on the source chain in bytes32.
     * @param _srcChainId The chain ID of the source chain from which the tokens are being bridged.
     * @param deliveryHash The hash which is used to verify relay calls.
     */
    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory,
        bytes32 sourceAddress,
        uint16 _srcChainId,
        bytes32 deliveryHash
    )
        external
        payable
        override
        replayProtect(deliveryHash)
    {
        if (msg.sender != address(WORMHOLE_RELAYER)) {
            revert OnlyRelayerAllowed();
        }
        if (address(this) != address(uint160(uint256(sourceAddress)))) {
            revert InvalidWormholeSourceAddress();
        }
        (address from, address to, uint256 _amount) = abi.decode(
            payload,
            (address, address, uint256)
        );
        _mint(to, _amount);
        emit vXNFBridgeReceive(to, _amount, BridgeId.Wormhole, abi.encode(_srcChainId), from);
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Sets the XNF contract address.
     * @dev This function is called by the team to set XNF contract address.
     * Function can be called only once.
     * @param _XNF The XNF contract address.
     * @param _ratio The ratio between vXNF and XNF used for minting and burning.
     */
    function setXNFAndRatio(address _XNF, uint256 _ratio)
        external
        override
    {
        if (msg.sender != team) {
            revert OnlyTeamAllowed();
        }
        if (address(XNF) != address(0)) {
            revert XNFIsAlreadySet();
        }
        XNF = IBurnableToken(_XNF);
        RATIO = _ratio;
    }

    /// ---------------------------------- PUBLIC FUNCTIONS --------------------------------- \\\

    /**
     * @notice Checks if a given interface ID is supported by the contract.
     * @dev Implements the IERC165 standard for interface detection.
     * @param interfaceId The ID of the interface in question.
     * @return bool `true` if the interface is supported, otherwise `false`.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return interfaceId == type(IBurnRedeemable).interfaceId || super.supportsInterface(interfaceId);
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Bridges tokens to another chain via LayerZero.
     * @dev Encodes destination and contract addresses, checks Ether sent against estimated gas,
     * then triggers the LayerZero endpoint to bridge tokens.
     * @param _dstChainId ID of the target chain on LayerZero.
     * @param from Sender's address on the source chain.
     * @param to Recipient's address on the destination chain.
     * @param _amount Amount of tokens to bridge.
     * @param feeRefundAddress Address for any excess fee refunds.
     * @param _zroPaymentAddress Address of the ZRO token holder covering transaction fees.
     * @param _adapterParams Additional parameters for custom functionalities.
     */
    function bridgeViaLayerZero(
        uint16 _dstChainId,
        address from,
        address to,
        uint256 _amount,
        address payable feeRefundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    )
        public
        payable
        override
    {
        if (_zroPaymentAddress == address(0)) {
            if (msg.value < estimateGasForLayerZero(_dstChainId, from, to, _amount, false, _adapterParams)) {
                revert InsufficientFee();
            }
        }
        else {
            if (msg.value < estimateGasForLayerZero(_dstChainId, from, to, _amount, true, _adapterParams)) {
                revert InsufficientFee();
            }
        }
        if (msg.sender != from)
            _spendAllowance(from, msg.sender, _amount);
            _burn(from, _amount);
        ENDPOINT.send{value: msg.value} (
            _dstChainId,
            abi.encodePacked(address(this),address(this)),
            abi.encode(from, to, _amount),
            feeRefundAddress,
            _zroPaymentAddress,
            _adapterParams
        );
        emit vXNFBridgeTransfer(from, _amount, BridgeId.LayerZero, abi.encode(_dstChainId), to);
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Bridges tokens to another chain via Axelar.
     * @dev Encodes sender's address and amount, then triggers the Axelar gateway to bridge tokens.
     * @param destinationChain ID of the target chain on Axelar.
     * @param from Sender's address on the source chain.
     * @param to Recipient's address on the destination chain.
     * @param _amount Amount of tokens to bridge.
     * @param feeRefundAddress Address for any excess fee refunds.
     */
    function bridgeViaAxelar(
        string calldata destinationChain,
        address from,
        address to,
        uint256 _amount,
        address payable feeRefundAddress
    )
        public
        payable
        override
    {
        bytes memory payload = abi.encode(from, to, _amount);
        string memory _vXNFAddress = vXNFAddress;
        if (msg.value != 0) {
            GAS_SERVICE.payNativeGasForContractCall{value: msg.value} (
                address(this),
                destinationChain,
                _vXNFAddress,
                payload,
                feeRefundAddress
            );
        }
        if (from != msg.sender)
            _spendAllowance(from, msg.sender, _amount);
            _burn(from, _amount);
        gateway.callContract(destinationChain, _vXNFAddress, payload);
        emit vXNFBridgeTransfer(from, _amount, BridgeId.Axelar, abi.encode(destinationChain), to);
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Bridges tokens to another chain via Wormhole.
     * @dev Estimates gas for the Wormhole bridge, checks Ether sent, then triggers the Wormhole relayer.
     * @param targetChain ID of the target chain on Wormhole.
     * @param from Sender's address on the source chain.
     * @param to Recipient's address on the destination chain.
     * @param _amount Amount of tokens to bridge.
     * @param feeRefundAddress Address for any excess fee refunds.
     * @param _gasLimit Gas limit for the transaction on the destination chain.
     */
    function bridgeViaWormhole(
        uint16 targetChain,
        address from,
        address to,
        uint256 _amount,
        address payable feeRefundAddress,
        uint256 _gasLimit
    )
        public
        payable
        override
    {
        uint256 cost = estimateGasForWormhole(targetChain, _gasLimit);
        if (msg.value < cost) {
            revert InsufficientFeeForWormhole();
        }
        if (msg.sender != from)
            _spendAllowance(from, msg.sender, _amount);
            _burn(from, _amount);
        WORMHOLE_RELAYER.sendPayloadToEvm{value: msg.value} (
            targetChain,
            address(this),
            abi.encode(from, to, _amount),
            0,
            _gasLimit,
            targetChain,
            feeRefundAddress
        );
        emit vXNFBridgeTransfer(from, _amount, BridgeId.Wormhole, abi.encode(targetChain), to);
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Estimates the bridging fee on LayerZero.
     * @dev Uses the `estimateFees` method of the endpoint contract.
     * @param _dstChainId ID of the destination chain on LayerZero.
     * @param from Sender's address on the source chain.
     * @param to Recipient's address on the destination chain.
     * @param _amount Amount of tokens to bridge.
     * @param _payInZRO If false, user pays the fee in native token.
     * @param _adapterParam Parameters for adapter services.
     * @return nativeFee Estimated fee in native tokens.
     */
    function estimateGasForLayerZero(
        uint16 _dstChainId,
        address from,
        address to,
        uint256 _amount,
        bool _payInZRO,
        bytes calldata _adapterParam
    )
        public
        override
        view
        returns (uint256 nativeFee)
    {
        (nativeFee, ) = ENDPOINT.estimateFees(
            _dstChainId,
            address(this),
            abi.encode(from, to, _amount),
            _payInZRO,
            _adapterParam
        );
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Estimates the bridging fee on Wormhole.
     * @dev Uses the `quoteEVMDeliveryPrice` method of the wormholeRelayer contract.
     * @param targetChain ID of the destination chain on Wormhole.
     * @param _gasLimit Gas limit for the transaction on the destination chain.
     * @return cost Estimated fee for the operation.
     */
    function estimateGasForWormhole(
        uint16 targetChain,
        uint256 _gasLimit
    )
        public
        override
        view
        returns (uint256 cost)
    {
        (cost, ) = WORMHOLE_RELAYER.quoteEVMDeliveryPrice(
            targetChain,
            0,
            _gasLimit
        );
    }

    /// --------------------------------- INTERNAL FUNCTION --------------------------------- \\\

    /**
     * @notice Executes a mint operation based on data from another chain.
     * @dev The function decodes the `payload` to extract the user's address and the amount,
     * then proceeds to mint tokens to the user's account. This is an internal function and can't
     * be called externally.
     * @param sourceChain The name or identifier of the source chain from which the tokens are being bridged.
     * @param sourceAddress The originating address from the source chain.
     * @param payload The encoded data payload containing user information and the amount to mint.
     */
    function _execute(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    )
        internal
        override
    {
        if (sourceAddress.toAddress() != address(this)) {
            revert InvalidSourceAddress();
        }
        (address from, address to, uint256 _amount) = abi.decode(
            payload,
            (address, address, uint256)
        );
        _mint(to, _amount);
        emit vXNFBridgeReceive(to, _amount, BridgeId.Axelar, abi.encode(sourceChain), from);
    }

    /// ------------------------------------------------------------------------------------- \\\
}