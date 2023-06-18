/**
 *Submitted for verification at Arbiscan on 2023-06-18
*/

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.19;

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
        
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function mint(address recipient, uint256 amount) external;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract DBXICO is Ownable {
    uint256 public price = 50000;
    uint256 public softCap = 50000 * (10**6);
    uint256 public hardCap = 187500 * (10**6);
    uint256 public totalSupplied = 0;
    uint256 public timeStarted = 0;
    uint256 public whitelistLength = 86400;
    uint256 public publicLength = 172800;
    bool public released = false;
    uint256 public totalClaimed = 0;

    address multisig = 0xc1e351b1156b55a611b77e2bF3B60DED44db28b3;

    address DBX = 0x0b257fe969d8782fAcb4ec790682C1d4d3dF1551;
    address USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;

    mapping (address => uint256) public userDeposited;
    mapping (address => bool) public whitelisted;

    function setTimeToStart(uint256 amount, bool secs) public onlyOwner {
        if (secs) {
            timeStarted = block.timestamp + amount;
        } else {
            timeStarted = amount;
        }
    }

    function addWallet(address account) public onlyOwner {
        whitelisted[account] = true;
    }

    function removeWallet(address account) public onlyOwner {
        whitelisted[account] = false;
    }

    function massAddWallets(address[] memory accounts) public onlyOwner {
        for(uint i = 0; i < accounts.length; i++) {
            addWallet(accounts[i]);
        }
    }

    function massRemoveWallets(address[] memory accounts) public onlyOwner {
        for(uint i = 0; i < accounts.length; i++) {
            removeWallet(accounts[i]);
        }
    }

    function releaseFunds() public onlyOwner {
        require(!released, "already released");
        if(totalSupplied >= softCap) {
            IERC20(DBX).mint(address(this), convertTokens(totalSupplied));
            IERC20(USDC).transfer(multisig, IERC20(USDC).balanceOf(address(this)));
        }
        released = true;
    }

    function deposit(uint256 amount) public {
        require(timeStarted > 0, "not started");
        require(whitelisted[msg.sender] == true || (block.timestamp > (timeStarted + whitelistLength)), "not whitelisted");
        require(block.timestamp < (timeStarted + whitelistLength + publicLength), "finished");
        require(!released, "finished");
        require(IERC20(USDC).balanceOf(msg.sender) >= amount, "bal low");
        require(IERC20(USDC).allowance(msg.sender, address(this)) >= amount, "low allowance");
        require(totalSupplied + amount <= hardCap, "not enough tokens left");
        IERC20(USDC).transferFrom(msg.sender, address(this), amount);
        userDeposited[msg.sender] += amount;
        totalSupplied += amount;
    }

    function withdraw() public {
        require(timeStarted > 0, "not started");
        require(block.timestamp >= (timeStarted + whitelistLength + publicLength), "not finished");
        require(released, "funds not released yet");
        require(userDeposited[msg.sender] > 0, "nothing to withdraw");
        if (totalSupplied < softCap) {
            IERC20(USDC).transfer(msg.sender, userDeposited[msg.sender]);
            totalClaimed += userDeposited[msg.sender];
        } else {
            uint256 amount = convertTokens(userDeposited[msg.sender]);
            IERC20(DBX).transfer(msg.sender, amount);
            totalClaimed += amount;
        }
        userDeposited[msg.sender] = 0;
    }

    function getTokens(address account) public view returns (uint256) {
        return convertTokens(userDeposited[account]);
    }

    function convertTokens(uint256 amount) internal view returns (uint256) {
        return (amount * (10 ** 18)) / price;
    }
}