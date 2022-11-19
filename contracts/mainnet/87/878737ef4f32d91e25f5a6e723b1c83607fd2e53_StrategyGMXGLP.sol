// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IERC20} from "./interfaces/IERC20.sol";
import {Util} from "./Util.sol";
import {IStrategyHelper} from "./interfaces/IStrategyHelper.sol";

abstract contract Strategy is Util {
    error OverCap();

    uint256 public cap;
    uint256 public totalShares;
    uint256 public slippage = 50;
    IStrategyHelper strategyHelper;

    event FileInt(bytes32 indexed what, uint256 data);
    event FileAddress(bytes32 indexed what, address data);
    event Mint(address indexed ast, uint256 amt, uint256 sha);
    event Burn(address indexed ast, uint256 amt, uint256 sha);

    constructor(address _strategyHelper) {
        strategyHelper = IStrategyHelper(_strategyHelper);
        exec[msg.sender] = true;
    }

    function file(bytes32 what, uint256 data) external auth {
        if (what == "cap") cap = data;
        if (what == "paused") paused = data == 1;
        if (what == "slippage") slippage = data;
        emit FileInt(what, data);
    }

    function file(bytes32 what, address data) external auth {
        if (what == "exec") exec[data] = !exec[data];
        emit FileAddress(what, data);
    }

    function getSlippage(bytes memory dat) internal view returns (uint256) {
        if (dat.length > 0) {
            (uint256 slp) = abi.decode(dat, (uint256));
            return slp;
        }
        return slippage;
    }

    function rate(uint256) public view virtual returns (uint256) {
        // calculate vault / lp value in usd (1e18) terms (through swap if needed)
        return 0;
    }

    function mint(address ast, uint256 amt, bytes calldata dat) external auth live returns (uint256) {
        pull(IERC20(ast), msg.sender, amt);
        uint256 sha = _mint(ast, amt, dat);
        totalShares += sha;
        if (cap != 0 && rate(totalShares) > cap) revert OverCap();
        emit Mint(ast, amt, sha);
        return sha;
    }

    function burn(address ast, uint256 sha, bytes calldata dat) external auth live returns (uint256) {
        uint256 amt = _burn(ast, sha, dat);
        totalShares -= sha;
        emit Burn(ast, amt, sha);
        return amt;
    }

    function _mint(address ast, uint256 amt, bytes calldata dat) internal virtual returns (uint256) { }

    function _burn(address ast, uint256 sha, bytes calldata dat) internal virtual returns (uint256) { }
}

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
    string public constant name = "GMX GLP";
    IRewardRouter public rewardRouter;
    IGlpManager public glpManager;
    IERC20 public glp;
    IERC20 public weth;

    constructor(
        address _strategyHelper,
        address _rewardRouter,
        address _weth
    ) Strategy(_strategyHelper) {
        rewardRouter = IRewardRouter(_rewardRouter);
        glpManager = IGlpManager(rewardRouter.glpManager());
        glp = IERC20(glpManager.glp());
        weth = IERC20(_weth);
    }

    function rate(uint256 sha) public view override returns (uint256) {
        if (sha == 0 || totalShares == 0) return 0;
        uint256 tot = glp.totalSupply();
        uint256 amt = IERC20(rewardRouter.stakedGlpTracker()).balanceOf(address(this));
        uint256 val = glpManager.getAumInUsdg(false);
        uint256 rew = IRewardTracker(rewardRouter.feeGlpTracker()).claimable(address(this));
        uint256 amtval = (val * amt / tot) + strategyHelper.value(address(weth), rew);
        return sha * amtval / totalShares;
    }

    function _mint(address ast, uint256 amt, bytes calldata dat) internal override returns (uint256) {
        uint256 slp = getSlippage(dat);
        uint256 tma = IERC20(rewardRouter.stakedGlpTracker()).balanceOf(address(this));
        uint256 pri = glpManager.getAumInUsdg(true) * 1e18 / glp.totalSupply();
        uint256 minUsd = strategyHelper.value(ast, amt) * slp / 10000;
        uint256 minGlp = minUsd * 1e18 / pri;
        IERC20(ast).approve(address(glpManager), amt);
        uint256 out = rewardRouter.mintAndStakeGlp(ast, amt, minUsd, minGlp);
        return tma == 0 ? out : out * totalShares / tma;
    }

    function _burn(address ast, uint256 sha, bytes calldata dat) internal override returns (uint256) {
        uint256 slp = getSlippage(dat);
        uint256 tma = IERC20(rewardRouter.stakedGlpTracker()).balanceOf(address(this));
        uint256 amt = sha * tma / totalShares;
        uint256 pri = glpManager.getAumInUsdg(false) * 1e18 / glp.totalSupply();
        uint256 min = (amt * pri / 1e18) * slp / 10000;
        min = min * (10 ** IERC20(ast).decimals()) / 1e18;
        return rewardRouter.unstakeAndRedeemGlp(ast, amt, min, msg.sender);
    }

    function earn() public {
        rewardRouter.handleRewards(true, true, true, true, true, true, false);
        uint256 amt = weth.balanceOf(address(this));
        if (amt > 0) {
            weth.approve(address(glpManager), amt);
            rewardRouter.mintAndStakeGlp(address(weth), amt, 0, 0);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IERC20} from './interfaces/IERC20.sol';

contract Util {
    error Paused();
    error Unauthorized();
    error TransferFailed();

    bool public paused;
    mapping(address => bool) public exec;

    modifier live() {
        if (paused) revert Paused();
        _;
    }

    modifier auth() {
        if (!exec[msg.sender]) revert Unauthorized();
        _;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function pull(IERC20 asset, address usr, uint256 amt) internal {
        if (!asset.transferFrom(usr, address(this), amt)) revert TransferFailed();
    }

    function push(IERC20 asset, address usr, uint256 amt) internal {
        if (!asset.transfer(usr, amt)) revert TransferFailed();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

interface IStrategyHelper {
    function price(address) external view returns (uint256);
    function value(address, uint256) external view returns (uint256);
    function convert(address, address, uint256) external view returns (uint256);
    function swap(address ast0, address ast1, uint256 amt, uint256 slp, address to) external returns (uint256);
}