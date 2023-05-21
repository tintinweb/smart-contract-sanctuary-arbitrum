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
import "./IQQBLock.sol";

contract FloatBottle is IQQBforFlotBottle {
    // using SafeMath for uint256;

    struct Messaage {
        string data;
        uint time;
        string social; //twitter:xxxx
        uint rid; // redpocket id
        uint ticket; //if have rid
        uint msgid; //
        string url;
        bool isB;
    }
    struct Red {
        uint m; //token total
        uint n; //number
        address a; //currecy
        // uint16 t; //tokon type
        uint bt; //begin time if t=1
    }

    //session_id
    uint s_id;
    //message_id
    uint msg_id;
    //redpocket_id
    uint r_id;
    //girl message id
    uint g_id;
    // man message id
    uint admin_id;

    mapping(address => bool) blue;
    mapping(address => string) blueid;
    mapping(uint => Red) redpockets; //index 1 start
    mapping(uint => uint) admin_msg; //index 1 start
    mapping(uint => uint) red_msg; //index 1 start
    mapping(uint => uint) ad_msg;

    mapping(uint => Messaage) msgs; //index 1 start
    // mapping(uint => address) msg_ow; //message owner
    //the address had get the red poket
    mapping(uint => mapping(address => bool)) is_red_get;
    //red pocket passwork
    // mapping(uint => uint) pw;
    mapping(address => uint) public preMin; //pre red pocket min number
    mapping(address => string) public tokenName;

    mapping(uint => uint) public password; //red pocket passwork
    mapping(uint => mapping(address => bool)) public had_get_red; //the address is had get the redpacket?
    mapping(address => uint) user_red_pw; //user last rebpacket password
    mapping(address => uint) w_time; //the time user last write message
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
        blue[msg.sender] = true;
    }

    function setPreMin(TokenData memory tokenData) public onlyOwner {
        require(tokenData.a != address(0) && tokenData.v > 0, "value wrong");
        preMin[tokenData.a] = tokenData.v;
        tokenName[tokenData.a] = tokenData.n;
    }

    // mapping
    function setBlue(address _a, bool v, string memory id) external onlyOwner {
        require(_a != address(0), "not zero");
        require(getLen(id) <= 20, "id too long");
        blue[_a] = v;
        blueid[_a] = id;
    }

    function wMsg(Messaage memory _msg, Red memory red) public {
        require(!isContract(msg.sender), "f404:address invild");
        require(
            block.timestamp > w_time[msg.sender] + 60 * 10 ||
                msg.sender == owner,
            "b303:10 minutes one write"
        );
        require(_msg.rid == 0, "f0:_msg wrong");
        require(
            getLen(_msg.data) > 0 &&
                getLen(_msg.data) <= 270 &&
                getLen(_msg.social) <= 40,
            "f1:index out"
        );

        require(
            (red.m == 0 && red.n == 0) ||
                (red.n >= preMin[red.a] && red.m >= preMin[red.a]),
            "f2:redpocket too min"
        );
        msg_id++;
        if (red.m > 0) {
            require(preMin[red.a] > 0, "rpa err");
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
            red_msg[r_id] = msg_id;
            _msg.rid = r_id;
            _msg.ticket = block.timestamp + r_id * 111111 + msg_id * 222222;
        }
        _msg.time = block.timestamp;
        _msg.msgid = msg_id;
        _msg.isB = blue[msg.sender];
        if (_msg.isB) {
            if (getLen(blueid[msg.sender]) > 2) {
                _msg.social = blueid[msg.sender];
            }
        }
        msgs[msg_id] = _msg;
        if (msg.sender == owner) {
            admin_id++;
            admin_msg[admin_id] = msg_id;
        }
        w_time[msg.sender] = block.timestamp;

        // if (red.m > 0) {
        //     return getPW();
        // } else {
        //     return 1000000;
        // }
    }

    function getMsg(
        uint min_admin_id,
        uint min_msg_id,
        uint min_red_id
    )
        external
        view
        returns (
            Messaage[] memory messages0,
            Red[] memory reds0,
            uint min_admin_id0,
            uint min_msg_id0,
            uint min_red_id0,
            uint lucktime0
        )
    {
        if (min_msg_id + 100 < msg_id) min_msg_id = msg_id - 100;
        if (min_red_id + 50 < r_id) min_red_id = r_id - 50;
        if (min_admin_id + 15 < admin_id) min_admin_id = admin_id - 15;
        Messaage[] memory messages = new Messaage[](20);
        Red[] memory reds = new Red[](20);
        //admin message
        messages[0] = msgs[admin_msg[admin_id]];
        reds[0] = redpockets[messages[0].rid];
        if (admin_id >= 1) {
            messages[2] = msgs[admin_msg[getIndex(admin_id - 1)]];
            reds[2] = redpockets[messages[2].rid];
        }
        messages[14] = msgs[admin_msg[min_admin_id + 1]];
        reds[14] = redpockets[messages[14].rid];
        //red packet message
        messages[3] = msgs[getIndex(red_msg[getIndex(r_id)])];
        reds[3] = redpockets[messages[3].rid];
        if (r_id >= 1) {
            messages[5] = msgs[red_msg[getIndex(r_id - 1)]];
            reds[5] = redpockets[messages[5].rid];
        }

        if (r_id >= 2) {
            messages[6] = msgs[red_msg[getIndex(r_id - 2)]];
            reds[6] = redpockets[messages[6].rid];
        }

        messages[12] = msgs[red_msg[getIndex(min_red_id + 2)]];
        reds[12] = redpockets[messages[12].rid];
        messages[13] = msgs[red_msg[getIndex(min_red_id + 1)]];
        reds[13] = redpockets[messages[13].rid];
        // other messages
        messages[8] = msgs[getIndex(msg_id)];
        reds[8] = redpockets[messages[8].rid];
        if (msg_id >= 1) {
            messages[9] = msgs[getIndex(msg_id - 1)];
            reds[9] = redpockets[messages[9].rid];
        }
        if (msg_id >= 2) {
            messages[10] = msgs[getIndex(msg_id - 2)];
            reds[10] = redpockets[messages[10].rid];
        }
        if (msg_id >= 3) {
            messages[11] = msgs[getIndex(msg_id - 3)];
            reds[11] = redpockets[messages[11].rid];
        }
        if (msg_id >= 4) {
            messages[16] = msgs[getIndex(msg_id - 4)];
            reds[16] = redpockets[messages[16].rid];
        }
        messages[17] = msgs[min_msg_id + 3];
        reds[17] = redpockets[messages[17].rid];
        messages[18] = msgs[min_msg_id + 2];
        reds[18] = redpockets[messages[18].rid];
        messages[19] = msgs[min_msg_id + 1];
        reds[19] = redpockets[messages[19].rid];
        uint _luckTime = 0;
        if (luckPool[isluck[msg.sender]] > 0) {
            _luckTime = isluck[msg.sender];
        }
        return (
            messages,
            reds,
            min_admin_id + 1,
            min_msg_id + 3,
            min_red_id + 2,
            _luckTime
        );
    }

    mapping(uint => mapping(address => uint)) redget_num;

    function getRed(uint rid, uint ticket, uint pw) external returns (bool) {
        require(!isContract(msg.sender), "address invaild");
        require(redget_num[rid][msg.sender] < 6, "b601:too many try");
        require(!is_red_get[rid][msg.sender], "b600:had get");
        require(redpockets[rid].m >= redpockets[rid].n, "b602:had over");
        IQQBLock(QQBaddress).setLocked(
            msg.sender,
            block.timestamp + redget_num[rid][msg.sender] ** 2 * (60 * 10)
        );
        if (msgs[red_msg[rid]].ticket == ticket && pw == password[rid]) {
            is_red_get[rid][msg.sender] = true;
            redpockets[rid].m -= redpockets[rid].n;
            IERC20(redpockets[rid].a).transferFrom(
                address(this),
                msg.sender,
                redpockets[rid].n
            );
            return true;
        } else {
            redget_num[rid][msg.sender] += 1;

            return false;
        }
    }

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
        require(
            QQBaddress == msg.sender && QQBaddress != address(0),
            "address invaild"
        );

        if (luckTime < getLuckTime() && luckPool[luckTime] > 0) {
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
        blue[owner] = true;
        blueid[owner] = "twitter:Arb_QQ";
    }

    //-----------------------------------------------------------------------------------------
    function isContract(address a) private view returns (bool) {
        return a.code.length > 0;
    }

    function setPW() public view returns (uint) {
        return
            (block.timestamp + msg_id * 123456 + luckLength * 654321 + r_id) %
            1000000;
    }

    function getPW() public view returns (uint) {
        return password[user_red_pw[msg.sender]];
    }

    function getLen(string memory str) public pure returns (uint) {
        //return name.length
        return bytes(str).length;
    }

    function getIndex(uint index) public pure returns (uint) {
        return index > 0 ? index : 0;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IQQBLock {
    function setLocked(address from, uint time) external returns (bool);
}