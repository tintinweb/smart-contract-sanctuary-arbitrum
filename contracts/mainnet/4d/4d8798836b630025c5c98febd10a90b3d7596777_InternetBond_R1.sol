// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import "../interfaces/IERC20.sol";
import "../interfaces/IInternetBondRatioFeed.sol";
import "./SimpleToken_R1.sol";
import "../libraries/Utils.sol";

contract InternetBond_R1 is SimpleToken_R1, IERC20InternetBond {

    IInternetBondRatioFeed public ratioFeed;
    bool internal _rebasing;

    function ratio() public view override returns (uint256) {
        return ratioFeed.getRatioFor(_originAddress);
    }

    function isRebasing() public view override returns (bool) {
        return _rebasing;
    }

    function totalSupply() public view override returns (uint256) {
        return _sharesToBonds(super.totalSupply());
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _sharesToBonds(super.balanceOf(account));
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        uint256 shares = _bondsToShares(amount);
        _transfer(_msgSender(), recipient, shares, false);
        emit Transfer(_msgSender(), recipient, _sharesToBonds(shares));
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _sharesToBonds(super.allowance(owner, spender));
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        uint256 shares = _bondsToShares(amount);
        _approve(_msgSender(), spender, shares, false);
        emit Approval(_msgSender(), spender, allowance(_msgSender(), spender));
        return true;
    }

    function increaseAllowance(address spender, uint256 amount) public override returns (bool) {
        uint256 shares = _bondsToShares(amount);
        _increaseAllowance(_msgSender(), spender, shares, false);
        emit Approval(_msgSender(), spender, allowance(_msgSender(), spender));
        return true;
    }

    function decreaseAllowance(address spender, uint256 amount) public override returns (bool) {
        uint256 shares = _bondsToShares(amount);
        _decreaseAllowance(_msgSender(), spender, shares, false);
        emit Approval(_msgSender(), spender, allowance(_msgSender(), spender));
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 shares = _bondsToShares(amount);
        _transfer(sender, recipient, shares, false);
        emit Transfer(sender, recipient, _sharesToBonds(shares));
        _decreaseAllowance(sender, _msgSender(), shares, false);
        emit Approval(sender, _msgSender(), allowance(sender, _msgSender()));
        return true;
    }

    // NB: mint accepts amount in shares
    function mint(address account, uint256 shares) public onlyOwner override {
        require(account != address(0));
        _totalSupply += shares;
        _balances[account] += shares;
        emit Transfer(address(0), account, _sharesToBonds(shares));
    }

    // NB: burn accepts amount in shares
    function burn(address account, uint256 shares) public onlyOwner override {
        require(account != address(0));
        _balances[account] -= shares;
        _totalSupply -= shares;
        emit Transfer(account, address(0), _sharesToBonds(shares));
    }

    function _sharesToBonds(uint256 amount) internal view returns (uint256) {
        if (_rebasing) {
            uint256 currentRatio = ratio();
            require(currentRatio > 0, "ratio not available");
            return Utils.multiplyAndDivideCeil(amount, 10 ** decimals(), currentRatio);
        } else {
            return amount;
        }
    }

    function _bondsToShares(uint256 amount) internal view returns (uint256) {
        if (_rebasing) {
            uint256 currentRatio = ratio();
            require(currentRatio > 0, "ratio not available");
            return Utils.multiplyAndDivideFloor(amount, currentRatio, 10 ** decimals());
        } else {
            return amount;
        }
    }

    function initAndObtainOwnership(bytes32 symbol, bytes32 name, uint256 originChain, address originAddress, address ratioFeedAddress, bool rebasing) external emptyOwner {
        super.initAndObtainOwnership(symbol, name, originChain, originAddress);
        require(ratioFeedAddress != address(0x0), "no ratio feed");
        ratioFeed = IInternetBondRatioFeed(ratioFeedAddress);
        _rebasing = rebasing;
    }
}

contract InternetBondFactory_R1 {
    address private _template;
    constructor() {
        _template = InternetBondFactoryUtils_R1.deployInternetBondTemplate(this);
    }

    function getImplementation() public view returns (address) {
        return _template;
    }
}

library InternetBondFactoryUtils_R1 {

    bytes32 constant internal INTERNET_BOND_TEMPLATE_SALT = keccak256("InternetBondTemplateV2");

    bytes constant internal INTERNET_BOND_TEMPLATE_BYTECODE = hex"608060405234801561001057600080fd5b50611216806100206000396000f3fe608060405234801561001057600080fd5b50600436106101425760003560e01c806371ca337d116100b857806395d89b411161007c57806395d89b411461029f5780639dc29fac146102a7578063a457c2d7146102ba578063a9059cbb146102cd578063dd62ed3e146102e0578063df1f29ee146102f357600080fd5b806371ca337d14610233578063898855ed1461023b5780638da5cb5b1461024e5780638e29ebb51461027957806394bfed881461028c57600080fd5b8063265535671161010a57806326553567146101c6578063313ce567146101d957806339509351146101e857806340c10f19146101fb5780635dfba1151461020e57806370a082311461022057600080fd5b806306fdde0314610147578063095ea7b31461016557806318160ddd146101885780631ad8fde61461019e57806323b872dd146101b3575b600080fd5b61014f610316565b60405161015c9190610f7e565b60405180910390f35b610178610173366004610e2e565b610328565b604051901515815260200161015c565b610190610384565b60405190815260200161015c565b6101b16101ac366004610e58565b610397565b005b6101786101c1366004610df2565b6103fb565b6101b16101d4366004610eb0565b6104a0565b6040516012815260200161015c565b6101786101f6366004610e2e565b61053e565b6101b1610209366004610e2e565b610559565b600854600160a01b900460ff16610178565b61019061022e366004610da4565b610600565b610190610622565b6101b1610249366004610e58565b6106a6565b600254610261906001600160a01b031681565b6040516001600160a01b03909116815260200161015c565b600854610261906001600160a01b031681565b6101b161029a366004610e71565b61070a565b61014f61075b565b6101b16102b5366004610e2e565b610768565b6101786102c8366004610e2e565b6107fd565b6101786102db366004610e2e565b610818565b6101906102ee366004610dbf565b610856565b600654600754604080519283526001600160a01b0390911660208301520161015c565b606061032360015461088e565b905090565b60008061033483610964565b905061034333858360006109ea565b6001600160a01b038416336000805160206111c18339815191526103678288610856565b60405190815260200160405180910390a360019150505b92915050565b600061032361039260055490565b610a80565b6002546001600160a01b031633146103ae57600080fd5b7fd7ad744cc76ebad190995130eec8ba506b3605612d23b5b9cef8e27f14d138b46103d761075b565b6103e08361088e565b6040516103ee929190610f91565b60405180910390a1600055565b60008061040783610964565b90506104168585836000610afd565b836001600160a01b0316856001600160a01b03166000805160206111a183398151915261044284610a80565b60405190815260200160405180910390a36104608533836000610bb6565b336001600160a01b0386166000805160206111c18339815191526104848884610856565b60405190815260200160405180910390a3506001949350505050565b6002546001600160a01b0316156104b657600080fd5b6104c28686868661070a565b6001600160a01b03821661050d5760405162461bcd60e51b815260206004820152600d60248201526c1b9bc81c985d1a5bc819995959609a1b60448201526064015b60405180910390fd5b60088054911515600160a01b026001600160a81b03199092166001600160a01b039093169290921717905550505050565b60008061054a83610964565b90506103433385836000610c63565b6002546001600160a01b0316331461057057600080fd5b6001600160a01b03821661058357600080fd5b80600560008282546105959190610fbf565b90915550506001600160a01b038216600090815260036020526040812080548392906105c2908490610fbf565b90915550506001600160a01b03821660006000805160206111a18339815191526105eb84610a80565b60405190815260200160405180910390a35050565b6001600160a01b03811660009081526003602052604081205461037e90610a80565b60085460075460405163a1f1d48d60e01b81526001600160a01b039182166004820152600092919091169063a1f1d48d9060240160206040518083038186803b15801561066e57600080fd5b505afa158015610682573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906103239190610f18565b6002546001600160a01b031633146106bd57600080fd5b7f6c20b91d1723b78732eba64ff11ebd7966a6e4af568a00fa4f6b72c20f58b02a6106e6610316565b6106ef8361088e565b6040516106fd929190610f91565b60405180910390a1600155565b6002546001600160a01b03161561072057600080fd5b60028054336001600160a01b031991821617909155600094909455600192909255600655600780549092166001600160a01b03909116179055565b606061032360005461088e565b6002546001600160a01b0316331461077f57600080fd5b6001600160a01b03821661079257600080fd5b6001600160a01b038216600090815260036020526040812080548392906107ba90849061111d565b9250508190555080600560008282546107d3919061111d565b90915550600090506001600160a01b0383166000805160206111a18339815191526105eb84610a80565b60008061080983610964565b90506103433385836000610bb6565b60008061082483610964565b90506108333385836000610afd565b6001600160a01b038416336000805160206111a183398151915261036784610a80565b6001600160a01b03808316600090815260046020908152604080832093851683529290529081205461088790610a80565b9392505050565b6060816108a957505060408051600081526020810190915290565b600060105b60ff81161561090057836108c28284610fd7565b60ff16602081106108d5576108d5611174565b1a60f81b6001600160f81b031916156108f5576108f28183610fd7565b91505b60011c607f166108ae565b50600061090e826001610fd7565b60ff1667ffffffffffffffff8111156109295761092961118a565b6040519080825280601f01601f191660200182016040528015610953576020820181803683370190505b506020810194909452509192915050565b600854600090600160a01b900460ff16156109e1576000610983610622565b9050600081116109cb5760405162461bcd60e51b8152602060048201526013602482015272726174696f206e6f7420617661696c61626c6560681b6044820152606401610504565b61088783826109dc6012600a611053565b610cc0565b5090565b919050565b6001600160a01b0384166109fd57600080fd5b6001600160a01b038316610a1057600080fd5b6001600160a01b0380851660009081526004602090815260408083209387168352929052208290558015610a7a57826001600160a01b0316846001600160a01b03166000805160206111c183398151915284604051610a7191815260200190565b60405180910390a35b50505050565b600854600090600160a01b900460ff16156109e1576000610a9f610622565b905060008111610ae75760405162461bcd60e51b8152602060048201526013602482015272726174696f206e6f7420617661696c61626c6560681b6044820152606401610504565b61088783610af76012600a611053565b83610d05565b6001600160a01b038416610b1057600080fd5b6001600160a01b038316610b2357600080fd5b6001600160a01b03841660009081526003602052604081208054849290610b4b90849061111d565b90915550506001600160a01b03831660009081526003602052604081208054849290610b78908490610fbf565b90915550508015610a7a57826001600160a01b0316846001600160a01b03166000805160206111a183398151915284604051610a7191815260200190565b6001600160a01b038416610bc957600080fd5b6001600160a01b038316610bdc57600080fd5b6001600160a01b03808516600090815260046020908152604080832093871683529290529081208054849290610c1390849061111d565b90915550508015610a7a576001600160a01b038481166000818152600460209081526040808320948816808452948252918290205491519182526000805160206111c18339815191529101610a71565b6001600160a01b038416610c7657600080fd5b6001600160a01b038316610c8957600080fd5b6001600160a01b03808516600090815260046020908152604080832093871683529290529081208054849290610c13908490610fbf565b6000610cfd610cd8610cd28487610ffc565b85610d42565b8385610ce48289611134565b610cee91906110fe565b610cf89190610ffc565b610d75565b949350505050565b6000610cfd610d17610cd28487610ffc565b83610d2360018261111d565b86610d2e878a611134565b610d3891906110fe565b610cee9190610fbf565b600082610d515750600061037e565b82820282848281610d6457610d6461115e565b04146108875760001991505061037e565b6000828201838110156108875760001991505061037e565b80356001600160a01b03811681146109e557600080fd5b600060208284031215610db657600080fd5b61088782610d8d565b60008060408385031215610dd257600080fd5b610ddb83610d8d565b9150610de960208401610d8d565b90509250929050565b600080600060608486031215610e0757600080fd5b610e1084610d8d565b9250610e1e60208501610d8d565b9150604084013590509250925092565b60008060408385031215610e4157600080fd5b610e4a83610d8d565b946020939093013593505050565b600060208284031215610e6a57600080fd5b5035919050565b60008060008060808587031215610e8757600080fd5b843593506020850135925060408501359150610ea560608601610d8d565b905092959194509250565b60008060008060008060c08789031215610ec957600080fd5b863595506020870135945060408701359350610ee760608801610d8d565b9250610ef560808801610d8d565b915060a08701358015158114610f0a57600080fd5b809150509295509295509295565b600060208284031215610f2a57600080fd5b5051919050565b6000815180845260005b81811015610f5757602081850181015186830182015201610f3b565b81811115610f69576000602083870101525b50601f01601f19169290920160200192915050565b6020815260006108876020830184610f31565b604081526000610fa46040830185610f31565b8281036020840152610fb68185610f31565b95945050505050565b60008219821115610fd257610fd2611148565b500190565b600060ff821660ff84168060ff03821115610ff457610ff4611148565b019392505050565b60008261100b5761100b61115e565b500490565b600181815b8085111561104b57816000190482111561103157611031611148565b8085161561103e57918102915b93841c9390800290611015565b509250929050565b600061088760ff84168360008261106c5750600161037e565b816110795750600061037e565b816001811461108f5760028114611099576110b5565b600191505061037e565b60ff8411156110aa576110aa611148565b50506001821b61037e565b5060208310610133831016604e8410600b84101617156110d8575081810a61037e565b6110e28383611010565b80600019048211156110f6576110f6611148565b029392505050565b600081600019048311821515161561111857611118611148565b500290565b60008282101561112f5761112f611148565b500390565b6000826111435761114361115e565b500690565b634e487b7160e01b600052601160045260246000fd5b634e487b7160e01b600052601260045260246000fd5b634e487b7160e01b600052603260045260246000fd5b634e487b7160e01b600052604160045260246000fdfeddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925a26469706673582212209af689c9c4267a97a7ee1f842a5dd9157f0e3207d11b84553c2544e190a08fa264736f6c63430008060033";

    bytes32 constant internal INTERNET_BOND_TEMPLATE_HASH = keccak256(INTERNET_BOND_TEMPLATE_BYTECODE);

    function deployInternetBondTemplate(InternetBondFactory_R1 templateFactory) internal returns (address) {
        /* we can use any deterministic salt here, since we don't care about it */
        bytes32 salt = INTERNET_BOND_TEMPLATE_SALT;
        /* concat bytecode with constructor */
        bytes memory bytecode = INTERNET_BOND_TEMPLATE_BYTECODE;
        /* deploy contract and store result in result variable */
        address result;
        assembly {
            result := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(result != address(0x00), "deploy failed");
        /* check that generated contract address is correct */
        require(result == internetBondTemplateAddress(templateFactory), "address mismatched");
        return result;
    }

    function internetBondTemplateAddress(InternetBondFactory_R1 templateFactory) internal pure returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(uint8(0xff), address(templateFactory), INTERNET_BOND_TEMPLATE_SALT, INTERNET_BOND_TEMPLATE_HASH));
        return address(bytes20(hash << 96));
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/IERC20.sol";

contract SimpleToken_R1 is Context, IERC20, IERC20Mintable, IERC20Pegged, IERC20MetadataChangeable {

    // pre-defined state
    bytes32 internal _symbol; // 0
    bytes32 internal _name; // 1
    address public owner; // 2

    // internal state
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 internal _totalSupply;
    uint256 internal _originChain;
    address internal _originAddress;

    function name() public view returns (string memory) {
        return bytes32ToString(_name);
    }

    function changeName(bytes32 newVal) external override onlyOwner {
        emit NameChanged(name(), bytes32ToString(newVal));
        _name = newVal;
    }

    function symbol() public view returns (string memory) {
        return bytes32ToString(_symbol);
    }

    function changeSymbol(bytes32 newVal) external override onlyOwner {
        emit SymbolChanged(symbol(), bytes32ToString(newVal));
        _symbol = newVal;
    }

    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        if (_bytes32 == 0) {
            return new string(0);
        }
        uint8 cntNonZero = 0;
        for (uint8 i = 16; i > 0; i >>= 1) {
            if (_bytes32[cntNonZero + i] != 0) cntNonZero += i;
        }
        string memory result = new string(cntNonZero + 1);
        assembly {
            mstore(add(result, 0x20), _bytes32)
        }
        return result;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount, true);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount, true);
        return true;
    }

    function increaseAllowance(address spender, uint256 amount) public virtual returns (bool) {
        _increaseAllowance(_msgSender(), spender, amount, true);
        return true;
    }

    function decreaseAllowance(address spender, uint256 amount) public virtual returns (bool) {
        _decreaseAllowance(_msgSender(), spender, amount, true);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount, true);
        _decreaseAllowance(sender, _msgSender(), amount, true);
        return true;
    }

    function _increaseAllowance(address owner, address spender, uint256 amount, bool emitEvent) internal {
        require(owner != address(0));
        require(spender != address(0));
        _allowances[owner][spender] += amount;
        if (emitEvent) {
            emit Approval(owner, spender, _allowances[owner][spender]);
        }
    }

    function _decreaseAllowance(address owner, address spender, uint256 amount, bool emitEvent) internal {
        require(owner != address(0));
        require(spender != address(0));
        _allowances[owner][spender] -= amount;
        if (emitEvent) {
            emit Approval(owner, spender, _allowances[owner][spender]);
        }
    }

    function _approve(address owner, address spender, uint256 amount, bool emitEvent) internal {
        require(owner != address(0));
        require(spender != address(0));
        _allowances[owner][spender] = amount;
        if (emitEvent) {
            emit Approval(owner, spender, amount);
        }
    }

    function _transfer(address sender, address recipient, uint256 amount, bool emitEvent) internal {
        require(sender != address(0));
        require(recipient != address(0));
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        if (emitEvent) {
            emit Transfer(sender, recipient, amount);
        }
    }

    function mint(address account, uint256 amount) public onlyOwner virtual override {
        require(account != address(0));
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function burn(address account, uint256 amount) public onlyOwner virtual override {
        require(account != address(0));
        _balances[account] -= amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    modifier emptyOwner() {
        require(owner == address(0x00));
        _;
    }

    function initAndObtainOwnership(bytes32 symbol, bytes32 name, uint256 originChain, address originAddress) public emptyOwner {
        owner = msg.sender;
        _symbol = symbol;
        _name = name;
        _originChain = originChain;
        _originAddress = originAddress;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function getOrigin() public view override returns (uint256, address) {
        return (_originChain, _originAddress);
    }
}

contract SimpleTokenFactory_R1 {
    address private _template;
    constructor() {
        _template = SimpleTokenFactoryUtils_R1.deploySimpleTokenTemplate(this);
    }

    function getImplementation() public view returns (address) {
        return _template;
    }
}

library SimpleTokenFactoryUtils_R1 {

    bytes32 constant internal SIMPLE_TOKEN_TEMPLATE_SALT = keccak256("SimpleTokenTemplateV2");

    bytes constant internal SIMPLE_TOKEN_TEMPLATE_BYTECODE = hex"608060405234801561001057600080fd5b50610bd5806100206000396000f3fe608060405234801561001057600080fd5b50600436106101165760003560e01c8063898855ed116100a25780639dc29fac116100715780639dc29fac1461024d578063a457c2d714610260578063a9059cbb14610273578063dd62ed3e14610286578063df1f29ee146102bf57600080fd5b8063898855ed146101f45780638da5cb5b1461020757806394bfed881461023257806395d89b411461024557600080fd5b806323b872dd116100e957806323b872dd14610183578063313ce5671461019657806339509351146101a557806340c10f19146101b857806370a08231146101cb57600080fd5b806306fdde031461011b578063095ea7b31461013957806318160ddd1461015c5780631ad8fde61461016e575b600080fd5b6101236102e2565b6040516101309190610ac8565b60405180910390f35b61014c6101473660046109f9565b6102f4565b6040519015158152602001610130565b6005545b604051908152602001610130565b61018161017c366004610a23565b61030c565b005b61014c6101913660046109bd565b610370565b60405160128152602001610130565b61014c6101b33660046109f9565b610396565b6101816101c63660046109f9565b6103a5565b6101606101d9366004610968565b6001600160a01b031660009081526003602052604090205490565b610181610202366004610a23565b610459565b60025461021a906001600160a01b031681565b6040516001600160a01b039091168152602001610130565b610181610240366004610a3c565b6104bd565b61012361050e565b61018161025b3660046109f9565b61051b565b61014c61026e3660046109f9565b6105c9565b61014c6102813660046109f9565b6105d8565b61016061029436600461098a565b6001600160a01b03918216600090815260046020908152604080832093909416825291909152205490565b600654600754604080519283526001600160a01b03909116602083015201610130565b60606102ef6001546105e7565b905090565b600061030333848460016106bd565b50600192915050565b6002546001600160a01b0316331461032357600080fd5b7fd7ad744cc76ebad190995130eec8ba506b3605612d23b5b9cef8e27f14d138b461034c61050e565b610355836105e7565b604051610363929190610adb565b60405180910390a1600055565b600061037f8484846001610765565b61038c8433846001610830565b5060019392505050565b600061030333848460016108ef565b6002546001600160a01b031633146103bc57600080fd5b6001600160a01b0382166103cf57600080fd5b80600560008282546103e19190610b09565b90915550506001600160a01b0382166000908152600360205260408120805483929061040e908490610b09565b90915550506040518181526001600160a01b038316906000907fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef906020015b60405180910390a35050565b6002546001600160a01b0316331461047057600080fd5b7f6c20b91d1723b78732eba64ff11ebd7966a6e4af568a00fa4f6b72c20f58b02a6104996102e2565b6104a2836105e7565b6040516104b0929190610adb565b60405180910390a1600155565b6002546001600160a01b0316156104d357600080fd5b60028054336001600160a01b031991821617909155600094909455600192909255600655600780549092166001600160a01b03909116179055565b60606102ef6000546105e7565b6002546001600160a01b0316331461053257600080fd5b6001600160a01b03821661054557600080fd5b6001600160a01b0382166000908152600360205260408120805483929061056d908490610b46565b9250508190555080600560008282546105869190610b46565b90915550506040518181526000906001600160a01b038416907fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef9060200161044d565b60006103033384846001610830565b60006103033384846001610765565b60608161060257505060408051600081526020810190915290565b600060105b60ff811615610659578361061b8284610b21565b60ff166020811061062e5761062e610b73565b1a60f81b6001600160f81b0319161561064e5761064b8183610b21565b91505b60011c607f16610607565b506000610667826001610b21565b60ff1667ffffffffffffffff81111561068257610682610b89565b6040519080825280601f01601f1916602001820160405280156106ac576020820181803683370190505b506020810194909452509192915050565b6001600160a01b0384166106d057600080fd5b6001600160a01b0383166106e357600080fd5b6001600160a01b038085166000908152600460209081526040808320938716835292905220829055801561075f57826001600160a01b0316846001600160a01b03167f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b9258460405161075691815260200190565b60405180910390a35b50505050565b6001600160a01b03841661077857600080fd5b6001600160a01b03831661078b57600080fd5b6001600160a01b038416600090815260036020526040812080548492906107b3908490610b46565b90915550506001600160a01b038316600090815260036020526040812080548492906107e0908490610b09565b9091555050801561075f57826001600160a01b0316846001600160a01b03167fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef8460405161075691815260200190565b6001600160a01b03841661084357600080fd5b6001600160a01b03831661085657600080fd5b6001600160a01b0380851660009081526004602090815260408083209387168352929052908120805484929061088d908490610b46565b9091555050801561075f576001600160a01b038481166000818152600460209081526040808320948816808452948252918290205491519182527f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b9259101610756565b6001600160a01b03841661090257600080fd5b6001600160a01b03831661091557600080fd5b6001600160a01b0380851660009081526004602090815260408083209387168352929052908120805484929061088d908490610b09565b80356001600160a01b038116811461096357600080fd5b919050565b60006020828403121561097a57600080fd5b6109838261094c565b9392505050565b6000806040838503121561099d57600080fd5b6109a68361094c565b91506109b46020840161094c565b90509250929050565b6000806000606084860312156109d257600080fd5b6109db8461094c565b92506109e96020850161094c565b9150604084013590509250925092565b60008060408385031215610a0c57600080fd5b610a158361094c565b946020939093013593505050565b600060208284031215610a3557600080fd5b5035919050565b60008060008060808587031215610a5257600080fd5b843593506020850135925060408501359150610a706060860161094c565b905092959194509250565b6000815180845260005b81811015610aa157602081850181015186830182015201610a85565b81811115610ab3576000602083870101525b50601f01601f19169290920160200192915050565b6020815260006109836020830184610a7b565b604081526000610aee6040830185610a7b565b8281036020840152610b008185610a7b565b95945050505050565b60008219821115610b1c57610b1c610b5d565b500190565b600060ff821660ff84168060ff03821115610b3e57610b3e610b5d565b019392505050565b600082821015610b5857610b58610b5d565b500390565b634e487b7160e01b600052601160045260246000fd5b634e487b7160e01b600052603260045260246000fd5b634e487b7160e01b600052604160045260246000fdfea26469706673582212208b92490ed0e0682b75f5159cd3275fb397f083f3c75e3b0a44ebccaaa492e72764736f6c63430008060033";

    bytes32 constant internal SIMPLE_TOKEN_TEMPLATE_HASH = keccak256(SIMPLE_TOKEN_TEMPLATE_BYTECODE);

    bytes4 constant internal SET_META_DATA_SIG = bytes4(keccak256("obtainOwnership(bytes32,bytes32)"));

    function deploySimpleTokenTemplate(SimpleTokenFactory_R1 templateFactory) internal returns (address) {
        /* we can use any deterministic salt here, since we don't care about it */
        bytes32 salt = SIMPLE_TOKEN_TEMPLATE_SALT;
        /* concat bytecode with constructor */
        bytes memory bytecode = SIMPLE_TOKEN_TEMPLATE_BYTECODE;
        /* deploy contract and store result in result variable */
        address result;
        assembly {
            result := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(result != address(0x00), "deploy failed");
        /* check that generated contract address is correct */
        require(result == simpleTokenTemplateAddress(templateFactory), "address mismatched");
        return result;
    }

    function simpleTokenTemplateAddress(SimpleTokenFactory_R1 templateFactory) internal pure returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(uint8(0xff), address(templateFactory), SIMPLE_TOKEN_TEMPLATE_SALT, SIMPLE_TOKEN_TEMPLATE_HASH));
        return address(bytes20(hash << 96));
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import "../SimpleToken.sol";

library Utils {

    function currentChain() internal view returns (uint256) {
        uint256 chain;
        assembly {
            chain := chainid()
        }
        return chain;
    }

    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(source, 32))
        }
    }

    function saturatingMultiply(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            if (a == 0) return 0;
            uint256 c = a * b;
            if (c / a != b) return type(uint256).max;
            return c;
        }
    }

    function saturatingAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return type(uint256).max;
            return c;
        }
    }

    // Preconditions:
    //  1. a may be arbitrary (up to 2 ** 256 - 1)
    //  2. b * c < 2 ** 256
    // Returned value: min(floor((a * b) / c), 2 ** 256 - 1)
    function multiplyAndDivideFloor(uint256 a, uint256 b, uint256 c) internal pure returns (uint256) {
        return saturatingAdd(
            saturatingMultiply(a / c, b),
            ((a % c) * b) / c // can't fail because of assumption 2.
        );
    }

    // Preconditions:
    //  1. a may be arbitrary (up to 2 ** 256 - 1)
    //  2. b * c < 2 ** 256
    // Returned value: min(ceil((a * b) / c), 2 ** 256 - 1)
    function multiplyAndDivideCeil(uint256 a, uint256 b, uint256 c) internal pure returns (uint256) {
        return saturatingAdd(
            saturatingMultiply(a / c, b),
            ((a % c) * b + (c - 1)) / c // can't fail because of assumption 2.
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

interface IInternetBondRatioFeed {
    event RatioThresholdChanged(uint256 oldValue, uint256 newValue);

    function updateRatioBatch(
        address[] calldata addresses,
        uint256[] calldata ratios
    ) external;

    function getRatioFor(address) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Mintable {

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}

interface IERC20Pegged {

    function getOrigin() external view returns (uint256, address);
}

interface IERC20Extra {

    function name() external returns (string memory);

    function decimals() external returns (uint8);

    function symbol() external returns (string memory);
}

interface IERC20MetadataChangeable {

    event NameChanged(string prevValue, string newValue);

    event SymbolChanged(string prevValue, string newValue);

    function changeName(bytes32) external;

    function changeSymbol(bytes32) external;
}

interface IERC20InternetBond {

    function ratio() external view returns (uint256);

    function isRebasing() external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IERC20.sol";

contract SimpleToken is Context, IERC20, IERC20Mintable, IERC20Pegged {

    // pre-defined state
    bytes32 internal _symbol; // 0
    bytes32 internal _name; // 1
    address public owner; // 2

    // internal state
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 internal _totalSupply;
    uint256 internal _originChain;
    address internal _originAddress;

    function name() public view returns (string memory) {
        return bytes32ToString(_name);
    }

    function symbol() public view returns (string memory) {
        return bytes32ToString(_symbol);
    }

    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        if (_bytes32 == 0) {
            return new string(0);
        }
        uint8 cntNonZero = 0;
        for (uint8 i = 16; i > 0; i >>= 1) {
            if (_bytes32[cntNonZero + i] != 0) cntNonZero += i;
        }
        string memory result = new string(cntNonZero + 1);
        assembly {
            mstore(add(result, 0x20), _bytes32)
        }
        return result;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount, true);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount, true);
        return true;
    }

    function increaseAllowance(address spender, uint256 amount) public virtual returns (bool) {
        _increaseAllowance(_msgSender(), spender, amount, true);
        return true;
    }

    function decreaseAllowance(address spender, uint256 amount) public virtual returns (bool) {
        _decreaseAllowance(_msgSender(), spender, amount, true);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount, true);
        _decreaseAllowance(sender, _msgSender(), amount, true);
        return true;
    }

    function _increaseAllowance(address owner, address spender, uint256 amount, bool emitEvent) internal {
        require(owner != address(0));
        require(spender != address(0));
        _allowances[owner][spender] += amount;
        if (emitEvent) {
            emit Approval(owner, spender, _allowances[owner][spender]);
        }
    }

    function _decreaseAllowance(address owner, address spender, uint256 amount, bool emitEvent) internal {
        require(owner != address(0));
        require(spender != address(0));
        _allowances[owner][spender] -= amount;
        if (emitEvent) {
            emit Approval(owner, spender, _allowances[owner][spender]);
        }
    }

    function _approve(address owner, address spender, uint256 amount, bool emitEvent) internal {
        require(owner != address(0));
        require(spender != address(0));
        _allowances[owner][spender] = amount;
        if (emitEvent) {
            emit Approval(owner, spender, amount);
        }
    }

    function _transfer(address sender, address recipient, uint256 amount, bool emitEvent) internal {
        require(sender != address(0));
        require(recipient != address(0));
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        if (emitEvent) {
            emit Transfer(sender, recipient, amount);
        }
    }

    function mint(address account, uint256 amount) public onlyOwner virtual override {
        require(account != address(0));
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function burn(address account, uint256 amount) public onlyOwner virtual override {
        require(account != address(0));
        _balances[account] -= amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    modifier emptyOwner() {
        require(owner == address(0x00));
        _;
    }

    function initAndObtainOwnership(bytes32 symbol, bytes32 name, uint256 originChain, address originAddress) public emptyOwner {
        owner = msg.sender;
        _symbol = symbol;
        _name = name;
        _originChain = originChain;
        _originAddress = originAddress;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function getOrigin() public view override returns (uint256, address) {
        return (_originChain, _originAddress);
    }
}

contract SimpleTokenFactory {
    address private _template;
    constructor() {
        _template = SimpleTokenFactoryUtils.deploySimpleTokenTemplate(this);
    }

    function getImplementation() public view returns (address) {
        return _template;
    }
}

library SimpleTokenFactoryUtils {

    bytes32 constant internal SIMPLE_TOKEN_TEMPLATE_SALT = keccak256("SimpleTokenTemplateV1");

    bytes constant internal SIMPLE_TOKEN_TEMPLATE_BYTECODE = hex"608060405234801561001057600080fd5b50610a7f806100206000396000f3fe608060405234801561001057600080fd5b50600436106101005760003560e01c80638da5cb5b11610097578063a457c2d711610066578063a457c2d714610224578063a9059cbb14610237578063dd62ed3e1461024a578063df1f29ee1461028357600080fd5b80638da5cb5b146101cb57806394bfed88146101f657806395d89b41146102095780639dc29fac1461021157600080fd5b8063313ce567116100d3578063313ce5671461016b578063395093511461017a57806340c10f191461018d57806370a08231146101a257600080fd5b806306fdde0314610105578063095ea7b31461012357806318160ddd1461014657806323b872dd14610158575b600080fd5b61010d6102a6565b60405161011a919061095e565b60405180910390f35b6101366101313660046108f5565b6102b8565b604051901515815260200161011a565b6005545b60405190815260200161011a565b6101366101663660046108b9565b6102d0565b6040516012815260200161011a565b6101366101883660046108f5565b6102f6565b6101a061019b3660046108f5565b610305565b005b61014a6101b0366004610864565b6001600160a01b031660009081526003602052604090205490565b6002546101de906001600160a01b031681565b6040516001600160a01b03909116815260200161011a565b6101a061020436600461091f565b6103b9565b61010d61040a565b6101a061021f3660046108f5565b610417565b6101366102323660046108f5565b6104c5565b6101366102453660046108f5565b6104d4565b61014a610258366004610886565b6001600160a01b03918216600090815260046020908152604080832093909416825291909152205490565b600654600754604080519283526001600160a01b0390911660208301520161011a565b60606102b36001546104e3565b905090565b60006102c733848460016105b9565b50600192915050565b60006102df8484846001610661565b6102ec843384600161072c565b5060019392505050565b60006102c733848460016107eb565b6002546001600160a01b0316331461031c57600080fd5b6001600160a01b03821661032f57600080fd5b806005600082825461034191906109b3565b90915550506001600160a01b0382166000908152600360205260408120805483929061036e9084906109b3565b90915550506040518181526001600160a01b038316906000907fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef906020015b60405180910390a35050565b6002546001600160a01b0316156103cf57600080fd5b60028054336001600160a01b031991821617909155600094909455600192909255600655600780549092166001600160a01b03909116179055565b60606102b36000546104e3565b6002546001600160a01b0316331461042e57600080fd5b6001600160a01b03821661044157600080fd5b6001600160a01b038216600090815260036020526040812080548392906104699084906109f0565b92505081905550806005600082825461048291906109f0565b90915550506040518181526000906001600160a01b038416907fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef906020016103ad565b60006102c7338484600161072c565b60006102c73384846001610661565b6060816104fe57505060408051600081526020810190915290565b600060105b60ff811615610555578361051782846109cb565b60ff166020811061052a5761052a610a1d565b1a60f81b6001600160f81b0319161561054a5761054781836109cb565b91505b60011c607f16610503565b5060006105638260016109cb565b60ff1667ffffffffffffffff81111561057e5761057e610a33565b6040519080825280601f01601f1916602001820160405280156105a8576020820181803683370190505b506020810194909452509192915050565b6001600160a01b0384166105cc57600080fd5b6001600160a01b0383166105df57600080fd5b6001600160a01b038085166000908152600460209081526040808320938716835292905220829055801561065b57826001600160a01b0316846001600160a01b03167f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b9258460405161065291815260200190565b60405180910390a35b50505050565b6001600160a01b03841661067457600080fd5b6001600160a01b03831661068757600080fd5b6001600160a01b038416600090815260036020526040812080548492906106af9084906109f0565b90915550506001600160a01b038316600090815260036020526040812080548492906106dc9084906109b3565b9091555050801561065b57826001600160a01b0316846001600160a01b03167fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef8460405161065291815260200190565b6001600160a01b03841661073f57600080fd5b6001600160a01b03831661075257600080fd5b6001600160a01b038085166000908152600460209081526040808320938716835292905290812080548492906107899084906109f0565b9091555050801561065b576001600160a01b038481166000818152600460209081526040808320948816808452948252918290205491519182527f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b9259101610652565b6001600160a01b0384166107fe57600080fd5b6001600160a01b03831661081157600080fd5b6001600160a01b038085166000908152600460209081526040808320938716835292905290812080548492906107899084906109b3565b80356001600160a01b038116811461085f57600080fd5b919050565b60006020828403121561087657600080fd5b61087f82610848565b9392505050565b6000806040838503121561089957600080fd5b6108a283610848565b91506108b060208401610848565b90509250929050565b6000806000606084860312156108ce57600080fd5b6108d784610848565b92506108e560208501610848565b9150604084013590509250925092565b6000806040838503121561090857600080fd5b61091183610848565b946020939093013593505050565b6000806000806080858703121561093557600080fd5b84359350602085013592506040850135915061095360608601610848565b905092959194509250565b600060208083528351808285015260005b8181101561098b5785810183015185820160400152820161096f565b8181111561099d576000604083870101525b50601f01601f1916929092016040019392505050565b600082198211156109c6576109c6610a07565b500190565b600060ff821660ff84168060ff038211156109e8576109e8610a07565b019392505050565b600082821015610a0257610a02610a07565b500390565b634e487b7160e01b600052601160045260246000fd5b634e487b7160e01b600052603260045260246000fd5b634e487b7160e01b600052604160045260246000fdfea2646970667358221220fe9609dd4d099f8ee61d515b2ebf66a53d24e78cf669be48b69b627acefde71564736f6c63430008060033";

    bytes32 constant internal SIMPLE_TOKEN_TEMPLATE_HASH = keccak256(SIMPLE_TOKEN_TEMPLATE_BYTECODE);

    bytes4 constant internal SET_META_DATA_SIG = bytes4(keccak256("obtainOwnership(bytes32,bytes32)"));

    function deploySimpleTokenTemplate(SimpleTokenFactory templateFactory) internal returns (address) {
        /* we can use any deterministic salt here, since we don't care about it */
        bytes32 salt = SIMPLE_TOKEN_TEMPLATE_SALT;
        /* concat bytecode with constructor */
        bytes memory bytecode = SIMPLE_TOKEN_TEMPLATE_BYTECODE;
        /* deploy contract and store result in result variable */
        address result;
        assembly {
            result := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(result != address(0x00), "deploy failed");
        /* check that generated contract address is correct */
        require(result == simpleTokenTemplateAddress(templateFactory), "address mismatched");
        return result;
    }

    function simpleTokenTemplateAddress(SimpleTokenFactory templateFactory) internal pure returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(uint8(0xff), address(templateFactory), SIMPLE_TOKEN_TEMPLATE_SALT, SIMPLE_TOKEN_TEMPLATE_HASH));
        return address(bytes20(hash << 96));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}