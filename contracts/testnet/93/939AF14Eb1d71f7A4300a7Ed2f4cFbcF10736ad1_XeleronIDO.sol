/**
 *Submitted for verification at Arbiscan on 2023-07-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

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

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

interface IOwnable {
    function owner() external view returns (address);

    function renounceOwnership() external;

    function transferOwnership(address newOwner_) external;
}

contract Ownable is IOwnable {
    address internal _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view override returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual override onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner_)
    public
    virtual
    override
    onlyOwner
    {
        require(newOwner_ != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner_);
        _owner = newOwner_;
    }
}

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

    constructor () internal {
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
}

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint value) external returns (bool);

    function withdraw(uint) external;

    function decimals() external view returns (uint8);
}

contract XeleronIDO is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    //token
    address public PayOutToken;


    //amount
    uint256 public MaxIDOPayInAmount = 100000000000000000000; // 100.00 ETH
    uint256 public receivedIDOPayInAmount;

    uint256 public MinPrivateSaleSinglePayInAmount = 1000000000000000; // 0.001 ETH
    uint256 public MaxPrivateSaleSinglePayInAmount = 1000000000000000000; // 1 ETH
    mapping(address => uint256) public privateSalePayInAmountCounter;
    mapping(address => uint256) public privateSalePurchaseAmount;


    uint256 public MinPublicSaleSinglePayInAmount = 1000000000000000; // 0.001 ETH
    uint256 public MaxPublicSaleSinglePayInAmount = 1000000000000000000; // 1 ETH
    mapping(address => uint256) public publicSalePayInAmountCounter;
    mapping(address => uint256) public publicSalePurchaseAmount;


    uint256 public PrivateSaleStartTime;
    uint256 public PrivateSaleEndTime;
    uint256 public PublicSaleStartTime;
    uint256 public PublicSaleEndTime;

    address public weth;

    //price
    uint256 public Price = 200000000000000; // 0.000200 ETH per XLR


    //switch
    bool public saleStarted;

    function initialize(
        address _weth,
        address _PayOutToken,

        uint256 _PrivateSaleStartTime,
        uint256 _PrivateSaleEndTime,
        uint256 _PublicSaleStartTime,
        uint256 _PublicSaleEndTime
    ) external onlyOwner returns (bool) {
        require(_PrivateSaleStartTime >= block.timestamp, "_PrivateSlaeStartTime error");
        require(_PrivateSaleEndTime >= _PrivateSaleStartTime, "_PrtivateSlaeEndTime error");
        require(_PublicSaleStartTime >= _PublicSaleEndTime, "_PublicSaleStartTime error");
        require(_PublicSaleEndTime >= _PublicSaleStartTime, "_PublicSaleEndTime error");

        weth = _weth;
        PayOutToken = _PayOutToken;
        PrivateSaleStartTime = _PrivateSaleStartTime;
        PrivateSaleEndTime = _PrivateSaleEndTime;
        PublicSaleStartTime = _PublicSaleStartTime;
        PublicSaleEndTime = _PublicSaleEndTime;


        saleStarted = true;
        return true;
    }

    function setStart() external onlyOwner returns (bool) {
        saleStarted = !saleStarted;
        return saleStarted;
    }


    function calPayOut(uint256 _payInAmount) public view returns (uint256) {
        return _payInAmount.mul(10 ** 18).div(Price);
    }


    function privatteSale(uint256 amount) internal {
    if (privateSalePayInAmountCounter[msg.sender] == 0) {
        require(amount >= MinPrivateSaleSinglePayInAmount, "privateSale Minimum buy error");
    } else if (privateSalePayInAmountCounter[msg.sender] < MinPrivateSaleSinglePayInAmount) {
        require(amount >= MinPrivateSaleSinglePayInAmount.sub(privateSalePayInAmountCounter[msg.sender]), "privateSale Minimum buy error");
    }
    require(MaxPrivateSaleSinglePayInAmount >= amount + privateSalePayInAmountCounter[msg.sender], "privateSale Maximum buy error");

    uint256 payOutAmount = calPayOut(amount);

    IWETH(weth).deposit{value: amount}();
    assert(IWETH(weth).transfer(address(this), amount));

    //transfer PayOutToken
    IERC20(PayOutToken).safeTransfer(msg.sender, payOutAmount);
    privateSalePurchaseAmount[msg.sender] = privateSalePurchaseAmount[msg.sender].add(payOutAmount);

    privateSalePayInAmountCounter[msg.sender] = privateSalePayInAmountCounter[msg.sender].add(amount);
}


    function publiccSale(uint256 amount) internal {
    if (publicSalePayInAmountCounter[msg.sender] == 0) {
        require(amount >= MinPublicSaleSinglePayInAmount, "publicSale Minimum buy error");
    } else if (publicSalePayInAmountCounter[msg.sender] < MinPublicSaleSinglePayInAmount) {
        require(amount >= MinPublicSaleSinglePayInAmount.sub(publicSalePayInAmountCounter[msg.sender]), "publicSale Minimum buy error");
    }
    require(MaxPublicSaleSinglePayInAmount >= amount + publicSalePayInAmountCounter[msg.sender], "publicSale Maximum buy error");

    uint256 payOutAmount = calPayOut(amount);

    IWETH(weth).deposit{value: amount}();
    assert(IWETH(weth).transfer(address(this), amount));

    //transfer PayOutToken
    IERC20(PayOutToken).safeTransfer(msg.sender, payOutAmount);
    publicSalePurchaseAmount[msg.sender] = publicSalePurchaseAmount[msg.sender].add(payOutAmount);

    publicSalePayInAmountCounter[msg.sender] = publicSalePayInAmountCounter[msg.sender].add(amount);
}



    function buy() nonReentrant payable public {
        uint256 payInEthAmount = msg.value;

        require(saleStarted, "IDO is upcoming");
        require(block.timestamp > PublicSaleStartTime, "IDO round1 is upcoming");
        require(block.timestamp <= PublicSaleEndTime, "IDO is closed");
        require(
            receivedIDOPayInAmount.add(payInEthAmount) <= MaxIDOPayInAmount,
            "Amount exceed the Fundraise Goal"
        );

        if (block.timestamp >= PrivateSaleStartTime && block.timestamp <= PrivateSaleEndTime) {
            privatteSale(payInEthAmount);
        } else if (block.timestamp >= PublicSaleStartTime && block.timestamp <= PublicSaleEndTime) {
            publiccSale(payInEthAmount);
        } else {
            revert("IDO round2 is upcoming");
        }

        receivedIDOPayInAmount += payInEthAmount;
    }


    function withdraw(
        address _erc20,
        address _to,
        uint256 _val
    ) external onlyOwner returns (bool) {
        IERC20(_erc20).safeTransfer(_to, _val);
        return true;
    }

    function withdrawETH(address payable recipient) external onlyOwner {
        (bool success,) = recipient.call{value: address(this).balance}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }


    //set IDOList time
    function setIDOTime(
        uint256 _PrivStartTime,
        uint256 _PrivEndTime,
        uint256 _PubStartTime,
        uint256 _PubEndTime
    ) external onlyOwner returns (bool) {
        require(_PrivStartTime >= block.timestamp, "_PrivStartTime error");
        require(_PrivEndTime >= _PrivStartTime, "_PrivEndTime error");
        require(_PubStartTime >= _PrivEndTime, "_PubStartTime error");
        require(_PubEndTime >= _PubStartTime, "_PubEndTime error");

        PrivateSaleStartTime = _PrivStartTime;
        PrivateSaleEndTime = _PrivEndTime;
        PublicSaleStartTime = _PubStartTime;
        PublicSaleEndTime = _PubEndTime;

        return true;
    }

    //set MaxIDOPayInAmount
    function setMaxIDOPayInAmount(uint256 _MaxIDOPayInAmount) external onlyOwner returns (bool) {
        MaxIDOPayInAmount = _MaxIDOPayInAmount;
        return true;
    }

    //set WitheListOne limit
    function setPrivateSaleLimit(uint256 _MinPrivateSaleSinglePayInAmount, uint256 _MaxPrivateSaleSinglePayInAmount) external onlyOwner returns (bool) {
        require(_MinPrivateSaleSinglePayInAmount > 0, "MinPrivateSaleSinglePayInAmount error");
        require(_MaxPrivateSaleSinglePayInAmount > _MinPrivateSaleSinglePayInAmount, "MaxPrivateSaleSinglePayInAmount error");
        MinPrivateSaleSinglePayInAmount = _MinPrivateSaleSinglePayInAmount;
        MaxPrivateSaleSinglePayInAmount = _MaxPrivateSaleSinglePayInAmount;
        return true;
    }

    //set WitheListTwo limit
    function setPublicSalewLimit(uint256 _MinPublicSaleSinglePayInAmount, uint256 _MaxPublicSaleSinglePayInAmount) external onlyOwner returns (bool) {
        require(_MinPublicSaleSinglePayInAmount > 0, "MinPublicSaleSinglePayInAmount error");
        require(_MaxPublicSaleSinglePayInAmount > _MinPublicSaleSinglePayInAmount, "MaxPublicSaleSinglePayInAmount error");
        MinPublicSaleSinglePayInAmount = _MinPublicSaleSinglePayInAmount;
        MaxPublicSaleSinglePayInAmount = _MaxPublicSaleSinglePayInAmount;
        return true;
    }

    //set price
    function setPrice(uint256 _price) external onlyOwner returns (bool) {
        require(_price > 0, "price error");
        Price = _price;
        return true;
    }

}