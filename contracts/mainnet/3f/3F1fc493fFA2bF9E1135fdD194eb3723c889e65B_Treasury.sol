// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../utils/EnumerableValues.sol";
import "../core/interfaces/IElpManager.sol";
import "../core/interfaces/IRouter.sol";
import "../tokens/interfaces/IWETH.sol";
import "../core/interfaces/IVault.sol";
import "./interfaces/IRewardRouter.sol";
import "./interfaces/IRewardTracker.sol";

interface ISwapRouter {
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

    function exactInputSingle(ExactInputSingleParams memory params) external returns (uint256 amountOut);
    // function exactInput(ExactInputParams memory params) external returns (uint256 amountOut);
    // https://docs.uniswap.org/contracts/v3/reference/periphery/interfaces/ISwapRouter
}



interface ICamelot {
    struct inputToken {
        address tokenAddress;
        uint256 amountIn;
        address receiver;
        bytes permit;
    }
    struct outputToken {
        address tokenAddress;
        uint256 relativeValue;
        address receiver;
    }

    // For : camelot
    function addLiquidity(address tokenA, address tokenB,uint256 amountADesired,uint256 amountBDesired,uint256 amountAMin,uint256 amountBMin,address to,uint256 deadline) external ;
    function removeLiquidity(address tokenA,address tokenB,uint liquidity,uint amountAMin,uint amountBMin,address to,uint deadline
        ) external returns (uint , uint, uint);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
        ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

        
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path,address to, address referrer,uint deadline) external payable;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint amountOutMin, address[] calldata path, address to, address referrer, uint deadline) external payable;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, address referrer, uint deadline) external;
}


interface ILPYield {
    function stake(address _token, uint256 _amount) external;
    function unstake(uint256 _amount) external;
    function claim() external;
}



contract Treasury is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableValues for EnumerableSet.AddressSet;
    using Address for address payable;


    mapping(string => address) public addDef;
    mapping(address => address) public elpToElpManager;
    mapping(address => address) public elpToElpTracker;

    //distribute setting
    EnumerableSet.AddressSet supportedToken;
    uint256[] public weights;
    uint256 public weight_sum;
    bool public openForPublic = true;
    mapping (address => bool) public isHandler;

    receive() external payable {
        // require(msg.sender == weth, "invalid sender");
    }
    
    modifier onlyHandler() {
        require(isHandler[msg.sender] || msg.sender == owner() || openForPublic, "forbidden");
        _;
    }
    
    function setHandler(address _handler, bool _isActive) external onlyOwner {
        isHandler[_handler] = _isActive;
    }
    function approve(address _token, address _spender, uint256 _amount) external onlyOwner {
        IERC20(_token).approve(_spender, _amount);
    }

    function setOpenstate(bool _state) external onlyOwner {
        openForPublic = _state;
    }
    function setWeights(uint256[] memory _weights) external onlyOwner {
        weight_sum = 0;
        weights = _weights;
        for(uint i = 0; i < _weights.length; i++){
            weight_sum = weight_sum.add(_weights[i]);
        }
    }
    function setRelContract(address[] memory _elp_n, address[] memory _elp_manager, address[] memory _elp_tracker) external onlyOwner{
        for(uint i = 0; i < _elp_n.length; i++){
            if (!supportedToken.contains(_elp_n[i]))
                supportedToken.add(_elp_n[i]);    
            elpToElpManager[_elp_n[i]] = _elp_manager[i];
            elpToElpTracker[_elp_n[i]] = _elp_tracker[i];
        }
    }


    function setToken(address[] memory _tokens, bool _state) external onlyOwner{
        if (_state){
            for(uint i = 0; i < _tokens.length; i++){
                if (!supportedToken.contains(_tokens[i]))
                    supportedToken.add(_tokens[i]);
            }
        }
        else{
            for(uint i = 0; i < _tokens.length; i++){
                if (supportedToken.contains(_tokens[i]))
                    supportedToken.remove(_tokens[i]);
            }
        }
    }

    function setAddress(string[] memory _name_list, address[] memory _contract_list) external onlyOwner{
        for(uint i = 0; i < _contract_list.length; i++){
            addDef[_name_list[i]] = _contract_list[i];
        }
    }

    function withdrawToken(address _token, uint256 _amount, address _dest) external onlyOwner {
        IERC20(_token).safeTransfer(_dest, _amount);
    }

    function depositNative(uint256 _amount) external payable onlyOwner {
        uint256 _curBalance = address(this).balance;
        IWETH(addDef["nativeToken"]).deposit{value: _amount > _curBalance ? _curBalance : _amount}();
    }

    function _internalSwap(address _token_src, address _token_dst, uint256 _amount_in, uint256 _amount_out_min) internal returns (uint256) {
        require(_token_src != _token_dst, "src token equals to dst token");
        require(isSupportedToken(_token_src), "not supported src token");
        require(isSupportedToken(_token_dst), "not supported dst token");
        require(addDef["camelotSwap"] != address(0), "camelotSwap contract not set");
        
        uint256 _deadline = block.timestamp.add(1);
        uint256 _src_pre_balance = _token_src == address(0) ? address(this).balance : IERC20(_token_src).balanceOf(address(this));
        uint256 _dst_pre_balance = _token_dst == address(0) ? address(this).balance : IERC20(_token_dst).balanceOf(address(this));
        address referrer = address(0);
        address[] memory _path = new address[](2);
        if (_token_src == address(0)){ //swap with native token
            _path[0] = addDef["nativeToken"];
            _path[1] = _token_dst;
            ICamelot(addDef["camelotSwap"]).swapExactETHForTokensSupportingFeeOnTransferTokens{value:_amount_in}(_amount_out_min,_path, address(this), referrer, _deadline);       
            // swapExactETHForTokensSupportingFeeOnTransferTokens(uint amountOutMin, address[] calldata path, address to, address referrer, uint deadline) external;
        }
        else if (_token_dst == address(0)){ //swap with native token
            _path[0] = _token_src;
            _path[1] = addDef["nativeToken"];
            IERC20(_token_src).approve(addDef["camelotSwap"], _amount_in);
            ICamelot(addDef["camelotSwap"]).swapExactTokensForETHSupportingFeeOnTransferTokens(_amount_in, _amount_out_min, _path, address(this), referrer, _deadline);       
            // swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, address referrer,uint deadline) external;
        }
        else{
            _path[0] = _token_src;
            _path[1] = _token_dst;
            IERC20(_token_src).approve(addDef["camelotSwap"], _amount_in);
            ICamelot(addDef["camelotSwap"]).swapExactTokensForTokensSupportingFeeOnTransferTokens(_amount_in, _amount_out_min, _path, address(this), referrer, _deadline);       
            // swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, address referrer, uint deadline) external;
        }
        uint256 _src_cur_balance = _token_src == address(0) ? address(this).balance : IERC20(_token_src).balanceOf(address(this));
        uint256 _dst_cur_balance = _token_dst == address(0) ? address(this).balance : IERC20(_token_dst).balanceOf(address(this));
        require(_src_pre_balance.sub(_src_cur_balance) <= _amount_in, "src token decrease not match");
        require(_dst_cur_balance.sub(_dst_pre_balance) >= _amount_out_min, "dst token increase not match");
        return _dst_cur_balance.sub(_dst_pre_balance);
    }


    function treasureSwap(address _src, address _dst, uint256 _amount_in, uint256 _amount_out_min) external onlyHandler returns (uint256) {
        return _internalSwap(_src, _dst, _amount_in, _amount_out_min);
    }


    // ------ Funcs. processing ELP
    function buyELP(address _token, address _elp_n, uint256 _amount) external onlyHandler returns (uint256) {
        require(isSupportedToken(_token), "not supported src token");
        if (_amount == 0)
            _amount = IERC20(_elp_n).balanceOf(address(this));
        return _buyELP(_token, _elp_n, _amount);
    }
    function _buyELP(address _token, address _elp_n, uint256 _amount) internal returns (uint256) {
        require(elpToElpManager[_elp_n]!= address(0), "ELP manager not set");
        uint256 elp_ret = 0;
        if (_token != address(0)){
            IERC20(_token).approve(elpToElpManager[_elp_n], _amount);
            require(IERC20(_token).balanceOf(address(this)) >= _amount, "insufficient token to buy elp");
            elp_ret = IElpManager(elpToElpManager[_elp_n]).addLiquidity(_token, _amount, 0, 0);
        }
        else{
            require(address(this).balance >= _amount, "insufficient native token ");
            elp_ret = IElpManager(elpToElpManager[_elp_n]).addLiquidityETH{value: _amount}();
        }
        return elp_ret;
    }

    function sellELP(address _token_out, address _elp_n, uint256 _amount_sell) external onlyHandler returns (uint256) {
        require(isSupportedToken(_token_out), "not supported out token");
        require(isSupportedToken(_elp_n), "not supported elp n");
        if (_amount_sell == 0){
            _amount_sell = IERC20(_elp_n).balanceOf(address(this));
        }
        return _sellELP(_token_out, _elp_n, _amount_sell);
    }

    function _sellELP(address _token_out, address _elp_n, uint256 _amount_sell) internal returns (uint256) {
        require(isSupportedToken(_token_out), "not supported src token");
        require(elpToElpManager[_elp_n]!= address(0), "ELP manager not set");
        IERC20(_elp_n).approve(elpToElpManager[_elp_n], _amount_sell);
        require(IERC20(_elp_n).balanceOf(address(this)) >= _amount_sell, "insufficient elp to sell");

        uint256 token_ret = 0;
        if (_token_out != address(0)){
            token_ret = IElpManager(elpToElpManager[_elp_n]).removeLiquidity(_token_out, _amount_sell, 0, address(this));
        }
        else{
            token_ret = IElpManager(elpToElpManager[_elp_n]).removeLiquidityETH(_amount_sell);
        }
        return token_ret;
    }

    function stakeELP(address _elp_n, uint256 _amount)  external onlyHandler returns (uint256) {
        require(isSupportedToken(_elp_n), "not supported elp n");
        if (_amount == 0){
            _amount = IERC20(_elp_n).balanceOf(address(this));
        }       
        return _stakeELP(_elp_n, _amount);
    }
    function _stakeELP(address _elp_n, uint256 _amount) internal returns (uint256) {
        require(IERC20(_elp_n).balanceOf(address(this)) >= _amount, "insufficient elp");
        require(isSupportedToken(_elp_n), "not supported elp n");
        require(addDef["RewardRouter"] != address(0), "RewardRouter not set");
        IERC20(_elp_n).approve(elpToElpTracker[_elp_n], _amount);
        return IRewardRouter(addDef["RewardRouter"]).stakeELPn(_elp_n, _amount);
    }

    function _unstakeELP(address _elp_n, uint256 _amount) internal returns (uint256) {
        require(isSupportedToken(_elp_n), "not supported elp n");
        require(addDef["RewardRouter"] != address(0), "RewardRouter not set");
        IERC20(_elp_n).approve(addDef["RewardRouter"], _amount);
        return IRewardRouter(addDef["RewardRouter"]).unstakeELPn(_elp_n, _amount);
    }

    function unstakeELP(address _elp_n, uint256 _amount)  external onlyHandler returns (uint256) {
         require(isSupportedToken(_elp_n), "not supported elp n");
        if (_amount == 0){
            _amount = IERC20(elpToElpTracker[_elp_n]).balanceOf(address(this));
        }     
        return _unstakeELP(_elp_n, _amount);
    }


    function claimELPReward()  external onlyHandler returns (uint256[] memory) {
        return _claimELPReward();
    }

    function _claimELPReward() internal returns (uint256[] memory) {
        require(addDef["RewardRouter"] != address(0), "RewardRouter not set");
        return IRewardRouter(addDef["RewardRouter"]).claimAll();
    }


    function sellEUSD(address _tokenOut, uint256 _amount)  external payable onlyHandler returns (uint256) {
        return _sellEUSD( _tokenOut, _amount);
    }

    function _sellEUSD(address _tokenOut, uint256 _amount) internal returns (uint256) {
        require(addDef["EUSD"] != address(0), "EUSD not defined");
        require(addDef["RewardRouter"] != address(0), "RewardRouter not set");
        require(IERC20(addDef["EUSD"]).balanceOf(address(this)) >= _amount, "insufficient EUSD");
        IERC20(addDef["EUSD"]).approve(addDef["RewardRouter"], _amount);
        return IRewardRouter(addDef["RewardRouter"]).sellEUSD(_tokenOut, _amount);
    }


    function stakeAEde(uint256 _amount)  external onlyHandler {
        _stakeAEde(_amount);
    }
    function unstakeAEde(uint256 _amount)  external payable onlyHandler  {
        _unstakeAEde(_amount);
    }
    function _stakeAEde(uint256 _amount) internal {
        require(addDef["aEdeStakingPool"] != address(0), "aEdeStakingPool not set");
        require(addDef["aEDE"] != address(0), "aEDE not set");
        require(IERC20(addDef["aEDE"]).balanceOf(address(this)) >= _amount, "insufficient aEDE");
        IERC20(addDef["aEDE"]).approve(addDef["aEdeStakingPool"], _amount);
        IRewardTracker(addDef["aEdeStakingPool"]).stake(addDef["aEDE"], _amount);
    }
    function _unstakeAEde(uint256 _amount) internal {
        require(addDef["aEdeStakingPool"] != address(0), "aEdeStakingPool not set");
        require(addDef["aEDE"] != address(0), "aEDE not set");
        IRewardTracker(addDef["RewardRouter"]).unstake(addDef["aEDE"],_amount);
    }
    function claimAEdeReward( )  external payable onlyHandler{
        require(addDef["aEdeStakingPool"] != address(0), "aEdeStakingPool not set");
        IRewardTracker(addDef["RewardRouter"]).claim(address(this));
    }

    //------ Funcs. processing EDE LP
    function addEdeLPNative(uint256 _amount_ede, uint256 _amount_eth) external payable onlyHandler returns (uint amountToken, uint amountETH, uint liquidity) {
        return _addEdeLPNative(_amount_ede, _amount_eth);
    }

    function _addEdeLPNative(uint256 _amount_ede, uint256 _amount_eth) private returns (uint amountToken, uint amountETH, uint liquidity) {
        require(addDef["camelotRouter"] != address(0), "camelot lp contract not defined");
        require(addDef["EDE"] != address(0), "EDE not defined");
        require(IERC20(addDef["EDE"]).balanceOf(address(this)) >= _amount_ede, "insufficient EDE");
        require(address(this).balance >= _amount_eth, "insufficient eth");

        IERC20(addDef["EDE"]).approve(addDef["camelotRouter"], _amount_ede);
        return ICamelot(addDef["camelotRouter"]).addLiquidityETH{value:_amount_eth}(addDef["EDE"], _amount_ede,0,0,address(this), block.timestamp.add(1));
    }


    function removeEdeLPNative(uint256 _amount_lptoken) external payable onlyHandler returns (uint amountToken, uint amountETH) {
        return _removeEdeLPNative(_amount_lptoken);
    }

    function _removeEdeLPNative(uint256 _amount_lptoken) private returns (uint amountToken, uint amountETH) {
        require(addDef["camelotRouter"] != address(0), "camelot lp contract not defined");
        require(addDef["EDE"] != address(0), "EDE not defined");
        require(addDef["edeLpToken"] != address(0), "edeLpToken not defined");
        require(IERC20(addDef["edeLpToken"]).balanceOf(address(this)) >= _amount_lptoken, "insufficient EDE");
        require(address(this).balance >= _amount_lptoken, "insufficient eth");

        IERC20(addDef["edeLpToken"]).approve(addDef["camelotRouter"], _amount_lptoken);
        return ICamelot(addDef["camelotRouter"]).removeLiquidityETH( addDef["edeLpToken"], _amount_lptoken, 0, 0, address(this), block.timestamp.add(1));
    }



    // Func. for public
    // function spendingEUSD(address _token, address _elp) external returns (uint256) {
    //     require(isSupportedToken(_token), "not supported src token");

    //     uint256 eusdBalance = IERC20(EUSD).balanceOf(address(this));
    //     //step1 sell
    //     IERC20(EUSD).approve(RewardRouter, eusdBalance);
    //     uint256 sold_amount = IRewardRouter(RewardRouter).sellEUSD(_token, eusdBalance);

    //     //step2 swap to usingToken
    //     // _swapUV3(_token, Token_lp, sold_amount);

    //     //step3 buy EDE LP
    //     uint256 amounts_buy_LP = sold_amount.mul(weights[0]).div(weight_sum);
    //     _addEdeLPNative(amounts_buy_LP, 0);
    //     //step3.1 stake EDE LP Token

    //     //step.4 buy ELP
    //     uint256 amounts_buy_ELP = sold_amount.sub(amounts_buy_LP);
    //     IElpManager(elpManager[_elp]).addLiquidity(_token, amounts_buy_ELP, 0, 0);
    //     //step 4.1 stake ELP

    //     return 0;
    // }


    // function swap(address _src_token, address _dst_token, uint256 _amount) public returns (uint256) {
    //     require(isSupportedToken(_src_token), "not supported src token");
    //     require(isSupportedToken(_dst_token), "not supported dst token");
    //     IERC20(_src_token).safeTransferFrom(_msgSender(), address(this), _amount);
    //     uint256 orig_dst_balance = IERC20(_dst_token).balanceOf(address(this));
    //     uint256 orig_src_balance = IERC20(_src_token).balanceOf(address(this));
    //     uint256 receive_dst_balance = _swapUV3(_src_token, _dst_token, _amount);
    //     require(IERC20(_src_token).balanceOf(address(this)) >= orig_src_balance, "src token not enough");
    //     require(IERC20(_dst_token).balanceOf(address(this)).sub(orig_dst_balance) >= receive_dst_balance, "not enough receipt");
    //     IERC20(_dst_token).transfer(_msgSender(), receive_dst_balance);
    //     return receive_dst_balance;
    // }
    // function _swapUV3(address _src_token, address _dst_token, uint256 _amount) private returns (uint256) {
    //     ISwapRouter.ExactInputSingleParams memory eisp;
    //     eisp.tokenIn = _src_token;
    //     eisp.tokenOut = _dst_token;
    //     eisp.fee = fee;
    //     eisp.recipient = address(this);
    //     eisp.deadline = block.timestamp.add(2);
    //     eisp.amountIn =  _amount;
    //     return ISwapRouter(univ3).exactInputSingle(eisp) ;
    // }


    // Func. public view
    function isSupportedToken(address _token) public view returns(bool){
        return supportedToken.contains(_token);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

library EnumerableValues {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    function valuesAt(EnumerableSet.Bytes32Set storage set, uint256 start, uint256 end) internal view returns (bytes32[] memory) {
        uint256 max = set.length();
        if (end > max) { end = max; }

        bytes32[] memory items = new bytes32[](end - start);
        for (uint256 i = start; i < end; i++) {
            items[i - start] = set.at(i);
        }

        return items;
    }


    function valuesAt(EnumerableSet.AddressSet storage set, uint256 start, uint256 end) internal view returns (address[] memory) {
        uint256 max = set.length();
        if (end > max) { end = max; }

        address[] memory items = new address[](end - start);
        for (uint256 i = start; i < end; i++) {
            items[i - start] = set.at(i);
        }

        return items;
    }


    function valuesAt(EnumerableSet.UintSet storage set, uint256 start, uint256 end) internal view returns (uint256[] memory) {
        uint256 max = set.length();
        if (end > max) { end = max; }

        uint256[] memory items = new uint256[](end - start);
        for (uint256 i = start; i < end; i++) {
            items[i - start] = set.at(i);
        }

        return items;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IElpManager {
    function cooldownDuration() external returns (uint256);
    function lastAddedAt(address _account) external returns (uint256);
    function addLiquidity(address _token, uint256 _amount, uint256 _minUsdx, uint256 _minElp) external returns (uint256);
    function addLiquidityETH() external payable returns (uint256);
    function removeLiquidity(address _tokenOut, uint256 _elpAmount, uint256 _minOut, address _receiver) external returns (uint256);
    function removeLiquidityETH(uint256 _elpAmount) external payable returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRouter {
    function addPlugin(address _plugin) external;
    function approvePlugin(address _plugin) external;
    function pluginTransfer(address _token, address _account, address _receiver, uint256 _amount) external;
    function pluginIncreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _sizeDelta, bool _isLong) external;
    function pluginDecreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, bool _isLong, address _receiver) external returns (uint256);
    function swap(address[] memory _path, uint256 _amountIn, uint256 _minOut, address _receiver) external;
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../DID/interfaces/IESBT.sol";
import "../VaultMSData.sol";

interface IVault {
    function isSwapEnabled() external view returns (bool);
    
    function priceFeed() external view returns (address);
    function usdx() external view returns (address);
    function totalTokenWeights() external view returns (uint256);
    function usdxSupply() external view returns (uint256);
    function usdxAmounts(address _token) external view returns (uint256);
    function guaranteedUsd(address _token) external view returns (uint256);
    function baseMode() external view returns (uint8);

    function approvedRouters(address _router) external view returns (bool);
    function isManager(address _account) external view returns (bool);

    function feeReserves(address _token) external view returns (uint256);
    function feeSold (address _token)  external view returns (uint256);
    function feeReservesUSD() external view returns (uint256);
    function feeReservesDiscountedUSD() external view returns (uint256);
    function feeReservesRecord(uint256 _day) external view returns (uint256);
    function feeClaimedUSD() external view returns (uint256);
    // function keyOwner(bytes32 _key) external view returns (address);
    // function shortSizes(address _token) external view returns (uint256);
    // function shortCollateral(address _token) external view returns (uint256);
    // function shortAveragePrices(address _token) external view returns (uint256);
    // function longSizes(address _token) external view returns (uint256);
    // function longCollateral(address _token) external view returns (uint256);
    // function longAveragePrices(address _token) external view returns (uint256);
    function globalShortSize( ) external view returns (uint256);
    function globalLongSize( ) external view returns (uint256);


    //---------------------------------------- owner FUNCTIONS --------------------------------------------------
    function setESBT(address _eSBT) external;
    function setVaultStorage(address _vaultStorage) external;
    function setVaultUtils(address _vaultUtils) external;
    function setManager(address _manager, bool _isManager) external;
    function setIsSwapEnabled(bool _isSwapEnabled) external;
    function setPriceFeed(address _priceFeed) external;
    function setRouter(address _router, bool _status) external;
    function setUsdxAmount(address _token, uint256 _amount, bool _increase) external;
    function setTokenConfig(address _token, uint256 _tokenDecimals, uint256 _tokenWeight, uint256 _maxUSDAmount,
        bool _isStable,  bool _isFundingToken, bool _isTradingToken ) external;
    function clearTokenConfig(address _token) external;
    function updateRate(address _token) external;

    //-------------------------------------------------- FUNCTIONS FOR MANAGER --------------------------------------------------
    function buyUSDX(address _token, address _receiver) external returns (uint256);
    function sellUSDX(address _token, address _receiver, uint256 _usdxAmount) external returns (uint256);
    function claimFeeToken(address _token) external returns (uint256);
    function claimFeeReserves( ) external returns (uint256) ;


    //---------------------------------------- TRADING FUNCTIONS --------------------------------------------------
    function swap(address _tokenIn, address _tokenOut, address _receiver) external returns (uint256);
    function increasePosition(address _account, address _collateralToken, address _indexToken, uint256 _sizeDelta, bool _isLong) external;
    function decreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, bool _isLong, address _receiver) external returns (uint256);
    function liquidatePosition(address _account, address _collateralToken, address _indexToken, bool _isLong, address _feeReceiver) external;


    //-------------------------------------------------- PUBLIC FUNCTIONS --------------------------------------------------
    function directPoolDeposit(address _token) external;
    function tradingTokenList() external view returns (address[] memory);
    function fundingTokenList() external view returns (address[] memory);
    function claimableFeeReserves( )  external view returns (uint256);
    // function whitelistedTokenCount() external view returns (uint256);
    //fee functions
    // function tokenBalances(address _token) external view returns (uint256);
    // function lastFundingTimes(address _token) external view returns (uint256);
    // function setInManagerMode(bool _inManagerMode) external;
    // function setBufferAmount(address _token, uint256 _amount) external;
    // function setMaxGlobalShortSize(address _token, uint256 _amount) external;
    function getMaxPrice(address _token) external view returns (uint256);
    function getMinPrice(address _token) external view returns (uint256);
    function getRedemptionAmount(address _token, uint256 _usdxAmount) external view returns (uint256);
    function tokenToUsdMin(address _token, uint256 _tokenAmount) external view returns (uint256);
    function usdToTokenMax(address _token, uint256 _usdAmount) external view returns (uint256);
    function usdToTokenMin(address _token, uint256 _usdAmount) external view returns (uint256);
    // function getPosition(address _account, address _collateralToken, address _indexToken, bool _isLong) external view returns (uint256, uint256, uint256, int256, uint256, uint256, bool, uint256);
    // function getPositionByKey(bytes32 _key) external view returns (uint256, uint256, uint256, int256, uint256, uint256, bool, uint256);
    // function getNextFundingRate(address _token) external view returns (uint256);
    function isFundingToken(address _token) external view returns(bool);
    function isTradingToken(address _token) external view returns(bool);
    function tokenDecimals(address _token) external view returns (uint256);
    function getPositionStructByKey(bytes32 _key) external view returns (VaultMSData.Position memory);
    function getPositionStruct(address _account, address _collateralToken, address _indexToken, bool _isLong) external view returns (VaultMSData.Position memory);
    function getTokenBase(address _token) external view returns (VaultMSData.TokenBase memory);
    function getTradingFee(address _token) external view returns (VaultMSData.TradingFee memory);
    function getTradingRec(address _token) external view returns (VaultMSData.TradingRec memory);
    function getUserKeys(address _account, uint256 _start, uint256 _end) external view returns (bytes32[] memory);
    function getKeys(uint256 _start, uint256 _end) external view returns (bytes32[] memory);

    // function fundingRateFactor() external view returns (uint256);
    // function stableFundingRateFactor() external view returns (uint256);
    // function cumulativeFundingRates(address _token) external view returns (uint256);
    // // function getFeeBasisPoints(address _token, uint256 _usdxDelta, uint256 _feeBasisPoints, uint256 _taxBasisPoints, bool _increment) external view returns (uint256);


    // function allWhitelistedTokensLength() external view returns (uint256);
    // function allWhitelistedTokens(uint256) external view returns (address);
    // function whitelistedTokens(address _token) external view returns (bool);
    // function stableTokens(address _token) external view returns (bool);
    // function shortableTokens(address _token) external view returns (bool);
    
    // function globalShortSizes(address _token) external view returns (uint256);
    // function globalShortAveragePrices(address _token) external view returns (uint256);
    // function maxGlobalShortSizes(address _token) external view returns (uint256);
    // function tokenDecimals(address _token) external view returns (uint256);
    // function tokenWeights(address _token) external view returns (uint256);
    // function guaranteedUsd(address _token) external view returns (uint256);
    // function poolAmounts(address _token) external view returns (uint256);
    // function bufferAmounts(address _token) external view returns (uint256);
    // function reservedAmounts(address _token) external view returns (uint256);
    // function maxUSDAmounts(address _token) external view returns (uint256);



}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRewardRouter {
    function getEUSDPoolInfo() external view returns (uint256[] memory);
    function stakeELPn(address _elp_n, uint256 _elpAmount) external returns (uint256);
    function unstakeELPn(address _elp_n, uint256 _tokenInAmount) external returns (uint256);
    function claimAll() external  returns ( uint256[] memory);
    function lvt() external view returns (uint256) ;
    function sellEUSD(address _token, uint256 _EUSDamount) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRewardTracker {
    // function depositBalances(address _account, address _depositToken) external view returns (uint256);
    function stakedAmounts(address _account) external view returns (uint256);
    function updateRewardsForUser(address _account) external;
    function poolStakedAmount() external view returns (uint256);
    
    function stake(address _depositToken, uint256 _amount) external;
    function stakeForAccount(address _fundingAccount, address _account, address _depositToken, uint256 _amount) external;
    function unstake(address _depositToken, uint256 _amount) external;
    function unstakeForAccount(address _account, address _depositToken, uint256 _amount, address _receiver) external;
    // function tokensPerInterval() external view returns (uint256);
    function claim(address _receiver) external returns (uint256);
    function claimForAccount(address _account, address _receiver) external returns (uint256);
    function claimable(address _account) external view returns (uint256);
    function averageStakedAmounts(address _account) external view returns (uint256);
    function cumulativeRewards(address _account) external view returns (uint256);
    function balanceOf(address _account) external view returns (uint256);

    function poolTokenRewardPerInterval() external view returns (uint256);

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
pragma solidity ^0.8.13;

interface IESBT {
    // function updateIncreaseLogForAccount(address _account, address _collateralToken, 
            // uint256 _collateralSize,uint256 _positionSize, bool /*_isLong*/ ) external returns (bool);

    function scorePara(uint256 _paraId) external view returns (uint256);
    function createTime(address _account) external view returns (uint256);
    // function tradingKey(address _account, bytes32 key) external view returns (bytes32);
    function nickName(address _account) external view returns (string memory);


    function getReferralForAccount(address _account) external view returns (address[] memory , address[] memory);
    function userSizeSum(address _account) external view returns (uint256);
    // function updateFeeDiscount(address _account, uint256 _discount, uint256 _rebate) external;
    function updateFee(address _account, uint256 _origFee) external returns (uint256);
    // function calFeeDiscount(address _account, uint256 _amount) external view returns (uint256);

    function getESBTAddMpUintetRoles(address _mpaddress, bytes32 _key) external view returns (uint256[] memory);
    function updateClaimVal(address _account) external ;
    function userClaimable(address _account) external view returns (uint256, uint256);

    // function updateScoreForAccount(address _account, uint256 _USDamount, uint16 _opeType) external;
    function updateScoreForAccount(address _account, address /*_vault*/, uint256 _amount, uint256 _reasonCode) external;
    function updateTradingScoreForAccount(address _account, address _vault, uint256 _amount, uint256 _refCode) external;
    function updateSwapScoreForAccount(address _account, address _vault, uint256 _amount) external;
    function updateAddLiqScoreForAccount(address _account, address _vault, uint256 _amount, uint256 _refCode) external;
    // function updateStakeEDEScoreForAccount(address _account, uint256 _amount) external ;
    function getScore(address _account) external view returns (uint256);
    function getRefCode(address _account) external view returns (string memory);
    function accountToDisReb(address _account) external view returns (uint256, uint256);
    function rank(address _account) external view returns (uint256);
    function addressToTokenID(address _account) external view returns (uint256);

    function rankToDiscount(uint256 _rank) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../utils/EnumerableValues.sol";

library VaultMSData {
    // bytes32 public constant opeProtectIdx = keccak256("opeProtectIdx");
    // using EnumerableSet for EnumerableSet.UintSet;
    // using EnumerableValues for EnumerableSet.UintSet;

    uint256 constant COM_RATE_PRECISION = 10**4; //for common rate(leverage, etc.) and hourly rate
    uint256 constant HOUR_RATE_PRECISION = 10**6; //for common rate(leverage, etc.) and hourly rate
    uint256 constant PRC_RATE_PRECISION = 10**10;   //for precise rate  secondly rate
    uint256 constant PRICE_PRECISION = 10**30;

    struct Position {
        address account;
        address collateralToken;
        address indexToken;
        uint256 size;
        uint256 collateral;
        uint256 averagePrice;
        uint256 reserveAmount;
        uint256 lastUpdateTime;
        uint256 aveIncreaseTime;


        uint256 entryFundingRateSec;
        int256 entryPremiumRateSec;

        int256 realisedPnl;

        uint256 stopLossRatio;
        uint256 takeProfitRatio;

        bool isLong;

        int256 accPremiumFee;
        uint256 accFundingFee;
        uint256 accPositionFee;
        uint256 accCollateral;
    }


    struct TokenBase {
        //Setable parts
        bool isFundable;
        bool isStable;
        uint256 decimal;
        uint256 weight;  //tokenWeights allows customisation of index composition
        uint256 maxUSDAmounts;  // maxUSDAmounts allows setting a max amount of USDX debt for a token

        //Record only
        uint256 balance;        // tokenBalances is used only to determine _transferIn values
        uint256 poolAmount;     // poolAmounts tracks the number of received tokens that can be used for leverage
                                // this is tracked separately from tokenBalances to exclude funds that are deposited as margin collateral
        uint256 reservedAmount; // reservedAmounts tracks the number of tokens reserved for open leverage positions
        uint256 bufferAmount;   // bufferAmounts allows specification of an amount to exclude from swaps
                                // this can be used to ensure a certain amount of liquidity is available for leverage positions
    }


    struct TradingFee {
        uint256 fundingRatePerSec; //borrow fee & token util

        uint256 accumulativefundingRateSec;

        int256 longRatePerSec;  //according to position
        int256 shortRatePerSec; //according to position
        int256 accumulativeLongRateSec;
        int256 accumulativeShortRateSec;

        uint256 latestUpdateTime;
        // uint256 lastFundingTimes;     // lastFundingTimes tracks the last time funding was updated for a token
        // uint256 cumulativeFundingRates;// cumulativeFundingRates tracks the funding rates based on utilization
        // uint256 cumulativeLongFundingRates;
        // uint256 cumulativeShortFundingRates;
    }

    struct TradingTax {
        uint256 taxMax;
        uint256 taxDuration;
        uint256 k;
    }

    struct TradingLimit {
        uint256 maxShortSize;
        uint256 maxLongSize;
        uint256 maxTradingSize;

        uint256 maxRatio;
        uint256 countMinSize;
        //Price Impact
    }


    struct TradingRec {
        uint256 shortSize;
        uint256 shortCollateral;
        uint256 shortAveragePrice;
        uint256 longSize;
        uint256 longCollateral;
        uint256 longAveragePrice;
    }

}