/**
 *Submitted for verification at Arbiscan on 2023-05-18
*/

/* Tribeone: SystemStatus.sol
* Latest source (may be newer): https://github.com/TribeOneDefi/tribeone-v3-contracts/blob/master/contracts/SystemStatus.sol
* Docs: https://docs.tribeone.io/contracts/SystemStatus
*
* Contract Dependencies: 
*	- ISystemStatus
*	- Owned
* Libraries: (none)
*
* MIT License
* ===========
*
* Copyright (c) 2023 Tribeone
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/



pragma solidity ^0.5.16;

// https://docs.tribeone.io/contracts/source/contracts/owned
contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) public {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}


// https://docs.tribeone.io/contracts/source/interfaces/isystemstatus
interface ISystemStatus {
    struct Status {
        bool canSuspend;
        bool canResume;
    }

    struct Suspension {
        bool suspended;
        // reason is an integer code,
        // 0 => no reason, 1 => upgrading, 2+ => defined by system usage
        uint248 reason;
    }

    // Views
    function accessControl(bytes32 section, address account) external view returns (bool canSuspend, bool canResume);

    function requireSystemActive() external view;

    function systemSuspended() external view returns (bool);

    function requireIssuanceActive() external view;

    function requireExchangeActive() external view;

    function requireFuturesActive() external view;

    function requireFuturesMarketActive(bytes32 marketKey) external view;

    function requireExchangeBetweenTribesAllowed(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view;

    function requireTribeActive(bytes32 currencyKey) external view;

    function tribeSuspended(bytes32 currencyKey) external view returns (bool);

    function requireTribesActive(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view;

    function systemSuspension() external view returns (bool suspended, uint248 reason);

    function issuanceSuspension() external view returns (bool suspended, uint248 reason);

    function exchangeSuspension() external view returns (bool suspended, uint248 reason);

    function futuresSuspension() external view returns (bool suspended, uint248 reason);

    function tribeExchangeSuspension(bytes32 currencyKey) external view returns (bool suspended, uint248 reason);

    function tribeSuspension(bytes32 currencyKey) external view returns (bool suspended, uint248 reason);

    function futuresMarketSuspension(bytes32 marketKey) external view returns (bool suspended, uint248 reason);

    function getTribeExchangeSuspensions(bytes32[] calldata tribes)
        external
        view
        returns (bool[] memory exchangeSuspensions, uint256[] memory reasons);

    function getTribeSuspensions(bytes32[] calldata tribes)
        external
        view
        returns (bool[] memory suspensions, uint256[] memory reasons);

    function getFuturesMarketSuspensions(bytes32[] calldata marketKeys)
        external
        view
        returns (bool[] memory suspensions, uint256[] memory reasons);

    // Restricted functions
    function suspendIssuance(uint256 reason) external;

    function suspendTribe(bytes32 currencyKey, uint256 reason) external;

    function suspendFuturesMarket(bytes32 marketKey, uint256 reason) external;

    function updateAccessControl(
        bytes32 section,
        address account,
        bool canSuspend,
        bool canResume
    ) external;
}


// Inheritance


// https://docs.tribeone.io/contracts/source/contracts/systemstatus
contract SystemStatus is Owned, ISystemStatus {
    mapping(bytes32 => mapping(address => Status)) public accessControl;

    uint248 public constant SUSPENSION_REASON_UPGRADE = 1;

    bytes32 public constant SECTION_SYSTEM = "System";
    bytes32 public constant SECTION_ISSUANCE = "Issuance";
    bytes32 public constant SECTION_EXCHANGE = "Exchange";
    bytes32 public constant SECTION_FUTURES = "Futures";
    bytes32 public constant SECTION_TRIBEONE_EXCHANGE = "TribeExchange";
    bytes32 public constant SECTION_TRIBEONE = "Tribe";

    bytes32 public constant CONTRACT_NAME = "SystemStatus";

    Suspension public systemSuspension;

    Suspension public issuanceSuspension;

    Suspension public exchangeSuspension;

    Suspension public futuresSuspension;

    mapping(bytes32 => Suspension) public tribeExchangeSuspension;

    mapping(bytes32 => Suspension) public tribeSuspension;

    mapping(bytes32 => Suspension) public futuresMarketSuspension;

    constructor(address _owner) public Owned(_owner) {}

    /* ========== VIEWS ========== */
    function requireSystemActive() external view {
        _internalRequireSystemActive();
    }

    function systemSuspended() external view returns (bool) {
        return systemSuspension.suspended;
    }

    function requireIssuanceActive() external view {
        // Issuance requires the system be active
        _internalRequireSystemActive();

        // and issuance itself of course
        _internalRequireIssuanceActive();
    }

    function requireExchangeActive() external view {
        // Exchanging requires the system be active
        _internalRequireSystemActive();

        // and exchanging itself of course
        _internalRequireExchangeActive();
    }

    function requireTribeExchangeActive(bytes32 currencyKey) external view {
        // Tribe exchange and transfer requires the system be active
        _internalRequireSystemActive();
        _internalRequireTribeExchangeActive(currencyKey);
    }

    function requireFuturesActive() external view {
        _internalRequireSystemActive();
        _internalRequireExchangeActive();
        _internalRequireFuturesActive();
    }

    /// @notice marketKey doesn't necessarily correspond to asset key
    function requireFuturesMarketActive(bytes32 marketKey) external view {
        _internalRequireSystemActive();
        _internalRequireExchangeActive(); // exchanging implicitely used
        _internalRequireFuturesActive(); // futures global flag
        _internalRequireFuturesMarketActive(marketKey); // specific futures market flag
    }

    function tribeSuspended(bytes32 currencyKey) external view returns (bool) {
        return systemSuspension.suspended || tribeSuspension[currencyKey].suspended;
    }

    function requireTribeActive(bytes32 currencyKey) external view {
        // Tribe exchange and transfer requires the system be active
        _internalRequireSystemActive();
        _internalRequireTribeActive(currencyKey);
    }

    function requireTribesActive(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view {
        // Tribe exchange and transfer requires the system be active
        _internalRequireSystemActive();
        _internalRequireTribeActive(sourceCurrencyKey);
        _internalRequireTribeActive(destinationCurrencyKey);
    }

    function requireExchangeBetweenTribesAllowed(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view {
        // Tribe exchange and transfer requires the system be active
        _internalRequireSystemActive();

        // and exchanging must be active
        _internalRequireExchangeActive();

        // and the tribe exchanging between the tribes must be active
        _internalRequireTribeExchangeActive(sourceCurrencyKey);
        _internalRequireTribeExchangeActive(destinationCurrencyKey);

        // and finally, the tribes cannot be suspended
        _internalRequireTribeActive(sourceCurrencyKey);
        _internalRequireTribeActive(destinationCurrencyKey);
    }

    function isSystemUpgrading() external view returns (bool) {
        return systemSuspension.suspended && systemSuspension.reason == SUSPENSION_REASON_UPGRADE;
    }

    function getTribeExchangeSuspensions(bytes32[] calldata tribes)
        external
        view
        returns (bool[] memory exchangeSuspensions, uint256[] memory reasons)
    {
        exchangeSuspensions = new bool[](tribes.length);
        reasons = new uint256[](tribes.length);

        for (uint i = 0; i < tribes.length; i++) {
            exchangeSuspensions[i] = tribeExchangeSuspension[tribes[i]].suspended;
            reasons[i] = tribeExchangeSuspension[tribes[i]].reason;
        }
    }

    function getTribeSuspensions(bytes32[] calldata tribes)
        external
        view
        returns (bool[] memory suspensions, uint256[] memory reasons)
    {
        suspensions = new bool[](tribes.length);
        reasons = new uint256[](tribes.length);

        for (uint i = 0; i < tribes.length; i++) {
            suspensions[i] = tribeSuspension[tribes[i]].suspended;
            reasons[i] = tribeSuspension[tribes[i]].reason;
        }
    }

    /// @notice marketKey doesn't necessarily correspond to asset key
    function getFuturesMarketSuspensions(bytes32[] calldata marketKeys)
        external
        view
        returns (bool[] memory suspensions, uint256[] memory reasons)
    {
        suspensions = new bool[](marketKeys.length);
        reasons = new uint256[](marketKeys.length);

        for (uint i = 0; i < marketKeys.length; i++) {
            suspensions[i] = futuresMarketSuspension[marketKeys[i]].suspended;
            reasons[i] = futuresMarketSuspension[marketKeys[i]].reason;
        }
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    function updateAccessControl(
        bytes32 section,
        address account,
        bool canSuspend,
        bool canResume
    ) external onlyOwner {
        _internalUpdateAccessControl(section, account, canSuspend, canResume);
    }

    function updateAccessControls(
        bytes32[] calldata sections,
        address[] calldata accounts,
        bool[] calldata canSuspends,
        bool[] calldata canResumes
    ) external onlyOwner {
        require(
            sections.length == accounts.length &&
                accounts.length == canSuspends.length &&
                canSuspends.length == canResumes.length,
            "Input array lengths must match"
        );
        for (uint i = 0; i < sections.length; i++) {
            _internalUpdateAccessControl(sections[i], accounts[i], canSuspends[i], canResumes[i]);
        }
    }

    function suspendSystem(uint256 reason) external {
        _requireAccessToSuspend(SECTION_SYSTEM);
        systemSuspension.suspended = true;
        systemSuspension.reason = uint248(reason);
        emit SystemSuspended(systemSuspension.reason);
    }

    function resumeSystem() external {
        _requireAccessToResume(SECTION_SYSTEM);
        systemSuspension.suspended = false;
        emit SystemResumed(uint256(systemSuspension.reason));
        systemSuspension.reason = 0;
    }

    function suspendIssuance(uint256 reason) external {
        _requireAccessToSuspend(SECTION_ISSUANCE);
        issuanceSuspension.suspended = true;
        issuanceSuspension.reason = uint248(reason);
        emit IssuanceSuspended(reason);
    }

    function resumeIssuance() external {
        _requireAccessToResume(SECTION_ISSUANCE);
        issuanceSuspension.suspended = false;
        emit IssuanceResumed(uint256(issuanceSuspension.reason));
        issuanceSuspension.reason = 0;
    }

    function suspendExchange(uint256 reason) external {
        _requireAccessToSuspend(SECTION_EXCHANGE);
        exchangeSuspension.suspended = true;
        exchangeSuspension.reason = uint248(reason);
        emit ExchangeSuspended(reason);
    }

    function resumeExchange() external {
        _requireAccessToResume(SECTION_EXCHANGE);
        exchangeSuspension.suspended = false;
        emit ExchangeResumed(uint256(exchangeSuspension.reason));
        exchangeSuspension.reason = 0;
    }

    function suspendFutures(uint256 reason) external {
        _requireAccessToSuspend(SECTION_FUTURES);
        futuresSuspension.suspended = true;
        futuresSuspension.reason = uint248(reason);
        emit FuturesSuspended(reason);
    }

    function resumeFutures() external {
        _requireAccessToResume(SECTION_FUTURES);
        futuresSuspension.suspended = false;
        emit FuturesResumed(uint256(futuresSuspension.reason));
        futuresSuspension.reason = 0;
    }

    /// @notice marketKey doesn't necessarily correspond to asset key
    function suspendFuturesMarket(bytes32 marketKey, uint256 reason) external {
        bytes32[] memory marketKeys = new bytes32[](1);
        marketKeys[0] = marketKey;
        _internalSuspendFuturesMarkets(marketKeys, reason);
    }

    /// @notice marketKey doesn't necessarily correspond to asset key
    function suspendFuturesMarkets(bytes32[] calldata marketKeys, uint256 reason) external {
        _internalSuspendFuturesMarkets(marketKeys, reason);
    }

    /// @notice marketKey doesn't necessarily correspond to asset key
    function resumeFuturesMarket(bytes32 marketKey) external {
        bytes32[] memory marketKeys = new bytes32[](1);
        marketKeys[0] = marketKey;
        _internalResumeFuturesMarkets(marketKeys);
    }

    /// @notice marketKey doesn't necessarily correspond to asset key
    function resumeFuturesMarkets(bytes32[] calldata marketKeys) external {
        _internalResumeFuturesMarkets(marketKeys);
    }

    function suspendTribeExchange(bytes32 currencyKey, uint256 reason) external {
        bytes32[] memory currencyKeys = new bytes32[](1);
        currencyKeys[0] = currencyKey;
        _internalSuspendTribeExchange(currencyKeys, reason);
    }

    function suspendTribesExchange(bytes32[] calldata currencyKeys, uint256 reason) external {
        _internalSuspendTribeExchange(currencyKeys, reason);
    }

    function resumeTribeExchange(bytes32 currencyKey) external {
        bytes32[] memory currencyKeys = new bytes32[](1);
        currencyKeys[0] = currencyKey;
        _internalResumeTribesExchange(currencyKeys);
    }

    function resumeTribesExchange(bytes32[] calldata currencyKeys) external {
        _internalResumeTribesExchange(currencyKeys);
    }

    function suspendTribe(bytes32 currencyKey, uint256 reason) external {
        bytes32[] memory currencyKeys = new bytes32[](1);
        currencyKeys[0] = currencyKey;
        _internalSuspendTribes(currencyKeys, reason);
    }

    function suspendTribes(bytes32[] calldata currencyKeys, uint256 reason) external {
        _internalSuspendTribes(currencyKeys, reason);
    }

    function resumeTribe(bytes32 currencyKey) external {
        bytes32[] memory currencyKeys = new bytes32[](1);
        currencyKeys[0] = currencyKey;
        _internalResumeTribes(currencyKeys);
    }

    function resumeTribes(bytes32[] calldata currencyKeys) external {
        _internalResumeTribes(currencyKeys);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _requireAccessToSuspend(bytes32 section) internal view {
        require(accessControl[section][msg.sender].canSuspend, "Restricted to access control list");
    }

    function _requireAccessToResume(bytes32 section) internal view {
        require(accessControl[section][msg.sender].canResume, "Restricted to access control list");
    }

    function _internalRequireSystemActive() internal view {
        require(
            !systemSuspension.suspended,
            systemSuspension.reason == SUSPENSION_REASON_UPGRADE
                ? "Tribeone is suspended, upgrade in progress... please stand by"
                : "Tribeone is suspended. Operation prohibited"
        );
    }

    function _internalRequireIssuanceActive() internal view {
        require(!issuanceSuspension.suspended, "Issuance is suspended. Operation prohibited");
    }

    function _internalRequireExchangeActive() internal view {
        require(!exchangeSuspension.suspended, "Exchange is suspended. Operation prohibited");
    }

    function _internalRequireFuturesActive() internal view {
        require(!futuresSuspension.suspended, "Futures markets are suspended. Operation prohibited");
    }

    function _internalRequireTribeExchangeActive(bytes32 currencyKey) internal view {
        require(!tribeExchangeSuspension[currencyKey].suspended, "Tribe exchange suspended. Operation prohibited");
    }

    function _internalRequireTribeActive(bytes32 currencyKey) internal view {
        require(!tribeSuspension[currencyKey].suspended, "Tribe is suspended. Operation prohibited");
    }

    function _internalRequireFuturesMarketActive(bytes32 marketKey) internal view {
        require(!futuresMarketSuspension[marketKey].suspended, "Market suspended");
    }

    function _internalSuspendTribes(bytes32[] memory currencyKeys, uint256 reason) internal {
        _requireAccessToSuspend(SECTION_TRIBEONE);
        for (uint i = 0; i < currencyKeys.length; i++) {
            bytes32 currencyKey = currencyKeys[i];
            tribeSuspension[currencyKey].suspended = true;
            tribeSuspension[currencyKey].reason = uint248(reason);
            emit TribeSuspended(currencyKey, reason);
        }
    }

    function _internalResumeTribes(bytes32[] memory currencyKeys) internal {
        _requireAccessToResume(SECTION_TRIBEONE);
        for (uint i = 0; i < currencyKeys.length; i++) {
            bytes32 currencyKey = currencyKeys[i];
            emit TribeResumed(currencyKey, uint256(tribeSuspension[currencyKey].reason));
            delete tribeSuspension[currencyKey];
        }
    }

    function _internalSuspendTribeExchange(bytes32[] memory currencyKeys, uint256 reason) internal {
        _requireAccessToSuspend(SECTION_TRIBEONE_EXCHANGE);
        for (uint i = 0; i < currencyKeys.length; i++) {
            bytes32 currencyKey = currencyKeys[i];
            tribeExchangeSuspension[currencyKey].suspended = true;
            tribeExchangeSuspension[currencyKey].reason = uint248(reason);
            emit TribeExchangeSuspended(currencyKey, reason);
        }
    }

    function _internalResumeTribesExchange(bytes32[] memory currencyKeys) internal {
        _requireAccessToResume(SECTION_TRIBEONE_EXCHANGE);
        for (uint i = 0; i < currencyKeys.length; i++) {
            bytes32 currencyKey = currencyKeys[i];
            emit TribeExchangeResumed(currencyKey, uint256(tribeExchangeSuspension[currencyKey].reason));
            delete tribeExchangeSuspension[currencyKey];
        }
    }

    function _internalSuspendFuturesMarkets(bytes32[] memory marketKeys, uint256 reason) internal {
        _requireAccessToSuspend(SECTION_FUTURES);
        for (uint i = 0; i < marketKeys.length; i++) {
            bytes32 marketKey = marketKeys[i];
            futuresMarketSuspension[marketKey].suspended = true;
            futuresMarketSuspension[marketKey].reason = uint248(reason);
            emit FuturesMarketSuspended(marketKey, reason);
        }
    }

    function _internalResumeFuturesMarkets(bytes32[] memory marketKeys) internal {
        _requireAccessToResume(SECTION_FUTURES);
        for (uint i = 0; i < marketKeys.length; i++) {
            bytes32 marketKey = marketKeys[i];
            emit FuturesMarketResumed(marketKey, uint256(futuresMarketSuspension[marketKey].reason));
            delete futuresMarketSuspension[marketKey];
        }
    }

    function _internalUpdateAccessControl(
        bytes32 section,
        address account,
        bool canSuspend,
        bool canResume
    ) internal {
        require(
            section == SECTION_SYSTEM ||
                section == SECTION_ISSUANCE ||
                section == SECTION_EXCHANGE ||
                section == SECTION_FUTURES ||
                section == SECTION_TRIBEONE_EXCHANGE ||
                section == SECTION_TRIBEONE,
            "Invalid section supplied"
        );
        accessControl[section][account].canSuspend = canSuspend;
        accessControl[section][account].canResume = canResume;
        emit AccessControlUpdated(section, account, canSuspend, canResume);
    }

    /* ========== EVENTS ========== */

    event SystemSuspended(uint256 reason);
    event SystemResumed(uint256 reason);

    event IssuanceSuspended(uint256 reason);
    event IssuanceResumed(uint256 reason);

    event ExchangeSuspended(uint256 reason);
    event ExchangeResumed(uint256 reason);

    event FuturesSuspended(uint256 reason);
    event FuturesResumed(uint256 reason);

    event TribeExchangeSuspended(bytes32 currencyKey, uint256 reason);
    event TribeExchangeResumed(bytes32 currencyKey, uint256 reason);

    event TribeSuspended(bytes32 currencyKey, uint256 reason);
    event TribeResumed(bytes32 currencyKey, uint256 reason);

    event FuturesMarketSuspended(bytes32 marketKey, uint256 reason);
    event FuturesMarketResumed(bytes32 marketKey, uint256 reason);

    event AccessControlUpdated(bytes32 indexed section, address indexed account, bool canSuspend, bool canResume);
}