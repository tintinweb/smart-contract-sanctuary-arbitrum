/**
 *Submitted for verification at Arbiscan on 2022-12-30
*/

// File: @openzeppelin/contracts/utils/Address.sol

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

library Address {
 
    function isContract(address account) internal view returns (bool) {
 
        return account.code.length > 0;
    }


    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

 
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }


    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }


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

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

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
}

pragma solidity ^0.8.0;

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

pragma solidity ^0.8.0;

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {

        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
}

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.8.0;

error IncorrectPrice();

contract ArbitrumTokenBundles is Ownable, ReentrancyGuard {
    using Address for address;

    IERC20[] public tokens;
    uint256[] public amounts;
    uint256 public price = 0.0095 ether;

    constructor() {
        // DBL
        tokens.push(IERC20(0xd3f1Da62CAFB7E7BC6531FF1ceF6F414291F03D3));
        amounts.push(0.01 ether);

        // DPX
        tokens.push(IERC20(0x6C2C06790b3E3E3c38e12Ee22F8183b37a13EE55));
        amounts.push(0.0001 ether);

        // LPT
        tokens.push(IERC20(0x289ba1701C2F088cf0faf8B3705246331cB8A839));
        amounts.push(0.001 ether);
        
        // PLS
        tokens.push(IERC20(0x51318B7D00db7ACc4026C88c3952B66278B6A67F));
        amounts.push(0.001 ether);

        // MAGIC
        tokens.push(IERC20(0x539bdE0d7Dbd336b79148AA742883198BBF60342));
        amounts.push(0.001 ether);

        // LINK
        tokens.push(IERC20(0xf97f4df75117a78c1A5a0DBb814Af92458539FB4));
        amounts.push(0.001 ether);

        // UMAMI
        tokens.push(IERC20(0x1622bF67e6e5747b81866fE0b85178a93C7F86e3));
        amounts.push(1000000);

        // MYC
        tokens.push(IERC20(0xC74fE4c715510Ec2F8C61d70D397B32043F55Abe));
        amounts.push(0.01 ether);

        // VSTA
        tokens.push(IERC20(0xa684cd057951541187f288294a1e1C2646aA2d24));
        amounts.push(0.01 ether);

        // JONES
        tokens.push(IERC20(0x10393c20975cF177a3513071bC110f7962CD67da));
        amounts.push(0.001 ether);

        // SPA
        tokens.push(IERC20(0x5575552988A3A80504bBaeB1311674fCFd40aD4B));
        amounts.push(0.01 ether);

        // GMX
        tokens.push(IERC20(0xfc5A1A6EB076a2C7aD06eD22C90d7E710E35ad0a));
        amounts.push(0.001 ether);

        // SYN
        tokens.push(IERC20(0x080F6AEd32Fc474DD5717105Dba5ea57268F46eb));
        amounts.push(0.01 ether);

        // BRC
        tokens.push(IERC20(0xB5de3f06aF62D8428a8BF7b4400Ea42aD2E0bc53));
        amounts.push(0.01 ether);

        // HOP-LP-USDC
        tokens.push(IERC20(0xB67c014FA700E69681a673876eb8BAFAA36BFf71));
        amounts.push(0.01 ether);

        // DODO
        tokens.push(IERC20(0x69Eb4FA4a2fbd498C257C57Ea8b7655a2559A581));
        amounts.push(0.01 ether);

        // IZI
        tokens.push(IERC20(0x60D01EC2D5E98Ac51C8B4cF84DfCCE98D527c747));
        amounts.push(0.01 ether);

        // IMO
        tokens.push(IERC20(0xB41bd4C99dA73510d9e081C5FADBE7A27Ac1F814));
        amounts.push(0.01 ether);

        // UNI
        tokens.push(IERC20(0xFa7F8980b0f1E64A2062791cc3b0871572f1F7f0));
        amounts.push(0.001 ether);

        // SUSHI
        tokens.push(IERC20(0xd4d42F0b6DEF4CE0383636770eF773390d85c61A));
        amounts.push(0.001 ether);

        // SLP SUSHI-ETH
        tokens.push(IERC20(0x3221022e37029923aCe4235D812273C5A42C322d));
        amounts.push(0.0001 ether);
   
    }

    function addToken(IERC20 token, uint256 amount) external onlyOwner {
        tokens.push(token);
        amounts.push(amount);
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function purchaseTokens() external payable nonReentrant {
        if (msg.value != price) revert IncorrectPrice();

        uint256 tokensLength = tokens.length;
        for (uint256 i; i < tokensLength;) {
            tokens[i].transfer(msg.sender, amounts[i]);
            unchecked { ++i; }
        }
    }

    function withdrawAllTokens() external onlyOwner {
        uint256 tokensLength = tokens.length;
        for (uint256 i; i < tokensLength;) {
            tokens[i].transfer(msg.sender, tokens[i].balanceOf(address(this)));
            unchecked { ++i; }
        }
    }

    function withdrawETH() external onlyOwner {
        Address.sendValue(payable(msg.sender), address(this).balance);
    }
}