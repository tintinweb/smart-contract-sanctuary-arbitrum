// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import "../interfaces/IParameterProvider.sol";
import "../interfaces/IAddressProvider.sol";


contract Providers {

    IParameterProvider internal _paramProvider;
    IAddressProvider internal _addressProvider;

    constructor(IParameterProvider param, IAddressProvider add) {
        _paramProvider = param;
        _addressProvider = add;
    }

    function getAddress(AddressKey key) internal view returns (address) {
        return _addressProvider.getAddress(key);
    }

    function getParam(ParamKey key) internal view returns (uint) {
        return _paramProvider.getValue(key);
    }
}

// SPDX-License-Identifier: BUSL-1.1


pragma solidity 0.8.15;

library Constant {

    address public constant ZERO_ADDRESS                        = address(0);
    uint    public constant E18                                 = 1e18;
    uint    public constant PCNT_100                            = 1e18;
    uint    public constant PCNT_50                             = 5e17;
    uint    public constant E12                                 = 1e12;
    
    // SaleTypes
    uint8    public constant TYPE_IDO                            = 0;
    uint8    public constant TYPE_OTC                            = 1;
    uint8    public constant TYPE_NFT                            = 2;

    uint8    public constant PUBLIC                              = 0;
    uint8    public constant STAKER                              = 1;
    uint8    public constant WHITELISTED                         = 2;

    // Register Campaign
    uint    public constant MAX_REBATE_PCNT                     = 5e16; // 5% max   

    // Misc
    bytes public constant ETH_SIGN_PREFIX                       = "\x19Ethereum Signed Message:\n32";

}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

enum AddressKey {

    // Dao MultiSig
    DaoMultiSig,
    OfficialSigner,

    // Token
    Launch,
    GovernanceLaunch, // Staked Launch

    // Fees Addresses
    ReferralRewardVault,
    TreasuryVault,
    SalesVault
}

interface IAddressProvider {
    function getAddress(AddressKey key) external view returns (address);
    function getOfficialAddresses() external view returns (address a, address b);
    function getTokenAddresses() external view returns (address a, address b);
    function getFeeAddresses() external view returns (address[3] memory values);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

enum DataSource {
    Campaign,
    SuperCerts,
    Governance,
    Referral,
    Proposal,
    MarketPlace,
    SuperFarm,
    EggPool,
    Swap
}

enum DataAction {
    Buy,
    Refund,
    ClaimCerts,
    ClaimTokens,
    ClaimTeamTokens,
    List,
    Unlist,
    AddLp,
    RemoveLp,
    Rebate,
    Revenue,
    Swap
}

interface IDataLog {
    
    function log(address fromContract, address fromUser, uint source, uint action, uint data1, uint data2) external;

}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

enum ParamKey {

        // There will only be 1 parameterProvders in the native chain.
        // The rest of the eVM contracts will retrieve from this single parameterProvider.

        ProposalTimeToLive,
        ProposalMinPower,
        ProposalMaxQueue,
        ProposalVotingDuration,
        ProposalLaunchCollateral,
        ProposalTimeLock,
        ProposalCreatorExecutionDuration,
        ProposalQuorumPcnt, // Eg 30% of total power voted (Yes, No, Abstain) to pass.
        ProposalDummy1, // For future
        ProposalDummy2, // For future

        StakerMinLaunch,        // Eg: Min 1000 vLaunch
        StakerCapLaunch,        // Eg: Cap at 50,000 vLaunch
        StakerDiscountMinPnct,  // Eg: 1000 vLaunch gets 0.6% discount on Fee. For OTC and NFT only.
        StakerDiscountCapPnct,  // Eg: 50,000 vLaunch gets 30%% discount on Fee. For OTC and NFT only.
        StakerDummy1,           // For future
        StakerDummy2,           // For future

        RevShareReferralPcnt,   // Fee% for referrals
        RevShareTreasuryPcnt,   // Fee% for treasury
        RevShareDealsTeamPcnt,  // Business & Tech .
        RevShareDummy1, // For future
        RevShareDummy2, // For future

        ReferralUplineSplitPcnt,    // Eg 80% of rebate goes to upline, 20% to user
        ReferralDummy1, // For future
        ReferralDummy2, // For future

        SaleUserMaxFeePcnt,         // User's max fee% for any sale
        SaleUserCurrentFeePcnt,     // The current user's fee%
        SaleChargeFee18Dp,          // Each time a user buys, there's a fee like $1. Can be 0.
        SaleMaxPurchasePcntByFund,  // The max % of hardCap that SuperLauncher Fund can buy in a sale.
        SaleDummy1, // For future
        SaleDummy2, // For future

        lastIndex
    }

interface IParameterProvider {

    function setValue(ParamKey key, uint value) external;
    function setValues(ParamKey[] memory keys, uint[] memory values) external;
    function getValue(ParamKey key) external view returns (uint);
    function getValues(ParamKey[] memory keys) external view returns (uint[] memory);

    // Validation
    function validateChanges(ParamKey[] calldata keys, uint[] calldata values) external returns (bool success);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

interface IReferralRewardVault {

    function registerCampaign(address campaign) external;
    function declareReward(address currency, uint totalSale, uint totalRebate, uint uplineSplitPcnt) external;
    function recordUserReward(address user, uint amount, address referer) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

interface IRoles {
    function isAdmin(address user) view external returns (bool);
    function isDeployer(address user) view external returns (bool);
    function isConfigurator(address user) view external returns (bool);
    function isApprover(address user) view external returns (bool);
    function isReporter(address user) view external returns (bool);
    function isRole(string memory roleName, address user) view external returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import "../../base/Providers.sol";
import "../interfaces/IManager.sol";
import "../../interfaces/IRoles.sol";
import "../../interfaces/IDataLog.sol";
import "../../Constant.sol";

contract Manager is IManager, Providers {

    IRoles internal _roles;
    IDataLog internal _logger;
    
    enum Status {
        Inactive,
        Active,
        Cancelled
    }

     modifier onlyFactory() {
        require(_factoryMap[msg.sender], "Not Factory");
        _;
    }
    
    modifier onlyAdmin() {
        require(_roles.isAdmin(msg.sender), "Not Admin");
        _;
    }
    
    // Events
    event FactoryRegistered(address indexed deployedAddress);
    event EntryCancelled(address indexed contractAddress);
    event EntryAdded(address indexed contractAddress);
    
    struct CampaignInfo {
        address contractAddress;
        Status status;
    }
    
    // History & list of factories.
    mapping(address => bool) private _factoryMap;
    address[] private _factories;
    
    // History/list of all IDOs
    mapping(uint => CampaignInfo) internal _indexCampaignMap; // Starts from 1. Zero is invalid //
    mapping(address => uint) internal _addressIndexMap;  // Maps a campaign address to an index in _indexCampaignMap.
    uint internal _count;
    
    constructor(IRoles roles, IParameterProvider param, IAddressProvider add, IDataLog logger) Providers(param, add)
    {
        _roles = roles;
        _logger = logger;
    }
    
    // EXTERNAL FUNCTIONS
    function getCampaignInfo(uint id) external view returns (CampaignInfo memory) {
        return _indexCampaignMap[id];
    }
    
    function getTotalCampaigns() external view returns (uint) {
        return _count;
    }
    
    function registerFactory(address newFactory) external onlyAdmin {
        if ( _factoryMap[newFactory] == false) {
            _factoryMap[newFactory] = true;
            _factories.push(newFactory);
            emit FactoryRegistered(newFactory);
        }
    }
    
    function isFactory(address contractAddress) external view returns (bool) {
        return _factoryMap[contractAddress];
    }
    
    function getFactory(uint id) external view returns (address) {
        return ((id < _factories.length) ? _factories[id] : Constant.ZERO_ADDRESS );
    }

    // IMPLEMENTS IManager
    function getRoles() external view override returns (IRoles) {
        return _roles;
    }

    function getParameterProvider() external view override returns (IParameterProvider) {
        return _paramProvider;
    }

    function getAddressProvider() external view override returns (IAddressProvider) {
        return _addressProvider;
    }

    function logData(address user, DataSource source, DataAction action, uint data1, uint data2) external override {

        // From an official campaign ?
        uint id = _addressIndexMap[msg.sender];
        require(id > 0, "Invalid camapign");   

        _logger.log(msg.sender, user, uint(source), uint(action), data1, data2);
    }

    function isCampaignActive(address campaign) external override view returns (bool) {
        
        uint id = _addressIndexMap[campaign];
        CampaignInfo storage camp = _indexCampaignMap[id];
        return (camp.status == Status.Active);
    }

    // INTERNAL FUNCTIONS
    function _addEntry(address newContract) internal {
        _count++;
        _indexCampaignMap[_count] = CampaignInfo(newContract, Status.Active);
        _addressIndexMap[newContract] = _count;
        emit EntryAdded(newContract);
    }

    function _cancelEntry(address contractAddress) internal returns (bool success) {
        uint index = _addressIndexMap[contractAddress];
        CampaignInfo storage info = _indexCampaignMap[index];
        // Update status if campaign is exist & active
        if (info.status == Status.Active) {
            info.status = Status.Cancelled;         
            emit EntryCancelled(contractAddress);
            success = true;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

interface ICampaign {
    function cancelCampaign() external;
    function daoMultiSigEmergencyWithdraw(address tokenAddress, address to, uint amount) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import "../../interfaces/IRoles.sol";
import "../../interfaces/IDataLog.sol";
import "../../interfaces/IParameterProvider.sol";
import "../../interfaces/IAddressProvider.sol";

interface IManager {
    function getRoles() external view returns (IRoles);
    function getParameterProvider() external view returns (IParameterProvider);
     function getAddressProvider() external view returns (IAddressProvider);
    function logData(address user, DataSource source, DataAction action, uint data1, uint data2) external;
    function isCampaignActive(address campaign) external view returns (bool);
}

interface ISaleManager is IManager {
    function addCampaign(address newContract) external;
    function isRouterApproved(address router) external view returns (bool);
}

interface ICertsManager is IManager {
    function addCerts(address certsContract) external;   
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import "../base/Manager.sol";
import "../interfaces/ICampaign.sol";
import "../../interfaces/IParameterProvider.sol";
import "../../interfaces/IAddressProvider.sol";
import "../../interfaces/IReferralRewardVault.sol";

contract SaleManager is Manager, ISaleManager {

    mapping(address=>bool) private _whitelistedRouterMap; // Only router here can be used for LP provision

    event ApproveRouter(address router, bool approved);
    event DaoMultiSigEmergencyWithdraw(address contractAddress, address to, address tokenAddress, uint amount);

    constructor(IRoles roles, IParameterProvider param, IAddressProvider add, IDataLog logger) Manager(roles, param, add, logger) { 
    }

    function approveRouter(address router, bool approved) external onlyAdmin {
        if (router != address(0)) {
            _whitelistedRouterMap[router] = approved;
            emit ApproveRouter(router, approved);
        }
    }

    function isRouterApproved(address router) external override view returns (bool) {
        return _whitelistedRouterMap[router];
    }

    function addCampaign(address newContract) external override onlyFactory {
        _addEntry(newContract);
        // Add the campaign to the Referral Rebate vault
        address[3] memory temp = _addressProvider.getFeeAddresses();
        require(temp[0] != Constant.ZERO_ADDRESS, "Invalid address");
        IReferralRewardVault(temp[0]).registerCampaign(newContract);
    }

    function cancelCampaign(address contractAddress) external onlyAdmin {
        if (_cancelEntry(contractAddress)) {
            ICampaign(contractAddress).cancelCampaign();
        }
    }

    // Emergency withdrawal to admin address only. Note: Admin is a multiSig dao address.
    function daoMultiSigEmergencyWithdraw(address contractAddress, address tokenAddress, uint amount) external onlyAdmin {
        ICampaign(contractAddress).daoMultiSigEmergencyWithdraw(tokenAddress, msg.sender, amount);
        emit DaoMultiSigEmergencyWithdraw(contractAddress, msg.sender, tokenAddress, amount);
    }
}