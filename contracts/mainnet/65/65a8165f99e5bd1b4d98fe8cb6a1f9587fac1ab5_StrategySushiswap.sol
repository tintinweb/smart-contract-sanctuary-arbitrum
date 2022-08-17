// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IERC20} from "./interfaces/IERC20.sol";
import {IPairUniV2} from "./interfaces/IPairUniV2.sol";
import {IOracle} from "./interfaces/IOracle.sol";
import {IVault} from "./interfaces/IVault.sol";
import {Strategy} from "./Strategy.sol";


contract StrategySushiswap is Strategy {
    string public name;
    IVault public vault;
    IOracle public oracleToken0; // Chainlink for pool token0
    IOracle public oracleToken1; // Chainlink for pool token1

    constructor(
        address _asset,
        address _investor,
        string memory _name,
        address _vault,
        address _oracleToken0,
        address _oracleToken1
    )
        Strategy(_asset, _investor)
    {
        name = _name;
        vault = IVault(_vault);
        oracleToken0 = IOracle(_oracleToken0);
        oracleToken1 = IOracle(_oracleToken1);
    }

    function getPair() private view returns (IPairUniV2) {
        return IPairUniV2(vault.asset());
    }

    function rate(uint256 sha) external view override returns (uint256) {
        IPairUniV2 pair = getPair();
        uint256 value = 0;
        uint256 lpTotalSupply = pair.totalSupply();
        uint256 lpAmount = vault.totalManagedAssets();
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        {
            uint256 decimals = uint256(IERC20(pair.token0()).decimals());
            uint256 price = uint256(oracleToken0.latestAnswer());
            value += (reserve0 * 1e12 / (10 ** decimals)) * lpAmount / lpTotalSupply
              * price / 1e14;
        }
        {
            uint256 decimals = uint256(IERC20(pair.token1()).decimals());
            uint256 price = uint256(oracleToken1.latestAnswer());
            value += (reserve1 * 1e12 / (10 ** decimals)) * lpAmount / lpTotalSupply
              * price / 1e14;
        }
        return value * sha / totalShares;
    }

    function _mint(uint256 amt) internal override returns (uint256) {
        IPairUniV2 pair = getPair();
        uint256 halfA = amt / 2;
        if (pair.token0() == address(asset)) {
            uint256 halfB = _swap1(pair, amt - halfA);
            _push(pair.token0(), address(pair), halfA);
            _push(pair.token1(), address(pair), halfB);
        } else {
            uint256 halfB = _swap0(pair, amt - halfA);
            _push(pair.token1(), address(pair), halfA);
            _push(pair.token0(), address(pair), halfB);
        }
        pair.mint(address(this));
        pair.skim(address(this));
        uint256 liq = IERC20(address(pair)).balanceOf(address(this));
        IERC20(address(pair)).approve(address(vault), liq);
        uint256 before = IERC20(address(vault)).balanceOf(address(this));
        vault.mint(liq, address(this));
        return IERC20(address(vault)).balanceOf(address(this)) - before;
    }

    function _burn(uint256 sha) internal override returns (uint256) {
        IPairUniV2 pair = getPair();
        vault.burn(sha, address(pair));
        pair.burn(address(this));
        if (pair.token0() == address(asset)) {
            _swap0(pair, IERC20(pair.token1()).balanceOf(address(this)));
        } else {
            _swap1(pair, IERC20(pair.token0()).balanceOf(address(this)));
        }
        return asset.balanceOf(address(this));
    }

    function _swap0(IPairUniV2 pair, uint256 amt) private returns (uint256) {
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        uint256 iwf = amt * 997;
        uint256 num = iwf * uint256(reserve0);
        uint256 den = (reserve1 * 1000) + iwf;
        IERC20(pair.token1()).transfer(address(pair), amt);
        pair.swap(num / den, 0, address(this), new bytes(0));
        pair.skim(address(this));
        return num / den;
    }

    function _swap1(IPairUniV2 pair, uint256 amt) private returns (uint256) {
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        uint256 iwf = amt * 997;
        uint256 num = iwf * uint256(reserve1);
        uint256 den = (reserve0 * 1000) + iwf;
        IERC20(pair.token0()).transfer(address(pair), amt);
        pair.swap(0, num / den, address(this), new bytes(0));
        pair.skim(address(this));
        return num / den;
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IPairUniV2 {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function totalSupply() external view returns (uint256);
    function getReserves() external view returns (uint112, uint112, uint32);
    function mint(address) external returns (uint256 liquidity);
    function burn(address) external returns (uint256 amount0, uint256 amount1);
    function swap(uint256, uint256, address, bytes calldata) external;
    function skim(address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IOracle {
    function latestAnswer() external view returns (int256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IVault {
    function asset() external view returns (address);
    function totalManagedAssets() external view returns (uint256);
    function mint(uint256, address) external;
    function burn(uint256, address) external;
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

    function rate(uint256 sha) external view virtual returns (uint256) {
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