// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {LibTermV2} from "./libraries/LibTermV2.sol";
import {LibYieldGeneration} from "./libraries/LibYieldGeneration.sol";

contract DiamondInitV2 {
    function init(
        address _aggregatorAddressEthUsd,
        address _aggregatorAddressUsdUsdc,
        address _sequencerUptimeFeedAddress,
        address _zapAddress, // Zaynfi Zap address
        address _vaultAddress // Zaynfi Vault address
    ) external {
        LibTermV2.TermConsts storage termConsts = LibTermV2._termConsts();
        LibYieldGeneration.YieldProviders storage yieldProvider = LibYieldGeneration
            ._yieldProviders();

        termConsts.sequencerStartupTime = 3600; // The sequencer must be running for at least an hour before it's reliable
        termConsts.aggregatorsAddresses["ETH/USD"] = _aggregatorAddressEthUsd;
        termConsts.aggregatorsAddresses["USD/USDC"] = _aggregatorAddressUsdUsdc;
        termConsts.sequencerUptimeFeedAddress = _sequencerUptimeFeedAddress;

        yieldProvider.zaps.push(_zapAddress);
        yieldProvider.vaults.push(_vaultAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

library LibTermV2 {
    uint public constant TERM_VERSION = 2;
    bytes32 constant TERM_CONSTS_POSITION = keccak256("diamond.standard.term.consts");
    bytes32 constant TERM_STORAGE_POSITION = keccak256("diamond.standard.term.storage");

    struct TermConsts {
        uint sequencerStartupTime;
        address sequencerUptimeFeedAddress;
        mapping(string => address) aggregatorsAddresses; // "ETH/USD" => address , "USD/USDC" => address
    }

    struct Term {
        bool initialized;
        bool expired;
        address termOwner;
        uint creationTime;
        uint termId;
        uint registrationPeriod; // Time for registration (seconds)
        uint totalParticipants; // Max number of participants
        uint cycleTime; // Time for single cycle (seconds)
        uint contributionAmount; // Amount user must pay per cycle (USD)
        uint contributionPeriod; // The portion of cycle user must make payment
        address stableTokenAddress;
    }

    struct TermStorage {
        uint nextTermId;
        mapping(uint => Term) terms; // termId => Term struct
        mapping(address => uint[]) participantToTermId; // userAddress => [termId1, termId2, ...]
    }

    function _termExists(uint termId) internal view returns (bool) {
        return _termStorage().terms[termId].initialized;
    }

    function _termConsts() internal pure returns (TermConsts storage termConsts) {
        bytes32 position = TERM_CONSTS_POSITION;
        assembly {
            termConsts.slot := position
        }
    }

    function _termStorage() internal pure returns (TermStorage storage termStorage) {
        bytes32 position = TERM_STORAGE_POSITION;
        assembly {
            termStorage.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

library LibYieldGeneration {
    uint public constant YIELD_GENERATION_VERSION = 1;
    bytes32 constant YIELD_PROVIDERS_POSITION = keccak256("diamond.standard.yield.providers");
    bytes32 constant YIELD_STORAGE_POSITION = keccak256("diamond.standard.yield.storage");

    enum YGProviders {
        InHouse,
        ZaynFi
    }

    // Both index 0 are reserved for ZaynFi
    struct YieldProviders {
        address[] zaps;
        address[] vaults;
    }

    struct YieldGeneration {
        bool initialized;
        YGProviders provider;
        uint startTimeStamp;
        uint totalDeposit;
        uint currentTotalDeposit;
        address zap;
        address vault;
        address[] yieldUsers;
        mapping(address => bool) hasOptedIn;
        mapping(address => uint256) withdrawnYield;
        mapping(address => uint256) withdrawnCollateral;
    }

    struct YieldStorage {
        mapping(uint => YieldGeneration) yields; // termId => YieldGeneration struct
    }

    function _yieldExists(uint termId) internal view returns (bool) {
        return _yieldStorage().yields[termId].initialized;
    }

    function _yieldProviders() internal pure returns (YieldProviders storage yieldProviders) {
        bytes32 position = YIELD_PROVIDERS_POSITION;
        assembly {
            yieldProviders.slot := position
        }
    }

    function _yieldStorage() internal pure returns (YieldStorage storage yieldStorage) {
        bytes32 position = YIELD_STORAGE_POSITION;
        assembly {
            yieldStorage.slot := position
        }
    }
}