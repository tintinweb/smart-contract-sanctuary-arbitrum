// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.20;

import {Ownable} from "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is specified at deployment time in the constructor for `Ownable`. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        if (pendingOwner() != sender) {
            revert OwnableUnauthorizedAccount(sender);
        }
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

//       c=<
//        |
//        |   ////\    1@2
//    @@  |  /___\**   @@@2			@@@@@@@@@@@@@@@@@@@@@@
//   @@@  |  |~L~ |*   @@@@@@		@@@  @@@@@        @@@@    @@@ @@@@    @@@  @@@@@@@@ @@@@ @@@@    @@@ @@@@@@@@@ @@@@   @@@@
//  @@@@@ |   \=_/8    @@@@1@@		@@@  @@@@@  @@@@  @@@@    @@@ @@@@@   @@@ @@@@@@@@@ @@@@ @@@@@  @@@@ @@@@@@@@@  @@@@ @@@@
// @@@@@@| _ /| |\__ @@@@@@@@2		@@@  @@@@@  @@@@  @@@@    @@@ @@@@@@@ @@@ @@@@      @@@@ @@@@@@ @@@@ @@@         @@@@@@@
// 1@@@@@@|\  \___/)   @@1@@@@@2	~~~  ~~~~~  @@@@  ~~@@    ~~~ ~~~~~~~~~~~ ~~~~      ~~~~ ~~~~~~~~~~~ ~@@          @@@@@
// 2@@@@@ |  \ \ / |     @@@@@@2	@@@  @@@@@  @@@@  @@@@    @@@ @@@@@@@@@@@ @@@@@@@@@ @@@@ @@@@@@@@@@@ @@@@@@@@@    @@@@@
// 2@@@@  |_  >   <|__    @@1@12	@@@  @@@@@  @@@@  @@@@    @@@ @@@@ @@@@@@ @@@@      @@@@ @@@@ @@@@@@ @@@         @@@@@@@
// @@@@  / _|  / \/    \   @@1@		@@@   @@@   @@@@  @@@@    @@@ @@@@  @@@@@ @@@@      @@@@ @@@@  @@@@@ @@@@@@@@@  @@@@ @@@@
//  @@ /  |^\/   |      |   @@1		@@@         @@@@  @@@@    @@@ @@@@    @@@ @@@@      @@@@ @@@    @@@@ @@@@@@@@@ @@@@   @@@@
//   /     / ---- \ \\\=    @@		@@@@@@@@@@@@@@@@@@@@@@
//   \___/ --------  ~~    @@@
//     @@  | |   | |  --   @@
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { Ownable2Step, Ownable } from "@openzeppelin/contracts/access/Ownable2Step.sol";

import { IInfinexProtocolConfigBeacon } from "src/interfaces/beacons/IInfinexProtocolConfigBeacon.sol";

import { Error } from "src/libraries/Error.sol";

contract InfinexProtocolConfigBeacon is IInfinexProtocolConfigBeacon, Ownable2Step {
    /// @notice The timestamp the beacon is initialised.
    uint256 public immutable CREATED_AT;
    /// @notice Gets the trusted forwarder address for the account EIP712 context
    address public immutable TRUSTED_FORWARDER;
    address public appRegistry;
    mapping(address => bool) public trustedRecoveryKeepers;
    bool public fundsRecoveryActive;
    address public revenuePool;
    uint256 public withdrawalFeeUSDC;

    // the required parameters for accepting and bridging USDC
    address public USDC;
    BridgeConfiguration public bridgeConfiguration;

    ImplementationAddresses public implementationAddresses;

    mapping(uint16 wormholeChainId => bool isSupported) public supportedWormholeChainIds;
    // the required parameters to handle any Solana-related transaction
    SolanaConfiguration public solanaConfiguration;
    uint32 public solanaCCTPDestinationDomain;

    /**
     * @notice constructor function
     * @param _owner The owner of the contract
     * @param _infinexBeaconArgs The constructor arguments struct
     * @dev Circle Destination Domain can be 0 - Ethereum
     */
    constructor(address _owner, InfinexBeaconConstructorArgs memory _infinexBeaconArgs) Ownable(_owner) {
        if (_infinexBeaconArgs.trustedForwarder == address(0)) revert Error.NullAddress();
        if (_infinexBeaconArgs.appRegistry == address(0)) revert Error.NullAddress();
        if (_infinexBeaconArgs.latestAccountImplementation == address(0)) revert Error.NullAddress();
        if (_infinexBeaconArgs.initialProxyImplementation == address(0)) revert Error.NullAddress();
        if (_infinexBeaconArgs.USDC == address(0)) revert Error.NullAddress();
        if (_infinexBeaconArgs.circleBridge == address(0)) revert Error.NullAddress();
        if (_infinexBeaconArgs.circleMinter == address(0)) revert Error.NullAddress();
        if (_infinexBeaconArgs.wormholeCircleBridge == address(0)) revert Error.NullAddress();
        if (_infinexBeaconArgs.defaultDestinationWormholeChainId == 0) revert Error.ZeroValue();
        if (_infinexBeaconArgs.supportedWormholeChainIds.length == 0) revert Error.ZeroValue();
        if (_infinexBeaconArgs.solanaWalletProgramAddress == bytes32(0)) revert Error.ZeroValue();
        if (_infinexBeaconArgs.solanaTokenMintAddress == bytes32(0)) revert Error.ZeroValue();
        if (_infinexBeaconArgs.solanaTokenProgramAddress == bytes32(0)) revert Error.ZeroValue();
        if (_infinexBeaconArgs.solanaAssociatedTokenProgramAddress == bytes32(0)) revert Error.ZeroValue();
        if (_infinexBeaconArgs.solanaWalletProgramAddress == bytes32(0)) revert Error.ZeroValue();
        if (_infinexBeaconArgs.solanaTokenMintAddress == bytes32(0)) revert Error.ZeroValue();
        if (_infinexBeaconArgs.solanaTokenProgramAddress == bytes32(0)) revert Error.ZeroValue();
        if (_infinexBeaconArgs.solanaAssociatedTokenProgramAddress == bytes32(0)) revert Error.ZeroValue();

        CREATED_AT = block.timestamp;
        TRUSTED_FORWARDER = _infinexBeaconArgs.trustedForwarder;
        appRegistry = _infinexBeaconArgs.appRegistry;

        implementationAddresses.latestAccountImplementation = _infinexBeaconArgs.latestAccountImplementation;
        implementationAddresses.initialProxyImplementation = _infinexBeaconArgs.initialProxyImplementation;
        implementationAddresses.latestInfinexProtocolConfigBeacon = address(this);

        revenuePool = _infinexBeaconArgs.revenuePool;
        USDC = _infinexBeaconArgs.USDC;

        for (uint256 i; i < _infinexBeaconArgs.supportedWormholeChainIds.length; i++) {
            supportedWormholeChainIds[_infinexBeaconArgs.supportedWormholeChainIds[i]] = true;
        }

        // setting the bridge configuration
        bridgeConfiguration = BridgeConfiguration({
            minimumUSDCBridgeAmount: _infinexBeaconArgs.minimumUSDCBridgeAmount,
            circleBridge: _infinexBeaconArgs.circleBridge,
            circleMinter: _infinexBeaconArgs.circleMinter,
            wormholeCircleBridge: _infinexBeaconArgs.wormholeCircleBridge,
            defaultDestinationCCTPDomain: _infinexBeaconArgs.defaultDestinationCCTPDomain,
            defaultDestinationWormholeChainId: _infinexBeaconArgs.defaultDestinationWormholeChainId
        });

        solanaCCTPDestinationDomain = _infinexBeaconArgs.solanaCCTPDestinationDomain;

        // setting the Solana configuration
        solanaConfiguration = SolanaConfiguration({
            walletSeed: _infinexBeaconArgs.solanaWalletSeed,
            fixedPDASeed: _infinexBeaconArgs.solanaFixedPDASeed,
            walletProgramAddress: _infinexBeaconArgs.solanaWalletProgramAddress,
            tokenMintAddress: _infinexBeaconArgs.solanaTokenMintAddress,
            tokenProgramAddress: _infinexBeaconArgs.solanaTokenProgramAddress,
            associatedTokenProgramAddress: _infinexBeaconArgs.solanaAssociatedTokenProgramAddress
        });
    }

    /*///////////////////////////////////////////////////////////////
                    			VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Retrieves supported wormhole chain ids.
     * @param _wormholeChainId the chain id to check
     * @return bool if the chain is supported or not.
     */
    function isSupportedWormholeChainId(uint16 _wormholeChainId) external view returns (bool) {
        return supportedWormholeChainIds[_wormholeChainId];
    }

    /**
     * @notice Retrieves the minimum USDC amount that can be bridged.
     * @return The minimum USDC bridge amount.
     */
    function getMinimumUSDCBridgeAmount() external view returns (uint256) {
        return bridgeConfiguration.minimumUSDCBridgeAmount;
    }

    /**
     * @notice Retrieves the Circle Bridge parameters.
     * @return circleBridge The address of the Circle Bridge contract.
     * @return circleMinter The address of the TokenMinter contract.
     * @return defaultDestinationCCTPDomain The CCTP domain of the default destination chain.
     */
    function getCircleBridgeParams()
        external
        view
        returns (address circleBridge, address circleMinter, uint32 defaultDestinationCCTPDomain)
    {
        return (bridgeConfiguration.circleBridge, bridgeConfiguration.circleMinter, bridgeConfiguration.defaultDestinationCCTPDomain);
    }

    /**
     * @notice Retrieves the Circle Bridge address.
     * @return The address of the Circle Bridge contract.
     */
    function getCircleBridge() external view returns (address) {
        return bridgeConfiguration.circleBridge;
    }

    /**
     * @notice Retrieves the Circle TokenMinter address.
     * @return The address of the Circle TokenMinter contract.
     */
    function getCircleMinter() external view returns (address) {
        return bridgeConfiguration.circleMinter;
    }

    /**
     * @notice Retrieves the CCTP domain of the destination chain.
     * @return The CCTP domain of the default destination chain.
     */
    function getDefaultDestinationCCTPDomain() external view returns (uint32) {
        return bridgeConfiguration.defaultDestinationCCTPDomain;
    }

    /**
     * @notice Retrieves the circle CCTP destination domain for solana.
     * @return The CCTP destination domain for solana.
     */
    function getSolanaCCTPDestinationDomain() external view returns (uint32) {
        return solanaCCTPDestinationDomain;
    }

    /**
     * @notice Retrieves the parameters required for Wormhole bridging.
     * @return The address of the Wormhole Circle Bridge contract.
     * @return The default wormhole destination domain for the circle bridge contract.
     */
    function getWormholeCircleBridgeParams() external view returns (address, uint16) {
        return (bridgeConfiguration.wormholeCircleBridge, bridgeConfiguration.defaultDestinationWormholeChainId);
    }

    /**
     * @notice Retrieves the Wormhole Circle Bridge address.
     * @return The address of the Wormhole Circle Bridge contract.
     */
    function getWormholeCircleBridge() external view returns (address) {
        return bridgeConfiguration.wormholeCircleBridge;
    }

    /**
     * @notice Retrieves the Wormhole chain id for the default destination chain.
     * @return The Wormhole chain id of the default destination chain.
     */
    function getDefaultDestinationWormholeChainId() external view returns (uint16) {
        return bridgeConfiguration.defaultDestinationWormholeChainId;
    }

    /**
     * @notice Gets the latest account implementation address.
     * @return The address of the latest account implementation.
     */
    function getLatestAccountImplementation() external view returns (address) {
        return implementationAddresses.latestAccountImplementation;
    }

    /**
     * @notice Gets the initial proxy implementation address.
     * @return The address of the initial proxy implementation.
     */
    function getInitialProxyImplementation() external view returns (address) {
        return implementationAddresses.initialProxyImplementation;
    }

    /**
     * @notice The latest Infinex Protocol config beacon address, used for pointing account updates to the latest beacon.
     * @return The address of the latest Infinex Protocol config beacon.
     */
    function getLatestInfinexProtocolConfigBeacon() external view returns (address) {
        return implementationAddresses.latestInfinexProtocolConfigBeacon;
    }

    /**
     * @notice Checks if an address is a trusted recovery keeper.
     * @param _address The address to check.
     * @return True if the address is a trusted recovery keeper, false otherwise.
     */
    function isTrustedRecoveryKeeper(address _address) external view returns (bool) {
        return trustedRecoveryKeepers[_address];
    }

    /**
     * @notice Returns the Solana configuration
     * @param walletSeed The salt used to generate the Solana account (fixed seed "wallet")
     * @param fixedPDASeed The salt used to generate the PDA (Program Derived Address)
     * @param walletProgramAddress The Solana Wallet Program Address
     * @param tokenMintAddress The Solana token mint address
     * @param tokenProgramAddress The Solana token address
     * @param associatedTokenProgramAddress The Solana ATA program address
     */
    function getSolanaConfiguration()
        external
        view
        returns (
            bytes memory walletSeed,
            bytes memory fixedPDASeed,
            bytes32 walletProgramAddress,
            bytes32 tokenMintAddress,
            bytes32 tokenProgramAddress,
            bytes32 associatedTokenProgramAddress
        )
    {
        return (
            solanaConfiguration.walletSeed,
            solanaConfiguration.fixedPDASeed,
            solanaConfiguration.walletProgramAddress,
            solanaConfiguration.tokenMintAddress,
            solanaConfiguration.tokenProgramAddress,
            solanaConfiguration.associatedTokenProgramAddress
        );
    }

    /*///////////////////////////////////////////////////////////////
                    			MUTATIVE FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets or unsets a supported wormhole chain id.
     * @param _wormholeChainId the wormhole chain id to add or remove.
     * @param _status the status of the chain id.
     */
    function setSupportedWormholeChainId(uint16 _wormholeChainId, bool _status) external onlyOwner {
        emit SupportedWormholeChainIdSet(_wormholeChainId, _status);
        supportedWormholeChainIds[_wormholeChainId] = _status;
    }

    /**
     * @notice Sets the Solana CCTP destination domain
     * @param _solanaCCTPDestinationDomain the destination domain for circles CCTP USDC bridge.
     */
    function setSolanaCCTPDestinationDomain(uint32 _solanaCCTPDestinationDomain) external onlyOwner {
        emit SolanaCCTPDestinationDomainSet(_solanaCCTPDestinationDomain);
        solanaCCTPDestinationDomain = _solanaCCTPDestinationDomain;
    }

    /**
     * @notice Sets the address of the app registry contract.
     * @param _appRegistry The address of the app registry contract.
     */
    function setAppRegistry(address _appRegistry) external onlyOwner {
        if (_appRegistry == address(0)) revert Error.NullAddress();
        emit AppRegistrySet(_appRegistry);
        appRegistry = _appRegistry;
    }

    /**
     * @notice Sets or unsets an address as a trusted recovery keeper.
     * @param _address The address to set or unset.
     * @param _isTrusted Boolean indicating whether to set or unset the address as a trusted recovery keeper.
     */
    function setTrustedRecoveryKeeper(address _address, bool _isTrusted) external onlyOwner {
        if (_address == address(0)) revert Error.NullAddress();
        emit TrustedRecoveryKeeperSet(_address, _isTrusted);
        trustedRecoveryKeepers[_address] = _isTrusted;
    }

    /**
     * @notice Sets the funds recovery flag to active.
     * @dev Initially only the owner can call this. After 90 days, it can be activated by anyone.
     */
    function setFundsRecoveryActive() external {
        if (owner() != _msgSender()) {
            if (block.timestamp - CREATED_AT < 90 days) {
                revert Error.FundsRecoveryActivationDeadlinePending();
            }
        }
        emit FundsRecoveryStatusSet(true);
        fundsRecoveryActive = true;
    }

    /**
     * @notice Sets the revenue pool address.
     * @param _revenuePool The revenue pool address.
     */
    function setRevenuePool(address _revenuePool) external onlyOwner {
        if (_revenuePool == address(0)) revert Error.NullAddress();
        emit RevenuePoolSet(_revenuePool);
        revenuePool = _revenuePool;
    }

    /**
     * @notice Sets the USDC amount to charge as withdrawal fee.
     * @param _withdrawalFeeUSDC The withdrawal fee in USDC's decimals.
     */
    function setWithdrawalFeeUSDC(uint256 _withdrawalFeeUSDC) external onlyOwner {
        _setWithdrawalFeeUSDC(_withdrawalFeeUSDC);
    }

    /**
     * @notice Sets the address of the USDC token contract.
     * @param _USDC The address of the USDC token contract.
     * @dev Only the contract owner can call this function.
     * @dev Throws an error if the provided address is the zero address.
     */
    function setUSDCAddress(address _USDC) external onlyOwner {
        if (_USDC == address(0)) revert Error.NullAddress();
        emit USDCAddressSet(_USDC);
        USDC = _USDC;
    }

    /**
     * @notice Sets the minimum USDC amount that can be bridged, in 6 decimals.
     * @param _amount The minimum USDC bridge amount.
     */
    function setMinimumUSDCBridgeAmount(uint256 _amount) external onlyOwner {
        emit MinimumUSDCBridgeAmountSet(_amount);
        bridgeConfiguration.minimumUSDCBridgeAmount = _amount;
    }

    /**
     * @notice Sets the parameters for Circle bridging.
     * @param _circleBridge The address of the Circle Bridge contract.
     * @param _circleMinter The address of the Circle TokenMinter contract.
     * @param _defaultDestinationCCTPDomain The CCTP domain of the default destination chain.
     * @dev Circle Destination Domain can be 0 - Ethereum.
     */
    function setCircleBridgeParams(address _circleBridge, address _circleMinter, uint32 _defaultDestinationCCTPDomain)
        external
        onlyOwner
    {
        if (_circleBridge == address(0)) revert Error.NullAddress();
        if (_circleMinter == address(0)) revert Error.NullAddress();
        emit CircleBridgeParamsSet(_circleBridge, _circleMinter, _defaultDestinationCCTPDomain);
        bridgeConfiguration.circleBridge = _circleBridge;
        bridgeConfiguration.circleMinter = _circleMinter;
        bridgeConfiguration.defaultDestinationCCTPDomain = _defaultDestinationCCTPDomain;
    }

    /**
     * @notice Sets the parameters for Wormhole bridging.
     * @param _wormholeCircleBridge The address of the Wormhole Circle Bridge contract.
     * @param _defaultDestinationWormholeChainId The wormhole domain of the default destination chain.
     */
    function setWormholeCircleBridgeParams(address _wormholeCircleBridge, uint16 _defaultDestinationWormholeChainId)
        external
        onlyOwner
    {
        if (_wormholeCircleBridge == address(0)) revert Error.NullAddress();
        if (_defaultDestinationWormholeChainId == 0) revert Error.ZeroValue();
        emit WormholeCircleBridgeParamsSet(_wormholeCircleBridge, _defaultDestinationWormholeChainId);
        bridgeConfiguration.wormholeCircleBridge = _wormholeCircleBridge;
        bridgeConfiguration.defaultDestinationWormholeChainId = _defaultDestinationWormholeChainId;
    }

    /**
     * @notice Sets the initial proxy implementation address.
     * @param _initialProxyImplementation The initial proxy implementation address.
     */
    function setInitialProxyImplementation(address _initialProxyImplementation) external onlyOwner {
        if (_initialProxyImplementation == address(0)) revert Error.NullAddress();
        emit InitialProxyImplementationSet(_initialProxyImplementation);
        implementationAddresses.initialProxyImplementation = _initialProxyImplementation;
    }

    /**
     * @notice Sets the latest account implementation address.
     * @param _latestAccountImplementation The latest account implementation address.
     */
    function setLatestAccountImplementation(address _latestAccountImplementation) external onlyOwner {
        if (_latestAccountImplementation == address(0)) revert Error.NullAddress();
        emit LatestAccountImplementationSet(_latestAccountImplementation);
        implementationAddresses.latestAccountImplementation = _latestAccountImplementation;
    }

    /**
     * @notice Sets the latest Infinex Protocol Config Beacon.
     * @param _latestInfinexProtocolConfigBeacon The address of the Infinex Protocol Config Beacon.
     */
    function setLatestInfinexProtocolConfigBeacon(address _latestInfinexProtocolConfigBeacon) external onlyOwner {
        if (_latestInfinexProtocolConfigBeacon == address(0)) revert Error.NullAddress();
        emit LatestInfinexProtocolConfigBeaconSet(_latestInfinexProtocolConfigBeacon);
        implementationAddresses.latestInfinexProtocolConfigBeacon = _latestInfinexProtocolConfigBeacon;
    }

    /*///////////////////////////////////////////////////////////////
                    			INTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    function _setWithdrawalFeeUSDC(uint256 _withdrawalFeeUSDC) internal {
        emit WithdrawalFeeUSDCSet(_withdrawalFeeUSDC);
        withdrawalFeeUSDC = _withdrawalFeeUSDC;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title IInfinexProtocolConfigBeacon
 * @notice Interface for the Infinex Protocol Config Beacon contract.
 */
interface IInfinexProtocolConfigBeacon {
    /*///////////////////////////////////////////////////////////////
    	 										STRUCTS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Struct containing the constructor arguments for the InfinexProtocolConfigBeacon contract
     * @param trustedForwarder Address of the trusted forwarder contract
     * @param appRegistry Address of the app registry contract
     * @param latestAccountImplementation Address of the latest account implementation contract
     * @param initialProxyImplementation Address of the initial proxy implementation contract
     * @param revenuePool Address of the revenue pool contract
     * @param USDC Address of the USDC token contract
     * @param minimumUSDCBridgeAmount Minimum amount of USDC required to bridge
     * @param circleBridge Address of the Circle bridge contract
     * @param circleMinter Address of the Circle minter contract, used for checking the maximum bridge amount
     * @param wormholeCircleBridge Address of the Wormhole Circle bridge contract
     * @param defaultDestinationCCTPDomain the CCTP domain of the default destination chain.
     * @param defaultDestinationWormholeChainId the Wormhole chain id of the default destination chain.
     * @param solanaWalletSeed The salt used to generate the Solana account (fixed seed "wallet")
     * @param solanaFixedPDASeed The salt used to generate the PDA (Program Derived Address)
     * @param solanaWalletProgramAddress The Solana Wallet Program Address
     * @param solanaTokenMintAddress The Solana token mint address
     * @param solanaTokenProgramAddress The Solana token program address
     * @param solanaAssociatedTokenProgramAddress The Solana ATA program address
     */
    struct InfinexBeaconConstructorArgs {
        address trustedForwarder;
        address appRegistry;
        address latestAccountImplementation;
        address initialProxyImplementation;
        address revenuePool;
        address USDC;
        uint256 minimumUSDCBridgeAmount;
        address circleBridge;
        address circleMinter;
        address wormholeCircleBridge;
        uint32 defaultDestinationCCTPDomain;
        uint16 defaultDestinationWormholeChainId;
        uint16[] supportedWormholeChainIds;
        uint32 solanaCCTPDestinationDomain;
        bytes solanaWalletSeed;
        bytes solanaFixedPDASeed;
        bytes32 solanaWalletProgramAddress;
        bytes32 solanaTokenMintAddress;
        bytes32 solanaTokenProgramAddress;
        bytes32 solanaAssociatedTokenProgramAddress;
    }

    /**
     * @notice Struct containing both Circle and Wormhole bridge configuration
     * @param minimumUSDCBridgeAmount Minimum amount of USDC required to bridge
     * @param circleBridge Address of the Circle bridge contract
     * @param circleMinter Address of the Circle minter contract, used for checking the maximum bridge amount
     * @param wormholeCircleBridge Address of the Wormhole Circle bridge contract
     * @param defaultDestinationCCTPDomain the CCTP domain of the default destination chain.
     * @param defaultDestinationWormholeChainId the Wormhole chain id of the default destination chain.
     * @dev Chain id is the official chain id for evm chains and documented one for non evm chains.
     */
    struct BridgeConfiguration {
        uint256 minimumUSDCBridgeAmount;
        address circleBridge;
        address circleMinter;
        address wormholeCircleBridge;
        uint32 defaultDestinationCCTPDomain;
        uint16 defaultDestinationWormholeChainId;
    }

    /**
     * @notice The addresses for implementations referenced by the beacon
     * @param initialProxyImplementation The initial proxy implementation address used for account creation to ensure identical cross chain addresses
     * @param latestAccountImplementation The latest account implementation address, used for account upgrades and new accounts
     * @param latestInfinexProtocolConfigBeacon The latest Infinex Protocol config beacon address, used for pointing account updates to the latest beacon
     */
    struct ImplementationAddresses {
        address initialProxyImplementation;
        address latestAccountImplementation;
        address latestInfinexProtocolConfigBeacon;
    }

    /**
     * @notice Struct containing the Solana configuration needed to verify addresses
     * @param walletSeed The salt used to generate the Solana account (fixed seed "wallet")
     * @param fixedPDASeed The salt used to generate the PDA (Program Derived Address)
     * @param walletProgramAddress The Solana Wallet Program Address
     * @param tokenMintAddress The Solana token mint address
     * @param tokenProgramAddress The Solana token address
     * @param associatedTokenProgramAddress The Solana ATA program address
     */
    struct SolanaConfiguration {
        bytes walletSeed;
        bytes fixedPDASeed;
        bytes32 walletProgramAddress;
        bytes32 tokenMintAddress;
        bytes32 tokenProgramAddress;
        bytes32 associatedTokenProgramAddress;
    }

    /*///////////////////////////////////////////////////////////////
    	 										EVENTS
    ///////////////////////////////////////////////////////////////*/

    event LatestAccountImplementationSet(address latestAccountImplementation);
    event InitialProxyImplementationSet(address initialProxyImplementation);
    event AppRegistrySet(address appRegistry);
    event RevenuePoolSet(address revenuePool);
    event USDCAddressSet(address USDC);
    event CircleBridgeParamsSet(address circleBridge, address circleMinter, uint32 defaultDestinationCCTPDomain);
    event WormholeCircleBridgeParamsSet(address wormholeCircleBridge, uint16 defaultDestinationWormholeChainId);
    event LatestInfinexProtocolConfigBeaconSet(address latestInfinexProtocolConfigBeacon);
    event WithdrawalFeeUSDCSet(uint256 withdrawalFee);
    event FundsRecoveryStatusSet(bool status);
    event MinimumUSDCBridgeAmountSet(uint256 amount);
    event WormholeDestinationDomainSet(uint256 indexed chainId, uint16 destinationDomain);
    event CircleDestinationDomainSet(uint256 indexed chainId, uint32 destinationDomain);
    event TrustedRecoveryKeeperSet(address indexed trustedRecoveryKeeper, bool isTrusted);
    event SupportedWormholeChainIdSet(uint16 wormholeChainId, bool status);
    event SolanaCCTPDestinationDomainSet(uint32 solanaCCTPDestinationDomain);

    /*///////////////////////////////////////////////////////////////
    	 									VARIABLES
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Gets the timestamp the beacon was deployed
     * @return The timestamp the beacon was deployed
     */
    function CREATED_AT() external view returns (uint256);

    /**
     * @notice Gets the trusted forwarder address
     * @return The address of the trusted forwarder
     */
    function TRUSTED_FORWARDER() external view returns (address);

    /**
     * @notice Gets the app registry address
     * @return The address of the app registry
     */
    function appRegistry() external view returns (address);

    /**
     * @notice A platform wide feature flag to enable or disable funds recovery, false by default
     * @return True if funds recovery is active
     */
    function fundsRecoveryActive() external view returns (bool);

    /**
     * @notice Gets the revenue pool address
     * @return The address of the revenue pool
     */
    function revenuePool() external view returns (address);

    /**
     * @notice Gets the USDC amount to charge as withdrawal fee
     * @return The withdrawal fee in USDC's decimals
     */
    function withdrawalFeeUSDC() external view returns (uint256);

    /**
     * @notice Retrieves the USDC address.
     * @return The address of the USDC token
     */
    function USDC() external view returns (address);

    /*///////////////////////////////////////////////////////////////
    	 								VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Retrieves supported wormhole chain ids.
     * @param _wormholeChainId the chain id to check
     * @return bool if the chain is supported or not.
     */
    function isSupportedWormholeChainId(uint16 _wormholeChainId) external view returns (bool);

    /**
     * @notice Retrieves the minimum USDC amount that can be bridged.
     * @return The minimum USDC bridge amount.
     */
    function getMinimumUSDCBridgeAmount() external view returns (uint256);

    /**
     * @notice Retrieves the Circle Bridge parameters.
     * @return circleBridge The address of the Circle Bridge contract.
     * @return circleMinter The address of the TokenMinter contract.
     * @return defaultDestinationCCTPDomain The CCTP domain of the default destination chain.
     */
    function getCircleBridgeParams()
        external
        view
        returns (address circleBridge, address circleMinter, uint32 defaultDestinationCCTPDomain);

    /**
     * @notice Retrieves the Circle Bridge address.
     * @return The address of the Circle Bridge contract.
     */
    function getCircleBridge() external view returns (address);

    /**
     * @notice Retrieves the Circle TokenMinter address.
     * @return The address of the Circle TokenMinter contract.
     */
    function getCircleMinter() external view returns (address);

    /**
     * @notice Retrieves the CCTP domain of the destination chain.
     * @return The CCTP domain of the default destination chain.
     */
    function getDefaultDestinationCCTPDomain() external view returns (uint32);

    /**
     * @notice Retrieves the parameters required for Wormhole bridging.
     * @return The address of the Wormhole Circle Bridge contract.
     * @return The default wormhole destination domain for the circle bridge contract.
     */
    function getWormholeCircleBridgeParams() external view returns (address, uint16);

    /**
     * @notice Retrieves the Wormhole Circle Bridge address.
     * @return The address of the Wormhole Circle Bridge contract.
     */
    function getWormholeCircleBridge() external view returns (address);

    /**
     * @notice Retrieves the Wormhole chain id for Base, or Ethereum Mainnet if deployed on Base.
     * @return The Wormhole chain id of the default destination chain.
     */
    function getDefaultDestinationWormholeChainId() external view returns (uint16);

    /**
     * @notice Retrieves the circle CCTP destination domain for solana.
     * @return The CCTP destination domain for solana.
     */
    function getSolanaCCTPDestinationDomain() external view returns (uint32);

    /**
     * @notice Gets the latest account implementation address.
     * @return The address of the latest account implementation.
     */
    function getLatestAccountImplementation() external view returns (address);

    /**
     * @notice Gets the initial proxy implementation address.
     * @return The address of the initial proxy implementation.
     */
    function getInitialProxyImplementation() external view returns (address);

    /**
     * @notice The latest Infinex Protocol config beacon address, used for pointing account updates to the latest beacon.
     * @return The address of the latest Infinex Protocol config beacon.
     */
    function getLatestInfinexProtocolConfigBeacon() external view returns (address);

    /**
     * @notice Checks if an address is a trusted recovery keeper.
     * @param _address The address to check.
     * @return True if the address is a trusted recovery keeper, false otherwise.
     */
    function isTrustedRecoveryKeeper(address _address) external view returns (bool);

    /**
     * @notice Returns the Solana configuration
     * @param walletSeed The salt used to generate the Solana account (fixed seed "wallet")
     * @param fixedPDASeed The salt used to generate the PDA (Program Derived Address)
     * @param walletProgramAddress The Solana Wallet Program Address
     * @param tokenMintAddress The Solana token mint address
     * @param tokenProgramAddress The Solana token program address
     * @param associatedTokenProgramAddress The Solana ATA program address
     */
    function getSolanaConfiguration()
        external
        view
        returns (
            bytes memory walletSeed,
            bytes memory fixedPDASeed,
            bytes32 walletProgramAddress,
            bytes32 tokenMintAddress,
            bytes32 tokenProgramAddress,
            bytes32 associatedTokenProgramAddress
        );

    /*///////////////////////////////////////////////////////////////
    	 							MUTATIVE FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets or unsets a supported wormhole chain id.
     * @param _wormholeChainId the wormhole chain id to add or remove.
     * @param _status the status of the chain id.
     */
    function setSupportedWormholeChainId(uint16 _wormholeChainId, bool _status) external;

    /**
     * @notice Sets the solana CCTP destination domain
     * @param _solanaCCTPDestinationDomain the destination domain for circles CCTP USDC bridge.
     */
    function setSolanaCCTPDestinationDomain(uint32 _solanaCCTPDestinationDomain) external;

    /**
     * @notice Sets the address of the app registry contract.
     * @param _appRegistry The address of the app registry contract.
     */
    function setAppRegistry(address _appRegistry) external;

    /**
     * @notice Sets or unsets an address as a trusted recovery keeper.
     * @param _address The address to set or unset.
     * @param _isTrusted Boolean indicating whether to set or unset the address as a trusted recovery keeper.
     */
    function setTrustedRecoveryKeeper(address _address, bool _isTrusted) external;

    /**
     * @notice Sets the funds recovery flag to active.
     * @dev Initially only the owner can call this. After 90 days, it can be activated by anyone.
     */
    function setFundsRecoveryActive() external;

    /**
     * @notice Sets the revenue pool address.
     * @param _revenuePool The revenue pool address.
     */
    function setRevenuePool(address _revenuePool) external;

    /**
     * @notice Sets the USDC amount to charge as withdrawal fee.
     * @param _withdrawalFeeUSDC The withdrawal fee in USDC's decimals.
     */
    function setWithdrawalFeeUSDC(uint256 _withdrawalFeeUSDC) external;

    /**
     * @notice Sets the address of the USDC token contract.
     * @param _USDC The address of the USDC token contract.
     * @dev Only the contract owner can call this function.
     * @dev Throws an error if the provided address is the zero address.
     */
    function setUSDCAddress(address _USDC) external;

    /**
     * @notice Sets the minimum USDC amount that can be bridged, in 6 decimals.
     * @param _amount The minimum USDC bridge amount.
     */
    function setMinimumUSDCBridgeAmount(uint256 _amount) external;

    /**
     * @notice Sets the parameters for Circle bridging.
     * @param _circleBridge The address of the Circle Bridge contract.
     * @param _circleMinter The address of the Circle TokenMinter contract.
     * @param _defaultDestinationCCTPDomain The CCTP domain of the default destination chain.
     * @dev Circle Destination Domain can be 0 - Ethereum.
     */
    function setCircleBridgeParams(address _circleBridge, address _circleMinter, uint32 _defaultDestinationCCTPDomain) external;

    /**
     * @notice Sets the parameters for Wormhole bridging.
     * @param _wormholeCircleBridge The address of the Wormhole Circle Bridge contract.
     * @param _defaultDestinationWormholeChainId The wormhole domain of the default destination chain.
     */
    function setWormholeCircleBridgeParams(address _wormholeCircleBridge, uint16 _defaultDestinationWormholeChainId) external;

    /**
     * @notice Sets the initial proxy implementation address.
     * @param _initialProxyImplementation The initial proxy implementation address.
     * @dev Throws an error if the provided address is the zero address.
     */
    function setInitialProxyImplementation(address _initialProxyImplementation) external;

    /**
     * @notice Sets the latest account implementation address.
     * @param _latestAccountImplementation The latest account implementation address.
     * @dev Throws an error if the provided address is the zero address.
     */
    function setLatestAccountImplementation(address _latestAccountImplementation) external;

    /**
     * @notice Sets the latest Infinex Protocol Config Beacon.
     * @param _latestInfinexProtocolConfigBeacon The address of the Infinex Protocol Config Beacon.
     * @dev Throws an error if the provided address is the zero address.
     */
    function setLatestInfinexProtocolConfigBeacon(address _latestInfinexProtocolConfigBeacon) external;
}

//       c=<
//        |
//        |   ////\    1@2
//    @@  |  /___\**   @@@2			@@@@@@@@@@@@@@@@@@@@@@
//   @@@  |  |~L~ |*   @@@@@@		@@@  @@@@@        @@@@    @@@ @@@@    @@@  @@@@@@@@ @@@@ @@@@    @@@ @@@@@@@@@ @@@@   @@@@
//  @@@@@ |   \=_/8    @@@@1@@		@@@  @@@@@  @@@@  @@@@    @@@ @@@@@   @@@ @@@@@@@@@ @@@@ @@@@@  @@@@ @@@@@@@@@  @@@@ @@@@
// @@@@@@| _ /| |\__ @@@@@@@@2		@@@  @@@@@  @@@@  @@@@    @@@ @@@@@@@ @@@ @@@@      @@@@ @@@@@@ @@@@ @@@         @@@@@@@
// 1@@@@@@|\  \___/)   @@1@@@@@2	~~~  ~~~~~  @@@@  ~~@@    ~~~ ~~~~~~~~~~~ ~~~~      ~~~~ ~~~~~~~~~~~ ~@@          @@@@@
// 2@@@@@ |  \ \ / |     @@@@@@2	@@@  @@@@@  @@@@  @@@@    @@@ @@@@@@@@@@@ @@@@@@@@@ @@@@ @@@@@@@@@@@ @@@@@@@@@    @@@@@
// 2@@@@  |_  >   <|__    @@1@12	@@@  @@@@@  @@@@  @@@@    @@@ @@@@ @@@@@@ @@@@      @@@@ @@@@ @@@@@@ @@@         @@@@@@@
// @@@@  / _|  / \/    \   @@1@		@@@   @@@   @@@@  @@@@    @@@ @@@@  @@@@@ @@@@      @@@@ @@@@  @@@@@ @@@@@@@@@  @@@@ @@@@
//  @@ /  |^\/   |      |   @@1		@@@         @@@@  @@@@    @@@ @@@@    @@@ @@@@      @@@@ @@@    @@@@ @@@@@@@@@ @@@@   @@@@
//   /     / ---- \ \\\=    @@		@@@@@@@@@@@@@@@@@@@@@@
//   \___/ --------  ~~    @@@
//     @@  | |   | |  --   @@
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

library Error {
    /*///////////////////////////////////////////////////////////////
                                            GENERIC
    ///////////////////////////////////////////////////////////////*/

    error AlreadyExists();

    error DoesNotExist();

    error Unauthorized();

    error InvalidLength();

    error NotOwner();

    error InvalidWormholeChainId();

    error InvalidCallerContext();

    /*///////////////////////////////////////////////////////////////
                                            ADDRESS
    ///////////////////////////////////////////////////////////////*/

    error ImplementationMismatch(address implementation, address latestImplementation);

    error InvalidWithdrawalAddress(address to);

    error NullAddress();

    error SameAddress();

    error InvalidSolanaAddress();

    error AddressAlreadySet();

    error InsufficientAllowlistDelay();

    /*///////////////////////////////////////////////////////////////
                                    AMOUNT / BALANCE
    ///////////////////////////////////////////////////////////////*/

    error InsufficientBalance();

    error InsufficientWithdrawalAmount(uint256 amount);

    error InsufficientBalanceForFee(uint256 balance, uint256 fee);

    error InvalidNonce(bytes32 nonce);

    error ZeroValue();

    error AmountDeltaZeroValue();

    error DecimalsMoreThan18(uint256 decimals);

    error InsufficientBridgeAmount();

    error BridgeMaxAmountExceeded();

    error ETHTransferFailed();

    error OutOfBounds();

    /*///////////////////////////////////////////////////////////////
                                            ACCOUNT
    ///////////////////////////////////////////////////////////////*/

    error CreateAccountDisabled();

    error InvalidKeysForSalt();

    error PredictAddressDisabled();

    error FundsRecoveryActivationDeadlinePending();

    error InvalidAppAccount();

    error InvalidAppBeacon();

    /*///////////////////////////////////////////////////////////////
                                        KEY MANAGEMENT
    ///////////////////////////////////////////////////////////////*/

    error InvalidRequest();

    error InvalidKeySignature(address from);

    error KeyAlreadyInvalid();

    error KeyAlreadyValid();

    error KeyNotFound();

    error CannotRemoveLastKey();

    /*///////////////////////////////////////////////////////////////
                                     GAS FEE REBATE
    ///////////////////////////////////////////////////////////////*/

    error InvalidDeductGasFunction(bytes4 sig);

    /*///////////////////////////////////////////////////////////////
                                FEATURE FLAGS
    ///////////////////////////////////////////////////////////////*/

    error FundsRecoveryNotActive();
}