pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { IStrips } from "../interface/IStrips.sol";
import { IInsuranceFund } from "../interface/IInsuranceFund.sol";
import { IMarket } from "../interface/IMarket.sol";
import { IStrips } from "../interface/IStrips.sol";
import { IrsMarket } from "../markets/IrsMarket.sol";
import { IStripsLpToken } from "../interface/IStripsLpToken.sol";
import { SLPToken } from "../token/SLPToken.sol";

import { StripsViewImpl } from "../impl/StripsViewImpl.sol";
import { StripsAdminImpl } from "../impl/StripsAdminImpl.sol";
import { StripsStateImpl } from "../impl/StripsStateImpl.sol";

import { TradeImpl } from "../impl/TradeImpl.sol";

import { SState } from "./State.sol";

import { PnlLib } from "../lib/Pnl.sol";
import { StorageStripsLib } from "../lib/StorageStrips.sol";
import { StorageMarketLib } from "../lib/StorageMarket.sol";
import { SignedBaseMath } from "../lib/SignedBaseMath.sol";

import { ISuspendable } from "../interface/ISuspendable.sol";
import { SSuspendable } from "../utils/SSuspendable.sol";

// REMEMBER about C3 linerazation: inheritance order matter for storage layout
contract Strips is
    SSuspendable,
    ReentrancyGuardUpgradeable,
    SState,
    IStrips
{
    using StorageStripsLib for StorageStripsLib.State;
    using SignedBaseMath for int256;
    using Address for address;

    function getVersion() external view returns (string memory version){
        version = "3.5";
    }

    event PingDone(
        uint indexed current,
        uint indexed next
    );

    function currentLevel() public view override returns (uint8) 
    {
        if (block.timestamp > g_state.lastAlive + g_state.keepAliveInterval){
            return 100;
        }

        return g_state._currentLevel;
    }

    /**
     * @dev Suspend the whole strips. Trader's can'd do anything with their positions.
     *      But stakers can continue to stake to markets
     */
    function changeLevel(uint8 _level) external override ownerOrListed
    {
        g_state._currentLevel = _level;
    }

    function withdrawStrp(address _to) external override onlyOwner
    {
        require(1 == 0, "NO_STRP");
    }

    function withdraw(address _to) external override minimumLevel(2) onlyOwner
    {
        require(_to != address(0), "BROKEN_ADDRESS");

        uint balance = g_state.tradingToken.balanceOf(address(this));
        
        require(balance > 0, "ZERO_BALANCE");

        SafeERC20.safeTransfer(g_state.tradingToken, 
                                _to, 
                                balance);
    }



    function initialize(
        StorageStripsLib.RiskParams memory _riskParams,
        IERC20 _tradingToken,
        uint256 _keepAliveInterval,
        address _dao,
        address _lpOracle
    ) public initializer {
        require(_dao != address(0), "ZERO_DAO");
        require(Address.isContract(address(_tradingToken)), "TRADING_TOKEN_NOT_A_CONTRACT");

        __ReentrancyGuard_init();

        g_state.riskParams = _riskParams;
        g_state.tradingToken = _tradingToken;

        g_state.lastAlive = block.timestamp;
        g_state.keepAliveInterval = _keepAliveInterval;

        g_state.dao = _dao;
        g_state.lpOracle = _lpOracle;
        
        /*Init ownable */
        owner = msg.sender;
    }

    function getLpOracle() external view override returns (address)
    {
        return g_state.lpOracle;
    }

    function changeLpOracle(address _lpOracle) external onlyOwner    
    {
        g_state.lpOracle = _lpOracle;
    }

    function getDao() external view returns (address)
    {
        return g_state.dao;
    }


    function changeDao(address _newDao) external onlyOwner
    {
        require(_newDao != address(0), "ZERO_DAO");
        g_state.dao = _newDao;
    }

    function adminDispatcher(IStrips.AdminActionArgs memory args) external onlyOwner
    {
        StripsAdminImpl.dispatcher(g_state, 
                                    args);
    }

    /*
        FOR TEST only. 
        todo:removeonproduction

     */
    function check_insurance() external
    {
        StripsStateImpl._check_insurance(g_state);
    }

    /*
        FOR TEST only. 
        todo:removeonproduction

     */
    function check_trader(address account, address market) external 
    {
        StripsStateImpl._check_trader(g_state, 
                                account,
                                IMarket(market));
    }

    
    function viewDispatcher(IStrips.ViewActionArgs memory args) external view returns (bytes memory)
    {
        return StripsViewImpl.dispatcher(g_state, 
                                        args);
    }

    function stateDispatcher(IStrips.StateActionArgs memory args) external maximumLevel(1)
    {
        return StripsStateImpl.dispatcher(g_state, 
                                            args);
    }

    function getTradingToken() external view returns (address)    
    {
        return address(g_state.tradingToken);
    }


    function changeTradingToken(IERC20 _newTradingToken) external onlyOwner    
    {
        g_state.tradingToken = _newTradingToken;
    }


    function changeInsurance(IInsuranceFund _insurance) external onlyOwner    
    {
        g_state.insuranceFund = _insurance;
    }

    function changeRiskParams(StorageStripsLib.RiskParams memory _params) external ownerOrListed
    {
        g_state.riskParams = _params;
    }

    function getTradingInfo(address _account) external view returns (IStrips.TradingInfo memory tradingInfo) {
        return StripsViewImpl.getTradingInfo(g_state, _account);
    }

    function getStakingInfo(address _account) public view returns (IStrips.StakingInfo memory stakingInfo) {
        return StripsViewImpl.getStakingInfo(g_state, _account);
    }

    function payKeeperReward(address keeper) external override {
        //TODO: implement
        StripsStateImpl._payKeeperReward(g_state,
                                    keeper);
    }

    /**
     * @notice Sets timestamp of last call for the availability of contract
     * methods when interacting with keepers. The call can only be made by
     * the user who has PINGER_ROLE
     */
    function ping() external override ownerOrListed
    {
       g_state.lastAlive = block.timestamp;
       
       emit PingDone(
            g_state.lastAlive,
            g_state.lastAlive + g_state.keepAliveInterval
       );
    }

    function assetPnl(address _asset) external view virtual override returns (int256){
        StorageStripsLib.Position storage ammPosition = g_state.checkPosition(IMarket(_asset), address(_asset));

        if (ammPosition.isActive == false){
            return 0;
        }

        return PnlLib.getAmmTotalPnl(g_state, 
                                        IMarket(_asset), 
                                        ammPosition);
    }

    function getPositionsCount() external view override returns (uint)
    {
        return g_state.allIndexes.length;
    }

    function getInsurance() external view returns (address)
    {
        return address(g_state.insuranceFund);
    }

    function checkMarket(IMarket _market) external view returns (bool){
        for (uint i=0; i< g_state.allMarkets.length; i++) {
            IMarket _address = g_state.allMarkets[i];
            if (_market == _address){
                return true;
            }
        }

        return false;
    }


    function getAllMarkets() external view override returns (IStrips.ExtendedMarketData[] memory)
    {
        IStrips.ExtendedMarketData[] memory _markets = new IStrips.ExtendedMarketData[](g_state.allMarkets.length);

        for (uint i=0; i< g_state.allMarkets.length; i++) {
            IMarket _address = g_state.allMarkets[i];
            _markets[i].created = g_state.markets[_address].created;
            _markets[i].market = address(_address);
        }

        return _markets;
    }


    function getPositionsForLiquidation(
        uint _start, 
        uint _length
    ) external view override returns (StorageStripsLib.PositionMeta[] memory) {
        // If requested length goes out of array indexes range,
        // enforce the _end to be the last element of array.

        
        if (g_state.allIndexes.length == 0){
            StorageStripsLib.PositionMeta[] memory liqPositions = new StorageStripsLib.PositionMeta[](1);
            return liqPositions;
        }

        uint256 _end;
        if ( _start + _length > g_state.allIndexes.length ) {
            _end = g_state.allIndexes.length - 1;
        } else {
            _end = _start + _length -  1;
        }
        // Since dynamic array can't be returned directly,
        // create static array of the result size and assign values to it.
        // So we count the total amount of liquidateable positions in the given range of indexes first
        uint count = _end - _start + 1;
        uint j = 0;
        StorageStripsLib.PositionMeta[] memory liqPositions = new StorageStripsLib.PositionMeta[](count);
        for (uint256 i = _start; i <= _end; i++) {
            uint posIndex = g_state.allIndexes[i];  // get posIndex first

            /*Check PositionMeta for current posIndex */
            if (g_state.indexToPositionMeta[posIndex].isActive){
                IMarket _market = g_state.indexToPositionMeta[posIndex]._market;

                StorageStripsLib.Position storage _position = g_state.checkPosition(_market, g_state.indexToPositionMeta[posIndex]._account);
                (,int256 marginRatio) = PnlLib.getMarginRatio(g_state,
                                                            _market,
                                                            _position,
                                                            SignedBaseMath.oneDecimal(),
                                                            false);  // based on Exit Price always
                
                /*We need to liquidate this position */
                if (marginRatio <= g_state.getLiquidationRatio()){
                    liqPositions[j] = g_state.indexToPositionMeta[posIndex];
                    j += 1;
                }
            }
        }

        return liqPositions;
    }

    function close(
        IMarket _market,
        int256 _closeRatio,
        int256 _slippage
    ) external override nonReentrant maximumLevel(1) {
        TradeImpl.closePosition(g_state,
                                _market,
                                _closeRatio,
                                _slippage);
    }

    function open(
        IMarket _market,
        bool isLong,
        int256 collateral,
        int256 leverage,
        int256 slippage
    ) external override nonReentrant maximumLevel(0) {
        TradeImpl.openPosition(g_state,
                                TradeImpl.PositionParams({
                                    _market: _market,
                                    _account: msg.sender,
                                    _collateral: collateral,
                                    _leverage: leverage,
                                    _isLong: isLong,
                                    _slippage: slippage
                                }));
    }

    function liquidatePositions(address[] memory markets, address[] memory accounts) external override nonReentrant {
        require(1==0, "DEPRECATED");
    }

    function liquidatePosition(address _market, 
                                address account) public override nonReentrant
    {
        TradeImpl.liquidatePosition(g_state,
                                    IMarket(_market),
                                    account);
    }

    function changeCollateral(IMarket _market,
                            int256 collateral,
                            bool isAdd) external override nonReentrant maximumLevel(1){
        
        if (isAdd){
            TradeImpl.addCollateral(g_state,
                            _market,
                            collateral);
        }else{
            TradeImpl.removeCollateral(g_state,
                            _market,
                            collateral);
        }
    }


    /*UPGRADE because of competition issues */ 
    function checkPosition(
        IMarket market,
        address account
    ) external view returns (StorageStripsLib.Position memory){
        return g_state.checkPosition(market, account);
    }

    function positionPnlParts(
        IMarket market,
        address account,
        int256 ratio,
        bool is_market_price
    ) external view returns (int256 funding_pnl, int256 trading_pnl, int256 total_pnl){
        StorageStripsLib.Position storage position = g_state.checkPosition(market, account);
        return PnlLib.calcPnlPartsSignedBased(g_state, 
                                        market, 
                                        position,
                                        ratio,
                                        is_market_price);

    }

    function ammPnlParts(
        IMarket market
    ) external view returns (int256 funding_pnl, int256 trading_pnl, int256 total_pnl){
        StorageStripsLib.Position storage ammPosition = g_state.checkPosition(market, address(market));
        return PnlLib.calcAmmPnlParts(g_state, 
                                        market, 
                                        ammPosition);
    }


    function currentFlatFee() external view returns (int256){
        return g_state.riskParams.flatFee;
    }

    function changeFlatFee(int256 _flatFee) external ownerOrListed
    {
        /* 
            IT could be negative.
            Admin should knows what he does.
        */

        g_state.riskParams.flatFee = _flatFee;
    }


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT

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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

pragma solidity ^0.8.0;

import { IMarket } from "./IMarket.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IInsuranceFund } from "./IInsuranceFund.sol";
import { IStripsLpToken } from "./IStripsLpToken.sol";

import { StorageStripsLib } from "../lib/StorageStrips.sol";
import { IStripsEvents } from "../lib/events/Strips.sol";

interface IStrips is IStripsEvents 
{
    /*
        for action:
        0 - open
        1 - close
        2 - liquidate
     */
    event TradeAction(
        uint256 indexed timestamp,
        address indexed marketAddress,
        bool indexed isLong,
        address traderAddress,
        uint256 action,   // 0- open, 1-close, 2-liquidate
        int256 notional,
        int256 ratio,
        int256 collateral,
        int256 feePaid,
        int256 slippage,
        int256 executedPrice,  //renamed from newPrice
        int256 marketPrice,
        int256 oraclePrice
    );

    event PnlTransfered(
        uint256 indexed timestamp,
        address indexed marketAddress,
        address indexed traderAddress,
        uint256 action,
        int256 collateral,
        int256 total_pnl,  
        int256 trading_pnl,
        int256 funding_pnl
    );

    event CollateralChanged(
        uint256 indexed timestamp,
        address indexed marketAddress,
        address indexed traderAddress,
        int256 notional,
        int256 total_pnl,
        int256 diff,
        int256 newMargin  // the new margin
    );

    struct ExtendedMarketData {
        bool created;
        address market;
    }


    /*
        State actions
     */
    enum StateActionType {
        ClaimRewards
    }

    /*request */
    struct ClaimRewardsParams {
        address account;
    }

    struct StateActionArgs {
        StateActionType actionType;
        bytes data;
    }


    /*
        View actions
     */
    enum ViewActionType {
        GetOracles,
        GetMarkets,
        CalcFeeAndSlippage,
        GetPosition,
        CalcClose,
        CalcRewards
    }

    /*request */
    struct CalcRewardsParams {
        address account;
    }
    /*response */
    struct CalcRewardsData {
        address account;
        int256 rewardsTotal;
    }


    /*request */
    struct CalcCloseParams {
        address market;
        address account;
        int256 closeRatio;
    }
    /*response */
    struct CalcCloseData {
        address market;
        int256 minimumMargin;
        int256 pnl;
        int256 marginLeft;
        int256 fee;
        int256 slippage;
        int256 whatIfPrice;
    }

    /*
        request 
        response: PositionParams or revert
    */
    struct GetPositionParams {
        address market;
        address account;
    }


    /*request */
    struct FeeAndSlippageParams {
        address market;
        int256 notional;
        int256 collateral;
        bool isLong;
    }

    /* response */
    struct FeeAndSlippageData{
        address market;
        int256 marketRate;
        int256 oracleRate;
        
        int256 fee;
        int256 whatIfPrice;
        int256 slippage;

        int256 minimumMargin;
        int256 estimatedMargin;
    }


    struct ViewActionArgs {
        ViewActionType actionType;
        bytes data;
    }


    /*
        Admin actions
     */

    enum AdminActionType {
        AddMarket,   
        AddOracle,  
        RemoveOracle,  
        ChangeOracle,
        SetInsurance,
        ChangeRisk
    }

    struct AddMarketParams{
        address market;
        address assetOracle;
    }

    struct AddOracleParams{
        address oracle;
        int256 keeperReward;
    }

    struct RemoveOracleParams{
        address oracle;
    }

    struct ChangeOracleParams{
        address oracle;
        int256 newReward;
    }

    struct SetInsuranceParams{
        address insurance;
    }

    struct ChangeRiskParams{
        StorageStripsLib.RiskParams riskParams;
    }


    struct AdminActionArgs {
        AdminActionType actionType;
        bytes data;
    }



    /*
        Events
     */
    event LogNewMarket(
        address indexed market,
        address indexed assetOracle
    );

    struct PositionParams {
        // true - for long, false - for short
        bool isLong;
        // is this position closed or not
        bool isActive;
        // is this position liquidated or not
        bool isLiquidated;

        //position size in USDC
        int256 notional;
        //collateral size in USDC
        int256 collateral;
        //initial price for position
        int256 initialPrice;
    }

    struct PositionData {
        //address of the market
        IMarket market;
        // total pnl - real-time profit or loss for this position
        int256 pnl;
        int256 trading_pnl;
        int256 funding_pnl;

        // this pnl is calculated based on whatIfPrice
        int256 pnlWhatIf;
        
        // current margin ratio of the position
        int256 marginRatio;
        PositionParams positionParams;
    }

    struct AssetData {
        bool isInsurance;
        
        address asset;
         // Address of SLP/SIP token
        address slpToken;

        int256 marketPrice;
        int256 oraclePrice;

        int256 maxLong;
        int256 maxShort;

        int256 tvl;
        int256 apy;

        int256 minimumMargin;
    }

    struct StakingData {
         //Market or Insurance address
        address asset; 

        //Collateral = slp amount
        uint256 totalStaked;


        //lpProfit
        int256 unrealizedLpProfit;
        //usdcProfit
        int256 unrealizedUsdcProfit;
    }

    /**
     * @notice Struct that keep real-time trading data
     */
    struct TradingInfo {
        //Includes also info about the current market prices, to show on dashboard
        AssetData[] assetData;
        PositionData[] positionData;
    }

    /**
     * @notice Struct that keep real-time staking data
     */
    struct StakingInfo {
        //Includes also info about the current market prices, to show on dashboard
        int256 lpPrice;
        AssetData[] assetData;
        StakingData[] stakingData;
    }

    /**
     * @notice Struct that keep staking and trading data
     */
    struct AllInfo {
        TradingInfo tradingInfo;
        StakingInfo stakingInfo;
    }

    function open(
        IMarket _market,
        bool isLong,
        int256 collateral,
        int256 leverage,
        int256 slippage
    ) external;

    function close(
        IMarket _market,
        int256 _closeRatio,
        int256 _slippage
    ) external;

    function changeCollateral(
        IMarket _market,
        int256 collateral,
        bool isAdd
    ) external;

    function ping() external;
    function getPositionsCount() external view returns (uint);
    function getPositionsForLiquidation(uint _start, uint _length) external view returns (StorageStripsLib.PositionMeta[] memory);
    function liquidatePosition(address _market, address account) external;
    function liquidatePositions(address[] memory markets, address[] memory accounts) external;

    function payKeeperReward(address keeper) external;

    /*
        Strips getters functions for Trader
     */
    function assetPnl(address _asset) external view virtual returns (int256);
    function getLpOracle() external view returns (address);

    function getAllMarkets() external view returns (ExtendedMarketData[] memory);

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;
import { IUniswapLpOracle } from "../interface/IUniswapLpOracle.sol";

interface IInsuranceFund {
    function borrow(address _to, int256 _amount) external;

    function getLiquidity() external view returns (int256);

    function changePairOracle(IUniswapLpOracle _oracle) external;

}

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IStripsLpToken } from "./IStripsLpToken.sol";
import { IUniswapV2Pair } from "../external/interfaces/IUniswapV2Pair.sol";
import { IUniswapLpOracle } from "../interface/IUniswapLpOracle.sol";
import { IAssetOracle } from "../interface/IAssetOracle.sol";
        
interface IMarket {        
    function getLongs() external view returns (int256);
    function getShorts() external view returns (int256);

    function priceChange(int256 notional, bool isLong) external view returns (int256);
    function currentPrice() external view returns (int256);
    function oraclePrice() external view returns (int256);
    
    function changeAssetOracle(IAssetOracle _oracle) external;
    function changePairOracle(IUniswapLpOracle _oracle) external;

    function getAssetOracle() external view returns (address);
    function getPairOracle() external view returns (address);
    function currentOracleIndex() external view returns (uint256);

    function getPrices() external view returns (int256 marketPrice, int256 oraclePrice);    
    function getLiquidity() external view returns (int256);

    /*Both returns the new value of virtual liquidity*/
    function changeVirtualLiquidity(int256 _new) external returns (int256);
    function getVirtualLiquidity() external view returns (int256);

    function openPosition(
        bool isLong,
        int256 notional
    ) external returns (int256 openPrice);

    function closePosition(
        bool isLong,
        int256 notional
    ) external returns (int256);

    function maxNotional() external view returns (int256 maxLong, int256 maxShort);

    /*Both returns the new value of fundingPeriod*/
    function getFundingPeriod() external view returns (int256);
    function changeFundingPeriod(int256 _newPeriod) external returns (int256);
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import { IMarket } from "../interface/IMarket.sol";
import { IStakeble } from "../interface/IStakeble.sol";
import { IRewardable } from "../interface/IRewardable.sol";
import { IRewarder } from "../interface/IRewarder.sol";

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IUniswapLpOracle } from "../interface/IUniswapLpOracle.sol";
import { IAssetOracle } from "../interface/IAssetOracle.sol";


import { IStrips } from "../interface/IStrips.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { IUniswapV2Pair } from "../external/interfaces/IUniswapV2Pair.sol";

import { IStripsLpToken } from "../interface/IStripsLpToken.sol";
import { MGetters } from "./Getters.sol";
import { StakingImpl } from "../impl/StakingImpl.sol";

import { SLPToken } from "../token/SLPToken.sol";
import { SignedBaseMath } from "../lib/SignedBaseMath.sol";
import { StorageMarketLib } from "../lib/StorageMarket.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

import { ISuspendable } from "../interface/ISuspendable.sol";
import { SSuspendable } from "../utils/SSuspendable.sol";

//REMEMBER about C3 linerazation: inheritance order matter for storage layout
contract IrsMarket is
    SSuspendable,
    ReentrancyGuardUpgradeable,
    IMarket,
    IStakeble,
    IRewardable,
    MGetters
{
    using SignedBaseMath for int256;
    using StorageMarketLib for StorageMarketLib.State;

    function getVersion() external view returns (string memory version){
        version = "3.5";
    }

    function initialize (
        StorageMarketLib.InitParams memory _params,
        address _sushiRouter,
        address _dao
    ) public initializer
    {
        require(Address.isContract(_sushiRouter), "SUSHI_ROUTER_NOT_A_CONTRACT");
        require(address(_params.stripsProxy) != address(0), "NO_STRIPS_ERROR");
        require(_dao != address(0), "ZERO_DAO");

        __ReentrancyGuard_init();

        m_state.dao = _dao;
        m_state.params = _params;
        m_state.extend.sushiRouter = _sushiRouter;

        m_state.extend.createdAt = block.timestamp;

        if (m_state.ratio == 0){
            m_state.ratio = SignedBaseMath.oneDecimal();
        }

        /*Set ownable */
        owner = msg.sender;
        strips = address(_params.stripsProxy);
    }

    function isSwapOn() external view override returns (bool)
    {
        return m_state.extend.isSwapOn;
    }

    function changeSwapMode(bool _mode) external override ownerOrListed
    {
        m_state.extend.isSwapOn = _mode;
    }


    /*Virtual liquidity management*/
    function depositTradingToken(address _from, int256 _amount) external ownerOrAdmin
    {
        require(_amount > 0, "WRONG_AMOUNT");

        SafeERC20.safeTransferFrom(m_state.params.tradingToken, 
                                            _from, 
                                            address(this), 
                                            uint(_amount));

        /*
            It's not anonymous addition
            We want reflec it as USDC growth
         */
        m_state.slpToken.changeTradingPnl(_amount);
    }

    function changeFundingPeriod(int256 _newPeriod) external override ownerOrListed returns (int256)
    {
        require(_newPeriod >= SignedBaseMath.oneDecimal(), "BROKEN_PERIOD");

        m_state.params.fundingPeriod = _newPeriod;

        return m_state.params.fundingPeriod;
    }

    /*Virtual liquidity management*/
    function changeVirtualLiquidity(int256 _new) external override ownerOrListed returns (int256)
    {
        require(_new > 0, "NEGATIVE_LIQUIDITY");

        m_state.params.virtualLiquidity = _new;

        return m_state.params.virtualLiquidity;
    }
    
    function getTvl() external view override returns (int256)
    {
        return m_state.getLiquidity();
    }


    function getVirtualLiquidity() external view override returns (int256)
    {
        return m_state.params.virtualLiquidity;
    }

    function getPartedLiquidity() external view override returns (int256 tradingLiquidity, int256 stakingLiquidity) {
        tradingLiquidity = m_state.calcTradingLiqudity();
        stakingLiquidity = m_state.calcStakingLiqudity();
    }

    function changeAssetOracle(IAssetOracle _oracle) external override onlyOwner 
    {
        require(Address.isContract(address(_oracle)), "NOT_A_CONTRACT");
        
        m_state.params.assetOracle = _oracle;

    }

    function changePairOracle(IUniswapLpOracle _oracle) external override onlyOwner
    {
        require(Address.isContract(address(_oracle)), "NOT_A_CONTRACT");

        m_state.params.pairOracle = _oracle;
    }

    function currentLevel() public view override returns (uint8) 
    {
        return m_state._currentLevel;
    }

    function changeLevel(uint8 _level) external override ownerOrListed
    {
        m_state._currentLevel = _level;
    }

    function withdrawStrp(address _to) external override onlyOwner
    {
        uint strpBalance = m_state.params.strpToken.balanceOf(address(this));
        if (strpBalance > 0){
            SafeERC20.safeTransfer(IERC20(address(m_state.params.strpToken)), 
                                    _to, 
                                    strpBalance);
        }
    }

    function withdraw(address _to) external override minimumLevel(2) onlyOwner
    {
        require(_to != address(0), "BROKEN_ADDRESS");

        uint tradingBalance = m_state.params.tradingToken.balanceOf(address(this));
        if (tradingBalance > 0){
            SafeERC20.safeTransfer(m_state.params.tradingToken, 
                                    _to, 
                                    tradingBalance);
        }
        
        uint stakingBalance = m_state.params.stakingToken.balanceOf(address(this));
        if (stakingBalance > 0){
            SafeERC20.safeTransfer(IERC20(address(m_state.params.stakingToken)), 
                                    _to, 
                                    stakingBalance);
        }

        uint strpBalance = m_state.params.strpToken.balanceOf(address(this));
        if (strpBalance > 0){
            SafeERC20.safeTransfer(IERC20(address(m_state.params.strpToken)), 
                                    _to, 
                                    strpBalance);
        }

    }

    function suspendRewards(bool _status) external override onlyOwner 
    {
        m_state.params.isRewardable = _status;
    }

    function isRewardable() external view override returns (bool)
    {
        return m_state.params.isRewardable;        
    }

    function getDao() external view returns (address)
    {
        return m_state.dao;
    }

    function changeDao(address _newDao) external onlyOwner
    {
        require(_newDao != address(0), "ZERO_DAO");
        m_state.dao = _newDao;
    }


    function getStrips() external view override returns (address) {
        return address(m_state.params.stripsProxy);
    }

    function changeRewarder(IRewarder _rewarder) external override onlyOwner
    {
        require(Address.isContract(address(_rewarder)), "REWARDER_NOT_A_CONTRACT");

        m_state.rewarder = _rewarder;
    }


    function getRewarder() external view override returns (address)
    {
        return address(m_state.rewarder);
    }

    function changeSlp(IStripsLpToken _slpToken) external override onlyOwner {
        require(Address.isContract(address(_slpToken)), "SLP_NOT_A_CONTRACT");

        m_state.slpToken = _slpToken;
    }


    function approveStrips(IERC20 _token, int256 _amount) external override onlyStrips {
        m_state.approveStrips(_token, _amount);
    }

    /*
        Not softSuspend nor hardsuspened
     */
    function openPosition(
        bool isLong,
        int256 notional
    ) external override nonReentrant maximumLevel(0) onlyStrips returns (int256){
        require(notional > 0, "NOTIONAL_LT_0");
        
        if (isLong == true){
            m_state.totalLongs += notional;
            m_state._updateRatio(notional, 0);
        }else{
            m_state.totalShorts += notional;
            m_state._updateRatio(0, notional);
        }

        return m_state.currentPrice();
    }

    /*
        softSuspend is ok
     */
    function closePosition(
        bool isLong,
        int256 notional
    ) external override nonReentrant maximumLevel(1) onlyStrips returns (int256){
        require(notional > 0, "NOTIONAL_LT_0");

        //TODO: check for slippage, if it's big then the trader PAY slippage
        if (isLong){
            m_state.totalLongs -= notional;
            require(m_state.totalLongs >= 0, "TOTALLONGS_LT_0");
            
            m_state._updateRatio(0 - notional, 0);
        }else{
            m_state.totalShorts -= notional;
            require(m_state.totalShorts >= 0, "TOTALSHORTS_LT_0");

            m_state._updateRatio(0, 0 - notional);
        }

        return m_state.currentPrice();
    }


    // SHORT: openPrice = initialPrice * (demand / (supply + notional))
    // LONG: openPrice = initialPrice * (demand / (supply + notional))
    // demand = total_longs + stackedLiquidity;
    // supply = total_shorts + stackedLiquidity 
    function priceChange(
        int256 notional,
        bool isLong
    ) public view override returns (int256){
        if (isLong){
            return _priceChangeOnLong(notional);
        }

        return _priceChangeOnShort(notional);
    }

    function _priceChangeOnLong(
        int256 notional
    ) private view returns (int256){

        int256 ratio = m_state._whatIfRatio(notional, 0);

        return m_state.params.initialPrice.muld(ratio);
    }

    function _priceChangeOnShort(
        int256 notional
    ) private view returns (int256){
        int256 ratio = m_state._whatIfRatio(0, notional);

        return m_state.params.initialPrice.muld(ratio);
    }


    /*
    ********************************************************************
    * Stake/Unstake related functions
    ********************************************************************
    */
    function netLiquidity() external view override virtual returns (int256){
        return m_state.netLiquidity();
    }

    function liveTime() external view override returns (uint){
        return block.timestamp - m_state.extend.createdAt;
    }

    function isInsurance() external view override returns (bool){
        return false;
    }

    function totalStaked() external view override returns (int256)
    {
        return m_state.calcStakingLiqudity();
    }

    function getSlpToken() external view override returns (address) {
        return address(m_state.slpToken);
    }

    function changeStakingToken(IUniswapV2Pair _newStakingToken) external ownerOrAdmin
    {
        m_state.params.stakingToken = _newStakingToken;
    }

    function getStakingToken() external view override returns (address)
    {
        return address(m_state.params.stakingToken);
    }

    function changeTradingToken(IERC20 _new) external ownerOrAdmin
    {
        m_state.params.tradingToken = _new;
    }

    function getTradingToken() external view override returns (address)
    {
        return address(m_state.params.tradingToken);
    }

    function ensureFunds(int256 amount) external override nonReentrant maximumLevel(0) onlyStrips {
        int256 diff = m_state.calcTradingLiqudity() - amount;
        if (diff >= 0){
            return;
        }

        //diff *= -1;
        StakingImpl._burnPair(m_state.slpToken,
                                amount);
    }

    function stake(int256 amount) external override nonReentrant maximumLevel(0) {
        StakingImpl._stake(m_state.slpToken,
                            msg.sender,
                            amount);
    }

    function unstake(int256 amount) external override nonReentrant maximumLevel(1) {
        StakingImpl._unstake(m_state.slpToken,
                            msg.sender,
                            amount);
        
    }

    function externalLiquidityChanged(int256 diff) external override nonReentrant onlyStrips{
        int256 currentBalance = m_state.calcTradingLiqudity();

        emit BalanceChanged(
            block.timestamp,
            address(this),
            msg.sender,
            diff,
            currentBalance,
            -1
        );
    }

    function changeTradingPnl(int256 amount) public override virtual nonReentrant onlyStrips{
        m_state.slpToken.changeTradingPnl(amount);
    }
    
    function changeStakingPnl(int256 amount) public override virtual nonReentrant onlyStrips{
        m_state.slpToken.changeStakingPnl(amount);
    }


    /* UTILS */
    function changeSushiRouter(address _router) external override onlyOwner
    {
        require(Address.isContract(_router), "SUSHI_ROUTER_NOT_A_CONTRACT");

        m_state.extend.sushiRouter = _router;

    }
    function getSushiRouter() external view override returns (address)
    {
        return m_state.extend.sushiRouter;
    }

    function getStrp() external view override returns (address)
    {
        return address(m_state.params.strpToken);
    }

    function changeStrp(IERC20 _strp) external onlyOwner
    {
        m_state.params.strpToken = _strp;
    }


}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { IUniswapV2Pair } from "../external/interfaces/IUniswapV2Pair.sol";
import { IStrips } from "../interface/IStrips.sol";
import { IUniswapLpOracle } from "../interface/IUniswapLpOracle.sol";

interface IStripsLpToken {
    struct TokenParams {
        address stripsProxy;
        address pairOracle;

        address tradingToken;
        address stakingToken; 

        int256 penaltyPeriod;
        int256 penaltyFee;

        int256 unstakingTolerance;
    }

    struct ProfitParams{
        int256 unstakeAmountLP;
        int256 unstakeAmountERC20;

        int256 stakingProfit;   
        int256 stakingFee;

        int256 penaltyLeft;
        uint256 totalStaked;

        int256 lpPrice;

        int256 lpProfit;
        int256 usdcLoss;

        int256 currentVritualLpGrowth; 
        int256 currentVirtualUsdcGrowth;
        uint256 slpSupply;
    }
    
    function instantGrowth() external view returns (int256 usdcGrowth, int256 lpGrowth);
    function getParams() external view returns (TokenParams memory);
    function getBurnableToken() external view returns (address);
    function getPairPrice() external view returns (int256);
    function checkOwnership() external view returns (address);

    function totalPnl() external view returns (int256 usdcTotal, int256 lpTotal);
    function realisedTotalPnl() external view returns (int256 usdcRealized, int256 lpTotal);

    function accumulatePnl() external;
    function saveProfit(address staker) external;
    function mint(address staker, uint256 amount) external;
    function burn(address staker, uint256 amount) external;

    function calcFeeLeft(address staker) external view returns (int256 feeShare, int256 periodLeft);
    function calcProfit(address staker, uint256 amount) external view returns (ProfitParams memory);
    function nonCheckCalcProfit(address staker, uint256 amount) external view returns (ProfitParams memory profit);

    function claimProfit(address staker, uint256 amount) external returns (ProfitParams memory profit);
    function setPenaltyFee(int256 _fee) external;
    function setParams(TokenParams memory _params) external;
    function canUnstake(address staker, uint256 amount) external view;

    function changeTradingPnl(int256 amount) external;
    function changeStakingPnl(int256 amount) external;

    function changePairOracle(IUniswapLpOracle _oracle) external;

    function bothPrices() external view returns (int256 lpPrice, int256 strpPrice);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IMarket } from "../interface/IMarket.sol";
import { IStrips } from "../interface/IStrips.sol";
import { IStripsLpToken } from "../interface/IStripsLpToken.sol";
import { IStakeble } from "../interface/IStakeble.sol";

import { SignedBaseMath } from "../lib/SignedBaseMath.sol";
import { IStripsLpToken } from "../interface/IStripsLpToken.sol";
import { IUniswapLpOracle } from "../interface/IUniswapLpOracle.sol";

import { SOwnable } from "../utils/SOwnable.sol";

/**
 * @title SLP token using for adding "stakebility" to any asset
 * @dev created by the asset. All calls for changing PNL are ownable:
 * Have 2 tokens by default:
 *  staking - the token that is using for staking to Asset (UNIV2 pair by default for the current version)
 *  trading - the token that is using for accumulating profit. By default it's USDC
 * @author Strips Finance
 **/
contract SLPToken is
    SOwnable,
    ReentrancyGuardUpgradeable,
    ERC20Upgradeable,
    IStripsLpToken
{ 
    using SignedBaseMath for int256;

    // Developed to be able to track 2-tokens asset
    struct StakerData {
        bool exist;

        //save initial staking/trading cummulative PNL on staker's stake event.
        int256 initialStakingPnl;
        int256 initialTradingPnl;
        
        uint256 initialBlockNum;
        uint256 initialTimeStamp;

        //Save the current staking/trading unrealized profit when the staker stake 2+ time.
        int256 unrealizedStakingProfit;
        int256 unrealizedTradingProfit;
    }
    int256 public prevStakingPnl;
    int256 public prevTradingPnl;

    int256 public cummulativeStakingPnl;
    int256 public cummulativeTradingPnl;
    
    //For tracking trading/staking "growth", should be changed by the OWNER only 
    int256 public cumTradingPNL;
    int256 public cumStakingPNL;
        
    
    //All data setup on init
    TokenParams public params;
    mapping (address => StakerData) public stakers;

    /*To not have stack too deep error */
    struct InternalCalcs {
        int256 amount;
        int256 assetPnl;
        int256 currentTradingPnl;
        int256 currentStakingPnl;

        int256 instantCummulativeStakingPnl;
        int256 isntantCummulativeTradingPnl;

        int256 unstakeShare;
        int256 feeShare;
    }

    function initialize(
        TokenParams memory _params,
        string memory _name,
        string memory _symbol,
        address _owner,
        address _admin
    ) public initializer {

        __ERC20_init(_name, _symbol);
        __ReentrancyGuard_init();

        params = _params;

        /*Init ownable */
        owner = _owner;
        admin = _admin;
        listed[admin] = true;
        strips = address(params.stripsProxy);
    }

    function instantGrowth() external view override returns (int256 usdcGrowth, int256 lpGrowth)
    {
        (, lpGrowth) = stakingPnl();
        (, usdcGrowth) = tradingPnl();
    }


    function changeTradingPnl(int256 amount) public override ownerOrAdmin
    {
        cumTradingPNL += amount;
    }
    
    function changeStakingPnl(int256 amount) public override ownerOrAdmin
    {
        cumStakingPNL += amount;
    }

    function claimProfit(address staker, uint256 amount) public override onlyOwner returns (ProfitParams memory profit)
    {
        profit = calcProfit(staker, amount);
        if (profit.stakingFee > 0){
            changeStakingPnl(profit.stakingFee);
        }

        if (profit.lpProfit > 0){
            changeStakingPnl(profit.lpProfit);
        }

        if (profit.usdcLoss < 0){
            changeTradingPnl(profit.usdcLoss);
        }

        burn(staker, amount);

        /*
        stakingProfit = profit.unstakeAmountLP;
        tradingProfit = profit.unstakeAmountERC20;
        */
    }

    function changePairOracle(IUniswapLpOracle _oracle) external override ownerOrListed
    {
        require(Address.isContract(address(_oracle)), "NOT_A_CONTRACT");

        params.pairOracle = address(_oracle);
    }

    function bothPrices() external view override returns (int256 lpPrice, int256 strpPrice)
    {
        return IUniswapLpOracle(params.pairOracle).bothPrices();
    }


    function getPairPrice() external view override returns (int256)
    {
        return IUniswapLpOracle(params.pairOracle).getPrice();
    }

    function getBurnableToken() external view override returns (address)
    {
        return params.stakingToken;
    }

    function getParams() external view override returns (TokenParams memory)
    {   
        return params;
    }

    function checkOwnership() external view override onlyOwner returns (address) {
        //DO nothing, just revert if call is not from owner

        return owner;
    }

    function totalPnl() external view override returns (int256 usdcTotal, int256 lpTotal)
    {
        int256 unrealizedPnl = IStrips(params.stripsProxy).assetPnl(owner);

        usdcTotal = unrealizedPnl + cumTradingPNL;
        lpTotal = cumStakingPNL;
    }

    function realisedTotalPnl() external view override returns (int256 usdcRealized, int256 lpTotal)
    {
        usdcRealized = cumTradingPNL;
        lpTotal = cumStakingPNL;
    }


    function stakingPnl() public view returns (int256 current, int256 cummulative)
    {
        int256 _totalSupply = int256(totalSupply());

        current = cumStakingPNL;

        if (_totalSupply == 0){
            cummulative = cummulativeStakingPnl + current;
        } else {
            cummulative = cummulativeStakingPnl + (current - prevStakingPnl).divd(_totalSupply);
        }

    }

    function tradingPnl() public view returns (int256 current, int256 cummulative)
    {
        int256 _totalSupply = int256(totalSupply());

        int256 assetPnl = IStrips(params.stripsProxy).assetPnl(owner);

        current = assetPnl + cumTradingPNL;
        
        if (_totalSupply == 0){
            cummulative = cummulativeTradingPnl + current;
        } else {
            cummulative = cummulativeTradingPnl + (current - prevTradingPnl).divd(_totalSupply);
        }
    }


    function accumulatePnl() public override onlyOwner {
        int256 currentStakingPnl = 0;
        int256 currentTradingPnl = 0;

        (currentStakingPnl, cummulativeStakingPnl) = stakingPnl();
        prevStakingPnl = currentStakingPnl;


        (currentTradingPnl, cummulativeTradingPnl) = tradingPnl();
        prevTradingPnl = currentTradingPnl;
    }

    /*All checks should be made inside caller */
    function saveProfit(address staker) public override onlyOwner {
        int256 tokenBalance = int256(balanceOf(staker));
        
        stakers[staker].unrealizedStakingProfit += (cummulativeStakingPnl - stakers[staker].initialStakingPnl).muld(tokenBalance);
        stakers[staker].unrealizedTradingProfit += (cummulativeTradingPnl - stakers[staker].initialTradingPnl).muld(tokenBalance);
    }


    /*All checks should be made inside caller */
    function mint(address staker, uint256 amount) public override onlyOwner 
    {        
        stakers[staker] = StakerData({
            exist: true,

            initialStakingPnl:cummulativeStakingPnl,
            initialTradingPnl:cummulativeTradingPnl,
    
            initialBlockNum:block.number,
            initialTimeStamp:block.timestamp,

            unrealizedStakingProfit: stakers[staker].unrealizedStakingProfit,
            unrealizedTradingProfit: stakers[staker].unrealizedTradingProfit
        });

        _mint(staker, amount);
    }

    /*All checks should be made inside caller */
    function burn(address staker, uint256 amount) public override onlyOwner 
    {
        int256 burnShare = int256(amount).divd(int256(balanceOf(staker)));

        stakers[staker].unrealizedStakingProfit -= (stakers[staker].unrealizedStakingProfit.muld(burnShare));
        stakers[staker].unrealizedTradingProfit -= (stakers[staker].unrealizedTradingProfit.muld(burnShare));

        _burn(staker, amount);

        if (balanceOf(staker) == 0){
            delete stakers[staker];
        }
    }

    function unstakeIntegrity(address staker, uint256 amount) internal view
    {
        require(stakers[staker].exist, "NO_SUCH_STAKER");
        require(amount > 0 && balanceOf(staker) >= amount, "WRONG_UNSTAKE_AMOUNT");

        
        /*Unstaking protection */
        int256 unrealizedPnl = IStrips(params.stripsProxy).assetPnl(owner);

        if (unrealizedPnl < 0){
            unrealizedPnl *= -1;

            int256 liquidity = IStakeble(owner).netLiquidity();

            require(liquidity.muld(params.unstakingTolerance) > unrealizedPnl, "UNSTAKE_RESERVE_ERROR");
        }

    }

    function canUnstake(address staker, uint256 amount) public view override
    {
        unstakeIntegrity(staker, amount);
        require(block.number > stakers[staker].initialBlockNum, "UNSTAKE_SAME_BLOCK");
    }

        


    /**
     * @dev Major view method that is using by frontend to view the current profit
     *  Here is how we show data on frontend (check ProfitParams below):
     *  1 - On major screen with the list of all stakes:
     *       totalStaked = 100 Lp tokens  (shows in LP amount of LP tokens user staked)
     *       stakingProfit (LP) = 10 LP ($10)  (shows the profit or loss that staker earned or lost in LP. Need to convert to USDC using profit.lpPrice)
     *       unstakeAmountERC20 (USDC) = -$100  (shows the profit or loss that staker earned in USDC)
     *       stakingFee = 1 LP (days left to 0 = penaltyLeft)
     *
     *  2 - on popup when staker select THE EXACT amount of SLP to unstake:
     *       profit.unstakeAmountLP (LP) = 100 LP ($100)   The amount that the staker will receive in LP, including collateral
     *       profit.unstakeAmountERC20 (USDC) = $10 | 0.   The amount that the staker will receive in USDC. Will be 0 if pnl is negative.
     *       _ hide the penalty
     *
     * @param staker staker address
     * @param amount amount of SLP tokens for unstake
     * @return profit ProfitParams all data that is required to show the profit, check IStripsLpToken interface
     *       struct ProfitParams
     *           // LP unstaked amount 
     *           int256 unstakeAmountLP;
     *
     *           //USDC unstaked amount  
     *           int256 unstakeAmountERC20;
     *
     *          //LP profit or loss not including collateral
     *           int256 stakingProfit;   
     *           
     *           //Fee that is paid if unstake in less than 7 days (paid in LP tokens)
     *           int256 stakingFee;
     *
     *          //Time in seconds left untill penalty will become 0
     *           int256 penaltyLeft;
     *
     *           //Collateral in LP that staker staked
     *           uint256 totalStaked;
     *
     *           //The current LP price (in USDC), using for conversion
     *           int256 lpPrice;
     **/
    function calcProfit(address staker, uint256 amount) public view override returns (ProfitParams memory profit)
    {
        unstakeIntegrity(staker, amount);
        profit = _implCalcProfit(staker, amount);
    }
    
    /*
       Only for stats
    */
    function nonCheckCalcProfit(address staker, uint256 amount) public view override returns (ProfitParams memory profit)
    {
        profit = _implCalcProfit(staker, amount);
    }

    function _implCalcProfit(address staker, uint256 amount) private view returns (ProfitParams memory profit)
    {
        profit.totalStaked = balanceOf(staker);
        require(amount > 0 && amount <= profit.totalStaked, "WRONG_AMOUNT");

        profit.currentVritualLpGrowth = cumStakingPNL;
        profit.currentVirtualUsdcGrowth = cumTradingPNL;
        profit.slpSupply = totalSupply();


        InternalCalcs memory internalCalcs;
        internalCalcs.amount = int256(amount);

        (internalCalcs.currentStakingPnl, 
            internalCalcs.instantCummulativeStakingPnl) = stakingPnl();
        
        (internalCalcs.currentTradingPnl, 
            internalCalcs.isntantCummulativeTradingPnl) = tradingPnl();


        internalCalcs.unstakeShare = internalCalcs.amount.divd(int256(profit.totalStaked));
        profit.stakingProfit = internalCalcs.amount.muld(internalCalcs.instantCummulativeStakingPnl - stakers[staker].initialStakingPnl) +  internalCalcs.unstakeShare.muld(stakers[staker].unrealizedStakingProfit);
        profit.unstakeAmountERC20 = internalCalcs.amount.muld(internalCalcs.isntantCummulativeTradingPnl - stakers[staker].initialTradingPnl) + internalCalcs.unstakeShare.muld(stakers[staker].unrealizedTradingProfit);

        (internalCalcs.feeShare, 
            profit.penaltyLeft) = calcFeeLeft(staker);

        profit.stakingFee = internalCalcs.amount.muld(internalCalcs.feeShare);
        profit.unstakeAmountLP = internalCalcs.amount + profit.stakingProfit - profit.stakingFee;

        profit.lpPrice = IUniswapLpOracle(params.pairOracle).getPrice();
        if (profit.unstakeAmountERC20 < 0){
            profit.usdcLoss = profit.unstakeAmountERC20;
            profit.lpProfit = -1 * profit.usdcLoss.divd(profit.lpPrice);
            profit.unstakeAmountLP = profit.unstakeAmountLP  - profit.lpProfit;

            profit.unstakeAmountERC20 = 0;
        }
    }

    /*
        2% fee during 7 days now.
    */
    function calcFeeLeft(
        address staker
    ) public view override returns (int256 feeShare, 
                                int256 periodLeft)
    {
        feeShare = 0;
        periodLeft = 0;

        int256 time_elapsed = int256(block.timestamp - stakers[staker].initialTimeStamp);

        if (time_elapsed >= params.penaltyPeriod){
            return (0, 0);
        }
        
        feeShare = params.penaltyFee - params.penaltyFee.divd(params.penaltyPeriod.toDecimal()).muld(time_elapsed.toDecimal());
        periodLeft = params.penaltyPeriod - time_elapsed;
    }

    function setPenaltyFee(int256 _fee) external override ownerOrListed{
        require(_fee >= 0, "WRONG_FEE");

        params.penaltyFee = _fee;
    }

    function setParams(TokenParams memory _params) external override ownerOrListed{
        params = _params;
    }


    function transfer(address recipient, uint256 amount) public override(ERC20Upgradeable) returns (bool) {
        require(1 == 0, "NOT_TRANSFERABLE");
        return false;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override(ERC20Upgradeable) returns (bool) {
        require(1 == 0, "NOT_TRANSFERABLE");
        return false;
    }
}

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IMarket } from "../interface/IMarket.sol";
import { IStrips } from "../interface/IStrips.sol";
import { IStripsLpToken } from "../interface/IStripsLpToken.sol";
import { IUniswapV2Pair } from "../external/interfaces/IUniswapV2Pair.sol";
import { IUniswapLpOracle } from "../interface/IUniswapLpOracle.sol";

import { IInsuranceFund } from "../interface/IInsuranceFund.sol";
import { IStakeble } from "../interface/IStakeble.sol";
import { IRewarder } from "../interface/IRewarder.sol";
import { IRewardable } from "../interface/IRewardable.sol";

import { SLPToken } from "../token/SLPToken.sol";

import { SignedBaseMath } from "../lib/SignedBaseMath.sol";
import { StorageStripsLib } from "../lib/StorageStrips.sol";
import { PnlLib } from "../lib/Pnl.sol";
import { StripsEvents, IStripsEvents } from "../lib/events/Strips.sol";

library StripsViewImpl {
    using SignedBaseMath for int256;
    using StorageStripsLib for StorageStripsLib.State;

    int256 constant SECONDS_PER_YEAR = 60 *60 *24 *365;

    struct InfoCalcParams {
        uint8 pnlIndex;

        uint8 stakingIndex;
        uint8 assetIndex;
        
        int256 strpPrice;
        int256 lpPrice;
        int256 pnlWhatIf;
    }   

    event LogCheckData(
        address indexed account,
        address indexed market,
        IStrips.CheckParams params
    );

    event LogAccountValue(
        address indexed account,
        AccountValueParams params
    );

    struct AccountValueParams {
        int256 tradingPnl;
        int256 stakingPnl;
        int256 insurancePnl;
    }

    struct ExtendedMarketData {
        bool created;
        address market;
    }


    function dispatcher(
        StorageStripsLib.State storage state,
        IStrips.ViewActionArgs memory args
    ) external view returns (bytes memory)
    {
        if (args.actionType == IStrips.ViewActionType.GetOracles){
            return _allOracles(state);
        }else if (args.actionType == IStrips.ViewActionType.GetMarkets){
            return _allMarkets(state);
        }else if (args.actionType == IStrips.ViewActionType.CalcFeeAndSlippage){
            return calcFeeWithSlippage(state, args.data);
        }else if (args.actionType == IStrips.ViewActionType.GetPosition){
            return calcPositionParams(state, args.data);
        }else if (args.actionType == IStrips.ViewActionType.CalcClose){
            return calcCloseParams(state, args.data);
        }else if (args.actionType == IStrips.ViewActionType.CalcRewards){
            return calcRewards(state, args.data);
        }else{
            return "";
        }
    }

    function _allOracles(
        StorageStripsLib.State storage state
    ) public view returns (bytes memory)
    {
        StorageStripsLib.OracleData[] memory _oracles = new StorageStripsLib.OracleData[](state.allOracles.length);

        for (uint i=0; i<state.allOracles.length; i++) {
            _oracles[i] = state.oracles[state.allOracles[i]];
        }

        return abi.encode(_oracles);
    }

    function _allMarkets(
        StorageStripsLib.State storage state
    ) public view returns (bytes memory)
    {
        ExtendedMarketData[] memory _markets = new ExtendedMarketData[](state.allMarkets.length);

        for (uint i=0; i<state.allMarkets.length; i++) {
            IMarket _address = state.allMarkets[i];
            _markets[i].created = state.markets[_address].created;
            _markets[i].market = address(_address);
        }

        return abi.encode(_markets);

    }

    /* */
    function collateralRequired(
        StorageStripsLib.State storage state,
        IMarket _market, 
        address _account
    ) external view returns (int256) {
        StorageStripsLib.Position storage position = state.getPosition(_market, _account);

        int256 total_pnl = PnlLib.calcUnrealizedPnl(state, 
                                                _market,
                                                position,
                                                SignedBaseMath.oneDecimal(),
                                                false);  //based on EXIT_PRICE

        return position.notional.muld(state.riskParams.liquidationMarginRatio) - total_pnl - position.collateral;
    }

    function apy(address _asset, int256 strpPrice, int256 lpPrice) public view returns (int256)
    {
        int256 stakingLiquidity = IStakeble(_asset).totalStaked();
        int256 rewardsApy = 0;
        if (stakingLiquidity != 0 && strpPrice != 0 && lpPrice != 0){
            int256 stakingRewardPerSec = IRewarder(IRewardable(_asset).getRewarder()).currentStakingReward();

            rewardsApy = (SECONDS_PER_YEAR.toDecimal().muld(stakingRewardPerSec.muld(strpPrice))).divd(stakingLiquidity.muld(lpPrice));
        }

        if (IStakeble(_asset).isInsurance()){
            return rewardsApy;
        }

        (int256 usdcPnl, int256 lpPnl) = IStripsLpToken(IStakeble(_asset).getSlpToken()).totalPnl();
        int256 lived = int256(IStakeble(_asset).liveTime());

        int256 ammApy = 0;
        int256 totalLiquidity = IMarket(_asset).getLiquidity();
        if (totalLiquidity != 0){
            ammApy = (SECONDS_PER_YEAR.toDecimal().divd(lived.toDecimal())).muld((usdcPnl + lpPnl.muld(lpPrice)).divd(totalLiquidity));

            if (ammApy < 0){
                (int256 usdcRealizedPnl, int256 lpPnl) = IStripsLpToken(IStakeble(_asset).getSlpToken()).realisedTotalPnl();                
                ammApy = (SECONDS_PER_YEAR.toDecimal().divd(lived.toDecimal())).muld((usdcRealizedPnl + lpPnl.muld(lpPrice)).divd(totalLiquidity));
            }
        }

        return rewardsApy + ammApy;
    }

    function getTradingInfo(
        StorageStripsLib.State storage state,
        address _account
    ) public view returns (IStrips.TradingInfo memory tradingInfo) {

        IMarket[] memory _markets = state.allMarkets;
        require(_markets.length > 0, "NO_MARKETS");

        InfoCalcParams memory calcParams;

        tradingInfo.assetData = new IStrips.AssetData[](_markets.length + 1); // + INSURANCE

        tradingInfo.positionData = new IStrips.PositionData[](_markets.length);
        calcParams.pnlIndex = 0;
        calcParams.assetIndex = 0;

        calcParams.strpPrice = IUniswapLpOracle(state.lpOracle).strpPrice();
        calcParams.lpPrice = IUniswapLpOracle(state.lpOracle).getPrice();

        for (uint i=0; i<_markets.length; i++) {
            tradingInfo.assetData[i].asset = address(_markets[i]);
            tradingInfo.assetData[i].minimumMargin = state.riskParams.liquidationMarginRatio;

            (tradingInfo.assetData[i].marketPrice,
                tradingInfo.assetData[i].oraclePrice) = _markets[i].getPrices();
            
            (tradingInfo.assetData[i].maxLong, 
                tradingInfo.assetData[i].maxShort) = _markets[i].maxNotional();
            tradingInfo.assetData[i].tvl = _markets[i].getLiquidity();

            //TODO: CALC APY
            tradingInfo.assetData[i].apy = apy(address(_markets[i]), calcParams.strpPrice, calcParams.lpPrice);
            tradingInfo.assetData[i].isInsurance = false;

            StorageStripsLib.Position storage _position = state.checkPosition(_markets[i], _account);
            if (_position.isActive == true){
                    (int256 pnlWhatIf,
                        int256 marginRatio) = PnlLib.getMarginRatio(state,
                                                                    _markets[i], 
                                                                    _position,
                                                                    SignedBaseMath.oneDecimal(),
                                                                    false); // based on EXIT_PRICE
                    calcParams.pnlWhatIf = pnlWhatIf;

                    (int256 funding_pnl,
                        int256 trading_pnl,
                        int256 total_pnl) = PnlLib.calcPnlPartsSignedBased(state, 
                                                    _markets[i], 
                                                    _position, 
                                                    SignedBaseMath.oneDecimal(), 
                                                    true); // BUT pnl based on MARKET_PRICE
                    
                    tradingInfo.positionData[calcParams.pnlIndex++] = IStrips.PositionData(_markets[i],
                                                                                total_pnl,
                                                                                trading_pnl,
                                                                                funding_pnl,
                                                                                calcParams.pnlWhatIf,
                                                                                marginRatio,
                                                                                IStrips.PositionParams(
                                                                                    _position.isLong,
                                                                                    _position.isActive,
                                                                                    _position.isLiquidated,

                                                                                    _position.notional,
                                                                                    _position.collateral,
                                                                                    _position.initialPrice
                                                                                ));
            }else if (_position.isLiquidated == true){
                tradingInfo.positionData[calcParams.pnlIndex++] = IStrips.PositionData(_markets[i],
                                                            0,
                                                            0,
                                                            0,
                                                            0,
                                                            0,
                                                            IStrips.PositionParams(
                                                                _position.isLong,
                                                                _position.isActive,
                                                                _position.isLiquidated,

                                                                _position.notional,
                                                                _position.collateral,
                                                                _position.initialPrice
                                                            ));

            }
            calcParams.assetIndex += 1;
        }
        
        
        tradingInfo.assetData[calcParams.assetIndex].asset = address(state.insuranceFund);
        tradingInfo.assetData[calcParams.assetIndex].slpToken = IStakeble(address(state.insuranceFund)).getSlpToken();
        tradingInfo.assetData[calcParams.assetIndex].tvl = state.insuranceFund.getLiquidity();
        tradingInfo.assetData[calcParams.assetIndex].isInsurance = true;
        tradingInfo.assetData[calcParams.assetIndex].minimumMargin = state.riskParams.liquidationMarginRatio;

        tradingInfo.assetData[calcParams.assetIndex].apy = apy(address(state.insuranceFund), calcParams.strpPrice, calcParams.lpPrice);

        calcParams.assetIndex += 1;
    }

    function getStakingInfo(
        StorageStripsLib.State storage state,
        address _account
    ) public view returns (IStrips.StakingInfo memory stakingInfo) {
        
        IMarket[] memory _markets = state.allMarkets;
        require(_markets.length > 0, "NO_MARKETS");
        InfoCalcParams memory calcParams;

        stakingInfo.lpPrice = IUniswapLpOracle(state.lpOracle).getPrice();
        
        stakingInfo.assetData = new IStrips.AssetData[](_markets.length + 1); //+ Insurance

        stakingInfo.stakingData = new IStrips.StakingData[](_markets.length + 1); //+ Insurance
        calcParams.stakingIndex = 0;
        calcParams.assetIndex = 0;
        
        calcParams.strpPrice = IUniswapLpOracle(state.lpOracle).strpPrice();
        calcParams.lpPrice = IUniswapLpOracle(state.lpOracle).getPrice();

        for (uint i=0; i<_markets.length; i++) {
            stakingInfo.assetData[i].asset = address(_markets[i]);
            stakingInfo.assetData[i].minimumMargin = state.riskParams.liquidationMarginRatio;

            (stakingInfo.assetData[i].marketPrice,
                stakingInfo.assetData[i].oraclePrice) = _markets[i].getPrices();
            
            (stakingInfo.assetData[i].maxLong,
                stakingInfo.assetData[i].maxShort) = _markets[i].maxNotional();

            stakingInfo.assetData[i].tvl = _markets[i].getLiquidity();
            stakingInfo.assetData[i].isInsurance = false;
            
            stakingInfo.assetData[i].apy = apy(address(_markets[i]), calcParams.strpPrice, calcParams.lpPrice);

            address slpToken = IStakeble(address(_markets[i])).getSlpToken();
            stakingInfo.assetData[i].slpToken = slpToken;
            uint256 slpAmount = IERC20(address(slpToken)).balanceOf(_account);
            if (slpAmount > 0){
                IStripsLpToken.ProfitParams memory profit = IStripsLpToken(slpToken).nonCheckCalcProfit(_account, slpAmount);

                stakingInfo.stakingData[calcParams.stakingIndex].asset = address(_markets[i]);
                stakingInfo.stakingData[calcParams.stakingIndex].totalStaked = profit.totalStaked;
    
                stakingInfo.stakingData[calcParams.stakingIndex].unrealizedLpProfit = profit.unstakeAmountLP;
                stakingInfo.stakingData[calcParams.stakingIndex].unrealizedUsdcProfit = profit.usdcLoss;
                if (profit.usdcLoss == 0){
                    stakingInfo.stakingData[calcParams.stakingIndex].unrealizedUsdcProfit = profit.unstakeAmountERC20;
                }



                calcParams.stakingIndex += 1;
            }

            calcParams.assetIndex += 1;
        }

        address sipToken = IStakeble(address(state.insuranceFund)).getSlpToken();
        
        stakingInfo.assetData[calcParams.assetIndex].asset = address(state.insuranceFund);
        stakingInfo.assetData[calcParams.assetIndex].slpToken = sipToken;
        stakingInfo.assetData[calcParams.assetIndex].tvl = state.insuranceFund.getLiquidity();
        stakingInfo.assetData[calcParams.assetIndex].isInsurance = true;
        stakingInfo.assetData[calcParams.assetIndex].minimumMargin = state.riskParams.liquidationMarginRatio;
        
        stakingInfo.assetData[calcParams.assetIndex].apy = apy(address(state.insuranceFund), calcParams.strpPrice, calcParams.lpPrice);

        uint256 sipAmount = IERC20(address(sipToken)).balanceOf(_account);
        if (sipAmount > 0){
            IStripsLpToken.ProfitParams memory profit = IStripsLpToken(sipToken).calcProfit(_account, sipAmount);

            stakingInfo.stakingData[calcParams.stakingIndex].asset = address(state.insuranceFund);
            stakingInfo.stakingData[calcParams.stakingIndex].totalStaked = profit.totalStaked;
            
            stakingInfo.stakingData[calcParams.stakingIndex].unrealizedLpProfit = profit.unstakeAmountLP;
            stakingInfo.stakingData[calcParams.stakingIndex].unrealizedUsdcProfit = profit.usdcLoss;
            if (profit.usdcLoss == 0){
                stakingInfo.stakingData[calcParams.stakingIndex].unrealizedUsdcProfit = profit.unstakeAmountERC20;
            }

            calcParams.stakingIndex += 1;
        }
    }

    function getAllInfo(
        StorageStripsLib.State storage state,
        address _account
    ) external view returns (IStrips.AllInfo memory allInfo) {
        /*
        allInfo.tradingInfo = getTradingInfo(state, _account);
        allInfo.stakingInfo = getStakingInfo(state, _account);
        */
    }

    function calcFeeWithSlippage(
        StorageStripsLib.State storage state,
        bytes memory data
    ) public view returns (bytes memory) {
        IStrips.FeeAndSlippageParams memory params = abi.decode(data, (IStrips.FeeAndSlippageParams));

        IStrips.FeeAndSlippageData memory data;

        data.market = params.market;
        (data.marketRate,
            data.oracleRate) = IMarket(params.market).getPrices();

        data.whatIfPrice = IMarket(params.market).priceChange(params.notional, params.isLong);

        (int256 marketFee, 
            int256 insuranceFee,
            int256 daoFee) = PnlLib.calcPositionFee(state,
                                                    params.notional, 
                                                    data.whatIfPrice);
        
        // 1.1 buffer
        data.fee = (marketFee + insuranceFee + daoFee).muld(110 * SignedBaseMath.onePercent());
        data.slippage = (data.whatIfPrice - data.marketRate).divd(data.marketRate);
        if (data.slippage < 0){
            data.slippage *= -1;
        }

        data.minimumMargin = state.riskParams.liquidationMarginRatio;

        int256 estimatedTradingPnl = params.notional.muld(data.marketRate - data.whatIfPrice).divd(data.marketRate);
        if (params.isLong == false) {
            /*If it's short don't forget to change the sign */
            estimatedTradingPnl *= -1;
        }
        data.estimatedMargin = (params.collateral + estimatedTradingPnl).divd(params.notional);

        return abi.encode(data);
    }

    function calcPositionParams(
        StorageStripsLib.State storage state,
        bytes memory data
    ) public view returns (bytes memory)
    {       
        IStrips.GetPositionParams memory params = abi.decode(data, (IStrips.GetPositionParams));  
        StorageStripsLib.Position storage _position = state.getPosition(IMarket(params.market), params.account);

        IStrips.PositionData memory data;
        data.market = IMarket(params.market);
        data.positionParams = IStrips.PositionParams({
            isLong: _position.isLong,
            isActive: _position.isActive,
            isLiquidated: _position.isLiquidated,
            notional: _position.notional,
            collateral: _position.collateral,
            initialPrice: _position.initialPrice
        });

        (,,data.pnl) = PnlLib.calcPnlParts(state, 
                                            IMarket(params.market), 
                                            _position,
                                            SignedBaseMath.oneDecimal(),
                                            true);
        (data.pnlWhatIf, data.marginRatio) = PnlLib.getMarginRatio(state,
                                                    IMarket(params.market),
                                                    _position,
                                                    SignedBaseMath.oneDecimal(),
                                                    false);

        return abi.encode(data);
    }

    function calcCloseParams(
        StorageStripsLib.State storage state,
        bytes memory data
    ) public view returns (bytes memory)
    {  
        IStrips.CalcCloseParams memory params = abi.decode(data, (IStrips.CalcCloseParams));
        require(params.closeRatio > 0 && params.closeRatio <= SignedBaseMath.oneDecimal(), "WRONG_RATIO");

        IStrips.CalcCloseData memory data;
        data.market = params.market;
        data.minimumMargin = state.riskParams.liquidationMarginRatio;

        StorageStripsLib.Position storage position = state.getPosition(IMarket(params.market), 
                                                                       params.account);


        (data.pnl, 
            data.marginLeft) = PnlLib.getMarginRatio(state, 
                                                    IMarket(params.market), 
                                                    position, 
                                                    params.closeRatio, 
                                                    false);
        
        //Calc fee for partly close position
        int256 notional = position.notional;
        if (params.closeRatio != SignedBaseMath.oneDecimal()){
            notional = notional.muld(params.closeRatio);
        }

        int256 currentPrice = IMarket(params.market).currentPrice();
        data.whatIfPrice = IMarket(params.market).priceChange(0 - notional, 
                                                                position.isLong);
        
        data.slippage = (data.whatIfPrice - currentPrice).divd(currentPrice);
        if (data.slippage < 0){
            data.slippage *= - 1;
        }

        (int256 marketFee, 
            int256 insuranceFee,
            int256 daoFee) = PnlLib.calcPositionFee(state, 
                                                        notional, 
                                                        data.whatIfPrice); 

        data.fee = marketFee + insuranceFee + daoFee;

        return abi.encode(data);
    }

    function calcRewards(
        StorageStripsLib.State storage state,
        bytes memory data
    ) public view returns (bytes memory)
    {  
        IStrips.CalcRewardsParams memory params = abi.decode(data, (IStrips.CalcRewardsParams));
        require(params.account != address(0), "WRONG_ACCOUNT");
        
        IStrips.CalcRewardsData memory data;
        data.account = params.account;
        data.rewardsTotal = 0;

        IMarket[] memory _markets = state.allMarkets;
        require(_markets.length > 0, "NO_MARKETS");
        
        /*
            Calc rewards for Insurance
         */
        if (IStakeble(address(state.insuranceFund)).isRewardable()){
            address rewarder = IRewardable(address(state.insuranceFund)).getRewarder();

            data.rewardsTotal += IRewarder(rewarder).totalStakerReward(params.account);
        }

        /*
            Calc rewards for Markets
        */
        for (uint i=0; i<_markets.length; i++) {
            if (IStakeble(address(_markets[i])).isRewardable() == false){
                continue;
            }
            address rewarder = IRewardable(address(_markets[i])).getRewarder();
            
            data.rewardsTotal += IRewarder(rewarder).totalTradeReward(params.account);
            data.rewardsTotal += IRewarder(rewarder).totalStakerReward(params.account);

        }


        return abi.encode(data);
    }

}

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IMarket } from "../interface/IMarket.sol";
import { IStrips } from "../interface/IStrips.sol";
import { IInsuranceFund } from "../interface/IInsuranceFund.sol";

import { SignedBaseMath } from "../lib/SignedBaseMath.sol";
import { StorageStripsLib } from "../lib/StorageStrips.sol";


library StripsAdminImpl {
    using SignedBaseMath for int256;
    using StorageStripsLib for StorageStripsLib.State;

    event LogNewMarket(
        address indexed market,
        address indexed assetOracle
    );


    function dispatcher(
        StorageStripsLib.State storage state,
        IStrips.AdminActionArgs memory args
    ) external
    {
        if (args.actionType == IStrips.AdminActionType.AddMarket){
            _addMarket(state, args.data);
        }else if (args.actionType == IStrips.AdminActionType.AddOracle){
            _addOracle(state, args.data);
        }else if (args.actionType == IStrips.AdminActionType.RemoveOracle){
            _removeOracle(state, args.data);
        }else if (args.actionType == IStrips.AdminActionType.ChangeOracle){
            _changeOracleReward(state, args.data);
        }else {
            require(true == false, "UNKNOWN_ACTIONTYPE");
        }
    }


    function _addMarket(
        StorageStripsLib.State storage state,
        bytes memory data
    ) public {
        IStrips.AddMarketParams memory params = abi.decode(data, (IStrips.AddMarketParams));

        state.addMarket(IMarket(params.market));

        emit LogNewMarket(
            params.market,
            params.assetOracle);
    }

    function _addOracle(StorageStripsLib.State storage state,
                        bytes memory data) public
    {
        IStrips.AddOracleParams memory params = abi.decode(data, (IStrips.AddOracleParams));

        state.addOracle(params.oracle,
                        params.keeperReward);
    }

    function _removeOracle(StorageStripsLib.State storage state,
                            bytes memory data) public
    {
        IStrips.RemoveOracleParams memory params = abi.decode(data, (IStrips.RemoveOracleParams));

        state.removeOracle(params.oracle);
    }


    function _changeOracleReward(StorageStripsLib.State storage state,
                                bytes memory data) public
    {
        IStrips.ChangeOracleParams memory params = abi.decode(data, (IStrips.ChangeOracleParams));

        state.changeOracleReward(params.oracle,
                                    params.newReward);
    }
}

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IMarket } from "../interface/IMarket.sol";
import { IStrips } from "../interface/IStrips.sol";
import { IStripsLpToken } from "../interface/IStripsLpToken.sol";
import { IUniswapV2Pair } from "../external/interfaces/IUniswapV2Pair.sol";
import { IUniswapLpOracle } from "../interface/IUniswapLpOracle.sol";

import { IInsuranceFund } from "../interface/IInsuranceFund.sol";
import { IStakeble } from "../interface/IStakeble.sol";
import { IRewarder } from "../interface/IRewarder.sol";
import { IRewardable } from "../interface/IRewardable.sol";

import { SLPToken } from "../token/SLPToken.sol";

import { SignedBaseMath } from "../lib/SignedBaseMath.sol";
import { StorageStripsLib } from "../lib/StorageStrips.sol";
import { PnlLib } from "../lib/Pnl.sol";
import { StripsEvents, IStripsEvents } from "../lib/events/Strips.sol";


library StripsStateImpl {
    using SignedBaseMath for int256;
    using StorageStripsLib for StorageStripsLib.State;

    function dispatcher(
        StorageStripsLib.State storage state,
        IStrips.StateActionArgs memory args
    ) external 
    {
        if (args.actionType == IStrips.StateActionType.ClaimRewards){
            claimRewards(state, args.data);
        }
    }

    function claimRewards(
        StorageStripsLib.State storage state,
        bytes memory data
    ) public {
        IStrips.ClaimRewardsParams memory params = abi.decode(data, (IStrips.ClaimRewardsParams));
        require(params.account != address(0), "BROKEN_ACCOUNT");

        IMarket[] memory _markets = state.allMarkets;
        require(_markets.length > 0, "NO_MARKETS");
        
        /*
            Claim rewards for Insurance
         */
        if (IStakeble(address(state.insuranceFund)).isRewardable()){
            address rewarder = IRewardable(address(state.insuranceFund)).getRewarder();
            IRewarder(rewarder).claimStakingReward(params.account);
        }

        /*
            Calc rewards for Markets
        */
        for (uint i=0; i<_markets.length; i++) {
            if (IStakeble(address(_markets[i])).isRewardable() == false){
                continue;
            }
            address rewarder = IRewardable(address(_markets[i])).getRewarder();
            
            IRewarder(rewarder).claimStakingReward(params.account);
            IRewarder(rewarder).claimTradingReward(params.account);
        }
    }

    function _payKeeperReward(StorageStripsLib.State storage state,
                                address keeper) external 
    {
        //TODO: implement
    }


    /*
        Info for testing models
     */

    function _check_trader(
        StorageStripsLib.State storage state,
        address _trader,
        IMarket _market) external 
    {
        IStripsEvents.CheckParams memory _checkParams;

        /*Calc market info first */
        (_checkParams.marketPrice,
            _checkParams.oraclePrice) = _market.getPrices();

        _checkParams.uniLpPrice = IUniswapLpOracle(_market.getPairOracle()).getPrice();


        /*Market params */
        StorageStripsLib.Position storage _ammPosition = state.checkPosition(_market, address(_market));

        if (_ammPosition.isActive){
            _checkParams.ammIsLong = _ammPosition.isLong;
            _checkParams.ammNotional = _ammPosition.notional;
            _checkParams.ammInitialPrice = _ammPosition.initialPrice;
            _checkParams.ammEntryPrice = _ammPosition.entryPrice;

            _checkParams.ammTotalLiquidity = _market.getLiquidity();
            (_checkParams.ammTradingLiquidity,
                _checkParams.ammStakingLiquidity) = IStakeble(address(_market)).getPartedLiquidity();

            (_checkParams.ammFundingPnl,
                _checkParams.ammTradingPnl,
                _checkParams.ammTotalPnl) = PnlLib.getAmmAllPnl(state, _market, _ammPosition);
        }

        /* Is trader a staker also? */
        address slpToken = IStakeble(address(_market)).getSlpToken();
        if (IERC20(address(slpToken)).balanceOf(_trader) > 0){
          (,
            _checkParams.stakerInitialStakingPnl,
            _checkParams.stakerInitialTradingPnl,
            _checkParams.stakerInitialBlockNum,
            ,
            _checkParams.stakerUnrealizedStakingProfit,
            _checkParams.stakerUnrealizedTradingProfit)  = SLPToken(slpToken).stakers(_trader);
        }

        _checkParams.slpTotalSupply = int256(IERC20(address(slpToken)).totalSupply());

        _checkParams.slpTradingCummulativePnl = SLPToken(slpToken).cummulativeTradingPnl();
        _checkParams.slpStakingCummulativePnl = SLPToken(slpToken).cummulativeStakingPnl();

        _checkParams.slpTradingPnl = SLPToken(slpToken).cumTradingPNL();
        _checkParams.slpStakingPnl = SLPToken(slpToken).cumStakingPNL();

        (int256 accumulatedTradingPnl,) = SLPToken(slpToken).tradingPnl();
        (int256 accumulatedStakingPnl,) = SLPToken(slpToken).stakingPnl();

        _checkParams.slpTradingPnlGrowth = accumulatedTradingPnl - SLPToken(slpToken).prevTradingPnl();
        _checkParams.slpStakingPnlGrowth = accumulatedStakingPnl - SLPToken(slpToken).prevStakingPnl();

        /*
            if it's market - just add additional integrity check
        */
        if (address(_market) == _trader){

            address[] memory allAccounts = state.allAccounts;
            for (uint i = 0; i < allAccounts.length; i++){
                if (allAccounts[i] == address(_market)){
                    continue;
                }

                StorageStripsLib.Position storage _position = state.checkPosition(_market, allAccounts[i]);
                if (_position.isActive == true){
                    int256 totalPnl;
                    (,,totalPnl) = PnlLib.getAllUnrealizedPnl(state, 
                                                        _market, 
                                                        _position, 
                                                        SignedBaseMath.oneDecimal(), 
                                                        true); // BUT pnl based on MARKET_PRICE

                    _checkParams.tradersTotalPnl += totalPnl;
                }
            }
        }else{

            StorageStripsLib.Position storage _traderPosition = state.checkPosition(_market, _trader);
            if (_traderPosition.isActive){

                _checkParams.isLong = _traderPosition.isLong;
                _checkParams.collateral = _traderPosition.collateral;
                _checkParams.notional = _traderPosition.notional;
                _checkParams.initialPrice = _traderPosition.initialPrice;
                _checkParams.entryPrice = _traderPosition.entryPrice;

                (,_checkParams.marginRatio) = PnlLib.getMarginRatio(state,
                                                                    _market, 
                                                                    _traderPosition,
                                                                    SignedBaseMath.oneDecimal(),
                                                                    false); // based on EXIT_PRICE
                (_checkParams.fundingPnl,
                    _checkParams.tradingPnl,
                    _checkParams.totalPnl) = PnlLib.getAllUnrealizedPnl(state, 
                                                            _market, 
                                                            _traderPosition, 
                                                            SignedBaseMath.oneDecimal(), 
                                                        true); // BUT pnl based on MARKET_PRICE
            }

                /*Add insurance staking rewards first */
                if (IStakeble(address(state.insuranceFund)).isRewardable()){
                    address rewarder = IRewardable(address(state.insuranceFund)).getRewarder();
                    _checkParams.stakingRewardsTotal += IRewarder(rewarder).totalStakerReward(_trader);
                }

                /*Calc rewards separately trading + staking for all markets */

                if (IStakeble(address(_market)).isRewardable()){
                    address rewarder = IRewardable(address(_market)).getRewarder();

                    _checkParams.tradingRewardsTotal += IRewarder(rewarder).totalTradeReward(_trader);
                    _checkParams.stakingRewardsTotal += IRewarder(rewarder).totalStakerReward(_trader);

                }
                
        }



        StripsEvents.logCheckData(_trader, address(_market), _checkParams);
    } 

    function _check_insurance(
        StorageStripsLib.State storage state) external 
    {
        IStripsEvents.CheckInsuranceParams memory _checkParams;

        address _insurance = address(state.insuranceFund);
        address sipToken = IStakeble(_insurance).getSlpToken();
        _checkParams.sipTotalSupply = IERC20(address(sipToken)).totalSupply();

        (_checkParams.usdcLiquidity,
            _checkParams.lpLiquidity) = IStakeble(_insurance).getPartedLiquidity();


        StripsEvents.logCheckInsuranceData(_insurance, _checkParams);
    }
}

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IMarket } from "../interface/IMarket.sol";
import { IStrips } from "../interface/IStrips.sol";
import { IInsuranceFund } from "../interface/IInsuranceFund.sol";

import { IRewarder } from "../interface/IRewarder.sol";
import { IRewardable } from "../interface/IRewardable.sol";
import { IStakeble } from "../interface/IStakeble.sol";

import { SignedBaseMath } from "../lib/SignedBaseMath.sol";
import { StorageStripsLib } from "../lib/StorageStrips.sol";
import { PnlLib } from "../lib/Pnl.sol";

library TradeImpl {
    using SignedBaseMath for int256;
    using StorageStripsLib for StorageStripsLib.State;

    event TradeAction(
        uint256 indexed timestamp,
        address indexed marketAddress,
        bool indexed isLong,
        address traderAddress,
        uint256 action,   // 0- open, 1-close, 2-liquidate
        int256 notional,
        int256 ratio,
        int256 collateral,
        int256 feePaid,
        int256 slippage,
        int256 executedPrice,  //renamed from newPrice
        int256 marketPrice,
        int256 oraclePrice
    );

    event PnlTransfered(
        uint256 indexed timestamp,
        address indexed marketAddress,
        address indexed traderAddress,
        uint256 action,
        int256 collateral,
        int256 total_pnl,  
        int256 trading_pnl,
        int256 funding_pnl
    );

    event CollateralChanged(
        uint256 indexed timestamp,
        address indexed marketAddress,
        address indexed traderAddress,
        int256 notional,
        int256 total_pnl,
        int256 diff,
        int256 newMargin  // the new margin
    );

    //against stack too deep error
    struct PositionParams {
        IMarket _market;
        address _account;
        int256 _collateral;
        int256 _leverage;
        bool _isLong;
        int256 _slippage;
    }

    struct TraderUpdate{
        int256 _notional;
        int256 _initialPrice;
        int256 _fundingPaid;
        bool _isActive;
        bool _isLong;
    }

    struct PosInfo{
        int256 _notional;
        int256 _collateral;
        int256 _unrealizedPnl;
        int256 _priceBeforeChange;
    }

    struct StackInfo{
        int256 marketPrice;
        int256 oraclePrice;
        int256 executedPrice;
        int256 feePaid;
        int256 funding_pnl;
        int256 trading_pnl;
        int256 total_pnl;
        int256 market_pnl;

        int256 notional;
        int256 ammFee;
        int256 liquidatorFee;
        int256 insuranceFee;
        int256 netEquity;
    }


    function openPosition(
        StorageStripsLib.State storage state,
        PositionParams memory posParams
    ) public {        
        require(posParams._collateral > 0, "COLLATERAL_LEQ_0");

        StorageStripsLib.Position storage prevPosition = state.checkPosition(posParams._market, posParams._account);
        
        require(prevPosition.lastChangeBlock != block.number, "SAME_BLOCK_ACTION_DENIED");

        int256 slippage = 0;
        int256 rewardedNotional = posParams._collateral * posParams._leverage;

        if (prevPosition.isActive == false){
            //There is no active position - just open new
           slippage = _open(state,
                                posParams,
                                false);  //not merge
        }else{
            if (posParams._isLong != prevPosition.isLong){    // opposite?
                
                //check if it's opposite close
                int256 notional = posParams._collateral * posParams._leverage;
                if (notional == prevPosition.notional){     // the same but opposite, just close current
                    slippage = _liquidateWholeOrCloseRatio(state,
                                                prevPosition,
                                                posParams._market,
                                                SignedBaseMath.oneDecimal());
                }else{  //netting
                    slippage = _netPosition(state,
                        posParams,
                        prevPosition
                    );

                }
            }else{  //the same side, it's aggregation
                slippage = _aggregate(state, 
                            posParams,
                            prevPosition);
            }
        }
        _requireSlippage(posParams._slippage, slippage);

        if (IStakeble(address(posParams._market)).isRewardable()){
            address rewarder = IRewardable(address(posParams._market)).getRewarder();
            IRewarder(rewarder).rewardTrader(posParams._account, rewardedNotional);
        }
    }



    function closePosition(
        StorageStripsLib.State storage state,
        IMarket _market,
        int256 _closeRatio,
        int256 _slippage
    ) public {
        require(_closeRatio > 0 && _closeRatio <= SignedBaseMath.oneDecimal(), "WRONG_CLOSE_RATIO");

        StorageStripsLib.Position storage position = state.getPosition(_market,
                                                                        msg.sender);
        
        int256 notional = position.notional;
        require(position.lastChangeBlock != block.number, "SAME_BLOCK_ACTION_DENIED");

        //ALWAYS check the full position first
        _requireMargin(state, 
                position, 
                _market,
                SignedBaseMath.oneDecimal());

        if (_closeRatio != SignedBaseMath.oneDecimal()){
            notional = notional.muld(_closeRatio);
        }

        int256 slippage = _close(state,
                                position,
                                _market,
                                _closeRatio);

        _requireSlippage(_slippage, slippage);
        if (IStakeble(address(_market)).isRewardable()){
            address rewarder = IRewardable(address(_market)).getRewarder();
            IRewarder(rewarder).rewardTrader(msg.sender, notional);
        }

        if (position.isActive){
            _requireMargin(state, 
                    position, 
                    _market,
                    SignedBaseMath.oneDecimal());
        }
    }


    function liquidatePosition(
        StorageStripsLib.State storage state,
        IMarket _market,
        address account
    ) public {
        //trader can't liquidate it's own position
        require(account != msg.sender, "TRADER_CANTBE_LIQUIDATOR");

        StorageStripsLib.Position storage position = state.getPosition(_market,
                                                                        account);


        (int256 total_pnl,
         int256 marginRatio) = PnlLib.getMarginRatio(state,
                                                    _market,
                                                    position,
                                                    SignedBaseMath.oneDecimal(),          // you can't partly close if full position is for liquidation
                                                    false);  // based on Exit price

        require(marginRatio <= state.getLiquidationRatio(), "MARGIN_OK");
        

        _liquidate(state,
                    _market,
                    msg.sender,
                    position);
    }


    function addCollateral(
        StorageStripsLib.State storage state,
        IMarket _market, 
        int256 collateral
    ) internal {
        require(collateral > 0, "COLLATERAL_LT_0");

        StorageStripsLib.Position storage position = state.getPosition(_market,
                                                                        msg.sender);

        int256 oldCollateral = position.collateral;

                //Get collateral on STRIPS balance
        _receiveCollateral(state,
                            msg.sender, 
                            collateral);

        state.addCollateral(position,
                            collateral);

        (int256 total_pnl, int256 newMargin) = _requireMargin(state,
                                                                position,
                                                                _market,
                                                                SignedBaseMath.oneDecimal());

        int256 diff = position.collateral - oldCollateral;
        emit CollateralChanged(
            block.timestamp,
            address(_market),
            msg.sender,
            position.notional,
            total_pnl,
            diff,
            newMargin  // the new margin
        );

    }

    function removeCollateral(
        StorageStripsLib.State storage state,
        IMarket _market, 
        int256 collateral
    ) internal {
        require(collateral > 0, "COLLATERAL_LT_0");

        StorageStripsLib.Position storage position = state.getPosition(_market,
                                                                        msg.sender);

        require(collateral < position.collateral, "CANT_REMOVE_ALL");

        int256 oldCollateral = position.collateral;

        state.removeCollateral(position, 
                                collateral);

        _returnCollateral(state,
                            msg.sender, 
                            collateral);
        
         (int256 total_pnl, int256 newMargin) = _requireMargin(state,
                                                    position,
                                                    _market,
                                                    SignedBaseMath.oneDecimal());
        
        int256 diff = position.collateral - oldCollateral;
        emit CollateralChanged(
            block.timestamp,
            address(_market),
            msg.sender,
            position.notional,
            total_pnl,
            diff,
            newMargin  // the new margin
        );
    }

    /*
    **************************************************************************
    *   Different netting AMM scenarios and Unrealized PNL
     **************************************************************************
    */

    function ammPositionUpdate(
        StorageStripsLib.State storage state,
        IMarket _market,
        TraderUpdate memory _traderUpdate
    ) private {
        StorageStripsLib.Position storage ammPosition = state.checkPosition(_market, address(_market));

        if (ammPosition.isActive == false){
            if (_traderUpdate._isActive == false){
                //trader closed the position, and we didn't have amm position
                return; // do nothing
            }
            bool traderRevertedSide = !_traderUpdate._isLong; //here for not too deep stack error

            //it's the new position, just open
            state.setPosition(
                _market, 
                address(_market), 
                traderRevertedSide,  //revert position 
                0,                      // for amm we don't have collateral 
                _traderUpdate._notional, 
                _traderUpdate._initialPrice, 
                false);
        }else{
            _ammCummulateFundingPnl(state, 
                                    ammPosition,
                                    _market);

            int256 ammNotional = ammPosition.notional;
            int256 ammUpdatedNotional = ammNotional;
            
            bool ammSide = ammPosition.isLong;
            bool newSide = ammSide;

            bool traderRevertedSide = !_traderUpdate._isLong; //here for not too deep stack error

            int256 closeNotional = _traderUpdate._notional;
            if (_traderUpdate._isActive == false){
                closeNotional *= -1;
            }

            //Trader open/change position
            if (ammSide == traderRevertedSide){
                //the same side
                ammUpdatedNotional += closeNotional;
                if (ammUpdatedNotional < 0){
                    ammUpdatedNotional *= -1;
                    newSide = !ammSide;
                }
            }else{
                int256 diff = ammNotional - closeNotional;        
            
                if (diff >= 0){
                    //the same side
                    ammUpdatedNotional = diff;
                } else {
                    //change side
                    ammUpdatedNotional = 0 - diff; 
                    newSide = !ammSide;
                }
            }

            if (_traderUpdate._isActive == false){
                ammPosition.unrealizedPnl += _traderUpdate._fundingPaid;
            }

            int256 t = _traderUpdate._notional.muld(_traderUpdate._initialPrice);
            if (_traderUpdate._isActive == true && _traderUpdate._isLong == false){
                t *= -1;
            }else if(_traderUpdate._isActive == false && _traderUpdate._isLong == true){
                t *= -1;
            }

            if (ammUpdatedNotional != 0){

                //Last time it was closed
                int256 a = ammPosition.initialPrice.muld(ammNotional);
                if (ammNotional == 0){
                    a = ammPosition.zeroParameter;
                }else{
                    if (ammSide == false){
                        a *= -1;
                    }
                }


                int256 divTo = ammUpdatedNotional;
                if (newSide == false){
                    divTo *= -1;
                }

                ammPosition.initialPrice = (a - t).divd(divTo);
            }else{
                
                int256 mulTo = ammNotional;
                if (ammSide == false){
                    mulTo *= -1;
                }
                ammPosition.savedTradingPnl = (_traderUpdate._initialPrice - ammPosition.initialPrice).muld(mulTo).divd(_traderUpdate._initialPrice);
                ammPosition.zeroParameter = ammPosition.initialPrice.muld(mulTo) - t; 
            }

    
            ammPosition.notional = ammUpdatedNotional;
            ammPosition.isLong = newSide;
        }
    }

    
    function _ammCummulateFundingPnl(
        StorageStripsLib.State storage state,
        StorageStripsLib.Position storage ammPosition,
        IMarket _market
    ) private {
        //ONLY once pre block
        if (ammPosition.initialBlockNumber == block.number){
            return;
        }
        ammPosition.initialBlockNumber = block.number;


        ammPosition.lastNotional = ammPosition.notional;
        ammPosition.lastIsLong = ammPosition.isLong;
        ammPosition.lastInitialPrice = ammPosition.initialPrice;

        ammPosition.unrealizedPnl = PnlLib.getAmmFundingPnl(state, 
                                                            _market, 
                                                            ammPosition);
        
        ammPosition.initialTimestamp = block.timestamp;
        ammPosition.cummulativeIndex = _market.currentOracleIndex();

    }



    /*
    **************************************************************************
    *   Different netting scenarios
    **************************************************************************
    */

    function _netPosition(
        StorageStripsLib.State storage state,
        PositionParams memory posParams,
        StorageStripsLib.Position storage prevPosition
    ) private returns (int256) {
        int256 notional = posParams._collateral * posParams._leverage;
        int256 prevNotional = prevPosition.notional;
        int256 diff = notional - prevNotional;
        // Is itpartly close?
        if (diff < 0){
            int256 closeRatio = notional.divd(prevNotional);

            // If position for liquidation, the AMM will liquidate it
            // In other way it will be partly close
            return _liquidateWholeOrCloseRatio(state,
                                        prevPosition,
                                        posParams._market,
                                        closeRatio);
        }


        // Is the new position bigger?
        if (diff > 0){

            //STEP 1: close prev(long10: return collateral+profit)
            int256 slippage = _liquidateWholeOrCloseRatio(state,
                                        prevPosition,
                                        posParams._market,
                                        SignedBaseMath.oneDecimal());
            /*
            *   open short(5K)
            *   We need to save the same proportion
            *   diff / (collateral - x) = leverage
            *   
            *   x = collateral - diff/leverage
            *   adjCollateral = collateral - collateral + diff/leverage = difd/leverage 
            */
            posParams._collateral = diff.divd(posParams._leverage.toDecimal());

            slippage += _open(state, 
                                posParams, 
                                false);  //not a merge
            
            return slippage;
        }

        require(true == false, "UNKNOWN_NETTING");
    }


    function _aggregate(
        StorageStripsLib.State storage state,
        PositionParams memory posParams,
        StorageStripsLib.Position storage prevPosition
    ) private returns (int256) {
        //We save ONLY funding_pnl
        prevPosition.unrealizedPnl = PnlLib.getFundingUnrealizedPnl(state, 
                                                            posParams._market, 
                                                            prevPosition, 
                                                            SignedBaseMath.oneDecimal(), 
                                                            true);  //based on CURRENT_MARKET_PRICE
        return _open(state,
                    posParams,
                    true);  // it's a merge
    }


    function _liquidateWholeOrCloseRatio(
        StorageStripsLib.State storage state,
        StorageStripsLib.Position storage _position,
        IMarket _market,
        int256 _closeRatio
    ) private returns (int256 slippage){

        (,int256 marginRatio) = PnlLib.getMarginRatio(state,
                                                    _market,
                                                    _position,
                                                    SignedBaseMath.oneDecimal(),          // you can't partly close if full position is for liquidation
                                                    false); // Based on exit price


        if (marginRatio <= state.getLiquidationRatio()){
            //If it's opposite close we can liquidate
            _liquidate(state,
                        _market,
                        address(_market),
                        _position
            );
            slippage = 0;
        }else{
            slippage = _close(state,
                                    _position,
                                    _market,
                                    _closeRatio); //the whole position
        }
    }


    /*
    ****************************************************
    * OPEN/CLOSE/LIQUIDATE implementation
    ****************************************************
    */

    //not safe, all checks should be outside
    function _close(
        StorageStripsLib.State storage state,
        StorageStripsLib.Position storage position,
        IMarket _market,
        int256 _closeRatio
    ) private returns (int256 slippage) {
        
        StackInfo memory _stackInfo;

        //we need to use closePrice here after the position will be closed
        (_stackInfo.funding_pnl,
           _stackInfo.trading_pnl,
            _stackInfo.total_pnl) = PnlLib.getAllUnrealizedPnl(state,
                                                        _market,
                                                        position,
                                                        _closeRatio,
                                                        false);
        

        _stackInfo.market_pnl = 0 - _stackInfo.total_pnl;


        PosInfo memory pos_info = PosInfo({
            _notional:position.notional,
            _collateral:position.collateral,
            _unrealizedPnl:position.unrealizedPnl,
            _priceBeforeChange:_market.currentPrice()
        });

        if (_closeRatio != SignedBaseMath.oneDecimal()){
            pos_info._notional = pos_info._notional.muld(_closeRatio);
            pos_info._collateral = pos_info._collateral.muld(_closeRatio);
            pos_info._unrealizedPnl = pos_info._unrealizedPnl.muld(_closeRatio);
        }

        _stackInfo.executedPrice = _market.closePosition(position.isLong, 
                                                    pos_info._notional);

        slippage = (_stackInfo.executedPrice - pos_info._priceBeforeChange).divd(pos_info._priceBeforeChange);
        if (slippage < 0){
            slippage *= -1;
        }


        // something went wrong, don't allow close positions
        require(_stackInfo.executedPrice > 0, "CLOSEPRICE_BROKEN");

        //Pay position Fee
        (_stackInfo.feePaid,,,) = _payPositionFee(state,
                                                    _market, 
                                                    msg.sender, 
                                                    pos_info._notional, 
                                                    _stackInfo.executedPrice);


        if (_stackInfo.market_pnl > 0){
            //PROFIT: trader pays to Market from collateral

            if (_stackInfo.market_pnl > pos_info._collateral){
                _stackInfo.market_pnl = pos_info._collateral;
            }

            _payProfitOnPositionClose(state,
                                    _market,
                                    address(this),
                                    _stackInfo.market_pnl);
            int256 left = pos_info._collateral - _stackInfo.market_pnl;
            if (left > 0){
                _returnCollateral(state,
                                    msg.sender, 
                                    left);
            }
        }
        else if (_stackInfo.market_pnl < 0){
            //LOSS: market pays to trader from liquidity

            int256 liquidity = _market.getLiquidity();
            if (liquidity < _stackInfo.total_pnl){
                
                /*
                    Depreccate this:
                    int256 debt = _stackInfo.total_pnl - liquidity;
                    
                    Because liquidity calculated based on LP price, BUT if we will borrow diff
                    and then we will need to burn LP from market, then in swapOff mode it will be always reverted

                    That's why we borrow the full total_pnl amount
                 */
                _borrowInsuranceOnBehalfOfMarket(state,
                                                address(_market), 
                                                _stackInfo.total_pnl);
            }

            state.withdrawFromMarket(_market,
                                        msg.sender,
                                        _stackInfo.total_pnl);
            _returnCollateral(state,
                                msg.sender,
                                pos_info._collateral);
        }
        else if (_stackInfo.market_pnl == 0){
            //ZERO: just return collateral to trader
            _returnCollateral(state,
                                msg.sender,
                                pos_info._collateral);
        }


        if (position.isLong == false){
            _stackInfo.funding_pnl *= -1;
        }

        (_stackInfo.marketPrice, _stackInfo.oraclePrice) = _market.getPrices();

        emit TradeAction(
            block.timestamp,    //timestamp
	        address(_market),   // marketAddress	
            position.isLong,    // isLong
            position.trader,    // traderAddress

            1,                    //action = close
            pos_info._notional,   // notional
            _closeRatio,          // ratio
            pos_info._collateral, // collateral
            
            _stackInfo.feePaid,               // feePaid
            slippage,               // slippage
            _stackInfo.executedPrice,             // executedPrice

            _stackInfo.marketPrice,            //marketPrice
            _stackInfo.oraclePrice            //oraclePrice
        );     

        emit PnlTransfered(
            block.timestamp,
            address(_market),
            position.trader,
            1, // 0 - open, 1- close, 2 -liquidate
            pos_info._collateral,
            _stackInfo.total_pnl,  
            _stackInfo.trading_pnl,
            _stackInfo.funding_pnl
        );


        ammPositionUpdate(state,
                _market,
                TraderUpdate({
                    _notional:pos_info._notional,
                    _isLong: position.isLong,
                    _initialPrice:position.initialPrice,
                    _fundingPaid:_stackInfo.funding_pnl,
                    _isActive:false
                }));

        _unsetPostion(state,
                    position,
                    pos_info._notional,
                    pos_info._collateral,
                    _closeRatio,
                    pos_info._unrealizedPnl);
    }

    function _open(
        StorageStripsLib.State storage state,
        PositionParams memory posParams,
        bool merge
    ) private returns (int256 slippage) {
        StackInfo memory _stackInfo;

        _stackInfo.notional = posParams._collateral * posParams._leverage;

        _requireNotional(posParams._market,
                        _stackInfo.notional,
                        posParams._isLong);

        _stackInfo.marketPrice = posParams._market.currentPrice();
        _stackInfo.executedPrice = posParams._market.openPosition(posParams._isLong, _stackInfo.notional);

        slippage = (_stackInfo.executedPrice - _stackInfo.marketPrice).divd(_stackInfo.marketPrice);
        if (slippage < 0){
            slippage *= -1;
        }

        // something went wrong, don't allow open positions
        require(_stackInfo.executedPrice > 0, "OPEN_PRICE_LTE_0");
        
        state.setPosition(
            posParams._market,
            posParams._account,
            posParams._isLong,
            posParams._collateral,
            _stackInfo.notional,
            _stackInfo.executedPrice,
            merge
        );

    

        //Get collateral on STRIPS balance
        _receiveCollateral(state,
                            posParams._account, 
                            posParams._collateral);

        //Send fee to Market and Insurance Balance, it will change liquidity
        (_stackInfo.feePaid,,,) = _payPositionFee(state,
                                                posParams._market, 
                                                posParams._account, 
                                                _stackInfo.notional, 
                                                _stackInfo.executedPrice);
        
        StorageStripsLib.Position storage position = state.getPosition(posParams._market, posParams._account);
        ammPositionUpdate(state,
                posParams._market,
                TraderUpdate({
                    _notional:_stackInfo.notional,
                    _isLong:posParams._isLong,
                    _initialPrice:position.entryPrice,
                    _fundingPaid:0,
                    _isActive:true
                }));
    
        
        //Always check margin after any open
        _requireMargin(state,
                position,
                posParams._market,
                SignedBaseMath.oneDecimal());

        (_stackInfo.marketPrice, _stackInfo.oraclePrice) = posParams._market.getPrices();

        emit TradeAction(
            block.timestamp,    //timestamp
	        address(posParams._market),   // marketAddress	
            posParams._isLong,      // isLong
            posParams._account,     // traderAddress

            0,                      //action = open
            _stackInfo.notional,               // notional
            0,                      // ratio
            posParams._collateral, // collateral
            
            _stackInfo.feePaid,               // feePaid
            slippage,               // slippage
            _stackInfo.executedPrice,             // executedPrice

            _stackInfo.marketPrice,            //marketPrice
            _stackInfo.oraclePrice            //oraclePrice
        );     


    }

    function _liquidate(
        StorageStripsLib.State storage state,
        IMarket _market,
        address _liquidator,
        StorageStripsLib.Position storage position
    ) private returns (int256 slippage) {
        //The closePrice after the notional removed should be USED
        StackInfo memory _stackInfo;

        (_stackInfo.ammFee,
        _stackInfo.liquidatorFee,
        _stackInfo.insuranceFee,
        _stackInfo.funding_pnl,
        _stackInfo.trading_pnl,
        _stackInfo.total_pnl,
        _stackInfo.netEquity) = PnlLib.calcLiquidationFee(state,
                                                        _market, 
                                                        position);

        /*
            We need this for logging only.
            If we liquidate position we want to now unrealized_pnl which is exactly total_pnl.
            So on dashboard to monitor the netEquity = collateral - feePaid. 
         */
        _stackInfo.feePaid = _stackInfo.total_pnl;
        if (_stackInfo.feePaid < 0) {
            _stackInfo.feePaid *= -1;
        }

        _stackInfo.marketPrice = _market.currentPrice();
        _stackInfo.executedPrice = _market.closePosition(position.isLong, 
                                                        position.notional);

        slippage = (_stackInfo.executedPrice - _stackInfo.marketPrice).divd(_stackInfo.marketPrice);
        if (slippage < 0){
            slippage *= -1;
        }
        
        //Calc how much debt we need to borrow for all possible situations
        int256 debt = 0; 
        if (_stackInfo.netEquity < 0){
            debt = 0 - _stackInfo.netEquity;
        }else{
            _stackInfo.insuranceFee += _stackInfo.netEquity;
        }
        
        /*EVERYTHING paid from collateral:
        * 1. Market fee - paid from strips balance to market
        * 2. Insurance fee - paid from strips balance to insurance
        * 3. Liquidator fee - paid from strips balance to liquidator (we use _returnCollateral)
        */
        if (debt > 0) {
            _borrowInsurance(state,
                            address(this), 
                            debt);//SO if we need to borrow we borrow to STRIPS balance, to keep logic unified

        }

        state.depositToMarket(_market, address(this), _stackInfo.ammFee); //pay to Market

        if (_stackInfo.insuranceFee > 0){
            state.depositToInsurance(address(this), _stackInfo.insuranceFee); //pay to Insurance
        }
        _returnCollateral(state,
                        _liquidator, 
                        _stackInfo.liquidatorFee); // pay to liquidator

        
        
        if (position.isLong == false){
            _stackInfo.funding_pnl*= -1;
        }
        ammPositionUpdate(state,
                _market,
                TraderUpdate({
                    _notional:position.notional,
                    _isLong:position.isLong,
                    _initialPrice:position.initialPrice,
                    _fundingPaid:_stackInfo.funding_pnl,
                    _isActive:false
                }));

        if (IStakeble(address(_market)).isRewardable()){
            address rewarder = IRewardable(address(_market)).getRewarder();
            IRewarder(rewarder).rewardTrader(position.trader, position.notional);
        }
        
        (_stackInfo.marketPrice, _stackInfo.oraclePrice) = _market.getPrices();

        emit TradeAction(
            block.timestamp,    //timestamp
	        address(_market),   // marketAddress	
            position.isLong,      // isLong
            position.trader,     // traderAddress

            2,                       //action = liquidate
            position.notional,       // notional
            0,                       // ratio
            position.collateral,    // collateral
            
            _stackInfo.feePaid,               // feePaid
            slippage,               // slippage
            _stackInfo.executedPrice,       // executedPrice

            _stackInfo.marketPrice,            //marketPrice
            _stackInfo.oraclePrice            //oraclePrice
        );     

        emit PnlTransfered(
            block.timestamp,
            address(_market),
            position.trader,
            2, // 0 - open, 1- close, 2 -liquidate
            position.collateral,
            _stackInfo.total_pnl,  
            _stackInfo.trading_pnl,
            _stackInfo.funding_pnl
        );


        //ALWAYS CLOSE here: no need to read from storage, that's why 0
        _unsetPostion(state,
                    position,
                    0,
                    0,
                    SignedBaseMath.oneDecimal(),
                    0);
        
        position.isLiquidated = true;
    }

    /*
    *
    *   HELPERS
    *
    */
    function _unsetPostion(
        StorageStripsLib.State storage state,
        StorageStripsLib.Position storage position,
        int256 notional,
        int256 collateral,
        int256 _closeRatio,
        int256 unrealizedPaid
    ) private {
        if (_closeRatio == SignedBaseMath.oneDecimal()){
            state.unsetPosition(position);
        }else{
            
            //It's just partly close
            state.partlyClose(
                position,
                collateral,
                notional,
                unrealizedPaid      
            );
        }
    }


    function _requireMargin(
        StorageStripsLib.State storage state,
        StorageStripsLib.Position storage position,
        IMarket _market,
        int256 _closeRatio
    ) private view returns (int256 total_pnl, int256 marginRatio) {
        (total_pnl, 
            marginRatio) = PnlLib.getMarginRatio(state,
                                                    _market,
                                                    position,
                                                    _closeRatio,
                                                    false);  // based on Exit Price always

        // Trader can't close position for liquidation                                            
        _requireMarginRatio(state, 
                            marginRatio);
    }


    function _requireMarginRatio(
        StorageStripsLib.State storage state,
        int256 marginRatio
    ) private view {
        require(marginRatio >= state.getLiquidationRatio(), "NOT_ENOUGH_MARGIN");
    }

    function _requireSlippage(
        int256 _requested,
        int256 _current
    ) private {
        require(_requested >= _current, "SLIPPAGE_EXCEEDED");
    }


    function _requireNotional(
        IMarket _market,
        int256 notional,
        bool isLong
    ) private {
        require(notional > 0, "NOTIONAL_LT_0");

        (int256 maxLong, int256 maxShort) = _market.maxNotional();

        if (isLong){
            require(notional <= maxLong, "NOTIONAL_GT_MAX");
        }else{
            require(notional <= maxShort, "NOTIONAL_GT_MAX");
        }
    }


    function _receiveCollateral(
        StorageStripsLib.State storage state,
        address _from, 
        int256 _amount
    )private returns (int256) {
        SafeERC20.safeTransferFrom(state.tradingToken, 
                                _from, 
                                address(this), 
                                uint(_amount));
    }

    function _returnCollateral(
        StorageStripsLib.State storage state,
        address _to, 
        int256 _amount
    )private returns (int256) {
        SafeERC20.safeTransfer(state.tradingToken, 
                                _to, 
                                uint(_amount));
    }

    function _payProfitOnPositionClose(
        StorageStripsLib.State storage state,
        IMarket _market, 
        address _from,
        int256 _amount
    ) private {
        int256 insuranceFee = _amount.muld(state.riskParams.insuranceProfitOnPositionClosed);
        int256 marketFee =_amount - insuranceFee;
        require(insuranceFee > 0 && marketFee > 0, "FEE_CALC_ERROR");
        state.depositToMarket(_market, 
                                _from, 
                                marketFee);

        //Pay fee to insurance fund
        state.depositToInsurance(_from, 
                                    insuranceFee);


    }

    //TODO: Can we store all the money on Strips? And just keep balances.
    // The only advantage is that Insurance money is safe in case of hack
    function _payPositionFee(
        StorageStripsLib.State storage state,
        IMarket _market, 
        address _from, 
        int256 _notional, 
        int256 _price
    ) private returns (int256 totalFee, int256 marketFee, int256 insuranceFee, int256 daoFee) {

        (marketFee, insuranceFee, daoFee) = PnlLib.calcPositionFee(state, 
                                                            _notional, 
                                                            _price);
        totalFee = marketFee + insuranceFee + daoFee;

        require(marketFee > 0 && insuranceFee > 0, "FEE_CALC_ERROR");

        state.depositToMarket(_market, 
                                _from, 
                                marketFee);
        
        //Pay fee to insurance fund
        state.depositToInsurance(_from, 
                                insuranceFee);

        if(daoFee > 0){
            state.depositToDao(_from,
                                daoFee);
        }
    }

    function _borrowInsurance(
        StorageStripsLib.State storage state,
        address _to, 
        int256 _amount         
    ) private {

        state.withdrawFromInsurance(_to, _amount);
    }

    /* 
        USE only this for borrowing on behalf of market
        This function reflect usdc growth.
     */
    function _borrowInsuranceOnBehalfOfMarket(
        StorageStripsLib.State storage state,
        address _to, 
        int256 _amount         
    ) private {
        state.withdrawFromInsurance(_to, _amount);

        IStakeble(_to).changeTradingPnl(_amount);
    }


}

pragma solidity ^0.8.0;

import { IStrips } from "../interface/IStrips.sol";
import { StorageStripsLib } from "../lib/StorageStrips.sol";

/*
    All new variables should be updated here
    The new versions of Strips MUST inherit this 
    to keep consistent on storage layout 
 */
abstract contract SState
{
    StorageStripsLib.State public g_state;
}

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IMarket } from "../interface/IMarket.sol";
import { IStrips } from "../interface/IStrips.sol";

import { IAssetOracle } from "../interface/IAssetOracle.sol";
import { IInsuranceFund } from "../interface/IInsuranceFund.sol";
import { IStripsLpToken } from "../interface/IStripsLpToken.sol";

import { SignedBaseMath } from "./SignedBaseMath.sol";
import { StorageStripsLib } from "./StorageStrips.sol";
import { StorageMarketLib } from "./StorageMarket.sol";

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library PnlLib {
    int256 constant ANN_PERIOD_SEC = 31536000;

    using SignedBaseMath for int256;
    using StorageStripsLib for StorageStripsLib.State;
    using StorageMarketLib for StorageMarketLib.State;

    // To not have stack too deep error
    struct PosInfo {
        bool isLong;
        int256 initialPrice;
        uint256 cummulativeIndex;
        int256 notional;
        int256 unrealizedPnl;
    }

    struct AmmPosInfo {
        int256 notional;        
        int256 initialPrice;
        bool lastIsLong;
    }


    function getMarginRatio(
        StorageStripsLib.State storage state,
        IMarket _market,
        StorageStripsLib.Position storage _position,
        int256 _notionalRatio,
        bool is_market_price
    ) internal view returns (int256 total_pnl, int256 marginRatio) {
         total_pnl = calcUnrealizedPnl(state,
                                        _market,
                                        _position,
                                        _notionalRatio,
                                        is_market_price);
        
        //traderPnl already calculated for right ratio
        if (_notionalRatio == SignedBaseMath.oneDecimal()){
            marginRatio = (_position.collateral + total_pnl).divd(_position.notional);
        }else{
            int256 full_pnl = calcUnrealizedPnl(state,
                                        _market,
                                        _position,
                                        SignedBaseMath.oneDecimal(),
                                        is_market_price);
                                        
            // Margin ratio after partly close
            marginRatio = (_position.collateral.muld(SignedBaseMath.oneDecimal() - _notionalRatio) + full_pnl - total_pnl).divd(_position.notional.muld(SignedBaseMath.oneDecimal() - _notionalRatio));
        }
    }

    function getFundingUnrealizedPnl(
        StorageStripsLib.State storage state,
        IMarket _market,
        StorageStripsLib.Position storage position,
        int256 _notionalRatio,
        bool is_market_price
    ) internal view returns (int256) {
        (int256 funding_pnl,
            int256 trading_pnl,
            int256 total_pnl) = calcPnlParts(state, 
                                        _market, 
                                        position,
                                        _notionalRatio,
                                        is_market_price);
        return funding_pnl;
    }

    
    function calcUnrealizedPnl(
        StorageStripsLib.State storage state,
        IMarket _market,
        StorageStripsLib.Position storage position,
        int256 _notionalRatio,
        bool is_market_price
    ) internal view returns (int256) {
        (int256 funding_pnl,
            int256 trading_pnl,
            int256 total_pnl) = calcPnlParts(state, 
                                        _market, 
                                        position,
                                        _notionalRatio,
                                        is_market_price);
        return total_pnl;
    }

    function getAmmTotalPnl(
        StorageStripsLib.State storage state,
        IMarket _market,
        StorageStripsLib.Position storage position
    ) internal view returns (int256) {
        (int256 funding_pnl,
            int256 trading_pnl,
            int256 total_pnl) = calcAmmPnlParts(state, 
                                        _market, 
                                        position);
        return total_pnl;
    }


    function getAmmFundingPnl(
        StorageStripsLib.State storage state,
        IMarket _market,
        StorageStripsLib.Position storage position
    ) internal view returns (int256) {
        (int256 funding_pnl,
            int256 trading_pnl,
            int256 total_pnl) = calcAmmPnlParts(state, 
                                        _market, 
                                        position);
        return funding_pnl;
    }


    function getAmmAllPnl(
        StorageStripsLib.State storage state,
        IMarket _market,
        StorageStripsLib.Position storage position
    ) internal view returns (int256 funding_pnl,
                            int256 trading_pnl,
                            int256 total_pnl) {
        (funding_pnl,
            trading_pnl,
            total_pnl) = calcAmmPnlParts(state, 
                                        _market, 
                                        position);
    }

    function getAllUnrealizedPnl(
        StorageStripsLib.State storage state,
        IMarket _market,
        StorageStripsLib.Position storage position,
        int256 _notionalRatio,
        bool is_market_price
    ) internal view returns (int256 funding_pnl,
                            int256 trading_pnl,
                            int256 total_pnl) {
        (funding_pnl,
            trading_pnl,
            total_pnl) = calcPnlParts(state, 
                                        _market, 
                                        position,
                                        _notionalRatio,
                                        is_market_price);
    }


    //It can calc partlyPnl 
    function calcPnlPartsSignedBased(
        StorageStripsLib.State storage state,
        IMarket _market,
        StorageStripsLib.Position storage position,
        int256 _notionalRatio,
        bool is_market_price
    ) internal view returns (int256 funding_pnl,
                            int256 trading_pnl,
                            int256 total_pnl)
    {
        (funding_pnl,
            trading_pnl,
            total_pnl) = calcPnlParts(state, 
                                        _market, 
                                        position,
                                        _notionalRatio,
                                        is_market_price);

        if (position.isLong == false){
            funding_pnl *= -1;
            trading_pnl *= -1;
        }
    
    }


    //It can calc partlyPnl 
    function calcPnlParts(
        StorageStripsLib.State storage state,
        IMarket _market,
        StorageStripsLib.Position storage position,
        int256 _notionalRatio,
        bool is_market_price
    ) internal view returns (int256 funding_pnl,
                            int256 trading_pnl,
                            int256 total_pnl)
    {
        
        PosInfo memory pos_info;

        //Save gas on reading
        pos_info.isLong = position.isLong;
        pos_info.initialPrice = position.initialPrice;
        pos_info.notional = position.notional;
        pos_info.unrealizedPnl = position.unrealizedPnl;
        if (_notionalRatio != SignedBaseMath.oneDecimal()){
            pos_info.notional = pos_info.notional.muld(_notionalRatio);
            pos_info.unrealizedPnl = pos_info.unrealizedPnl.muld(_notionalRatio);
        }

        

        int256 _price;

        if (is_market_price == true){
            _price = _market.currentPrice();
        }else{
            _price = _market.priceChange(0 - pos_info.notional, 
                                            pos_info.isLong);
        }
        
        //DONE: after 24-June discussion
        trading_pnl = pos_info.notional.muld(_price - pos_info.initialPrice).divd(_price);


                //scalar - in seconds since epoch
        int256 time_elapsed = int256(block.timestamp - position.initialTimestamp);

        //we have funding_pnl ONLY for next block
        if (time_elapsed > 0){
            int256 oracle_avg = calcOracleAverage(_market, position.cummulativeIndex);

            int256 fundingPeriod = _market.getFundingPeriod();
            int256 proportion = time_elapsed.toDecimal().divd(ANN_PERIOD_SEC.toDecimal());      

            funding_pnl = pos_info.notional.muld(oracle_avg.muld(time_elapsed.toDecimal()) - pos_info.initialPrice.muld(proportion)).muld(fundingPeriod);
        }

        funding_pnl += pos_info.unrealizedPnl;

        if (pos_info.isLong){
            total_pnl = funding_pnl + trading_pnl;
        }else{
            total_pnl = 0 - trading_pnl - funding_pnl;
        }
    }

    function calcAmmPnlParts(
        StorageStripsLib.State storage state,
        IMarket _market,
        StorageStripsLib.Position storage ammPosition
    ) internal view returns (int256 funding_pnl,
                            int256 trading_pnl,
                            int256 total_pnl)
    {

        int256 _price = _market.currentPrice();


        //trading calcs always based on current notional
        trading_pnl = ammPosition.notional.muld(_price - ammPosition.initialPrice).divd(_price);
        if (ammPosition.notional == 0){
            trading_pnl = ammPosition.savedTradingPnl;
        }

        AmmPosInfo memory amm_info = AmmPosInfo({
            notional:ammPosition.lastNotional,      
            initialPrice:ammPosition.lastInitialPrice,
            lastIsLong:ammPosition.lastIsLong
        });


        if (ammPosition.initialBlockNumber != block.number){
            amm_info.notional = ammPosition.notional;
            amm_info.initialPrice = ammPosition.initialPrice;
            amm_info.lastIsLong = ammPosition.isLong;
        }

        int256 time_elapsed = int256(block.timestamp - ammPosition.initialTimestamp);

        int256 instantFunding;
        if (time_elapsed > 0){
            int256 oracle_avg;

            oracle_avg = calcOracleAverage(_market, ammPosition.cummulativeIndex);

            int256 fundingPeriod = _market.getFundingPeriod();
            int256 proportion = time_elapsed.toDecimal().divd(ANN_PERIOD_SEC.toDecimal());     

            instantFunding = amm_info.notional.muld(oracle_avg.muld(time_elapsed.toDecimal()) - amm_info.initialPrice.muld(proportion)).muld(fundingPeriod);
            //SUPER carefull here - we need to know the PREVIOUS sign if we calc based on historical value
            if (ammPosition.lastIsLong == false){
                instantFunding *= -1;
            }

            
            
        }


        funding_pnl = instantFunding + ammPosition.unrealizedPnl;


        //BUT here we are using current isLong of amm
        if (ammPosition.notional == 0){
            total_pnl = funding_pnl + trading_pnl;
        }
        else if (ammPosition.isLong == true){
            total_pnl = funding_pnl + trading_pnl;
        }else{
            total_pnl = 0 - trading_pnl + funding_pnl;
        }

    }



    function calcOracleAverage(
        IMarket _market,
        uint256 fromIndex
    ) internal view returns (int256) {        
        return IAssetOracle(_market.getAssetOracle()).calcOracleAverage(fromIndex);
    }

    function calcPositionParams(
        StorageStripsLib.State storage state,
        IMarket _market, 
        address _account, 
        bool is_market_price
    ) internal view returns (int256 funding_pnl, 
                            int256 trading_pnl,
                            int256 total_pnl,
                            int256 margin_ratio)
    {
        StorageStripsLib.Position storage _position = state.getPosition(_market, _account);

        (funding_pnl,
          trading_pnl,
          total_pnl) = calcPnlParts(state, 
                                    _market, 
                                    _position,
                                    SignedBaseMath.oneDecimal(),
                                    is_market_price);
        
        margin_ratio = (_position.collateral + total_pnl).divd(_position.notional);
    }

    /*
    *
    *   FEE CALCULATIOSN
    *
    */

    function calcLiquidationFee(
        StorageStripsLib.State storage state,
        IMarket _market,
        StorageStripsLib.Position storage position
    ) internal view returns (int256 ammFee,
                            int256 liquidatorFee,
                            int256 insuranceFee,
                            int256 funding_pnl,
                            int256 trading_pnl,
                            int256 total_pnl,
                            int256 netEquity)
    {

        //we calc PNL based on price after the position is closed
        (funding_pnl,
            trading_pnl,
            total_pnl) = getAllUnrealizedPnl(state,
                                                _market, 
                                                position,
                                                SignedBaseMath.oneDecimal(),
                                                false);

        int256 unrealizedPnl = total_pnl;
        if (unrealizedPnl < 0){
            unrealizedPnl *= -1;
        }

        netEquity = position.collateral - unrealizedPnl;

        //Market and liquidator Fee are always the same
        ammFee = unrealizedPnl.muld(state.riskParams.marketFeeRatio);
        liquidatorFee = unrealizedPnl.muld(state.riskParams.liquidatorFeeRatio);

        //easy to read is more important than optimization now
        int256 insuranceFeeRatio = SignedBaseMath.oneDecimal() - state.riskParams.liquidatorFeeRatio - state.riskParams.marketFeeRatio;

        insuranceFee = unrealizedPnl.muld(insuranceFeeRatio);
    }

    function calcPositionFee(
        StorageStripsLib.State storage state,
        int256 _notional,
        int256 _price
    ) internal view returns (int256 fee, int256 iFee, int256 daoFee) {
        int256 calcPrice = _price;
        if (calcPrice < state.riskParams.minimumPricePossible){
            calcPrice = state.riskParams.minimumPricePossible;
        }

        int256 baseFee = calcPrice.muld(_notional).muld(SignedBaseMath.onePercent()) + state.riskParams.flatFee;

        int256 ammFeeRatio = state.riskParams.fundFeeRatio;
        int256 daoFeeRatio = state.riskParams.daoFeeRatio;
        int256 iFeeRatio = SignedBaseMath.oneDecimal() - ammFeeRatio - daoFeeRatio;

        require((ammFeeRatio + daoFeeRatio + iFeeRatio) <= SignedBaseMath.oneDecimal(), "FEE_SUM_GT_1");

        fee = ammFeeRatio.muld(baseFee);
        daoFee = daoFeeRatio.muld(baseFee);
        iFee = iFeeRatio.muld(baseFee);
    }
}

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IMarket } from "../interface/IMarket.sol";
import { IStrips } from "../interface/IStrips.sol";
import { IStakeble } from "../interface/IStakeble.sol";
import { IAssetOracle } from "../interface/IAssetOracle.sol";
import { IInsuranceFund } from "../interface/IInsuranceFund.sol";
import { IStripsLpToken } from "../interface/IStripsLpToken.sol";

import { SignedBaseMath } from "./SignedBaseMath.sol";
import { StorageMarketLib } from "./StorageMarket.sol";

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library StorageStripsLib {
    using SignedBaseMath for int256;
    
    struct MarketData {
        bool created;

        //TODO: any data about the
    }

    struct Position {
        IMarket market; //can be removed
        address trader;

        int256 initialPrice; //will become avg on _aggregation
        int256 entryPrice;   // always the "new market price"
        int256 prevAvgPrice; 

        int256 collateral; 
        int256 notional; 

        uint256 initialTimestamp;
        uint256 cummulativeIndex; 
        uint256 initialBlockNumber;
        uint256 posIndex;           // use this to find position by index
        uint256 lastChangeBlock;

        int256 unrealizedPnl;   //used to save funding_pnl for aggregation
        
        //TODO: refactor this
        bool isLong;
        bool isActive;
        bool isLiquidated;  
        
        //used only for AMM
        bool isAmm;
        int256 savedTradingPnl;    // use this to deal with div to zero when ammUpdatedNotional == 0
        int256 zeroParameter;
        int256 lastNotional;      // for amm we calculate funding based on notional from prev block always
        int256 lastInitialPrice;  // for amm
        bool lastIsLong;

        int256 oraclePriceUsed;
    }

    struct RiskParams {
        int256 fundFeeRatio; //the part of fee that goes to Fee Fund. insuranceFeeRatio = 1 - fundFeeRatio 
        int256 daoFeeRatio;

        int256 liquidatorFeeRatio; // used to calc the liquidator reward insuranceLiquidationFeeRatio = 1 - liquidatorFeeRatio
        int256 marketFeeRatio; // used to calc market ratio on Liquidation
        int256 insuranceProfitOnPositionClosed;

        int256 liquidationMarginRatio; // the minimum possible margin ratio.
        int256 minimumPricePossible; //use this when calculate fee
        int256 flatFee;
    }

    struct OracleData {
        bool isActive;
        int256 keeperReward; 
    }

    /*Use this struct for fast access to position */
    struct PositionMeta {
        bool isActive; // is Position active

        address _account; 
        IMarket _market;
        uint _posIndex;
    }


    //GENERAL STATE - keep aligned on update
    struct State {
        address dao;
        uint8 _currentLevel;

        /*Markets data */
        IMarket[] allMarkets;
        mapping (IMarket => MarketData) markets;

        /*Traders data */
        address[] allAccounts; // never pop
        mapping (address => bool) existingAccounts; // so to not add twice, and have o(1) check for addin

        mapping (address => mapping(IMarket => Position)) accounts; 
        
        uint[] allIndexes;  // if we need to loop through all positions we use this array. Reorder it to imporove effectivenes
        mapping (uint => PositionMeta) indexToPositionMeta;
        uint256 currentPositionIndex; //index of the latest created position

        /*Oracles */
        address[] allOracles;
        mapping(address => OracleData) oracles;

        /*Strips params */
        RiskParams riskParams;
        IInsuranceFund insuranceFund;
        IERC20 tradingToken;

        // last ping timestamp
        uint256 lastAlive;
        // the time interval during which contract methods are available that are marked with a modifier ifAlive
        uint256 keepAliveInterval;

        address lpOracle;
    }

    /*
        Oracles routines
    */
    function addOracle(
        State storage state,
        address _oracle,
        int256 _keeperReward
    ) internal {
        require(state.oracles[_oracle].isActive == false, "ORACLE_EXIST");
        
        state.oracles[_oracle].keeperReward = _keeperReward;
        state.oracles[_oracle].isActive = true;

        state.allOracles.push(_oracle);
    }

    function removeOracle(
        State storage state,
        address _oracle
    ) internal {
        require(state.oracles[_oracle].isActive == true, "NO_SUCH_ORACLE");
        state.oracles[_oracle].isActive = false;
    }


    function changeOracleReward(
        State storage state,
        address _oracle,
        int256 _newReward
    ) internal {
        require(state.oracles[_oracle].isActive == true, "NO_SUCH_ORACLE");
        state.oracles[_oracle].keeperReward = _newReward;
    }


    /*
    *******************************************************
    *   getters/setters for adding/removing data to state
    *******************************************************
    */

    function setInsurance(
        State storage state,
        IInsuranceFund _insurance
    ) internal
    {
        require(address(_insurance) != address(0), "ZERO_INSURANCE");

        state.insuranceFund = _insurance;
    }

    function getMarket(
        State storage state,
        IMarket _market
    ) internal view returns (MarketData storage market) {
        market = state.markets[_market];
        require(market.created == true, "NO_MARKET");
    }

    function addMarket(
        State storage state,
        IMarket _market
    ) internal {
        MarketData storage market = state.markets[_market];
        require(market.created == false, "MARKET_EXIST");

        state.markets[_market].created = true;
        state.allMarkets.push(_market);
    }

    function setRiskParams(
        State storage state,
        RiskParams memory _riskParams
    ) internal{
        state.riskParams = _riskParams;
    }



    // Not optimal 
    function checkPosition(
        State storage state,
        IMarket _market,
        address account
    ) internal view returns (Position storage){
        return state.accounts[account][_market];
    }

    // Not optimal 
    function getPosition(
        State storage state,
        IMarket _market,
        address _account
    ) internal view returns (Position storage position){
        position = state.accounts[_account][_market];
        require(position.isActive == true, "NO_POSITION");
    }

    function setPosition(
        State storage state,
        IMarket _market,
        address account,
        bool isLong,
        int256 collateral,
        int256 notional,
        int256 initialPrice,
        bool merge
    ) internal returns (uint256 index) {
        
        /*TODO: remove this */
        if (state.existingAccounts[account] == false){
            state.allAccounts.push(account); 
            state.existingAccounts[account] = true;
        }
        Position storage _position = state.accounts[account][_market];

        /*
            Update PositionMeta for faster itterate over positions.
            - it MUST be trader position
            - it should be closed or liquidated. 

            We DON'T update PositionMeta if it's merge of the position
         */
        if (address(_market) != account && _position.isActive == false)
        {            
            /*First ever position for this account-_market setup index */
            if (_position.posIndex == 0){
                if (state.currentPositionIndex == 0){
                    state.currentPositionIndex = 1;  // posIndex started from 1, to be able to do check above
                }

                _position.posIndex = state.currentPositionIndex;

                state.allIndexes.push(_position.posIndex);
                state.indexToPositionMeta[_position.posIndex] = PositionMeta({
                    isActive: true,
                    _account: account,
                    _market: _market,
                    _posIndex: _position.posIndex
                });

                /*INCREMENT index only if unique position was created */
                state.currentPositionIndex += 1;                
            }else{
                /*We don't change index if it's old position, just need to activate it */
                state.indexToPositionMeta[_position.posIndex].isActive = true;
            }
        }

        index = _position.posIndex;

        _position.trader = account;
        _position.lastChangeBlock = block.number;
        _position.isActive = true;
        _position.isLiquidated = false;

        _position.isLong = isLong;
        _position.market = _market;
        _position.cummulativeIndex = _market.currentOracleIndex();
        _position.initialTimestamp = block.timestamp;
        _position.initialBlockNumber = block.number;
        _position.entryPrice = initialPrice;

        int256 avgPrice = initialPrice;
        int256 prevAverage = _position.prevAvgPrice;
        if (prevAverage != 0){
            int256 prevNotional = _position.notional; //save 1 read
            avgPrice =(prevAverage.muld(prevNotional) + initialPrice.muld(notional)).divd(notional + prevNotional);
        }
        
        
        _position.prevAvgPrice = avgPrice;

        
        if (merge == true){
            _position.collateral +=  collateral; 
            _position.notional += notional;
            _position.initialPrice = avgPrice;
        }else{
            _position.collateral = collateral;
            _position.notional = notional;
            _position.initialPrice = initialPrice;
            
            //It's AMM need to deal with that in other places        
            if (address(_market) == account){
                _position.isAmm = true;
                _position.lastNotional = notional;
                _position.lastInitialPrice = initialPrice;
            }
        }
    }

    function unsetPosition(
        State storage state,
        Position storage _position
    ) internal {
        if (_position.isActive == false){
            return;
        } 

        /*
            Position is fully closed or liquidated, NEED to update PositionMeta 
            BUT
            we never reset the posIndex
        */
        state.indexToPositionMeta[_position.posIndex].isActive = false;

        _position.lastChangeBlock = block.number;
        _position.isActive = false;

        _position.entryPrice = 0;
        _position.collateral = 0; 
        _position.notional = 0; 
        _position.initialPrice = 0;
        _position.cummulativeIndex = 0;
        _position.initialTimestamp = 0;
        _position.initialBlockNumber = 0;
        _position.unrealizedPnl = 0;
        _position.prevAvgPrice = 0;
    }

    function partlyClose(
        State storage state,
        Position storage _position,
        int256 collateral,
        int256 notional,
        int256 unrealizedPaid
    ) internal {
        _position.collateral -= collateral; 
        _position.notional -= notional;
        _position.unrealizedPnl -= unrealizedPaid;
        _position.lastChangeBlock = block.number;
    }

    /*
    *******************************************************
    *******************************************************
    *   Liquidation related functions
    *******************************************************
    *******************************************************
    */
    function getLiquidationRatio(
        State storage state
    ) internal view returns (int256){
        return state.riskParams.liquidationMarginRatio;
    }


    //Integrity check outside
    function addCollateral(
        State storage state,
        Position storage _position,
        int256 collateral
    ) internal {
        _position.collateral += collateral;
    }

    function removeCollateral(
        State storage state,
        Position storage _position,
        int256 collateral
    ) internal {
        _position.collateral -= collateral;
        
        require(_position.collateral >= 0, "COLLATERAL_TOO_BIG");
    }



    /*
    *******************************************************
    *   Funds view/transfer utils
    *******************************************************
    */
    function depositToDao(
        State storage state,
        address _from,
        int256 _amount
    ) internal {
        require(_amount > 0, "WRONG_AMOUNT");
        require(state.dao != address(0), "ZERO_DAO");
        
        if (_from == address(this)){
            SafeERC20.safeTransfer(state.tradingToken,
                                        state.dao, 
                                        uint(_amount));
        }else{
            SafeERC20.safeTransferFrom(state.tradingToken, 
                                        _from, 
                                        state.dao, 
                                        uint(_amount));
        }

    }

    function depositToMarket(
        State storage state,
        IMarket _market,
        address _from,
        int256 _amount
    ) internal {
        require(_amount > 0, "WRONG_AMOUNT");

        getMarket(state, _market);

        int256 balanceBefore = int256(state.tradingToken.balanceOf(address(_market)));

        if (_from == address(this)){
            SafeERC20.safeTransfer(state.tradingToken, 
                                        address(_market), 
                                        uint(_amount));
        }else{
            SafeERC20.safeTransferFrom(state.tradingToken, 
                                        _from, 
                                        address(_market), 
                                        uint(_amount));
        }

        int256 diff = int256(state.tradingToken.balanceOf(address(_market))) - balanceBefore;

        IStakeble(address(_market)).externalLiquidityChanged(diff);

        IStakeble(address(_market)).changeTradingPnl(_amount);
    }
    
    function withdrawFromMarket(
        State storage state,
        IMarket _market,
        address _to,
        int256 _amount
    ) internal {
        require(_amount > 0, "WRONG_AMOUNT");

        getMarket(state, _market);

        IStakeble(address(_market)).ensureFunds(_amount);

        IStakeble(address(_market)).approveStrips(state.tradingToken, _amount);

        int256 balanceBefore = int256(state.tradingToken.balanceOf(address(_market)));

        SafeERC20.safeTransferFrom(state.tradingToken, 
                                    address(_market), 
                                    _to, 
                                    uint(_amount));
        
        int256 diff = int256(state.tradingToken.balanceOf(address(_market))) - balanceBefore;

        IStakeble(address(_market)).externalLiquidityChanged(diff);

        IStakeble(address(_market)).changeTradingPnl(0 - _amount);
    }

    function depositToInsurance(
        State storage state,
        address _from,
        int256 _amount
    ) internal {
        require(address(state.insuranceFund) != address(0), "BROKEN_INSURANCE_ADDRESS");

        int256 balanceBefore = int256(state.tradingToken.balanceOf(address(state.insuranceFund)));

        if (_from == address(this)){
            SafeERC20.safeTransfer(state.tradingToken, 
                                        address(state.insuranceFund), 
                                        uint(_amount));
        }else{
            SafeERC20.safeTransferFrom(state.tradingToken, 
                                        _from, 
                                        address(state.insuranceFund), 
                                        uint(_amount));
        }

        int256 diff = int256(state.tradingToken.balanceOf(address(state.insuranceFund))) - balanceBefore;

        IStakeble(address(state.insuranceFund)).externalLiquidityChanged(diff);

        IStakeble(address(state.insuranceFund)).changeTradingPnl(_amount);

    }
    
    function withdrawFromInsurance(
        State storage state,
        address _to,
        int256 _amount
    ) internal {
        
        require(address(state.insuranceFund) != address(0), "BROKEN_INSURANCE_ADDRESS");

        IStakeble(address(state.insuranceFund)).ensureFunds(_amount);

        state.insuranceFund.borrow(_to, _amount);

        IStakeble(address(state.insuranceFund)).changeTradingPnl(0 - _amount);
    }


}

pragma solidity ^0.8.0;

import { SignedBaseMath } from "./SignedBaseMath.sol";
import { IMarket } from "../interface/IMarket.sol";
import { IStrips } from "../interface/IStrips.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IStripsLpToken } from "../interface/IStripsLpToken.sol";
import { IUniswapLpOracle } from "../interface/IUniswapLpOracle.sol";
import { IAssetOracle } from "../interface/IAssetOracle.sol";

import { IUniswapV2Pair } from "../external/interfaces/IUniswapV2Pair.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IRewarder } from "../interface/IRewarder.sol";

library StorageMarketLib {
    using SignedBaseMath for int256;

    /* Params that are set on contract creation */
    struct InitParams {
        IStrips stripsProxy;
        IAssetOracle assetOracle;
        IUniswapLpOracle pairOracle;

        int256 initialPrice;
        int256 burningCoef;

        IUniswapV2Pair stakingToken;
        IERC20 tradingToken;
        IERC20 strpToken;

        bool isRewardable;
        int256 notionalTolerance;

        int256 virtualLiquidity; // virtual liquidity that helps to decrease slippage
        int256 fundingPeriod;  // using for calculating funding_pnl (1 - default) should be 365 / k
    }

    /*Because of stack too deep error */
    struct Extended {
        address sushiRouter;
        uint createdAt;
        bool isSwapOn;
    }

    //Need to care about align here 
    struct State {
        address dao;
        
        InitParams params;
        IStripsLpToken slpToken;
        IRewarder rewarder;

        int256 totalLongs; //Real notional 
        int256 totalShorts; //Real notional
        
        int256 demand; //included proportion
        int256 supply; //included proportion
        
        int256 ratio;
        int256 _prevLiquidity;
        uint8 _currentLevel;
        
        Extended extend;
    }

    function pairPrice(
        State storage state
    ) internal view returns (int256){
        return state.params.pairOracle.getPrice();
    }

    //If required LP price conversions should be made here
    function calcStakingLiqudity(
        State storage state
    ) internal view returns (int256){
        return int256(state.params.stakingToken.balanceOf(address(this)));
    }

    function calcTradingLiqudity(
        State storage state
    ) internal view returns (int256){
        return int256(state.params.tradingToken.balanceOf(address(this)));
    }

    function netLiquidity(
        State storage state
    ) internal view returns (int256) {
        int256 stakingLiquidity = calcStakingLiqudity(state);
        
        if (stakingLiquidity != 0){
            stakingLiquidity = stakingLiquidity.muld(pairPrice(state)); //convert LP to USDC
        }

        int256 unrealizedPnl = state.params.stripsProxy.assetPnl(address(this));
        int256 exposure = state.totalLongs - state.totalShorts;
        if (exposure < 0){
            exposure *= -1;
        }

        return stakingLiquidity - exposure + unrealizedPnl + calcTradingLiqudity(state);
    }


    function getLiquidity(
        State storage state
    ) internal view returns (int256) {
        int256 stakingLiquidity = calcStakingLiqudity(state);
        
        if (stakingLiquidity != 0){
            stakingLiquidity = stakingLiquidity.muld(pairPrice(state)); //convert LP to USDC
        }

        return stakingLiquidity + calcTradingLiqudity(state);
    }

    //Should return the scalar
    function maxNotional(
        State storage state
    ) internal view returns (int256 maxLong, int256 maxShort) {
        int256 _liquidity = getLiquidity(state);

        if (_liquidity <= 0){
            return (0,0);
        }
        int256 unrealizedPnl = state.params.stripsProxy.assetPnl(address(this));
        int256 ammExposure = state.totalShorts - state.totalLongs;
        
        maxLong = (_liquidity + ammExposure + unrealizedPnl).muld(state.params.notionalTolerance);
        maxShort = (_liquidity - ammExposure + unrealizedPnl).muld(state.params.notionalTolerance);
    }


    function getPrices(
        State storage state
    ) internal view returns (int256 marketPrice, int256 oraclePrice){
        marketPrice = currentPrice(state);

        oraclePrice = IAssetOracle(state.params.assetOracle).getPrice();
    }

    function currentPrice(
        State storage state
    ) internal view returns (int256) {
        return state.params.initialPrice.muld(state.ratio);
    }


    function oraclePrice(
        State storage state
    ) internal view returns (int256) {
        return IAssetOracle(state.params.assetOracle).getPrice();
    }

    function approveStrips(
        State storage state,
        IERC20 _token,
        int256 _amount
    ) internal {
        require(_amount > 0, "BAD_AMOUNT");

        SafeERC20.safeApprove(_token, 
                                address(state.params.stripsProxy), 
                                uint(_amount));
    }
    
    function _updateRatio(
        State storage state,
        int256 _longAmount,
        int256 _shortAmount
    ) internal
    {
        /*
            supply = liquidity / (1 + ratio)
            demand = supply * ratio
            ratio = demand / supply

            Adding new liquidity (real or virtual) should not change the ratio.
        */
        int256 _liquidity = getLiquidity(state) + state.params.virtualLiquidity; 
        if (state._prevLiquidity == 0){
            /* initial setup */
            state.supply = _liquidity.divd(SignedBaseMath.oneDecimal() + state.ratio);
            state.demand = state.supply.muld(state.ratio);
            state._prevLiquidity = _liquidity;
        }

        int256 diff = _liquidity - state._prevLiquidity;

        state.demand += (_longAmount + diff.muld(state.ratio.divd(SignedBaseMath.oneDecimal() + state.ratio)));
        state.supply += (_shortAmount + diff.divd(SignedBaseMath.oneDecimal() + state.ratio));
        if (state.demand <= 0 || state.supply <= 0){
            require(0 == 1, "BROKEN_DEMAND_SUPPLY");
        }

        state.ratio = state.demand.divd(state.supply);
        state._prevLiquidity = _liquidity;
    }


    // we need this to be VIEW to use for priceChange calculations
    function _whatIfRatio(
        State storage state,
        int256 _longAmount,
        int256 _shortAmount
    ) internal view returns (int256){
        int256 ratio = state.ratio;
        int256 supply = state.supply;
        int256 demand = state.demand;
        int256 prevLiquidity = state._prevLiquidity;

        int256 _liquidity = getLiquidity(state) + state.params.virtualLiquidity;
        if (prevLiquidity == 0){
            supply = _liquidity.divd(SignedBaseMath.oneDecimal() + ratio);
            demand = supply.muld(ratio);
            prevLiquidity = _liquidity;
        }

        int256 diff = _liquidity - prevLiquidity;

        demand += (_longAmount + diff.muld(ratio.divd(SignedBaseMath.oneDecimal() + ratio)));
        supply += (_shortAmount + diff.divd(SignedBaseMath.oneDecimal() + ratio));
        if (demand <= 0 || supply <= 0){
            require(0 == 1, "BROKEN_DEMAND_SUPPLY");
        }

        return demand.divd(supply);

    }
}

pragma solidity ^0.8.0;

// We are using 0.8.0 with safemath inbuilt
// Need to implement mul and div operations only
// We have 18 for decimal part and  58 for integer part. 58+18 = 76 + 1 bit for sign
// so the maximum is 10**58.10**18 (should be enough :) )

library SignedBaseMath {
    uint8 constant DECIMALS = 18;
    int256 constant BASE = 10**18;
    int256 constant BASE_PERCENT = 10**16;

    function toDecimal(int256 x, uint8 decimals) internal pure returns (int256) {
        return x * int256(10**decimals);
    }

    function toDecimal(int256 x) internal pure returns (int256) {
        return x * BASE;
    }

    function oneDecimal() internal pure returns (int256) {
        return 1 * BASE;
    }

    function tenPercent() internal pure returns (int256) {
        return 10 * BASE_PERCENT;
    }

    function ninetyPercent() internal pure returns (int256) {
        return 90 * BASE_PERCENT;
    }

    function onpointOne() internal pure returns (int256) {
        return 110 * BASE_PERCENT;
    }


    function onePercent() internal pure returns (int256) {
        return 1 * BASE_PERCENT;
    }

    function muld(int256 x, int256 y) internal pure returns (int256) {
        return _muld(x, y, DECIMALS);
    }

    function divd(int256 x, int256 y) internal pure returns (int256) {
        if (y == 1){
            return x;
        }
        return _divd(x, y, DECIMALS);
    }

    function _muld(
        int256 x,
        int256 y,
        uint8 decimals
    ) internal pure returns (int256) {
        return (x * y) / unit(decimals);
    }

    function _divd(
        int256 x,
        int256 y,
        uint8 decimals
    ) internal pure returns (int256) {
        return (x * unit(decimals)) / y;
    }

    function unit(uint8 decimals) internal pure returns (int256) {
        return int256(10**uint256(decimals));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface ISuspendable {
    function changeLevel(uint8 _level) external;
    function withdraw(address _to) external;
    function withdrawStrp(address _to) external;

    function currentLevel() external view returns (uint8);
}

import { SOwnable } from "./SOwnable.sol";
import { ISuspendable } from "../interface/ISuspendable.sol";

abstract contract SSuspendable is 
    SOwnable,
    ISuspendable
{
    /*
        Implements suspend logic with different statuses
        0 - initial 
        1 - soft suspend
        2 - hard suspend

        open - 0  maximumLevel(0)
        close - 0 or 1  maximumLevel(1)
        withdraw - 2 minimumLevel(2)
     */
    modifier maximumLevel(uint8 _level) {
        require(currentLevel() <= _level, "WRONG_LEVEL");
         _;
    }

    modifier minimumLevel(uint8 _level) {
        require(currentLevel() >= _level, "WRONG_LEVEL");
         _;
    }


    function changeLevel(uint8 _level) external virtual override;
    function withdraw(address _to) external virtual override;

    function currentLevel() public view virtual override returns (uint8);

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

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

interface IStripsEvents {
    event LogCheckData(
        address indexed account,
        address indexed market,
        CheckParams params
    );

    event LogCheckInsuranceData(
        address indexed insurance,
        CheckInsuranceParams params
    );

    struct CheckInsuranceParams{
        int256 lpLiquidity;
        int256 usdcLiquidity;
        uint256 sipTotalSupply;
    }

    // ============ Structs ============

    struct CheckParams{
        /*Integrity Checks */        
        int256 marketPrice;
        int256 oraclePrice;
        int256 tradersTotalPnl;
        int256 uniLpPrice;
        
        /*Market params */
        bool ammIsLong;
        int256 ammTradingPnl;
        int256 ammFundingPnl;
        int256 ammTotalPnl;
        int256 ammNotional;
        int256 ammInitialPrice;
        int256 ammEntryPrice;
        int256 ammTradingLiquidity;
        int256 ammStakingLiquidity;
        int256 ammTotalLiquidity;

        /*Trading params */
        bool isLong;
        int256 tradingPnl;
        int256 fundingPnl;
        int256 totalPnl;
        int256 marginRatio;
        int256 collateral;
        int256 notional;
        int256 initialPrice;
        int256 entryPrice;

        /*Staking params */
        int256 slpTradingPnl;
        int256 slpStakingPnl;
        int256 slpTradingCummulativePnl;
        int256 slpStakingCummulativePnl;
        int256 slpTradingPnlGrowth;
        int256 slpStakingPnlGrowth;
        int256 slpTotalSupply;

        int256 stakerInitialStakingPnl;
        int256 stakerInitialTradingPnl;
        uint256 stakerInitialBlockNum;
        int256 stakerUnrealizedStakingProfit;
        int256 stakerUnrealizedTradingProfit;

        /*Rewards params */
        int256 tradingRewardsTotal; 
        int256 stakingRewardsTotal;
    }
}

library StripsEvents {
    event LogCheckData(
        address indexed account,
        address indexed market,
        IStripsEvents.CheckParams params
    );

    event LogCheckInsuranceData(
        address indexed insurance,
        IStripsEvents.CheckInsuranceParams params
    );


    function logCheckData(address _account,
                            address _market, 
                            IStripsEvents.CheckParams memory _params) internal {
        
        emit LogCheckData(_account,
                        _market,
                        _params);
    }

    function logCheckInsuranceData(address insurance,
                                    IStripsEvents.CheckInsuranceParams memory _params) internal {
        
        emit LogCheckInsuranceData(insurance,
                                    _params);
    }

}

pragma solidity >=0.8.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

interface IUniswapLpOracle is KeeperCompatibleInterface {
    function getPrice() external view returns (int256);
    function strpPrice() external view returns (int256);
    function bothPrices() external view returns (int256 lpPrice, int256 strpPrice);
}

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

interface IAssetOracle is KeeperCompatibleInterface {
    function getPrice() external view returns (int256);
    function calcOracleAverage(uint256 fromIndex) external view returns (int256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {

  /**
   * @notice checks if the contract requires work to be done.
   * @param checkData data passed to the contract when checking for upkeep.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with,
   * if upkeep is needed.
   */
  function checkUpkeep(
    bytes calldata checkData
  )
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData
    );

  /**
   * @notice Performs work on the contract. Executed by the keepers, via the registry.
   * @param performData is the data which was passed back from the checkData
   * simulation.
   */
  function performUpkeep(
    bytes calldata performData
  ) external;
}

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IStripsLpToken } from "./IStripsLpToken.sol";
import { IStakebleEvents } from "../lib/events/Stakeble.sol";

interface IStakeble is IStakebleEvents {
    event BalanceChanged(
        uint256 indexed timestamp,
        address indexed asset,
        address indexed initiator,
        int256 diff,
        int256 currentBalance,
        int256 reason
    );

    event TokenAdded(
        address indexed asset,
        address indexed token
    );
    
    function changeSlp(IStripsLpToken _slpToken) external;

    function netLiquidity() external view virtual returns (int256);

    function totalStaked() external view returns (int256);
    function isInsurance() external view returns (bool);
    function liveTime() external view returns (uint);

    function getSlpToken() external view returns (address);
    function getStakingToken() external view returns (address);
    function getTradingToken() external view returns (address);
    function getStrips() external view returns (address);

    function ensureFunds(int256 amount) external;
    function stake(int256 amount) external;
    function unstake(int256 amount) external;

    function approveStrips(IERC20 _token, int256 _amount) external;
    function externalLiquidityChanged(int256 diff) external;

    function changeTradingPnl(int256 amount) external virtual;
    function changeStakingPnl(int256 amount) external virtual;

    function isRewardable() external view returns (bool);

    function changeSushiRouter(address _router) external;
    function getSushiRouter() external view returns (address);

    function getStrp() external view returns (address);
    
    function getPartedLiquidity() external view returns (int256 usdcLiquidity, int256 lpLiquidity);
    function getTvl() external view returns (int256);

    function isSwapOn() external view returns (bool);
    function changeSwapMode(bool _mode) external;

}

import { IStripsLpToken } from "../../interface/IStripsLpToken.sol";
import { IStakeble } from "../../interface/IStakeble.sol";
import { IMarket } from "../../interface/IMarket.sol";


interface IStakebleEvents {
    struct LogUnstakeParams {
        address asset;
        address staker;
        int256 slpAmount;
        int256 lpPaid; 
        int256 lpPnl; 
        int256 usdcPnl; 
        int256 lpFee;
        int256 marketPrice;
        int256 oraclePrice;
        int256 stakingLiquidity;
        int256 tradingLiquidity;
        int256 tvl;
    }

    struct LogStakeParams {
        address asset;
        address staker;
        uint256 lpAmount;
        int256 currentVritualLpGrowth;
        int256 currentVirtualUsdcGrowth;
        uint256 slpSupply;
        int256 lpPrice;
        int256 tradingLiquidity;
        int256 stakingLiquidity;
        int256 tvl;
        int256 marketPrice;
        int256 oraclePrice;
    }


    struct UnstakeParams{
        int256 currentVritualLpGrowth; // before he unstakes
        int256 currentVirtualUsdcGrowth; //before he unstakes
        uint256 slpSupply;
        int256 lpPrice;
        int256 stakingLiquidity;
        int256 tradingLiquidity;
        int256 tvl;
        int256 marketPrice;
        int256 oraclePrice;
    }


    event LogStake(
        uint256 indexed timestamp,
        address indexed asset,
        address indexed staker,
        uint256 lpAmount,
        int256 currentVritualLpGrowth, // before he stakes
        int256 currentVirtualUsdcGrowth, //before he stakes
        uint256 slpSupply,
        int256 lpPrice,
        int256 stakingLiquidity,
        int256 tradingLiquidity,
        int256 tvl,
        int256 marketPrice,
        int256 oraclePrice
    );

    event LogUnstake(
        uint256 indexed timestamp,
        address indexed asset,
        address indexed staker,
        int256 slpAmount,
        int256 lpPaid, // renamed   
        int256 lpPnl,  // renamed  (this is the lp that you earned or lost)
        int256 usdcPnl,  // renamed (this is the usdc that you earned or lost)
        int256 lpFee, // renamed
        IStakebleEvents.UnstakeParams params
    );

    event BurnAction(
        uint256 indexed timestamp,
        address indexed asset,
        int256 requiredAmount,
        int256 lpToBurnCalculated,
        int256 lp_diff,
        int256 usdc_diff,
        int256 lpPrice,
        int256 strpPrice
    );
}

library StakebleEvents {
    event LogStake(
        uint256 indexed timestamp,
        address indexed asset,
        address indexed staker,
        uint256 lpAmount,
        int256 currentVritualLpGrowth, // before he stakes
        int256 currentVirtualUsdcGrowth, //before he stakes
        uint256 slpSupply,
        int256 lpPrice,
        int256 stakingLiquidity,
        int256 tradingLiquidity,
        int256 tvl,
        int256 marketPrice,
        int256 oraclePrice
    );

    event LogUnstake(
        uint256 indexed timestamp,
        address indexed asset,
        address indexed staker,
        int256 slpAmount,
        int256 lpPaid, // renamed   
        int256 lpPnl,  // renamed  (this is the lp that you earned or lost)
        int256 usdcPnl,  // renamed (this is the usdc that you earned or lost)
        int256 lpFee, // renamed
        IStakebleEvents.UnstakeParams params
    );

    event BurnAction(
        uint256 indexed timestamp,
        address indexed asset,
        int256 requiredAmount,
        int256 lpToBurnCalculated,
        int256 lp_diff,
        int256 usdc_diff,
        int256 lpPrice,
        int256 strpPrice
    );

    function logStakeData(IStakebleEvents.LogStakeParams memory _params) internal {
        
        if (IStakeble(_params.asset).isInsurance() == false){
            (_params.marketPrice, _params.oraclePrice) = IMarket(_params.asset).getPrices();
        }             

        emit LogStake(
            block.timestamp,
            _params.asset,
            _params.staker,
            _params.lpAmount,
            _params.currentVritualLpGrowth, // before he stakes
            _params.currentVirtualUsdcGrowth, //before he stakes
            _params.slpSupply,
            _params.lpPrice,
            _params.stakingLiquidity,
            _params.tradingLiquidity,
            _params.tvl,
            _params.marketPrice,
            _params.oraclePrice
            );
    }


    function logUnstakeData(IStakebleEvents.LogUnstakeParams memory _params,
                            IStripsLpToken.ProfitParams memory _profit) internal {


        if (IStakeble(_params.asset).isInsurance() == false){
            (_params.marketPrice, _params.oraclePrice) = IMarket(_params.asset).getPrices();
        }             
            
            emit LogUnstake(
                block.timestamp,
                _params.asset,
                _params.staker,
                _params.slpAmount,

                _profit.unstakeAmountLP, // renamed   
                (_profit.stakingProfit - _profit.lpProfit),  // renamed  (this is the lp that you earned or lost)
                (_profit.unstakeAmountERC20 + _profit.usdcLoss),  // renamed (this is the usdc that you earned or lost)
                _profit.stakingFee, // renamed
                IStakebleEvents.UnstakeParams({
                    currentVritualLpGrowth:_profit.currentVritualLpGrowth,
                    currentVirtualUsdcGrowth:_profit.currentVirtualUsdcGrowth,
                    slpSupply:_profit.slpSupply,
                    lpPrice:_profit.lpPrice,
                    stakingLiquidity:_params.stakingLiquidity,
                    tradingLiquidity:_params.tradingLiquidity,
                    tvl: _params.tvl,
                    marketPrice: _params.marketPrice,
                    oraclePrice: _params.oraclePrice
                }));


    }

    function logBurnData(address _asset,
                            int256 _requiredAmount,
                            int256 _lpToBurnCalculated,
                            int256 _lp_diff,
                            int256 _usdc_diff,
                            int256 _lpPrice,
                            int256 _strpPrice) internal {
        emit BurnAction(
            block.timestamp,
            _asset,
            _requiredAmount,
            _lpToBurnCalculated,
            _lp_diff,
            _usdc_diff,
            _lpPrice,
            _strpPrice
        );
    }
}

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IStripsLpToken } from "./IStripsLpToken.sol";
import { IStakebleEvents } from "../lib/events/Stakeble.sol";

interface IRewarder {
    event TradingRewardClaimed(
        uint256 indexed timestamp,
        address indexed asset,
        address indexed user, 
        int256 amount
    );


    event StakingRewardClaimed(
        uint256 indexed timestamp,
        address indexed asset,
        address indexed user, 
        int256 amount
    );

    struct InitParams {
        uint256 periodLength;
        uint256 washTime;

        IERC20 slpToken;
        IERC20 strpToken;

        address stripsProxy;
        address dao;

        int256 rewardTotalPerSecTrader;
        int256 rewardTotalPerSecStaker;
    }

    function claimStakingReward(address _staker) external;
    function claimTradingReward(address _trader) external;

    function totalStakerReward(address _staker) external view returns (int256 reward);
    function totalTradeReward(address _trader) external view returns (int256 reward);

    function rewardStaker(address _staker) external;
    function rewardTrader(address _trader, int256 _notional) external;

    function currentTradingReward() external view returns(int256);
    function currentStakingReward() external view returns (int256);
}

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IStripsLpToken } from "./IStripsLpToken.sol";
import { IStakebleEvents } from "../lib/events/Stakeble.sol";
import { IRewarder } from "./IRewarder.sol";

interface IRewardable {
    function suspendRewards(bool _status) external;
    function changeRewarder(IRewarder _rewarder) external;
    function getRewarder() external view returns (address);
}

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IMarket } from "../interface/IMarket.sol";
import { IStripsLpToken } from "../interface/IStripsLpToken.sol";
import { IUniswapV2Pair } from "../external/interfaces/IUniswapV2Pair.sol";

import { MState } from "./State.sol";
import { StorageMarketLib } from "../lib/StorageMarket.sol";
import { SignedBaseMath } from "../lib/SignedBaseMath.sol";
import { StakingImpl } from "../impl/StakingImpl.sol";
import { AssetOracle } from "../oracle/AssetOracle.sol";

abstract contract MGetters is
    IMarket,
    MState
{
    using StorageMarketLib for StorageMarketLib.State;
    using SignedBaseMath for int256;

    function currentPrice() external view override returns (int256) {
        return m_state.currentPrice();
    }

    function oraclePrice() external view override returns (int256) {
        return m_state.oraclePrice();
    }
    
    /**
     * @notice total longs positions notional for this market. 
     * @return in USDC
     */
    function getLongs() external view override returns (int256) 
    {
        return m_state.totalLongs;
    }

    /**
     * @notice total shorts positions notional for this market. 
     * @return in USDC
     */
    function getShorts() external view override returns (int256) {
        return m_state.totalShorts;
    }

    function maxNotional() external view override returns (int256 maxLong, int256 maxShort) {
        return m_state.maxNotional();
    }


    function getPrices() external view override returns (int256, int256) {
        return m_state.getPrices();
    }

    function getLiquidity() external view override returns (int256) {
        return m_state.getLiquidity();
    }

    function getAssetOracle() external view override returns (address)
    {
        return address(m_state.params.assetOracle);
    }

    function getPairOracle() external view override returns (address)
    {
        return address(m_state.params.pairOracle);
    }

    function currentOracleIndex() external view override returns (uint256) 
    {
        return AssetOracle(address(m_state.params.assetOracle)).lastCumulativeIndex();
    }

    function getFundingPeriod() external view override returns (int256) {
        return m_state.params.fundingPeriod;
    }



}

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IStripsLpToken } from "../interface/IStripsLpToken.sol";
import { IStrips } from "../interface/IStrips.sol";
import { IMarket } from "../interface/IMarket.sol";
import { IStripsLpToken } from "../interface/IStripsLpToken.sol";
import { IStakeble } from "../interface/IStakeble.sol";
import { SignedBaseMath } from "../lib/SignedBaseMath.sol";
import { SLPToken } from "../token/SLPToken.sol";
import { StakebleEvents, IStakebleEvents } from "../lib/events/Stakeble.sol";
import { IRewarder } from "../interface/IRewarder.sol";
import { IRewardable } from "../interface/IRewardable.sol";

import { IUniswapV2Router02 } from "../external/interfaces/IUniswapV2Router02.sol";
import { IUniswapV2Pair } from "../external/interfaces/IUniswapV2Pair.sol";
import { IUniswapV2Factory } from "../external/interfaces/IUniswapV2Factory.sol";

library StakingImpl {
    using SignedBaseMath for int256; 

    struct BurnParams{
        IUniswapV2Router02 router;
        IUniswapV2Factory factory;
        IUniswapV2Pair pair;

        address strp;
        address usdc;

        int256 strpReserve;
        int256 usdcReserve;

        int256 liquidity;

        int256 amountIn;  //strp to swap
        int256 amountOutMin; //minimum usdc to receive on swap

        int256 lpPrice;
        int256 strpPrice;

        address _asset;
    }

    modifier onlyStaker (address staker) {
        require(msg.sender == staker, "STAKER_ONLY");
         _;
    }

    function _stake(
        IStripsLpToken slpToken,
        address staker,
        int256 amount
    ) external onlyStaker(staker) {
        require(amount > 0, "WRONG_AMOUNT");
        slpToken.accumulatePnl();

        //The staker already has stake, need to store current Profit
        if (IERC20(address(slpToken)).balanceOf(staker) > 0){
            slpToken.saveProfit(staker);
        }

        SafeERC20.safeTransferFrom(IERC20(slpToken.getParams().stakingToken), 
                                    staker, 
                                    address(this), 
                                    uint(amount));

        slpToken.mint(staker, uint(amount));

        if (IStakeble(address(this)).isRewardable()){
            address rewarder = IRewardable(address(this)).getRewarder();
            IRewarder(rewarder).rewardStaker(staker);
        }

        IStakebleEvents.LogStakeParams memory _stakeParams;
        /*
            LOGGING HERE
        */
        (_stakeParams.tradingLiquidity, _stakeParams.stakingLiquidity) = IStakeble(SLPToken(address(slpToken)).owner()).getPartedLiquidity();
        _stakeParams.lpPrice = slpToken.getPairPrice();
        _stakeParams.tvl = IStakeble(SLPToken(address(slpToken)).owner()).getTvl();
        _stakeParams.marketPrice = 0;
        _stakeParams.marketPrice = 0;

        _stakeParams.asset = SLPToken(address(slpToken)).owner();
        _stakeParams.staker = staker;
        _stakeParams.lpAmount = uint(amount);
        _stakeParams.currentVritualLpGrowth = SLPToken(address(slpToken)).cumStakingPNL();
        _stakeParams.currentVirtualUsdcGrowth = SLPToken(address(slpToken)).cumTradingPNL();
        _stakeParams.slpSupply = SLPToken(address(slpToken)).totalSupply();

        StakebleEvents.logStakeData(_stakeParams);
    }

  
    function _unstake(
        IStripsLpToken slpToken,
        address staker,
        int256 amount
    ) external onlyStaker(staker) {
        slpToken.canUnstake(staker, uint(amount));

        slpToken.accumulatePnl();

        /*
            stakingProfit = profit.unstakeAmountLP;
            tradingProfit = profit.unstakeAmountERC20;
        */
        IStripsLpToken.ProfitParams memory profit = slpToken.claimProfit(staker, uint(amount));
        int256 stakingProfit = profit.unstakeAmountLP;
        int256 tradingProfit = profit.unstakeAmountERC20;

        require(stakingProfit > 0 && tradingProfit >= 0, "NO_PROFIT");


        if (stakingProfit > 0){
            SafeERC20.safeTransfer(IERC20(slpToken.getParams().stakingToken), 
                                    staker, 
                                    uint(stakingProfit));
        }

        if (tradingProfit > 0){
            int256 tradingBalance = int256(IERC20(slpToken.getParams().tradingToken).balanceOf(address(this)));
            if (tradingProfit >= tradingBalance){
                _burnPair(slpToken, tradingProfit);
            }
            
            SafeERC20.safeTransfer(IERC20(slpToken.getParams().tradingToken), 
                                    staker, 
                                    uint(tradingProfit));
        }

        if (IStakeble(address(this)).isRewardable()){
            address rewarder = IRewardable(address(this)).getRewarder();
            IRewarder(rewarder).rewardStaker(staker);
        }

        /*
            Logging after changing balances
        */
        IStakebleEvents.LogUnstakeParams memory _unstakeParams;

        (_unstakeParams.tradingLiquidity, _unstakeParams.stakingLiquidity) = IStakeble(SLPToken(address(slpToken)).owner()).getPartedLiquidity();
        _unstakeParams.tvl = IStakeble(SLPToken(address(slpToken)).owner()).getTvl();
        _unstakeParams.marketPrice = 0;
        _unstakeParams.oraclePrice = 0;
        
        _unstakeParams.asset = SLPToken(address(slpToken)).owner();
        _unstakeParams.staker = staker;
        _unstakeParams.slpAmount = amount;


        StakebleEvents.logUnstakeData(_unstakeParams, profit);
    }

    function _burnPair(
        IStripsLpToken slpToken,
        int256 requiredAmount
    ) public {
        //ONLY if we are in Owner context (address(this) == owner), otherwise revert
        slpToken.checkOwnership();

        require(requiredAmount > 0, "WRONG_AMOUNT");
    /*
            Steps for burning LP:
            1. Find reserves
            2. Calc liquidity amount to burn
            3. Burn
            4. Swap STRP to USDC with slippage
            5. Reflect lp and usdc growth
         */

        BurnParams memory params;

        params._asset = SLPToken(address(slpToken)).owner();

        params.strp = IStakeble(address(this)).getStrp();
        params.usdc = slpToken.getParams().tradingToken;
        
        params.router = IUniswapV2Router02(IStakeble(address(this)).getSushiRouter());
        params.factory = IUniswapV2Factory(params.router.factory());
        params.pair = IUniswapV2Pair(params.factory.getPair(
            params.strp,
            params.usdc));
        require(address(params.pair) != address(0), "ZERO_PAIR_CONTRACT");

        (uint112 reserve0,
            uint112 reserve1,) = params.pair.getReserves();

        if (address(params.strp) == params.pair.token0()){
            params.strpReserve = int256(uint(reserve0));
            params.usdcReserve = int256(uint(reserve1));
        }else{
            params.strpReserve = int256(uint(reserve1));
            params.usdcReserve = int256(uint(reserve0));
        }

        /*How much liquidity we need to burn? */
        int256 supply = int256(params.pair.totalSupply());

        /*Just 10% more for don't care about the fee */
        params.liquidity = (requiredAmount.muld(supply).divd(params.usdcReserve)).muld(SignedBaseMath.onpointOne());

        /*
            Need to calc balance before burn - as we need to change PNL to differ
         */
        int256 lp_balance = int256(params.pair.balanceOf(address(this)));
        int256 usdc_balance = int256(IERC20(params.usdc).balanceOf(address(this)));

        /*BURN:
            address tokenA,
            address tokenB,
            uint liquidity,
            uint amountAMin,
            uint amountBMin,
            address to,
            uint deadline
         */
        params.pair.approve(address(params.router), uint(params.liquidity));
        params.router.removeLiquidity(
            address(params.usdc), 
            address(params.strp), 
            uint(params.liquidity), 
            uint(requiredAmount),
            0, 
            address(this), 
            block.timestamp + 200);

        /*
            Change reserves
         */
        (reserve0,
            reserve1,) = params.pair.getReserves();

        if (address(params.strp) == params.pair.token0()){
            params.strpReserve = int256(uint(reserve0));
            params.usdcReserve = int256(uint(reserve1));
        }else{
            params.strpReserve = int256(uint(reserve1));
            params.usdcReserve = int256(uint(reserve0));
        }


        if (IStakeble(params._asset).isSwapOn()){
            /*NOW SWAP */
            params.amountIn = int256(IERC20(params.strp).balanceOf(address(this)));
            require(params.amountIn > 0, "BURN_FAILED_ZERO_STRP");

            IERC20(params.strp).approve(address(params.router), uint(params.amountIn));
            params.amountOutMin = int256(params.router.quote(uint(params.amountIn), uint(params.strpReserve), uint(params.usdcReserve)));

            /*10% slippage */
            params.amountOutMin = params.amountOutMin.muld(SignedBaseMath.ninetyPercent());
            address[] memory path = new address[](2);
            path[0] = params.strp;
            path[1] = params.usdc;

            params.router.swapExactTokensForTokens(
                uint(params.amountIn),
                uint(params.amountOutMin),
                path,
                address(this),
                block.timestamp + 200
            );
        }
        
        /*Calc change in balance */
        int256 lp_diff = int256(params.pair.balanceOf(address(this))) - lp_balance;
        require (lp_diff < 0, "LP_BURN_ERROR");

        int256 usdc_diff = int256(IERC20(params.usdc).balanceOf(address(this))) - usdc_balance;
        require (usdc_diff > 0, "USDC_BURN_ERROR");

        /*Reflect change*/
        slpToken.changeStakingPnl(lp_diff);
        slpToken.changeTradingPnl(usdc_diff);

        (params.lpPrice, params.strpPrice) = slpToken.bothPrices();

        StakebleEvents.logBurnData(SLPToken(address(slpToken)).owner(), 
                                                requiredAmount,
                                                params.liquidity,
                                                lp_diff,
                                                usdc_diff,
                                                params.lpPrice,
                                                params.strpPrice);
    }
}

// SPDX-License-Identifier: MIT

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
        _checkRole(role, _msgSender());
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
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
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
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
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

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

pragma solidity ^0.8.0;

import { StorageMarketLib } from "../lib/StorageMarket.sol";

abstract contract MState
{
    StorageMarketLib.State public m_state;
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

import { IAssetOracle } from "../interface/IAssetOracle.sol";
import { IStrips } from "../interface/IStrips.sol";
import { IMarket } from "../interface/IMarket.sol";
import { SignedBaseMath } from "../lib/SignedBaseMath.sol";
import { SOwnable } from "../utils/SOwnable.sol";


contract AssetOracle is 
    SOwnable,
    IAssetOracle
{
    using SignedBaseMath for int256;

    event AssetOracleUpdated(
        uint256 indexed timestamp,
        address indexed oracleAddress,
        address indexed marketAddress,
        address keeper,
        int256 oraclePrice,
        int256 marketPrice 
    );

    address public keeper;
    address public market;

    uint public lastTimeStamp;

    int256 public lastApr;

    uint256 public lastCumulativeIndex;
    uint256 public lastBlockNumUpdate;
    int256[] public cumulativeOracleAvg;

    int256 constant ANN_PERIOD_SEC = 31536000;
    
    modifier activeOnly() {
        require(lastTimeStamp != 0, "NOT_ACTIVE");
         _;
    }

    constructor(
        address _stripsProxy,
        address _keeper
    ){
        require(_keeper != address(0), "BROKEN_KEEPER");
        require(Address.isContract(_stripsProxy), "STRIPS_NOT_A_CONTRACT");

        strips = _stripsProxy;
        owner = msg.sender;
        listed[_keeper] = true;
    }

    function setMarket(address _market) external ownerOrAdmin {
        market = _market;
    }

    function getPrice() external view override activeOnly returns (int256){
        return lastApr;
    }

    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory) {
        if (block.timestamp > lastTimeStamp){
            upkeepNeeded = true;
        }else{
            upkeepNeeded = false;
        }
    }

    function accumulateOracle() internal {
        int256 aprPerSec = lastApr / ANN_PERIOD_SEC;

        if (lastCumulativeIndex != 0){
            aprPerSec += cumulativeOracleAvg[lastCumulativeIndex-1];
        }

        cumulativeOracleAvg.push(aprPerSec);
        lastCumulativeIndex += 1;
    }

    function performUpkeep(bytes calldata _data) public virtual override ownerOrListed {
        require(block.timestamp > lastTimeStamp, "NO_NEED_UPDATE");
        lastTimeStamp = block.timestamp;

        lastApr = abi.decode(_data, (int256));

        //TODO: calc and set APY here
        accumulateOracle();

        int256 marketPrice = 0;
        if (market != address(0)){
            marketPrice = IMarket(market).currentPrice();
        }
        
        emit AssetOracleUpdated(
            block.timestamp,
            address(this),
            market,
            msg.sender,
            lastApr,
            marketPrice
        );
    }

    function calcOracleAverage(uint256 fromIndex) external view virtual override activeOnly returns (int256) {        
        require(lastCumulativeIndex > 0, "ORACLE_NEVER_UPDATED");

        int256 avg = cumulativeOracleAvg[lastCumulativeIndex-1];

        int256 len = int256(lastCumulativeIndex - fromIndex);
        if (len == 0){
            if (fromIndex > 1){
                return avg - cumulativeOracleAvg[fromIndex-2];
            }else{
                return avg;
            }
        }

        if (fromIndex != 0){
            avg -= cumulativeOracleAvg[fromIndex-1];
        }

        return avg / len;
    }
}

pragma solidity >=0.8.0;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.8.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
    uint256[45] private __gap;
}

abstract contract SOwnable
{
    address public owner;
    address public admin; // used for managing admin functions like add remove to list
    address public strips;
    address public proposed;

    mapping (address => bool) public listed;

    modifier onlyProposed(){
        require(msg.sender == proposed, "NOT_PROPOSED");
        _;
    }


    modifier onlyOwner(){
        require(msg.sender == owner, "NOT_OWNER");
        _;
    }

    modifier ownerOrAdmin(){
        require(msg.sender == owner || msg.sender == admin, "NOT_OWNER_NOR_ADMIN");
        _;
    }

    modifier ownerOrStrips(){
        require(msg.sender == owner || msg.sender == strips, "NOT_OWNER_NOR_STRIPS");
        _;
    }

    modifier onlyStrips(){
        require(msg.sender == strips, "NOT_STRIPS");
        _;
    }

    modifier ownerOrListed(){
        require(msg.sender == owner || listed[msg.sender] == true, "NOT_OWNER_NOR_LISTED");
        _;
    }

    function listAdd(address _new) public ownerOrAdmin {
        listed[_new] = true;
    }

    function listRemove(address _exist) public ownerOrAdmin {
        /*No check for existing */
        listed[_exist] = false;
    }

    function proposeOwner(address _new) public onlyOwner {
        require(_new != address(0), "ZERO_OWNER");
        require(_new != msg.sender, "ALREADY_AN_OWNER");

        proposed = _new;
    }

    function changeOwner() public onlyProposed {
        owner = proposed;

        /*Reset proposed */
        proposed = address(0);
    }

    function changeAdmin(address _new) public onlyOwner {
        admin = _new;
    }

    function changeStrips(address _new) public onlyOwner {
        strips = _new;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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