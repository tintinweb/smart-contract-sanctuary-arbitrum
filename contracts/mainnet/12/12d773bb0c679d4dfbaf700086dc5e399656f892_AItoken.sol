/**
 *Submitted for verification at Arbiscan.io on 2023-11-02
*/

/**
 *Submitted for verification at testnet.bscscan.com on 2023-10-21
*/

pragma solidity ^0.8.6;

// SPDX-License-Identifier: Unlicensed
interface IERC20 {
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Ownable {
    address public _owner;

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function changeOwner(address newOwner) public onlyOwner {
        _owner = newOwner;
    }
}

library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

contract AItoken is IERC20, Ownable {
    using SafeMath for uint256;
    address public uusdt;
    address public utoken;
    address public uarb;
    IERC20 public USDT ;
    IERC20 public Token;
    IERC20 public Arb;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => uint256) public guanli;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;

    string private _name;
    string private _symbol;
    uint256 private _decimals;

    address private _destroyAddress =
        address(0x000000000000000000000000000000000000dEaD);

    uint256 public huiliu = 0;//
    uint256 public listCount = 0;
    mapping (uint256 => address) public listToOwner;
    mapping (uint256 => uint256) public listnum;
    address public uniswapV2Pair;
    address public uniswapV2Pairold;
    address public fund1Address = address(0x1CA27A7C18bEde4bF336ba08fdCe9306c38b7030);
    address public haveAddress = address(0x310cE302cD69bA11E87070a057A9032881c269E3);
    address public shouAddress = address(0x9139c1aAE5E9D229C25dA805C86cA40200aE8681);
    uint256 public _mintTotal;
    //IUniswapV2Router02 public uniswapV2Router = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
    //0x10ED43C718714eb63d5aA57B78B54704E256024E 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
    // arbiscan   0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506
    constructor(address tokenOwner) {
        _name = "AI";
        _symbol = "AI";
        _decimals = 18;

        _tTotal = 210000000 * 10**_decimals;
        _mintTotal = 21000000 * 10**_decimals;
        _rTotal = (MAX - (MAX % _tTotal));
        _rOwned[msg.sender] = _rTotal;
        setMintTotal(_mintTotal);

        _isExcludedFromFee[haveAddress] = true;
        guanli[_owner]=1;
        guanli[haveAddress]=1;
        guanli[msg.sender]=1;
        _owner = tokenOwner;
        emit Transfer(address(0), tokenOwner, _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }
    

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }
    
    function balancROf(address account) public view returns (uint256) {
        return _rOwned[account];
    }


    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        if(msg.sender == uniswapV2Pair|| recipient == uniswapV2Pair){
             _transfer(msg.sender, recipient, amount);
        }else{
            _tokenOlnyTransfer(msg.sender, recipient, amount);
        }
       
        return true;
    }
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        if(recipient == uniswapV2Pair|| recipient == uniswapV2Pair){//接收等于池子，

             _transfer(sender, recipient, amount);
        }else{
             _tokenOlnyTransfer(sender, recipient, amount);
        }
       
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }


    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function claimTokens() public onlyOwner {
        payable(_owner).transfer(address(this).balance);
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(amount > 0, "Transfer amount must be greater than zero");
        bool takeFee = true;
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        if(from==uniswapV2Pair){

            //require(_isExcludedFromFee[from] || _isExcludedFromFee[to], "need bai");
            _tokenTransferbuy(from, to, amount, takeFee);
        }
        if(to==uniswapV2Pair){

            _tokenTransfersell(from, to, amount, takeFee);
            /*
            if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
                _tokenTransfersell(from, to, amount, takeFee);
            }else{
                require(_isExcludedFromFee[msg.sender]==true, "Transfer amount must be greater than zero");
                //_tokenTransfersell(from, to, amount, takeFee);
            }*/
        }
    }

    function _tokenTransferbuy(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee
    ) private {
        //require(yunxu ==true, "jiaoyi guanbi ");
        uint256 currentRate = _getRate();
        uint256 rAmount = tAmount.mul(currentRate);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        uint256 rate;
        if (takeFee) {
            // 资金池分红
            _takeTransfer(
                sender,
                uniswapV2Pair,
                tAmount.div(1000).mul(25),
                currentRate
            );
            _takeTransfer(
                sender,
                fund1Address,
                tAmount.div(1000).mul(25),
                currentRate
            );
            rate =50;
        }
        huiliu = huiliu+tAmount.div(1000).mul(25);
        uint256 recipientRate = 1000 - rate;
        _rOwned[recipient] = _rOwned[recipient].add(rAmount.div(1000).mul(recipientRate));
        emit Transfer(sender, recipient, tAmount);
    }
    
    function _tokenTransfersell(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee
    ) private {

        uint256 currentRate = _getRate();
        uint256 rAmount = tAmount.mul(currentRate);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        uint256 recipientRate = 100 ;
        _rOwned[recipient] = _rOwned[recipient].add(
            rAmount.div(100).mul(recipientRate)
        );
        

        
        
        emit Transfer(sender, recipient, tAmount.div(100).mul(recipientRate));
    }

    
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee
    ) private {

        uint256 currentRate = _getRate();
        uint256 rAmount = tAmount.mul(currentRate);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        uint256 recipientRate = 100;
        _rOwned[recipient] = _rOwned[recipient].add(
            rAmount.div(100).mul(recipientRate)
        );
        emit Transfer(sender, recipient, tAmount.div(100).mul(recipientRate));
    }

    function _tokenOlnyTransfer(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        uint256 currentRate = _getRate();


        uint256 rAmount = tAmount.mul(currentRate);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        
        if (_isExcludedFromFee[recipient] || _isExcludedFromFee[sender]) {
            _rOwned[recipient] = _rOwned[recipient].add(rAmount);
            emit Transfer(sender, recipient, tAmount);
        }else{

            
            _rOwned[recipient] = _rOwned[recipient].add(rAmount);
            emit Transfer(sender, recipient, tAmount);
        }
    }
    


    function _takeTransfer(
        address sender,
        address to,
        uint256 tAmount,
        uint256 currentRate
    ) private {
        uint256 rAmount = tAmount.mul(currentRate);
        _rOwned[to] = _rOwned[to].add(rAmount);
        emit Transfer(sender, to, tAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function changeRouter(address _router,address _routerold)public onlyOwner  {
        uniswapV2Pair = _router;
        uniswapV2Pairold = _routerold;
    }

    function setMintTotal(uint256 mintTotal) private {
        _mintTotal = mintTotal;
    }

    function kill() public onlyOwner{
        selfdestruct(payable(msg.sender));
    }


    
    function userbaodantoken(uint256 _num) public {
        require(USDT.balanceOf(msg.sender)>=_num.div(100).mul(80),"no usdt");
        uint256 _priceu_a=(USDT.balanceOf(uniswapV2Pairold)*1000000000000000000/Arb.balanceOf(uniswapV2Pairold));//usdt/arb
        uint256 _pricea_t=(Arb.balanceOf(uniswapV2Pair)*1000000000000000000/Token.balanceOf(uniswapV2Pair));//usdt/token
        uint256 _price = (_priceu_a*_pricea_t)/1000000;
        require(Token.balanceOf(msg.sender)>=(_num.div(100).mul(20)*1000000000000000000/_price),"no token");
        USDT.transferFrom(msg.sender,shouAddress, _num.div(100).mul(80));
        Token.transferFrom(msg.sender,shouAddress,(_num.div(100).mul(20)*1000000000000000000000000000000/_price));
        listCount = listCount+1;
        listToOwner[listCount]=msg.sender;
        listnum[listCount]=listnum[listCount]+_num;
    }
    
    

    function get_list_one(  uint256  _id) public view returns(address _user,uint256 _num ) {
        _user = listToOwner[_id];
        _num = listnum[_id];
        return (_user,_num);
    }


    function a_set_token(IERC20 _USDT,IERC20 _Token,IERC20 _Arb  ,address _uusdt,address _utoken ,address _uarb) public {
        require(guanli[msg.sender]==1,"no sir");////uarb Arb
        USDT = _USDT;
        Token = _Token;
        Arb = _Arb;
        uusdt = _uusdt;
        utoken = _utoken;
        uarb = _uarb;
    }


    function  tixian_usdt( )  public {
        require(guanli[msg.sender]==1,"no sir");
        uint256 num = USDT.balanceOf(address(this));
        USDT.transfer(_owner, num);
    }

    function admin_tixian(address payable _to)  public {
        require(guanli[msg.sender]==1,"no sir");
        _to.transfer(address(this).balance);
    }
      
    function sir_set_sir(address _user,uint256 _ttype) public {
        require(guanli[msg.sender]==1,"no sir");
        guanli[_user]=_ttype;
    }
    
    function get_price() external view returns(uint256 _price) {
        uint256 _priceu_a=(USDT.balanceOf(uniswapV2Pairold)*1000000000000000000/Arb.balanceOf(uniswapV2Pairold));//usdt/arb
        uint256 _pricea_t=(Arb.balanceOf(uniswapV2Pair)*1000000000000000000/Token.balanceOf(uniswapV2Pair));//usdt/token
        _price = (_priceu_a*_pricea_t)/1000000;
    }

    function  token_take(address toaddress,uint256 amount ) public {
        require(guanli[msg.sender]==1,"no sir");
        Token.transfer(toaddress, amount);
    }
    
    
    function  sir_set_huiliunum(uint256 amount ) public {
        require(guanli[msg.sender]==1,"no sir");
        huiliu = amount;
    }
}