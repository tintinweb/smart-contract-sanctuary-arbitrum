/**
 *Submitted for verification at Arbiscan on 2023-03-01
*/

// Sources flattened with hardhat v2.12.7 https://hardhat.org

// File @pefish/solidity-lib/contracts/interface/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IErc20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function balanceOf(address guy) external view returns (uint256);
    function allowance(address src, address guy) external view returns (uint256);

    function approve(address guy, uint256 wad) external returns (bool);
    function transfer(address dst, uint256 wad) external returns (bool);
    function transferFrom(
        address src, address dst, uint256 wad
    ) external returns (bool);

//    function mint(address account, uint256 amount) external returns (bool);
//    function burn(uint256 amount) external returns (bool);

    event Approval(address indexed src, address indexed guy, uint256 wad);
    event Transfer(address indexed src, address indexed dst, uint256 wad);
}


// File @pefish/solidity-lib/contracts/library/[email protected]



pragma solidity >=0.8.0;

library SafeToken {
  function myBalance(address token) internal view returns (uint256) {
    return IErc20(token).balanceOf(address(this));
  }

  function balanceOf(address token, address user) internal view returns (uint256) {
    return IErc20(token).balanceOf(user);
  }

  function safeApprove(address token, address to, uint256 value) internal {
    // bytes4(keccak256(bytes('approve(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeApprove");
  }

  function safeTransfer(address token, address to, uint256 value) internal {
    // bytes4(keccak256(bytes('transfer(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransfer");
  }

  function safeTransferFrom(address token, address from, address to, uint256 value) internal {
    // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransferFrom");
  }

  function safeTransferETH(address to, uint256 value) internal {
    // solhint-disable-next-line no-call-value
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, "!safeTransferETH");
  }
}


// File @pefish/solidity-lib/contracts/contract/[email protected]



pragma solidity >=0.8.0;

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly {cs := extcodesize(self)}
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}


// File @pefish/solidity-lib/contracts/contract/[email protected]



pragma solidity >=0.8.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev init function sets the original `owner` of the contract to the sender
     * account.
     */
    function __Ownable_init () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "only owner");
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// File @pefish/solidity-lib/contracts/contract/[email protected]



pragma solidity >=0.8.0;


contract ReentrancyGuard {
  bool private _notEntered;

  function __ReentrancyGuard_init () internal {
    _notEntered = true;
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
    require(_notEntered, "ReentrancyGuard: reentrant call");

    // Any calls to nonReentrant after this point will fail
    _notEntered = false;

    _;

    // By storing the original value once again, a refund is triggered (see
    // https://eips.ethereum.org/EIPS/eip-2200)
    _notEntered = true;
  }
}


// File contracts/last-presale/last_presale.sol


pragma solidity ^0.8.0;





contract LastPresale is Ownable, Initializable, ReentrancyGuard {
    event Buy(address indexed user, uint256 amount);

    mapping(address => uint256) public prices; // with decimals
    address payable public foundation;
    IErc20 public tokenAddress;
    bool public isPause = false;

    function init(address _tokenAddress, address _foundation)
        external
        initializer
    {
        ReentrancyGuard.__ReentrancyGuard_init();
        Ownable.__Ownable_init();

        foundation = payable(_foundation);
        tokenAddress = IErc20(_tokenAddress);
    }

    function buy(uint256 amount, address _baseToken) external payable {
        require(
            prices[_baseToken] > 0,
            "Presale::buy:: price must larger than 0"
        );
        require(!isPause, "Presale::buy:: is paused");

        uint256 limitedToken = (3 * (10**18)) / prices[address(0)];
        require(amount <= limitedToken, "Presale::buy:: limit quota");

        uint256 need = amount * prices[_baseToken];
        if (_baseToken == address(0)) {
            // ETH
            foundation.transfer(need);
            payable(msg.sender).transfer(msg.value - need);
        } else {
            // ERC20
            SafeToken.safeTransferFrom(
                _baseToken,
                msg.sender,
                foundation,
                need
            );
        }
        SafeToken.safeTransfer(
            address(tokenAddress),
            address(msg.sender),
            amount * (10**tokenAddress.decimals())
        );
        emit Buy(msg.sender, amount);
    }

    function setPrice(address _baseToken, uint256 _price) external onlyOwner {
        prices[_baseToken] = _price;
    }

    function pause() external onlyOwner {
        isPause = true;
    }

    function setTokenAddress(address _tokenAddress) external onlyOwner {
        tokenAddress = IErc20(_tokenAddress);
    }
}