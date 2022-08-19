// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Strategy} from "./Strategy.sol";
import {IERC20} from "./interfaces/IERC20.sol";

interface IRewardRouter {
    function glpManager() external view returns (address);
    function feeGlpTracker() external view returns (address);
    function stakedGlpTracker() external view returns (address);
    function mintAndStakeGlp(
        address _token,
        uint256 _amount,
        uint256 _minUsdg,
        uint256 _minGlp
    )
        external
        returns (uint256);
    function unstakeAndRedeemGlp(
        address _tokenOut,
        uint256 _glpAmount,
        uint256 _minOut,
        address _receiver
    )
        external
        returns (uint256);
    function handleRewards(
        bool _shouldClaimGmx,
        bool _shouldStakeGmx,
        bool _shouldClaimEsGmx,
        bool _shouldStakeEsGmx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth
    ) external;
}

interface IGlpManager {
    function getAumInUsdg(bool) external view returns (uint256);
    function glp() external view returns (address);
}

interface IRewardTracker {
    function claimable(address) external view returns (uint256);
    function depositBalances(address _account, address _depositToken) external view returns (uint256);
}

interface IOracle {
    function latestAnswer() external view returns (int256);
}

contract StrategyGMXGLP is Strategy {
    uint256 public constant bipsDivisor = 10000;

    string public name = "GMX GLP";
    uint256 public slippage = 9900;
    IRewardRouter public rewardRouter;
    IGlpManager public glpManager;
    IERC20 public glp;
    IOracle public oracle; // Chainlink for ETH fee reward token
    address public weth;

    constructor(
        address _asset,
        address _investor,
        address _rewardRouter,
        address _oracle,
        address _weth
    )
        Strategy(_asset, _investor)
    {
        rewardRouter = IRewardRouter(_rewardRouter);
        glpManager = IGlpManager(rewardRouter.glpManager());
        glp = IERC20(glpManager.glp());
        oracle = IOracle(_oracle);
        weth = _weth;
    }

    function setSlippage(uint256 _slippage) external auth {
        slippage = _slippage;
    }

    function rate(uint256 sha) external view override returns (uint256) {
        uint256 tma = IERC20(rewardRouter.stakedGlpTracker()).balanceOf(address(this));
        uint256 aumInUsdg = glpManager.getAumInUsdg(false);
        uint256 glpSupply = glp.totalSupply();
        uint256 usdgAmount = tma * aumInUsdg / glpSupply;

        uint256 ethRewards =
            IRewardTracker(rewardRouter.feeGlpTracker()).claimable(address(this));
        uint256 ethPrice = uint256(oracle.latestAnswer());
        // GLP is 1e18, while oracle price is 1e8, so division by 1e20 is required to get to 1e6 for USDC
        uint256 feesUsd = ethRewards * ethPrice / 1e20;
        uint256 valueUsd = (usdgAmount / 1e12) + feesUsd;

        return sha * valueUsd / totalShares;
    }

    function _mint(uint256 amt) internal override returns (uint256) {
        compound();

        uint256 glpPrice =
            glpManager.getAumInUsdg(true) * 1e18 / glp.totalSupply();
        uint256 minGlp = ((amt * 1e30 / glpPrice) * slippage) / bipsDivisor;
        uint256 minUsdg = amt * 1e12 * slippage / bipsDivisor;

        uint256 tma = IERC20(rewardRouter.stakedGlpTracker()).balanceOf(address(this));

        asset.approve(address(glpManager), amt);
        uint256 newGlp =
            rewardRouter.mintAndStakeGlp(address(asset), amt, minUsdg, minGlp);

        return tma == 0 ? newGlp : newGlp * totalShares / tma;
    }

    function _burn(uint256 sha) internal override returns (uint256) {
        compound();

        uint256 tma = IERC20(rewardRouter.stakedGlpTracker()).balanceOf(address(this));
        uint256 glpAmount = sha * tma / totalShares;

        uint256 glpPrice =
            glpManager.getAumInUsdg(false) * 1e18 / glp.totalSupply();
        uint256 minAmt = ((glpAmount * glpPrice / 1e30) * slippage) / bipsDivisor;

        return rewardRouter.unstakeAndRedeemGlp(
            address(asset), glpAmount, minAmt, address(this)
        );
    }

    function compound() public {
        rewardRouter.handleRewards(true, true, true, true, true, true, false);

        uint256 wethBalance = IERC20(weth).balanceOf(address(this));

        if (wethBalance > 0) {
            IERC20(weth).approve(address(glpManager), wethBalance);
            rewardRouter.mintAndStakeGlp(weth, wethBalance, 0, 0);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IERC20} from "./interfaces/IERC20.sol";

abstract contract Strategy {
    error Paused();
    error NotInvestor();
    error UnknownFile();
    error Unauthorized();
    error TransferFailed();

    IERC20 public asset;
    uint256 public cap;
    bool public paused;
    address public investor;
    mapping(address => bool) public exec;

    uint256 public totalShares;

    event FileInt(bytes32 indexed what, uint256 data);
    event FileAddress(bytes32 indexed what, address data);
    event Mint(uint256 amt, uint256 sha);
    event Burn(uint256 sha, uint256 amt);

    constructor(address _asset, address _investor) {
        asset = IERC20(_asset);
        investor = _investor;
        exec[msg.sender] = true;
    }

    modifier auth() {
        if (!exec[msg.sender]) revert Unauthorized();
        _;
    }

    function file(bytes32 what, uint256 data) external auth {
        if (what == "cap") {
            cap = data;
        } else if (what == "paused") {
            paused = data == 1;
        } else {
            revert UnknownFile();
        }
        emit FileInt(what, data);
    }

    function file(bytes32 what, address data) external auth {
        if (what == "exec") {
            exec[data] = !exec[data];
        } else {
            revert UnknownFile();
        }
        emit FileAddress(what, data);
    }

    function rate(uint256) external view virtual returns (uint256) {
        // calculate vault / lp value in usdc terms (through swap if needed)
        return 0;
    }

    function mint(uint256 amt) external returns (uint256) {
        if (msg.sender != investor) revert NotInvestor();
        if (paused) revert Paused();
        _pull(address(asset), msg.sender, amt);
        uint256 sha = _mint(amt);
        totalShares += sha;
        emit Mint(amt, sha);
        return sha;
    }

    function burn(uint256 sha) external returns (uint256) {
        if (msg.sender != investor) revert NotInvestor();
        if (paused) revert Paused();
        uint256 amt = _burn(sha);
        totalShares -= sha;
        _push(address(asset), msg.sender, amt);
        emit Burn(sha, amt);
        return amt;
    }

    function _pull(address tkn, address usr, uint256 amt) internal {
        if (!IERC20(tkn).transferFrom(usr, address(this), amt)) revert
            TransferFailed();
    }

    function _push(address tkn, address usr, uint256 amt) internal {
        if (!IERC20(tkn).transfer(usr, amt)) revert TransferFailed();
    }

    function _mint(uint256 amt) internal virtual returns (uint256) { // pull in usdc from caller
            // convert usdc to needed assets
            // enter vault / lp
    }

    function _burn(uint256 sha) internal virtual returns (uint256) { // exit vault / lp
            // convert assets to usdc
            // return funds
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IERC20 {
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}