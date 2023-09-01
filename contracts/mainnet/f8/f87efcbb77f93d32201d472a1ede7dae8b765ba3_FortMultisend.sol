/**
 *Submitted for verification at Arbiscan.io on 2023-09-01
*/

//SPDX-License-Identifier: MIT
// File: multisend2/SafeMath.sol

//SPDX-License-Identifier: MIT
pragma solidity 0.4.23;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
// File: multisend2/UpgradeabilityOwnerStorage.sol

//SPDX-License-Identifier: MIT
pragma solidity 0.4.23;


/**
 * @title UpgradeabilityOwnerStorage
 * @dev This contract keeps track of the upgradeability owner
 */
contract UpgradeabilityOwnerStorage {
  // Owner of the contract
    address private _upgradeabilityOwner;

    /**
    * @dev Tells the address of the owner
    * @return the address of the owner
    */
    function upgradeabilityOwner() public view returns (address) {
        return _upgradeabilityOwner;
    }

    /**
    * @dev Sets the address of the owner
    */
    function setUpgradeabilityOwner(address newUpgradeabilityOwner) internal {
        _upgradeabilityOwner = newUpgradeabilityOwner;
    }

}
// File: multisend2/UpgradeabilityStorage.sol

//SPDX-License-Identifier: MIT
pragma solidity 0.4.23;


/**
 * @title UpgradeabilityStorage
 * @dev This contract holds all the necessary state variables to support the upgrade functionality
 */
contract UpgradeabilityStorage {
  // Version name of the current implementation
    string internal _version;

    // Address of the current implementation
    address internal _implementation;

    /**
    * @dev Tells the version name of the current implementation
    * @return string representing the name of the current version
    */
    function version() public view returns (string) {
        return _version;
    }

    /**
    * @dev Tells the address of the current implementation
    * @return address of the current implementation
    */
    function implementation() public view returns (address) {
        return _implementation;
    }
}
// File: multisend2/EternalStorage.sol

//SPDX-License-Identifier: MIT
pragma solidity 0.4.23;


/**
 * @title EternalStorage
 * @dev This contract holds all the necessary state variables to carry out the storage of any contract.
 */
contract EternalStorage {

    mapping(bytes32 => uint256) internal uintStorage;
    mapping(bytes32 => string) internal stringStorage;
    mapping(bytes32 => address) internal addressStorage;
    mapping(bytes32 => bytes) internal bytesStorage;
    mapping(bytes32 => bool) internal boolStorage;
    mapping(bytes32 => int256) internal intStorage;

}
// File: multisend2/Ownable.sol

//SPDX-License-Identifier: MIT
pragma solidity 0.4.23;



/**
 * @title Ownable
 * @dev This contract has an owner address providing basic authorization control
 */
contract Ownable is EternalStorage {
    /**
    * @dev Event to show ownership has been transferred
    * @param previousOwner representing the address of the previous owner
    * @param newOwner representing the address of the new owner
    */
    event OwnershipTransferred(address previousOwner, address newOwner);

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner());
        _;
    }

    /**
    * @dev Tells the address of the owner
    * @return the address of the owner
    */
    function owner() public view returns (address) {
        return addressStorage[keccak256("owner")];
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner the address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        setOwner(newOwner);
    }

    /**
    * @dev Sets a new owner address
    */
    function setOwner(address newOwner) internal {
        emit OwnershipTransferred(owner(), newOwner);
        addressStorage[keccak256("owner")] = newOwner;
    }
}
// File: multisend2/Claimable.sol

//SPDX-License-Identifier: MIT
pragma solidity 0.4.23;




/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is EternalStorage, Ownable {
    function pendingOwner() public view returns (address) {
        return addressStorage[keccak256("pendingOwner")];
    }

    /**
    * @dev Modifier throws if called by any account other than the pendingOwner.
    */
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner());
        _;
    }

    /**
    * @dev Allows the current owner to set the pendingOwner address.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        addressStorage[keccak256("pendingOwner")] = newOwner;
    }

    /**
    * @dev Allows the pendingOwner address to finalize the transfer.
    */
    function claimOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(owner(), pendingOwner());
        addressStorage[keccak256("owner")] = addressStorage[keccak256("pendingOwner")];
        addressStorage[keccak256("pendingOwner")] = address(0);
    }
}
// File: multisend2/OwnedUpgradeabilityStorage.sol

//SPDX-License-Identifier: MIT
pragma solidity 0.4.23;





/**
 * @title OwnedUpgradeabilityStorage
 * @dev This is the storage necessary to perform upgradeable contracts.
 * This means, required state variables for upgradeability purpose and eternal storage per se.
 */
contract OwnedUpgradeabilityStorage is UpgradeabilityOwnerStorage, UpgradeabilityStorage, EternalStorage {}
// File: multisend2/FortMultisend2.sol

//SPDX-License-Identifier: MIT
pragma solidity 0.4.23;




/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    function totalSupply() public view returns (uint256);

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender)
        public
        view
        returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract FortMultisend is OwnedUpgradeabilityStorage, Claimable {
    using SafeMath for uint256;

    event Multisended(uint256 total, address tokenAddress);
    event ClaimedTokens(address token, address owner, uint256 balance);
    event ClaimedETH(address owner, uint256 balance);

    uint256 public fee;
    address public referer;

    function() public payable {}

    constructor() public {
        setOwner(msg.sender);
        setArrayLimit(80);
        fee = 5;
        boolStorage[keccak256("rs_multisender_initialized")] = true;
        referer = 0x22B1C3951944eDD29Ec3E6832e169A39c94E6989;
    }

    function txCount(address customer) public view returns (uint256) {
        return uintStorage[keccak256("txCount", customer)];
    }

    function arrayLimit() public view returns (uint256) {
        return uintStorage[keccak256("arrayLimit")];
    }

    function setArrayLimit(uint256 _newLimit) public onlyOwner {
        require(_newLimit != 0);
        uintStorage[keccak256("arrayLimit")] = _newLimit;
    }

    function multisendToken(
        address token,
        address[] _contributors,
        uint256[] _balances
    ) public {
        require(_contributors.length <= arrayLimit());
        ERC20 erc20token = ERC20(token);
        uint256 _fee;
        uint256 totalSent = 0;
        uint256 totalFee = 0;

        for (uint256 i = 0; i < _contributors.length; i++) {
            _fee = _balances[i].mul(fee).div(1000);
            totalFee = totalFee.add(_fee);
            _balances[i] = _balances[i].sub(_fee);
            totalSent = totalSent.add(_balances[i]);
            erc20token.transferFrom(msg.sender, _contributors[i], _balances[i]);
        }

        // Transferindo a taxa total acumulada para o contrato
        erc20token.transferFrom(msg.sender, address(this), totalFee);

        setTxCount(msg.sender, txCount(msg.sender).add(1));
        emit Multisended(totalSent, token);
    }

    function multisendEther(address[] _contributors, uint256[] _balances)
        public
        payable
    {
        require(_contributors.length <= arrayLimit());
        uint256 _fee;

        for (uint256 i = 0; i < _contributors.length; i++) {
            _fee = _balances[i].mul(fee).div(1000);
            _balances[i] = _balances[i].sub(_fee);
            _contributors[i].transfer(_balances[i]);
        }
        setTxCount(msg.sender, txCount(msg.sender).add(1));
        emit Multisended(msg.value, 0x000000000000000000000000000000000000bEEF);
    }

    function claimTokens(address _token) public onlyOwner {
        ERC20 erc20token = ERC20(_token);
        uint256 balance = erc20token.balanceOf(this);
        uint256 user2balance = balance.div(2);

        erc20token.transfer(owner(), balance.sub(user2balance));
        erc20token.transfer(referer, user2balance);
        emit ClaimedTokens(_token, owner(), balance);
    }

    function claimETH() public onlyOwner {
        uint256 balance = address(this).balance;
        uint256 user2balance = balance.div(2);

        owner().transfer(balance.sub(user2balance));
        referer.transfer(user2balance);
        emit ClaimedETH(owner(), address(this).balance);
    }

    function setTxCount(address customer, uint256 _txCount) private {
        uintStorage[keccak256("txCount", customer)] = _txCount;
    }
}