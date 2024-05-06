// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

contract Governable {
    address public gov;

    constructor() public {
        gov = msg.sender;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "Governable: forbidden");
        _;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IGovRequester {
    function afterGovGranted() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../access/Governable.sol";
import "../access/interfaces/IGovRequester.sol";

import "../peripherals/interfaces/ITimelock.sol";
import "../peripherals/interfaces/IHandlerTarget.sol";
import "../tokens/interfaces/IMintable.sol";

contract BaseMigrator is IGovRequester {
    address public immutable admin;
    address public immutable stakedGmxTracker;
    address public immutable bonusGmxTracker;
    address public immutable feeGmxTracker;
    address public immutable stakedGlpTracker;
    address public immutable feeGlpTracker;
    address public immutable gmxVester;
    address public immutable glpVester;
    address public immutable esGmx;
    address public immutable bnGmx;
    address public immutable rewardRouter;

    address public expectedGovGrantedCaller;

    modifier onlyAdmin() {
        require(msg.sender == admin, "forbidden");
        _;
    }

    constructor(
        address _admin,
        address _stakedGmxTracker,
        address _bonusGmxTracker,
        address _feeGmxTracker,
        address _stakedGlpTracker,
        address _feeGlpTracker,
        address _gmxVester,
        address _glpVester,
        address _esGmx,
        address _bnGmx,
        address _rewardRouter
    ) public {
        admin = _admin;

        stakedGmxTracker = _stakedGmxTracker;
        bonusGmxTracker = _bonusGmxTracker;
        feeGmxTracker = _feeGmxTracker;
        stakedGlpTracker = _stakedGlpTracker;
        feeGlpTracker = _feeGlpTracker;
        gmxVester = _gmxVester;
        glpVester = _glpVester;
        esGmx = _esGmx;
        bnGmx = _bnGmx;

        rewardRouter = _rewardRouter;
    }

    function migrate() external onlyAdmin {
        address gov = Governable(stakedGmxTracker).gov();
        expectedGovGrantedCaller = gov;

        address[] memory targets = new address[](9);
        targets[0] = stakedGmxTracker;
        targets[1] = bonusGmxTracker;
        targets[2] = feeGmxTracker;
        targets[3] = stakedGlpTracker;
        targets[4] = feeGlpTracker;
        targets[5] = gmxVester;
        targets[6] = glpVester;
        targets[7] = esGmx;
        targets[8] = bnGmx;

        ITimelock(gov).requestGov(targets);
    }

    function afterGovGranted() external override {
        require(msg.sender == expectedGovGrantedCaller, "forbidden");

        _toggleRewardRouter(true);

        _makeExternalCall();

        _toggleRewardRouter(false);

        address mainGov = msg.sender;

        Governable(stakedGmxTracker).setGov(mainGov);
        Governable(bonusGmxTracker).setGov(mainGov);
        Governable(feeGmxTracker).setGov(mainGov);
        Governable(stakedGlpTracker).setGov(mainGov);
        Governable(feeGlpTracker).setGov(mainGov);
        Governable(gmxVester).setGov(mainGov);
        Governable(glpVester).setGov(mainGov);
        Governable(esGmx).setGov(mainGov);
        Governable(bnGmx).setGov(mainGov);

        expectedGovGrantedCaller = address(0);
    }

    function _makeExternalCall() internal virtual {}

    function _toggleRewardRouter(bool isEnabled) internal {
        IHandlerTarget(stakedGmxTracker).setHandler(rewardRouter, isEnabled);
        IHandlerTarget(bonusGmxTracker).setHandler(rewardRouter, isEnabled);
        IHandlerTarget(feeGmxTracker).setHandler(rewardRouter, isEnabled);
        IHandlerTarget(stakedGlpTracker).setHandler(rewardRouter, isEnabled);
        IHandlerTarget(feeGlpTracker).setHandler(rewardRouter, isEnabled);
        IHandlerTarget(gmxVester).setHandler(rewardRouter, isEnabled);
        IHandlerTarget(glpVester).setHandler(rewardRouter, isEnabled);
        IHandlerTarget(esGmx).setHandler(rewardRouter, isEnabled);
        IMintable(bnGmx).setMinter(rewardRouter, isEnabled);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./BaseMigrator.sol";
import "./BeefyTimelockCaller.sol";

contract BeefyMigrator is BaseMigrator {

    address public immutable beefyTimelockCaller;

    constructor(
        address _admin,
        address _stakedGmxTracker,
        address _bonusGmxTracker,
        address _feeGmxTracker,
        address _stakedGlpTracker,
        address _feeGlpTracker,
        address _gmxVester,
        address _glpVester,
        address _esGmx,
        address _bnGmx,
        address _rewardRouter,
        address _beefyTimelockCaller
    ) public BaseMigrator(
        _admin,
        _stakedGmxTracker,
        _bonusGmxTracker,
        _feeGmxTracker,
        _stakedGlpTracker,
        _feeGlpTracker,
        _gmxVester,
        _glpVester,
        _esGmx,
        _bnGmx,
        _rewardRouter
    ) {
        beefyTimelockCaller = _beefyTimelockCaller;
    }

    function _makeExternalCall() internal override {
        BeefyTimelockCaller(beefyTimelockCaller).executeProposals();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./interfaces/ITimelockController.sol";

pragma experimental ABIEncoderV2;

contract BeefyTimelockCaller {
    bool public isInitialized;
    address public parent;
    address public gov;
    uint256 public chainId;

    constructor() public {
        gov = msg.sender;
    }

    function initialize(
        uint256 _chainId,
        address _parent
    ) external {
        require(msg.sender == gov, "forbidden");
        require(!isInitialized, "already initialized");
        isInitialized = true;

        chainId = _chainId;
        parent = _parent;
    }

    function executeProposals() external {
        require(msg.sender == parent, "forbidden");

        if (chainId == 42161) {
            ITimelockController timelock = ITimelockController(0x9A94784264AaAE397441c1e47fA132BE4e61BdaD);

            address[] memory targets = new address[](2);
            targets[0] = 0x5B904f19fb9ccf493b623e5c8cE91603665788b0;
            targets[1] = 0x9dbbBaecACEDf53d5Caa295b8293c1def2055Adc;

            uint256[] memory values = new uint256[](2);
            values[0] = 0;
            values[1] = 0;

            bytes[] memory payloads = new bytes[](2);
            payloads[0] = hex"e6685244";
            payloads[1] = hex"e6685244";

            bytes32 predecessor = 0x0000000000000000000000000000000000000000000000000000000000000000;
            bytes32 salt = 0x0000000000000000000000000000000000000000000000000000000000000000;

            timelock.executeBatch(
                targets,
                values,
                payloads,
                predecessor,
                salt
            );
        }

        if (chainId == 43114) {
            ITimelockController timelock = ITimelockController(0x690216f462615b749bEEB5AA3f1d89a2BEc45Ecf);

            address[] memory targets = new address[](2);
            targets[0] = 0x408835a5616baE0ECE4d3eF821C1D1CC88a2179E;
            targets[1] = 0x22EafB9C7E2858cfDA712940896464DdAA83d053;

            uint256[] memory values = new uint256[](2);
            values[0] = 0;
            values[1] = 0;

            bytes[] memory payloads = new bytes[](2);
            payloads[0] = hex"e6685244";
            payloads[1] = hex"e6685244";

            bytes32 predecessor = 0x0000000000000000000000000000000000000000000000000000000000000000;
            bytes32 salt = 0x0000000000000000000000000000000000000000000000000000000000000000;

            timelock.executeBatch(
                targets,
                values,
                payloads,
                predecessor,
                salt
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface ITimelockController {
    function executeBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata payloads,
        bytes32 predecessor,
        bytes32 salt
    ) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IHandlerTarget {
    function isHandler(address _account) external returns (bool);
    function setHandler(address _handler, bool _isActive) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ITimelock {
    function marginFeeBasisPoints() external returns (uint256);
    function setAdmin(address _admin) external;
    function enableLeverage(address _vault) external;
    function disableLeverage(address _vault) external;
    function setIsLeverageEnabled(address _vault, bool _isLeverageEnabled) external;
    function signalSetGov(address _target, address _gov) external;
    function setGov(address _target) external;
    function requestGov(address[] memory _targets) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IMintable {
    function isMinter(address _account) external returns (bool);
    function setMinter(address _minter, bool _isActive) external;
    function mint(address _account, uint256 _amount) external;
    function burn(address _account, uint256 _amount) external;
}