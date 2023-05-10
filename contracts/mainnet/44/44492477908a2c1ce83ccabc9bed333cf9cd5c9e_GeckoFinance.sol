/**
 *Submitted for verification at Arbiscan on 2023-05-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call(data);

        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );

        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    function contains(
        address[] storage haystack,
        address needle
    ) internal view returns (bool) {
        uint256 length = haystack.length;
        for (uint256 i = 0; i < length; i++) {
            if (haystack[i] == needle) {
                return true;
            }
        }
        return false;
    }
}

contract GeckoFinance {
    using SafeMath for uint256;
    using Address for address payable;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    address private Admin;
    address[] private admins;
    uint8 private _reflectionFee;
    uint8 private _taxFee;
    //anyswap
    address public immutable underlying;
    //
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 private _totalFees;
    mapping(address => uint256) private _reflections;

    address public LpAccount;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 _supply,
        address _lpaccount,
        uint8 _refFee,
        uint8 _txFee
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
        _reflectionFee = _refFee;
        _taxFee = _txFee;
        underlying = address(0);
        uint256 initialSupply = _supply * 10 ** decimals();
        Admin = msg.sender;
        admins.push(msg.sender);
        LpAccount = _lpaccount;
        _mint(_msgSender(), initialSupply);
        _totalFees = 0;
        _reflections[_msgSender()] = initialSupply;
    }

    modifier onlyOwner() {
        require(msg.sender == Admin, "Only Admin");
        _;
    }

    modifier onlyAuth() {
        require(
            Address.contains(admins, msg.sender),
            "Only admins can call this function"
        );
        _;
    }

    function changeReflectionFee(uint8 _fee) public onlyOwner {
        require(_fee <= 10, "Max 10");
        _reflectionFee = _fee;
    }

    function addAdmin(address _mntr) public onlyOwner {
        admins.push(_mntr);
    }

    function changeTaxFee(uint8 _fee) public onlyOwner {
        require(_fee <= 5, "Max 5");
        _taxFee = _fee;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        if (_reflections[account] == 0) return 0;
        return
            _reflections[account].add(
                _reflections[account].mul(_totalFees).div(totalSupply())
            );
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _approve(sender, _msgSender(), currentAllowance.sub(amount));

        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        _approve(_msgSender(), spender, currentAllowance.sub(subtractedValue));

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 reflectionFee = amount.mul(_reflectionFee).div(100); // Calculate % reflection fee
        uint256 taxFee = amount.mul(_taxFee).div(100); // Calculate % tax fee
        _totalFees = _totalFees.add(reflectionFee);
        uint256 totalFees = reflectionFee.add(taxFee);
        uint256 netAmount = amount.sub(totalFees);
        // Update sender's reflection balance
        _reflections[sender] = _reflections[sender].sub(amount);
        _reflections[recipient] = _reflections[recipient].add(netAmount);
        _reflections[LpAccount] = _reflections[LpAccount].add(taxFee);

        _balances[sender] = _balances[sender].sub(amount);
        _balances[LpAccount] = _balances[LpAccount].add(taxFee);
        _balances[recipient] = _balances[recipient].add(netAmount);
        emit Transfer(sender, LpAccount, taxFee);
        emit Transfer(sender, recipient, netAmount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        _reflections[account] = _reflections[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(
            _reflections[account] >= amount,
            "ERC20: burn amount exceeds balance"
        );
        _reflections[account] = _reflections[account].sub(amount);
        _balances[account] = _balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    ///anyswap intigration
    function mint(address to, uint256 amount) external onlyAuth returns (bool) {
        _mint(to, amount);
        return true;
    }
    function burn(
        address from,
        uint256 amount
    ) external onlyAuth returns (bool) {
        require(from != address(0), "AnyswapV3ERC20: address(0x0)");
        _burn(from, amount);
        return true;
    }
}