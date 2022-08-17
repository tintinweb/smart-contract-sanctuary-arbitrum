// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {ERC20} from "./ERC20.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IOracle} from "./interfaces/IOracle.sol";
import {IPairUniV2} from "./interfaces/IPairUniV2.sol";
import {IRouterUniV2} from "./interfaces/IRouterUniV2.sol";
import {IRewarderMiniChefV2} from "./interfaces/IRewarderMiniChefV2.sol";

contract VaultSushiLP is ERC20 {
    error TransferFailed();

    IRewarderMiniChefV2 public rewarder; // MiniChefV2
    IRouterUniV2 public router; // UniswapV2Router02
    IPairUniV2 public asset; // UniswapV2Pair
    uint256 poolId;
    address[] public path0;
    address[] public path1;

    constructor(
        address _rewarder,
        address _router,
        uint256 _poolId,
        address[] memory _path0,
        address[] memory _path1
    )
        ERC20("SushiLP Vault", "vSLP", 18)
    {
        rewarder = IRewarderMiniChefV2(_rewarder);
        router = IRouterUniV2(_router);
        asset = IPairUniV2(rewarder.lpToken(poolId));
        poolId = _poolId;
        path0 = _path0;
        path1 = _path1;
    }

    function mint(uint256 amt, address usr) external returns (uint256) {
        earn();
        _pull(address(asset), msg.sender, amt);
        uint256 tma = totalManagedAssets();
        uint256 sha = tma == 0 ? amt : amt * totalSupply / tma;
        IERC20(address(asset)).approve(address(rewarder), amt);
        rewarder.deposit(poolId, amt, address(this));
        _mint(sha, usr);
        return sha;
    }

    function burn(uint256 sha, address usr) external returns (uint256) {
        earn();
        if (balanceOf[msg.sender] < sha) revert InsufficientBalance();
        uint256 tma = totalManagedAssets();
        uint256 amt = sha * tma / totalSupply;
        _burn(sha, msg.sender);
        rewarder.withdraw(poolId, amt, address(this));
        _push(address(asset), usr, amt);
        return amt;
    }

    function earn() public {
        rewarder.harvest(poolId, address(this));
        uint256 amt = IERC20(rewarder.SUSHI()).balanceOf(address(this));
        uint256 haf = amt / 2;
        if (amt == 0) return;
        if (path0.length > 0) {
          router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
              haf,
              0, // TODO fix using oracle
              path0,
              address(asset),
              type(uint256).max
          );
        }
        if (path1.length > 0) {
          router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
              amt - haf,
              0, // TODO fix using oracle
              path1,
              address(asset),
              type(uint256).max
          );
        }
        asset.mint(address(this));
        asset.skim(address(this));
        uint256 liq = IERC20(address(asset)).balanceOf(address(this));
        rewarder.deposit(poolId, liq, address(this));
    }

    function totalManagedAssets() public view returns (uint256) {
        (uint256 amt,) = rewarder.userInfo(poolId, address(this));
        return amt;
    }

    function _pull(address tkn, address usr, uint256 amt) internal {
        if (!IERC20(tkn).transferFrom(usr, address(this), amt)) revert
            TransferFailed();
    }

    function _push(address tkn, address usr, uint256 amt) internal {
        if (!IERC20(tkn).transfer(usr, amt)) revert TransferFailed();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract ERC20 {
    error InsufficientBalance();
    error InsufficientAllowance();

    string public name;
    string public symbol;
    uint8 public immutable decimals;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Approval(address indexed src, address indexed guy, uint256 amt);
    event Transfer(address indexed src, address indexed dst, uint256 amt);

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function transfer(address dst, uint256 amt) external returns (bool) {
        return transferFrom(msg.sender, dst, amt);
    }

    function transferFrom(address src, address dst, uint256 amt)
        public
        returns (bool)
    {
        if (balanceOf[src] < amt) revert InsufficientBalance();
        if (
            src != msg.sender && allowance[src][msg.sender] != type(uint256).max
        ) {
            if (allowance[src][msg.sender] < amt) revert InsufficientAllowance();
            allowance[src][msg.sender] = allowance[src][msg.sender] - amt;
        }
        balanceOf[src] = balanceOf[src] - amt;
        balanceOf[dst] = balanceOf[dst] + amt;
        emit Transfer(src, dst, amt);
        return true;
    }

    function approve(address usr, uint256 amt) external returns (bool) {
        allowance[msg.sender][usr] = amt;
        emit Approval(msg.sender, usr, amt);
        return true;
    }

    function _mint(uint256 amt, address usr) internal {
        balanceOf[usr] = balanceOf[usr] + amt;
        totalSupply = totalSupply + amt;
        emit Transfer(address(0), usr, amt);
    }

    function _burn(uint256 amt, address usr) internal {
        if (balanceOf[usr] < amt) revert InsufficientBalance();
        balanceOf[usr] = balanceOf[usr] - amt;
        totalSupply = totalSupply - amt;
        emit Transfer(usr, address(0), amt);
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

interface IOracle {
    function latestAnswer() external view returns (int256);
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

interface IRouterUniV2 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IRewarderMiniChefV2 {
    function SUSHI() external view returns (address);
    function lpToken(uint256) external view returns (address);
    function pendingSushi(uint256, address) external view returns (uint256);
    function userInfo(uint256, address) external view returns (uint256, int256);
    function deposit(uint256, uint256, address) external;
    function withdraw(uint256, uint256, address) external;
    function harvest(uint256, address) external;
}