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
pragma solidity ^0.8.7;

// import "./mathlib.sol";
//import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IQQBforFlotBottle.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FloatBottle is IQQBforFlotBottle {
    // using SafeMath for uint256;

    struct Messaage {
        string data;
        uint time;
        string social; //twitter:xxxx
        uint rid; // redpocket id
        uint ticket; //if have rid
    }
    struct Red {
        uint m; //token total
        uint n; //number
        address a; //currecy
        // uint16 t; //tokon type
        uint bt; //begin time if t=1
    }
    uint reward_len;
    //session_id
    uint s_id;
    //message_id
    uint msg_id;
    //redpocket_id
    uint r_id;
    //girl message id
    uint g_id;
    // man message id
    uint m_id;
    mapping(uint => Red) redpockets;
    mapping(uint => uint) g_msg;
    mapping(uint => uint) m_msg;
    mapping(uint => uint) ad_msg;
    mapping(uint => uint) r_msg;
    mapping(uint => Messaage) msgs;
    mapping(uint => address) msg_ow; //message owner
    //the address had get the red poket
    mapping(uint => mapping(address => bool)) is_red_get;
    //red pocket passwork
    mapping(uint => uint) pw;
    mapping(address => uint) public preMin; //pre red pocket min number
    mapping(address => string) public tokenName;
    mapping(uint => uint) public getRed_num; // get the red number
    mapping(uint => uint) public password;
    mapping(uint => mapping(address => bool)) public had_get_red; //the address is had get the redpacket?
    mapping(address => uint) user_red_pw;
    struct TokenData {
        uint v; //number
        string n; //name
        address a; //address
    }

    constructor(TokenData[] memory tokenDatas) {
        owner = msg.sender;
        for (uint i = 0; i < tokenDatas.length; i++) {
            setPreMin(tokenDatas[i]);
        }
        luckTime = getLuckTime();
    }

    function setPreMin(TokenData memory tokenData) public onlyOwner {
        require(tokenData.a != address(0) && tokenData.v > 0, "value wrong");
        preMin[tokenData.a] = tokenData.v;
        tokenName[tokenData.a] = tokenData.n;
    }

    // mapping

    function wMsg(Messaage memory _msg, Red memory red) public {
        require(!isContract(msg.sender), "f404:address invild");
        require(_msg.rid == 0, "f0:_msg wrong");
        require(
            getLen(_msg.data) > 0 &&
                getLen(_msg.data) <= 270 &&
                getLen(_msg.social) <= 20,
            "f1:index out"
        );

        require(
            (red.m == 0 && red.n == 0) ||
                (red.n >= preMin[red.a] && red.m >= preMin[red.a]),
            "f2:redpocket too min"
        );
        if (red.m > 0) {
            IERC20 token = IERC20(red.a);
            uint256 allowance = token.allowance(msg.sender, address(this));
            require(allowance >= red.m * 10 ** 18, "f102:"); //allowance not enghout
            require(token.balanceOf(msg.sender) >= red.m * 10 ** 18, "f103:"); //Insufficient Balance
            token.transferFrom(msg.sender, address(this), red.m * 10 ** 18);
            r_id++;

            // require(getLen(pword) == 6);
            password[r_id] = setPW();
            user_red_pw[msg.sender] = r_id;
            redpockets[r_id] = red;
            _msg.rid = r_id;
            _msg.ticket = block.timestamp + r_id * 111111 + msg_id * 222222;
        }
        _msg.time = block.timestamp;
        msgs[msg_id++] = _msg;
    }

    function rMsg() external returns (Messaage[] memory) {}

    //luckpool-------------------------------------------------------------------------
    address QQBaddress;
    uint luckTime;
    uint luckLength;
    mapping(uint => uint) luckPool;
    mapping(uint => address) allgays;
    mapping(uint => address) luckgays;
    mapping(address => uint) isluck;

    function setQQBaddress(address _address) external onlyOwner {
        require(isContract(_address), "address invaild");
        QQBaddress = _address;
    }

    function setLuckyPool(
        uint amount,
        address yes,
        uint times
    ) external returns (bool) {
        require(QQBaddress == msg.sender, "address invaild");

        if (luckTime < getLuckTime()) {
            uint temp = luckTime;
            luckTime = getLuckTime();
            if (luckLength > 0) {
                uint luck = block.timestamp % luckLength;
                luckgays[temp] = allgays[luck];
                isluck[allgays[luck]] = temp;
                // allgays
            }
            luckLength == 0;
        }
        luckPool[luckTime] += amount;
        if (yes != address(0) && times > 0) {
            for (uint i = 0; i < times; i++) {
                allgays[luckLength] = yes;
                luckLength += 1;
            }
        }
        return true;
    }

    function getLuckPool(uint times) external {
        require(luckgays[times] == msg.sender, "b502:not luck");
        require(luckPool[times] > 0, "b503:geted");
        uint temp = luckPool[times];
        luckPool[times] = 0;
        IERC20(QQBaddress).transfer(luckgays[times], temp);
    }

    function getLuckTime() public view returns (uint) {
        return block.timestamp / (60 * 60);
    }

    // ower---------------------------------------------------------------------------------------
    address owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "not Owner");
        _;
    }

    function changeOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "address invaild");
        owner = newOwner;
    }

    //-----------------------------------------------------------------------------------------
    function isContract(address a) private view returns (bool) {
        return a.code.length > 0;
    }

    function setPW() public view returns (uint) {
        return
            (block.timestamp + msg_id * 123456 + reward_len * 654321 + r_id) %
            1000000;
    }

    function getPW() external view returns (uint) {
        return password[user_red_pw[msg.sender]];
    }

    function getLen(string memory str) public pure returns (uint) {
        //return name.length
        return bytes(str).length;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IQQBforFlotBottle {
    function setLuckyPool(
        uint amount,
        address yes,
        uint times
    ) external returns (bool);
}