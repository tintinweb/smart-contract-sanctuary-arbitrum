// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../interface/IMasterChef.sol";
import "../../interface/IERC20.sol";
import "../../interface/IStargateRouter.sol";
import "../../interface/IPoolLpToken.sol";
import "../../interface/IERC20Burnable.sol";

contract LizardStrategyUsdc {
    address public owner;

    address public constant stg = 0x6694340fc020c5E6B96567843da2df01b2CE1eb6;
    address public constant usdc = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;

    address public constant susdc = 0x892785f33CdeE22A30AEF750F285E18c18040c3e;
    uint16 public constant susdcPoolId = 1;
    address public constant stgRouter =
        0x53Bf833A5d6c4ddA888F69c22C88C9f356a41614;

    address public constant chefStg =
        0xeA8DfEE1898a7e0a59f7527F076106d7e44c2176;
    uint256 public constant chefPoolId = 0;

    address public lizardUsdc;
    address public timelock;

    uint256 public maximumMint = 500000 * 1000000;

    mapping(address => bool) public whitelist;

    bool private locked;

    event Deposit(uint256 amount, uint256 amountLp);
    event Withdraw(uint256 amount, uint256 amountLp);

    constructor(address _lizardUsdc) {
        lizardUsdc = _lizardUsdc;
        owner = msg.sender;
        timelock = msg.sender;
        _giveAllowances();
    }

    // MODIFIERS
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier nonReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    // TIMELOCK
    function changeTimelock(address _timelock) public {
        require(msg.sender == timelock, "Not old timelock");
        timelock = _timelock;
    }

    function withdrawUsdcGrowth() public {
        require(msg.sender == timelock, "not timelock");
        uint256 susdcTotalLiquidity = IPoolLpToken(susdc).totalLiquidity();
        uint256 susdcTotalSupply = IPoolLpToken(susdc).totalSupply();

        require(
            susdcTotalLiquidity > 0 && susdcTotalSupply > 0,
            "cant convert (S*USDC) to USDC when (S*USDC).totalLiquidity == 0 || totalSupply == 0"
        );

        uint256 LizardUsdcTotalSupply = IERC20(lizardUsdc).totalSupply();

        // do we have enough susdc to redeem all LizardUsdc supplies ?
        (uint256 balanceSusdc, ) = IMasterChef(chefStg).userInfo(
            chefPoolId,
            address(this)
        );
        uint256 balanceSusdcToUsdc = (balanceSusdc * susdcTotalLiquidity) /
            susdcTotalSupply; // /!\ can be done juste like that because decimal susdc == decimal usdc

        if (balanceSusdcToUsdc > LizardUsdcTotalSupply) {
            //we have more susdc than necessary to redeem 100% of the LizardUsdc supply.

            // we unstack the growth
            uint256 _amountSusdc = ((balanceSusdcToUsdc -
                LizardUsdcTotalSupply) * susdcTotalSupply) /
                susdcTotalLiquidity; // /!\ can be done juste like that because decimal susdc == decimal usdc

            IStargateRouter(stgRouter).instantRedeemLocal(
                susdcPoolId,
                _amountSusdc,
                address(this)
            );
        }
        // we transfert the growth
        IERC20(susdc).transfer(
            msg.sender,
            IERC20(susdc).balanceOf(address(this))
        );
    }

    // ONLYOWNER

    function setMaximumMint(uint256 _maximumMint) public onlyOwner {
        maximumMint = _maximumMint;
    }

    function changeOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function addToWhitelist(address _address) public onlyOwner {
        whitelist[_address] = true;
    }

    function removeFromWhitelist(address _address) public onlyOwner {
        if (whitelist[_address]) {
            whitelist[_address] = false;
        }
    }

    function withdrawReward() public onlyOwner {
        IMasterChef(chefStg).deposit(chefPoolId, 0);
        IERC20(stg).transfer(msg.sender, IERC20(stg).balanceOf(address(this)));
    }

    function giveAllowances() public onlyOwner {
        _giveAllowances();
    }

    //PUBLIC
    function pegStatus() public view returns (uint256, uint256) {
        uint256 susdcTotalLiquidity = IPoolLpToken(susdc).totalLiquidity();
        uint256 susdcTotalSupply = IPoolLpToken(susdc).totalSupply();
        require(
            susdcTotalLiquidity > 0 && susdcTotalSupply > 0,
            "cant convert (S*USDC) to USDC when (S*USDC).totalLiquidity == 0 || totalSupply == 0"
        );
        uint256 totalSupplyLizardUsdc = IERC20(lizardUsdc).totalSupply();

        (uint256 balanceSusdc, ) = IMasterChef(chefStg).userInfo(
            chefPoolId,
            address(this)
        );
        uint256 balanceSusdcToUsdc = (balanceSusdc * susdcTotalLiquidity) /
            susdcTotalSupply; // /!\ can be done juste like that because decimal susdc == decimal usdc

        return (totalSupplyLizardUsdc, balanceSusdcToUsdc);
    }

    function deposit(uint256 _amountUsdc) public nonReentrant {
        require(
            tx.origin == msg.sender || whitelist[msg.sender],
            "only no smart contract or whitelist"
        );
        require(
            IERC20Burnable(lizardUsdc).totalSupply() + _amountUsdc <
                maximumMint,
            "maximum lizardUsdc minted"
        );
        require(_amountUsdc > 0, "amount need to be positive");

        uint256 oldBalUsdc = IERC20(usdc).balanceOf(address(this));
        IERC20(usdc).transferFrom(msg.sender, address(this), _amountUsdc);
        uint256 balUsdc = IERC20(usdc).balanceOf(address(this));

        require(
            balUsdc >= _amountUsdc + oldBalUsdc,
            "transfert usdc from sender failed"
        );

        IERC20Burnable(lizardUsdc).mint(msg.sender, _amountUsdc);

        uint256 oldBalSusdc = IERC20(susdc).balanceOf(address(this));

        // convert all usdc we have to susdc
        IStargateRouter(stgRouter).addLiquidity(
            susdcPoolId,
            balUsdc,
            address(this)
        );
        uint256 balSusdc = IERC20(susdc).balanceOf(address(this));

        require(
            balSusdc > oldBalSusdc,
            "transfert (S*USDC) from stargate router failed"
        );

        IMasterChef(chefStg).deposit(chefPoolId, balSusdc); //deposit all we have

        emit Deposit(_amountUsdc, balSusdc - oldBalSusdc);
    }

    function withdraw(uint256 _amountUsdc) public nonReentrant {
        require(
            tx.origin == msg.sender || whitelist[msg.sender],
            "only no smart contract or whitelist"
        );

        uint256 susdcTotalLiquidity = IPoolLpToken(susdc).totalLiquidity();
        uint256 susdcTotalSupply = IPoolLpToken(susdc).totalSupply();
        require(
            susdcTotalLiquidity > 0 && susdcTotalSupply > 0,
            "cant convert (S*USDC) to USDC when (S*USDC).totalLiquidity == 0 || totalSupply == 0"
        );

        uint256 totalSupplyLizardUsdc = IERC20(susdc).totalSupply();

        IERC20Burnable(lizardUsdc).burn(msg.sender, _amountUsdc); // burn after read totalSupply

        //do we have enough susdc to redeem all LizardUsdc supplies ?
        (uint256 balanceSusdc, ) = IMasterChef(chefStg).userInfo(
            chefPoolId,
            address(this)
        );
        uint256 balanceSusdcToUsdc = (balanceSusdc * susdcTotalLiquidity) /
            susdcTotalSupply;

        uint256 amountSusdc;

        if (
            balanceSusdcToUsdc < totalSupplyLizardUsdc
        ) //not enough Susdc to redeem with 1/1 ratio
        {
            amountSusdc =
                (_amountUsdc * balanceSusdcToUsdc * susdcTotalSupply) /
                (totalSupplyLizardUsdc * susdcTotalLiquidity); // we lower the redeem ratio to the real one
        }
        // enough Susdc - classic conversion usdc=>susdc /!\ can be done juste like that because decimal susdc == decimal usdc
        else {
            amountSusdc =
                (_amountUsdc * susdcTotalSupply) /
                susdcTotalLiquidity;
        }

        uint256 balSusdc = IERC20(susdc).balanceOf(address(this));

        if (balSusdc < amountSusdc) {
            // withdraw missing susdc
            IMasterChef(chefStg).withdraw(chefPoolId, amountSusdc - balSusdc);
            balSusdc = IERC20(susdc).balanceOf(address(this));
            if (balSusdc < amountSusdc) {
                //still missing some susdc? hope its rounding problem
                amountSusdc = balSusdc;
            }
        }

        IStargateRouter(stgRouter).instantRedeemLocal(
            susdcPoolId,
            amountSusdc,
            address(this)
        );

        uint256 balUsdc = IERC20(usdc).balanceOf(address(this));
        if (balUsdc >= _amountUsdc) {
            balUsdc = _amountUsdc;
        }

        IERC20(usdc).transfer(msg.sender, balUsdc);

        emit Withdraw(_amountUsdc, balUsdc);
    }

    // INTERNAL
    function _giveAllowances() internal {
        IERC20(usdc).approve(stgRouter, type(uint256).max);
        IERC20(susdc).approve(chefStg, type(uint256).max);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

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
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Burnable {


  function mint(address account, uint amount) external returns (bool);
  function burn(address account, uint amount) external returns (bool);
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

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
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IMasterChef {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function enterStaking(uint256 _amount) external;
    function leaveStaking(uint256 _amount) external;
    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);
    function emergencyWithdraw(uint256 _pid) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

interface IPoolLpToken {

    function totalSupply() external view returns (uint256);
    function totalLiquidity() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

interface IStargateRouter {
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    function addLiquidity(
        uint256 _poolId,
        uint256 _amountLD,
        address _to
    ) external;

    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;

    function redeemRemote(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        uint256 _minAmountLD,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function instantRedeemLocal(
        uint16 _srcPoolId,
        uint256 _amountLP,
        address _to
    ) external returns (uint256);

    function redeemLocal(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function sendCredits(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress
    ) external payable;

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);
}