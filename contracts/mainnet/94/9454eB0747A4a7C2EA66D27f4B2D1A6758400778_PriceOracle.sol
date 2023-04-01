/**
 *Submitted for verification at Arbiscan on 2023-03-30
*/

// File contracts/PriceOracle.sol

// License: GPL-3.0
pragma solidity ^0.6.12;
// SPDX-License-Identifier: MIT
interface IChainlink {
  function latestAnswer() external view returns (int256);
}

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

    // for lp
   
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);    
}

interface IFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}
 

contract PriceOracle {
    //usdt decimal 6,eth decimal 18
    uint256 constant F = 1e18;
    address owner;
 
    /////////////////////////  change for release  //////////////////////// 
    address constant public SWAP_FACTORY = 0xBED2e4b94225847c84c099639A7D0A3435A15eB2;  //change for release
    address constant public STAKING_POOL = 0x34D715147773927d7E53850784B76e9E0B44e186;   //change for release

    //main net
    address constant public COEX  =  0xB126dde12F645041efb716F87dE2e636812A1b4C ;  //change for release
    address constant public MDAO  =  0x170469270738fA4827b02e242E304809A8cfc87F ;  //change for release
    address constant public USDT =  0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9 ;   
    address constant public ETH =   0x82aF49447D8a07e3bd95BD0d56f35241523fBab1 ;
 
    address public COEX_ETH ;
    address public COEX_USDT ;
    address public COEX_MDAO ;
    address public MDAO_USDT ;
  
    constructor() public {
        owner = msg.sender;
        update();
    } 

    function update() public {
        IFactory factory = IFactory(SWAP_FACTORY);
        COEX_ETH = factory.getPair(COEX, ETH);
        COEX_USDT = factory.getPair(COEX, USDT);
        COEX_MDAO  = factory.getPair(COEX, MDAO );
        MDAO_USDT  = factory.getPair(MDAO, USDT );
     }
    

    // X-USDT OR USDT-X  , return x price
    function amm_price( address _lptoken) public view returns (uint256){
        uint token_balance;
        uint256 usd_balance;

        IERC20 pair = IERC20(_lptoken);
        if (pair.token0() == USDT) 
            (usd_balance, token_balance, ) = pair.getReserves();     
        else
            (token_balance, usd_balance , ) = pair.getReserves();           

        uint256 price = usd_balance * F / token_balance;
        return price;
    }    
   
    function mdao_price() public  view returns (uint256){
        return amm_price(MDAO_USDT);
    }
    function coex_price() public  view returns (uint256){
        return amm_price(COEX_USDT);
    }
 

    // reward_pre_day
    // X-USDT  
     function apy_usdt_pair_lp( address _lptoken, address _staking_pool, uint256 _reward_pre_day ) public  view returns (uint256) {          
        uint112 token_balance;
        uint112 usd_balance;

        IERC20 pair = IERC20(_lptoken);
        if (pair.token0() == USDT) 
            (usd_balance, token_balance, ) = pair.getReserves();     
        else
            (token_balance, usd_balance , ) = pair.getReserves();           

        uint256 token_price = usd_balance * F / token_balance;
        //lp token price
        uint256 lp_price = ((token_balance * token_price) + (usd_balance * F) ) / pair.totalSupply();
        //deposit lp token to usdt value
        uint256 staking_lp_value = pair.balanceOf(_staking_pool) * lp_price / F;          
        uint256 apy =  _reward_pre_day * F  *  mdao_price() * 365 * 100 / staking_lp_value;   
      
        return apy;
    } 

    // reward_pre_day
    // not usdt , transfer to usdt value
     function apy_coex_pair_lp( address _lptoken,  address _staking_pool, uint256 _reward_pre_day) public  view returns (uint256) {          
        uint112 token_balance;
        uint112 coex_balance;

        IERC20 pair = IERC20(_lptoken);
        if (pair.token0() == COEX) 
            (coex_balance, token_balance, ) = pair.getReserves();     
        else
            (token_balance, coex_balance , ) = pair.getReserves();  

        //token price
        // coex_price() = usd_balance * F / coex_balance;
        uint256 usd_balance = coex_balance * coex_price() / F;
        uint256 token_price = usd_balance * F / token_balance;
        //lp token price
        uint256 lp_price = ((token_balance * token_price) + (usd_balance * F) ) / pair.totalSupply();
        //deposit lp token to usdt value
        uint256 staking_lp_value = pair.balanceOf(_staking_pool) * lp_price / F;          
        uint256 apy =  _reward_pre_day * F  *  mdao_price() * 365 * 100 / staking_lp_value;   
      
        return apy;
    }


    function coex_eth_lp_apy(uint256 _reward_pre_day) public  view returns (uint256){
        return apy_coex_pair_lp(COEX_ETH, STAKING_POOL, _reward_pre_day  ) ; 
    }    

     function coex_usdt_lp_apy(uint256 _reward_pre_day) public  view returns (uint256){
        return apy_coex_pair_lp(COEX_USDT, STAKING_POOL, _reward_pre_day ) ; 
    }    

    function coex_mdao_lp_apy(uint256 _reward_pre_day) public  view returns (uint256){
        return apy_coex_pair_lp(COEX_MDAO,  STAKING_POOL, _reward_pre_day ) ; 
    }    
 
    function mdao_usdt_lp_apy(uint256 _reward_pre_day) public  view returns (uint256){
        return apy_usdt_pair_lp(MDAO_USDT, STAKING_POOL, _reward_pre_day ) ; 
    }
}