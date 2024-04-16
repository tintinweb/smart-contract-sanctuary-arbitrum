/**
 *Submitted for verification at Arbiscan.io on 2024-04-16
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;










contract ArbitrumLlamaLendAddresses {
    address internal constant BYTES_TRANSIENT_STORAGE = 0xab38cAeA7dcf9ffa0AE7a7567D72380f2504a0F2;
    address internal constant LLAMALEND_FACTORY = 0xcaEC110C784c9DF37240a8Ce096D352A75922DeA;
}






contract DSMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x + y;
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x - y;
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x * y;
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x / y;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x >= y ? x : y;
    }

    function imin(int256 x, int256 y) internal pure returns (int256 z) {
        return x <= y ? x : y;
    }

    function imax(int256 x, int256 y) internal pure returns (int256 z) {
        return x >= y ? x : y;
    }

    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}






abstract contract IBytesTransientStorage {
    function setBytesTransiently(bytes calldata) public virtual;
    function getBytesTransiently() public virtual returns (bytes memory);
}







interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint256 digits);
    function totalSupply() external view returns (uint256 supply);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}







interface IAGG {
    function rate() external view returns (uint256);
    function rate(address) external view returns (uint256);
    function rate0() external view returns (uint256);
    function target_debt_fraction() external view returns (uint256);
    function sigma() external view returns (int256);
    function peg_keepers(uint256) external view returns (address); 
}






interface ILLAMMA {
    function active_band_with_skip() external view returns (int256);
    function get_sum_xy(address) external view returns (uint256[2] memory);
    function get_xy(address) external view returns (uint256[][2] memory);
    function get_p() external view returns (uint256);
    function read_user_tick_numbers(address) external view returns (int256[2] memory);
    function p_oracle_up(int256) external view returns (uint256);
    function p_oracle_down(int256) external view returns (uint256);
    function p_current_up(int256) external view returns (uint256);
    function p_current_down(int256) external view returns (uint256);
    function bands_x(int256) external view returns (uint256);
    function bands_y(int256) external view returns (uint256);
    function get_base_price() external view returns (uint256);
    function price_oracle() external view returns (uint256);
    function active_band() external view returns (int256);
    function A() external view returns (uint256);
    function min_band() external view returns (int256);
    function max_band() external view returns (int256);
    function rate() external view returns (uint256);
    function exchange(uint256 i, uint256 j, uint256 in_amount, uint256 min_amount) external returns (uint256[2] memory);
    function coins(uint256 i) external view returns (address);
    function user_state(address _user) external view returns (uint256[4] memory);
}






interface ILlamaLendController {
    function create_loan(uint256 _collateralAmount, uint256 _debtAmount, uint256 _nBands) external payable;
    function create_loan_extended(uint256 _collateralAmount, uint256 _debtAmount, uint256 _nBands, address _callbacker, uint256[] memory _callbackArgs) external payable;

    /// @dev all functions below: if _collateralAmount is 0 will just return
    function add_collateral(uint256 _collateralAmount) external payable;
    function add_collateral(uint256 _collateralAmount, address _for) external payable;

    function remove_collateral(uint256 _collateralAmount) external;
    /// @param _useEth relevant only for ETH collateral pools (currently not deployed)
    function remove_collateral(uint256 _collateralAmount, bool _useEth) external;

    /// @dev all functions below: if _debtAmount is 0 will just return
    function borrow_more(uint256 _collateralAmount, uint256 _debtAmount) external payable;
    function borrow_more_extended(uint256 _collateralAmount, uint256 _debt, address _callbacker, uint256[] memory _callbackArgs) external payable;

    /// @dev if _debtAmount > debt will do full repay
    function repay(uint256 _debtAmount) external payable;
    function repay(uint256 _debtAmount, address _for) external payable;
    /// @param _maxActiveBand Don't allow active band to be higher than this (to prevent front-running the repay)
    function repay(uint256 _debtAmount, address _for, int256 _maxActiveBand) external payable;
    function repay(uint256 _debtAmount, address _for, int256 _maxActiveBand, bool _useEth) external payable;
    function repay_extended(address _callbacker, uint256[] memory _callbackArgs) external;

    function liquidate(address user, uint256 min_x) external;
    function liquidate(address user, uint256 min_x, bool _useEth) external;
    function liquidate_extended(address user, uint256 min_x, uint256 frac, bool use_eth, address callbacker, uint256[] memory _callbackArgs) external;


    /// GETTERS
    function amm() external view returns (address);
    function monetary_policy() external view returns (address);
    function collateral_token() external view returns (address);
    function borrowed_token() external view returns (address);
    function debt(address) external view returns (uint256);
    function total_debt() external view returns (uint256);
    function health_calculator(address, int256, int256, bool, uint256) external view returns (int256);
    function health_calculator(address, int256, int256, bool) external view returns (int256);
    function health(address) external view returns (int256);
    function health(address, bool) external view returns (int256);
    function max_borrowable(uint256 collateralAmount, uint256 nBands) external view returns (uint256);
    function min_collateral(uint256 debtAmount, uint256 nBands) external view returns (uint256);
    function calculate_debt_n1(uint256, uint256, uint256) external view returns (int256);
    function minted() external view returns (uint256);
    function redeemed() external view returns (uint256);
    function amm_price() external view returns (uint256);
    function user_state(address) external view returns (uint256[4] memory);
    function user_prices(address) external view returns (uint256[2] memory);
    function loan_exists(address) external view returns (bool);
    function liquidation_discount() external view returns (uint256);
    function factory() external view returns (address);
    function loan_discount() external view returns (uint256);
}







interface ILlamaLendFactory {
    function controllers(uint256) external view returns (address);
}







abstract contract IWETH {
    function allowance(address, address) public virtual view returns (uint256);

    function balanceOf(address) public virtual view returns (uint256);

    function approve(address, uint256) public virtual;

    function transfer(address, uint256) public virtual returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) public virtual returns (bool);

    function deposit() public payable virtual;

    function withdraw(uint256) public virtual;
}







library Address {
    //insufficient balance
    error InsufficientBalance(uint256 available, uint256 required);
    //unable to send value, recipient may have reverted
    error SendingValueFail();
    //insufficient balance for call
    error InsufficientBalanceForCall(uint256 available, uint256 required);
    //call to non-contract
    error NonContractCall();
    
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        uint256 balance = address(this).balance;
        if (balance < amount){
            revert InsufficientBalance(balance, amount);
        }

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        if (!(success)){
            revert SendingValueFail();
        }
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        uint256 balance = address(this).balance;
        if (balance < value){
            revert InsufficientBalanceForCall(balance, value);
        }
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        if (!(isContract(target))){
            revert NonContractCall();
        }

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}











library SafeERC20 {
    using Address for address;

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
    }
}








library TokenUtils {
    using SafeERC20 for IERC20;

    address public constant WETH_ADDR = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address public constant ETH_ADDR = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev Only approves the amount if allowance is lower than amount, does not decrease allowance
    function approveToken(
        address _tokenAddr,
        address _to,
        uint256 _amount
    ) internal {
        if (_tokenAddr == ETH_ADDR) return;

        if (IERC20(_tokenAddr).allowance(address(this), _to) < _amount) {
            IERC20(_tokenAddr).safeApprove(_to, _amount);
        }
    }

    function pullTokensIfNeeded(
        address _token,
        address _from,
        uint256 _amount
    ) internal returns (uint256) {
        // handle max uint amount
        if (_amount == type(uint256).max) {
            _amount = getBalance(_token, _from);
        }

        if (_from != address(0) && _from != address(this) && _token != ETH_ADDR && _amount != 0) {
            IERC20(_token).safeTransferFrom(_from, address(this), _amount);
        }

        return _amount;
    }

    function withdrawTokens(
        address _token,
        address _to,
        uint256 _amount
    ) internal returns (uint256) {
        if (_amount == type(uint256).max) {
            _amount = getBalance(_token, address(this));
        }

        if (_to != address(0) && _to != address(this) && _amount != 0) {
            if (_token != ETH_ADDR) {
                IERC20(_token).safeTransfer(_to, _amount);
            } else {
                (bool success, ) = _to.call{value: _amount}("");
                require(success, "Eth send fail");
            }
        }

        return _amount;
    }

    function depositWeth(uint256 _amount) internal {
        IWETH(WETH_ADDR).deposit{value: _amount}();
    }

    function withdrawWeth(uint256 _amount) internal {
        IWETH(WETH_ADDR).withdraw(_amount);
    }

    function getBalance(address _tokenAddr, address _acc) internal view returns (uint256) {
        if (_tokenAddr == ETH_ADDR) {
            return _acc.balance;
        } else {
            return IERC20(_tokenAddr).balanceOf(_acc);
        }
    }

    function getTokenDecimals(address _token) internal view returns (uint256) {
        if (_token == ETH_ADDR) return 18;

        return IERC20(_token).decimals();
    }
}














contract LlamaLendHelper is ArbitrumLlamaLendAddresses, DSMath {
    using TokenUtils for address;

    error InvalidLlamaLendController();

    IBytesTransientStorage constant transientStorage = IBytesTransientStorage(BYTES_TRANSIENT_STORAGE);
    ILlamaLendFactory constant factory = ILlamaLendFactory(LLAMALEND_FACTORY);

    bytes4 constant LLAMALEND_SWAPPER_ID = bytes4(keccak256("LlamaLendSwapper"));

    function isControllerValid(address _controllerAddr, uint256 _controllerId) public view returns (bool) {
        return (factory.controllers(_controllerId) == _controllerAddr);
    }

    function getCollateralRatio(address _user, address _controllerAddr) public view returns (uint256 collRatio, bool isInSoftLiquidation) {
        // fetch users debt
        uint256 debt = ILlamaLendController(_controllerAddr).debt(_user);
        // no position can exist without debt
        if (debt == 0) return (0, false);
        (uint256 debtAssetCollAmount, uint256 collAmount) = getCollAmountsFromAMM(_controllerAddr, _user);
        // if user has debt asset as coll he is currently underwater
        if (debtAssetCollAmount > 0) isInSoftLiquidation = true;

        // fetch collToken oracle price
        address amm = ILlamaLendController(_controllerAddr).amm();
        uint256 oraclePrice = ILLAMMA(amm).price_oracle();
        // calculate collAmount as WAD (18 decimals)
        address collToken = ILlamaLendController(_controllerAddr).collateral_token();
        uint256 assetDec = IERC20(collToken).decimals();
        uint256 collAmountWAD = assetDec > 18 ? (collAmount / 10 ** (assetDec - 18)) : (collAmount * 10 ** (18 - assetDec));
        
        collRatio = wdiv(wmul(collAmountWAD, oraclePrice) + debtAssetCollAmount, debt);
    }

    function _sendLeftoverFunds(
        address _collToken,
        address _debtToken,
        uint256 _collStartingBalance,
        uint256 _debtStartingBalance,
        address _to
    ) internal returns (uint256 collTokenReceived, uint256 debtTokenReceived) {
        collTokenReceived = _collToken.getBalance(address(this)) - _collStartingBalance;
        debtTokenReceived = _debtToken.getBalance(address(this)) - _debtStartingBalance;
        _collToken.withdrawTokens(_to, collTokenReceived);
        _debtToken.withdrawTokens(_to, debtTokenReceived);
    }

    function userMaxWithdraw(
        address _controllerAddress,
        address _user
    ) public view returns (uint256 maxWithdraw) {
        uint256[4] memory userState = ILlamaLendController(_controllerAddress).user_state(_user);
        return
            userState[0] -
            ILlamaLendController(_controllerAddress).min_collateral(userState[2], userState[3]);
    }

    function getCollAmountsFromAMM(
        address _controllerAddress,
        address _user
    ) public view returns (uint256 debtAssetCollAmount, uint256 collAssetCollAmount) {
        address llammaAddress = ILlamaLendController(_controllerAddress).amm();
        uint256[2] memory xy = ILLAMMA(llammaAddress).get_sum_xy(_user);
        debtAssetCollAmount = xy[0];
        collAssetCollAmount = xy[1];
    }
}






interface IERC4626 is IERC20 {
    function deposit(uint256 _assets, address _receiver) external returns (uint256 shares);
    function mint(uint256 _shares, address _receiver) external returns (uint256 assets);
    function withdraw(uint256 _assets, address _receiver, address _owner) external returns (uint256 shares);
    function redeem(uint256 _shares, address _receiver, address _owner) external returns (uint256 assets);

    function previewDeposit(uint256 _assets) external view returns (uint256 shares);
    function previewMint(uint256 _shares) external view returns (uint256 assets);
    function previewWithdraw(uint256 _assets) external view returns (uint256 shares);
    function previewRedeem(uint256 _shares) external view returns (uint256 assets);

    function convertToAssets(uint256 _shares) external view returns (uint256 assets);

    function totalAssets() external view returns (uint256);

    function asset() external view returns (address);
}







interface ILlamaLendVault {
    function borrow_apr() external view returns (uint256);
    function lend_apr() external view returns (uint256);
}










contract LlamaLendView is LlamaLendHelper {
  struct Band {
    int256 id;
    uint256 lowPrice;
    uint256 highPrice;
    uint256 collAmount;
    uint256 debtAmount;
  }

  struct CreateLoanData {
    int256 health;
    uint256 minColl;
    uint256 maxBorrow;
    Band[] bands;
  }

  struct GlobalData {
    address collateralToken;
    address debtToken;
    uint256 decimals;
    int256 activeBand;
    uint256 A;
    uint256 totalDebt;
    uint256 ammPrice;
    uint256 basePrice;
    uint256 oraclePrice;
    uint256 minted;
    uint256 redeemed;
    uint256 monetaryPolicyRate;
    uint256 ammRate;
    int256 minBand;
    int256 maxBand;
    uint256 borrowApr;
    uint256 lendApr;
    uint256 debtTokenTotalSupply;
    uint256 debtTokenLeftToBorrow;
    uint256 loanDiscount;
  }

  struct UserData {
    bool loanExists;
    uint256 collateralPrice;
    uint256 marketCollateralAmount;
    uint256 debtTokenCollateralAmount;
    uint256 debtAmount;
    uint256 N;
    uint256 priceLow;
    uint256 priceHigh;
    uint256 liquidationDiscount;
    int256 health;
    int256[2] bandRange;
    uint256[][2] usersBands;
    uint256 collRatio;
    bool isInSoftLiquidation;
    uint256 debtTokenSuppliedShares;
    uint256 debtTokenSuppliedAssets;
  }

  function userData(address market, address user) external view returns (UserData memory) {
      ILlamaLendController ctrl = ILlamaLendController(market);
      uint256 debtTokenSuppliedShares = IERC20(ctrl.factory()).balanceOf(user);
      uint256 debtTokenSuppliedAssets = IERC4626(ctrl.factory()).convertToAssets(debtTokenSuppliedShares);
      ILLAMMA amm = ILLAMMA(ctrl.amm());

      if (!ctrl.loan_exists(user)) {
        int256[2] memory bandRange = [int256(0), int256(0)];
        uint256[][2] memory usersBands;

        return UserData({
          loanExists: false,
          collateralPrice: 0,
          marketCollateralAmount: 0,
          debtTokenCollateralAmount: 0,
          debtAmount: 0,
          N: 0,
          priceLow: 0,
          priceHigh: 0,
          liquidationDiscount: 0,
          health: 0,
          bandRange: bandRange,
          usersBands: usersBands,
          collRatio: 0,
          isInSoftLiquidation: false,
          debtTokenSuppliedShares: debtTokenSuppliedShares,
          debtTokenSuppliedAssets: debtTokenSuppliedAssets
        });
      }

      uint256[4] memory amounts = ctrl.user_state(user);
      uint256[2] memory prices = ctrl.user_prices(user);
      (uint256 collRatio, bool isInSoftLiquidation) = getCollateralRatio(user, market);

      return UserData({
        loanExists: ctrl.loan_exists(user),
        collateralPrice: amm.price_oracle(),
        marketCollateralAmount: amounts[0],
        debtTokenCollateralAmount: amounts[1],
        debtAmount: amounts[2],
        N: amounts[3],
        priceLow: prices[1],
        priceHigh: prices[0],
        liquidationDiscount: ctrl.liquidation_discount(),
        health: ctrl.health(user, true),
        bandRange: amm.read_user_tick_numbers(user),
        usersBands: amm.get_xy(user),
        collRatio: collRatio,
        isInSoftLiquidation: isInSoftLiquidation,
        debtTokenSuppliedShares: debtTokenSuppliedShares,
        debtTokenSuppliedAssets: debtTokenSuppliedAssets
      });
  }

  function globalData(address market) external view returns (GlobalData memory) {
      ILlamaLendController ctrl = ILlamaLendController(market);
      IAGG agg = IAGG(ctrl.monetary_policy());
      ILLAMMA amm = ILLAMMA(ctrl.amm());
      address collTokenAddr = ctrl.collateral_token();
      address debtTokenAddr = ctrl.borrowed_token();

      return GlobalData({
        collateralToken: collTokenAddr,
        debtToken: debtTokenAddr,
        decimals: IERC20(collTokenAddr).decimals(),
        activeBand: amm.active_band(),
        A: amm.A(),
        totalDebt: ctrl.total_debt(),
        ammPrice: ctrl.amm_price(),
        basePrice: amm.get_base_price(),
        oraclePrice: amm.price_oracle(),
        minted: ctrl.minted(),
        redeemed: ctrl.redeemed(),
        monetaryPolicyRate: agg.rate(market),
        ammRate: amm.rate(),
        minBand: amm.min_band(),
        maxBand: amm.max_band(),
        lendApr: ILlamaLendVault(ctrl.factory()).lend_apr(),
        borrowApr:  ILlamaLendVault(ctrl.factory()).borrow_apr(),
        debtTokenTotalSupply: IERC4626(ctrl.factory()).totalAssets(),
        debtTokenLeftToBorrow: IERC20(debtTokenAddr).balanceOf(market),
        loanDiscount: ctrl.loan_discount()
    });
  }

  function getBandData(address market, int256 n) external view returns (Band memory) {
      ILlamaLendController ctrl = ILlamaLendController(market);
      ILLAMMA lama = ILLAMMA(ctrl.amm());

      return Band(n, lama.p_oracle_down(n), lama.p_oracle_up(n), lama.bands_y(n), lama.bands_x(n));
  }
  
  function getBandsData(address market, int256 from, int256 to) public view returns (Band[] memory) {
      ILlamaLendController ctrl = ILlamaLendController(market);
      ILLAMMA lama = ILLAMMA(ctrl.amm());
      Band[] memory bands = new Band[](uint256(to-from+1));
      for (int256 i = from; i <= to; i++) {
          bands[uint256(i-from)] = Band(i, lama.p_oracle_down(i), lama.p_oracle_up(i), lama.bands_y(i), lama.bands_x(i));
      }

      return bands;
  }

  function createLoanData(address market, uint256 collateral, uint256 debt, uint256 N) external view returns (CreateLoanData memory) {
    ILlamaLendController ctrl = ILlamaLendController(market);

    uint256 collForHealthCalc = collateral;

    int health = healthCalculator(market, address(0x00), int256(collForHealthCalc), int256(debt), true, N);

    int256 n1 = ctrl.calculate_debt_n1(collateral, debt, N);
    int256 n2 = n1 + int256(N) - 1;

    Band[] memory bands = getBandsData(market, n1, n2);

    return CreateLoanData({
      health: health,
      minColl: ctrl.min_collateral(debt, N),
      maxBorrow: ctrl.max_borrowable(collateral, N),
      bands: bands
    });
  }

  function maxBorrow(address market, uint256 collateral, uint256 N) external view returns (uint256) {
    ILlamaLendController ctrl = ILlamaLendController(market);
    return ctrl.max_borrowable(collateral, N);
  }

  function minCollateral(address market, uint256 debt, uint256 N) external view returns (uint256) {
    ILlamaLendController ctrl = ILlamaLendController(market);
    return ctrl.min_collateral(debt, N);
  }

  function getBandsDataForPosition(address market, uint256 collateral, uint256 debt, uint256 N) external view returns (Band[] memory bands) {
    ILlamaLendController ctrl = ILlamaLendController(market);

    int256 n1 = ctrl.calculate_debt_n1(collateral, debt, N);
    int256 n2 = n1 + int256(N) - 1;

    bands = getBandsData(market, n1, n2);
  }

  function healthCalculator(address market, address user, int256 collChange, int256 debtChange, bool isFull, uint256 numBands) public view returns (int256 health) {
    ILlamaLendController ctrl = ILlamaLendController(market);

    health =  ctrl.health_calculator(user, collChange, debtChange, isFull, numBands);
  }
}