//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Adapter} from "src/adapters/Adapter.sol";
import {GlpRouter} from "src/glp/GlpRouter.sol";
import {GlpRewardDistributor} from "src/glp/rewards/GlpRewardDistributor.sol";
import {StableSwapper} from "src/glp/swappers/StableSwapper.sol";
import {JonesGlpRewardDistributor} from "src/glp/rewards/JonesGlpRewardDistributor.sol";
import {JonesGlpVaultRouter} from "src/glp/JonesGlpVaultRouter.sol";
import {JonesGlpRewardTracker} from "src/glp/rewards/JonesGlpRewardTracker.sol";
import {JonesGlpVault} from "src/glp/vaults/JonesGlpVault.sol";
import {JonesGlpCompoundRewards} from "src/glp/rewards/JonesGlpCompoundRewards.sol";
import {GlpStrategy} from "src/glp/strategies/GlpStrategy.sol";
import {JonesGlpStableVault} from "src/glp/vaults/JonesGlpStableVault.sol";
import {jGlpViewer} from "src/common/jGlpViewer.sol";
import {GlpAdapter} from "src/adapters/GlpAdapter.sol";
import {JonesGlpRewardsSplitter} from "src/glp/rewards/JonesGlpRewardsSplitter.sol";
import {WhitelistController} from "src/common/WhitelistController.sol";
import {IncentiveReceiver} from "src/common/IncentiveReceiver.sol";
import {Governable} from "src/common/Governable.sol";
import {OwnableUpgradeable} from "openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract Initializer is Governable {
    struct Contracts {
        Adapter adapter;
        GlpRouter router;
        GlpRewardDistributor distributor;
        StableSwapper stableSwapper;
    }

    struct Addresses {
        address adapter;
        address router;
        address distributor;
        address uniSwapper;
        address oneInchSwapper;
    }

    address private constant jonesDeployer = 0xc8ce0aC725f914dBf1D743D51B6e222b79F479f1;

    IERC20 private constant USDC = IERC20(0xaf88d065e77c8cC2239327C5EDb3A432268e5831);
    IERC20 private constant USDCE = IERC20(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);

    address private constant incentiveReceiverAddress = 0x5A446ba4D4BF482a3E63648E76E9404E784f7BbC;

    address private constant currentViewer = 0xEE5828181aFD52655457C2793833EbD7ccFE86Ac;
    address private constant stableRouter = 0x9c895CcDd1da452eb390803d48155e38f9fC2e4d;
    address private constant NewStableVault = 0xB0BDE111812EAC913b392D80D51966eC977bE3A2;

    JonesGlpRewardDistributor private constant jonesDistributor =
        JonesGlpRewardDistributor(0xda04B5F54756774AD405DE499bB5100c80980a12);
    JonesGlpVaultRouter private constant router = JonesGlpVaultRouter(0x2F43c6475f1ecBD051cE486A9f3Ccc4b03F3d713);
    JonesGlpRewardTracker private constant glpTracker =
        JonesGlpRewardTracker(0x13C6Bed5Aa16823Aba5bBA691CAeC63788b19D9d);
    JonesGlpVault private constant glpVault = JonesGlpVault(0x17fF154A329E37282eb9a76C3ae848FC277F24C7);
    JonesGlpCompoundRewards private constant glpCompound =
        JonesGlpCompoundRewards(0x7241bC8035b65865156DDb5EdEf3eB32874a3AF6);
    GlpStrategy private constant strategy = GlpStrategy(0x64ECc55a4F5D61ead9B966bcB59D777593afBd6f);
    JonesGlpRewardTracker private constant stableTracker =
        JonesGlpRewardTracker(0xEB23C7e19DB72F9a728fD64E1CAA459E457cfaca);
    JonesGlpCompoundRewards private constant stableCompound =
        JonesGlpCompoundRewards(0xe66998533a1992ecE9eA99cDf47686F4fc8458E0);
    JonesGlpStableVault private constant stableVault = JonesGlpStableVault(0xa485a0bc44988B95245D5F20497CCaFF58a73E99);
    jGlpViewer private constant viewer = jGlpViewer(0xEE5828181aFD52655457C2793833EbD7ccFE86Ac);
    GlpAdapter private constant adapter = GlpAdapter(0x42EfE3E686808ccA051A49BCDE34C5CbA2EBEfc1);
    JonesGlpRewardsSplitter private constant splitter =
        JonesGlpRewardsSplitter(0xB77289D3bF29bAADfC7D301Aa305fD4AcABf889a);
    WhitelistController private constant whitelistController =
        WhitelistController(0x2ACc798DA9487fdD7F4F653e04D8E8411cd73e88);
    IncentiveReceiver private constant incentiveReceiver = IncentiveReceiver(0x5A446ba4D4BF482a3E63648E76E9404E784f7BbC);

    address private constant glp = 0x5402B5F40310bDED796c7D0F3FF6683f5C0cFfdf;
    address private constant weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address private constant usdc = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
    address private constant usdce = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address private constant wbtc = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;
    address private constant link = 0xf97f4df75117a78c1A5a0DBb814Af92458539FB4;
    address private constant uni = 0xFa7F8980b0f1E64A2062791cc3b0871572f1F7f0;
    address private constant usdt = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address private constant dai = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;
    address private constant frax = 0x17FC002b466eEc40DaE837Fc4bE5c67993ddBd6F;

    address private constant glpVaultAddress = 0x17fF154A329E37282eb9a76C3ae848FC277F24C7;
    address private constant strategyAddress = 0x64ECc55a4F5D61ead9B966bcB59D777593afBd6f;
    address private constant glpCompoundAddress = 0x7241bC8035b65865156DDb5EdEf3eB32874a3AF6;
    address private constant glpTrackerAddress = 0x13C6Bed5Aa16823Aba5bBA691CAeC63788b19D9d;
    address private constant whitelistControllerAddress = 0x2ACc798DA9487fdD7F4F653e04D8E8411cd73e88;
    address private constant routerAddress = 0x2F43c6475f1ecBD051cE486A9f3Ccc4b03F3d713;
    address private constant adapterAddress = 0x42EfE3E686808ccA051A49BCDE34C5CbA2EBEfc1;
    address private constant stableVaultAddress = 0xa485a0bc44988B95245D5F20497CCaFF58a73E99;
    address private constant distributorAddress = 0xda04B5F54756774AD405DE499bB5100c80980a12;
    address private constant stableCompoundAddress = 0xe66998533a1992ecE9eA99cDf47686F4fc8458E0;
    address private constant stableTrackerAddress = 0xEB23C7e19DB72F9a728fD64E1CAA459E457cfaca;
    address private constant splitterAddress = 0xB77289D3bF29bAADfC7D301Aa305fD4AcABf889a;

    address private constant usdcOwner = 0xc8ce0aC725f914dBf1D743D51B6e222b79F479f1; //jonesDeployer

    constructor(Contracts memory contracts, Addresses memory addr, bytes memory OneInchSwap)
        Governable(jonesDeployer)
    {
        contracts.router.initialize(
            currentViewer,
            addr.adapter,
            NewStableVault,
            glpVaultAddress,
            strategyAddress,
            glpCompoundAddress,
            glpTrackerAddress,
            whitelistControllerAddress,
            incentiveReceiverAddress
        );

        contracts.distributor.initialize(
            addr.uniSwapper,
            NewStableVault,
            address(jonesDistributor.splitter()),
            incentiveReceiverAddress,
            glpTrackerAddress
        );

        address[] memory glpTokens = new address[](9);

        glpTokens[0] = weth;
        glpTokens[1] = usdc;
        glpTokens[2] = usdce;
        glpTokens[3] = wbtc;
        glpTokens[4] = link;
        glpTokens[5] = uni;
        glpTokens[6] = usdt;
        glpTokens[7] = dai;
        glpTokens[8] = frax;

        contracts.adapter.initialize(glpTokens, addr.router, stableRouter, NewStableVault, strategyAddress);

        ///@notice Pause Router
        router.togglePause();
        router.toggleEmergencyPause();

        ///@notice Remove Operators First
        glpTracker.removeOperator(routerAddress);
        glpVault.removeOperator(routerAddress);
        glpCompound.removeOperator(routerAddress);
        strategy.removeOperator(routerAddress);

        ///@notice Stable Tracker
        stableTracker.removeOperator(routerAddress);
        stableTracker.removeOperator(stableCompoundAddress);

        ///@notice Stable Vault
        stableVault.removeOperator(routerAddress);

        ///@notice Stable Compounding Vault
        stableCompound.removeOperator(routerAddress);

        ///@notice Update Viewer
        viewer.updateGlpVaultRouter(addr.router);
        viewer.updateJonesGlpStableVault(NewStableVault);

        ///@notice Update Contracts

        ///@notice Adapter
        adapter.updateVaultRouter(addr.router);

        ///@notice Glp Tracker
        glpTracker.addOperator(addr.router);
        glpTracker.setDistributor(addr.distributor);

        ///@notice Glp Vault
        glpVault.addOperator(addr.router);

        ///@notice Glp Compounding Vault
        glpCompound.setRouter(JonesGlpVaultRouter(addr.router));
        glpCompound.addOperator(addr.router);

        ///@notice Strategy
        strategy.addOperator(addr.router);

        ///@notice Distributor
        contracts.distributor.addOperator(strategyAddress);
        contracts.distributor.addOperator(address(glpTracker));

        ///@notice Splitter
        splitter.addOperator(addr.distributor);

        ///@notice Incentive Receiver
        incentiveReceiver.addDepositor(addr.router);
        incentiveReceiver.addDepositor(addr.distributor);

        ///@notice Transfer USDC to new Vault
        uint256 usdc_eAmount = USDCE.balanceOf(stableVaultAddress);
        uint256 usdcAmount;

        if (usdc_eAmount > 200e6) {
            stableVault.emergencyWithdraw(address(contracts.stableSwapper));
            contracts.stableSwapper.swapAndSend(OneInchSwap);
            usdcAmount = USDC.balanceOf(NewStableVault);
        } else {
            stableVault.emergencyWithdraw(usdcOwner);
        }

        if (usdcAmount < usdc_eAmount) {
            contracts.stableSwapper.send(usdcOwner, usdc_eAmount - usdcAmount);
        }

        ///@notice Add Internal Contracts
        whitelistController.addToInternalContract(addr.adapter);

        ///@notice Update Strategy
        strategy.setInternalContracts(NewStableVault, glpVaultAddress, addr.distributor);
        strategy.setTokenAddresses(glp, usdc);

        contracts.router.updateGovernor(jonesDeployer);
        contracts.distributor.updateGovernor(jonesDeployer);
        contracts.adapter.updateGovernor(jonesDeployer);
        Governable(routerAddress).updateGovernor(jonesDeployer);
        Governable(glpVaultAddress).updateGovernor(jonesDeployer);
        Governable(incentiveReceiverAddress).updateGovernor(jonesDeployer);
        Governable(stableVaultAddress).updateGovernor(jonesDeployer);
        Governable(strategyAddress).updateGovernor(jonesDeployer);
        Governable(adapterAddress).updateGovernor(jonesDeployer);
        Governable(glpTrackerAddress).updateGovernor(jonesDeployer);
        Governable(stableTrackerAddress).updateGovernor(jonesDeployer);
        Governable(glpCompoundAddress).updateGovernor(jonesDeployer);
        Governable(stableCompoundAddress).updateGovernor(jonesDeployer);
        Governable(splitterAddress).updateGovernor(jonesDeployer);
        OwnableUpgradeable(currentViewer).transferOwnership(jonesDeployer);
        OwnableUpgradeable(whitelistControllerAddress).transferOwnership(jonesDeployer);
    }

    function changeGovernor(address _contract, address _newGovernor) external onlyGovernor {
        Governable(_contract).updateGovernor(_newGovernor);
    }

    function changeOwnership(address _contract, address _newOwner) external onlyGovernor {
        OwnableUpgradeable(_contract).transferOwnership(_newOwner);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {IGmxRewardRouter} from "src/interfaces/IGmxRewardRouter.sol";
import {IGlpManager} from "src/interfaces/IGlpManager.sol";

import {IGMXVault} from "src/interfaces/IGMXVault.sol";

import {IJonesGlpVaultRouter} from "src/interfaces/IJonesGlpVaultRouter.sol";
import {IJonesGlpLeverageStrategy} from "src/interfaces/IJonesGlpLeverageStrategy.sol";
import {IStableRouter} from "src/interfaces/IStableRouter.sol";

import {UpgradeableOperable} from "src/common/UpgradeableOperable.sol";
import {ReentrancyGuardUpgradeable} from "openzeppelin-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";

import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";

import {WhitelistController} from "src/common/WhitelistController.sol";

contract Adapter is UpgradeableOperable, ReentrancyGuardUpgradeable {
    using Math for uint256;

    /* -------------------------------------------------------------------------- */
    /*                                  VARIABLES                                 */
    /* -------------------------------------------------------------------------- */

    IGmxRewardRouter public gmxRouter;
    IGlpManager private glpManager;
    address public socket;

    IERC20 public glp;
    IERC20 public usdc;

    IJonesGlpVaultRouter public glpRouter;
    IStableRouter public stableRouter;
    WhitelistController public controller;
    IJonesGlpLeverageStrategy public strategy;
    address public jUSDCVault;

    mapping(address => bool) public isValid;

    uint256 public constant BASIS_POINTS = 1e12;
    uint256 private constant PRECISION = 1e30;
    uint256 private constant USDC_DECIMALS = 1e6;
    uint256 private constant GLP_DECIMALS = 1e18;

    /* -------------------------------------------------------------------------- */
    /*                                 INITIALIZE                                 */
    /* -------------------------------------------------------------------------- */

    function initialize(
        address[] memory _tokens,
        address _glpRouter,
        address _stableRouter,
        address _jUSDCVault,
        address _strategy
    ) external initializer {
        __Governable_init(msg.sender);
        __ReentrancyGuard_init();

        uint8 i = 0;
        for (; i < _tokens.length;) {
            _editToken(_tokens[i], true);
            unchecked {
                i++;
            }
        }

        jUSDCVault = _jUSDCVault;

        glpRouter = IJonesGlpVaultRouter(_glpRouter);
        stableRouter = IStableRouter(_stableRouter);
        strategy = IJonesGlpLeverageStrategy(_strategy);

        controller = WhitelistController(0x2ACc798DA9487fdD7F4F653e04D8E8411cd73e88);
        socket = 0x88616cB9499F32Ff6A784B66B60aABF0bCf0df39;

        gmxRouter = IGmxRewardRouter(0xB95DB5B167D75e6d04227CfFFA61069348d271F5);
        glpManager = IGlpManager(0x3963FfC9dff443c2A94f21b129D429891E32ec18);

        glp = IERC20(0x5402B5F40310bDED796c7D0F3FF6683f5C0cFfdf);
        usdc = IERC20(0xaf88d065e77c8cC2239327C5EDb3A432268e5831);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  EXTERNAL                                  */
    /* -------------------------------------------------------------------------- */

    function zapToGlp(address _token, uint256 _amount, bool _compound, uint256 _minGlpOut)
        external
        nonReentrant
        validToken(_token)
        returns (uint256)
    {
        _onlyEOA();

        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        IERC20(_token).approve(gmxRouter.glpManager(), _amount);
        uint256 mintedGlp = gmxRouter.mintAndStakeGlp(_token, _amount, 0, _minGlpOut);

        glp.approve(address(glpRouter), mintedGlp);
        uint256 receipts = glpRouter.depositGlp(mintedGlp, msg.sender, _compound);

        return receipts;
    }

    function zapToGlpEth(bool _compound, uint256 _minGlpOut) external payable nonReentrant returns (uint256) {
        _onlyEOA();

        uint256 mintedGlp = gmxRouter.mintAndStakeGlpETH{value: msg.value}(0, _minGlpOut);

        glp.approve(address(glpRouter), mintedGlp);

        uint256 receipts = glpRouter.depositGlp(mintedGlp, msg.sender, _compound);

        return receipts;
    }

    function redeemGlpBasket(uint256 _shares, bool _compound, address _token, bool _native)
        external
        nonReentrant
        validToken(_token)
        returns (uint256)
    {
        _onlyEOA();

        uint256 assetsReceived = glpRouter.redeemGlpAdapter(_shares, _compound, _token, msg.sender, _native);

        return assetsReceived;
    }

    function depositGlp(uint256 _assets, bool _compound) external nonReentrant returns (uint256) {
        _onlyEOA();

        glp.transferFrom(msg.sender, address(this), _assets);

        glp.approve(address(glpRouter), _assets);

        uint256 receipts = glpRouter.depositGlp(_assets, msg.sender, _compound);

        return receipts;
    }

    function depositStable(uint256 _assets) external nonReentrant returns (uint256) {
        _onlyEOA();

        usdc.transferFrom(msg.sender, address(this), _assets);

        usdc.approve(address(stableRouter), _assets);

        uint256 receipts = stableRouter.deposit(_assets, msg.sender);

        return receipts;
    }

    ///@notice MultiChain Deposits

    function multichainZapToGlp(address _receiver, address _token, bool _compound, uint256 _minGlpOut)
        external
        nonReentrant
        returns (uint256)
    {
        IERC20 token = IERC20(_token);

        uint256 amount = token.allowance(msg.sender, address(this));

        if (amount == 0 || !isValid[_token]) {
            return 0;
        }

        if (!_onlyAllowed(_receiver)) {
            revert NotWhitelisted();
        }

        token.transferFrom(msg.sender, address(this), amount);

        if (!_onlySocket()) {
            token.transfer(_receiver, amount);
            return 0;
        }

        address _glpManager = gmxRouter.glpManager();
        token.approve(_glpManager, amount);

        uint256 mintedGlp;

        try gmxRouter.mintAndStakeGlp(_token, amount, 0, _minGlpOut) returns (uint256 glpAmount) {
            mintedGlp = glpAmount;
        } catch {
            token.transfer(_receiver, amount);
            token.approve(_glpManager, 0);
            return 0;
        }

        address routerAddress = address(glpRouter);

        glp.approve(routerAddress, mintedGlp);

        try glpRouter.depositGlp(mintedGlp, _receiver, _compound) returns (uint256 receipts) {
            return receipts;
        } catch {
            glp.transfer(_receiver, mintedGlp);
            glp.approve(routerAddress, 0);
            return 0;
        }
    }

    function multichainZapToGlpEth(address payable _receiver, bool _compound, uint256 _minGlpOut)
        external
        payable
        nonReentrant
        returns (uint256)
    {
        if (msg.value == 0) {
            return 0;
        }

        if (!_onlyAllowed(_receiver)) {
            revert NotWhitelisted();
        }

        if (!_onlySocket()) {
            (bool sent,) = _receiver.call{value: msg.value}("");
            if (!sent) {
                revert SendETHFail();
            }
            return 0;
        }

        uint256 mintedGlp;

        try gmxRouter.mintAndStakeGlpETH{value: msg.value}(0, _minGlpOut) returns (uint256 glpAmount) {
            mintedGlp = glpAmount;
        } catch {
            (bool sent,) = _receiver.call{value: msg.value}("");
            if (!sent) {
                revert SendETHFail();
            }
            return 0;
        }

        address routerAddress = address(glpRouter);

        glp.approve(routerAddress, mintedGlp);

        try glpRouter.depositGlp(mintedGlp, _receiver, _compound) returns (uint256 receipts) {
            return receipts;
        } catch {
            glp.transfer(_receiver, mintedGlp);
            glp.approve(routerAddress, 0);
            return 0;
        }
    }

    function multichainDepositStable(address _receiver) external nonReentrant returns (uint256) {
        uint256 amount = usdc.allowance(msg.sender, address(this));

        if (amount == 0) {
            return 0;
        }

        if (!_onlyAllowed(_receiver)) {
            revert NotWhitelisted();
        }

        usdc.transferFrom(msg.sender, address(this), amount);

        if (!_onlySocket()) {
            usdc.transfer(_receiver, amount);
            return 0;
        }

        address routerAddress = address(stableRouter);

        usdc.approve(routerAddress, amount);

        try stableRouter.deposit(amount, _receiver) returns (uint256 receipts) {
            return receipts;
        } catch {
            usdc.transfer(_receiver, amount);
            usdc.approve(routerAddress, 0);
            return 0;
        }
    }
    /// @notice Calculate USDC needed to leverage new GLP and Verify if STable vault have enough USDC

    function aboveCap(uint256 _amount) public view returns (bool) {
        uint256 missingGlp = ((_amount * (strategy.getTargetLeverage() - BASIS_POINTS)) / BASIS_POINTS); // 18 Decimals

        uint256 stableToBorrow = strategy.getRequiredStableAmount(missingGlp); // 6 Decimals

        stableToBorrow = _adjustToGMXCap(stableToBorrow);

        if (stableToBorrow > usdc.balanceOf(jUSDCVault)) {
            return true;
        } else {
            return false;
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                                  GOVERNOR                                  */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Moves assets from the strategy to `_to`
     * @param _assets An array of IERC20 compatible tokens to move out from the strategy
     * @param _withdrawNative `true` if we want to move the native asset from the strategy
     */
    function emergencyWithdraw(address _to, address[] memory _assets, bool _withdrawNative) external onlyGovernor {
        uint256 assetsLength = _assets.length;
        for (uint256 i = 0; i < assetsLength; i++) {
            IERC20 asset_ = IERC20(_assets[i]);
            uint256 assetBalance = asset_.balanceOf(address(this));

            if (assetBalance > 0) {
                // Transfer the ERC20 tokens
                asset_.transfer(_to, assetBalance);
            }

            unchecked {
                ++i;
            }
        }

        uint256 nativeBalance = address(this).balance;

        // Nothing else to do
        if (_withdrawNative && nativeBalance > 0) {
            // Transfer the native currency
            (bool sent,) = payable(_to).call{value: nativeBalance}("");
            if (!sent) {
                revert SendETHFail();
            }
        }

        emit EmergencyWithdrawal(msg.sender, _to, _assets, _withdrawNative ? nativeBalance : 0);
    }

    function updateGmxRouter(address _gmxRouter) external onlyGovernor {
        gmxRouter = IGmxRewardRouter(_gmxRouter);
    }

    function updateGlpManager(address _glpManager) external onlyGovernor {
        glpManager = IGlpManager(_glpManager);
    }

    function updateSocket(address _socket) external onlyGovernor {
        socket = _socket;
    }

    function updateGlpRouter(address _glpRouter) external onlyGovernor {
        glpRouter = IJonesGlpVaultRouter(_glpRouter);
    }

    function updateStableRouter(address _stableRouter) external onlyGovernor {
        stableRouter = IStableRouter(_stableRouter);
    }

    function updateController(address _controller) external onlyGovernor {
        controller = WhitelistController(_controller);
    }

    function updateGlpToken(address _glp) external onlyGovernor {
        glp = IERC20(_glp);
    }

    function updateStableToken(address _stable) external onlyGovernor {
        usdc = IERC20(_stable);
    }

    function editToken(address _token, bool _valid) external onlyGovernor {
        _editToken(_token, _valid);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  PRIVATE                                   */
    /* -------------------------------------------------------------------------- */

    function _editToken(address _token, bool _valid) private {
        isValid[_token] = _valid;
    }

    function _onlyEOA() private view {
        if (msg.sender != tx.origin && !controller.isWhitelistedContract(msg.sender)) {
            revert NotWhitelisted();
        }
    }

    function _onlySocket() private view returns (bool) {
        if (msg.sender == socket) {
            return true;
        }
        return false;
    }

    function _onlyAllowed(address _receiver) private view returns (bool) {
        if (_isContract(_receiver) && !controller.isWhitelistedContract(_receiver)) {
            return false;
        }
        return true;
    }

    function _isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function _adjustToGMXCap(uint256 _stableAmount) private view returns (uint256) {
        IGlpManager manager = glpManager;
        IGMXVault vault = IGMXVault(manager.vault());

        address _usdc = address(usdc);

        uint256 usdgAmount =
            strategy.buyGlpStableSimulation(_stableAmount).mulDiv(manager.getAumInUsdg(false), glp.totalSupply());

        uint256 currentUsdgAmount = vault.usdgAmounts(_usdc);

        uint256 nextAmount = currentUsdgAmount + usdgAmount;
        uint256 maxUsdgAmount = vault.maxUsdgAmounts(_usdc);

        if (nextAmount > maxUsdgAmount) {
            uint256 redemptionAmount = (maxUsdgAmount - currentUsdgAmount).mulDiv(PRECISION, vault.getMaxPrice(_usdc));
            return redemptionAmount.mulDiv(USDC_DECIMALS, GLP_DECIMALS); // 6 decimals
        } else {
            return _stableAmount;
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                                  MODIFIERS                                 */
    /* -------------------------------------------------------------------------- */

    modifier validToken(address _token) {
        require(isValid[_token], "Invalid token.");
        _;
    }

    /* -------------------------------------------------------------------------- */
    /*                                  ERRROS                                    */
    /* -------------------------------------------------------------------------- */

    error NotWhitelisted();
    error SendETHFail();
    error OverUsdcCap();

    /* -------------------------------------------------------------------------- */
    /*                                  EVENTS                                    */
    /* -------------------------------------------------------------------------- */

    event EmergencyWithdrawal(address indexed caller, address indexed receiver, address[] tokens, uint256 nativeBalanc);
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2024 Jones DAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

pragma solidity ^0.8.10;

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";

import {ReentrancyGuardUpgradeable} from "openzeppelin-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";
import {PausableUpgradeable} from "openzeppelin-upgradeable/contracts/security/PausableUpgradeable.sol";
import {UpgradeableGovernable} from "src/common/UpgradeableGovernable.sol";
import {Pausable} from "src/common/Pausable.sol";

import {IUnderlyingVault} from "src/interfaces/jusdc/IUnderlyingVault.sol";
import {IJonesGlpLeverageStrategy} from "src/interfaces/IJonesGlpLeverageStrategy.sol";
import {IJonesGlpRewardTracker} from "src/interfaces/IJonesGlpRewardTracker.sol";
import {IJonesGlpCompoundRewards} from "src/interfaces/IJonesGlpCompoundRewards.sol";
import {IWhitelistController} from "src/interfaces/IWhitelistController.sol";
import {IIncentiveReceiver} from "src/interfaces/IIncentiveReceiver.sol";
import {IViewer} from "src/interfaces/IViewer.sol";

import {GlpAdapter} from "src/adapters/GlpAdapter.sol";
import {JonesGlpVault} from "src/glp/vaults/JonesGlpVault.sol";

import {IGmxRewardRouter} from "src/interfaces/IGmxRewardRouter.sol";

import {Errors} from "src/interfaces/Errors.sol";

contract GlpRouter is UpgradeableGovernable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using FixedPointMathLib for uint256;

    bool public initialized;

    struct WithdrawalSignal {
        uint256 targetEpoch;
        uint256 commitedShares;
        bool redeemed;
        bool compound;
    }

    /* -------------------------------------------------------------------------- */
    /*                                  VARIABLES                                 */
    /* -------------------------------------------------------------------------- */

    IGmxRewardRouter private constant router = IGmxRewardRouter(0xB95DB5B167D75e6d04227CfFFA61069348d271F5);
    address private constant weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    JonesGlpVault private glpVault;

    IJonesGlpLeverageStrategy public strategy;

    IUnderlyingVault public stableVault;
    IJonesGlpRewardTracker public glpRewardTracker;
    IJonesGlpCompoundRewards private glpCompoundRewards;
    IWhitelistController private whitelistController;
    IIncentiveReceiver private incentiveReceiver;
    IViewer private viewer;
    GlpAdapter private adapter;

    IERC20 private glp;

    uint256 private constant BASIS_POINTS = 1e12;

    /* -------------------------------------------------------------------------- */
    /*                                 INITIALIZE                                 */
    /* -------------------------------------------------------------------------- */

    function initialize(
        address _viewer,
        address _adapter,
        address _stableVault,
        address _underlyingVault,
        address _strategy,
        address _compoundingVault,
        address _tracker,
        address _whitelistController,
        address _incentiveReceiver
    ) external initializer {
        __Governable_init(msg.sender);
        __Pausable_init();
        __ReentrancyGuard_init();

        stableVault = IUnderlyingVault(_stableVault);
        glpVault = JonesGlpVault(_underlyingVault);
        strategy = IJonesGlpLeverageStrategy(_strategy);

        glpRewardTracker = IJonesGlpRewardTracker(_tracker);
        glpCompoundRewards = IJonesGlpCompoundRewards(_compoundingVault);

        incentiveReceiver = IIncentiveReceiver(_incentiveReceiver);
        whitelistController = IWhitelistController(_whitelistController);

        viewer = IViewer(_viewer);

        glp = IERC20(0x5402B5F40310bDED796c7D0F3FF6683f5C0cFfdf);
        adapter = GlpAdapter(_adapter);
    }

    // ============================= Whitelisted functions ================================ //

    /**
     * @notice The Adapter contract can deposit GLP to the system on behalf of the _sender
     * @param _assets Amount of assets deposited
     * @param _sender address of who is deposit the assets
     * @param _compound optional compounding rewards
     * @return Amount of shares jGLP minted
     */
    function depositGlp(uint256 _assets, address _sender, bool _compound) external whenNotPaused returns (uint256) {
        _onlyInternalContract(); //can only be adapter or compounder

        bytes32 role = whitelistController.getUserRole(_sender);
        IWhitelistController.RoleInfo memory info = whitelistController.getRoleInfo(role);

        IJonesGlpLeverageStrategy _strategy = strategy;
        JonesGlpVault _glpVault = glpVault;

        if (_assets > getMaxCapGlp() && !info.jGLP_BYPASS_CAP) {
            revert Errors.MaxGlpTvlReached();
        }

        if (_compound) {
            glpCompoundRewards.compound();
        }

        (uint256 compoundShares, uint256 vaultShares) = _deposit(_glpVault, _sender, _assets, _compound);

        _strategy.onGlpDeposit(_assets);

        if (_compound) {
            emit DepositGlp(_sender, _assets, compoundShares, _compound);
            return compoundShares;
        }

        emit DepositGlp(_sender, _assets, vaultShares, _compound);

        return vaultShares;
    }

    /**
     * @notice Users & Whitelist contract can redeem GLP from the system
     * @param _shares Amount of jGLP deposited to redeem GLP
     * @param _compound flag if the rewards are compounding
     * @return Amount of GLP remdeemed
     */
    function redeemGlp(uint256 _shares, bool _compound) external nonReentrant returns (uint256) {
        _onlyEOA();

        if (_compound) {
            glpCompoundRewards.compound();
            _shares = _unCompoundGlp(_shares, msg.sender);
        }

        glpRewardTracker.withdraw(msg.sender, _shares);
        JonesGlpVault _glpVault = glpVault;

        uint256 glpAmount = _glpVault.previewRedeem(_shares);

        _glpVault.burn(address(this), _shares);

        //We can't send glpAmount - retention here because it'd mess our rebalance
        glpAmount = strategy.onGlpRedeem(glpAmount);

        if (glpAmount > 0) {
            glpAmount = _distributeGlp(glpAmount, msg.sender, _compound);
        }

        return glpAmount;
    }

    /**
     * @notice User & Whitelist contract can redeem GLP using any asset of GLP basket from the system
     * @param _shares Amount of jGLP deposited to redeem GLP
     * @param _compound flag if the rewards are compounding
     * @param _token address of asset token
     * @param _user address of the user that will receive the assets
     * @param _native flag if the user will receive raw ETH
     * @return Amount of assets redeemed
     */
    function redeemGlpAdapter(uint256 _shares, bool _compound, address _token, address _user, bool _native)
        external
        nonReentrant
        returns (uint256)
    {
        if (msg.sender != address(adapter)) {
            revert Errors.OnlyAdapter();
        }

        if (_compound) {
            glpCompoundRewards.compound();
            _shares = _unCompoundGlp(_shares, _user);
        }
        glpRewardTracker.withdraw(_user, _shares);
        JonesGlpVault _glpVault = glpVault;

        uint256 glpAmount = _glpVault.previewRedeem(_shares);

        _glpVault.burn(address(this), _shares);

        //We can't send glpAmount - retention here because it'd mess our rebalance
        glpAmount = strategy.onGlpRedeem(glpAmount);

        if (glpAmount > 0) {
            glpAmount = _distributeGlpAdapter(glpAmount, _user, _token, _native, _compound);
        }

        return glpAmount;
    }

    /**
     * @notice User & Whitelist contract can claim their rewards
     * @return ETH rewards comming from GLP deposits
     */
    function claimRewards() external returns (uint256, uint256, uint256) {
        strategy.claimGlpRewards();

        uint256 glpRewards = glpRewardTracker.claim(msg.sender);

        IERC20(weth).transfer(msg.sender, glpRewards);

        emit ClaimRewards(msg.sender, 0, glpRewards, 0);

        return (0, glpRewards, 0);
    }

    /**
     * @notice User Compound GLP rewards
     * @param _shares Amount of glp shares to compound
     * @param _minGlpOut Min amount of Glp to be minted.
     * @return Amount of jGLP shares
     */
    function compoundGlpRewards(uint256 _shares, uint256 _minGlpOut) public returns (uint256) {
        glpCompoundRewards.compound();
        // claim rewards & mint GLP

        IJonesGlpLeverageStrategy _strategy = strategy;

        _strategy.claimGlpRewards();
        uint256 rewards = glpRewardTracker.claim(msg.sender); // WETH

        uint256 rewardShares;
        if (rewards != 0) {
            IERC20(weth).approve(router.glpManager(), rewards);
            uint256 glpAmount = router.mintAndStakeGlp(weth, rewards, 0, _minGlpOut);

            // vault deposit GLP to get jGLP
            glp.approve(address(glpVault), glpAmount);
            rewardShares = glpVault.deposit(glpAmount, address(this));
            _strategy.onGlpCompound(glpAmount);
        }

        // withdraw jGlp
        uint256 currentShares = glpRewardTracker.withdraw(msg.sender, _shares);

        // Stake in Rewards Tracker & Deposit into compounder
        IJonesGlpCompoundRewards compounder = glpCompoundRewards;
        uint256 totalShares = currentShares + rewardShares;
        IERC20(address(glpVault)).approve(address(compounder), totalShares);
        uint256 shares = compounder.deposit(totalShares, msg.sender);

        emit CompoundGlp(msg.sender, totalShares);

        return shares;
    }

    /**
     * @notice User UnCompound GLP rewards
     * @param _shares Amount of glp shares to uncompound
     * @return Amount of GLP shares
     */
    function unCompoundGlpRewards(uint256 _shares, address _user) public returns (uint256) {
        glpCompoundRewards.compound();
        return _unCompoundGlp(_shares, _user);
    }

    // ============================= External functions ================================ //

    /**
     * @notice Return max amount of glp in deposit that can be leveraged by the stable vault.
     */
    function getMaxCapGlp() public view returns (uint256) {
        uint256 stablesInVault = stableVault.underlying().balanceOf(address(stableVault));

        uint256 simulatedGlp = strategy.buyGlpStableSimulation(stablesInVault);

        return simulatedGlp.mulDivDown(BASIS_POINTS, strategy.getTargetLeverage() - BASIS_POINTS); // 18 decimals
    }

    // ============================= Governor functions ================================ //

    /**
     * @notice Set Leverage Strategy Contract
     * @param _leverageStrategy Leverage Strategy address
     */
    function setLeverageStrategy(address _leverageStrategy) external onlyGovernor {
        strategy = IJonesGlpLeverageStrategy(_leverageStrategy);
    }

    /**
     * @notice Set GLP Compound Contract
     * @param _glpCompoundRewards GLP Compound address
     */
    function setGlpCompoundRewards(address _glpCompoundRewards) external onlyGovernor {
        glpCompoundRewards = IJonesGlpCompoundRewards(_glpCompoundRewards);
    }

    /**
     * @notice Set GLP Tracker Contract
     * @param _glpRewardTracker GLP Tracker address
     */
    function setGlpRewardTracker(address _glpRewardTracker) external onlyGovernor {
        glpRewardTracker = IJonesGlpRewardTracker(_glpRewardTracker);
    }

    /**
     * @notice Set a new incentive Receiver address
     * @param _newIncentiveReceiver Incentive Receiver Address
     */
    function setIncentiveReceiver(address _newIncentiveReceiver) external onlyGovernor {
        incentiveReceiver = IIncentiveReceiver(_newIncentiveReceiver);
    }

    /**
     * @notice Set GLP Adapter Contract
     * @param _adapter GLP Adapter address
     */
    function setGlpAdapter(address _adapter) external onlyGovernor {
        adapter = GlpAdapter(_adapter);
    }

    // ============================= Private functions ================================ //

    function _deposit(IERC4626 _vault, address _caller, uint256 _assets, bool compound)
        private
        returns (uint256, uint256)
    {
        IERC20 asset = IERC20(_vault.asset());
        address adapterAddress = address(adapter);

        if (msg.sender == adapterAddress) {
            asset.transferFrom(adapterAddress, address(this), _assets);
        } else {
            asset.transferFrom(_caller, address(this), _assets);
        }

        uint256 vaultShares = _vaultDeposit(_vault, _assets);

        uint256 compoundShares;

        if (compound) {
            IJonesGlpCompoundRewards compounder = glpCompoundRewards;
            IERC20(address(_vault)).approve(address(compounder), vaultShares);
            compoundShares = compounder.deposit(vaultShares, _caller);
        } else {
            IJonesGlpRewardTracker tracker = glpRewardTracker;
            IERC20(address(_vault)).approve(address(tracker), vaultShares);
            tracker.stake(_caller, vaultShares);
        }

        return (compoundShares, vaultShares);
    }

    function _distributeGlp(uint256 _amount, address _dest, bool _compound) private returns (uint256) {
        uint256 retention = _chargeIncentive(_amount, _dest);
        uint256 wethAmount;

        if (retention > 0) {
            wethAmount = router.unstakeAndRedeemGlp(weth, retention, 0, address(this));
            uint256 jonesRetention = (wethAmount * 2) / 3;
            IERC20(weth).approve(address(incentiveReceiver), jonesRetention);
            incentiveReceiver.deposit(weth, jonesRetention);
            IERC20(weth).approve(address(glpRewardTracker), wethAmount - jonesRetention);

            glpRewardTracker.depositRewards(wethAmount - jonesRetention);
        }

        uint256 glpAfterRetention = _amount - retention;

        glp.transfer(_dest, glpAfterRetention);

        // Information needed to calculate glp retention
        emit RedeemGlp(_dest, glpAfterRetention, retention, wethAmount, address(0), 0, _compound);

        return glpAfterRetention;
    }

    function _distributeGlpAdapter(uint256 _amount, address _dest, address _token, bool _native, bool _compound)
        private
        returns (uint256)
    {
        uint256 retention = _chargeIncentive(_amount, _dest);

        uint256 wethAmount;

        if (retention > 0) {
            wethAmount = router.unstakeAndRedeemGlp(weth, retention, 0, address(this));
            uint256 jonesRetention = (wethAmount * 2) / 3;
            IERC20(weth).approve(address(incentiveReceiver), jonesRetention);
            incentiveReceiver.deposit(weth, jonesRetention);
            IERC20(weth).approve(address(glpRewardTracker), wethAmount - jonesRetention);

            glpRewardTracker.depositRewards(wethAmount - jonesRetention);
        }

        if (_native) {
            uint256 ethAmount = router.unstakeAndRedeemGlpETH(_amount - retention, 0, payable(_dest));

            // Information needed to calculate glp retention
            emit RedeemGlp(_dest, _amount - retention, retention, wethAmount, address(0), ethAmount, _compound);

            return ethAmount;
        }

        uint256 assetAmount = router.unstakeAndRedeemGlp(_token, _amount - retention, 0, _dest);

        // Information needed to calculate glp retention
        emit RedeemGlp(_dest, _amount - retention, retention, wethAmount, _token, 0, _compound);

        return assetAmount;
    }

    function _chargeIncentive(uint256 _withdrawAmount, address _sender) private view returns (uint256) {
        bytes32 userRole = whitelistController.getUserRole(_sender);
        IWhitelistController.RoleInfo memory info = whitelistController.getRoleInfo(userRole);

        return (_withdrawAmount * info.jGLP_RETENTION) / BASIS_POINTS;
    }

    function _unCompoundGlp(uint256 _shares, address _user) private returns (uint256) {
        if (msg.sender != address(adapter) && msg.sender != _user) {
            revert Errors.OnlyAuthorized();
        }

        uint256 shares = glpCompoundRewards.redeem(_shares, _user);

        emit unCompoundGlp(_user, _shares);

        return shares;
    }

    function _vaultDeposit(IERC4626 _vault, uint256 _assets) private returns (uint256) {
        address asset = _vault.asset();
        address vaultAddress = address(_vault);

        uint256 glpMintIncentives;

        if (strategy.leverageOnDeposit(_assets)) {
            glpMintIncentives = strategy.glpMintIncentive(_assets);
        }

        uint256 assetsToDeposit = _assets - glpMintIncentives;

        IERC20(asset).approve(vaultAddress, assetsToDeposit);

        uint256 vaultShares = _vault.deposit(assetsToDeposit, address(this));

        if (glpMintIncentives > 0) {
            glp.transfer(vaultAddress, glpMintIncentives);
        }

        emit VaultDeposit(vaultAddress, _assets, glpMintIncentives);

        return vaultShares;
    }

    function _onlyInternalContract() private view {
        if (!whitelistController.isInternalContract(msg.sender)) {
            revert Errors.CallerIsNotInternalContract();
        }
    }

    function _onlyEOA() private view {
        if (msg.sender != tx.origin && !whitelistController.isWhitelistedContract(msg.sender)) {
            revert Errors.CallerIsNotWhitelisted();
        }
    }

    function togglePause() external onlyGovernor {
        if (paused()) {
            _unpause();
            return;
        }

        _pause();
    }

    event DepositGlp(address indexed _to, uint256 _amount, uint256 _sharesReceived, bool _compound);
    event VaultDeposit(address indexed vault, uint256 _amount, uint256 _retention);
    event RedeemGlp(
        address indexed _to,
        uint256 _amount,
        uint256 _retentions,
        uint256 _ethRetentions,
        address _token,
        uint256 _ethAmount,
        bool _compound
    );
    event ClaimRewards(address indexed _to, uint256 _stableAmount, uint256 _wEthAmount, uint256 _amountJones);
    event CompoundGlp(address indexed _to, uint256 _amount);
    event unCompoundGlp(address indexed _to, uint256 _amount);
    event EmergencyWithdraw(address indexed _to, uint256 indexed _amount);
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 Jones DAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

pragma solidity ^0.8.10;

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {UpgradeableOperable} from "src/common/UpgradeableOperable.sol";

import {IJonesGlpRewardDistributor} from "src/interfaces/IJonesGlpRewardDistributor.sol";
import {IJonesGlpRewardsSplitter} from "src/interfaces/IJonesGlpRewardsSplitter.sol";
import {IIncentiveReceiver} from "src/interfaces/IIncentiveReceiver.sol";
import {IJonesGlpRewardTracker} from "src/interfaces/IJonesGlpRewardTracker.sol";
import {ITokenSwapper} from "src/interfaces/swap/ITokenSwapper.sol";
import {IUnderlyingVault} from "src/interfaces/jusdc/IUnderlyingVault.sol";

contract GlpRewardDistributor is IJonesGlpRewardDistributor, UpgradeableOperable {
    using FixedPointMathLib for uint256;

    /* -------------------------------------------------------------------------- */
    /*                                  VARIABLES                                 */
    /* -------------------------------------------------------------------------- */

    uint256 public constant BASIS_POINTS = 1e12;
    uint256 public constant PRECISION = 1e30;

    address public constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address public constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;

    IJonesGlpRewardsSplitter public splitter;
    ITokenSwapper public swapper;

    IIncentiveReceiver public incentiveReceiver;
    IUnderlyingVault public jUSDCVault;
    address public glpTracker;

    uint256 public slippage;

    mapping(address => uint256) public rewardPools;

    /* -------------------------------------------------------------------------- */
    /*                                 INITIALIZE                                 */
    /* -------------------------------------------------------------------------- */

    function initialize(
        address _swapper,
        address _jUSDC,
        address _splitter,
        address _incentiveReceiver,
        address _glpTracker
    ) external initializer {
        __Governable_init(msg.sender);

        if (address(_splitter) == address(0)) {
            revert AddressCannotBeZeroAddress();
        }
        swapper = ITokenSwapper(_swapper);
        jUSDCVault = IUnderlyingVault(_jUSDC);
        splitter = IJonesGlpRewardsSplitter(_splitter);
        incentiveReceiver = IIncentiveReceiver(_incentiveReceiver);
        glpTracker = _glpTracker;

        slippage = BASIS_POINTS.mulDivDown(970, 1000);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   OPERATOR                                 */
    /* -------------------------------------------------------------------------- */

    /**
     * @inheritdoc IJonesGlpRewardDistributor
     */
    function splitRewards(uint256 _amount, uint256 _leverage, uint256 _utilization) external onlyOperator {
        if (_amount == 0) {
            return;
        }
        IERC20(WETH).transferFrom(msg.sender, address(this), _amount);
        (uint256 glpRewards, uint256 stableRewards, uint256 jonesRewards) =
            splitter.splitRewards(_amount, _leverage, _utilization);

        if (jonesRewards > 0) {
            IERC20(WETH).approve(address(incentiveReceiver), jonesRewards);
            incentiveReceiver.deposit(WETH, jonesRewards);
        }

        address _glpTracker = glpTracker;

        rewardPools[_glpTracker] = rewardPools[_glpTracker] + glpRewards;

        if (stableRewards > 0) {
            ///@notice swap stable rewards WETH -> USDC
            IERC20(WETH).approve(address(swapper), stableRewards);
            stableRewards = swapper.swap(WETH, stableRewards, USDC, 0, abi.encode(slippage, BASIS_POINTS));

            ///@notice deposit stable rewards in jUSDC Reward Receiver
            IERC20(USDC).approve(address(jUSDCVault), stableRewards);
            jUSDCVault.receiveRewards(stableRewards);
        }

        // Information needed to calculate rewards per Vault
        emit SplitRewards(glpRewards, stableRewards, jonesRewards);
    }

    /**
     * @inheritdoc IJonesGlpRewardDistributor
     */
    function distributeRewards() external onlyOperator returns (uint256) {
        uint256 rewards = rewardPools[msg.sender];

        if (rewards == 0) {
            return 0;
        }
        rewardPools[msg.sender] = 0;
        IERC20(WETH).transfer(msg.sender, rewards);
        return rewards;
    }

    /* -------------------------------------------------------------------------- */
    /*                                    VIEW                                    */
    /* -------------------------------------------------------------------------- */

    /**
     * @inheritdoc IJonesGlpRewardDistributor
     */
    function pendingRewards(address _pool) external view returns (uint256) {
        return rewardPools[_pool];
    }

    /* -------------------------------------------------------------------------- */
    /*                                   GOVERNOR                                 */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Moves assets from the strategy to `_to`
     * @param _assets An array of IERC20 compatible tokens to move out from the strategy
     * @param _withdrawNative `true` if we want to move the native asset from the strategy
     */
    function emergencyWithdraw(address _to, address[] memory _assets, bool _withdrawNative) external onlyGovernor {
        uint256 assetsLength = _assets.length;
        for (uint256 i = 0; i < assetsLength; i++) {
            IERC20 asset_ = IERC20(_assets[i]);
            uint256 assetBalance = asset_.balanceOf(address(this));

            if (assetBalance > 0) {
                // Transfer the ERC20 tokens
                asset_.transfer(_to, assetBalance);
            }

            unchecked {
                ++i;
            }
        }

        uint256 nativeBalance = address(this).balance;

        // Nothing else to do
        if (_withdrawNative && nativeBalance > 0) {
            // Transfer the native currency
            (bool sent,) = payable(_to).call{value: nativeBalance}("");
            if (!sent) {
                revert FailSendETH();
            }
        }

        emit EmergencyWithdrawal(msg.sender, _to, _assets, _withdrawNative ? nativeBalance : 0);
    }

    /**
     * @notice update slippage
     * @param _slippage amount of slippage
     */
    function updateSlippage(uint256 _slippage) external onlyGovernor {
        slippage = _slippage;
    }

    /**
     * @notice update swapper contract
     * @param _swapper new swapper address
     */
    function updateSwapper(address _swapper) external onlyGovernor {
        swapper = ITokenSwapper(_swapper);
    }

    /**
     * @notice Set the beneficiaries address of the GMX rewards
     * @param _splitter Jones reward splitter address
     */
    function setSplitter(IJonesGlpRewardsSplitter _splitter) external onlyGovernor {
        if (address(_splitter) == address(0)) {
            revert AddressCannotBeZeroAddress();
        }
        splitter = _splitter;
    }

    /**
     * @notice Set the beneficiaries address of the GMX rewards
     * @param _incentiveReceiver incentive receiver address
     * @param _glpTracker GLP Reward Tracker address
     */
    function setBeneficiaries(IIncentiveReceiver _incentiveReceiver, address _glpTracker, address _stableReceiver)
        external
        onlyGovernor
    {
        if (address(_incentiveReceiver) == address(0)) {
            revert AddressCannotBeZeroAddress();
        }
        if (_glpTracker == address(0)) {
            revert AddressCannotBeZeroAddress();
        }
        if (_stableReceiver == address(0)) {
            revert AddressCannotBeZeroAddress();
        }

        incentiveReceiver = _incentiveReceiver;
        jUSDCVault = IUnderlyingVault(_stableReceiver);
        glpTracker = _glpTracker;
    }

    event EmergencyWithdrawal(address indexed caller, address indexed receiver, address[] tokens, uint256 nativeBalanc);

    error FailSendETH();
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 Jones DAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

pragma solidity ^0.8.10;

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {Governable} from "src/common/Governable.sol";
import {UniswapV3Swapper} from "src/glp/swappers/UniswapV3Swapper.sol";
import {OneInchV5Swapper} from "src/glp/swappers/OneInchV5Swapper.sol";
import {ITokenSwapper} from "src/interfaces/swap/ITokenSwapper.sol";

contract StableSwapper is Governable {
    using FixedPointMathLib for uint256;

    uint256 public constant BASIS_POINTS = 1e12;

    address public constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
    address public constant USDCE = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;

    ITokenSwapper public swapper;
    address public target;
    uint256 public slippage;

    constructor(address _swapper, address _target, address _gov) Governable(_gov) {
        swapper = ITokenSwapper(_swapper);
        target = _target;
        slippage = BASIS_POINTS.mulDivDown(995, 1000); //0.5% slippage
    }

    function swapAndSend(bytes memory externalData) external onlyGovernor returns (uint256) {
        uint256 amount = IERC20(USDCE).balanceOf(address(this));

        uint256 minAmountOut = amount.mulDivDown(slippage, BASIS_POINTS);

        IERC20(USDCE).approve(address(swapper), amount);
        uint256 amountOut = swapper.swap(USDCE, amount, USDC, minAmountOut, externalData);

        IERC20(USDC).transfer(target, amountOut);

        return amountOut;
    }

    function send(address owner, uint256 amount) external onlyGovernor {
        IERC20(USDC).transferFrom(owner, target, amount);
    }

    function updateSwapper(address _swapper) external onlyGovernor {
        swapper = ITokenSwapper(_swapper);
    }

    function updateTarget(address _target) external onlyGovernor {
        target = _target;
    }

    function updateSlippage(uint256 _slippage) external onlyGovernor {
        slippage = _slippage;
    }

    /**
     * @notice Moves assets from the strategy to `_to`
     * @param _assets An array of IERC20 compatible tokens to move out from the strategy
     * @param _withdrawNative `true` if we want to move the native asset from the strategy
     */
    function emergencyWithdraw(address _to, address[] memory _assets, bool _withdrawNative) external onlyGovernor {
        uint256 assetsLength = _assets.length;
        for (uint256 i = 0; i < assetsLength; i++) {
            IERC20 asset_ = IERC20(_assets[i]);
            uint256 assetBalance = asset_.balanceOf(address(this));

            if (assetBalance > 0) {
                // Transfer the ERC20 tokens
                asset_.transfer(_to, assetBalance);
            }

            unchecked {
                ++i;
            }
        }

        uint256 nativeBalance = address(this).balance;

        // Nothing else to do
        if (_withdrawNative && nativeBalance > 0) {
            // Transfer the native currency
            (bool sent,) = payable(_to).call{value: nativeBalance}("");
            if (!sent) {
                revert FailSendETH();
            }
        }

        emit EmergencyWithdrawal(msg.sender, _to, _assets, _withdrawNative ? nativeBalance : 0);
    }

    event EmergencyWithdrawal(address indexed caller, address indexed receiver, address[] tokens, uint256 nativeBalanc);

    error FailSendETH();
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 Jones DAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

pragma solidity ^0.8.10;

import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {Operable} from "../../common/Operable.sol";
import {Governable} from "../../common/Operable.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IJonesGlpRewardDistributor} from "../../interfaces/IJonesGlpRewardDistributor.sol";
import {IJonesGlpRewardsSplitter} from "../../interfaces/IJonesGlpRewardsSplitter.sol";
import {IIncentiveReceiver} from "../../interfaces/IIncentiveReceiver.sol";
import {IJonesGlpRewardTracker} from "../../interfaces/IJonesGlpRewardTracker.sol";

contract JonesGlpRewardDistributor is IJonesGlpRewardDistributor, Operable, ReentrancyGuard {
    uint256 public constant BASIS_POINTS = 1e12;
    uint256 public constant PRECISION = 1e30;

    address public constant weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    IJonesGlpRewardsSplitter public splitter;
    IIncentiveReceiver public incentiveReceiver;

    address public stableTracker;
    address public glpTracker;

    uint256 public jonesPercentage;
    uint256 public stablePercentage;

    mapping(address => uint256) public rewardPools;

    constructor(IJonesGlpRewardsSplitter _splitter) Governable(msg.sender) ReentrancyGuard() {
        if (address(_splitter) == address(0)) {
            revert AddressCannotBeZeroAddress();
        }
        splitter = _splitter;
    }

    // ============================= Operator functions ================================ //

    /**
     * @inheritdoc IJonesGlpRewardDistributor
     */
    function splitRewards(uint256 _amount, uint256 _leverage, uint256 _utilization)
        external
        nonReentrant
        onlyOperator
    {
        if (_amount == 0) {
            return;
        }
        IERC20(weth).transferFrom(msg.sender, address(this), _amount);
        (uint256 glpRewards, uint256 stableRewards, uint256 jonesRewards) =
            splitter.splitRewards(_amount, _leverage, _utilization);

        IERC20(weth).approve(address(incentiveReceiver), jonesRewards);
        incentiveReceiver.deposit(weth, jonesRewards);
        address _stableTracker = stableTracker;
        address _glpTracker = glpTracker;
        rewardPools[_stableTracker] = rewardPools[_stableTracker] + stableRewards;
        rewardPools[_glpTracker] = rewardPools[_glpTracker] + glpRewards;

        // Information needed to calculate rewards per Vault
        emit SplitRewards(glpRewards, stableRewards, jonesRewards);
    }

    /**
     * @inheritdoc IJonesGlpRewardDistributor
     */
    function distributeRewards() external nonReentrant onlyOperator returns (uint256) {
        uint256 rewards = rewardPools[msg.sender];
        if (rewards == 0) {
            return 0;
        }
        rewardPools[msg.sender] = 0;
        IERC20(weth).transfer(msg.sender, rewards);
        return rewards;
    }

    // ============================= External functions ================================ //

    /**
     * @inheritdoc IJonesGlpRewardDistributor
     */
    function pendingRewards(address _pool) external view returns (uint256) {
        return rewardPools[_pool];
    }

    // ============================= Governor functions ================================ //

    /**
     * @notice Set the beneficiaries address of the GMX rewards
     * @param _splitter Jones reward splitter address
     */
    function setSplitter(IJonesGlpRewardsSplitter _splitter) external onlyGovernor {
        if (address(_splitter) == address(0)) {
            revert AddressCannotBeZeroAddress();
        }
        splitter = _splitter;
    }

    /**
     * @notice Set the beneficiaries address of the GMX rewards
     * @param _incentiveReceiver incentive receiver address
     * @param _stableTracker Stable Reward Tracker address
     * @param _glpTracker GLP Reward Tracker address
     */
    function setBeneficiaries(IIncentiveReceiver _incentiveReceiver, address _stableTracker, address _glpTracker)
        external
        onlyGovernor
    {
        if (address(_incentiveReceiver) == address(0)) {
            revert AddressCannotBeZeroAddress();
        }
        if (_stableTracker == address(0)) {
            revert AddressCannotBeZeroAddress();
        }
        if (_glpTracker == address(0)) {
            revert AddressCannotBeZeroAddress();
        }

        incentiveReceiver = _incentiveReceiver;
        stableTracker = _stableTracker;
        glpTracker = _glpTracker;
    }
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 Jones DAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

pragma solidity ^0.8.10;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";
import {Pausable} from "../common/Pausable.sol";
import {WhitelistController} from "../common/WhitelistController.sol";
import {JonesGlpVault} from "./vaults/JonesGlpVault.sol";
import {JonesGlpStableVault} from "./vaults/JonesGlpStableVault.sol";
import {Governable} from "../common/Governable.sol";
import {GlpJonesRewards} from "./rewards/GlpJonesRewards.sol";
import {IGmxRewardRouter} from "../interfaces/IGmxRewardRouter.sol";
import {IWhitelistController} from "../interfaces/IWhitelistController.sol";
import {IJonesGlpLeverageStrategy} from "../interfaces/IJonesGlpLeverageStrategy.sol";
import {IIncentiveReceiver} from "../interfaces/IIncentiveReceiver.sol";
import {IJonesGlpRewardTracker} from "../interfaces/IJonesGlpRewardTracker.sol";
import {GlpAdapter} from "../adapters/GlpAdapter.sol";
import {IJonesGlpCompoundRewards} from "../interfaces/IJonesGlpCompoundRewards.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {Errors} from "src/interfaces/Errors.sol";

contract JonesGlpVaultRouter is Governable, Pausable, ReentrancyGuard {
    bool public initialized;

    struct WithdrawalSignal {
        uint256 targetEpoch;
        uint256 commitedShares;
        bool redeemed;
        bool compound;
    }

    IGmxRewardRouter private constant router = IGmxRewardRouter(0xB95DB5B167D75e6d04227CfFFA61069348d271F5);
    address private constant weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    JonesGlpVault private glpVault;
    JonesGlpStableVault private glpStableVault;
    IJonesGlpLeverageStrategy public strategy;
    GlpJonesRewards private jonesRewards;
    IJonesGlpRewardTracker public glpRewardTracker;
    IJonesGlpRewardTracker public stableRewardTracker;
    IJonesGlpCompoundRewards private stableCompoundRewards;
    IJonesGlpCompoundRewards private glpCompoundRewards;
    IWhitelistController private whitelistController;
    IIncentiveReceiver private incentiveReceiver;
    GlpAdapter private adapter;

    IERC20 private glp;
    IERC20 private stable;

    // vault asset -> reward tracker
    mapping(address => IJonesGlpRewardTracker) public rewardTrackers;
    // vault asset -> reward compounder
    mapping(address => IJonesGlpCompoundRewards) public rewardCompounder;

    mapping(address => mapping(uint256 => WithdrawalSignal)) private userSignal;

    uint256 private constant BASIS_POINTS = 1e12;
    uint256 private constant EPOCH_DURATION = 1 days;
    uint256 public EXIT_COOLDOWN;

    constructor(
        JonesGlpVault _glpVault,
        JonesGlpStableVault _glpStableVault,
        IJonesGlpLeverageStrategy _strategy,
        GlpJonesRewards _jonesRewards,
        IJonesGlpRewardTracker _glpRewardTracker,
        IJonesGlpRewardTracker _stableRewardTracker,
        IJonesGlpCompoundRewards _glpCompoundRewards,
        IJonesGlpCompoundRewards _stableCompoundRewards,
        IWhitelistController _whitelistController,
        IIncentiveReceiver _incentiveReceiver
    ) Governable(msg.sender) {
        glpVault = _glpVault;
        glpStableVault = _glpStableVault;
        strategy = _strategy;
        jonesRewards = _jonesRewards;
        glpRewardTracker = _glpRewardTracker;
        stableRewardTracker = _stableRewardTracker;
        glpCompoundRewards = _glpCompoundRewards;
        stableCompoundRewards = _stableCompoundRewards;
        whitelistController = _whitelistController;

        incentiveReceiver = _incentiveReceiver;
    }

    function initialize(address _glp, address _stable, address _adapter) external onlyGovernor {
        if (initialized) {
            revert Errors.AlreadyInitialized();
        }

        rewardTrackers[_glp] = glpRewardTracker;
        rewardTrackers[_stable] = stableRewardTracker;
        rewardCompounder[_glp] = glpCompoundRewards;
        rewardCompounder[_stable] = stableCompoundRewards;

        glp = IERC20(_glp);
        stable = IERC20(_stable);
        adapter = GlpAdapter(_adapter);

        initialized = true;
    }

    // ============================= Whitelisted functions ================================ //

    /**
     * @notice The Adapter contract can deposit GLP to the system on behalf of the _sender
     * @param _assets Amount of assets deposited
     * @param _sender address of who is deposit the assets
     * @param _compound optional compounding rewards
     * @return Amount of shares jGLP minted
     */
    function depositGlp(uint256 _assets, address _sender, bool _compound) external whenNotPaused returns (uint256) {
        _onlyInternalContract(); //can only be adapter or compounder

        bytes32 role = whitelistController.getUserRole(_sender);
        IWhitelistController.RoleInfo memory info = whitelistController.getRoleInfo(role);

        IJonesGlpLeverageStrategy _strategy = strategy;
        JonesGlpVault _glpVault = glpVault;

        uint256 assetsUsdValue = _strategy.getStableGlpValue(_assets);
        uint256 underlyingUsdValue = _strategy.getStableGlpValue(_strategy.getUnderlyingGlp());
        uint256 maxTvlGlp = getMaxCapGlp();

        if ((assetsUsdValue + underlyingUsdValue) * BASIS_POINTS > maxTvlGlp && !info.jGLP_BYPASS_CAP) {
            revert Errors.MaxGlpTvlReached();
        }

        if (_compound) {
            glpCompoundRewards.compound();
        }

        (uint256 compoundShares, uint256 vaultShares) = _deposit(_glpVault, _sender, _assets, _compound);

        _strategy.onGlpDeposit(_assets);

        if (_compound) {
            emit DepositGlp(_sender, _assets, compoundShares, _compound);
            return compoundShares;
        }

        emit DepositGlp(_sender, _assets, vaultShares, _compound);

        return vaultShares;
    }

    /**
     * @notice Users & Whitelist contract can redeem GLP from the system
     * @param _shares Amount of jGLP deposited to redeem GLP
     * @param _compound flag if the rewards are compounding
     * @return Amount of GLP remdeemed
     */
    function redeemGlp(uint256 _shares, bool _compound)
        external
        whenNotEmergencyPaused
        nonReentrant
        returns (uint256)
    {
        _onlyEOA();

        if (_compound) {
            glpCompoundRewards.compound();
            _shares = _unCompoundGlp(_shares, msg.sender);
        }

        glpRewardTracker.withdraw(msg.sender, _shares);
        JonesGlpVault _glpVault = glpVault;

        uint256 glpAmount = _glpVault.previewRedeem(_shares);

        _glpVault.burn(address(this), _shares);

        //We can't send glpAmount - retention here because it'd mess our rebalance
        glpAmount = strategy.onGlpRedeem(glpAmount);

        if (glpAmount > 0) {
            glpAmount = _distributeGlp(glpAmount, msg.sender, _compound);
        }

        return glpAmount;
    }

    /**
     * @notice User & Whitelist contract can redeem GLP using any asset of GLP basket from the system
     * @param _shares Amount of jGLP deposited to redeem GLP
     * @param _compound flag if the rewards are compounding
     * @param _token address of asset token
     * @param _user address of the user that will receive the assets
     * @param _native flag if the user will receive raw ETH
     * @return Amount of assets redeemed
     */
    function redeemGlpAdapter(uint256 _shares, bool _compound, address _token, address _user, bool _native)
        external
        whenNotEmergencyPaused
        nonReentrant
        returns (uint256)
    {
        if (msg.sender != address(adapter)) {
            revert Errors.OnlyAdapter();
        }

        if (_compound) {
            glpCompoundRewards.compound();
            _shares = _unCompoundGlp(_shares, _user);
        }
        glpRewardTracker.withdraw(_user, _shares);
        JonesGlpVault _glpVault = glpVault;

        uint256 glpAmount = _glpVault.previewRedeem(_shares);

        _glpVault.burn(address(this), _shares);

        //We can't send glpAmount - retention here because it'd mess our rebalance
        glpAmount = strategy.onGlpRedeem(glpAmount);

        if (glpAmount > 0) {
            glpAmount = _distributeGlpAdapter(glpAmount, _user, _token, _native, _compound);
        }

        return glpAmount;
    }

    /**
     * @notice adapter & compounder can deposit Stable assets to the system
     * @param _assets Amount of Stables deposited
     * @param _compound optional compounding rewards
     * @return Amount of shares jUSDC minted
     */
    function depositStable(uint256 _assets, bool _compound, address _user) external whenNotPaused returns (uint256) {
        _onlyInternalContract(); //can only be adapter or compounder

        if (_compound) {
            stableCompoundRewards.compound();
        }

        (uint256 shares, uint256 track) = _deposit(glpStableVault, _user, _assets, _compound);

        if (_user != address(rewardCompounder[address(stable)])) {
            jonesRewards.stake(_user, track);
        }

        //strategy.onStableDeposit();

        emit DepositStables(_user, _assets, shares, _compound);

        return shares;
    }

    /**
     * @notice Users can signal a stable redeem or redeem directly if user has the role to do it.
     * @dev The Jones & Stable rewards stop here
     * @param _shares Amount of shares jUSDC to redeem
     * @param _compound flag if the rewards are compounding
     * @return Epoch when will be possible the redeem or the amount of stables received in case user has special role
     */
    function stableWithdrawalSignal(uint256 _shares, bool _compound)
        external
        whenNotEmergencyPaused
        returns (uint256)
    {
        _onlyEOA();

        bytes32 userRole = whitelistController.getUserRole(msg.sender);
        IWhitelistController.RoleInfo memory info = whitelistController.getRoleInfo(userRole);

        uint256 targetEpoch = currentEpoch() + EXIT_COOLDOWN;
        WithdrawalSignal memory userWithdrawalSignal = userSignal[msg.sender][targetEpoch];

        if (userWithdrawalSignal.commitedShares > 0) {
            revert Errors.WithdrawalSignalAlreadyDone();
        }

        if (_compound) {
            stableCompoundRewards.compound();
            uint256 assets = stableCompoundRewards.previewRedeem(_shares);
            uint256 assetDeposited = stableCompoundRewards.totalAssetsToDeposits(msg.sender, assets);
            jonesRewards.getReward(msg.sender);
            jonesRewards.withdraw(msg.sender, assetDeposited);
            _shares = _unCompoundStables(_shares);
        } else {
            jonesRewards.getReward(msg.sender);
            jonesRewards.withdraw(msg.sender, _shares);
        }

        rewardTrackers[address(stable)].withdraw(msg.sender, _shares);

        if (info.jUSDC_BYPASS_TIME) {
            return _redeemDirectly(_shares, info.jUSDC_RETENTION, _compound);
        }

        userSignal[msg.sender][targetEpoch] = WithdrawalSignal(targetEpoch, _shares, false, _compound);

        emit StableWithdrawalSignal(msg.sender, _shares, targetEpoch, _compound);

        return targetEpoch;
    }

    function _redeemDirectly(uint256 _shares, uint256 _retention, bool _compound) private returns (uint256) {
        uint256 stableAmount = glpStableVault.previewRedeem(_shares);
        uint256 stablesFromVault = _borrowStables(stableAmount);
        uint256 gmxIncentive;

        IJonesGlpLeverageStrategy _strategy = strategy;

        // Only redeem from strategy if there is not enough on the vault
        if (stablesFromVault < stableAmount) {
            uint256 difference = stableAmount - stablesFromVault;
            gmxIncentive = (difference * _strategy.getRedeemStableGMXIncentive(difference) * 1e8) / BASIS_POINTS;
            _strategy.onStableRedeem(difference, difference - gmxIncentive);
        }

        uint256 remainderStables = stableAmount - gmxIncentive;

        IERC20 stableToken = stable;

        if (stableToken.balanceOf(address(this)) < remainderStables) {
            revert Errors.NotEnoughStables();
        }

        glpStableVault.burn(address(this), _shares);

        uint256 retention = ((stableAmount * _retention) / BASIS_POINTS);

        uint256 realRetention = gmxIncentive < retention ? retention - gmxIncentive : 0;

        uint256 amountAfterRetention = remainderStables - realRetention;

        if (amountAfterRetention > 0) {
            stableToken.transfer(msg.sender, amountAfterRetention);
        }

        if (realRetention > 0) {
            stableToken.approve(address(stableRewardTracker), realRetention);
            stableRewardTracker.depositRewards(realRetention);
        }

        // Information needed to calculate stable retentions
        emit RedeemStable(msg.sender, amountAfterRetention, retention, realRetention, _compound);

        return amountAfterRetention;
    }

    /**
     * @notice Users can cancel the signal to stable redeem
     * @param _epoch Target epoch
     * @param _compound true if the rewards should be compound
     */
    function cancelStableWithdrawalSignal(uint256 _epoch, bool _compound) external {
        WithdrawalSignal memory userWithdrawalSignal = userSignal[msg.sender][_epoch];

        if (userWithdrawalSignal.redeemed) {
            revert Errors.WithdrawalAlreadyCompleted();
        }

        uint256 snapshotCommitedShares = userWithdrawalSignal.commitedShares;

        if (snapshotCommitedShares == 0) {
            return;
        }

        userWithdrawalSignal.commitedShares = 0;
        userWithdrawalSignal.targetEpoch = 0;
        userWithdrawalSignal.compound = false;

        IJonesGlpRewardTracker tracker = stableRewardTracker;

        jonesRewards.stake(msg.sender, snapshotCommitedShares);

        if (_compound) {
            stableCompoundRewards.compound();
            IJonesGlpCompoundRewards compounder = rewardCompounder[address(stable)];
            IERC20(address(glpStableVault)).approve(address(compounder), snapshotCommitedShares);
            compounder.deposit(snapshotCommitedShares, msg.sender);
        } else {
            IERC20(address(glpStableVault)).approve(address(tracker), snapshotCommitedShares);
            tracker.stake(msg.sender, snapshotCommitedShares);
        }

        // Update struct storage
        userSignal[msg.sender][_epoch] = userWithdrawalSignal;

        emit CancelStableWithdrawalSignal(msg.sender, snapshotCommitedShares, _compound);
    }

    /**
     * @notice Users can redeem stable assets from the system
     * @param _epoch Target epoch
     * @return Amount of stables reeemed
     */
    function redeemStable(uint256 _epoch) external whenNotEmergencyPaused returns (uint256) {
        bytes32 userRole = whitelistController.getUserRole(msg.sender);
        IWhitelistController.RoleInfo memory info = whitelistController.getRoleInfo(userRole);

        WithdrawalSignal memory userWithdrawalSignal = userSignal[msg.sender][_epoch];

        if (currentEpoch() < userWithdrawalSignal.targetEpoch || userWithdrawalSignal.targetEpoch == 0) {
            revert Errors.NotRightEpoch();
        }

        if (userWithdrawalSignal.redeemed) {
            revert Errors.WithdrawalAlreadyCompleted();
        }

        if (userWithdrawalSignal.commitedShares == 0) {
            revert Errors.WithdrawalWithNoShares();
        }

        uint256 stableAmount = glpStableVault.previewRedeem(userWithdrawalSignal.commitedShares);

        uint256 stablesFromVault = _borrowStables(stableAmount);

        uint256 gmxIncentive;

        IJonesGlpLeverageStrategy _strategy = strategy;

        // Only redeem from strategy if there is not enough on the vault
        if (stablesFromVault < stableAmount) {
            uint256 difference = stableAmount - stablesFromVault;
            gmxIncentive = (difference * _strategy.getRedeemStableGMXIncentive(difference) * 1e8) / BASIS_POINTS;
            _strategy.onStableRedeem(difference, difference - gmxIncentive);
        }

        uint256 remainderStables = stableAmount - gmxIncentive;

        IERC20 stableToken = stable;

        if (stableToken.balanceOf(address(this)) < remainderStables) {
            revert Errors.NotEnoughStables();
        }

        glpStableVault.burn(address(this), userWithdrawalSignal.commitedShares);

        userSignal[msg.sender][_epoch] = WithdrawalSignal(
            userWithdrawalSignal.targetEpoch, userWithdrawalSignal.commitedShares, true, userWithdrawalSignal.compound
        );

        uint256 retention = ((stableAmount * info.jUSDC_RETENTION) / BASIS_POINTS);

        uint256 realRetention = gmxIncentive < retention ? retention - gmxIncentive : 0;

        uint256 amountAfterRetention = remainderStables - realRetention;

        if (amountAfterRetention > 0) {
            stableToken.transfer(msg.sender, amountAfterRetention);
        }

        if (realRetention > 0) {
            stableToken.approve(address(stableRewardTracker), realRetention);
            stableRewardTracker.depositRewards(realRetention);
        }

        // Information needed to calculate stable retention
        emit RedeemStable(msg.sender, amountAfterRetention, retention, realRetention, userWithdrawalSignal.compound);

        return amountAfterRetention;
    }

    /**
     * @notice User & Whitelist contract can claim their rewards
     * @return Stable rewards comming from Stable deposits
     * @return ETH rewards comming from GLP deposits
     * @return Jones rewards comming from jones emission
     */
    function claimRewards() external returns (uint256, uint256, uint256) {
        strategy.claimGlpRewards();

        uint256 stableRewards = stableRewardTracker.claim(msg.sender);

        stable.transfer(msg.sender, stableRewards);

        uint256 glpRewards = glpRewardTracker.claim(msg.sender);

        IERC20(weth).transfer(msg.sender, glpRewards);

        uint256 _jonesRewards = jonesRewards.getReward(msg.sender);

        emit ClaimRewards(msg.sender, stableRewards, glpRewards, _jonesRewards);

        return (stableRewards, glpRewards, _jonesRewards);
    }

    /**
     * @notice User Compound rewards
     * @param _stableDeposits Amount of stable shares to compound
     * @param _glpDeposits Amount of glp shares to compound
     * @return Amount of USDC shares
     * @return Amount of GLP shares
     */
    function compoundRewards(uint256 _stableDeposits, uint256 _glpDeposits) external returns (uint256, uint256) {
        return (compoundStableRewards(_stableDeposits), compoundGlpRewards(_glpDeposits));
    }

    /**
     * @notice User UnCompound rewards
     * @param _stableDeposits Amount of stable shares to uncompound
     * @param _glpDeposits Amount of glp shares to uncompound
     * @return Amount of USDC shares
     * @return Amount of GLP shares
     */
    function unCompoundRewards(uint256 _stableDeposits, uint256 _glpDeposits, address _user)
        external
        returns (uint256, uint256)
    {
        return (unCompoundStableRewards(_stableDeposits), unCompoundGlpRewards(_glpDeposits, _user));
    }

    /**
     * @notice User Compound GLP rewards
     * @param _shares Amount of glp shares to compound
     * @return Amount of jGLP shares
     */
    function compoundGlpRewards(uint256 _shares) public returns (uint256) {
        glpCompoundRewards.compound();
        // claim rewards & mint GLP

        IJonesGlpLeverageStrategy _strategy = strategy;

        _strategy.claimGlpRewards();
        uint256 rewards = glpRewardTracker.claim(msg.sender); // WETH

        uint256 rewardShares;
        if (rewards != 0) {
            IERC20(weth).approve(router.glpManager(), rewards);
            uint256 glpAmount = router.mintAndStakeGlp(weth, rewards, 0, 0);

            // vault deposit GLP to get jGLP
            glp.approve(address(glpVault), glpAmount);
            rewardShares = glpVault.deposit(glpAmount, address(this));
        }

        // withdraw jGlp
        uint256 currentShares = glpRewardTracker.withdraw(msg.sender, _shares);

        // Stake in Rewards Tracker & Deposit into compounder
        IJonesGlpCompoundRewards compounder = rewardCompounder[address(glp)];
        uint256 totalShares = currentShares + rewardShares;
        IERC20(address(glpVault)).approve(address(compounder), totalShares);
        uint256 shares = compounder.deposit(totalShares, msg.sender);

        emit CompoundGlp(msg.sender, totalShares);

        return shares;
    }

    /**
     * @notice User UnCompound GLP rewards
     * @param _shares Amount of glp shares to uncompound
     * @return Amount of GLP shares
     */
    function unCompoundGlpRewards(uint256 _shares, address _user) public returns (uint256) {
        glpCompoundRewards.compound();
        return _unCompoundGlp(_shares, _user);
    }

    /**
     * @notice User Compound Stable rewards
     * @param _shares Amount of stable shares to compound
     * @return Amount of jUSDC shares
     */
    function compoundStableRewards(uint256 _shares) public returns (uint256) {
        stableCompoundRewards.compound();
        // claim rewards & deposit USDC
        strategy.claimGlpRewards();
        uint256 rewards = stableRewardTracker.claim(msg.sender); // USDC

        // vault deposit USDC to get jUSDC
        uint256 rewardShares;
        if (rewards > 0) {
            stable.approve(address(glpStableVault), rewards);
            rewardShares = glpStableVault.deposit(rewards, address(this));
        }

        // withdraw jUSDC
        uint256 currentShares = stableRewardTracker.withdraw(msg.sender, _shares);

        // Stake in Rewards Tracker & Deposit into compounder
        IJonesGlpCompoundRewards compounder = rewardCompounder[address(stable)];
        uint256 totalShares = currentShares + rewardShares;
        IERC20(address(glpStableVault)).approve(address(compounder), totalShares);
        uint256 shares = compounder.deposit(totalShares, msg.sender);

        emit CompoundStables(msg.sender, totalShares);

        return shares;
    }

    /**
     * @notice User UnCompound rewards
     * @param _shares Amount of stable shares to uncompound
     * @return Amount of USDC shares
     */
    function unCompoundStableRewards(uint256 _shares) public returns (uint256) {
        stableCompoundRewards.compound();
        IJonesGlpCompoundRewards compounder = rewardCompounder[address(stable)];

        uint256 assets = compounder.previewRedeem(_shares);
        uint256 assetsDeposited = compounder.totalAssetsToDeposits(msg.sender, assets);

        uint256 difference = assets - assetsDeposited;
        if (difference > 0) {
            jonesRewards.stake(msg.sender, difference);
        }

        return _unCompoundStables(_shares);
    }

    // ============================= External functions ================================ //
    /**
     * @notice Return user withdrawal signal
     * @param user address of user
     * @param epoch address of user
     * @return Targe Epoch
     * @return Commited shares
     * @return Redeem boolean
     */
    function withdrawSignal(address user, uint256 epoch) external view returns (uint256, uint256, bool, bool) {
        WithdrawalSignal memory userWithdrawalSignal = userSignal[user][epoch];
        return (
            userWithdrawalSignal.targetEpoch,
            userWithdrawalSignal.commitedShares,
            userWithdrawalSignal.redeemed,
            userWithdrawalSignal.compound
        );
    }

    /**
     * @notice Return the max amount of GLP that can be deposit in order to be alaign with the target leverage
     * @return GLP Cap
     */
    function getMaxCapGlp() public view returns (uint256) {
        return (glpStableVault.tvl() * BASIS_POINTS) / (strategy.getTargetLeverage() - BASIS_POINTS); // 18 decimals
    }

    function currentEpoch() public view returns (uint256) {
        return (block.timestamp / EPOCH_DURATION) * EPOCH_DURATION;
    }

    // ============================= Governor functions ================================ //
    /**
     * @notice Set exit cooldown length in days
     * @param _days amount of days a user needs to wait to withdraw his stables
     */
    function setExitCooldown(uint256 _days) external onlyGovernor {
        EXIT_COOLDOWN = _days * EPOCH_DURATION;
    }

    /**
     * @notice Set Jones Rewards Contract
     * @param _jonesRewards Contract that manage Jones Rewards
     */
    function setJonesRewards(GlpJonesRewards _jonesRewards) external onlyGovernor {
        jonesRewards = _jonesRewards;
    }

    /**
     * @notice Set Leverage Strategy Contract
     * @param _leverageStrategy Leverage Strategy address
     */
    function setLeverageStrategy(address _leverageStrategy) external onlyGovernor {
        strategy = IJonesGlpLeverageStrategy(_leverageStrategy);
    }

    /**
     * @notice Set Stable Compound Contract
     * @param _stableCompoundRewards Stable Compound address
     */
    function setStableCompoundRewards(address _stableCompoundRewards) external onlyGovernor {
        stableCompoundRewards = IJonesGlpCompoundRewards(_stableCompoundRewards);
        rewardCompounder[address(stable)] = stableCompoundRewards;
    }

    /**
     * @notice Set GLP Compound Contract
     * @param _glpCompoundRewards GLP Compound address
     */
    function setGlpCompoundRewards(address _glpCompoundRewards) external onlyGovernor {
        glpCompoundRewards = IJonesGlpCompoundRewards(_glpCompoundRewards);
        rewardCompounder[address(glp)] = glpCompoundRewards;
    }

    /**
     * @notice Set Stable Tracker Contract
     * @param _stableRewardTracker Stable Tracker address
     */
    function setStableRewardTracker(address _stableRewardTracker) external onlyGovernor {
        stableRewardTracker = IJonesGlpRewardTracker(_stableRewardTracker);
        rewardTrackers[address(stable)] = stableRewardTracker;
    }

    /**
     * @notice Set GLP Tracker Contract
     * @param _glpRewardTracker GLP Tracker address
     */
    function setGlpRewardTracker(address _glpRewardTracker) external onlyGovernor {
        glpRewardTracker = IJonesGlpRewardTracker(_glpRewardTracker);
        rewardTrackers[address(glp)] = glpRewardTracker;
    }

    /**
     * @notice Set a new incentive Receiver address
     * @param _newIncentiveReceiver Incentive Receiver Address
     */
    function setIncentiveReceiver(address _newIncentiveReceiver) external onlyGovernor {
        incentiveReceiver = IIncentiveReceiver(_newIncentiveReceiver);
    }

    /**
     * @notice Set GLP Adapter Contract
     * @param _adapter GLP Adapter address
     */
    function setGlpAdapter(address _adapter) external onlyGovernor {
        adapter = GlpAdapter(_adapter);
    }

    // ============================= Private functions ================================ //

    function _deposit(IERC4626 _vault, address _caller, uint256 _assets, bool compound)
        private
        returns (uint256, uint256)
    {
        IERC20 asset = IERC20(_vault.asset());
        address adapterAddress = address(adapter);
        IJonesGlpRewardTracker tracker = rewardTrackers[address(asset)];

        if (msg.sender == adapterAddress) {
            asset.transferFrom(adapterAddress, address(this), _assets);
        } else {
            asset.transferFrom(_caller, address(this), _assets);
        }

        uint256 vaultShares = _vaultDeposit(_vault, _assets);

        uint256 compoundShares;

        if (compound) {
            IJonesGlpCompoundRewards compounder = rewardCompounder[address(asset)];
            IERC20(address(_vault)).approve(address(compounder), vaultShares);
            compoundShares = compounder.deposit(vaultShares, _caller);
        } else {
            IERC20(address(_vault)).approve(address(tracker), vaultShares);
            tracker.stake(_caller, vaultShares);
        }

        return (compoundShares, vaultShares);
    }

    function _distributeGlp(uint256 _amount, address _dest, bool _compound) private returns (uint256) {
        uint256 retention = _chargeIncentive(_amount, _dest);
        uint256 wethAmount;

        if (retention > 0) {
            wethAmount = router.unstakeAndRedeemGlp(weth, retention, 0, address(this));
            uint256 jonesRetention = (wethAmount * 2) / 3;
            IERC20(weth).approve(address(incentiveReceiver), jonesRetention);
            incentiveReceiver.deposit(weth, jonesRetention);
            IERC20(weth).approve(address(glpRewardTracker), wethAmount - jonesRetention);

            glpRewardTracker.depositRewards(wethAmount - jonesRetention);
        }

        uint256 glpAfterRetention = _amount - retention;

        glp.transfer(_dest, glpAfterRetention);

        // Information needed to calculate glp retention
        emit RedeemGlp(_dest, glpAfterRetention, retention, wethAmount, address(0), 0, _compound);

        return glpAfterRetention;
    }

    function _distributeGlpAdapter(uint256 _amount, address _dest, address _token, bool _native, bool _compound)
        private
        returns (uint256)
    {
        uint256 retention = _chargeIncentive(_amount, _dest);

        uint256 wethAmount;

        if (retention > 0) {
            wethAmount = router.unstakeAndRedeemGlp(weth, retention, 0, address(this));
            uint256 jonesRetention = (wethAmount * 2) / 3;
            IERC20(weth).approve(address(incentiveReceiver), jonesRetention);
            incentiveReceiver.deposit(weth, jonesRetention);
            IERC20(weth).approve(address(glpRewardTracker), wethAmount - jonesRetention);

            glpRewardTracker.depositRewards(wethAmount - jonesRetention);
        }

        if (_native) {
            uint256 ethAmount = router.unstakeAndRedeemGlpETH(_amount - retention, 0, payable(_dest));

            // Information needed to calculate glp retention
            emit RedeemGlp(_dest, _amount - retention, retention, wethAmount, address(0), ethAmount, _compound);

            return ethAmount;
        }

        uint256 assetAmount = router.unstakeAndRedeemGlp(_token, _amount - retention, 0, _dest);

        // Information needed to calculate glp retention
        emit RedeemGlp(_dest, _amount - retention, retention, wethAmount, _token, 0, _compound);

        return assetAmount;
    }

    function _borrowStables(uint256 _amount) private returns (uint256) {
        JonesGlpStableVault stableVault = glpStableVault;

        uint256 balance = stable.balanceOf(address(stableVault));
        if (balance == 0) {
            return 0;
        }

        uint256 amountToBorrow = balance < _amount ? balance : _amount;

        emit BorrowStables(amountToBorrow);

        return stableVault.borrow(amountToBorrow);
    }

    function _chargeIncentive(uint256 _withdrawAmount, address _sender) private view returns (uint256) {
        bytes32 userRole = whitelistController.getUserRole(_sender);
        IWhitelistController.RoleInfo memory info = whitelistController.getRoleInfo(userRole);

        return (_withdrawAmount * info.jGLP_RETENTION) / BASIS_POINTS;
    }

    function _unCompoundGlp(uint256 _shares, address _user) private returns (uint256) {
        if (msg.sender != address(adapter) && msg.sender != _user) {
            revert Errors.OnlyAuthorized();
        }

        IJonesGlpCompoundRewards compounder = rewardCompounder[address(glp)];

        uint256 shares = compounder.redeem(_shares, _user);

        emit unCompoundGlp(_user, _shares);

        return shares;
    }

    function _unCompoundStables(uint256 _shares) private returns (uint256) {
        IJonesGlpCompoundRewards compounder = rewardCompounder[address(stable)];

        uint256 shares = compounder.redeem(_shares, msg.sender);

        emit unCompoundStables(msg.sender, _shares);

        return shares;
    }

    function _vaultDeposit(IERC4626 _vault, uint256 _assets) private returns (uint256) {
        address asset = _vault.asset();
        address vaultAddress = address(_vault);
        uint256 vaultShares;
        if (_vault.asset() == address(glp)) {
            uint256 glpMintIncentives = strategy.glpMintIncentive(_assets);

            uint256 assetsToDeposit = _assets - glpMintIncentives;

            IERC20(asset).approve(vaultAddress, assetsToDeposit);

            vaultShares = _vault.deposit(assetsToDeposit, address(this));
            if (glpMintIncentives > 0) {
                glp.transfer(vaultAddress, glpMintIncentives);
            }

            emit VaultDeposit(vaultAddress, _assets, glpMintIncentives);
        } else {
            IERC20(asset).approve(vaultAddress, _assets);
            vaultShares = _vault.deposit(_assets, address(this));
            emit VaultDeposit(vaultAddress, _assets, 0);
        }
        return vaultShares;
    }

    function _onlyInternalContract() private view {
        if (!whitelistController.isInternalContract(msg.sender)) {
            revert Errors.CallerIsNotInternalContract();
        }
    }

    function _onlyEOA() private view {
        if (msg.sender != tx.origin && !whitelistController.isWhitelistedContract(msg.sender)) {
            revert Errors.CallerIsNotWhitelisted();
        }
    }

    function togglePause() external onlyGovernor {
        if (paused()) {
            _unpause();
            return;
        }

        _pause();
    }

    function toggleEmergencyPause() external onlyGovernor {
        if (emergencyPaused()) {
            _emergencyUnpause();
            return;
        }

        _emergencyPause();
    }

    /**
     * @notice Emergency withdraw UVRT in this contract
     * @param _to address to send the funds
     */
    function emergencyWithdraw(address _to) external onlyGovernor {
        IERC20 UVRT = IERC20(address(glpStableVault));
        uint256 currentBalance = UVRT.balanceOf(address(this));

        if (currentBalance == 0) {
            return;
        }

        UVRT.transfer(_to, currentBalance);

        emit EmergencyWithdraw(_to, currentBalance);
    }

    event DepositGlp(address indexed _to, uint256 _amount, uint256 _sharesReceived, bool _compound);
    event DepositStables(address indexed _to, uint256 _amount, uint256 _sharesReceived, bool _compound);
    event VaultDeposit(address indexed vault, uint256 _amount, uint256 _retention);
    event RedeemGlp(
        address indexed _to,
        uint256 _amount,
        uint256 _retentions,
        uint256 _ethRetentions,
        address _token,
        uint256 _ethAmount,
        bool _compound
    );
    event RedeemStable(
        address indexed _to, uint256 _amount, uint256 _retentions, uint256 _realRetentions, bool _compound
    );
    event ClaimRewards(address indexed _to, uint256 _stableAmount, uint256 _wEthAmount, uint256 _amountJones);
    event CompoundGlp(address indexed _to, uint256 _amount);
    event CompoundStables(address indexed _to, uint256 _amount);
    event unCompoundGlp(address indexed _to, uint256 _amount);
    event unCompoundStables(address indexed _to, uint256 _amount);
    event StableWithdrawalSignal(
        address indexed sender, uint256 _shares, uint256 indexed _targetEpochTs, bool _compound
    );
    event CancelStableWithdrawalSignal(address indexed sender, uint256 _shares, bool _compound);
    event BorrowStables(uint256 indexed _amountBorrowed);
    event EmergencyWithdraw(address indexed _to, uint256 indexed _amount);
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 Jones DAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

pragma solidity ^0.8.10;

import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {Governable, OperableKeepable} from "../../common/OperableKeepable.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";
import {IJonesGlpRewardDistributor} from "../../interfaces/IJonesGlpRewardDistributor.sol";
import {IJonesGlpRewardTracker} from "../../interfaces/IJonesGlpRewardTracker.sol";
import {IJonesGlpRewardsSwapper} from "../../interfaces/IJonesGlpRewardsSwapper.sol";
import {IIncentiveReceiver} from "../../interfaces/IIncentiveReceiver.sol";

contract JonesGlpRewardTracker is IJonesGlpRewardTracker, OperableKeepable, ReentrancyGuard {
    uint256 public constant PRECISION = 1e30;

    address public constant weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address public constant usdc = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;

    address public immutable sharesToken;
    address public immutable rewardToken;

    IJonesGlpRewardDistributor public distributor;
    IJonesGlpRewardsSwapper public swapper;
    IIncentiveReceiver public incentiveReceiver;

    uint256 public wethRewards;
    uint256 public cumulativeRewardPerShare;
    mapping(address => uint256) public claimableReward;
    mapping(address => uint256) public previousCumulatedRewardPerShare;
    mapping(address => uint256) public cumulativeRewards;

    uint256 public totalStakedAmount;
    mapping(address => uint256) public stakedAmounts;

    constructor(address _sharesToken, address _rewardToken, address _distributor, address _incentiveReceiver)
        Governable(msg.sender)
        ReentrancyGuard()
    {
        if (_sharesToken == address(0)) {
            revert AddressCannotBeZeroAddress();
        }
        if (_rewardToken == address(0)) {
            revert AddressCannotBeZeroAddress();
        }
        if (_distributor == address(0)) {
            revert AddressCannotBeZeroAddress();
        }
        if (_incentiveReceiver == address(0)) {
            revert AddressCannotBeZeroAddress();
        }

        sharesToken = _sharesToken;
        rewardToken = _rewardToken;
        distributor = IJonesGlpRewardDistributor(_distributor);
        incentiveReceiver = IIncentiveReceiver(_incentiveReceiver);
    }

    // ============================= Operator functions ================================ //

    /**
     * @inheritdoc IJonesGlpRewardTracker
     */
    function stake(address _account, uint256 _amount) external onlyOperator returns (uint256) {
        if (_amount == 0) {
            revert AmountCannotBeZero();
        }
        _stake(_account, _amount);
        return _amount;
    }

    /**
     * @inheritdoc IJonesGlpRewardTracker
     */
    function withdraw(address _account, uint256 _amount) external onlyOperator returns (uint256) {
        if (_amount == 0) {
            revert AmountCannotBeZero();
        }

        _withdraw(_account, _amount);
        return _amount;
    }

    /**
     * @inheritdoc IJonesGlpRewardTracker
     */
    function claim(address _account) external onlyOperator returns (uint256) {
        return _claim(_account);
    }

    /**
     * @inheritdoc IJonesGlpRewardTracker
     */
    function updateRewards() external nonReentrant onlyOperatorOrKeeper {
        _updateRewards(address(0));
    }

    /**
     * @inheritdoc IJonesGlpRewardTracker
     */
    function depositRewards(uint256 _rewards) external onlyOperator {
        if (_rewards == 0) {
            revert AmountCannotBeZero();
        }
        uint256 totalShares = totalStakedAmount;
        IERC20(rewardToken).transferFrom(msg.sender, address(this), _rewards);

        if (totalShares != 0) {
            cumulativeRewardPerShare = cumulativeRewardPerShare + ((_rewards * PRECISION) / totalShares);
            emit UpdateRewards(msg.sender, _rewards, totalShares, cumulativeRewardPerShare);
        } else {
            IERC20(rewardToken).approve(address(incentiveReceiver), _rewards);
            incentiveReceiver.deposit(rewardToken, _rewards);
        }
    }

    // ============================= External functions ================================ //

    /**
     * @inheritdoc IJonesGlpRewardTracker
     */
    function claimable(address _account) external view returns (uint256) {
        uint256 shares = stakedAmounts[_account];
        if (shares == 0) {
            return claimableReward[_account];
        }
        uint256 totalShares = totalStakedAmount;
        uint256 pendingRewards = distributor.pendingRewards(address(this)) * PRECISION;
        uint256 nextCumulativeRewardPerShare = cumulativeRewardPerShare + (pendingRewards / totalShares);
        return claimableReward[_account]
            + ((shares * (nextCumulativeRewardPerShare - previousCumulatedRewardPerShare[_account])) / PRECISION);
    }

    /**
     * @inheritdoc IJonesGlpRewardTracker
     */
    function stakedAmount(address _account) external view returns (uint256) {
        return stakedAmounts[_account];
    }

    // ============================= Governor functions ================================ //

    /**
     * @notice Set a new distributor contract
     * @param _distributor New distributor address
     */
    function setDistributor(address _distributor) external onlyGovernor {
        if (_distributor == address(0)) {
            revert AddressCannotBeZeroAddress();
        }

        distributor = IJonesGlpRewardDistributor(_distributor);
    }

    /**
     * @notice Set a new swapper contract
     * @param _swapper New swapper address
     */
    function setSwapper(address _swapper) external onlyGovernor {
        if (_swapper == address(0)) {
            revert AddressCannotBeZeroAddress();
        }

        swapper = IJonesGlpRewardsSwapper(_swapper);
    }

    /**
     * @notice Set a new incentive receiver contract
     * @param _incentiveReceiver New incentive receiver address
     */
    function setIncentiveReceiver(address _incentiveReceiver) external onlyGovernor {
        if (_incentiveReceiver == address(0)) {
            revert AddressCannotBeZeroAddress();
        }

        incentiveReceiver = IIncentiveReceiver(_incentiveReceiver);
    }

    // ============================= Private functions ================================ //

    function _stake(address _account, uint256 _amount) private nonReentrant {
        IERC20(sharesToken).transferFrom(msg.sender, address(this), _amount);

        _updateRewards(_account);

        stakedAmounts[_account] = stakedAmounts[_account] + _amount;
        totalStakedAmount = totalStakedAmount + _amount;
        emit Stake(_account, _amount);
    }

    function _withdraw(address _account, uint256 _amount) private nonReentrant {
        _updateRewards(_account);

        uint256 amountStaked = stakedAmounts[_account];
        if (_amount > amountStaked) {
            revert AmountExceedsStakedAmount(); // Error camel case
        }

        stakedAmounts[_account] = amountStaked - _amount;

        totalStakedAmount = totalStakedAmount - _amount;

        IERC20(sharesToken).transfer(msg.sender, _amount);
        emit Withdraw(_account, _amount);
    }

    function _claim(address _account) private nonReentrant returns (uint256) {
        _updateRewards(_account);

        uint256 tokenAmount = claimableReward[_account];
        claimableReward[_account] = 0;

        if (tokenAmount > 0) {
            IERC20(rewardToken).transfer(msg.sender, tokenAmount);
            emit Claim(_account, tokenAmount);
        }

        return tokenAmount;
    }

    function _updateRewards(address _account) private {
        uint256 rewards = distributor.distributeRewards(); // get new rewards for the distributor

        if (IERC4626(sharesToken).asset() == usdc && rewards > 0) {
            wethRewards = wethRewards + rewards;
            if (swapper.minAmountOut(wethRewards) > 0) {
                // enough weth to swap
                IERC20(weth).approve(address(swapper), wethRewards);
                rewards = swapper.swapRewards(wethRewards);
                wethRewards = 0;
            }
        }

        uint256 totalShares = totalStakedAmount;

        uint256 _cumulativeRewardPerShare = cumulativeRewardPerShare;
        if (totalShares > 0 && rewards > 0 && wethRewards == 0) {
            _cumulativeRewardPerShare = _cumulativeRewardPerShare + ((rewards * PRECISION) / totalShares);
            cumulativeRewardPerShare = _cumulativeRewardPerShare; // add new rewards to cumulative rewards
            // Information needed to calculate rewards
            emit UpdateRewards(_account, rewards, totalShares, cumulativeRewardPerShare);
        }

        // cumulativeRewardPerShare can only increase
        // so if cumulativeRewardPerShare is zero, it means there are no rewards yet
        if (_cumulativeRewardPerShare == 0) {
            return;
        }

        if (_account != address(0)) {
            uint256 shares = stakedAmounts[_account];

            uint256 accountReward =
                (shares * (_cumulativeRewardPerShare - previousCumulatedRewardPerShare[_account])) / PRECISION;
            uint256 _claimableReward = claimableReward[_account] + accountReward;
            claimableReward[_account] = _claimableReward; // add new user rewards to cumulative user rewards
            previousCumulatedRewardPerShare[_account] = _cumulativeRewardPerShare; // Important to not have more rewards than expected

            if (_claimableReward > 0 && shares > 0) {
                uint256 nextCumulativeReward = cumulativeRewards[_account] + accountReward;
                cumulativeRewards[_account] = nextCumulativeReward;
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 Jones DAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

pragma solidity ^0.8.10;

import {JonesBaseGlpVault, ERC4626, IERC4626} from "./JonesBaseGlpVault.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IAggregatorV3} from "../../interfaces/IAggregatorV3.sol";
import {IStakedGlp} from "../../interfaces/IStakedGlp.sol";
import {IJonesGlpLeverageStrategy} from "../../interfaces/IJonesGlpLeverageStrategy.sol";

contract JonesGlpVault is JonesBaseGlpVault {
    uint256 private freezedAssets;

    constructor()
        JonesBaseGlpVault(
            IAggregatorV3(0xDFE51CC551949704E5C52C7BB98DCC3fd934E7fa),
            IERC20Metadata(0x5402B5F40310bDED796c7D0F3FF6683f5C0cFfdf),
            "GLP Vault Receipt Token",
            "GVRT"
        )
    {}
    // ============================= Public functions ================================ //

    function deposit(uint256 _assets, address _receiver)
        public
        override(JonesBaseGlpVault)
        whenNotPaused
        returns (uint256)
    {
        _validate();
        return super.deposit(_assets, _receiver);
    }

    /**
     * @dev See {openzeppelin-IERC4626-_burn}.
     */
    function burn(address _user, uint256 _amount) public onlyOperator {
        _validate();
        _burn(_user, _amount);
    }

    /**
     * @notice Return total asset deposited
     * @return Amount of asset deposited
     */
    function totalAssets() public view override(IERC4626, ERC4626) returns (uint256) {
        if (freezedAssets != 0) {
            return freezedAssets;
        }

        return super.totalAssets() + strategy.getUnderlyingGlp();
    }

    // ============================= Private functions ================================ //

    function _validate() private {
        IERC20 asset = IERC20(asset());
        uint256 balance = asset.balanceOf(address(this));

        if (balance > 0) {
            asset.transfer(receiver, balance);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 Jones DAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

pragma solidity ^0.8.10;

import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {Governable} from "src/common/Governable.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {OperableKeepable} from "src/common/OperableKeepable.sol";
import {IGmxRewardRouter} from "src/interfaces/IGmxRewardRouter.sol";
import {JonesGlpVaultRouter} from "src/glp/JonesGlpVaultRouter.sol";
import {IJonesGlpCompoundRewards} from "src/interfaces/IJonesGlpCompoundRewards.sol";
import {IJonesGlpRewardTracker} from "src/interfaces/IJonesGlpRewardTracker.sol";
import {IIncentiveReceiver} from "src/interfaces/IIncentiveReceiver.sol";
import {GlpJonesRewards} from "src/glp/rewards/GlpJonesRewards.sol";

contract JonesGlpCompoundRewards is IJonesGlpCompoundRewards, ERC20, OperableKeepable, ReentrancyGuard {
    using Math for uint256;

    uint256 public constant BASIS_POINTS = 1e12;

    address public constant weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address public constant usdc = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address public constant glp = 0x5402B5F40310bDED796c7D0F3FF6683f5C0cFfdf;
    IGmxRewardRouter public gmxRouter = IGmxRewardRouter(0xB95DB5B167D75e6d04227CfFFA61069348d271F5);

    IERC20 public asset;
    IERC20Metadata public vaultToken;

    uint256 public stableRetentionPercentage;
    uint256 public glpRetentionPercentage;

    uint256 public totalAssets; // total assets;
    uint256 public totalAssetsDeposits; // total assets deposits;

    mapping(address => uint256) public receiptBalance; // assets deposits

    JonesGlpVaultRouter public router;
    IJonesGlpRewardTracker public tracker;
    IIncentiveReceiver public incentiveReceiver;
    GlpJonesRewards public jonesRewards;

    constructor(
        uint256 _stableRetentionPercentage,
        uint256 _glpRetentionPercentage,
        IIncentiveReceiver _incentiveReceiver,
        IJonesGlpRewardTracker _tracker,
        GlpJonesRewards _jonesRewards,
        IERC20 _asset,
        IERC20Metadata _vaultToken,
        string memory _name,
        string memory _symbol
    ) Governable(msg.sender) ERC20(_name, _symbol) ReentrancyGuard() {
        if (_stableRetentionPercentage > BASIS_POINTS) {
            revert RetentionPercentageOutOfRange();
        }
        if (_glpRetentionPercentage > BASIS_POINTS) {
            revert RetentionPercentageOutOfRange();
        }

        stableRetentionPercentage = _stableRetentionPercentage;
        glpRetentionPercentage = _glpRetentionPercentage;
        incentiveReceiver = _incentiveReceiver;
        jonesRewards = _jonesRewards;

        asset = _asset;
        vaultToken = _vaultToken;

        tracker = _tracker;
    }

    // ============================= Keeper Functions ================================ //

    /**
     * @inheritdoc IJonesGlpCompoundRewards
     */
    function compound() external onlyOperatorOrKeeper {
        _compound();
    }

    // ============================= Operable Functions ================================ //

    /**
     * @inheritdoc IJonesGlpCompoundRewards
     */
    function deposit(uint256 _assets, address _receiver) external nonReentrant onlyOperator returns (uint256) {
        uint256 shares = previewDeposit(_assets);
        _deposit(_receiver, _assets, shares);

        return shares;
    }

    /**
     * @inheritdoc IJonesGlpCompoundRewards
     */
    function redeem(uint256 _shares, address _receiver) external nonReentrant onlyOperator returns (uint256) {
        uint256 assets = previewRedeem(_shares);
        _withdraw(_receiver, assets, _shares);

        return assets;
    }

    // ============================= Public Functions ================================ //

    /**
     * @inheritdoc IJonesGlpCompoundRewards
     */
    function previewDeposit(uint256 assets) public view returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Down);
    }

    /**
     * @inheritdoc IJonesGlpCompoundRewards
     */
    function previewRedeem(uint256 shares) public view returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Down);
    }

    /**
     * @inheritdoc IJonesGlpCompoundRewards
     */
    function totalAssetsToDeposits(address recipient, uint256 assets) public view returns (uint256) {
        uint256 totalRecipientAssets = _convertToAssets(balanceOf(recipient), Math.Rounding.Down);
        return assets.mulDiv(receiptBalance[recipient], totalRecipientAssets, Math.Rounding.Down);
    }

    // ============================= Governor Functions ================================ //

    /**
     * @notice Transfer all Glp managed by this contract to an address
     * @param _to Address to transfer funds
     */
    function emergencyGlpWithdraw(address _to) external onlyGovernor {
        _compound();
        router.redeemGlp(tracker.stakedAmount(address(this)), false);
        asset.transfer(_to, asset.balanceOf(address(this)));
    }

    /**
     * @notice Transfer all Stable assets managed by this contract to an address
     * @param _to Address to transfer funds
     */
    function emergencyStableWithdraw(address _to) external onlyGovernor {
        _compound();
        router.stableWithdrawalSignal(tracker.stakedAmount(address(this)), false);
        asset.transfer(_to, asset.balanceOf(address(this)));
    }

    /**
     * @notice Set new router contract
     * @param _router New router contract
     */
    function setRouter(JonesGlpVaultRouter _router) external onlyGovernor {
        router = _router;
    }

    /**
     * @notice Set new retention received
     * @param _incentiveReceiver New retention received
     */
    function setIncentiveReceiver(IIncentiveReceiver _incentiveReceiver) external onlyGovernor {
        incentiveReceiver = _incentiveReceiver;
    }

    /**
     * @notice Set new reward tracker contract
     * @param _tracker New reward tracker contract
     */
    function setRewardTracker(IJonesGlpRewardTracker _tracker) external onlyGovernor {
        tracker = _tracker;
    }

    /**
     * @notice Set new asset
     * @param _asset New asset
     */
    function setAsset(IERC20Metadata _asset) external onlyGovernor {
        asset = _asset;
    }

    /**
     * @notice Set new vault token
     * @param _vaultToken New vault token contract
     */
    function setVaultToken(IERC20Metadata _vaultToken) external onlyGovernor {
        vaultToken = _vaultToken;
    }

    /**
     * @notice Set new gmx router contract
     * @param _gmxRouter New gmx router contract
     */
    function setGmxRouter(IGmxRewardRouter _gmxRouter) external onlyGovernor {
        gmxRouter = _gmxRouter;
    }

    /**
     * @notice Set new retentions
     * @param _stableRetentionPercentage New stable retention
     * @param _glpRetentionPercentage New glp retention
     */
    function setNewRetentions(uint256 _stableRetentionPercentage, uint256 _glpRetentionPercentage)
        external
        onlyGovernor
    {
        if (_stableRetentionPercentage > BASIS_POINTS) {
            revert RetentionPercentageOutOfRange();
        }
        if (_glpRetentionPercentage > BASIS_POINTS) {
            revert RetentionPercentageOutOfRange();
        }

        stableRetentionPercentage = _stableRetentionPercentage;
        glpRetentionPercentage = _glpRetentionPercentage;
    }

    /**
     * @notice Set Jones Rewards Contract
     * @param _jonesRewards Contract that manage Jones Rewards
     */
    function setJonesRewards(GlpJonesRewards _jonesRewards) external onlyGovernor {
        jonesRewards = _jonesRewards;
    }

    // ============================= Private Functions ================================ //

    function _deposit(address receiver, uint256 assets, uint256 shares) private {
        vaultToken.transferFrom(msg.sender, address(this), assets);

        receiptBalance[receiver] = receiptBalance[receiver] + assets;

        vaultToken.approve(address(tracker), assets);
        tracker.stake(address(this), assets);

        totalAssetsDeposits = totalAssetsDeposits + assets;
        totalAssets = tracker.stakedAmount(address(this));

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    function _withdraw(address receiver, uint256 assets, uint256 shares) private {
        uint256 depositAssets = totalAssetsToDeposits(receiver, assets);

        _burn(receiver, shares);

        receiptBalance[receiver] = receiptBalance[receiver] - depositAssets;

        totalAssetsDeposits = totalAssetsDeposits - depositAssets;

        tracker.withdraw(address(this), assets);

        vaultToken.approve(address(tracker), assets);
        tracker.stake(receiver, assets);

        totalAssets = tracker.stakedAmount(address(this));

        emit Withdraw(msg.sender, receiver, assets, shares);
    }

    function _compound() private {
        (uint256 stableRewards, uint256 glpRewards,) = router.claimRewards();
        if (glpRewards > 0) {
            uint256 retention = _retention(glpRewards, glpRetentionPercentage);
            if (retention > 0) {
                IERC20(weth).approve(address(incentiveReceiver), retention);
                incentiveReceiver.deposit(weth, retention);
                glpRewards = glpRewards - retention;
            }

            IERC20(weth).approve(gmxRouter.glpManager(), glpRewards);
            uint256 glpAmount = gmxRouter.mintAndStakeGlp(weth, glpRewards, 0, 0);
            glpRewards = glpAmount;

            IERC20(glp).approve(address(router), glpRewards);
            router.depositGlp(glpRewards, address(this), false);
            totalAssets = tracker.stakedAmount(address(this));

            // Information needed to calculate compounding rewards per Vault
            emit Compound(glpRewards, totalAssets, retention);
        }
        if (stableRewards > 0) {
            uint256 retention = _retention(stableRewards, stableRetentionPercentage);
            if (retention > 0) {
                IERC20(usdc).approve(address(incentiveReceiver), retention);
                incentiveReceiver.deposit(usdc, retention);
                stableRewards = stableRewards - retention;
            }

            IERC20(usdc).approve(address(router), stableRewards);
            router.depositStable(stableRewards, false, address(this));
            totalAssets = tracker.stakedAmount(address(this));

            // Information needed to calculate compounding rewards per Vault
            emit Compound(stableRewards, totalAssets, retention);
        }
    }

    function _convertToShares(uint256 assets, Math.Rounding rounding) private view returns (uint256 shares) {
        uint256 supply = totalSupply();

        return (assets == 0 || supply == 0)
            ? assets.mulDiv(10 ** decimals(), 10 ** vaultToken.decimals(), rounding)
            : assets.mulDiv(supply, totalAssets, rounding);
    }

    function _convertToAssets(uint256 shares, Math.Rounding rounding) private view returns (uint256 assets) {
        uint256 supply = totalSupply();
        return (supply == 0)
            ? shares.mulDiv(10 ** vaultToken.decimals(), 10 ** decimals(), rounding)
            : shares.mulDiv(totalAssets, supply, rounding);
    }

    function _retention(uint256 _rewards, uint256 _retentionPercentage) private pure returns (uint256) {
        return (_rewards * _retentionPercentage) / BASIS_POINTS;
    }

    function internalTransfer(address from, address to, uint256 amount) private {
        uint256 assets = previewRedeem(amount);
        uint256 depositAssets = totalAssetsToDeposits(from, assets);
        receiptBalance[from] = receiptBalance[from] - depositAssets;
        receiptBalance[to] = receiptBalance[to] + depositAssets;
        if (address(asset) == usdc) {
            jonesRewards.getReward(from);
            jonesRewards.withdraw(from, depositAssets);
            jonesRewards.stake(to, depositAssets);
        }
    }

    /// ============================= ERC20 Functions ================================ //

    function name() public view override returns (string memory) {
        return super.name();
    }

    function symbol() public view override returns (string memory) {
        return super.symbol();
    }

    function decimals() public view override returns (uint8) {
        return super.decimals();
    }

    function totalSupply() public view override returns (uint256) {
        return super.totalSupply();
    }

    function balanceOf(address account) public view override returns (uint256) {
        return super.balanceOf(account);
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        internalTransfer(msg.sender, to, amount);
        return super.transfer(to, amount);
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return super.allowance(owner, spender);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        return super.approve(spender, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        internalTransfer(from, to, amount);
        return super.transferFrom(from, to, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 Jones DAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

pragma solidity ^0.8.10;

import {UpgradeableOperableKeepable, UpgradeableGovernable} from "src/common/UpgradeableOperableKeepable.sol";

import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IJonesBorrowableVault} from "src/interfaces/IJonesBorrowableVault.sol";
import {IUnderlyingVault} from "src/interfaces/jusdc/IUnderlyingVault.sol";
import {IJonesUsdVault} from "src/interfaces/IJonesUsdVault.sol";
import {IJonesGlpRewardDistributor} from "src/interfaces/IJonesGlpRewardDistributor.sol";
import {IAggregatorV3} from "src/interfaces/IAggregatorV3.sol";
import {IGmxRewardRouter} from "src/interfaces/IGmxRewardRouter.sol";
import {IJonesGlpLeverageStrategy} from "src/interfaces/IJonesGlpLeverageStrategy.sol";
import {IGlpManager} from "src/interfaces/IGlpManager.sol";
import {IGMXVault} from "src/interfaces/IGMXVault.sol";
import {IRewardTracker} from "src/interfaces/IRewardTracker.sol";
import {IPayBack} from "src/interfaces/IPayBack.sol";

contract GlpStrategy is IJonesGlpLeverageStrategy, IPayBack, UpgradeableOperableKeepable {
    using Math for uint256;

    struct LeverageConfig {
        uint256 target;
        uint256 min;
        uint256 max;
    }

    /* -------------------------------------------------------------------------- */
    /*                                  VARIABLES                                 */
    /* -------------------------------------------------------------------------- */

    IGmxRewardRouter private routerV1;
    IGmxRewardRouter private routerV2;
    IGlpManager private glpManager;

    uint256 private constant PRECISION = 1e30;
    uint256 private constant BASIS_POINTS = 1e12;
    uint256 private constant GMX_BASIS = 1e4;
    uint256 private constant USDC_DECIMALS = 1e6;
    uint256 private constant GLP_DECIMALS = 1e18;

    address private constant weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    IERC20 private stable;
    IERC20 private glp;

    IUnderlyingVault private stableVault;
    IJonesBorrowableVault private glpVault;
    IJonesGlpRewardDistributor private distributor;

    uint256 public stableDebt;

    LeverageConfig public leverageConfig;

    /// @notice Slippage to avoid reverts after simulations
    uint256 private slippage;

    /* -------------------------------------------------------------------------- */
    /*                                 INITIALIZE                                 */
    /* -------------------------------------------------------------------------- */

    function initialize(
        LeverageConfig memory _leverageConfig,
        address _stableVault,
        address _glpVault,
        address _distributor,
        uint256 _stableDebt
    ) external initializer {
        __Governable_init(msg.sender);

        routerV1 = IGmxRewardRouter(0xA906F338CB21815cBc4Bc87ace9e68c87eF8d8F1);
        routerV2 = IGmxRewardRouter(0xB95DB5B167D75e6d04227CfFFA61069348d271F5);
        glpManager = IGlpManager(0x3963FfC9dff443c2A94f21b129D429891E32ec18);

        stableVault = IUnderlyingVault(_stableVault);
        glpVault = IJonesBorrowableVault(_glpVault);
        distributor = IJonesGlpRewardDistributor(_distributor);

        stable = IERC20(0xaf88d065e77c8cC2239327C5EDb3A432268e5831);
        glp = IERC20(0x5402B5F40310bDED796c7D0F3FF6683f5C0cFfdf);

        stableDebt = _stableDebt;
        slippage = (99 * 1e12) / 100;

        _setLeverageConfig(_leverageConfig);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  OPERATOR                                  */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Enforce Payback to stable vault
     * @param amount Amount to pay back
     * @param enforceData Extra data to enforce payback
     * @return gmx retention used in the payback
     */
    function payBack(uint256 amount, bytes calldata enforceData) external onlyOperator returns (uint256) {
        uint256 strategyStables = stable.balanceOf(address(this));

        uint256 expectedStables = amount > strategyStables ? amount - strategyStables : 0;

        uint256 gmxIncentive;
        uint256 amountAfterRetention;

        if (expectedStables > 0) {
            gmxIncentive = retentionRefund(expectedStables + 2, enforceData);
            amountAfterRetention = amount - gmxIncentive;
            expectedStables = expectedStables - gmxIncentive;
            (uint256 glpAmount,) = _getRequiredGlpAmount(expectedStables + 2);
            routerV2.unstakeAndRedeemGlp(address(stable), glpAmount, expectedStables, address(this));
        } else {
            amountAfterRetention = amount;
        }

        stable.approve(address(stableVault), amountAfterRetention);
        stableVault.payBack(amount, gmxIncentive);

        stableDebt = stableDebt > amount ? stableDebt - amount : 0;

        return gmxIncentive;
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function onGlpDeposit(uint256 _amount) external onlyOperator {
        _borrowGlp(_amount);
        uint256 targetLeverage = getTargetLeverage();
        if (leverage() < targetLeverage && targetLeverage > BASIS_POINTS + 1) {
            _leverage(_amount);
        }
        uint256 underlying = getUnderlyingGlp();
        if (underlying > 0) {
            _rebalance(underlying);
        }
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function onGlpCompound(uint256 _amount) external onlyOperator {
        _borrowGlp(_amount);

        uint256 underlying = getUnderlyingGlp();
        if (underlying > 0) {
            _rebalance(underlying);
        }
    }
    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */

    function onGlpRedeem(uint256 _amount) external onlyOperator returns (uint256) {
        if (_amount > getUnderlyingGlp()) {
            revert NotEnoughUnderlyingGlp();
        }

        uint256 glpRedeemRetention_ = glpRedeemRetention(_amount);
        uint256 assetsToRedeem = _amount - glpRedeemRetention_;

        glp.transfer(msg.sender, assetsToRedeem);

        uint256 underlying = getUnderlyingGlp();
        uint256 leverageAmount = glp.balanceOf(address(this)) - underlying;
        uint256 protocolExcess = ((underlying * (leverageConfig.target - BASIS_POINTS)) / BASIS_POINTS);
        uint256 excessGlp;
        if (leverageAmount < protocolExcess) {
            excessGlp = leverageAmount;
        } else {
            excessGlp = ((_amount * (leverageConfig.target - BASIS_POINTS)) / BASIS_POINTS); // 18 Decimals
        }

        if (leverageAmount >= excessGlp && leverage() > getTargetLeverage()) {
            _deleverage(excessGlp);
            emit Deleverage(excessGlp, assetsToRedeem);
        } else {
            assetsToRedeem = _amount;
            glp.transfer(msg.sender, glpRedeemRetention_);
        }

        underlying = getUnderlyingGlp();
        if (underlying > 0) {
            _rebalance(underlying);
        }

        return assetsToRedeem;
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function onStableRedeem(uint256 _amount, uint256 _amountAfterRetention) external onlyOperator returns (uint256) {
        uint256 strategyStables = stable.balanceOf(address(this));
        uint256 expectedStables = _amountAfterRetention > strategyStables ? _amountAfterRetention - strategyStables : 0;

        if (expectedStables > 0) {
            (uint256 glpAmount,) = _getRequiredGlpAmount(expectedStables + 2);
            uint256 stableAmount =
                routerV2.unstakeAndRedeemGlp(address(stable), glpAmount, expectedStables, address(this));
            if (stableAmount + strategyStables < _amountAfterRetention) {
                revert NotEnoughStables();
            }
        }

        stable.transfer(msg.sender, _amountAfterRetention);

        stableDebt = stableDebt - _amount;

        return _amountAfterRetention;
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function claimGlpRewards() external onlyOperatorOrKeeper {
        routerV1.handleRewards(false, false, true, true, true, true, false);

        uint256 rewards = IERC20(weth).balanceOf(address(this));

        uint256 currentLeverage = leverage();

        IERC20(weth).approve(address(distributor), rewards);

        distributor.splitRewards(rewards, currentLeverage, utilization());

        // Information needed to calculate rewards per Vault
        emit ClaimGlpRewards(
            tx.origin,
            msg.sender,
            rewards,
            block.timestamp,
            currentLeverage,
            glp.balanceOf(address(this)),
            getUnderlyingGlp(),
            glpVault.totalSupply(),
            stableDebt,
            stableVault.totalSupply()
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                                     VIEW                                   */
    /* -------------------------------------------------------------------------- */

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function utilization() public view returns (uint256) {
        address thisAddress = address(this);
        uint256 totalStables = stableVault.totalAssets();
        uint256 _cap = stableVault.cap(thisAddress).mulDiv(totalStables, BASIS_POINTS, Math.Rounding.Down);

        if (_cap == 0 || totalStables == 0) {
            return 0;
        }

        if (_cap < stableDebt) {
            return BASIS_POINTS;
        }

        return stableDebt.mulDiv(BASIS_POINTS, _cap, Math.Rounding.Down);
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function leverage() public view returns (uint256) {
        uint256 glpTvl = getUnderlyingGlp(); // 18 Decimals

        if (glpTvl == 0) {
            if (stableDebt > 0) {
                revert UnWind();
            }
            return 0;
        }

        if (stableDebt == 0) {
            return BASIS_POINTS;
        }

        return ((glp.balanceOf(address(this)) * BASIS_POINTS) / glpTvl); // 12 Decimals;
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function getUnderlyingGlp() public view returns (uint256) {
        uint256 currentBalance = glp.balanceOf(address(this));

        if (currentBalance == 0) {
            return 0;
        }

        if (stableDebt > 0) {
            (uint256 glpAmount,) = _getRequiredGlpAmount(stableDebt + 2);
            return currentBalance > glpAmount ? currentBalance - glpAmount : 0;
        } else {
            return currentBalance;
        }
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function getStableGlpValue(uint256 _glpAmount) public view returns (uint256) {
        (uint256 _value,) = _sellGlpStableSimulation(_glpAmount);
        return _value;
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function buyGlpStableSimulation(uint256 _stableAmount) public view returns (uint256) {
        return _buyGlpStableSimulation(_stableAmount);
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function getRequiredStableAmount(uint256 _glpAmount) external view returns (uint256) {
        (uint256 stableAmount,) = _getRequiredStableAmount(_glpAmount);
        return stableAmount;
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function getRequiredGlpAmount(uint256 _stableAmount) external view returns (uint256) {
        (uint256 glpAmount,) = _getRequiredGlpAmount(_stableAmount);
        return glpAmount;
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function getRedeemStableGMXIncentive(uint256 _stableAmount) external view returns (uint256) {
        (, uint256 gmxRetention) = _getRequiredGlpAmount(_stableAmount);
        return gmxRetention;
    }

    function retentionRefund(uint256 amount, bytes calldata enforceData) public view returns (uint256) {
        (, uint256 gmxRetention) = _getRequiredGlpAmount(amount);
        return (amount * gmxRetention * 1e8) / BASIS_POINTS;
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function glpMintIncentive(uint256 _glpAmount) public view returns (uint256) {
        return _glpMintIncentive(_glpAmount);
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function leverageOnDeposit(uint256 _glpAmount) external view returns (bool) {
        uint256 glpTvl = glp.balanceOf(address(this)) + _glpAmount;

        uint256 underlyingGlp;

        if (stableDebt > 0) {
            (uint256 glpAmount,) = _getRequiredGlpAmount(stableDebt + 2);
            underlyingGlp = glpTvl > glpAmount ? glpTvl - glpAmount : 0;
        }

        if (underlyingGlp == 0) {
            return false;
        }

        if (stableDebt == 0) {
            return false;
        }

        uint256 currentLeverage = ((glpTvl * BASIS_POINTS) / underlyingGlp); // 12 Decimals;

        if (currentLeverage < getTargetLeverage()) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function glpRedeemRetention(uint256 _glpAmount) public view returns (uint256) {
        return _glpRedeemRetention(_glpAmount);
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function getMaxLeverage() public view returns (uint256) {
        return leverageConfig.max;
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function getMinLeverage() public view returns (uint256) {
        return leverageConfig.min;
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function getGMXCapDifference() public view returns (uint256) {
        return _getGMXCapDifference();
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function getTargetLeverage() public view returns (uint256) {
        return leverageConfig.target;
    }

    /* -------------------------------------------------------------------------- */
    /*                                  GOVERNOR                                  */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Set Leverage Configuration
     * @dev Precision is based on 1e12 as 1x leverage
     * @param _target Target leverage
     * @param _min Min Leverage
     * @param _max Max Leverage
     * @param rebalance_ If is true trigger a rebalance
     */
    function setLeverageConfig(uint256 _target, uint256 _min, uint256 _max, bool rebalance_) public onlyGovernor {
        _setLeverageConfig(LeverageConfig(_target, _min, _max));
        emit SetLeverageConfig(_target, _min, _max);
        if (rebalance_) {
            _rebalance(getUnderlyingGlp());
        }
    }

    /**
     * @notice Set new token addresses
     * @param _glp GLP address
     * @param _stable Stable addresss
     */
    function setTokenAddresses(address _glp, address _stable) external onlyGovernor {
        address oldGlp = address(glp);
        address oldStable = address(stable);
        glp = IERC20(_glp);
        stable = IERC20(_stable);
        emit UpdateGlpAddress(oldGlp, _glp);
        emit UpdateStableAddress(oldStable, _stable);
    }

    /**
     * @notice Set new GMX contracts
     * @param _routerV1 GMX Router V1
     * @param _routerV2 GMX Router V2
     * @param _glpManager GMX GLP Manager
     */
    function setGMXContracts(address _routerV1, address _routerV2, address _glpManager) external onlyGovernor {
        routerV1 = IGmxRewardRouter(_routerV1);
        routerV2 = IGmxRewardRouter(_routerV2);
        glpManager = IGlpManager(_glpManager);
    }

    /**
     * @notice Set new internal contracts
     * @param _stableVault GMX Router V1
     * @param _glpVault GMX Router V2
     * @param _distributor GMX GLP Manager
     */
    function setInternalContracts(address _stableVault, address _glpVault, address _distributor)
        external
        onlyGovernor
    {
        stableVault = IUnderlyingVault(_stableVault);
        glpVault = IJonesBorrowableVault(_glpVault);
        distributor = IJonesGlpRewardDistributor(_distributor);
    }

    /**
     * @notice Update Slipagge
     * @param _newSlippage Slippage amount
     */
    function updateSlippage(uint256 _newSlippage) external onlyGovernor {
        slippage = _newSlippage;
    }

    /**
     * @notice Moves assets from the strategy to `_to`
     * @param _assets An array of IERC20 compatible tokens to move out from the strategy
     * @param _withdrawNative `true` if we want to move the native asset from the strategy
     */
    function emergencyWithdraw(address _to, address[] memory _assets, bool _withdrawNative) external onlyGovernor {
        uint256 assetsLength = _assets.length;
        for (uint256 i = 0; i < assetsLength; i++) {
            IERC20 asset_ = IERC20(_assets[i]);
            uint256 assetBalance = asset_.balanceOf(address(this));

            if (assetBalance > 0) {
                // Transfer the ERC20 tokens
                asset_.transfer(_to, assetBalance);
            }

            unchecked {
                ++i;
            }
        }

        uint256 nativeBalance = address(this).balance;

        // Nothing else to do
        if (_withdrawNative && nativeBalance > 0) {
            // Transfer the native currency
            (bool sent,) = payable(_to).call{value: nativeBalance}("");
            if (!sent) {
                revert FailSendETH();
            }
        }

        emit EmergencyWithdrawal(msg.sender, _to, _assets, _withdrawNative ? nativeBalance : 0);
    }

    /**
     * @notice GMX function to signal transfer position
     * @param _to address to send the funds
     * @param _gmxRouter address of gmx router with the function
     */
    function transferAccount(address _to, address _gmxRouter) external onlyGovernor {
        if (_to == address(0)) {
            revert ZeroAddressError();
        }

        IGmxRewardRouter(_gmxRouter).signalTransfer(_to);
    }

    /**
     * @notice GMX function to accept transfer position
     * @param _sender address to receive the funds
     * @param _gmxRouter address of gmx router with the function
     */
    function acceptAccountTransfer(address _sender, address _gmxRouter) external onlyGovernor {
        IGmxRewardRouter gmxRouter = IGmxRewardRouter(_gmxRouter);

        gmxRouter.acceptTransfer(_sender);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   KEEEPR                                   */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Using by the bot to rebalance if is it needed
     */
    function rebalance() external onlyKeeper {
        _rebalance(getUnderlyingGlp());
    }

    /**
     * @notice Deleverage & pay stable debt
     */
    function unwind() external onlyGovernorOrKeeper {
        _setLeverageConfig(LeverageConfig(BASIS_POINTS + 1, BASIS_POINTS, BASIS_POINTS + 2));
        _liquidate();
    }

    /**
     * @notice Using by the bot to leverage Up if is needed
     */
    function leverageUp(uint256 _stableAmount, uint256 _minGlpOut) external onlyKeeper {
        uint256 availableForBorrowing = stableVault.borrowableAmount(address(this));

        if (availableForBorrowing == 0) {
            return;
        }

        uint256 oldLeverage = leverage();

        _stableAmount = _adjustToGMXCap(_stableAmount);

        if (_stableAmount < 1e4) {
            return;
        }

        if (availableForBorrowing < _stableAmount) {
            _stableAmount = availableForBorrowing;
        }

        uint256 stablesInStrategy = stable.balanceOf(address(this));

        uint256 stableToBorrow = _stableAmount > stablesInStrategy ? _stableAmount - stablesInStrategy : 0;

        if (stableToBorrow > 0) {
            stableVault.borrow(stableToBorrow);
            emit BorrowStable(stableToBorrow);

            stableDebt = stableDebt + stableToBorrow;
        }

        address stableAsset = address(stable);
        IERC20(stableAsset).approve(routerV2.glpManager(), _stableAmount);

        routerV2.mintAndStakeGlp(stableAsset, _stableAmount, 0, _minGlpOut);

        uint256 newLeverage = leverage();

        if (newLeverage > getMaxLeverage()) {
            revert OverLeveraged();
        }

        emit LeverageUp(stableDebt, oldLeverage, newLeverage);
    }

    /**
     * @notice Using by the bot to leverage Down if is needed
     */
    function leverageDown(uint256 _glpAmount, uint256 _minStableOut) external onlyKeeper {
        uint256 oldLeverage = leverage();

        uint256 stablesReceived =
            routerV2.unstakeAndRedeemGlp(address(stable), _glpAmount, _minStableOut, address(this));

        uint256 totalStables = stablesReceived + stable.balanceOf(address(this));

        uint256 currentStableDebt = stableDebt;

        if (totalStables <= currentStableDebt) {
            _repayStable(totalStables);
        } else {
            _repayStable(currentStableDebt);
        }

        uint256 newLeverage = leverage();

        if (newLeverage > oldLeverage) {
            revert OverLeveraged();
        }

        if (newLeverage < getMinLeverage()) {
            revert UnderLeveraged();
        }

        emit LeverageDown(stableDebt, oldLeverage, newLeverage);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  PRIVATE                                   */
    /* -------------------------------------------------------------------------- */

    function _rebalance(uint256 _glpDebt) private {
        uint256 currentLeverage = leverage();

        LeverageConfig memory currentLeverageConfig = leverageConfig;

        if (currentLeverage < currentLeverageConfig.min) {
            uint256 missingGlp = (_glpDebt * (currentLeverageConfig.target - currentLeverage)) / BASIS_POINTS; // 18 Decimals
            (uint256 stableToDeposit,) = _getRequiredStableAmount(missingGlp); // 6 Decimals

            stableToDeposit = _adjustToGMXCap(stableToDeposit);

            if (stableToDeposit < 1e4) {
                return;
            }

            uint256 availableForBorrowing = stableVault.borrowableAmount(address(this));

            if (availableForBorrowing == 0) {
                return;
            }

            if (availableForBorrowing < stableToDeposit) {
                stableToDeposit = availableForBorrowing;
            }

            uint256 stablesInStrategy = stable.balanceOf(address(this));

            uint256 stableToBorrow = stableToDeposit > stablesInStrategy ? stableToDeposit - stablesInStrategy : 0;

            if (stableToBorrow > 0) {
                stableVault.borrow(stableToBorrow);
                emit BorrowStable(stableToBorrow);

                stableDebt = stableDebt + stableToBorrow;
            }

            address stableAsset = address(stable);
            IERC20(stableAsset).approve(routerV2.glpManager(), stableToDeposit);

            routerV2.mintAndStakeGlp(
                stableAsset, stableToDeposit, 0, _applySlippage(_buyGlpStableSimulation(stableToDeposit))
            );

            emit Rebalance(_glpDebt, currentLeverage, leverage(), tx.origin);

            return;
        }

        if (currentLeverage > currentLeverageConfig.max) {
            uint256 excessGlp = (_glpDebt * (currentLeverage - currentLeverageConfig.target)) / BASIS_POINTS;

            (uint256 minStableOut,) = _sellGlpStableSimulation(excessGlp);

            uint256 stablesReceived =
                routerV2.unstakeAndRedeemGlp(address(stable), excessGlp, _applySlippage(minStableOut), address(this));

            uint256 currentStableDebt = stableDebt;

            if (stablesReceived <= currentStableDebt) {
                _repayStable(stablesReceived);
            } else {
                _repayStable(currentStableDebt);
            }

            emit Rebalance(_glpDebt, currentLeverage, leverage(), tx.origin);

            return;
        }

        return;
    }

    function _liquidate() private {
        if (stableDebt == 0) {
            return;
        }

        uint256 glpBalance = glp.balanceOf(address(this));

        (uint256 glpAmount,) = _getRequiredGlpAmount(stableDebt + 2);

        if (glpAmount > glpBalance) {
            glpAmount = glpBalance;
        }

        (uint256 minStableOut,) = _sellGlpStableSimulation(glpAmount);

        uint256 stablesReceived =
            routerV2.unstakeAndRedeemGlp(address(stable), glpAmount, _applySlippage(minStableOut), address(this));

        uint256 currentStableDebt = stableDebt;

        if (stablesReceived <= currentStableDebt) {
            _repayStable(stablesReceived);
        } else {
            _repayStable(currentStableDebt);
        }

        emit Liquidate(stablesReceived);
    }

    function _borrowGlp(uint256 _amount) private returns (uint256) {
        glpVault.borrow(_amount);

        emit BorrowGlp(_amount);

        return _amount;
    }

    function _repayStable(uint256 _amount) internal returns (uint256) {
        stable.approve(address(stableVault), _amount);
        stableVault.payBack(_amount, 0);

        uint256 updatedAmount = stableDebt - _amount;

        stableDebt = updatedAmount;

        return updatedAmount;
    }

    function _setLeverageConfig(LeverageConfig memory _config) private {
        if (
            _config.min >= _config.max || _config.min >= _config.target || _config.max <= _config.target
                || _config.min < BASIS_POINTS
        ) {
            revert InvalidLeverageConfig();
        }

        leverageConfig = _config;
    }

    function _getRequiredGlpAmount(uint256 _stableAmount) private view returns (uint256, uint256) {
        // Working as expected, will get the amount of glp nedeed to get a few less stables than expected
        // If you have to get an amount greater or equal of _stableAmount, use _stableAmount + 2
        IGlpManager manager = glpManager;
        IGMXVault vault = IGMXVault(manager.vault());

        address usdc = address(stable);

        uint256 usdcPrice = vault.getMaxPrice(usdc); // 30 decimals

        uint256 glpSupply = glp.totalSupply();

        uint256 glpPrice = manager.getAum(false).mulDiv(GLP_DECIMALS, glpSupply, Math.Rounding.Down); // 30 decimals

        uint256 usdgAmount = _stableAmount.mulDiv(usdcPrice * BASIS_POINTS, PRECISION, Math.Rounding.Down); // 18 decimals

        uint256 glpAmount = _stableAmount.mulDiv(usdcPrice * BASIS_POINTS, glpPrice, Math.Rounding.Down); // 18 decimals

        uint256 retentionBasisPoints =
            _getGMXBasisRetention(usdc, usdgAmount, vault.mintBurnFeeBasisPoints(), vault.taxBasisPoints(), false);

        uint256 glpRequired = (glpAmount * GMX_BASIS) / (GMX_BASIS - retentionBasisPoints);

        return (glpRequired, retentionBasisPoints);
    }

    function _getRequiredStableAmount(uint256 _glpAmount) private view returns (uint256, uint256) {
        // Working as expected, will get the amount of stables nedeed to get a few less glp than expected
        // If you have to get an amount greater or equal of _glpAmount, use _glpAmount + 2
        IGlpManager manager = glpManager;
        IGMXVault vault = IGMXVault(manager.vault());

        address usdc = address(stable);

        uint256 usdcPrice = vault.getMinPrice(usdc); // 30 decimals

        uint256 glpPrice = manager.getAum(true).mulDiv(GLP_DECIMALS, glp.totalSupply(), Math.Rounding.Down); // 30 decimals

        uint256 stableAmount = _glpAmount.mulDiv(glpPrice, usdcPrice, Math.Rounding.Down); // 18 decimals

        uint256 usdgAmount = _glpAmount.mulDiv(glpPrice, PRECISION, Math.Rounding.Down); // 18 decimals

        uint256 retentionBasisPoints =
            vault.getFeeBasisPoints(usdc, usdgAmount, vault.mintBurnFeeBasisPoints(), vault.taxBasisPoints(), true);

        return ((stableAmount * GMX_BASIS / (GMX_BASIS - retentionBasisPoints)) / BASIS_POINTS, retentionBasisPoints); // 18 decimals
    }

    function _leverage(uint256 _glpAmount) private {
        uint256 missingGlp = ((_glpAmount * (leverageConfig.target - BASIS_POINTS)) / BASIS_POINTS); // 18 Decimals
        (uint256 stableToDeposit,) = _getRequiredStableAmount(missingGlp); // 6 Decimals

        stableToDeposit = _adjustToGMXCap(stableToDeposit);

        if (stableToDeposit < 1e4) {
            return;
        }

        uint256 availableForBorrowing = stableVault.borrowableAmount(address(this));

        if (availableForBorrowing == 0) {
            return;
        }

        if (availableForBorrowing < stableToDeposit) {
            stableToDeposit = availableForBorrowing;
        }

        uint256 stablesInStrategy = stable.balanceOf(address(this));

        uint256 stableToBorrow = stableToDeposit > stablesInStrategy ? stableToDeposit - stablesInStrategy : 0;

        if (stableToBorrow > 0) {
            stableVault.borrow(stableToBorrow);
            emit BorrowStable(stableToBorrow);

            stableDebt = stableDebt + stableToBorrow;
        }

        address stableAsset = address(stable);
        IERC20(stableAsset).approve(routerV2.glpManager(), stableToDeposit);

        uint256 glpMinted = routerV2.mintAndStakeGlp(
            stableAsset, stableToDeposit, 0, _applySlippage(_buyGlpStableSimulation(stableToDeposit))
        );

        emit Leverage(_glpAmount, glpMinted);
    }

    function _deleverage(uint256 _excessGlp) private returns (uint256) {
        (uint256 minStableOut,) = _sellGlpStableSimulation(_excessGlp);

        uint256 stablesReceived =
            routerV2.unstakeAndRedeemGlp(address(stable), _excessGlp, _applySlippage(minStableOut), address(this));

        uint256 currentStableDebt = stableDebt;

        if (stablesReceived <= currentStableDebt) {
            _repayStable(stablesReceived);
        } else {
            _repayStable(currentStableDebt);
        }

        return stablesReceived;
    }

    function _adjustToGMXCap(uint256 _stableAmount) private view returns (uint256) {
        IGlpManager manager = glpManager;
        IGMXVault vault = IGMXVault(manager.vault());

        address _usdc = address(stable);

        uint256 usdgAmount =
            _buyGlpStableSimulation(_stableAmount).mulDiv(manager.getAumInUsdg(false), glp.totalSupply());

        uint256 currentUsdgAmount = vault.usdgAmounts(_usdc);

        uint256 nextAmount = currentUsdgAmount + usdgAmount;
        uint256 maxUsdgAmount = vault.maxUsdgAmounts(_usdc);

        if (nextAmount > maxUsdgAmount) {
            uint256 redemptionAmount = (maxUsdgAmount - currentUsdgAmount).mulDiv(PRECISION, vault.getMaxPrice(_usdc));
            return redemptionAmount.mulDiv(USDC_DECIMALS, GLP_DECIMALS); // 6 decimals
        } else {
            return _stableAmount;
        }
    }

    function _getGMXCapDifference() private view returns (uint256) {
        IGlpManager manager = glpManager;
        IGMXVault vault = IGMXVault(manager.vault());

        address usdc = address(stable);

        uint256 currentUsdgAmount = vault.usdgAmounts(usdc);

        uint256 maxUsdgAmount = vault.maxUsdgAmounts(usdc);

        return maxUsdgAmount - currentUsdgAmount;
    }

    function _buyGlpStableSimulation(uint256 _stableAmount) private view returns (uint256) {
        IGlpManager manager = glpManager;
        IGMXVault vault = IGMXVault(manager.vault());

        address usdc = address(stable);

        uint256 aumInUsdg = manager.getAumInUsdg(true);

        uint256 usdcPrice = vault.getMinPrice(usdc); // 30 decimals

        uint256 usdgAmount = _stableAmount.mulDiv(usdcPrice, PRECISION); // 6 decimals

        usdgAmount = usdgAmount.mulDiv(GLP_DECIMALS, USDC_DECIMALS); // 18 decimals

        uint256 retentionBasisPoints =
            vault.getFeeBasisPoints(usdc, usdgAmount, vault.mintBurnFeeBasisPoints(), vault.taxBasisPoints(), true);

        uint256 amountAfterRetention = _stableAmount.mulDiv(GMX_BASIS - retentionBasisPoints, GMX_BASIS); // 6 decimals

        uint256 mintAmount = amountAfterRetention.mulDiv(usdcPrice, PRECISION); // 6 decimals

        mintAmount = mintAmount.mulDiv(GLP_DECIMALS, USDC_DECIMALS); // 18 decimals

        return aumInUsdg == 0 ? mintAmount : mintAmount.mulDiv(glp.totalSupply(), aumInUsdg); // 18 decimals
    }

    function _buyGlpStableSimulationWhitoutRetention(uint256 _stableAmount) private view returns (uint256) {
        IGlpManager manager = glpManager;
        IGMXVault vault = IGMXVault(manager.vault());

        address usdc = address(stable);

        uint256 aumInUsdg = manager.getAumInUsdg(true);

        uint256 usdcPrice = vault.getMinPrice(usdc); // 30 decimals

        uint256 usdgAmount = _stableAmount.mulDiv(usdcPrice, PRECISION); // 6 decimals

        usdgAmount = usdgAmount.mulDiv(GLP_DECIMALS, USDC_DECIMALS); // 18 decimals

        uint256 mintAmount = _stableAmount.mulDiv(usdcPrice, PRECISION); // 6 decimals

        mintAmount = mintAmount.mulDiv(GLP_DECIMALS, USDC_DECIMALS); // 18 decimals

        return aumInUsdg == 0 ? mintAmount : mintAmount.mulDiv(glp.totalSupply(), aumInUsdg); // 18 decimals
    }

    function _sellGlpStableSimulation(uint256 _glpAmount) private view returns (uint256, uint256) {
        IGlpManager manager = glpManager;
        IGMXVault vault = IGMXVault(manager.vault());

        address usdc = address(stable);

        uint256 usdgAmount = _glpAmount.mulDiv(manager.getAumInUsdg(false), glp.totalSupply());

        uint256 redemptionAmount = usdgAmount.mulDiv(PRECISION, vault.getMaxPrice(usdc));

        redemptionAmount = redemptionAmount.mulDiv(USDC_DECIMALS, GLP_DECIMALS); // 6 decimals

        uint256 retentionBasisPoints =
            _getGMXBasisRetention(usdc, usdgAmount, vault.mintBurnFeeBasisPoints(), vault.taxBasisPoints(), false);

        return (redemptionAmount.mulDiv(GMX_BASIS - retentionBasisPoints, GMX_BASIS), retentionBasisPoints);
    }

    function _glpMintIncentive(uint256 _glpAmount) private view returns (uint256) {
        uint256 amountToMint = _glpAmount.mulDiv(leverageConfig.target - BASIS_POINTS, BASIS_POINTS); // 18 Decimals
        (uint256 stablesNeeded, uint256 gmxIncentive) = _getRequiredStableAmount(amountToMint + 2);
        uint256 incentiveInStables = stablesNeeded.mulDiv(gmxIncentive, GMX_BASIS);
        return _buyGlpStableSimulationWhitoutRetention(incentiveInStables); // retention in glp
    }

    function _glpRedeemRetention(uint256 _glpAmount) private view returns (uint256) {
        uint256 amountToRedeem = _glpAmount.mulDiv(leverageConfig.target - BASIS_POINTS, BASIS_POINTS); //18
        (, uint256 gmxRetention) = _sellGlpStableSimulation(amountToRedeem + 2);
        uint256 retentionInGlp = amountToRedeem.mulDiv(gmxRetention, GMX_BASIS);
        return retentionInGlp;
    }

    function _getGMXBasisRetention(
        address _token,
        uint256 _usdgDelta,
        uint256 _retentionBasisPoints,
        uint256 _taxBasisPoints,
        bool _increment
    ) private view returns (uint256) {
        IGMXVault vault = IGMXVault(glpManager.vault());

        if (!vault.hasDynamicFees()) return _retentionBasisPoints;

        uint256 initialAmount;

        if (_increment) {
            initialAmount = vault.usdgAmounts(_token);
        } else {
            initialAmount = vault.usdgAmounts(_token) > _usdgDelta ? vault.usdgAmounts(_token) - _usdgDelta : 0;
        }

        uint256 nextAmount = initialAmount + _usdgDelta;
        if (!_increment) {
            nextAmount = _usdgDelta > initialAmount ? 0 : initialAmount - _usdgDelta;
        }

        uint256 targetAmount = vault.getTargetUsdgAmount(_token);
        if (targetAmount == 0) return _retentionBasisPoints;

        uint256 initialDiff = initialAmount > targetAmount ? initialAmount - targetAmount : targetAmount - initialAmount;
        uint256 nextDiff = nextAmount > targetAmount ? nextAmount - targetAmount : targetAmount - nextAmount;

        // action improves relative asset balance
        if (nextDiff < initialDiff) {
            uint256 rebateBps = _taxBasisPoints.mulDiv(initialDiff, targetAmount);
            return rebateBps > _retentionBasisPoints ? 0 : _retentionBasisPoints - rebateBps;
        }

        uint256 averageDiff = (initialDiff + nextDiff) / 2;
        if (averageDiff > targetAmount) {
            averageDiff = targetAmount;
        }
        uint256 taxBps = _taxBasisPoints.mulDiv(averageDiff, targetAmount);
        return _retentionBasisPoints + taxBps;
    }

    function _applySlippage(uint256 _amountOut) private view returns (uint256) {
        return _amountOut.mulDiv(slippage, BASIS_POINTS, Math.Rounding.Down);
    }

    event EmergencyWithdrawal(address indexed caller, address indexed receiver, address[] tokens, uint256 nativeBalanc);

    error FailSendETH();
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 Jones DAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

pragma solidity ^0.8.10;

import {JonesBaseGlpVault, ERC4626, IERC4626} from "./JonesBaseGlpVault.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IAggregatorV3} from "../../interfaces/IAggregatorV3.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract JonesGlpStableVault is JonesBaseGlpVault {
    uint256 public constant BASIS_POINTS = 1e12;

    constructor()
        JonesBaseGlpVault(
            IAggregatorV3(0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3),
            IERC20Metadata(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8),
            "USDC Vault Receipt Token",
            "UVRT"
        )
    {}

    // ============================= Public functions ================================ //

    function deposit(uint256 _assets, address _receiver)
        public
        override(JonesBaseGlpVault)
        whenNotPaused
        returns (uint256)
    {
        _validate();
        return super.deposit(_assets, _receiver);
    }

    /**
     * @dev See {openzeppelin-IERC4626-_burn}.
     */
    function burn(address _user, uint256 _amount) public onlyOperator {
        _validate();
        _burn(_user, _amount);
    }

    /**
     * @notice Return total asset deposited
     * @return Amount of asset deposited
     */
    function totalAssets() public view override(ERC4626, IERC4626) returns (uint256) {
        return super.totalAssets() + strategy.stableDebt();
    }

    // ============================= Governor functions ================================ //

    /**
     * @notice Emergency withdraw USDC in this contract
     * @param _to address to send the funds
     */
    function emergencyWithdraw(address _to) external onlyGovernor {
        IERC20 underlyingAsset = IERC20(super.asset());

        uint256 balance = underlyingAsset.balanceOf(address(this));

        if (balance == 0) {
            return;
        }

        underlyingAsset.transfer(_to, balance);
    }

    // ============================= Private functions ================================ //

    function _validate() private {
        uint256 shares = totalSupply() / BASIS_POINTS;
        uint256 assets = totalAssets();
        address stable = asset();

        if (assets > shares) {
            uint256 ratioExcess = assets - shares;
            IERC20(stable).transfer(receiver, ratioExcess);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import {IGMXVault} from "src/interfaces/IGMXVault.sol";
import {JonesGlpVault} from "src/glp/vaults/JonesGlpVault.sol";
import {JonesGlpVaultRouter} from "src/glp/JonesGlpVaultRouter.sol";
import {JonesGlpLeverageStrategy} from "src/glp/strategies/JonesGlpLeverageStrategy.sol";
import {GlpJonesRewards} from "src/glp/rewards/GlpJonesRewards.sol";
import {JonesGlpRewardTracker} from "src/glp/rewards/JonesGlpRewardTracker.sol";
import {JonesGlpStableVault} from "src/glp/vaults/JonesGlpStableVault.sol";
import {JonesGlpCompoundRewards} from "src/glp/rewards/JonesGlpCompoundRewards.sol";
import {WhitelistController} from "src/common/WhitelistController.sol";
import {IWhitelistController} from "src/interfaces/IWhitelistController.sol";
import {IGlpManager, IGMXVault} from "src/interfaces/IGlpManager.sol";
import {IERC4626} from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";
import {IERC20, IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {GlpAdapter} from "src/adapters/GlpAdapter.sol";
import {IAggregatorV3} from "src/interfaces/IAggregatorV3.sol";
import {OwnableUpgradeable} from "openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";

contract jGlpViewer is OwnableUpgradeable {
    using Math for uint256;

    IAggregatorV3 public constant oracle = IAggregatorV3(0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3);

    address public constant usdc = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;

    uint256 public constant PRECISION = 1e30;
    uint256 public constant GMX_BASIS = 1e4;
    uint256 public constant GLP_DECIMALS = 1e18;
    uint256 public constant BASIS_POINTS = 1e12;

    IGlpManager public constant manager = IGlpManager(0x3963FfC9dff443c2A94f21b129D429891E32ec18);
    IERC20 public constant glp = IERC20(0x5402B5F40310bDED796c7D0F3FF6683f5C0cFfdf);

    address public constant usdc_ = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;

    struct Contracts {
        JonesGlpVault glpVault;
        JonesGlpVaultRouter router;
        GlpJonesRewards jonesRewards;
        JonesGlpRewardTracker glpTracker;
        JonesGlpRewardTracker stableTracker;
        JonesGlpLeverageStrategy strategy;
        JonesGlpStableVault stableVault;
        JonesGlpCompoundRewards glpCompounder;
        JonesGlpCompoundRewards stableCompounder;
        IGMXVault gmxVault;
        WhitelistController controller;
        GlpAdapter adapter;
    }

    Contracts public contracts;

    function initialize(Contracts memory _contracts) external initializer {
        __Ownable_init();

        contracts = _contracts;
    }

    // Glp Functions
    // GLP Vault: User deposit GLP are minted GVRT
    // GLP Reward Tracker: Are staked GVRT
    // GLP Compounder: Manage GVRT on behalf of the user are minted jGLP
    function getGlpTvl() public view returns (uint256) {
        (, int256 lastPrice,,,) = oracle.latestRoundData(); //8 decimals
        uint256 totalAssets = getTotalGlp(); // total glp
        uint256 USDC = contracts.strategy.getStableGlpValue(totalAssets); // GMX GLP Redeem for USDC
        return USDC.mulDiv(uint256(lastPrice), 1e8);
    }

    function getTotalGlp() public view returns (uint256) {
        return contracts.glpVault.totalAssets(); //total glp
    }

    function getGlpMaxCap() public view returns (uint256) {
        return contracts.router.getMaxCapGlp();
    }

    function getGlpClaimableRewards(address _user) public view returns (uint256) {
        return contracts.glpTracker.claimable(_user);
    }

    function getGlpPriceUsd() public view returns (uint256) {
        return contracts.strategy.getStableGlpValue(GLP_DECIMALS); // USDC Price of sell 1 glp (1e18)
    }

    function getStakedGVRT(address _user) public view returns (uint256) {
        return contracts.glpTracker.stakedAmount(_user); // GVRT
    }

    function sharesToGlp(uint256 _shares) public view returns (uint256) {
        return contracts.glpVault.previewRedeem(_shares); // GVRT -> GLP
    }

    function getGVRT(uint256 _shares) public view returns (uint256) {
        return contracts.glpCompounder.previewRedeem(_shares); // jGLP -> GVRT
    }

    function getjGlp(address _user) public view returns (uint256) {
        return contracts.glpCompounder.balanceOf(_user); // jGLP
    }

    function getGlp(address _user, bool _compound) public view returns (uint256) {
        uint256 GVRT;
        if (_compound) {
            uint256 jGLP = getjGlp(_user); //jGLP
            GVRT = getGVRT(jGLP); // jGLP -> GVRT
        } else {
            GVRT = getStakedGVRT(_user); // GVRT
        }
        return sharesToGlp(GVRT); // GVRT -> GLP
    }

    function getGlpRatio(uint256 _jGLP) public view returns (uint256) {
        uint256 GVRT = getGVRT(_jGLP); // jGLP -> GVRT
        return sharesToGlp(GVRT); // GVRT -> GLP
    }

    function getGlpRatioWithoutRetention(uint256 _jGLP) public view returns (uint256) {
        uint256 GVRT = getGVRT(_jGLP); // jGLP -> GVRT
        uint256 glpPrice = ((manager.getAum(false) + manager.getAum(true)) / 2).mulDiv(
            GLP_DECIMALS, glp.totalSupply(), Math.Rounding.Down
        ); // 30 decimals
        uint256 glpDebt = contracts.strategy.stableDebt().mulDiv(PRECISION * BASIS_POINTS, glpPrice, Math.Rounding.Down); // 18 decimals
        uint256 strategyGlpBalance = glp.balanceOf(address(contracts.strategy)); // 18 decimals
        if (glpDebt > strategyGlpBalance) {
            return 0;
        }
        uint256 underlyingGlp = strategyGlpBalance - glpDebt; // 18 decimals
        return GVRT.mulDiv(underlyingGlp, contracts.glpVault.totalSupply(), Math.Rounding.Down); // GVRT -> GLP
    }

    // This function do not include the compound() before the redemption
    // which means the shares will be a little lower
    function getPreviewGlpDeposit(uint256 _assets, bool _compound) public view returns (uint256, uint256) {
        uint256 glpMintIncentives = contracts.strategy.glpMintIncentive(_assets);
        uint256 assetsToDeposit = _assets - glpMintIncentives;
        uint256 GVRT = contracts.glpVault.previewDeposit(assetsToDeposit);
        uint256 shares;
        if (_compound) {
            shares = contracts.glpCompounder.previewDeposit(GVRT);
        }
        return (shares, glpMintIncentives);
    }

    // Function to get the GLP amount retained by GMX when the user causes a deleverage(withdrawing)
    function getGMXDeleverageIncentive(uint256 _glpAmount) public view returns (uint256) {
        uint256 USDC_DECIMALS = 1e6;

        uint256 amountToDeleverage =
            _glpAmount.mulDiv(contracts.strategy.getTargetLeverage() - BASIS_POINTS, BASIS_POINTS);

        IGMXVault vault = IGMXVault(manager.vault());

        uint256 usdgAmount = amountToDeleverage.mulDiv(manager.getAumInUsdg(false), glp.totalSupply());

        uint256 retentionBasisPoints =
            _getGMXBasisRetention(usdc_, usdgAmount, vault.mintBurnFeeBasisPoints(), vault.taxBasisPoints(), false);

        return retentionBasisPoints;
    }

    // This function do not include the compound() before the redemption,
    // which means the final amount is a little higher
    function getGlpRedemption(uint256 _jGLP, address _caller) public view returns (uint256, uint256) {
        // GVRT Ratio without compounding
        uint256 GVRT = getGVRT(_jGLP); // jGLP -> GVRT
        uint256 GLP = sharesToGlp(GVRT); // GVRT -> GLP
        uint256 deleverageRetention = contracts.strategy.glpRedeemRetention(GLP); // GMX retention to deleverage
        GLP = GLP - deleverageRetention;

        // Get caller role and incentive retention
        bytes32 role = contracts.controller.getUserRole(_caller);
        IWhitelistController.RoleInfo memory info = contracts.controller.getRoleInfo(role);

        uint256 retention = GLP.mulDiv(info.jGLP_RETENTION, BASIS_POINTS, Math.Rounding.Down); // Protocol retention
        return (GLP - retention, deleverageRetention + retention);
    }

    // USDC Functions
    // USDC Vault: User deposit USDC are minted UVRT
    // USDC Reward Tracker: Are staked UVRT
    // USDC Compounder: Manage UVRT on behalf of the user are minted jUSDC
    function getUSDCTvl() public view returns (uint256) {
        return contracts.stableVault.tvl(); // USDC Price * total USDC
    }

    function getTotalUSDC() public view returns (uint256) {
        return contracts.stableVault.totalAssets(); //total USDC
    }

    function getStakedUVRT(address _user) public view returns (uint256) {
        return contracts.stableTracker.stakedAmount(_user); // UVRT
    }

    function getUSDCClaimableRewards(address _user) public view returns (uint256) {
        return contracts.stableTracker.claimable(_user);
    }

    function sharesToUSDC(uint256 _shares) public view returns (uint256) {
        return contracts.stableVault.previewRedeem(_shares); // jUSDC -> USDC
    }

    function getjUSDC(address _user) public view returns (uint256) {
        return contracts.stableVault.balanceOf(_user); // jUSDC
    }

    function getUSDC(address _user) public view returns (uint256) {
        return getjUSDC(_user); // jUSDC
    }

    function getUSDCRatio(uint256 _jUSDC) public view returns (uint256) {
        return sharesToUSDC(_jUSDC); // jUSDC -> USDC
    }

    // This function do not include the compound() before the redemption
    // which means the shares will be a little lower
    function getPreviewUSDCDeposit(uint256 _assets) public view returns (uint256) {
        return contracts.stableVault.previewDeposit(_assets);
    }

    // This function do not include the compound() before the redemption,
    // which means the final amount is a little higher
    function getUSDCRedemption(uint256 _jUSDC, address _caller) public view returns (uint256, uint256) {
        // GVRT Ratio without compounding
        uint256 USDC = sharesToUSDC(_jUSDC); // jUSDC -> USDC

        uint256 stableVaultBalance = IERC20(usdc_).balanceOf(address(contracts.stableVault));

        uint256 gmxIncentive;

        if (stableVaultBalance < USDC) {
            uint256 difference = USDC - stableVaultBalance;
            gmxIncentive =
                (difference * contracts.strategy.getRedeemStableGMXIncentive(difference) * 1e8) / BASIS_POINTS;
        }

        uint256 remainderStables = USDC - gmxIncentive; // GMX retention to deleverage

        // Get caller role and incentive retention
        bytes32 role = contracts.controller.getUserRole(_caller);
        IWhitelistController.RoleInfo memory info = contracts.controller.getRoleInfo(role);

        uint256 retention = remainderStables.mulDiv(info.jUSDC_RETENTION, BASIS_POINTS, Math.Rounding.Down);

        return (remainderStables - retention, retention + gmxIncentive);
    }

    //Incentive due leverage, happen on every glp deposit
    function getGlpDepositIncentive(uint256 _glpAmount) public view returns (uint256) {
        return contracts.strategy.glpMintIncentive(_glpAmount);
    }

    function getGlpRedeemRetention(uint256 _glpAmount) public view returns (uint256) {
        return contracts.strategy.glpRedeemRetention(_glpAmount); //18 decimals
    }

    function getRedeemStableGMXIncentive(uint256 _stableAmount) public view returns (uint256) {
        return contracts.strategy.getRedeemStableGMXIncentive(_stableAmount);
    }

    // Jones emissiones available rewards

    function getJonesRewards(address _user) public view returns (uint256) {
        return contracts.jonesRewards.rewards(_user);
    }

    // User Role Info

    function getUserRoleInfo(address _user) public view returns (bool, bool, uint256, uint256) {
        bytes32 userRole = contracts.controller.getUserRole(_user);
        IWhitelistController.RoleInfo memory info = contracts.controller.getRoleInfo(userRole);

        return (info.jGLP_BYPASS_CAP, info.jUSDC_BYPASS_TIME, info.jGLP_RETENTION, info.jUSDC_RETENTION);
    }

    // User Withdraw Signal
    function getUserSignal(address _user, uint256 _epoch)
        public
        view
        returns (uint256 targetEpoch, uint256 commitedShares, bool redeemed, bool compound)
    {
        (targetEpoch, commitedShares, redeemed, compound) = contracts.router.withdrawSignal(_user, _epoch);
    }

    // Pause Functions
    function isRouterPaused() public view returns (bool) {
        return contracts.router.paused();
    }

    /*
    function isStableVaultPaused() public view returns (bool) {
        return contracts.stableVault.paused();
    }
    */

    function isGlpVaultPaused() public view returns (bool) {
        return contracts.glpVault.paused();
    }

    //Strategy functions

    function getTargetLeverage() public view returns (uint256) {
        return contracts.strategy.getTargetLeverage();
    }

    function getUnderlyingGlp() public view returns (uint256) {
        return contracts.strategy.getUnderlyingGlp();
    }

    function getStrategyTvl() public view returns (uint256) {
        (, int256 lastPrice,,,) = oracle.latestRoundData(); // 8 decimals
        uint256 totalGlp = glp.balanceOf(address(contracts.strategy)); // 18 decimals
        uint256 USDC = contracts.strategy.getStableGlpValue(totalGlp); // GMX GLP Redeem for USDC 6 decimals
        return USDC.mulDiv(uint256(lastPrice), 1e8);
    }

    function getStableDebt() public view returns (uint256) {
        (, int256 lastPrice,,,) = oracle.latestRoundData(); // 8 decimals
        return contracts.strategy.stableDebt().mulDiv(uint256(lastPrice), 1e8);
    }

    // Current Epoch
    /*
    function currentEpoch() public view returns (uint256) {
        return contracts.router.currentEpoch();
    }
    */

    //Owner functions

    function updateGlpVault(address _newGlpVault) external onlyOwner {
        contracts.glpVault = JonesGlpVault(_newGlpVault);
    }

    function updateGlpVaultRouter(address _newGlpVaultRouter) external onlyOwner {
        contracts.router = JonesGlpVaultRouter(_newGlpVaultRouter);
    }

    function updateGlpRewardTracker(address _newGlpTracker) external onlyOwner {
        contracts.glpTracker = JonesGlpRewardTracker(_newGlpTracker);
    }

    function updateStableRewardTracker(address _newStableTracker) external onlyOwner {
        contracts.stableTracker = JonesGlpRewardTracker(_newStableTracker);
    }

    function updateJonesGlpLeverageStrategy(address _newJonesGlpLeverageStrategy) external onlyOwner {
        contracts.strategy = JonesGlpLeverageStrategy(_newJonesGlpLeverageStrategy);
    }

    function updateJonesGlpStableVault(address _newJonesGlpStableVault) external onlyOwner {
        contracts.stableVault = JonesGlpStableVault(_newJonesGlpStableVault);
    }

    function updatejGlpJonesGlpCompoundRewards(address _newJonesGlpCompoundRewards) external onlyOwner {
        contracts.glpCompounder = JonesGlpCompoundRewards(_newJonesGlpCompoundRewards);
    }

    function updateAdapter(address _newAdapter) external onlyOwner {
        contracts.adapter = GlpAdapter(_newAdapter);
    }

    function updatejUSDCJonesGlpCompoundRewards(address _newJonesUSDCCompoundRewards) external onlyOwner {
        contracts.stableCompounder = JonesGlpCompoundRewards(_newJonesUSDCCompoundRewards);
    }

    function updateJonesRewards(address _jonesRewards) external onlyOwner {
        contracts.jonesRewards = GlpJonesRewards(_jonesRewards);
    }

    function updateDeployment(Contracts memory _contracts) external onlyOwner {
        contracts = _contracts;
    }

    // This amount do not include the withdraw glp retention
    // you have to discount the glp withdraw retentions before using this function
    function previewRedeemGlp(address _token, uint256 _glpAmount) public view returns (uint256, uint256) {
        IGMXVault vault = contracts.gmxVault;

        IERC20Metadata token = IERC20Metadata(_token);

        uint256 usdgAmount = _glpAmount.mulDiv(manager.getAumInUsdg(false), glp.totalSupply()); // 18 decimals

        uint256 redemptionAmount = usdgAmount.mulDiv(PRECISION, vault.getMaxPrice(_token)); // 18 decimals

        redemptionAmount = redemptionAmount.mulDiv(10 ** token.decimals(), GLP_DECIMALS);

        uint256 retentionBasisPoints =
            _getGMXBasisRetention(_token, usdgAmount, vault.mintBurnFeeBasisPoints(), vault.taxBasisPoints(), false);

        return (redemptionAmount.mulDiv(GMX_BASIS - retentionBasisPoints, GMX_BASIS), retentionBasisPoints);
    }

    function previewMintGlp(address _token, uint256 _assetAmount) public view returns (uint256, uint256) {
        IGMXVault vault = contracts.gmxVault;

        IERC20Metadata token = IERC20Metadata(_token);

        uint256 aumInUsdg = manager.getAumInUsdg(true);

        uint256 assetPrice = vault.getMinPrice(_token); // 30 decimals

        uint256 usdgAmount = _assetAmount.mulDiv(assetPrice, PRECISION); // 6 decimals

        usdgAmount = usdgAmount.mulDiv(GLP_DECIMALS, 10 ** token.decimals()); // 18 decimals

        uint256 retentionBasisPoints =
            vault.getFeeBasisPoints(_token, usdgAmount, vault.mintBurnFeeBasisPoints(), vault.taxBasisPoints(), true);

        uint256 amountAfterRetentions = _assetAmount.mulDiv(GMX_BASIS - retentionBasisPoints, GMX_BASIS); // 6 decimals

        uint256 mintAmount = amountAfterRetentions.mulDiv(assetPrice, PRECISION); // 6 decimals

        mintAmount = mintAmount.mulDiv(GLP_DECIMALS, 10 ** token.decimals()); // 18 decimals

        return (aumInUsdg == 0 ? mintAmount : mintAmount.mulDiv(glp.totalSupply(), aumInUsdg), retentionBasisPoints); // 18 decimals
    }

    function getMintGlpIncentive(address _token, uint256 _assetAmount) public view returns (uint256) {
        IGMXVault vault = contracts.gmxVault;

        IERC20Metadata token = IERC20Metadata(_token);

        uint256 assetPrice = vault.getMinPrice(_token); // 30 decimals

        uint256 usdgAmount = _assetAmount.mulDiv(assetPrice, PRECISION); // 6 decimals

        usdgAmount = usdgAmount.mulDiv(GLP_DECIMALS, 10 ** token.decimals()); // 18 decimals

        return vault.getFeeBasisPoints(_token, usdgAmount, vault.mintBurnFeeBasisPoints(), vault.taxBasisPoints(), true);
    }

    function getRedeemGlpRetention(address _token, uint256 _glpAmount) public view returns (uint256) {
        IGMXVault vault = contracts.gmxVault;

        IERC20Metadata token = IERC20Metadata(_token);

        uint256 usdgAmount = _glpAmount.mulDiv(manager.getAumInUsdg(false), glp.totalSupply());

        uint256 redemptionAmount = usdgAmount.mulDiv(PRECISION, vault.getMaxPrice(_token));

        redemptionAmount = redemptionAmount.mulDiv(10 ** token.decimals(), GLP_DECIMALS);

        return _getGMXBasisRetention(_token, usdgAmount, vault.mintBurnFeeBasisPoints(), vault.taxBasisPoints(), false);
    }

    function _getGMXBasisRetention(
        address _token,
        uint256 _usdgDelta,
        uint256 _retentionBasisPoints,
        uint256 _taxBasisPoints,
        bool _increment
    ) private view returns (uint256) {
        IGMXVault vault = contracts.gmxVault;

        if (!vault.hasDynamicFees()) return _retentionBasisPoints;

        uint256 initialAmount;

        if (_increment) {
            initialAmount = vault.usdgAmounts(_token);
        } else {
            initialAmount = vault.usdgAmounts(_token) > _usdgDelta ? vault.usdgAmounts(_token) - _usdgDelta : 0;
        }

        uint256 nextAmount = initialAmount + _usdgDelta;
        if (!_increment) {
            nextAmount = _usdgDelta > initialAmount ? 0 : initialAmount - _usdgDelta;
        }

        uint256 targetAmount = vault.getTargetUsdgAmount(_token);
        if (targetAmount == 0) return _retentionBasisPoints;

        uint256 initialDiff = initialAmount > targetAmount ? initialAmount - targetAmount : targetAmount - initialAmount;
        uint256 nextDiff = nextAmount > targetAmount ? nextAmount - targetAmount : targetAmount - nextAmount;

        // action improves relative asset balance
        if (nextDiff < initialDiff) {
            uint256 rebateBps = _taxBasisPoints.mulDiv(initialDiff, targetAmount);
            return rebateBps > _retentionBasisPoints ? 0 : _retentionBasisPoints - rebateBps;
        }

        uint256 averageDiff = (initialDiff + nextDiff) / 2;
        if (averageDiff > targetAmount) {
            averageDiff = targetAmount;
        }
        uint256 taxBps = _taxBasisPoints.mulDiv(averageDiff, targetAmount);
        return _retentionBasisPoints + taxBps;
    }

    //Use when flexible cap status is TRUE
    //Returns 18 decimals
    function getUsdcCap() public view returns (uint256) {
        return contracts.adapter.getUsdcCap();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20, IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC4626} from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";
import {IGmxRewardRouter} from "../interfaces/IGmxRewardRouter.sol";
import {IGlpManager, IGMXVault} from "../interfaces/IGlpManager.sol";
import {IJonesGlpVaultRouter} from "../interfaces/IJonesGlpVaultRouter.sol";
import {Operable, Governable} from "../common/Operable.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {MerkleProof} from "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import {WhitelistController} from "src/common/WhitelistController.sol";
import {IAggregatorV3} from "src/interfaces/IAggregatorV3.sol";
import {JonesGlpLeverageStrategy} from "src/glp/strategies/JonesGlpLeverageStrategy.sol";
import {JonesGlpStableVault} from "src/glp/vaults/JonesGlpStableVault.sol";

contract GlpAdapter is Operable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IJonesGlpVaultRouter public vaultRouter;
    IGmxRewardRouter public gmxRouter = IGmxRewardRouter(0xB95DB5B167D75e6d04227CfFFA61069348d271F5);
    IAggregatorV3 public oracle = IAggregatorV3(0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3);
    IERC20 public glp = IERC20(0x5402B5F40310bDED796c7D0F3FF6683f5C0cFfdf);
    IERC20 public usdc = IERC20(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
    WhitelistController public controller;
    JonesGlpLeverageStrategy public strategy;
    JonesGlpStableVault public stableVault;
    address public socket;

    uint256 public flexibleTotalCap;
    bool public hatlistStatus;
    bool public useFlexibleCap;

    mapping(address => bool) public isValid;

    uint256 public constant BASIS_POINTS = 1e12;

    constructor(address[] memory _tokens, address _controller, address _strategy, address _stableVault, address _socket)
        Governable(msg.sender)
    {
        uint8 i = 0;
        for (; i < _tokens.length;) {
            _editToken(_tokens[i], true);
            unchecked {
                i++;
            }
        }

        controller = WhitelistController(_controller);
        strategy = JonesGlpLeverageStrategy(_strategy);
        stableVault = JonesGlpStableVault(_stableVault);
        socket = _socket;
    }

    function zapToGlp(address _token, uint256 _amount, bool _compound)
        external
        nonReentrant
        validToken(_token)
        returns (uint256)
    {
        _onlyEOA();

        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        IERC20(_token).approve(gmxRouter.glpManager(), _amount);
        uint256 mintedGlp = gmxRouter.mintAndStakeGlp(_token, _amount, 0, 0);

        glp.approve(address(vaultRouter), mintedGlp);
        uint256 receipts = vaultRouter.depositGlp(mintedGlp, msg.sender, _compound);

        return receipts;
    }

    function zapToGlpEth(bool _compound) external payable nonReentrant returns (uint256) {
        _onlyEOA();

        uint256 mintedGlp = gmxRouter.mintAndStakeGlpETH{value: msg.value}(0, 0);

        glp.approve(address(vaultRouter), mintedGlp);

        uint256 receipts = vaultRouter.depositGlp(mintedGlp, msg.sender, _compound);

        return receipts;
    }

    function redeemGlpBasket(uint256 _shares, bool _compound, address _token, bool _native)
        external
        nonReentrant
        validToken(_token)
        returns (uint256)
    {
        _onlyEOA();

        uint256 assetsReceived = vaultRouter.redeemGlpAdapter(_shares, _compound, _token, msg.sender, _native);

        return assetsReceived;
    }

    function depositGlp(uint256 _assets, bool _compound) external nonReentrant returns (uint256) {
        _onlyEOA();

        glp.transferFrom(msg.sender, address(this), _assets);

        glp.approve(address(vaultRouter), _assets);

        uint256 receipts = vaultRouter.depositGlp(_assets, msg.sender, _compound);

        return receipts;
    }

    function depositStable(uint256 _assets, bool _compound) external nonReentrant returns (uint256) {
        _onlyEOA();

        if (useFlexibleCap) {
            _checkUsdcCap(_assets);
        }

        usdc.transferFrom(msg.sender, address(this), _assets);

        usdc.approve(address(vaultRouter), _assets);

        uint256 receipts = vaultRouter.depositStable(_assets, _compound, msg.sender);

        return receipts;
    }

    // MultiChain Deposits

    function multichainZapToGlp(address _receiver, address _token, bool _compound)
        external
        nonReentrant
        returns (uint256)
    {
        IERC20 token = IERC20(_token);

        uint256 amount = token.allowance(msg.sender, address(this));

        if (amount == 0 || !isValid[_token]) {
            return 0;
        }

        token.transferFrom(msg.sender, address(this), amount);

        if (!_onlySocket()) {
            token.transfer(_receiver, amount);
            return 0;
        }

        if (!_onlyAllowed(_receiver)) {
            return 0;
        }

        address glpManager = gmxRouter.glpManager();
        token.approve(glpManager, amount);

        uint256 mintedGlp;

        try gmxRouter.mintAndStakeGlp(_token, amount, 0, 0) returns (uint256 glpAmount) {
            mintedGlp = glpAmount;
        } catch {
            token.transfer(_receiver, amount);
            token.safeDecreaseAllowance(glpManager, amount);
            return 0;
        }

        address routerAddress = address(vaultRouter);

        glp.approve(routerAddress, mintedGlp);

        try vaultRouter.depositGlp(mintedGlp, _receiver, _compound) returns (uint256 receipts) {
            return receipts;
        } catch {
            glp.transfer(_receiver, mintedGlp);
            glp.approve(routerAddress, 0);
            return 0;
        }
    }

    function multichainZapToGlpEth(address payable _receiver, bool _compound)
        external
        payable
        nonReentrant
        returns (uint256)
    {
        if (msg.value == 0) {
            return 0;
        }

        if (!_onlySocket()) {
            (bool sent,) = _receiver.call{value: msg.value}("");
            if (!sent) {
                revert SendETHFail();
            }
            return 0;
        }

        if (!_onlyAllowed(_receiver)) {
            return 0;
        }

        uint256 mintedGlp;

        try gmxRouter.mintAndStakeGlpETH{value: msg.value}(0, 0) returns (uint256 glpAmount) {
            mintedGlp = glpAmount;
        } catch {
            (bool sent,) = _receiver.call{value: msg.value}("");
            if (!sent) {
                revert SendETHFail();
            }
            return 0;
        }

        address routerAddress = address(vaultRouter);

        glp.approve(routerAddress, mintedGlp);

        try vaultRouter.depositGlp(mintedGlp, _receiver, _compound) returns (uint256 receipts) {
            return receipts;
        } catch {
            glp.transfer(_receiver, mintedGlp);
            glp.approve(routerAddress, 0);
            return 0;
        }
    }

    function multichainDepositStable(address _receiver, bool _compound) external nonReentrant returns (uint256) {
        uint256 amount = usdc.allowance(msg.sender, address(this));

        if (amount == 0) {
            return 0;
        }

        usdc.transferFrom(msg.sender, address(this), amount);

        if (!_onlySocket()) {
            usdc.transfer(_receiver, amount);
            return 0;
        }

        if (!_onlyAllowed(_receiver)) {
            return 0;
        }

        address routerAddress = address(vaultRouter);

        usdc.approve(routerAddress, amount);

        try vaultRouter.depositStable(amount, _compound, _receiver) returns (uint256 receipts) {
            return receipts;
        } catch {
            usdc.transfer(_receiver, amount);
            usdc.safeDecreaseAllowance(routerAddress, amount);
            return 0;
        }
    }

    function rescueFunds(address _token, address _userAddress, uint256 _amount) external onlyGovernor {
        IERC20(_token).safeTransfer(_userAddress, _amount);
    }

    function updateGmxRouter(address _gmxRouter) external onlyGovernor {
        gmxRouter = IGmxRewardRouter(_gmxRouter);
    }

    function updateVaultRouter(address _vaultRouter) external onlyGovernor {
        vaultRouter = IJonesGlpVaultRouter(_vaultRouter);
    }

    function updateStrategy(address _strategy) external onlyGovernor {
        strategy = JonesGlpLeverageStrategy(_strategy);
    }

    function updateSocket(address _socket) external onlyGovernor {
        socket = _socket;
    }

    function toggleHatlist(bool _status) external onlyGovernor {
        hatlistStatus = _status;
    }

    function toggleFlexibleCap(bool _status) external onlyGovernor {
        useFlexibleCap = _status;
    }

    function updateFlexibleCap(uint256 _newAmount) public onlyGovernor {
        //18 decimals -> $1mi = 1_000_000e18
        flexibleTotalCap = _newAmount;
    }

    function getFlexibleCap() public view returns (uint256) {
        return flexibleTotalCap; //18 decimals
    }

    function usingFlexibleCap() public view returns (bool) {
        return useFlexibleCap;
    }

    function usingHatlist() public view returns (bool) {
        return hatlistStatus;
    }

    function getUsdcCap() public view returns (uint256 usdcCap) {
        usdcCap = (flexibleTotalCap * (strategy.getTargetLeverage() - BASIS_POINTS)) / strategy.getTargetLeverage();
    }

    function belowCap(uint256 _amount) public view returns (bool) {
        uint256 increaseDecimals = 10;
        (, int256 lastPrice,,,) = oracle.latestRoundData(); //8 decimals
        uint256 price = uint256(lastPrice) * (10 ** increaseDecimals); //18 DECIMALS
        uint256 usdcCap = getUsdcCap(); //18 decimals
        uint256 stableTvl = stableVault.tvl(); //18 decimals
        uint256 denominator = 1e6;

        uint256 notional = (price * _amount) / denominator;

        if (stableTvl + notional > usdcCap) {
            return false;
        }

        return true;
    }

    function _editToken(address _token, bool _valid) internal {
        isValid[_token] = _valid;
    }

    function _onlyEOA() private view {
        if (msg.sender != tx.origin && !controller.isWhitelistedContract(msg.sender)) {
            revert NotWhitelisted();
        }
    }

    function _onlySocket() private view returns (bool) {
        if (msg.sender == socket) {
            return true;
        }
        return false;
    }

    function _onlyAllowed(address _receiver) private view returns (bool) {
        if (isContract(_receiver) && !controller.isWhitelistedContract(_receiver)) {
            return false;
        }
        return true;
    }

    function isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function _checkUsdcCap(uint256 _amount) private view {
        if (!belowCap(_amount)) {
            revert OverUsdcCap();
        }
    }

    function editToken(address _token, bool _valid) external onlyGovernor {
        _editToken(_token, _valid);
    }

    modifier validToken(address _token) {
        require(isValid[_token], "Invalid token.");
        _;
    }

    error NotHatlisted();
    error OverUsdcCap();
    error NotWhitelisted();
    error SendETHFail();
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 Jones DAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

pragma solidity ^0.8.10;

import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import {Governable, Operable} from "../../common/Operable.sol";
import {IJonesGlpRewardsSplitter} from "../../interfaces/IJonesGlpRewardsSplitter.sol";

contract JonesGlpRewardsSplitter is IJonesGlpRewardsSplitter, Operable {
    using Math for uint256;

    uint256 public constant BASIS_POINTS = 1e12;

    uint256 public jonesPercentage;

    constructor() Governable(msg.sender) {}

    // ============================= Operator functions ================================ //
    /**
     * @inheritdoc IJonesGlpRewardsSplitter
     */
    function splitRewards(uint256 _amount, uint256 _leverage, uint256 _utilization)
        external
        view
        onlyOperator
        returns (uint256, uint256, uint256)
    {
        if (_leverage <= BASIS_POINTS) {
            return (_amount, 0, 0);
        }

        uint256 glpRewards = _amount.mulDiv(BASIS_POINTS, _leverage, Math.Rounding.Down);
        uint256 leverageRewards = _amount - glpRewards; // new 100%
        uint256 jonesRewards = leverageRewards.mulDiv(jonesPercentage, BASIS_POINTS, Math.Rounding.Down); // Jones Rewards
        uint256 stableRewards =
            leverageRewards.mulDiv(_stableRewardsPercentage(_utilization), BASIS_POINTS, Math.Rounding.Down); // Stable Rewards

        if (jonesRewards + stableRewards > leverageRewards) {
            stableRewards = leverageRewards - jonesRewards;
        }

        glpRewards = glpRewards + leverageRewards - jonesRewards - stableRewards;

        return (glpRewards, stableRewards, jonesRewards);
    }

    // ============================= Governor functions ================================ //
    /**
     * @notice Set reward percetage for jones
     * @param _jonesPercentage Jones reward percentage
     */
    function setJonesRewardsPercentage(uint256 _jonesPercentage) external onlyGovernor {
        if (_jonesPercentage > BASIS_POINTS) {
            revert TotalPercentageExceedsMax();
        }
        jonesPercentage = _jonesPercentage;
    }

    // ============================= Private functions ================================ //
    function _stableRewardsPercentage(uint256 _utilization) private pure returns (uint256) {
        // 100%
        if (_utilization == BASIS_POINTS) {
            return BASIS_POINTS.mulDiv(55, 100);
        }

        // [85 - 100[
        if (_utilization >= (85 * BASIS_POINTS) / 100 && _utilization < BASIS_POINTS) {
            return ((80 * _utilization) - (47 * BASIS_POINTS)) / 60;
        }

        // [0 - 85[
        return BASIS_POINTS.mulDiv(35, 100);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {IWhitelistController} from "../interfaces/IWhitelistController.sol";

contract WhitelistController is IWhitelistController, AccessControl, Ownable {
    mapping(bytes32 => IWhitelistController.RoleInfo) public roleInfo;
    mapping(address => bytes32) public userInfo;
    mapping(bytes32 => bool) public roleExists;

    bytes32 private constant INTERNAL = bytes32("INTERNAL");
    bytes32 private constant WHITELISTED_CONTRACTS = bytes32("WHITELISTED_CONTRACTS");
    uint256 public constant BASIS_POINTS = 1e12;

    constructor() {
        IWhitelistController.RoleInfo memory DEFAULT_ROLE = IWhitelistController.RoleInfo(false, false, 3e10, 97e8);

        bytes32 defaultRole = bytes32(0);
        createRole(defaultRole, DEFAULT_ROLE);
    }

    function updateDefaultRole(uint256 _jglpRetention, uint256 _jusdcRetention) public onlyOwner {
        IWhitelistController.RoleInfo memory NEW_DEFAULT_ROLE =
            IWhitelistController.RoleInfo(false, false, _jglpRetention, _jusdcRetention);

        bytes32 defaultRole = bytes32(0);
        createRole(defaultRole, NEW_DEFAULT_ROLE);
    }

    function hasRole(bytes32 role, address account)
        public
        view
        override(IWhitelistController, AccessControl)
        returns (bool)
    {
        return super.hasRole(role, account);
    }

    function isInternalContract(address _account) public view returns (bool) {
        return hasRole(INTERNAL, _account);
    }

    function isWhitelistedContract(address _account) public view returns (bool) {
        return hasRole(WHITELISTED_CONTRACTS, _account);
    }

    function addToRole(bytes32 ROLE, address _account) public onlyOwner validRole(ROLE) {
        _addRoleUser(ROLE, _account);
    }

    function addToInternalContract(address _account) public onlyOwner {
        _grantRole(INTERNAL, _account);
    }

    function addToWhitelistContracts(address _account) public onlyOwner {
        _grantRole(WHITELISTED_CONTRACTS, _account);
    }

    function bulkAddToWhitelistContracts(address[] calldata _accounts) public onlyOwner {
        uint256 length = _accounts.length;
        for (uint8 i = 0; i < length;) {
            _grantRole(WHITELISTED_CONTRACTS, _accounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    function createRole(bytes32 _roleName, IWhitelistController.RoleInfo memory _roleInfo) public onlyOwner {
        roleExists[_roleName] = true;
        roleInfo[_roleName] = _roleInfo;
    }

    function _addRoleUser(bytes32 _role, address _user) internal {
        userInfo[_user] = _role;
    }

    function getUserRole(address _user) public view returns (bytes32) {
        return userInfo[_user];
    }

    function getDefaultRole() public view returns (IWhitelistController.RoleInfo memory) {
        bytes32 defaultRole = bytes32(0);
        return getRoleInfo(defaultRole);
    }

    function getRoleInfo(bytes32 _role) public view returns (IWhitelistController.RoleInfo memory) {
        return roleInfo[_role];
    }

    function removeUserFromRole(address _user) public onlyOwner {
        bytes32 zeroRole = bytes32(0x0);
        userInfo[_user] = zeroRole;
    }

    function removeFromInternalContract(address _account) public onlyOwner {
        _revokeRole(INTERNAL, _account);
    }

    function removeFromWhitelistContract(address _account) public onlyOwner {
        _revokeRole(WHITELISTED_CONTRACTS, _account);
    }

    function bulkRemoveFromWhitelistContract(address[] calldata _accounts) public onlyOwner {
        uint256 length = _accounts.length;
        for (uint8 i = 0; i < length;) {
            _revokeRole(WHITELISTED_CONTRACTS, _accounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    modifier validRole(bytes32 _role) {
        require(roleExists[_role], "Role does not exist!");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IIncentiveReceiver} from "../interfaces/IIncentiveReceiver.sol";
import {OneInchZapLib} from "src/libraries/OneInchZapLib.sol";
import {I1inchAggregationRouterV4} from "src/interfaces/I1inchAggregationRouterV4.sol";
import {Keepable, Governable} from "./Keepable.sol";

contract IncentiveReceiver is IIncentiveReceiver, Keepable {
    using OneInchZapLib for I1inchAggregationRouterV4;

    I1inchAggregationRouterV4 internal router;

    // Registry of allowed depositors
    mapping(address => bool) public depositors;

    // Registry of allowed tokens
    mapping(address => bool) public destinationTokens;

    address public leverageStrategy;

    /**
     * @param _governor The address of the owner of this contract
     */
    constructor(address _governor, address payable _router) Governable(_governor) {
        router = I1inchAggregationRouterV4(_router);
    }

    /**
     * @notice To enforce only allowed depositors to deposit funds
     */
    modifier onlyDepositors() {
        if (!depositors[msg.sender]) {
            revert NotAuthorized();
        }
        _;
    }

    /**
     * @notice Used by depositors to deposit incentives
     * @param _token the address of the asset to be deposited
     * @param _amount the amount of `_token` to deposit
     */
    function deposit(address _token, uint256 _amount) external onlyDepositors {
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        emit Deposit(msg.sender, _token, _amount);
    }

    /**
     * @notice Used to register new depositors
     * @param _depositor the address of the new depositor
     */
    function addDepositor(address _depositor) external onlyGovernor {
        _isValidAddress(_depositor);

        depositors[_depositor] = true;

        emit DepositorAdded(msg.sender, _depositor);
    }

    function addToken(address _token) external onlyGovernor {
        _isValidAddress(_token);

        destinationTokens[_token] = true;

        emit TokenAdded(msg.sender, _token);
    }

    /**
     * @notice Used to remove depositors
     * @param _depositor the address of the depositor to remove
     */
    function removeDepositor(address _depositor) external onlyGovernor {
        depositors[_depositor] = false;

        emit DepositorRemoved(msg.sender, _depositor);
    }

    function removeToken(address _token) external onlyGovernor {
        destinationTokens[_token] = false;

        emit TokenRemoved(msg.sender, _token);
    }

    function updateRouter(address payable _router) external onlyGovernor {
        _isValidAddress(_router);

        address oldRouter = address(router);

        router = I1inchAggregationRouterV4(_router);

        emit UpdateRouter(oldRouter, _router);
    }

    function updateStrategy(address _strategy) external onlyGovernor {
        _isValidAddress(_strategy);

        address oldStrategy = leverageStrategy;

        leverageStrategy = _strategy;

        emit UpdateStrategy(oldStrategy, _strategy);
    }

    function swap(OneInchZapLib.SwapParams calldata _swapParams) external onlyKeeper {
        _isWhitelisted(_swapParams.desc.dstToken);

        OneInchZapLib.SwapParams memory swap = _swapParams;
        if (swap.desc.dstReceiver != address(this)) {
            revert InvalidReceiver();
        }

        router.perform1InchSwap(swap);
    }

    function sendsGLP(bool _all, uint256 _amount) external onlyKeeper {
        IERC20 sGLP = IERC20(0x5402B5F40310bDED796c7D0F3FF6683f5C0cFfdf);

        if (_all) {
            uint256 balance = sGLP.balanceOf(address(this));
            sGLP.transfer(leverageStrategy, balance);

            return;
        }

        sGLP.transfer(leverageStrategy, _amount);
    }

    /**
     * @notice Moves assets from the strategy to `_to`
     * @param _assets An array of IERC20 compatible tokens to move out from the strategy
     * @param _withdrawNative `true` if we want to move the native asset from the strategy
     */
    function withdraw(address _to, address[] memory _assets, bool _withdrawNative) external onlyGovernor {
        _isValidAddress(_to);

        for (uint256 i; i < _assets.length; i++) {
            IERC20 asset = IERC20(_assets[i]);
            uint256 assetBalance = asset.balanceOf(address(this));

            // No need to transfer
            if (assetBalance == 0) {
                continue;
            }

            // Transfer the ERC20 tokens
            asset.transfer(_to, assetBalance);
        }

        uint256 nativeBalance = address(this).balance;

        // Nothing else to do
        if (_withdrawNative && nativeBalance > 0) {
            // Transfer the native currency
            payable(_to).transfer(nativeBalance);
        }

        emit Withdrawal(msg.sender, _to, _assets, _withdrawNative);
    }

    function _isValidAddress(address _address) internal pure {
        if (_address == address(0)) {
            revert InvalidAddress();
        }
    }

    function _isWhitelisted(address _token) internal view {
        if (!destinationTokens[_token]) {
            revert NotWhitelisted();
        }
    }

    /**
     * @notice Emitted when a depositor deposits incentives
     * @param depositor the contract that deposited
     * @param token the address of the asset that was deposited
     * @param amount the amount of `token` that was deposited
     */
    event Deposit(address indexed depositor, address indexed token, uint256 amount);

    /**
     * @notice Emitted when a new depositor is registered
     * @param owner the current owner of this contract
     * @param depositor the address of the new depositor
     */
    event DepositorAdded(address indexed owner, address indexed depositor);
    event TokenAdded(address indexed owner, address indexed token);
    event UpdateRouter(address indexed oldAddress, address indexed newAddress);
    event UpdateStrategy(address indexed oldAddress, address indexed newAddress);

    /**
     * @notice Emitted when a new depositor is registered
     * @param owner the current owner of this contract
     * @param depositor the address of the new depositor
     */
    event DepositorRemoved(address indexed owner, address indexed depositor);
    event TokenRemoved(address indexed owner, address indexed depositor);

    event Withdrawal(address owner, address receiver, address[] assets, bool includeNative);

    error NotAuthorized();
    error InvalidAddress();
    error NotWhitelisted();
    error InvalidReceiver();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";

abstract contract Governable is AccessControl {
    bytes32 public constant GOVERNOR = bytes32("GOVERNOR");

    constructor(address _governor) {
        _grantRole(GOVERNOR, _governor);
    }

    modifier onlyGovernor() {
        _onlyGovernor();
        _;
    }

    function updateGovernor(address _newGovernor) external onlyGovernor {
        _revokeRole(GOVERNOR, msg.sender);
        _grantRole(GOVERNOR, _newGovernor);

        emit GovernorUpdated(msg.sender, _newGovernor);
    }

    function _onlyGovernor() private view {
        if (!hasRole(GOVERNOR, msg.sender)) {
            revert CallerIsNotGovernor();
        }
    }

    event GovernorUpdated(address _oldGovernor, address _newGovernor);

    error CallerIsNotGovernor();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IGmxRewardRouter {
    function mintAndStakeGlp(address _token, uint256 _amount, uint256 _minUsdg, uint256 _minGlp)
        external
        returns (uint256);

    function unstakeAndRedeemGlp(address _tokenOut, uint256 _glpAmount, uint256 _minOut, address _receiver)
        external
        returns (uint256);

    function unstakeAndRedeemGlpETH(uint256 _glpAmount, uint256 _minOut, address payable _receiver)
        external
        returns (uint256);

    function glpManager() external view returns (address);

    function handleRewards(
        bool _shouldClaimGmx,
        bool _shouldStakeGmx,
        bool _shouldClaimEsGmx,
        bool _shouldStakeEsGmx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth
    ) external;

    function signalTransfer(address _receiver) external;
    function acceptTransfer(address _sender) external;
    function pendingReceivers(address input) external returns (address);
    function stakeEsGmx(uint256 _amount) external;
    function mintAndStakeGlpETH(uint256 _minUsdg, uint256 _minGlp) external payable returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IGMXVault} from "./IGMXVault.sol";

interface IGlpManager {
    function getAum(bool _maximize) external view returns (uint256);
    function getAumInUsdg(bool _maximize) external view returns (uint256);
    function vault() external view returns (address);
    function glp() external view returns (address);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface IGMXVault {
    function whitelistedTokens(address) external view returns (bool);

    function stableTokens(address) external view returns (bool);

    function shortableTokens(address) external view returns (bool);

    function getMaxPrice(address _token) external view returns (uint256);

    function getMinPrice(address _token) external view returns (uint256);

    function getPosition(address _account, address _collateralToken, address _indexToken, bool _isLong)
        external
        view
        returns (uint256, uint256, uint256, uint256, uint256, uint256, bool, uint256);

    function mintBurnFeeBasisPoints() external view returns (uint256);

    function taxBasisPoints() external view returns (uint256);

    function getFeeBasisPoints(
        address _token,
        uint256 _usdgDelta,
        uint256 _feeBasisPoints,
        uint256 _taxBasisPoints,
        bool _increment
    ) external view returns (uint256);

    function usdgAmounts(address _token) external view returns (uint256);
    function maxUsdgAmounts(address _token) external view returns (uint256);
    function hasDynamicFees() external view returns (bool);
    function getTargetUsdgAmount(address _token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IJonesGlpVaultRouter {
    function depositGlp(uint256 _assets, address _sender, bool _compound) external returns (uint256);
    function depositStable(uint256 _assets, bool _compound, address _user) external returns (uint256);
    function redeemGlpAdapter(uint256 _shares, bool _compound, address _token, address _user, bool _native)
        external
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IJonesGlpLeverageStrategy {
    /**
     * @notice React to a GLP deposit, borrow GLO from Vault & relabance
     * @param _amount Amount of GLP deposited
     */
    function onGlpDeposit(uint256 _amount) external;

    /**
     * @notice React to a GLP compound, borrow GLP from Vault
     * @param _amount Amount of GLP deposited
     */
    function onGlpCompound(uint256 _amount) external;

    /**
     * @notice React to a GLP redeem, pay stable debt if is need and transfer GLP to the user
     * @param _amount Amount that the user is attempting to redeem
     * @return Amount of GLP to redeem
     */
    function onGlpRedeem(uint256 _amount) external returns (uint256);

    /**
     * @notice Redeem GLP for stables
     * @param _amount Amount of stables to reduce from debt
     * @param _amountAfterRetention Amount of stables getting from redeem GLP
     * @return Amount of stables getting from redeem GLP
     */
    function onStableRedeem(uint256 _amount, uint256 _amountAfterRetention) external returns (uint256);

    /**
     * @notice Claim GLP rewards from GMX and split them
     */
    function claimGlpRewards() external;

    /**
     * @notice Return the current utilization of stable Vault
     * @dev Precision is based on 1e12 as 100% percent
     * @return The % of utilization
     */
    function utilization() external view returns (uint256);

    /**
     * @notice Return the current GLP leverage position
     * @dev Precision is based on 1e12 as 1x leverage
     * @return Leverage position
     */
    function leverage() external view returns (uint256);

    /**
     * @notice Return the amount of GLP that represent 1x of leverage
     * @return Amount of GLP
     */
    function getUnderlyingGlp() external view returns (uint256);

    /**
     * @notice Return the stable debt
     * @return Amount of stable debt
     */
    function stableDebt() external view returns (uint256);

    /**
     * @notice Get the stable value of sell _amount of GLP
     * @param _glpAmount Amount of GLP
     * @return Stables getting from _glpAmount of GLP
     */
    function getStableGlpValue(uint256 _glpAmount) external view returns (uint256);

    /**
     * @notice Get the simulated GLP amount minted with USDC
     * @param _stableAmount Amount of USDC
     * @return Stables Amount of simulated GLP
     */
    function buyGlpStableSimulation(uint256 _stableAmount) external view returns (uint256);

    /**
     * @notice Get the required USDC amount to mint _glpAmount of GLP
     * @param _glpAmount Amount of GLP to be minted
     * @return Amount of stables required to mint _glpAmount of GLP
     */
    function getRequiredStableAmount(uint256 _glpAmount) external view returns (uint256);

    /**
     * @notice Get the simulated GLP amount required to redeem _stableAmount of USDC
     * @param _stableAmount Amount of USDC
     * @return Stables Amount of simulated GLP amount required to redeem _stableAmount of USDC
     */
    function getRequiredGlpAmount(uint256 _stableAmount) external view returns (uint256);

    /**
     * @notice Get the simulated GLP mint retention on a glp deposit
     * @param _glpAmount Amount of GLP deposited
     * @return GLP Amount of retention
     */
    function glpMintIncentive(uint256 _glpAmount) external view returns (uint256);

    /**
     * @notice Get GMX incentive to redeem stables
     * @param _stableAmount Amount of stables
     * @return GMX retention to redeem stables
     */
    function getRedeemStableGMXIncentive(uint256 _stableAmount) external view returns (uint256);

    /**
     * @notice Return max leverage configuration
     * @return Max leverage
     */
    function getMaxLeverage() external view returns (uint256);

    /**
     * @notice Return min leverage configuration
     * @return Min leverage
     */
    function getMinLeverage() external view returns (uint256);

    /**
     * @notice Return target leverage configuration
     * @return Target leverage
     */
    function getTargetLeverage() external view returns (uint256);

    /**
     * @notice Return the amount of GLP to reach the GMX cap for USDC
     * @return Cap Difference
     */
    function getGMXCapDifference() external view returns (uint256);

    /**
     * @notice Get the simulated GLP redeem retention on a glp redeem
     * @param _glpAmount Amount of GLP redeemed
     * @return GLP Amount of retention
     */
    function glpRedeemRetention(uint256 _glpAmount) external view returns (uint256);

    /**
     * @notice Check if leverage will be triggered on glp deposit
     * @param _glpAmount Amount of GLP redeemed
     */
    function leverageOnDeposit(uint256 _glpAmount) external view returns (bool);

    event Rebalance(
        uint256 _glpDebt, uint256 indexed _currentLeverage, uint256 indexed _newLeverage, address indexed _sender
    );
    event GetUnderlyingGlp(uint256 _amount);
    event SetLeverageConfig(uint256 _target, uint256 _min, uint256 _max);
    event ClaimGlpRewards(
        address indexed _origin,
        address indexed _sender,
        uint256 _rewards,
        uint256 _timestamp,
        uint256 _leverage,
        uint256 _glpBalance,
        uint256 _underlyingGlp,
        uint256 _glpShares,
        uint256 _stableDebt,
        uint256 _stableShares
    );

    event Liquidate(uint256 indexed _stablesReceived);
    event BorrowGlp(uint256 indexed _amount);
    event BorrowStable(uint256 indexed _amount);
    event RepayStable(uint256 indexed _amount);
    event RepayGlp(uint256 indexed _amount);
    event EmergencyWithdraw(address indexed _to, uint256 indexed _amount);
    event UpdateStableAddress(address _oldStableAddress, address _newStableAddress);
    event UpdateGlpAddress(address _oldGlpAddress, address _newGlpAddress);
    event Leverage(uint256 _glpDeposited, uint256 _glpMinted);
    event LeverageUp(uint256 _stableDebt, uint256 _oldLeverage, uint256 _currentLeverage);
    event LeverageDown(uint256 _stableDebt, uint256 _oldLeverage, uint256 _currentLeverage);
    event Deleverage(uint256 _glpAmount, uint256 _glpRedeemed);

    error ZeroAddressError();
    error InvalidLeverageConfig();
    error InvalidSlippage();
    error ReachedSlippageTolerance();
    error OverLeveraged();
    error UnderLeveraged();
    error NotEnoughUnderlyingGlp();
    error UnWind();
    error NotEnoughStables();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IStableRouter {
    struct Request {
        uint256 assets;
        uint256 shares;
        uint256 timestamp;
    }

    function deposit(uint256 _assets, address _receiver) external returns (uint256);
    function multichainDeposit(address _receiver) external returns (uint256);
    function withdrawRequest(uint256 _shares, address _receiver, bytes calldata _enforceData)
        external
        returns (uint256);
    function cancelWithdrawRequest(address _receiver) external returns (uint256);
    function withdraw(bytes calldata _enforceData) external returns (uint256);
    function redeemStable(uint256 _epoch, uint256 _minAmountOut, bytes calldata _enforceData)
        external
        returns (uint256);
    function migratePosition() external returns (uint256, uint256);

    function withdrawRequests(address _user) external view returns (uint256, uint256, uint256);
    function totalWithdrawRequests() external view returns (uint256);

    function incentiveReceiver() external view returns (address);
    function withdrawCooldown() external view returns (uint256);

    event Deposit(address indexed owner, uint256 assets, address receiver, uint256 shares);
    event WithdrawRequest(address indexed owner, address receiver, uint256 assets);
    event CancelWithdrawRequest(address indexed owner, address receiver, uint256 assets, uint256 shares);
    event Withdraw(address indexed owner, uint256 assets, address receiver, uint256 retention);
    event MigratePosition(
        address indexed owner, uint256 oldAssets, uint256 oldjUSDC, uint256 newAssets, uint256 newjUSDC
    );
    event EmergencyWithdrawal(address indexed caller, address indexed receiver, address[] tokens, uint256 nativeBalanc);

    error ZeroAmount();
    error InsufficientFunds();
    error CooldownNotMeet();
    error FailSendETH();
    error AlreadyRedemeed();
    error AlreadyCalled();
    error NotRightCaller();
    error CallerIsNotWhitelisted();
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

// Check https://docs.jonesdao.io/jones-dao/other/bounty for details on our bounty program.

pragma solidity ^0.8.10;

import {UpgradeableGovernable} from "src/common/UpgradeableGovernable.sol";

abstract contract UpgradeableOperable is UpgradeableGovernable {
    /**
     * @notice Operator role
     */
    bytes32 public constant OPERATOR = bytes32("OPERATOR");

    /**
     * @notice Modifier if msg.sender has not Operator role revert.
     */
    modifier onlyOperator() {
        if (!hasRole(OPERATOR, msg.sender)) {
            revert CallerIsNotOperator();
        }

        _;
    }

    /**
     * @notice Only msg.sender with OPERATOR or GOVERNOR role can call the function.
     */
    modifier onlyGovernorOrOperator() {
        if (!(hasRole(GOVERNOR, msg.sender) || hasRole(OPERATOR, msg.sender))) {
            revert CallerIsNotAllowed();
        }

        _;
    }

    /**
     * @notice Grant Operator role to _newOperator.
     */
    function addOperator(address _newOperator) external onlyGovernor {
        _grantRole(OPERATOR, _newOperator);

        emit OperatorAdded(_newOperator);
    }

    /**
     * @notice Remove Operator role from _operator.
     */
    function removeOperator(address _operator) external onlyGovernor {
        _revokeRole(OPERATOR, _operator);

        emit OperatorRemoved(_operator);
    }

    event OperatorAdded(address _newOperator);
    event OperatorRemoved(address _operator);

    error CallerIsNotOperator();
    error CallerIsNotAllowed();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb computation, we are able to compute `result = 2**(k/2)` which is a
        // good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z) // Like multiplying by 2 ** 64.
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z) // Like multiplying by 2 ** 32.
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z) // Like multiplying by 2 ** 16.
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z) // Like multiplying by 2 ** 8.
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z) // Like multiplying by 2 ** 4.
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z) // Like multiplying by 2 ** 2.
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";
import "../token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 *
 * _Available since v4.7._
 */
interface IERC4626 is IERC20, IERC20Metadata {
    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

// Check https://docs.jonesdao.io/jones-dao/other/bounty for details on our bounty program.

pragma solidity ^0.8.10;

import {AccessControlUpgradeable} from "openzeppelin-upgradeable/contracts/access/AccessControlUpgradeable.sol";

abstract contract UpgradeableGovernable is AccessControlUpgradeable {
    /**
     * @notice Governor role
     */
    bytes32 public constant GOVERNOR = bytes32("GOVERNOR");

    /**
     * @notice Initialize Governable contract.
     */
    function __Governable_init(address _governor) internal onlyInitializing {
        __AccessControl_init();
        _grantRole(GOVERNOR, _governor);
    }

    /**
     * @notice Modifier if msg.sender has not Governor role revert.
     */
    modifier onlyGovernor() {
        _onlyGovernor();
        _;
    }

    /**
     * @notice Update Governor Role
     */
    function updateGovernor(address _newGovernor) external virtual onlyGovernor {
        _revokeRole(GOVERNOR, msg.sender);
        _grantRole(GOVERNOR, _newGovernor);

        emit GovernorUpdated(msg.sender, _newGovernor);
    }

    /**
     * @notice If msg.sender has not Governor role revert.
     */
    function _onlyGovernor() private view {
        if (!hasRole(GOVERNOR, msg.sender)) {
            revert CallerIsNotGovernor();
        }
    }

    event GovernorUpdated(address _oldGovernor, address _newGovernor);

    error CallerIsNotGovernor();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

abstract contract Pausable {
    bool private _paused;
    bool private _emergencyPaused;

    constructor() {
        _paused = false;
        _emergencyPaused = false;
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    function emergencyPaused() public view returns (bool) {
        return _emergencyPaused;
    }

    function _requireNotPaused() internal view {
        if (paused()) {
            revert ErrorPaused();
        }
    }

    function _requireNotEmergencyPaused() internal view {
        if (emergencyPaused()) {
            revert ErrorEmergencyPaused();
        }
    }

    function _pause() internal whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    function _unpause() internal whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    function _emergencyPause() internal whenNotEmergencyPaused {
        _paused = true;
        _emergencyPaused = true;
        emit EmergencyPaused(msg.sender);
    }

    function _emergencyUnpause() internal whenEmergencyPaused {
        _emergencyPaused = false;
        _paused = false;
        emit EmergencyUnpaused(msg.sender);
    }

    modifier whenPaused() {
        if (!paused()) {
            revert ErrorNotPaused();
        }
        _;
    }

    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    modifier whenEmergencyPaused() {
        if (!emergencyPaused()) {
            revert ErrorNotEmergencyPaused();
        }
        _;
    }

    modifier whenNotEmergencyPaused() {
        _requireNotEmergencyPaused();
        _;
    }

    event Paused(address _account);
    event Unpaused(address _account);
    event EmergencyPaused(address _account);
    event EmergencyUnpaused(address _account);

    error ErrorPaused();
    error ErrorEmergencyPaused();
    error ErrorNotPaused();
    error ErrorNotEmergencyPaused();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IUnderlyingVault {
    function burn(address account, uint256 shares) external;
    function mint(uint256 shares, address receiver) external returns (uint256);
    function withdraw(uint256 assets, address receiver, address /*owner*/ ) external returns (uint256);

    function receiveRewards(uint256 amount) external;
    function borrow(uint256 amount) external;
    function payBack(uint256 amount, uint256 incentives) external;
    function enforcePayBack(uint256 amount, bytes calldata enforceData) external returns (uint256);

    function transfer(address user, uint256 amount) external returns (bool);
    function decimals() external returns (uint256);

    function retentionRefund(uint256 amount, bytes memory enforceData) external view returns (uint256);
    function balanceOf(address user) external view returns (uint256);

    function previewDeposit(uint256 assets) external view returns (uint256);
    function previewRedeem(uint256 shares) external view returns (uint256);
    function borrowableAmount(address strategy) external view returns (uint256);
    function cap(address strategy) external view returns (uint256);
    function totalAssets() external view returns (uint256);
    function totalSupply() external view returns (uint256);

    function loaned(address strategy) external view returns (uint256);

    function underlying() external view returns (IERC20);

    function initialize(address _asset, address _enforceHub, string calldata _name, string calldata _symbol) external;

    function addOperator(address _newOperator) external;

    function addKeeper(address _newKeeper) external;

    function addStrategy(address _newOperator, uint256 _cap) external;

    function updateDebt(address _strategy, uint256 _amount, bool _substract) external;

    function hasRole(bytes32 role, address account) external view returns (bool);

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */

    event EmergencyWithdrawal(address indexed caller, address indexed receiver, address[] tokens, uint256 nativeBalanc);
    event ReceiveRewards(address indexed sender, uint256 amount, uint256 totalAssets, uint256 totalSupply);
    event Borrowed(address indexed to, uint256 amount, uint256 totalDebt);
    event PayBack(address indexed from, uint256 amount, uint256 incentives, uint256 totalDebt);
    event EnforcePayback(uint256 amount, uint256 retention, uint256 totalAssets, uint256 totalDebt);

    /* -------------------------------------------------------------------------- */
    /*                                    ERRORS                                   */
    /* -------------------------------------------------------------------------- */

    error NotEnoughFunds();
    error CallerIsNotStrategy();
    error FailSendETH();
    error NotRightCaller();
    error CapReached();
    error StalePrice();
    error InvalidPrice();
    error StalePriceUpdate();
    error SequencerDown();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IJonesGlpRewardTracker {
    event Stake(address indexed depositor, uint256 amount);
    event Withdraw(address indexed _account, uint256 _amount);
    event Claim(address indexed receiver, uint256 amount);
    event UpdateRewards(address indexed _account, uint256 _rewards, uint256 _totalShares, uint256 _rewardPerShare);

    /**
     * @notice Stake into this contract assets to start earning rewards
     * @param _account Owner of the stake and future rewards
     * @param _amount Assets to be staked
     * @return Amount of assets staked
     */
    function stake(address _account, uint256 _amount) external returns (uint256);

    /**
     * @notice Withdraw the staked assets
     * @param _account Owner of the assets to be withdrawn
     * @param _amount Assets to be withdrawn
     * @return Amount of assets witdrawed
     */
    function withdraw(address _account, uint256 _amount) external returns (uint256);

    /**
     * @notice Claim _account cumulative rewards
     * @dev Reward token will be transfer to the _account
     * @param _account Owner of the rewards
     * @return Amount of reward tokens transferred
     */
    function claim(address _account) external returns (uint256);

    /**
     * @notice Return _account claimable rewards
     * @dev No reward token are transferred
     * @param _account Owner of the rewards
     * @return Amount of reward tokens that can be claim
     */
    function claimable(address _account) external view returns (uint256);

    /**
     * @notice Return _account staked amount
     * @param _account Owner of the staking
     * @return Staked amount
     */
    function stakedAmount(address _account) external view returns (uint256);

    /**
     * @notice Update global cumulative reward
     * @dev No reward token are transferred
     */
    function updateRewards() external;

    /**
     * @notice Deposit rewards
     * @dev Transfer from called here
     * @param _rewards Amount of reward asset transferer
     */
    function depositRewards(uint256 _rewards) external;

    error AddressCannotBeZeroAddress();
    error AmountCannotBeZero();
    error AmountExceedsStakedAmount();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IJonesGlpCompoundRewards {
    event Deposit(address indexed _caller, address indexed receiver, uint256 _assets, uint256 _shares);
    event Withdraw(address indexed _caller, address indexed receiver, uint256 _assets, uint256 _shares);
    event Compound(uint256 _rewards, uint256 _totalAssets, uint256 _retentions);

    /**
     * @notice Deposit assets into this contract and get shares
     * @param assets Amount of assets to be deposit
     * @param receiver Address Owner of the deposit
     * @return Amount of shares minted
     */
    function deposit(uint256 assets, address receiver) external returns (uint256);

    /**
     * @notice Withdraw the deposited assets
     * @param shares Amount to shares to be burned to get the assets
     * @param receiver Address who will receive the assets
     * @return Amount of assets redemeed
     */
    function redeem(uint256 shares, address receiver) external returns (uint256);

    /**
     * @notice Claim cumulative rewards & stake them
     */
    function compound() external;

    /**
     * @notice Preview how many shares will obtain when deposit
     * @param assets Amount to shares to be deposit
     * @return Amount of shares to be minted
     */
    function previewDeposit(uint256 assets) external view returns (uint256);

    /**
     * @notice Preview how many assets will obtain when redeem
     * @param shares Amount to shares to be redeem
     * @return Amount of assets to be redeemed
     */
    function previewRedeem(uint256 shares) external view returns (uint256);

    /**
     * @notice Convert recipent compounded assets into un-compunding assets
     * @param assets Amount to be converted
     * @param recipient address of assets owner
     * @return Amount of un-compounding assets
     */
    function totalAssetsToDeposits(address recipient, uint256 assets) external view returns (uint256);

    error AddressCannotBeZeroAddress();
    error AmountCannotBeZero();
    error AmountExceedsStakedAmount();
    error RetentionPercentageOutOfRange();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IWhitelistController {
    struct RoleInfo {
        bool jGLP_BYPASS_CAP;
        bool jUSDC_BYPASS_TIME;
        uint256 jGLP_RETENTION;
        uint256 jUSDC_RETENTION;
    }

    function isInternalContract(address _account) external view returns (bool);
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getUserRole(address _user) external view returns (bytes32);
    function getRoleInfo(bytes32 _role) external view returns (IWhitelistController.RoleInfo memory);
    function getDefaultRole() external view returns (IWhitelistController.RoleInfo memory);
    function isWhitelistedContract(address _account) external view returns (bool);
    function addToInternalContract(address _account) external;
    function addToWhitelistContracts(address _account) external;
    function removeFromInternalContract(address _account) external;
    function removeFromWhitelistContract(address _account) external;
    function bulkAddToWhitelistContracts(address[] calldata _accounts) external;
    function bulkRemoveFromWhitelistContract(address[] calldata _accounts) external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

interface IIncentiveReceiver {
    function deposit(address _token, uint256 _amount) external;

    function addDepositor(address _depositor) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

interface IViewer {
    function getUSDCTvl() external view returns (uint256);
    function usdc_() external view returns (address);
}

//SPDX-License-Identifier:  MIT
pragma solidity ^0.8.10;

interface Errors {
    error AlreadyInitialized();
    error CallerIsNotInternalContract();
    error CallerIsNotWhitelisted();
    error InvalidWithdrawalRetention();
    error MaxGlpTvlReached();
    error CannotSettleEpochInFuture();
    error EpochAlreadySettled();
    error EpochNotSettled();
    error WithdrawalAlreadyCompleted();
    error WithdrawalWithNoShares();
    error WithdrawalSignalAlreadyDone();
    error NotRightEpoch();
    error NotEnoughStables();
    error NoEpochToSettle();
    error CannotCancelWithdrawal();
    error AddressCannotBeZeroAddress();
    error OnlyAdapter();
    error OnlyAuthorized();
    error DoesntHavePermission();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IJonesGlpRewardDistributor {
    event Distribute(uint256 amount);
    event SplitRewards(uint256 _glpRewards, uint256 _stableRewards, uint256 _jonesRewards);

    /**
     * @notice Send the pool rewards to the tracker
     * @dev This function is called from the Reward Tracker
     * @return Amount of rewards sent
     */
    function distributeRewards() external returns (uint256);

    /**
     * @notice Split the rewards comming from GMX
     * @param _amount of rewards to be splited
     * @param _leverage current strategy leverage
     * @param _utilization current stable pool utilization
     */
    function splitRewards(uint256 _amount, uint256 _leverage, uint256 _utilization) external;

    /**
     * @notice Return the pending rewards to be distributed of a pool
     * @param _pool Address of the Reward Tracker pool
     * @return Amount of pending rewards
     */
    function pendingRewards(address _pool) external view returns (uint256);

    error AddressCannotBeZeroAddress();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IJonesGlpRewardsSplitter {
    /**
     * @notice Split the rewards comming from GMX
     * @param _amount of rewards to be splited
     * @param _leverage current strategy leverage
     * @param _utilization current stable pool utilization
     * @return Rewards splited in three, GLP rewards, Stable Rewards & Jones Rewards
     */
    function splitRewards(uint256 _amount, uint256 _leverage, uint256 _utilization)
        external
        returns (uint256, uint256, uint256);

    error TotalPercentageExceedsMax();
    error InvalidNumber();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// token swapper for Butter (tokenin => Butter)
interface ITokenSwapper {
    function swap(address tokenIn, uint256 amountIn, address tokenOut, uint256 minAmountOut, bytes memory externalData)
        external
        returns (uint256 amountOut);

    error EmptyTokenIn();
    error EmptyTokenOut();
    error EmptyRouter();
    error EmptyPath();
    error InvalidPathSegment(address from, address next);
    error InvalidAmountIn(uint256 amountIn, uint256 referenceAmount);
    error InvalidMinAmountOut(uint256 minAmountOut, uint256 referenceAmount);
    error InvalidTokenIn(address tokenIn, address referenceToken);
    error InvalidTokenOut(address tokenOut, address referenceToken);
    error InvalidReceiver(address receiver, address referenceReceiver);
    error Slippage(uint256 amountOut, uint256 minAmountOut);
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

// Check https://docs.jonesdao.io/jones-dao/other/bounty for details on our bounty program.

pragma solidity ^0.8.10;

import {UpgradeableGovernable} from "src/common/UpgradeableGovernable.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {IV3SwapRouter} from "src/interfaces/swap/IV3SwapRouter.sol";
import {IUniswapV3Pool} from "src/interfaces/swap/IUniswapV3Pool.sol";
import {ITokenSwapper} from "src/interfaces/swap/ITokenSwapper.sol";
import {UniV3Library} from "src/libraries/UniV3Library.sol";

contract UniswapV3Swapper is UpgradeableGovernable, ITokenSwapper {
    using FixedPointMathLib for uint256;
    using SafeERC20 for IERC20;

    struct SwapPair {
        address from;
        address to;
        uint24 fee;
    }

    /// @notice Uni V3 Router
    IV3SwapRouter private constant V3_ROUTER = IV3SwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    /// @notice Uni V3 Factory
    address private constant UNISWAP_V3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

    /// @notice Uni V3 Pool Code Hash
    bytes32 private constant UNISWAP_POOL_INIT_CODE_HASH =
        0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /// @notice input token => output token => swap route
    mapping(address => mapping(address => bytes)) public tokenSwapPaths;

    /// @notice input token => output token => pairs
    mapping(address => mapping(address => SwapPair[])) public pairs;

    int24 public ticksMin;

    uint256 public threshold;

    /// @notice Math Precision
    uint256 public constant PRECISION = 1e30;

    function initialize() external initializer {
        __Governable_init(msg.sender);
        ticksMin = 300; // 5 minutes
        threshold = PRECISION.mulDivDown(1, 1000); // 0.1%
    }

    /**
     * @notice Update Ticks time frame to calculate price.
     */
    function updateTicksMin(int24 _minutes) external onlyGovernor {
        ticksMin = _minutes * 60;
    }

    /**
     * @notice Update price threshold to conclude if a pool is manipulated
     *  1e30 == 100%
     */
    function updateThreshold(uint256 _threshold) external onlyGovernor {
        threshold = _threshold;
    }

    /**
     * @notice Updates the swap path for the given inputToken and outputToken pair.
     * @param inputToken The input token of the custom swap route.
     * @param outputToken The output token of the custom swap route.
     * @param swapRoute An array of SwapPair objects representing the new swap path for the given inputToken and outputToken pair.
     * @dev Only the contract owner can call this function.
     */
    function upsertPathOverride(address inputToken, address outputToken, SwapPair[] calldata swapRoute)
        external
        onlyGovernor
    {
        if (inputToken == address(0)) revert EmptyTokenIn();
        if (outputToken == address(0)) revert EmptyTokenOut();
        if (swapRoute.length == 0) revert EmptyPath();

        tokenSwapPaths[inputToken][outputToken] = _composeSwapPath(swapRoute, inputToken, outputToken);
    }

    /**
     * @notice Removes a custom swap route for a specific input-output token pair.
     * @param inputToken The input token of the custom swap route to be removed.
     * @param outputToken The output token of the custom swap route to be removed.
     * @dev Only the contract owner can call this function.
     */
    function removePathOverride(address inputToken, address outputToken) external onlyGovernor {
        delete tokenSwapPaths[inputToken][outputToken];
        delete pairs[inputToken][outputToken];
    }

    /**
     * @notice Returns the serialized swap route between the `inputToken` and `outputToken` as bytes data.
     * @param inputToken The input token in the swap route.
     * @param outputToken The output token in the swap route.
     * @return swapRoute The serialized swap route between the `inputToken` and `outputToken`.
     */
    function getSwapPath(address inputToken, address outputToken) public view returns (bytes memory swapRoute) {
        return tokenSwapPaths[inputToken][outputToken];
    }

    /**
     * @notice Returns the pairs swap route between the `inputToken` and `outputToken`.
     * @param inputToken The input token in the swap route.
     * @param outputToken The output token in the swap route.
     * @return The SwapPair struct route between the `inputToken` and `outputToken`.
     */
    function getPairs(address inputToken, address outputToken) public view returns (SwapPair[] memory) {
        return pairs[inputToken][outputToken];
    }

    /**
     * @notice Swaps the specified amount of `tokenIn` for `tokenOut`.
     * @param tokenIn The address of the input token.
     * @param amountIn The amount of the input token to be swapped.
     * @param tokenOut The address of the output token.
     * @param minAmountOut The minimum amount of the output token to be returned.
     * @return amountOut The amount of the output token returned.
     * @dev If the amount of `tokenOut` returned is less than `minAmountOut`, the transaction reverts.
     */
    function swap(address tokenIn, uint256 amountIn, address tokenOut, uint256 minAmountOut, bytes memory data)
        external
        override
        returns (uint256 amountOut)
    {
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenIn).safeApprove(address(V3_ROUTER), amountIn);

        if (minAmountOut == 0) {
            (uint256 slippage, uint256 basis) = abi.decode(data, (uint256, uint256));
            minAmountOut = _applySlippage(_minAmountOut(tokenIn, tokenOut, amountIn), slippage, basis);
        }

        IV3SwapRouter.ExactInputParams memory params;
        params.recipient = msg.sender;
        params.amountIn = amountIn;
        params.amountOutMinimum = minAmountOut;
        params.path = tokenSwapPaths[tokenIn][tokenOut];
        params.deadline = type(uint256).max;

        amountOut = V3_ROUTER.exactInput(params);

        IERC20(tokenIn).safeApprove(address(V3_ROUTER), 0);
    }

    /**
     * @notice Composes a swapPath from a given swapRoute.
     * The swapPath consists of the encoded addresses of the SwapPairs in the swapRoute as well as the fees associated with each swap.
     * @param swapRoute The swapRoute to be composed into a swapPath.
     * @return swapPath The resulting swapPath after composing the swapRoute.
     * @dev Checks that the from address of each SwapPair matches the to address of the previous SwapPair in the swapRoute.
     * If the from address of a SwapPair does not match the to address of the previous SwapPair, it reverts with an error.
     */
    function _composeSwapPath(SwapPair[] calldata swapRoute, address tokenIn, address tokenOut)
        private
        returns (bytes memory swapPath)
    {
        swapPath = abi.encodePacked(swapRoute[0].from);
        uint256 srl = swapRoute.length;
        for (uint256 i; i < srl;) {
            pairs[tokenIn][tokenOut].push(
                SwapPair({from: swapRoute[i].from, to: swapRoute[i].to, fee: swapRoute[i].fee})
            );
            swapPath = abi.encodePacked(swapPath, swapRoute[i].fee, swapRoute[i].to);
            if (i > 0) {
                unchecked {
                    // i > 0 in check above so i - 1 cannot underflow
                    if (swapRoute[i].from != swapRoute[i - 1].to) {
                        revert InvalidPathSegment(swapRoute[i].from, swapRoute[i - 1].to);
                    }
                }
            }

            unchecked {
                // i < srl cannot overflow
                ++i;
            }
        }
    }

    function _minAmountOut(address tokenIn, address tokenOut, uint256 amountIn) private view returns (uint256) {
        SwapPair[] memory _pairs = pairs[tokenIn][tokenOut];
        uint256 length = _pairs.length;
        uint256 min;

        for (uint256 i; i < length;) {
            IUniswapV3Pool pool = UniV3Library.getPool(
                UNISWAP_V3_FACTORY, _pairs[i].from, _pairs[i].to, _pairs[i].fee, UNISWAP_POOL_INIT_CODE_HASH
            );

            // Get TWAP of token0 quoted in token1.
            min = _checkManipulation(address(pool));

            address tokenA = pool.token0();

            if (tokenA == _pairs[i].from) {
                // Calculate min amount based of current TWAP price
                min = amountIn.mulDivDown(min, 10 ** IERC20Metadata(tokenA).decimals());
            } else {
                min = amountIn.mulDivDown(10 ** IERC20Metadata(tokenA).decimals(), min);
            }

            amountIn = min;

            unchecked {
                // i < length cannot overflow
                ++i;
            }
        }

        return min;
    }

    function _applySlippage(uint256 _amount, uint256 _slippage, uint256 _basis) private pure returns (uint256) {
        return _amount.mulDivDown(_slippage, _basis);
    }

    /**
     * @notice Check pool manipulation. check if the price change "too much" (base on threshold) in X time.
     * @param pool UniswapV3 Pool.
     * @return spot TWAP price of token0 quoted in token1.
     */
    function _checkManipulation(address pool) private view returns (uint256 spot) {
        spot = UniV3Library.getSpot(pool);

        uint256 mean = UniV3Library.getPrice(pool, ticksMin);

        uint256 diff;

        if (mean > spot) {
            diff = (mean - spot).mulDivDown(PRECISION, (spot + mean) / 2);
        } else {
            diff = (spot - mean).mulDivDown(PRECISION, (spot + mean) / 2);
        }

        if (diff > threshold) {
            revert PoolManipulated();
        }
    }

    error PoolManipulated();
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

// Check https://docs.jonesdao.io/jones-dao/other/bounty for details on our bounty program.

pragma solidity ^0.8.20;

import {IGenericRouter, IAggregationExecutor, IERC20} from "src/interfaces/swap/IGenericRouter.sol";
import {ITokenSwapper} from "src/interfaces/swap/ITokenSwapper.sol";

contract OneInchV5Swapper is ITokenSwapper {
    struct SwapParams {
        address executor;
        address srcToken;
        address dstToken;
        address srcReceiver;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
        bytes permit;
        bytes data;
    }

    IGenericRouter public router;

    address executor = 0xE37e799D5077682FA0a244D46E5649F71457BD09;

    constructor(address _router) {
        router = IGenericRouter(payable(_router));
    }

    /*
    * @param externalData A bytes value containing the encoded swap parameters.
    * @return The actual amount of `tokenOut` received in the swap.
    */
    function swap(address tokenIn, uint256 amountIn, address tokenOut, uint256 minAmountOut, bytes memory externalData)
        external
        returns (uint256 amountOut)
    {
        SwapParams memory _swap;

        (_swap.executor, _swap.srcToken, _swap.dstToken,,, _swap.amount, _swap.minReturnAmount,,, _swap.data) = abi
            .decode(externalData, (address, address, address, address, address, uint256, uint256, uint256, bytes, bytes));

        if (tokenIn != _swap.srcToken) {
            revert InvalidTokenIn(tokenIn, _swap.srcToken);
        }

        if (amountIn < _swap.amount) {
            revert InvalidAmountIn(amountIn, _swap.amount);
        }

        if (tokenOut != _swap.dstToken) {
            revert InvalidTokenOut(tokenOut, _swap.dstToken);
        }

        if (minAmountOut > _swap.minReturnAmount) {
            revert InvalidMinAmountOut(minAmountOut, _swap.minReturnAmount);
        }

        IERC20(_swap.srcToken).transferFrom(msg.sender, address(this), _swap.amount);
        IERC20(_swap.srcToken).approve(address(router), _swap.amount);

        (amountOut,) = router.swap(
            IAggregationExecutor(_swap.executor),
            IGenericRouter.SwapDescription({
                srcToken: IERC20(_swap.srcToken),
                dstToken: IERC20(_swap.dstToken),
                srcReceiver: payable(_swap.executor),
                dstReceiver: payable(address(this)),
                amount: _swap.amount,
                minReturnAmount: _swap.minReturnAmount,
                flags: 4
            }),
            "",
            _swap.data
        );

        IERC20(_swap.dstToken).transfer(msg.sender, amountOut);

        return amountOut;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {Governable} from "./Governable.sol";

abstract contract Operable is Governable {
    bytes32 public constant OPERATOR = bytes32("OPERATOR");

    modifier onlyOperator() {
        if (!hasRole(OPERATOR, msg.sender)) {
            revert CallerIsNotOperator();
        }

        _;
    }

    function addOperator(address _newOperator) external onlyGovernor {
        _grantRole(OPERATOR, _newOperator);

        emit OperatorAdded(_newOperator);
    }

    function removeOperator(address _operator) external onlyGovernor {
        _revokeRole(OPERATOR, _operator);

        emit OperatorRemoved(_operator);
    }

    event OperatorAdded(address _newOperator);
    event OperatorRemoved(address _operator);

    error CallerIsNotOperator();
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

pragma solidity ^0.8.10;

import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Operable, Governable} from "src/common/Operable.sol";
import {IJonesGlpOldRewards} from "src/interfaces/IJonesGlpOldRewards.sol";

contract GlpJonesRewards is Operable, ReentrancyGuard {
    IERC20 public immutable rewardsToken;

    // Duration of rewards to be paid out (in seconds)
    uint256 public duration;
    // Timestamp of when the rewards finish
    uint256 public finishAt;
    // Minimum of last updated time and reward finish time
    uint256 public updatedAt;
    // Reward to be paid out per second
    uint256 public rewardRate;
    // Sum of (reward rate * dt * 1e18 / total supply)
    uint256 public rewardPerTokenStored;
    // User address => rewardPerTokenStored
    mapping(address => uint256) public userRewardPerTokenPaid;
    // User address => rewards to be claimed
    mapping(address => uint256) public rewards;

    // Total staked
    uint256 public totalSupply;
    // User address => staked amount
    mapping(address => uint256) public balanceOf;

    IJonesGlpOldRewards oldReward;

    constructor(address _rewardToken, address _oldJonesRewards) Governable(msg.sender) ReentrancyGuard() {
        rewardsToken = IERC20(_rewardToken);
        oldReward = IJonesGlpOldRewards(_oldJonesRewards);
    }

    // ============================= Modifiers ================================ //

    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        updatedAt = lastTimeRewardApplicable();

        if (_account != address(0)) {
            uint256 oldBalance = oldReward.balanceOf(_account);
            if (oldBalance > 0) {
                oldReward.getReward(_account);
                oldReward.withdraw(_account, oldBalance);
                balanceOf[_account] += oldBalance;
                totalSupply += oldBalance;
                emit Stake(_account, oldBalance);
            }
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }

        _;
    }

    // ============================= Operator functions ================================ //

    /**
     * @notice Virtual Stake, an accountability of the deposit
     * @dev No asset are transferred here is it just the accountability
     * @param _user Address of depositor
     * @param _amount Amount deposited
     */
    function stake(address _user, uint256 _amount) external onlyOperator updateReward(_user) {
        if (_amount > 0) {
            balanceOf[_user] += _amount;
            totalSupply += _amount;
        }
        emit Stake(_user, _amount);
    }

    /**
     * @notice Virtual withdraw, an accountability of the withdraw
     * @dev No asset have to be transfer here is it just the accountability
     * @param _user Address of withdrawal
     * @param _amount Amount to withdraw
     */
    function withdraw(address _user, uint256 _amount) external onlyOperator updateReward(_user) {
        if (_amount > 0) {
            balanceOf[_user] -= _amount;
            totalSupply -= _amount;
        }

        emit Withdraw(_user, _amount);
    }

    /**
     * @notice Transfer respective rewards, Jones emissions, to the _user address
     * @param _user Address where the rewards are transferred
     * @return Amount of rewards, Jones emissions
     */
    function getReward(address _user) external onlyOperator updateReward(_user) nonReentrant returns (uint256) {
        uint256 reward = rewards[_user];
        if (reward > 0) {
            rewards[_user] = 0;
            rewardsToken.transfer(_user, reward);
        }

        emit GetReward(_user, reward);

        return reward;
    }

    // ============================= Public functions ================================ //

    /**
     * @notice Return the last time a reward was applie
     * @return Timestamp when the last reward happened
     */
    function lastTimeRewardApplicable() public view returns (uint256) {
        return _min(finishAt, block.timestamp);
    }

    /**
     * @notice Return the amount of reward per tokend deposited
     * @return Amount of rewards, jones emissions
     */
    function rewardPerToken() public view returns (uint256) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }

        return rewardPerTokenStored + (rewardRate * (lastTimeRewardApplicable() - updatedAt) * 1e18) / totalSupply;
    }

    /**
     * @notice Return the total jones emissions earned by an user
     * @return Total emissions earned
     */
    function earned(address _user) public view returns (uint256) {
        return ((balanceOf[_user] * (rewardPerToken() - userRewardPerTokenPaid[_user])) / 1e18) + rewards[_user];
    }

    // ============================= Governor functions ================================ //

    /**
     * @notice Set the duration of the rewards
     * @param _duration timestamp based duration
     */
    function setRewardsDuration(uint256 _duration) external onlyGovernor {
        if (block.timestamp <= finishAt) {
            revert DurationNotFinished();
        }

        duration = _duration;

        emit UpdateRewardsDuration(finishAt, _duration + block.timestamp);
    }

    /**
     * @notice Notify Reward Amount for a specific _amount
     * @param _amount AMount to calculate the rewards
     */
    function notifyRewardAmount(uint256 _amount) external onlyGovernor updateReward(address(0)) {
        if (block.timestamp >= finishAt) {
            rewardRate = _amount / duration;
        } else {
            uint256 remainingRewards = (finishAt - block.timestamp) * rewardRate;
            rewardRate = (_amount + remainingRewards) / duration;
        }

        if (rewardRate == 0) {
            revert ZeroRewardRate();
        }
        if (rewardRate * duration > rewardsToken.balanceOf(address(this))) {
            revert NotEnoughBalance();
        }

        finishAt = block.timestamp + duration;
        updatedAt = block.timestamp;

        emit NotifyRewardAmount(_amount, finishAt);
    }

    // ============================= Private functions ================================ //
    function _min(uint256 x, uint256 y) private pure returns (uint256) {
        return x <= y ? x : y;
    }

    // ============================= Events ================================ //

    event Stake(address indexed _to, uint256 _amount);
    event Withdraw(address indexed _to, uint256 _amount);
    event GetReward(address indexed _to, uint256 _rewards);
    event UpdateRewardsDuration(uint256 _oldEnding, uint256 _newEnding);
    event NotifyRewardAmount(uint256 _amount, uint256 _finishAt);

    // ============================= Errors ================================ //

    error ZeroRewardRate();
    error NotEnoughBalance();
    error DurationNotFinished();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Governable} from "./Governable.sol";

abstract contract OperableKeepable is Governable {
    bytes32 public constant OPERATOR = bytes32("OPERATOR");
    bytes32 public constant KEEPER = bytes32("KEEPER");

    modifier onlyOperator() {
        if (!hasRole(OPERATOR, msg.sender)) {
            revert CallerIsNotOperator();
        }

        _;
    }

    modifier onlyKeeper() {
        if (!hasRole(KEEPER, msg.sender)) {
            revert CallerIsNotKeeper();
        }

        _;
    }

    modifier onlyOperatorOrKeeper() {
        if (!(hasRole(OPERATOR, msg.sender) || hasRole(KEEPER, msg.sender))) {
            revert CallerIsNotAllowed();
        }

        _;
    }

    modifier onlyGovernorOrKeeper() {
        if (!(hasRole(GOVERNOR, msg.sender) || hasRole(KEEPER, msg.sender))) {
            revert CallerIsNotAllowed();
        }

        _;
    }

    function addOperator(address _newOperator) external onlyGovernor {
        _grantRole(OPERATOR, _newOperator);

        emit OperatorAdded(_newOperator);
    }

    function removeOperator(address _operator) external onlyGovernor {
        _revokeRole(OPERATOR, _operator);

        emit OperatorRemoved(_operator);
    }

    function addKeeper(address _newKeeper) external onlyGovernor {
        _grantRole(KEEPER, _newKeeper);

        emit KeeperAdded(_newKeeper);
    }

    function removeKeeper(address _operator) external onlyGovernor {
        _revokeRole(KEEPER, _operator);

        emit KeeperRemoved(_operator);
    }

    event OperatorAdded(address _newOperator);
    event OperatorRemoved(address _operator);

    error CallerIsNotOperator();

    event KeeperAdded(address _newKeeper);
    event KeeperRemoved(address _operator);

    error CallerIsNotKeeper();

    error CallerIsNotAllowed();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IJonesGlpRewardsSwapper {
    event Swap(address indexed _tokenIn, uint256 _amountIn, address indexed _tokenOut, uint256 _amountOut);

    /**
     * @notice Swap eth rewards to USDC
     * @param _amountIn amount of rewards to swap
     * @return amount of USDC swapped
     */
    function swapRewards(uint256 _amountIn) external returns (uint256);

    /**
     * @notice Return min amount out of USDC due a weth in amount considering the slippage tolerance
     * @param _amountIn amount of weth rewards to swap
     * @return min output amount of USDC
     */
    function minAmountOut(uint256 _amountIn) external view returns (uint256);

    error InvalidSlippage();
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 Jones DAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

pragma solidity ^0.8.10;

import {ERC4626} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {JonesUsdVault} from "../../vaults/JonesUsdVault.sol";
import {JonesBorrowableVault} from "../../vaults/JonesBorrowableVault.sol";
import {JonesOperableVault} from "../../vaults/JonesOperableVault.sol";
import {JonesGovernableVault} from "../../vaults/JonesGovernableVault.sol";
import {IAggregatorV3} from "../../interfaces/IAggregatorV3.sol";
import {IStakedGlp} from "../../interfaces/IStakedGlp.sol";
import {IJonesGlpLeverageStrategy} from "../../interfaces/IJonesGlpLeverageStrategy.sol";

abstract contract JonesBaseGlpVault is JonesOperableVault, JonesUsdVault, JonesBorrowableVault {
    IJonesGlpLeverageStrategy public strategy;
    address internal receiver;

    constructor(IAggregatorV3 _oracle, IERC20Metadata _asset, string memory _name, string memory _symbol)
        JonesGovernableVault(msg.sender)
        JonesUsdVault(_oracle)
        ERC4626(_asset)
        ERC20(_name, _symbol)
    {}

    // ============================= Operable functions ================================ //

    /**
     * @dev See {openzeppelin-IERC4626-deposit}.
     */
    function deposit(uint256 _assets, address _receiver)
        public
        virtual
        override(JonesOperableVault, ERC4626, IERC4626)
        whenNotPaused
        returns (uint256)
    {
        return super.deposit(_assets, _receiver);
    }

    /**
     * @dev See {openzeppelin-IERC4626-mint}.
     */
    function mint(uint256 _shares, address _receiver)
        public
        override(JonesOperableVault, ERC4626, IERC4626)
        whenNotPaused
        returns (uint256)
    {
        return super.mint(_shares, _receiver);
    }

    /**
     * @dev See {openzeppelin-IERC4626-withdraw}.
     */
    function withdraw(uint256 _assets, address _receiver, address _owner)
        public
        virtual
        override(JonesOperableVault, ERC4626, IERC4626)
        returns (uint256)
    {
        return super.withdraw(_assets, _receiver, _owner);
    }

    /**
     * @dev See {openzeppelin-IERC4626-redeem}.
     */
    function redeem(uint256 _shares, address _receiver, address _owner)
        public
        virtual
        override(JonesOperableVault, ERC4626, IERC4626)
        returns (uint256)
    {
        return super.redeem(_shares, _receiver, _owner);
    }

    /**
     * @notice Set new strategy address
     * @param _strategy Strategy Contract
     */
    function setStrategyAddress(IJonesGlpLeverageStrategy _strategy) external onlyGovernor {
        strategy = _strategy;
    }

    function setExcessReceiver(address _receiver) external onlyGovernor {
        receiver = _receiver;
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
pragma solidity ^0.8.10;

interface IAggregatorV3 {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IStakedGlp {
    function stakedGlpTracker() external view returns (address);
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
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

// Check https://docs.jonesdao.io/jones-dao/other/bounty for details on our bounty program.

pragma solidity ^0.8.10;

import {UpgradeableGovernable} from "src/common/UpgradeableGovernable.sol";

abstract contract UpgradeableOperableKeepable is UpgradeableGovernable {
    bytes32 public constant OPERATOR = bytes32("OPERATOR");
    bytes32 public constant KEEPER = bytes32("KEEPER");

    modifier onlyOperator() {
        if (!hasRole(OPERATOR, msg.sender)) {
            revert CallerIsNotOperator();
        }

        _;
    }

    modifier onlyKeeper() {
        if (!hasRole(KEEPER, msg.sender)) {
            revert CallerIsNotKeeper();
        }

        _;
    }

    modifier onlyOperatorOrKeeper() {
        if (!(hasRole(OPERATOR, msg.sender) || hasRole(KEEPER, msg.sender))) {
            revert CallerIsNotAllowed();
        }

        _;
    }

    modifier onlyGovernorOrKeeper() {
        if (!(hasRole(GOVERNOR, msg.sender) || hasRole(KEEPER, msg.sender))) {
            revert CallerIsNotAllowed();
        }

        _;
    }

    /**
     * @notice Only msg.sender with OPERATOR or GOVERNOR role can call the function.
     */
    modifier onlyGovernorOrOperator() {
        if (!(hasRole(GOVERNOR, msg.sender) || hasRole(OPERATOR, msg.sender))) {
            revert CallerIsNotAllowed();
        }

        _;
    }

    function addOperator(address _newOperator) external onlyGovernor {
        _grantRole(OPERATOR, _newOperator);

        emit OperatorAdded(_newOperator);
    }

    function removeOperator(address _operator) external onlyGovernor {
        _revokeRole(OPERATOR, _operator);

        emit OperatorRemoved(_operator);
    }

    function addKeeper(address _newKeeper) external onlyGovernor {
        _grantRole(KEEPER, _newKeeper);

        emit KeeperAdded(_newKeeper);
    }

    function removeKeeper(address _operator) external onlyGovernor {
        _revokeRole(KEEPER, _operator);

        emit KeeperRemoved(_operator);
    }

    event OperatorAdded(address _newOperator);
    event OperatorRemoved(address _operator);

    error CallerIsNotOperator();

    event KeeperAdded(address _newKeeper);
    event KeeperRemoved(address _operator);

    error CallerIsNotKeeper();

    error CallerIsNotAllowed();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC4626} from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";

interface IJonesBorrowableVault is IERC4626 {
    function borrow(uint256 _amount) external returns (uint256);
    function repay(uint256 _amount) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IAggregatorV3} from "./IAggregatorV3.sol";

interface IJonesUsdVault {
    function priceOracle() external view returns (IAggregatorV3);
    function tvl() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IRewardTracker {
    function depositBalances(address _account, address _depositToken) external view returns (uint256);
    function stakedAmounts(address _account) external view returns (uint256);
    function updateRewards() external;
    function stake(address _depositToken, uint256 _amount) external;
    function stakeForAccount(address _fundingAccount, address _account, address _depositToken, uint256 _amount)
        external;
    function unstake(address _depositToken, uint256 _amount) external;
    function unstakeForAccount(address _account, address _depositToken, uint256 _amount, address _receiver) external;
    function tokensPerInterval() external view returns (uint256);
    function claim(address _receiver) external returns (uint256);
    function claimForAccount(address _account, address _receiver) external returns (uint256);
    function claimable(address _account) external view returns (uint256);
    function averageStakedAmounts(address _account) external view returns (uint256);
    function cumulativeRewards(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IPayBack {
    function payBack(uint256 amount, bytes calldata enforceData) external returns (uint256);

    function retentionRefund(uint256 amount, bytes calldata enforceData) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 Jones DAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

pragma solidity ^0.8.10;

import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {Governable, OperableKeepable} from "src/common/OperableKeepable.sol";
import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IJonesBorrowableVault} from "src/interfaces/IJonesBorrowableVault.sol";
import {IJonesUsdVault} from "src/interfaces/IJonesUsdVault.sol";
import {IJonesGlpRewardDistributor} from "src/interfaces/IJonesGlpRewardDistributor.sol";
import {IAggregatorV3} from "src/interfaces/IAggregatorV3.sol";
import {IGmxRewardRouter} from "src/interfaces/IGmxRewardRouter.sol";
import {IJonesGlpLeverageStrategy} from "src/interfaces/IJonesGlpLeverageStrategy.sol";
import {IGlpManager} from "src/interfaces/IGlpManager.sol";
import {IGMXVault} from "src/interfaces/IGMXVault.sol";
import {IRewardTracker} from "src/interfaces/IRewardTracker.sol";

contract JonesGlpLeverageStrategy is IJonesGlpLeverageStrategy, OperableKeepable, ReentrancyGuard {
    using Math for uint256;

    struct LeverageConfig {
        uint256 target;
        uint256 min;
        uint256 max;
    }

    IGmxRewardRouter constant routerV1 = IGmxRewardRouter(0xA906F338CB21815cBc4Bc87ace9e68c87eF8d8F1);
    IGmxRewardRouter constant routerV2 = IGmxRewardRouter(0xB95DB5B167D75e6d04227CfFFA61069348d271F5);
    IGlpManager constant glpManager = IGlpManager(0x3963FfC9dff443c2A94f21b129D429891E32ec18);
    address constant weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    uint256 public constant PRECISION = 1e30;
    uint256 public constant BASIS_POINTS = 1e12;
    uint256 public constant GMX_BASIS = 1e4;
    uint256 public constant USDC_DECIMALS = 1e6;
    uint256 public constant GLP_DECIMALS = 1e18;

    IERC20 public stable;
    IERC20 public glp;

    IJonesBorrowableVault stableVault;
    IJonesBorrowableVault glpVault;

    IJonesGlpRewardDistributor distributor;

    uint256 public stableDebt;

    LeverageConfig public leverageConfig;

    constructor(
        IJonesBorrowableVault _stableVault,
        IJonesBorrowableVault _glpVault,
        IJonesGlpRewardDistributor _distributor,
        LeverageConfig memory _leverageConfig,
        address _glp,
        address _stable,
        uint256 _stableDebt
    ) Governable(msg.sender) ReentrancyGuard() {
        stableVault = _stableVault;
        glpVault = _glpVault;
        distributor = _distributor;

        stable = IERC20(_stable);
        glp = IERC20(_glp);

        stableDebt = _stableDebt;

        _setLeverageConfig(_leverageConfig);
    }

    // ============================= Operator functions ================================ //

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function onGlpDeposit(uint256 _amount) external nonReentrant onlyOperator {
        _borrowGlp(_amount);
        if (leverage() < getTargetLeverage()) {
            _leverage(_amount);
        }
        _rebalance(getUnderlyingGlp());
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function onGlpCompound(uint256 _amount) external nonReentrant onlyOperator {
        _borrowGlp(_amount);
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function onGlpRedeem(uint256 _amount) external nonReentrant onlyOperator returns (uint256) {
        if (_amount > getUnderlyingGlp()) {
            revert NotEnoughUnderlyingGlp();
        }

        uint256 glpRedeemRetention = glpRedeemRetention(_amount);
        uint256 assetsToRedeem = _amount - glpRedeemRetention;

        glp.transfer(msg.sender, assetsToRedeem);

        uint256 underlying = getUnderlyingGlp();
        uint256 leverageAmount = glp.balanceOf(address(this)) - underlying;
        uint256 protocolExcess = ((underlying * (leverageConfig.target - BASIS_POINTS)) / BASIS_POINTS);
        uint256 excessGlp;
        if (leverageAmount < protocolExcess) {
            excessGlp = leverageAmount;
        } else {
            excessGlp = ((_amount * (leverageConfig.target - BASIS_POINTS)) / BASIS_POINTS); // 18 Decimals
        }

        if (leverageAmount >= excessGlp && leverage() > getTargetLeverage()) {
            _deleverage(excessGlp);
        }

        underlying = getUnderlyingGlp();
        if (underlying > 0) {
            _rebalance(underlying);
        }

        emit Deleverage(excessGlp, assetsToRedeem);

        return assetsToRedeem;
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function onStableRedeem(uint256 _amount, uint256 _amountAfterRetention) external onlyOperator returns (uint256) {
        uint256 strategyStables = stable.balanceOf(address(stableVault));
        uint256 expectedStables = _amountAfterRetention > strategyStables ? _amountAfterRetention - strategyStables : 0;

        if (expectedStables > 0) {
            (uint256 glpAmount,) = _getRequiredGlpAmount(expectedStables + 2);
            uint256 stableAmount =
                routerV2.unstakeAndRedeemGlp(address(stable), glpAmount, expectedStables, address(this));
            if (stableAmount + strategyStables < _amountAfterRetention) {
                revert NotEnoughStables();
            }
        }

        stable.transfer(msg.sender, _amountAfterRetention);

        stableDebt = stableDebt - _amount;

        return _amountAfterRetention;
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function claimGlpRewards() external nonReentrant onlyOperatorOrKeeper {
        routerV1.handleRewards(false, false, true, true, true, true, false);

        uint256 rewards = IERC20(weth).balanceOf(address(this));

        uint256 currentLeverage = leverage();

        IERC20(weth).approve(address(distributor), rewards);
        distributor.splitRewards(rewards, currentLeverage, utilization());

        // Information needed to calculate rewards per Vault
        emit ClaimGlpRewards(
            tx.origin,
            msg.sender,
            rewards,
            block.timestamp,
            currentLeverage,
            glp.balanceOf(address(this)),
            getUnderlyingGlp(),
            glpVault.totalSupply(),
            stableDebt,
            stableVault.totalSupply()
        );
    }

    // ============================= Public functions ================================ //

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function utilization() public view returns (uint256) {
        uint256 borrowed = stableDebt;
        uint256 available = stable.balanceOf(address(stableVault));
        uint256 total = borrowed + available;

        if (total == 0) {
            return 0;
        }

        return (borrowed * BASIS_POINTS) / total;
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function leverage() public view returns (uint256) {
        uint256 glpTvl = getUnderlyingGlp(); // 18 Decimals

        if (glpTvl == 0) {
            return 0;
        }

        if (stableDebt == 0) {
            return 1 * BASIS_POINTS;
        }

        return ((glp.balanceOf(address(this)) * BASIS_POINTS) / glpTvl); // 12 Decimals;
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function getUnderlyingGlp() public view returns (uint256) {
        uint256 currentBalance = glp.balanceOf(address(this));

        if (currentBalance == 0) {
            return 0;
        }

        if (stableDebt > 0) {
            (uint256 glpAmount,) = _getRequiredGlpAmount(stableDebt + 2);
            return currentBalance > glpAmount ? currentBalance - glpAmount : 0;
        } else {
            return currentBalance;
        }
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function getStableGlpValue(uint256 _glpAmount) public view returns (uint256) {
        (uint256 _value,) = _sellGlpStableSimulation(_glpAmount);
        return _value;
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function buyGlpStableSimulation(uint256 _stableAmount) public view returns (uint256) {
        return _buyGlpStableSimulation(_stableAmount);
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function getRequiredStableAmount(uint256 _glpAmount) external view returns (uint256) {
        (uint256 stableAmount,) = _getRequiredStableAmount(_glpAmount);
        return stableAmount;
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function getRequiredGlpAmount(uint256 _stableAmount) external view returns (uint256) {
        (uint256 glpAmount,) = _getRequiredGlpAmount(_stableAmount);
        return glpAmount;
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function getRedeemStableGMXIncentive(uint256 _stableAmount) external view returns (uint256) {
        (, uint256 gmxRetention) = _getRequiredGlpAmount(_stableAmount);
        return gmxRetention;
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function glpMintIncentive(uint256 _glpAmount) public view returns (uint256) {
        return _glpMintIncentive(_glpAmount);
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function glpRedeemRetention(uint256 _glpAmount) public view returns (uint256) {
        return _glpRedeemRetention(_glpAmount);
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function getMaxLeverage() public view returns (uint256) {
        return leverageConfig.max;
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function getMinLeverage() public view returns (uint256) {
        return leverageConfig.min;
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function getGMXCapDifference() public view returns (uint256) {
        return _getGMXCapDifference();
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function getTargetLeverage() public view returns (uint256) {
        return leverageConfig.target;
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function leverageOnDeposit(uint256 _glpAmount) external view returns (bool) {
        uint256 glpTvl = glp.balanceOf(address(this)) + _glpAmount;

        uint256 underlyingGlp;

        if (stableDebt > 0) {
            (uint256 glpAmount,) = _getRequiredGlpAmount(stableDebt + 2);
            underlyingGlp = glpTvl > glpAmount ? glpTvl - glpAmount : 0;
        }

        if (underlyingGlp == 0) {
            return false;
        }

        if (stableDebt == 0) {
            return false;
        }

        uint256 currentLeverage = ((glpTvl * BASIS_POINTS) / underlyingGlp); // 12 Decimals;

        if (currentLeverage < getTargetLeverage()) {
            return true;
        } else {
            return false;
        }
    }

    // ============================= Governor functions ================================ //

    /**
     * @notice Set Leverage Configuration
     * @dev Precision is based on 1e12 as 1x leverage
     * @param _target Target leverage
     * @param _min Min Leverage
     * @param _max Max Leverage
     * @param rebalance_ If is true trigger a rebalance
     */
    function setLeverageConfig(uint256 _target, uint256 _min, uint256 _max, bool rebalance_) public onlyGovernor {
        _setLeverageConfig(LeverageConfig(_target, _min, _max));
        emit SetLeverageConfig(_target, _min, _max);
        if (rebalance_) {
            _rebalance(getUnderlyingGlp());
        }
    }

    /**
     * @notice Set new glp address
     * @param _glp GLP address
     */
    function setGlpAddress(address _glp) external onlyGovernor {
        address oldGlp = address(glp);
        glp = IERC20(_glp);
        emit UpdateGlpAddress(oldGlp, _glp);
    }

    /**
     * @notice Set new stable address
     * @param _stable Stable addresss
     */
    function setStableAddress(address _stable) external onlyGovernor {
        address oldStable = address(stable);
        stable = IERC20(_stable);
        emit UpdateStableAddress(oldStable, _stable);
    }

    /**
     * @notice Emergency withdraw GLP in this contract
     * @param _to address to send the funds
     */
    function emergencyWithdraw(address _to) external onlyGovernor {
        uint256 currentBalance = glp.balanceOf(address(this));

        if (currentBalance == 0) {
            return;
        }

        glp.transfer(_to, currentBalance);

        emit EmergencyWithdraw(_to, currentBalance);
    }

    /**
     * @notice GMX function to signal transfer position
     * @param _to address to send the funds
     * @param _gmxRouter address of gmx router with the function
     */
    function transferAccount(address _to, address _gmxRouter) external onlyGovernor {
        if (_to == address(0)) {
            revert ZeroAddressError();
        }

        IGmxRewardRouter(_gmxRouter).signalTransfer(_to);
    }

    /**
     * @notice GMX function to accept transfer position
     * @param _sender address to receive the funds
     * @param _gmxRouter address of gmx router with the function
     */
    function acceptAccountTransfer(address _sender, address _gmxRouter) external onlyGovernor {
        IGmxRewardRouter gmxRouter = IGmxRewardRouter(_gmxRouter);

        gmxRouter.acceptTransfer(_sender);
    }

    // ============================= Keeper functions ================================ //

    /**
     * @notice Using by the bot to rebalance if is it needed
     */
    function rebalance() external onlyKeeper {
        _rebalance(getUnderlyingGlp());
    }

    /**
     * @notice Deleverage & pay stable debt
     */
    function unwind() external onlyGovernorOrKeeper {
        _setLeverageConfig(LeverageConfig(BASIS_POINTS + 1, BASIS_POINTS, BASIS_POINTS + 2));
        _liquidate();
    }

    /**
     * @notice Using by the bot to leverage Up if is needed
     */
    function leverageUp(uint256 _stableAmount) external onlyKeeper {
        uint256 availableForBorrowing = stable.balanceOf(address(stableVault));

        if (availableForBorrowing == 0) {
            return;
        }

        uint256 oldLeverage = leverage();

        _stableAmount = _adjustToGMXCap(_stableAmount);

        if (_stableAmount < 1e4) {
            return;
        }

        if (availableForBorrowing < _stableAmount) {
            _stableAmount = availableForBorrowing;
        }

        uint256 stableToBorrow = _stableAmount - stable.balanceOf(address(this));

        stableVault.borrow(stableToBorrow);
        emit BorrowStable(stableToBorrow);

        stableDebt = stableDebt + stableToBorrow;

        address stableAsset = address(stable);
        IERC20(stableAsset).approve(routerV2.glpManager(), _stableAmount);
        routerV2.mintAndStakeGlp(stableAsset, _stableAmount, 0, 0);

        uint256 newLeverage = leverage();

        if (newLeverage > getMaxLeverage()) {
            revert OverLeveraged();
        }

        emit LeverageUp(stableDebt, oldLeverage, newLeverage);
    }

    /**
     * @notice Using by the bot to leverage Down if is needed
     */
    function leverageDown(uint256 _glpAmount) external onlyKeeper {
        uint256 oldLeverage = leverage();

        uint256 stablesReceived = routerV2.unstakeAndRedeemGlp(address(stable), _glpAmount, 0, address(this));

        uint256 currentStableDebt = stableDebt;

        if (stablesReceived <= currentStableDebt) {
            _repayStable(stablesReceived);
        } else {
            _repayStable(currentStableDebt);
        }

        uint256 newLeverage = leverage();

        if (newLeverage < getMinLeverage()) {
            revert UnderLeveraged();
        }

        emit LeverageDown(stableDebt, oldLeverage, newLeverage);
    }

    // ============================= Private functions ================================ //

    function _rebalance(uint256 _glpDebt) private {
        uint256 currentLeverage = leverage();

        LeverageConfig memory currentLeverageConfig = leverageConfig;

        if (currentLeverage < currentLeverageConfig.min) {
            uint256 missingGlp = (_glpDebt * (currentLeverageConfig.target - currentLeverage)) / BASIS_POINTS; // 18 Decimals

            (uint256 stableToDeposit,) = _getRequiredStableAmount(missingGlp); // 6 Decimals

            stableToDeposit = _adjustToGMXCap(stableToDeposit);

            if (stableToDeposit < 1e4) {
                return;
            }

            uint256 availableForBorrowing = stable.balanceOf(address(stableVault));

            if (availableForBorrowing == 0) {
                return;
            }

            if (availableForBorrowing < stableToDeposit) {
                stableToDeposit = availableForBorrowing;
            }

            uint256 stableToBorrow = stableToDeposit - stable.balanceOf(address(this));

            stableVault.borrow(stableToBorrow);
            emit BorrowStable(stableToBorrow);

            stableDebt = stableDebt + stableToBorrow;

            address stableAsset = address(stable);
            IERC20(stableAsset).approve(routerV2.glpManager(), stableToDeposit);
            routerV2.mintAndStakeGlp(stableAsset, stableToDeposit, 0, 0);

            emit Rebalance(_glpDebt, currentLeverage, leverage(), tx.origin);

            return;
        }

        if (currentLeverage > currentLeverageConfig.max) {
            uint256 excessGlp = (_glpDebt * (currentLeverage - currentLeverageConfig.target)) / BASIS_POINTS;

            uint256 stablesReceived = routerV2.unstakeAndRedeemGlp(address(stable), excessGlp, 0, address(this));

            uint256 currentStableDebt = stableDebt;

            if (stablesReceived <= currentStableDebt) {
                _repayStable(stablesReceived);
            } else {
                _repayStable(currentStableDebt);
            }

            emit Rebalance(_glpDebt, currentLeverage, leverage(), tx.origin);

            return;
        }

        return;
    }

    function _liquidate() private {
        if (stableDebt == 0) {
            return;
        }

        uint256 glpBalance = glp.balanceOf(address(this));

        (uint256 glpAmount,) = _getRequiredGlpAmount(stableDebt + 2);

        if (glpAmount > glpBalance) {
            glpAmount = glpBalance;
        }

        uint256 stablesReceived = routerV2.unstakeAndRedeemGlp(address(stable), glpAmount, 0, address(this));

        uint256 currentStableDebt = stableDebt;

        if (stablesReceived <= currentStableDebt) {
            _repayStable(stablesReceived);
        } else {
            _repayStable(currentStableDebt);
        }

        emit Liquidate(stablesReceived);
    }

    function _borrowGlp(uint256 _amount) private returns (uint256) {
        glpVault.borrow(_amount);

        emit BorrowGlp(_amount);

        return _amount;
    }

    function _repayStable(uint256 _amount) internal returns (uint256) {
        stable.approve(address(stableVault), _amount);

        uint256 updatedAmount = stableDebt - stableVault.repay(_amount);

        stableDebt = updatedAmount;

        return updatedAmount;
    }

    function _setLeverageConfig(LeverageConfig memory _config) private {
        if (
            _config.min >= _config.max || _config.min >= _config.target || _config.max <= _config.target
                || _config.min < BASIS_POINTS
        ) {
            revert InvalidLeverageConfig();
        }

        leverageConfig = _config;
    }

    function _getRequiredGlpAmount(uint256 _stableAmount) private view returns (uint256, uint256) {
        // Working as expected, will get the amount of glp nedeed to get a few less stables than expected
        // If you have to get an amount greater or equal of _stableAmount, use _stableAmount + 2
        IGlpManager manager = glpManager;
        IGMXVault vault = IGMXVault(manager.vault());

        address usdc = address(stable);

        uint256 usdcPrice = vault.getMaxPrice(usdc); // 30 decimals

        uint256 glpSupply = glp.totalSupply();

        uint256 glpPrice = manager.getAum(false).mulDiv(GLP_DECIMALS, glpSupply, Math.Rounding.Down); // 30 decimals

        uint256 usdgAmount = _stableAmount.mulDiv(usdcPrice, PRECISION, Math.Rounding.Down) * BASIS_POINTS; // 18 decimals

        uint256 glpAmount = _stableAmount.mulDiv(usdcPrice, glpPrice, Math.Rounding.Down) * BASIS_POINTS; // 18 decimals

        uint256 retentionBasisPoints =
            _getGMXBasisRetention(usdc, usdgAmount, vault.mintBurnFeeBasisPoints(), vault.taxBasisPoints(), false);

        uint256 glpRequired = (glpAmount * GMX_BASIS) / (GMX_BASIS - retentionBasisPoints);

        return (glpRequired, retentionBasisPoints);
    }

    function _getRequiredStableAmount(uint256 _glpAmount) private view returns (uint256, uint256) {
        // Working as expected, will get the amount of stables nedeed to get a few less glp than expected
        // If you have to get an amount greater or equal of _glpAmount, use _glpAmount + 2
        IGlpManager manager = glpManager;
        IGMXVault vault = IGMXVault(manager.vault());

        address usdc = address(stable);

        uint256 usdcPrice = vault.getMinPrice(usdc); // 30 decimals

        uint256 glpPrice = manager.getAum(true).mulDiv(GLP_DECIMALS, glp.totalSupply(), Math.Rounding.Down); // 30 decimals

        uint256 stableAmount = _glpAmount.mulDiv(glpPrice, usdcPrice, Math.Rounding.Down); // 18 decimals

        uint256 usdgAmount = _glpAmount.mulDiv(glpPrice, PRECISION, Math.Rounding.Down); // 18 decimals

        uint256 retentionBasisPoints =
            vault.getFeeBasisPoints(usdc, usdgAmount, vault.mintBurnFeeBasisPoints(), vault.taxBasisPoints(), true);

        return ((stableAmount * GMX_BASIS / (GMX_BASIS - retentionBasisPoints)) / BASIS_POINTS, retentionBasisPoints); // 18 decimals
    }

    function _leverage(uint256 _glpAmount) private {
        uint256 missingGlp = ((_glpAmount * (leverageConfig.target - BASIS_POINTS)) / BASIS_POINTS); // 18 Decimals

        (uint256 stableToDeposit,) = _getRequiredStableAmount(missingGlp); // 6 Decimals

        stableToDeposit = _adjustToGMXCap(stableToDeposit);

        if (stableToDeposit < 1e4) {
            return;
        }

        uint256 availableForBorrowing = stable.balanceOf(address(stableVault));

        if (availableForBorrowing == 0) {
            return;
        }

        if (availableForBorrowing < stableToDeposit) {
            stableToDeposit = availableForBorrowing;
        }

        uint256 stableToBorrow = stableToDeposit - stable.balanceOf(address(this));

        stableVault.borrow(stableToBorrow);
        emit BorrowStable(stableToBorrow);

        stableDebt = stableDebt + stableToBorrow;

        address stableAsset = address(stable);
        IERC20(stableAsset).approve(routerV2.glpManager(), stableToDeposit);
        uint256 glpMinted = routerV2.mintAndStakeGlp(stableAsset, stableToDeposit, 0, 0);

        emit Leverage(_glpAmount, glpMinted);
    }

    function _deleverage(uint256 _excessGlp) private returns (uint256) {
        uint256 stablesReceived = routerV2.unstakeAndRedeemGlp(address(stable), _excessGlp, 0, address(this));

        uint256 currentStableDebt = stableDebt;

        if (stablesReceived <= currentStableDebt) {
            _repayStable(stablesReceived);
        } else {
            _repayStable(currentStableDebt);
        }

        return stablesReceived;
    }

    function _adjustToGMXCap(uint256 _stableAmount) private view returns (uint256) {
        IGlpManager manager = glpManager;
        IGMXVault vault = IGMXVault(manager.vault());

        address usdc = address(stable);

        uint256 mintAmount = _buyGlpStableSimulation(_stableAmount);

        uint256 currentUsdgAmount = vault.usdgAmounts(usdc);

        uint256 nextAmount = currentUsdgAmount + mintAmount;
        uint256 maxUsdgAmount = vault.maxUsdgAmounts(usdc);

        if (nextAmount > maxUsdgAmount) {
            (uint256 requiredStables,) = _getRequiredStableAmount(maxUsdgAmount - currentUsdgAmount);
            return requiredStables;
        } else {
            return _stableAmount;
        }
    }

    function _getGMXCapDifference() private view returns (uint256) {
        IGlpManager manager = glpManager;
        IGMXVault vault = IGMXVault(manager.vault());

        address usdc = address(stable);

        uint256 currentUsdgAmount = vault.usdgAmounts(usdc);

        uint256 maxUsdgAmount = vault.maxUsdgAmounts(usdc);

        return maxUsdgAmount - currentUsdgAmount;
    }

    function _buyGlpStableSimulation(uint256 _stableAmount) private view returns (uint256) {
        IGlpManager manager = glpManager;
        IGMXVault vault = IGMXVault(manager.vault());

        address usdc = address(stable);

        uint256 aumInUsdg = manager.getAumInUsdg(true);

        uint256 usdcPrice = vault.getMinPrice(usdc); // 30 decimals

        uint256 usdgAmount = _stableAmount.mulDiv(usdcPrice, PRECISION); // 6 decimals

        usdgAmount = usdgAmount.mulDiv(GLP_DECIMALS, USDC_DECIMALS); // 18 decimals

        uint256 retentionBasisPoints =
            vault.getFeeBasisPoints(usdc, usdgAmount, vault.mintBurnFeeBasisPoints(), vault.taxBasisPoints(), true);

        uint256 amountAfterRetention = _stableAmount.mulDiv(GMX_BASIS - retentionBasisPoints, GMX_BASIS); // 6 decimals

        uint256 mintAmount = amountAfterRetention.mulDiv(usdcPrice, PRECISION); // 6 decimals

        mintAmount = mintAmount.mulDiv(GLP_DECIMALS, USDC_DECIMALS); // 18 decimals

        return aumInUsdg == 0 ? mintAmount : mintAmount.mulDiv(glp.totalSupply(), aumInUsdg); // 18 decimals
    }

    function _buyGlpStableSimulationWhitoutRetention(uint256 _stableAmount) private view returns (uint256) {
        IGlpManager manager = glpManager;
        IGMXVault vault = IGMXVault(manager.vault());

        address usdc = address(stable);

        uint256 aumInUsdg = manager.getAumInUsdg(true);

        uint256 usdcPrice = vault.getMinPrice(usdc); // 30 decimals

        uint256 usdgAmount = _stableAmount.mulDiv(usdcPrice, PRECISION); // 6 decimals

        usdgAmount = usdgAmount.mulDiv(GLP_DECIMALS, USDC_DECIMALS); // 18 decimals

        uint256 mintAmount = _stableAmount.mulDiv(usdcPrice, PRECISION); // 6 decimals

        mintAmount = mintAmount.mulDiv(GLP_DECIMALS, USDC_DECIMALS); // 18 decimals

        return aumInUsdg == 0 ? mintAmount : mintAmount.mulDiv(glp.totalSupply(), aumInUsdg); // 18 decimals
    }

    function _sellGlpStableSimulation(uint256 _glpAmount) private view returns (uint256, uint256) {
        IGlpManager manager = glpManager;
        IGMXVault vault = IGMXVault(manager.vault());

        address usdc = address(stable);

        uint256 usdgAmount = _glpAmount.mulDiv(manager.getAumInUsdg(false), glp.totalSupply());

        uint256 redemptionAmount = usdgAmount.mulDiv(PRECISION, vault.getMaxPrice(usdc));

        redemptionAmount = redemptionAmount.mulDiv(USDC_DECIMALS, GLP_DECIMALS); // 6 decimals

        uint256 retentionBasisPoints =
            _getGMXBasisRetention(usdc, usdgAmount, vault.mintBurnFeeBasisPoints(), vault.taxBasisPoints(), false);

        return (redemptionAmount.mulDiv(GMX_BASIS - retentionBasisPoints, GMX_BASIS), retentionBasisPoints);
    }

    function _glpMintIncentive(uint256 _glpAmount) private view returns (uint256) {
        uint256 amountToMint = _glpAmount.mulDiv(leverageConfig.target - BASIS_POINTS, BASIS_POINTS); // 18 Decimals
        (uint256 stablesNeeded, uint256 gmxIncentive) = _getRequiredStableAmount(amountToMint + 2);
        uint256 incentiveInStables = stablesNeeded.mulDiv(gmxIncentive, GMX_BASIS);
        return _buyGlpStableSimulationWhitoutRetention(incentiveInStables); // retention in glp
    }

    function _glpRedeemRetention(uint256 _glpAmount) private view returns (uint256) {
        uint256 amountToRedeem = _glpAmount.mulDiv(leverageConfig.target - BASIS_POINTS, BASIS_POINTS); //18
        (, uint256 gmxRetention) = _sellGlpStableSimulation(amountToRedeem + 2);
        uint256 retentionInGlp = amountToRedeem.mulDiv(gmxRetention, GMX_BASIS);
        return retentionInGlp;
    }

    function _getGMXBasisRetention(
        address _token,
        uint256 _usdgDelta,
        uint256 _retentionBasisPoints,
        uint256 _taxBasisPoints,
        bool _increment
    ) private view returns (uint256) {
        IGMXVault vault = IGMXVault(glpManager.vault());

        if (!vault.hasDynamicFees()) return _retentionBasisPoints;

        uint256 initialAmount;

        if (_increment) {
            initialAmount = vault.usdgAmounts(_token);
        } else {
            initialAmount = vault.usdgAmounts(_token) > _usdgDelta ? vault.usdgAmounts(_token) - _usdgDelta : 0;
        }

        uint256 nextAmount = initialAmount + _usdgDelta;

        if (!_increment) {
            nextAmount = _usdgDelta > initialAmount ? 0 : initialAmount - _usdgDelta;
        }

        uint256 targetAmount = vault.getTargetUsdgAmount(_token);
        if (targetAmount == 0) return _retentionBasisPoints;

        uint256 initialDiff = initialAmount > targetAmount ? initialAmount - targetAmount : targetAmount - initialAmount;
        uint256 nextDiff = nextAmount > targetAmount ? nextAmount - targetAmount : targetAmount - nextAmount;

        // action improves relative asset balance
        if (nextDiff < initialDiff) {
            uint256 rebateBps = _taxBasisPoints.mulDiv(initialDiff, targetAmount);
            return rebateBps > _retentionBasisPoints ? 0 : _retentionBasisPoints - rebateBps;
        }

        uint256 averageDiff = (initialDiff + nextDiff) / 2;
        if (averageDiff > targetAmount) {
            averageDiff = targetAmount;
        }
        uint256 taxBps = _taxBasisPoints.mulDiv(averageDiff, targetAmount);
        return _retentionBasisPoints + taxBps;
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IUniswapV2Router02} from "../interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "../interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "../interfaces/IUniswapV2Pair.sol";
import {SushiAdapter} from "../adapters/SushiAdapter.sol";
import {I1inchAggregationRouterV4} from "../interfaces/I1inchAggregationRouterV4.sol";
import {Babylonian} from "./Babylonian.sol";
import {IStableSwap} from "../interfaces/IStableSwap.sol";
import {Curve2PoolAdapter} from "../adapters/Curve2PoolAdapter.sol";

library OneInchZapLib {
    using Curve2PoolAdapter for IStableSwap;
    using SafeERC20 for IERC20;
    using SushiAdapter for IUniswapV2Router02;

    enum ZapType {
        ZAP_IN,
        ZAP_OUT
    }

    struct SwapParams {
        address caller;
        I1inchAggregationRouterV4.SwapDescription desc;
        bytes data;
    }

    struct ZapInIntermediateParams {
        SwapParams swapFromIntermediate;
        SwapParams toPairTokens;
        address pairAddress;
        uint256 token0Amount;
        uint256 token1Amount;
        uint256 minPairTokens;
    }

    struct ZapInParams {
        SwapParams toPairTokens;
        address pairAddress;
        uint256 token0Amount;
        uint256 token1Amount;
        uint256 minPairTokens;
    }

    IUniswapV2Router02 public constant sushiSwapRouter = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);

    IStableSwap public constant crv2 = IStableSwap(0x7f90122BF0700F9E7e1F688fe926940E8839F353);

    uint256 private constant deadline = 0xf000000000000000000000000000000000000000000000000000000000000000;

    /**
     * @notice Add liquidity to Sushiswap pools with ETH/ERC20 Tokens
     */
    function zapInIntermediate(
        I1inchAggregationRouterV4 self,
        SwapParams calldata _swapFromIntermediate,
        SwapParams calldata _toPairTokens,
        address _pairAddress,
        uint256 _token0Amount,
        uint256 _token1Amount,
        uint256 _minPairTokens
    ) public returns (uint256) {
        address[2] memory pairTokens = [IUniswapV2Pair(_pairAddress).token0(), IUniswapV2Pair(_pairAddress).token1()];

        // The dest token should be one of the tokens on the pair
        if (
            (_toPairTokens.desc.dstToken != pairTokens[0] && _toPairTokens.desc.dstToken != pairTokens[1])
                || (
                    _swapFromIntermediate.desc.dstToken != pairTokens[0]
                        && _swapFromIntermediate.desc.dstToken != pairTokens[1]
                )
        ) {
            revert INVALID_DEST_TOKEN();
        }

        perform1InchSwap(self, _swapFromIntermediate);

        if (_toPairTokens.desc.srcToken != pairTokens[0] && _toPairTokens.desc.srcToken != pairTokens[1]) {
            revert INVALID_SOURCE_TOKEN();
        }

        uint256 swapped = zapIn(self, _toPairTokens, _pairAddress, _token0Amount, _token1Amount, _minPairTokens);

        return swapped;
    }

    /**
     * @notice Add liquidity to Sushiswap pools with ETH/ERC20 Tokens
     */
    function zapIn(
        I1inchAggregationRouterV4 self,
        SwapParams calldata _toPairTokens,
        address _pairAddress,
        uint256 _token0Amount,
        uint256 _token1Amount,
        uint256 _minPairTokens
    ) public returns (uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(_pairAddress);

        address[2] memory tokens = [pair.token0(), pair.token1()];

        // Validate sources
        if (_toPairTokens.desc.srcToken != tokens[0] && _toPairTokens.desc.srcToken != tokens[1]) {
            revert INVALID_SOURCE_TOKEN();
        }

        // Validate dest
        if (_toPairTokens.desc.dstToken != tokens[0] && _toPairTokens.desc.dstToken != tokens[1]) {
            revert INVALID_DEST_TOKEN();
        }

        perform1InchSwap(self, _toPairTokens);

        uint256 lpBought = uniDeposit(pair.token0(), pair.token1(), _token0Amount, _token1Amount);

        if (lpBought < _minPairTokens) {
            revert HIGH_SLIPPAGE();
        }

        emit Zap(msg.sender, _pairAddress, ZapType.ZAP_IN, lpBought);

        return lpBought;
    }

    function zapInFrom2Crv(
        I1inchAggregationRouterV4 self,
        SwapParams calldata _swapFromStable,
        SwapParams calldata _toPairTokens,
        address _pairAddress,
        uint256 _starting2crv,
        uint256 _token0Amount,
        uint256 _token1Amount,
        uint256 _minPairTokens,
        address _intermediateToken
    ) public returns (uint256) {
        // The intermediate token should be one of the stable coins on `2Crv`
        if (_intermediateToken != crv2.coins(0) && _intermediateToken != crv2.coins(1)) {
            revert INVALID_INTERMEDIATE_TOKEN();
        }

        // Swaps 2crv for stable using 2crv contract
        crv2.swap2CrvForStable(_intermediateToken, _starting2crv, _swapFromStable.desc.amount);

        // Perform zapIn intermediate with the stable received
        return zapInIntermediate(
            self, _swapFromStable, _toPairTokens, _pairAddress, _token0Amount, _token1Amount, _minPairTokens
        );
    }

    /**
     * @notice Removes liquidity from Sushiswap pools and swaps pair tokens to `_tokenOut`.
     */
    function zapOutToOneTokenFromPair(
        I1inchAggregationRouterV4 self,
        address _pair,
        uint256 _amount,
        uint256 _token0PairAmount,
        uint256 _token1PairAmount,
        SwapParams calldata _tokenSwap
    ) public returns (uint256 tokenOutAmount) {
        IUniswapV2Pair pair = IUniswapV2Pair(_pair);

        // Remove liquidity from pair
        _removeLiquidity(pair, _amount, _token0PairAmount, _token1PairAmount);

        // Swap anyone of the tokens to the other
        tokenOutAmount = perform1InchSwap(self, _tokenSwap);

        emit Zap(msg.sender, _pair, ZapType.ZAP_OUT, tokenOutAmount);
    }

    /**
     * @notice Removes liquidity from Sushiswap pools and swaps pair tokens to `_tokenOut`.
     */
    function zapOutAnyToken(
        I1inchAggregationRouterV4 self,
        address _pair,
        uint256 _amount,
        uint256 _token0PairAmount,
        uint256 _token1PairAmount,
        SwapParams calldata _token0Swap,
        SwapParams calldata _token1Swap
    ) public returns (uint256 tokenOutAmount) {
        IUniswapV2Pair pair = IUniswapV2Pair(_pair);

        // Remove liquidity from pair
        _removeLiquidity(pair, _amount, _token0PairAmount, _token1PairAmount);

        // Swap token0 to output
        uint256 token0SwappedAmount = perform1InchSwap(self, _token0Swap);

        // Swap token1 to output
        uint256 token1SwappedAmount = perform1InchSwap(self, _token1Swap);

        tokenOutAmount = token0SwappedAmount + token1SwappedAmount;
        emit Zap(msg.sender, _pair, ZapType.ZAP_OUT, tokenOutAmount);
    }

    function zapOutTo2crv(
        I1inchAggregationRouterV4 self,
        address _pair,
        uint256 _amount,
        uint256 _token0PairAmount,
        uint256 _token1PairAmount,
        uint256 _min2CrvAmount,
        address _intermediateToken,
        SwapParams calldata _token0Swap,
        SwapParams calldata _token1Swap
    ) public returns (uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(_pair);

        address[2] memory pairTokens = [IUniswapV2Pair(_pair).token0(), IUniswapV2Pair(_pair).token1()];

        // Check source tokens
        if (_token0Swap.desc.srcToken != pairTokens[0] || _token1Swap.desc.srcToken != pairTokens[1]) {
            revert INVALID_SOURCE_TOKEN();
        }

        if (_token0Swap.desc.dstToken != _intermediateToken || _token1Swap.desc.dstToken != _intermediateToken) {
            revert INVALID_DEST_TOKEN();
        }

        if (_intermediateToken != crv2.coins(0) && _intermediateToken != crv2.coins(1)) {
            revert INVALID_INTERMEDIATE_TOKEN();
        }

        // Remove liquidity from pair
        _removeLiquidity(pair, _amount, _token0PairAmount, _token1PairAmount);

        uint256 stableAmount = perform1InchSwap(self, _token0Swap) + perform1InchSwap(self, _token1Swap);

        // Swap to 2crv
        IERC20(_intermediateToken).approve(address(crv2), stableAmount);

        return crv2.swapStableFor2Crv(_token0Swap.desc.dstToken, stableAmount, _min2CrvAmount);
    }

    function perform1InchSwap(I1inchAggregationRouterV4 self, SwapParams calldata _swap) public returns (uint256) {
        IERC20(_swap.desc.srcToken).safeApprove(address(self), _swap.desc.amount);
        (uint256 returnAmount,) = self.swap(_swap.caller, _swap.desc, _swap.data);
        IERC20(_swap.desc.srcToken).safeApprove(address(self), 0);

        return returnAmount;
    }

    /**
     * Removes liquidity from Sushi.
     */
    function _removeLiquidity(IUniswapV2Pair _pair, uint256 _amount, uint256 _minToken0Amount, uint256 _minToken1Amount)
        private
        returns (uint256 amountA, uint256 amountB)
    {
        _approveToken(address(_pair), address(sushiSwapRouter), _amount);
        return sushiSwapRouter.removeLiquidity(
            _pair.token0(), _pair.token1(), _amount, _minToken0Amount, _minToken1Amount, address(this), deadline
        );
    }

    /**
     * Adds liquidity to Sushi.
     */
    function uniDeposit(address _tokenA, address _tokenB, uint256 _amountADesired, uint256 _amountBDesired)
        public
        returns (uint256)
    {
        _approveToken(_tokenA, address(sushiSwapRouter), _amountADesired);
        _approveToken(_tokenB, address(sushiSwapRouter), _amountBDesired);

        (,, uint256 lp) = sushiSwapRouter.addLiquidity(
            _tokenA,
            _tokenB,
            _amountADesired,
            _amountBDesired,
            1, // amountAMin - no need to worry about front-running since we handle that in main Zap
            1, // amountBMin - no need to worry about front-running since we handle that in main Zap
            address(this), // to
            deadline // deadline
        );

        return lp;
    }

    function _approveToken(address _token, address _spender) internal {
        IERC20 token = IERC20(_token);
        if (token.allowance(address(this), _spender) > 0) {
            return;
        } else {
            token.safeApprove(_spender, type(uint256).max);
        }
    }

    function _approveToken(address _token, address _spender, uint256 _amount) internal {
        IERC20(_token).safeApprove(_spender, 0);
        IERC20(_token).safeApprove(_spender, _amount);
    }

    /* ========== EVENTS ========== */
    /**
     * Emits when zapping in/out.
     * @param _sender sender performing zap action.
     * @param _pool address of the pool pair.
     * @param _type type of action (ie zap in or out).
     * @param _amount output amount after zap (pair amount for Zap In, output token amount for Zap Out)
     */
    event Zap(address indexed _sender, address indexed _pool, ZapType _type, uint256 _amount);

    /* ========== ERRORS ========== */
    error ERROR_SWAPPING_TOKENS();
    error ADDRESS_IS_ZERO();
    error HIGH_SLIPPAGE();
    error INVALID_INTERMEDIATE_TOKEN();
    error INVALID_SOURCE_TOKEN();
    error INVALID_DEST_TOKEN();
    error NON_EXISTANCE_PAIR();
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

pragma experimental ABIEncoderV2;

interface I1inchAggregationRouterV4 {
    struct SwapDescription {
        address srcToken;
        address dstToken;
        address srcReceiver;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
        bytes permit;
    }

    event OrderFilledRFQ(bytes32 orderHash, uint256 makingAmount);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    event Swapped(
        address sender,
        address srcToken,
        address dstToken,
        address dstReceiver,
        uint256 spentAmount,
        uint256 returnAmount
    );

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function LIMIT_ORDER_RFQ_TYPEHASH() external view returns (bytes32);

    function cancelOrderRFQ(uint256 orderInfo) external;

    function destroy() external;

    function fillOrderRFQ(
        LimitOrderProtocolRFQ.OrderRFQ memory order,
        bytes memory signature,
        uint256 makingAmount,
        uint256 takingAmount
    ) external payable returns (uint256, uint256);

    function fillOrderRFQTo(
        LimitOrderProtocolRFQ.OrderRFQ memory order,
        bytes memory signature,
        uint256 makingAmount,
        uint256 takingAmount,
        address target
    ) external payable returns (uint256, uint256);

    function fillOrderRFQToWithPermit(
        LimitOrderProtocolRFQ.OrderRFQ memory order,
        bytes memory signature,
        uint256 makingAmount,
        uint256 takingAmount,
        address target,
        bytes memory permit
    ) external returns (uint256, uint256);

    function invalidatorForOrderRFQ(address maker, uint256 slot) external view returns (uint256);

    function owner() external view returns (address);

    function renounceOwnership() external;

    function rescueFunds(address token, uint256 amount) external;

    function swap(address caller, SwapDescription memory desc, bytes memory data)
        external
        payable
        returns (uint256 returnAmount, uint256 gasLeft);

    function transferOwnership(address newOwner) external;

    function uniswapV3Swap(uint256 amount, uint256 minReturn, uint256[] memory pools)
        external
        payable
        returns (uint256 returnAmount);

    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes memory) external;

    function uniswapV3SwapTo(address recipient, uint256 amount, uint256 minReturn, uint256[] memory pools)
        external
        payable
        returns (uint256 returnAmount);

    function uniswapV3SwapToWithPermit(
        address recipient,
        address srcToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory pools,
        bytes memory permit
    ) external returns (uint256 returnAmount);

    function unoswap(address srcToken, uint256 amount, uint256 minReturn, bytes32[] memory pools)
        external
        payable
        returns (uint256 returnAmount);

    function unoswapWithPermit(
        address srcToken,
        uint256 amount,
        uint256 minReturn,
        bytes32[] memory pools,
        bytes memory permit
    ) external returns (uint256 returnAmount);

    receive() external payable;
}

interface LimitOrderProtocolRFQ {
    struct OrderRFQ {
        uint256 info;
        address makerAsset;
        address takerAsset;
        address maker;
        address allowedSender;
        uint256 makingAmount;
        uint256 takingAmount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {Governable} from "./Governable.sol";

abstract contract Keepable is Governable {
    bytes32 public constant KEEPER = bytes32("KEEPER");

    modifier onlyKeeper() {
        if (!hasRole(KEEPER, msg.sender)) {
            revert CallerIsNotKeeper();
        }

        _;
    }

    function addKeeper(address _newKeeper) external onlyGovernor {
        _grantRole(KEEPER, _newKeeper);

        emit KeeperAdded(_newKeeper);
    }

    function removeKeeper(address _operator) external onlyGovernor {
        _revokeRole(KEEPER, _operator);

        emit KeeperRemoved(_operator);
    }

    event KeeperAdded(address _newKeeper);
    event KeeperRemoved(address _operator);

    error CallerIsNotKeeper();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(account),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
pragma abicoder v2;

import "uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface IV3SwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.10;

interface IUniswapV3Pool {
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(address recipient, uint256 amount0, uint256 amount1, bytes calldata data) external;

    function fee() external view returns (uint24);
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2024 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

// Check https://docs.jonesdao.io/jones-dao/other/bounty for details on our bounty program.

pragma solidity ^0.8.10;

import {FullMath} from "src/libraries/FullMath.sol";
import {TickMath} from "src/libraries/TickMath.sol";
import {IUniswapV3Pool} from "src/interfaces/swap/IUniswapV3Pool.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

library UniV3Library {
    // The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /**
     * @notice Get TWAP of token0 quoted in token1.
     * @param _secondsAgo Length of TWAP.
     */
    function getPrice(address _pool, int24 _secondsAgo) public view returns (uint256) {
        IUniswapV3Pool pool = IUniswapV3Pool(_pool);
        // Avoid revert with arg 0 and get spot price.
        _secondsAgo = _secondsAgo == 0 ? int24(1) : _secondsAgo;

        uint32[] memory secondsAgo = new uint32[](2);

        secondsAgo[0] = uint32(uint24(_secondsAgo));
        secondsAgo[1] = 0;

        // Get cumulative ticks
        (int56[] memory tickCumulative,) = pool.observe(secondsAgo);

        // Now get the cumulative tick just for the specified timeframe (_secondsAgo).
        int56 deltaCumulativeTicks = tickCumulative[1] - tickCumulative[0];

        // Get the arithmetic mean of the delta between the two cumulative ticks.
        int24 arithmeticMeanTick = int24(deltaCumulativeTicks / _secondsAgo);

        // Rounding to negative infinity.
        if (deltaCumulativeTicks < 0 && (deltaCumulativeTicks % _secondsAgo != 0)) {
            arithmeticMeanTick = arithmeticMeanTick - 1;
        }

        // One unit of token0, so we if for example token has 8 decimals, one unit will be 10 ** 8 = 100000000.
        uint256 oneUnit = 10 ** IERC20Metadata(pool.token0()).decimals();

        return getQuoteAtTick(arithmeticMeanTick, uint128(oneUnit), pool.token0(), pool.token1());
    }

    function getSpot(address _pool) public view returns (uint256) {
        return getPrice(_pool, 0);
    }

    function getPool(address factory, address tokenA, address tokenB, uint24 fee, bytes32 initCodeHash)
        public
        pure
        returns (IUniswapV3Pool)
    {
        return IUniswapV3Pool(computeAddress(factory, getPoolKey(tokenA, tokenB, fee), initCodeHash));
    }

    /**
     * @notice Returns PoolKey: the ordered tokens with the matched fee levels
     * @param tokenA The first token of a pool, unsorted
     * @param tokenB The second token of a pool, unsorted
     * @param fee The fee level of the pool
     * @return Poolkey The pool details with ordered token0 and token1 assignments
     */
    function getPoolKey(address tokenA, address tokenB, uint24 fee) private pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    /**
     * @notice Deterministically computes the pool address given the factory and PoolKey
     * @param factory The Uniswap V3 factory contract address
     * @param key The PoolKey
     * @return pool The contract address of the V3 pool
     */
    function computeAddress(address factory, PoolKey memory key, bytes32 initCodeHash)
        private
        pure
        returns (address pool)
    {
        require(key.token0 < key.token1);
        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff", factory, keccak256(abi.encode(key.token0, key.token1, key.fee)), initCodeHash
                        )
                    )
                )
            )
        );
    }

    /**
     * @notice Given a tick and a token amount, calculates the amount of token received in exchange
     * @param tick Tick value used to calculate the quote
     * @param baseAmount Amount of token to be converted
     * @param baseToken Address of an ERC20 token contract used as the baseAmount denomination
     * @param quoteToken Address of an ERC20 token contract used as the quoteAmount denomination
     * @return quoteAmount Amount of quoteToken received for baseAmount of baseToken
     *
     */
    function getQuoteAtTick(int24 tick, uint128 baseAmount, address baseToken, address quoteToken)
        private
        pure
        returns (uint256 quoteAmount)
    {
        uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(tick);

        // Calculate quoteAmount with better precision if it doesn't overflow when multiplied by itself
        if (sqrtRatioX96 <= type(uint128).max) {
            uint256 ratioX192 = uint256(sqrtRatioX96) * sqrtRatioX96;
            quoteAmount = baseToken < quoteToken
                ? FullMath.mulDiv(ratioX192, baseAmount, 1 << 192)
                : FullMath.mulDiv(1 << 192, baseAmount, ratioX192);
        } else {
            uint256 ratioX128 = FullMath.mulDiv(sqrtRatioX96, sqrtRatioX96, 1 << 64);
            quoteAmount = baseToken < quoteToken
                ? FullMath.mulDiv(ratioX128, baseAmount, 1 << 128)
                : FullMath.mulDiv(1 << 128, baseAmount, ratioX128);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

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

/// @title Interface for making arbitrary calls during swap
interface IAggregationExecutor {
    /// @notice propagates information about original msg.sender and executes arbitrary data
    function execute(address msgSender) external payable; // 0x4b64e492
}

interface IGenericRouter {
    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address payable srcReceiver;
        address payable dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
    }

    /// @notice Performs a swap, delegating all calls encoded in `data` to `executor`. See tests for usage examples
    /// @dev router keeps 1 wei of every token on the contract balance for gas optimisations reasons. This affects first swap of every token by leaving 1 wei on the contract.
    /// @param executor Aggregation executor that executes calls described in `data`
    /// @param desc Swap description
    /// @param permit Should contain valid permit that can be used in `IERC20Permit.permit` calls.
    /// @param data Encoded calls that `caller` should execute in between of swaps
    /// @return returnAmount Resulting token amount
    /// @return spentAmount Source token amount
    function swap(
        IAggregationExecutor executor,
        SwapDescription calldata desc,
        bytes calldata permit,
        bytes calldata data
    ) external payable returns (uint256 returnAmount, uint256 spentAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IJonesGlpOldRewards {
    function balanceOf(address _user) external returns (uint256);
    function getReward(address _user) external returns (uint256);
    function withdraw(address _user, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/extensions/ERC4626.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../utils/SafeERC20.sol";
import "../../../interfaces/IERC4626.sol";
import "../../../utils/math/Math.sol";

/**
 * @dev Implementation of the ERC4626 "Tokenized Vault Standard" as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[EIP-4626].
 *
 * This extension allows the minting and burning of "shares" (represented using the ERC20 inheritance) in exchange for
 * underlying "assets" through standardized {deposit}, {mint}, {redeem} and {burn} workflows. This contract extends
 * the ERC20 standard. Any additional extensions included along it would affect the "shares" token represented by this
 * contract and not the "assets" token which is an independent contract.
 *
 * CAUTION: Deposits and withdrawals may incur unexpected slippage. Users should verify that the amount received of
 * shares or assets is as expected. EOAs should operate through a wrapper that performs these checks such as
 * https://github.com/fei-protocol/ERC4626#erc4626router-and-base[ERC4626Router].
 *
 * _Available since v4.7._
 */
abstract contract ERC4626 is ERC20, IERC4626 {
    using Math for uint256;

    IERC20Metadata private immutable _asset;

    /**
     * @dev Set the underlying asset contract. This must be an ERC20-compatible contract (ERC20 or ERC777).
     */
    constructor(IERC20Metadata asset_) {
        _asset = asset_;
    }

    /** @dev See {IERC4626-asset}. */
    function asset() public view virtual override returns (address) {
        return address(_asset);
    }

    /** @dev See {IERC4626-totalAssets}. */
    function totalAssets() public view virtual override returns (uint256) {
        return _asset.balanceOf(address(this));
    }

    /** @dev See {IERC4626-convertToShares}. */
    function convertToShares(uint256 assets) public view virtual override returns (uint256 shares) {
        return _convertToShares(assets, Math.Rounding.Down);
    }

    /** @dev See {IERC4626-convertToAssets}. */
    function convertToAssets(uint256 shares) public view virtual override returns (uint256 assets) {
        return _convertToAssets(shares, Math.Rounding.Down);
    }

    /** @dev See {IERC4626-maxDeposit}. */
    function maxDeposit(address) public view virtual override returns (uint256) {
        return _isVaultCollateralized() ? type(uint256).max : 0;
    }

    /** @dev See {IERC4626-maxMint}. */
    function maxMint(address) public view virtual override returns (uint256) {
        return type(uint256).max;
    }

    /** @dev See {IERC4626-maxWithdraw}. */
    function maxWithdraw(address owner) public view virtual override returns (uint256) {
        return _convertToAssets(balanceOf(owner), Math.Rounding.Down);
    }

    /** @dev See {IERC4626-maxRedeem}. */
    function maxRedeem(address owner) public view virtual override returns (uint256) {
        return balanceOf(owner);
    }

    /** @dev See {IERC4626-previewDeposit}. */
    function previewDeposit(uint256 assets) public view virtual override returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Down);
    }

    /** @dev See {IERC4626-previewMint}. */
    function previewMint(uint256 shares) public view virtual override returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Up);
    }

    /** @dev See {IERC4626-previewWithdraw}. */
    function previewWithdraw(uint256 assets) public view virtual override returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Up);
    }

    /** @dev See {IERC4626-previewRedeem}. */
    function previewRedeem(uint256 shares) public view virtual override returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Down);
    }

    /** @dev See {IERC4626-deposit}. */
    function deposit(uint256 assets, address receiver) public virtual override returns (uint256) {
        require(assets <= maxDeposit(receiver), "ERC4626: deposit more than max");

        uint256 shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);

        return shares;
    }

    /** @dev See {IERC4626-mint}. */
    function mint(uint256 shares, address receiver) public virtual override returns (uint256) {
        require(shares <= maxMint(receiver), "ERC4626: mint more than max");

        uint256 assets = previewMint(shares);
        _deposit(_msgSender(), receiver, assets, shares);

        return assets;
    }

    /** @dev See {IERC4626-withdraw}. */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual override returns (uint256) {
        require(assets <= maxWithdraw(owner), "ERC4626: withdraw more than max");

        uint256 shares = previewWithdraw(assets);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return shares;
    }

    /** @dev See {IERC4626-redeem}. */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual override returns (uint256) {
        require(shares <= maxRedeem(owner), "ERC4626: redeem more than max");

        uint256 assets = previewRedeem(shares);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return assets;
    }

    /**
     * @dev Internal conversion function (from assets to shares) with support for rounding direction.
     *
     * Will revert if assets > 0, totalSupply > 0 and totalAssets = 0. That corresponds to a case where any asset
     * would represent an infinite amout of shares.
     */
    function _convertToShares(uint256 assets, Math.Rounding rounding) internal view virtual returns (uint256 shares) {
        uint256 supply = totalSupply();
        return
            (assets == 0 || supply == 0)
                ? assets.mulDiv(10**decimals(), 10**_asset.decimals(), rounding)
                : assets.mulDiv(supply, totalAssets(), rounding);
    }

    /**
     * @dev Internal conversion function (from shares to assets) with support for rounding direction.
     */
    function _convertToAssets(uint256 shares, Math.Rounding rounding) internal view virtual returns (uint256 assets) {
        uint256 supply = totalSupply();
        return
            (supply == 0)
                ? shares.mulDiv(10**_asset.decimals(), 10**decimals(), rounding)
                : shares.mulDiv(totalAssets(), supply, rounding);
    }

    /**
     * @dev Deposit/mint common workflow.
     */
    function _deposit(
        address caller,
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal virtual {
        // If _asset is ERC777, `transferFrom` can trigger a reenterancy BEFORE the transfer happens through the
        // `tokensToSend` hook. On the other hand, the `tokenReceived` hook, that is triggered after the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer before we mint so that any reentrancy would happen before the
        // assets are transfered and before the shares are minted, which is a valid state.
        // slither-disable-next-line reentrancy-no-eth
        SafeERC20.safeTransferFrom(_asset, caller, address(this), assets);
        _mint(receiver, shares);

        emit Deposit(caller, receiver, assets, shares);
    }

    /**
     * @dev Withdraw/redeem common workflow.
     */
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal virtual {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }

        // If _asset is ERC777, `transfer` can trigger a reentrancy AFTER the transfer happens through the
        // `tokensReceived` hook. On the other hand, the `tokensToSend` hook, that is triggered before the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer after the burn so that any reentrancy would happen after the
        // shares are burned and after the assets are transfered, which is a valid state.
        _burn(owner, shares);
        SafeERC20.safeTransfer(_asset, receiver, assets);

        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    function _isVaultCollateralized() private view returns (bool) {
        return totalAssets() > 0 || totalSupply() == 0;
    }
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 Jones DAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

pragma solidity ^0.8.10;

import {ERC4626} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {JonesGovernableVault} from "./JonesGovernableVault.sol";
import {IAggregatorV3} from "../interfaces/IAggregatorV3.sol";
import {IJonesUsdVault} from "../interfaces/IJonesUsdVault.sol";

abstract contract JonesUsdVault is JonesGovernableVault, ERC4626, IJonesUsdVault {
    IAggregatorV3 public priceOracle;

    constructor(IAggregatorV3 _priceOracle) {
        priceOracle = _priceOracle;
    }

    function setPriceAggregator(IAggregatorV3 _newPriceOracle) external onlyGovernor {
        emit PriceOracleUpdated(address(priceOracle), address(_newPriceOracle));

        priceOracle = _newPriceOracle;
    }

    function tvl() external view returns (uint256) {
        return _toUsdValue(totalAssets());
    }

    function _toUsdValue(uint256 _value) internal view returns (uint256) {
        IAggregatorV3 oracle = priceOracle;

        (, int256 currentPrice,,,) = oracle.latestRoundData();

        uint8 totalDecimals = IERC20Metadata(asset()).decimals() + oracle.decimals();
        uint8 targetDecimals = 18;

        return totalDecimals > targetDecimals
            ? (_value * uint256(currentPrice)) / 10 ** (totalDecimals - targetDecimals)
            : (_value * uint256(currentPrice)) * 10 ** (targetDecimals - totalDecimals);
    }

    event PriceOracleUpdated(address _oldPriceOracle, address _newPriceOracle);
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 Jones DAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

pragma solidity ^0.8.10;

import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {ERC4626} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {JonesGovernableVault} from "./JonesGovernableVault.sol";
import {IJonesBorrowableVault} from "../interfaces/IJonesBorrowableVault.sol";
import {Pausable} from "../common/Pausable.sol";

abstract contract JonesBorrowableVault is JonesGovernableVault, ERC4626, IJonesBorrowableVault, Pausable {
    bytes32 public constant BORROWER = bytes32("BORROWER");

    modifier onlyBorrower() {
        if (!hasRole(BORROWER, msg.sender)) {
            revert CallerIsNotBorrower();
        }
        _;
    }

    function addBorrower(address _newBorrower) external onlyGovernor {
        _grantRole(BORROWER, _newBorrower);

        emit BorrowerAdded(_newBorrower);
    }

    function removeBorrower(address _borrower) external onlyGovernor {
        _revokeRole(BORROWER, _borrower);

        emit BorrowerRemoved(_borrower);
    }

    function togglePause() external onlyGovernor {
        if (paused()) {
            _unpause();
            return;
        }

        _pause();
    }

    function borrow(uint256 _amount) external virtual onlyBorrower whenNotPaused returns (uint256) {
        IERC20(asset()).transfer(msg.sender, _amount);

        emit AssetsBorrowed(msg.sender, _amount);

        return _amount;
    }

    function repay(uint256 _amount) external virtual onlyBorrower returns (uint256) {
        IERC20(asset()).transferFrom(msg.sender, address(this), _amount);

        emit AssetsRepayed(msg.sender, _amount);

        return _amount;
    }

    event BorrowerAdded(address _newBorrower);
    event BorrowerRemoved(address _borrower);
    event AssetsBorrowed(address _borrower, uint256 _amount);
    event AssetsRepayed(address _borrower, uint256 _amount);

    error CallerIsNotBorrower();
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 Jones DAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

pragma solidity ^0.8.10;

import {JonesGovernableVault} from "./JonesGovernableVault.sol";
import {ERC4626} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol";

abstract contract JonesOperableVault is JonesGovernableVault, ERC4626 {
    bytes32 public constant OPERATOR = bytes32("OPERATOR");

    modifier onlyOperator() {
        if (!hasRole(OPERATOR, msg.sender)) {
            revert CallerIsNotOperator();
        }

        _;
    }

    function addOperator(address _newOperator) external onlyGovernor {
        _grantRole(OPERATOR, _newOperator);

        emit OperatorAdded(_newOperator);
    }

    function removeOperator(address _operator) external onlyGovernor {
        _revokeRole(OPERATOR, _operator);

        emit OperatorRemoved(_operator);
    }

    function deposit(uint256 _assets, address _receiver) public virtual override onlyOperator returns (uint256) {
        return super.deposit(_assets, _receiver);
    }

    function mint(uint256 _shares, address _receiver) public virtual override onlyOperator returns (uint256) {
        return super.mint(_shares, _receiver);
    }

    function withdraw(uint256 _assets, address _receiver, address _owner)
        public
        virtual
        override
        onlyOperator
        returns (uint256)
    {
        return super.withdraw(_assets, _receiver, _owner);
    }

    function redeem(uint256 _shares, address _receiver, address _owner)
        public
        virtual
        override
        onlyOperator
        returns (uint256)
    {
        return super.redeem(_shares, _receiver, _owner);
    }

    event OperatorAdded(address _newOperator);
    event OperatorRemoved(address _operator);

    error CallerIsNotOperator();
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 Jones DAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

pragma solidity ^0.8.10;

import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";

abstract contract JonesGovernableVault is AccessControl {
    bytes32 public constant GOVERNOR = bytes32("GOVERNOR");

    constructor(address _governor) {
        _grantRole(GOVERNOR, _governor);
    }

    modifier onlyGovernor() {
        if (!hasRole(GOVERNOR, msg.sender)) {
            revert CallerIsNotGovernor();
        }
        _;
    }

    function updateGovernor(address _newGovernor) external onlyGovernor {
        _revokeRole(GOVERNOR, msg.sender);
        _grantRole(GOVERNOR, _newGovernor);

        emit GovernorUpdated(msg.sender, _newGovernor);
    }

    event GovernorUpdated(address _oldGovernor, address _newGovernor);

    error CallerIsNotGovernor();
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-3.0
/*                            ******@@@@@@@@@**@*                               
                        ***@@@@@@@@@@@@@@@@@@@@@@**                             
                     *@@@@@@**@@@@@@@@@@@@@@@@@*@@@*                            
                  *@@@@@@@@@@@@@@@@@@@*@@@@@@@@@@@*@**                          
                 *@@@@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@*                         
                **@@@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@@@**                       
                **@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@@@@@@@*                      
                **@@@@@@@@@@@@@@@@*************************                    
                **@@@@@@@@***********************************                   
                 *@@@***********************&@@@@@@@@@@@@@@@****,    ******@@@@*
           *********************@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@************* 
      ***@@@@@@@@@@@@@@@*****@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@****@@*********      
   **@@@@@**********************@@@@*****************#@@@@**********            
  *@@******************************************************                     
 *@************************************                                         
 @*******************************                                               
 *@*************************                                                    
   ********************* 
   
    /$$$$$                                               /$$$$$$$   /$$$$$$   /$$$$$$ 
   |__  $$                                              | $$__  $$ /$$__  $$ /$$__  $$
      | $$  /$$$$$$  /$$$$$$$   /$$$$$$   /$$$$$$$      | $$  \ $$| $$  \ $$| $$  \ $$
      | $$ /$$__  $$| $$__  $$ /$$__  $$ /$$_____/      | $$  | $$| $$$$$$$$| $$  | $$
 /$$  | $$| $$  \ $$| $$  \ $$| $$$$$$$$|  $$$$$$       | $$  | $$| $$__  $$| $$  | $$
| $$  | $$| $$  | $$| $$  | $$| $$_____/ \____  $$      | $$  | $$| $$  | $$| $$  | $$
|  $$$$$$/|  $$$$$$/| $$  | $$|  $$$$$$$ /$$$$$$$/      | $$$$$$$/| $$  | $$|  $$$$$$/
 \______/  \______/ |__/  |__/ \_______/|_______/       |_______/ |__/  |__/ \______/                                      */

pragma solidity ^0.8.10;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IUniswapV2Router02} from "../interfaces/IUniswapV2Router02.sol";

library SushiAdapter {
    using SafeERC20 for IERC20;

    /**
     * Sells the received tokens for the provided amounts for the last token in the route
     * Temporary solution until we implement accumulation policy.
     * @param self the sushi router used to perform the sale.
     * @param _assetAmounts output amount from selling the tokens.
     * @param _tokens tokens to sell.
     * @param _recepient recepient address.
     * @param _routes routes to sell each token
     */
    function sellTokens(
        IUniswapV2Router02 self,
        uint256[] memory _assetAmounts,
        address[] memory _tokens,
        address _recepient,
        address[][] memory _routes
    ) public {
        uint256 amountsLength = _assetAmounts.length;
        uint256 tokensLength = _tokens.length;
        uint256 routesLength = _routes.length;

        require(amountsLength == tokensLength, "SRE1");
        require(routesLength == tokensLength, "SRE1");

        uint256 deadline = block.timestamp + 120;
        for (uint256 i = 0; i < tokensLength; i++) {
            _sellTokens(self, IERC20(_tokens[i]), _assetAmounts[i], _recepient, deadline, _routes[i]);
        }
    }

    /**
     * Sells the received tokens for the provided amounts for ETH
     * Temporary solution until we implement accumulation policy.
     * @param self the sushi router used to perform the sale.
     * @param _assetAmounts output amount from selling the tokens.
     * @param _tokens tokens to sell.
     * @param _recepient recepient address.
     * @param _routes routes to sell each token.
     */
    function sellTokensForEth(
        IUniswapV2Router02 self,
        uint256[] memory _assetAmounts,
        address[] memory _tokens,
        address _recepient,
        address[][] memory _routes
    ) public {
        uint256 amountsLength = _assetAmounts.length;
        uint256 tokensLength = _tokens.length;
        uint256 routesLength = _routes.length;

        require(amountsLength == tokensLength, "SRE1");
        require(routesLength == tokensLength, "SRE1");

        uint256 deadline = block.timestamp + 120;
        for (uint256 i = 0; i < tokensLength; i++) {
            _sellTokensForEth(self, IERC20(_tokens[i]), _assetAmounts[i], _recepient, deadline, _routes[i]);
        }
    }

    /**
     * Sells one token for a given amount of another.
     * @param self the Sushi router used to perform the sale.
     * @param _route route to swap the token.
     * @param _assetAmount output amount of the last token in the route from selling the first.
     * @param _recepient recepient address.
     */
    function sellTokensForExactTokens(
        IUniswapV2Router02 self,
        address[] memory _route,
        uint256 _assetAmount,
        address _recepient,
        address _token
    ) public {
        require(_route.length >= 2, "SRE2");
        uint256 balance = IERC20(_route[0]).balanceOf(_recepient);
        if (balance > 0) {
            uint256 deadline = block.timestamp + 120; // Two minutes
            _sellTokens(self, IERC20(_token), _assetAmount, _recepient, deadline, _route);
        }
    }

    function _sellTokensForEth(
        IUniswapV2Router02 _sushiRouter,
        IERC20 _token,
        uint256 _assetAmount,
        address _recepient,
        uint256 _deadline,
        address[] memory _route
    ) private {
        uint256 balance = _token.balanceOf(_recepient);
        if (balance > 0) {
            _sushiRouter.swapExactTokensForETH(balance, _assetAmount, _route, _recepient, _deadline);
        }
    }

    function swapTokens(
        IUniswapV2Router02 self,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] memory _path,
        address _recepient
    ) external {
        self.swapExactTokensForTokens(_amountIn, _amountOutMin, _path, _recepient, block.timestamp);
    }

    function _sellTokens(
        IUniswapV2Router02 _sushiRouter,
        IERC20 _token,
        uint256 _assetAmount,
        address _recepient,
        uint256 _deadline,
        address[] memory _route
    ) private {
        uint256 balance = _token.balanceOf(_recepient);
        if (balance > 0) {
            _sushiRouter.swapExactTokensForTokens(balance, _assetAmount, _route, _recepient, _deadline);
        }
    }

    // ERROR MAPPING:
    // {
    //   "SRE1": "Rewards: token, amount and routes lenght must match",
    //   "SRE2": "Length of route must be at least 2",
    // }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

library Babylonian {
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IStableSwap is IERC20 {
    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount) external returns (uint256);

    function remove_liquidity(uint256 burn_amount, uint256[2] calldata min_amounts)
        external
        returns (uint256[2] memory);

    function remove_liquidity_one_coin(uint256 burn_amount, int128 i, uint256 min_amount) external returns (uint256);

    function calc_token_amount(uint256[2] calldata amounts, bool is_deposit) external view returns (uint256);

    function calc_withdraw_one_coin(uint256 burn_amount, int128 i) external view returns (uint256);

    function coins(uint256 i) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
/*                            ******@@@@@@@@@**@*                               
                        ***@@@@@@@@@@@@@@@@@@@@@@**                             
                     *@@@@@@**@@@@@@@@@@@@@@@@@*@@@*                            
                  *@@@@@@@@@@@@@@@@@@@*@@@@@@@@@@@*@**                          
                 *@@@@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@*                         
                **@@@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@@@**                       
                **@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@@@@@@@*                      
                **@@@@@@@@@@@@@@@@*************************                    
                **@@@@@@@@***********************************                   
                 *@@@***********************&@@@@@@@@@@@@@@@****,    ******@@@@*
           *********************@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@************* 
      ***@@@@@@@@@@@@@@@*****@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@****@@*********      
   **@@@@@**********************@@@@*****************#@@@@**********            
  *@@******************************************************                     
 *@************************************                                         
 @*******************************                                               
 *@*************************                                                    
   *********************  
   
    /$$$$$                                               /$$$$$$$   /$$$$$$   /$$$$$$ 
   |__  $$                                              | $$__  $$ /$$__  $$ /$$__  $$
      | $$  /$$$$$$  /$$$$$$$   /$$$$$$   /$$$$$$$      | $$  \ $$| $$  \ $$| $$  \ $$
      | $$ /$$__  $$| $$__  $$ /$$__  $$ /$$_____/      | $$  | $$| $$$$$$$$| $$  | $$
 /$$  | $$| $$  \ $$| $$  \ $$| $$$$$$$$|  $$$$$$       | $$  | $$| $$__  $$| $$  | $$
| $$  | $$| $$  | $$| $$  | $$| $$_____/ \____  $$      | $$  | $$| $$  | $$| $$  | $$
|  $$$$$$/|  $$$$$$/| $$  | $$|  $$$$$$$ /$$$$$$$/      | $$$$$$$/| $$  | $$|  $$$$$$/
 \______/  \______/ |__/  |__/ \_______/|_______/       |_______/ |__/  |__/ \______/                                      */

pragma solidity ^0.8.10;

// Interfaces
import {IStableSwap} from "../interfaces/IStableSwap.sol";
import {IUniswapV2Router02} from "../interfaces/IUniswapV2Router02.sol";

library Curve2PoolAdapter {
    address constant USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address constant SUSHI_ROUTER = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;

    IUniswapV2Router02 constant sushiRouter = IUniswapV2Router02(SUSHI_ROUTER);

    /**
     * @notice Swaps a token for 2CRV
     * @param _inputToken The token to swap
     * @param _amount The token amount to swap
     * @param _stableToken The address of the stable token to swap the `_inputToken`
     * @param _minStableAmount The minimum output amount of `_stableToken`
     * @param _min2CrvAmount The minimum output amount of 2CRV to receive
     * @param _recipient The address that's going to receive the 2CRV
     * @return The amount of 2CRV received
     */
    function swapTokenFor2Crv(
        IStableSwap self,
        address _inputToken,
        uint256 _amount,
        address _stableToken,
        uint256 _minStableAmount,
        uint256 _min2CrvAmount,
        address _recipient
    ) public returns (uint256) {
        if (_stableToken != USDC && _stableToken != USDT) {
            revert INVALID_STABLE_TOKEN();
        }

        address[] memory route = _swapTokenFor2CrvRoute(_inputToken, _stableToken);

        uint256[] memory swapOutputs =
            sushiRouter.swapExactTokensForTokens(_amount, _minStableAmount, route, _recipient, block.timestamp);

        uint256 stableOutput = swapOutputs[swapOutputs.length - 1];

        uint256 amountOut = swapStableFor2Crv(self, _stableToken, stableOutput, _min2CrvAmount);

        emit SwapTokenFor2Crv(_amount, amountOut, _inputToken);

        return amountOut;
    }

    /**
     * @notice Swaps 2CRV for `_outputToken`
     * @param _outputToken The output token to receive
     * @param _amount The amount of 2CRV to swap
     * @param _stableToken The address of the stable token to receive
     * @param _minStableAmount The minimum output amount of `_stableToken` to receive
     * @param _minTokenAmount The minimum output amount of `_outputToken` to receive
     * @param _recipient The address that's going to receive the `_outputToken`
     * @return The amount of `_outputToken` received
     */
    function swap2CrvForToken(
        IStableSwap self,
        address _outputToken,
        uint256 _amount,
        address _stableToken,
        uint256 _minStableAmount,
        uint256 _minTokenAmount,
        address _recipient
    ) public returns (uint256) {
        if (_stableToken != USDC && _stableToken != USDT) {
            revert INVALID_STABLE_TOKEN();
        }

        uint256 stableAmount = swap2CrvForStable(self, _stableToken, _amount, _minStableAmount);

        address[] memory route = _swapStableForTokenRoute(_outputToken, _stableToken);

        uint256[] memory swapOutputs =
            sushiRouter.swapExactTokensForTokens(stableAmount, _minTokenAmount, route, _recipient, block.timestamp);

        uint256 amountOut = swapOutputs[swapOutputs.length - 1];

        emit Swap2CrvForToken(_amount, amountOut, _outputToken);

        return amountOut;
    }

    /**
     * @notice Swaps 2CRV for a stable token
     * @param _stableToken The stable token address
     * @param _amount The amount of 2CRV to sell
     * @param _minStableAmount The minimum amount stables to receive
     * @return The amount of stables received
     */
    function swap2CrvForStable(IStableSwap self, address _stableToken, uint256 _amount, uint256 _minStableAmount)
        public
        returns (uint256)
    {
        int128 stableIndex;

        if (_stableToken != USDC && _stableToken != USDT) {
            revert INVALID_STABLE_TOKEN();
        }

        if (_stableToken == USDC) {
            stableIndex = 0;
        }
        if (_stableToken == USDT) {
            stableIndex = 1;
        }

        return self.remove_liquidity_one_coin(_amount, stableIndex, _minStableAmount);
    }

    /**
     * @notice Swaps a stable token for 2CRV
     * @param _stableToken The stable token address
     * @param _amount The amount of `_stableToken` to sell
     * @param _min2CrvAmount The minimum amount of 2CRV to receive
     * @return The amount of 2CRV received
     */
    function swapStableFor2Crv(IStableSwap self, address _stableToken, uint256 _amount, uint256 _min2CrvAmount)
        public
        returns (uint256)
    {
        uint256[2] memory deposits;
        if (_stableToken != USDC && _stableToken != USDT) {
            revert INVALID_STABLE_TOKEN();
        }

        if (_stableToken == USDC) {
            deposits = [_amount, 0];
        }
        if (_stableToken == USDT) {
            deposits = [0, _amount];
        }

        return self.add_liquidity(deposits, _min2CrvAmount);
    }

    function _swapStableForTokenRoute(address _outputToken, address _stableToken)
        internal
        pure
        returns (address[] memory)
    {
        address[] memory route;
        if (_outputToken == WETH) {
            // handle weth swaps
            route = new address[](2);
            route[0] = _stableToken;
            route[1] = _outputToken;
        } else {
            route = new address[](3);
            route[0] = _stableToken;
            route[1] = WETH;
            route[2] = _outputToken;
        }
        return route;
    }

    function _swapTokenFor2CrvRoute(address _inputToken, address _stableToken)
        internal
        pure
        returns (address[] memory)
    {
        address[] memory route;
        if (_inputToken == WETH) {
            // handle weth swaps
            route = new address[](2);
            route[0] = _inputToken;
            route[1] = _stableToken;
        } else {
            route = new address[](3);
            route[0] = _inputToken;
            route[1] = WETH;
            route[2] = _stableToken;
        }
        return route;
    }

    event Swap2CrvForToken(uint256 _amountIn, uint256 _amountOut, address _token);
    event SwapTokenFor2Crv(uint256 _amountIn, uint256 _amountOut, address _token);

    error INVALID_STABLE_TOKEN();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0 = a * b; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            // Subtract 256 bit remainder from 512 bit number
            assembly {
                let remainder := mulmod(a, b, denominator)
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (0 - denominator) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the preconditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            if (a == 0 || ((result = a * b) / a == b)) {
                require(denominator > 0);
                assembly {
                    result := add(div(result, denominator), gt(mod(result, denominator), 0))
                }
            } else {
                result = mulDiv(a, b, denominator);
                if (mulmod(a, b, denominator) > 0) {
                    require(result < type(uint256).max);
                    result++;
                }
            }
        }
    }

    /// @notice Returns ceil(x / y)
    /// @dev division by 0 has unspecified behavior, and must be checked externally
    /// @param x The dividend
    /// @param y The divisor
    /// @return z The quotient, ceil(x / y)
    function unsafeDivRoundingUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := add(div(x, y), gt(mod(x, y), 0))
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.10;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/blob/main/contracts/libraries
library TickMath {
    error tickOutOfRange();
    error priceOutOfRange();
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128

    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return price A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 price) {
        unchecked {
            // get abs value
            int24 absTickMask = tick >> (24 - 1);
            uint256 absTick = uint24((tick + absTickMask) ^ absTickMask);
            if (absTick > uint24(MAX_TICK)) revert tickOutOfRange();

            uint256 ratio = 0x100000000000000000000000000000000;
            if (absTick & 0x1 != 0) ratio = 0xfffcb933bd6fad37aa2d162d1a594001;
            if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
            if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
            if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
            if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
            if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
            if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
            if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
            if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
            if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
            if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
            if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
            if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
            if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
            if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
            if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
            if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
            if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
            if (absTick >= 0x40000) {
                if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
                if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;
            }

            if (tick > 0) {
                assembly {
                    ratio := div(not(0), ratio)
                }
            }

            // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
            // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
            // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
            price = uint160((ratio + 0xFFFFFFFF) >> 32);
        }
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case price < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param price The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 price) internal pure returns (int24 tick) {
        unchecked {
            // second inequality must be >= because the price can never reach the price at the max tick
            if (price < MIN_SQRT_RATIO || price >= MAX_SQRT_RATIO) revert priceOutOfRange();
            uint256 ratio = uint256(price) << 32;

            uint256 r = ratio;
            uint256 msb;

            assembly {
                let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(5, gt(r, 0xFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(4, gt(r, 0xFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(3, gt(r, 0xFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(2, gt(r, 0xF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(1, gt(r, 0x3))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := gt(r, 0x1)
                msb := or(msb, f)
            }

            if (msb >= 128) r = ratio >> (msb - 127);
            else r = ratio << (127 - msb);

            int256 log_2 = (int256(msb) - 128) << 64;

            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(63, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(62, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(61, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(60, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(59, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(58, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(57, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(56, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(55, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(54, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(53, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(52, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(51, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(50, f))
            }

            int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

            int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
            int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

            tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= price ? tickHi : tickLow;
        }
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(uint256 amountOut, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory amounts);

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint256 amountB);

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        external
        pure
        returns (uint256 amountOut);

    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut)
        external
        pure
        returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
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
interface IERC165Upgradeable {
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