/**
 *Submitted for verification at Arbiscan on 2023-07-05
*/

/**
 *  Created By: Fatsale
 *  Website: https://fatsale.finance
 *  Telegram: https://t.me/fatsale
 *  The Best Tool for Token Presale
 **/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library EnumerableSet {
    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    function decimals() external view returns (uint256);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

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

interface ISwapRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}

interface ISwapFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

interface ITokenFactory {
    function informTransferTokenOwnership(address newOwner) external; 
}

contract TokenDistributor {
    constructor(address token) {
        IERC20(token).approve(msg.sender, uint256(~uint256(0)));
    }
}

contract AddPoolDividendToken is IERC20, Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address public fundAddress;

    string private _name;
    string private _symbol;
    uint256 private _decimals;
    uint256 public kb;
    uint256 public maxSwapAmount;
    uint256 public maxWalletAmount;
    bool public limitEnable = true;
    bool public canMint;

    mapping(address => bool) public _feeWhiteList;
    mapping(address => bool) public _initFeeWhiteList;
    mapping(address => bool) public _rewardList;
    mapping(address => bool) public isMaxEatExempt;

    uint256 private _tTotal;

    ISwapRouter public _swapRouter;
    address public currency;
    mapping(address => bool) public _swapPairList;

    bool private inSwap;

    uint256 private constant MAX = ~uint256(0);
    TokenDistributor public _tokenDistributor;
    TokenDistributor public _rewardTokenDistributor;
    EnumerableSet.AddressSet private _feeWhiteListSet;

    uint256 public _buyFundFee;
    uint256 public _buyLPFee;
    uint256 public _buyRewardFee;
    uint256 public _sellFundFee;
    uint256 public _sellLPFee;
    uint256 public _sellRewardFee;
    uint256 public _FeePercentageBase = 10000;
    uint256 public minimumTokensBeforeSwap;

    mapping(address => uint256) public user2blocks;
    uint256 public batchBots;

    bool currencyIsEth;

    address public rewardToken;
    uint256 public startTradeBlock;

    address public _mainPair;

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    bool public enableKillBlock;
    bool public enableSwapLimit;
    bool public enableWalletLimit;
    bool public enableChangeTax;
    bool public enableManualStartTrade;
    bool public tradeStart;
    bool public enableWhiteList;

    address[] public rewardPath;

    constructor(
        string[] memory stringParams,
        address[] memory addressParams,
        uint256[] memory numberParams,
        bool[] memory boolParams
    ) {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);

        _name = stringParams[0];
        _symbol = stringParams[1];
        _decimals = numberParams[0];
        uint256 total = numberParams[1];
        _tTotal = total;

        currency = addressParams[0];
        ISwapRouter swapRouter = ISwapRouter(addressParams[1]);
        address receiveAddress = addressParams[2];
        fundAddress = addressParams[3];
        rewardToken = addressParams[4];

        _buyFundFee = numberParams[2];
        _buyRewardFee = numberParams[3];
        _buyLPFee = numberParams[4];

        _sellFundFee = numberParams[5];
        _sellRewardFee = numberParams[6];
        _sellLPFee = numberParams[7];

        require(_buyRewardFee + _buyLPFee + _buyFundFee <= 2000, "fee too high");
        require(_sellRewardFee + _sellLPFee + _sellFundFee <= 2000, "fee too high");
        require(_buyFundFee + _buyLPFee + _buyRewardFee + _sellFundFee + _sellRewardFee + _sellLPFee > 0, "fee must > 0");

        kb = numberParams[8];
        maxSwapAmount = numberParams[9];
        maxWalletAmount = numberParams[10];

        currencyIsEth = boolParams[0];
        enableManualStartTrade = boolParams[1];
        enableKillBlock = boolParams[2];

        enableSwapLimit = boolParams[3];
        enableWalletLimit = boolParams[4];
        enableChangeTax = boolParams[5];
        enableWhiteList = boolParams[6];
        canMint = boolParams[7];

        if(enableKillBlock){
            enableManualStartTrade = true;
        }
        if(!enableManualStartTrade){
            tradeStart = true;
            startTradeBlock = block.timestamp;
        }

        rewardPath = [address(this), currency];
        if (currency != rewardToken) {
            if (currencyIsEth == false) {
                rewardPath.push(swapRouter.WETH());
            }
            if (rewardToken != swapRouter.WETH()) rewardPath.push(rewardToken);
        }

        IERC20(currency).approve(address(swapRouter), MAX);

        _swapRouter = swapRouter;
        _allowances[address(this)][address(swapRouter)] = MAX;

        ISwapFactory swapFactory = ISwapFactory(swapRouter.factory());
        address swapPair = swapFactory.createPair(address(this), currency);
        _mainPair = swapPair;
        _swapPairList[swapPair] = true;
        minimumTokensBeforeSwap = total / (10**6); 

        _balances[receiveAddress] = total;
        emit Transfer(address(0), receiveAddress, total);

        _initFeeWhiteList[fundAddress] = true;
        _initFeeWhiteList[receiveAddress] = true;
        _initFeeWhiteList[address(this)] = true;
        _initFeeWhiteList[address(swapRouter)] = true;
        _initFeeWhiteList[msg.sender] = true;

        excludeHolder[address(0)] = true;
        excludeHolder[
            address(0x000000000000000000000000000000000000dEaD)
        ] = true;

        holderRewardCondition = 10**IERC20(currency).decimals() / 10;

        _tokenDistributor = new TokenDistributor(currency);
        _rewardTokenDistributor = new TokenDistributor(rewardToken);
    }

    address private tokenFactory;
    bool private isInitFactory = false;

    function initTokenFactory(address factory) public onlyOwner {
        require(!isInitFactory, "has inited");
        tokenFactory = factory;
        isInitFactory = true;
    }

    address internal _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event InformTokenFactoryFailed(address indexed tokenFactory, address indexed newOwner);

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(
            _owner,
            0x000000000000000000000000000000000000dEaD
        );
        _owner = 0x000000000000000000000000000000000000dEaD;
        try
            ITokenFactory(tokenFactory).informTransferTokenOwnership(_owner)
        {} catch {
            emit InformTokenFactoryFailed(tokenFactory, _owner);
        }
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;

        try
            ITokenFactory(tokenFactory).informTransferTokenOwnership(_owner)
        {} catch {
            emit InformTokenFactoryFailed(tokenFactory, _owner);
        }
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function decimals() external view override returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address o, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[o][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        if (_allowances[sender][msg.sender] != MAX) {
            _allowances[sender][msg.sender] =
                _allowances[sender][msg.sender] -
                amount;
        }
        return true;
    }

    function _approve(
        address o,
        address spender,
        uint256 amount
    ) private {
        _allowances[o][spender] = amount;
        emit Approval(o, spender, amount);
    }

    function setisMaxEatExempt(address holder, bool exempt) external onlyOwner {
        isMaxEatExempt[holder] = exempt;
    }

    function setkb(uint256 a) public onlyOwner {
        kb = a;
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        if(inSwap) { 
            _basicTransfer(sender, recipient, amount); 
            return;
        }
        if(!_swapPairList[sender] && !_swapPairList[recipient]) {
            _basicTransfer(sender, recipient, amount); 
            addHolderAndProcessReward(sender, recipient);
            return;
        }
        if(enableWhiteList && (_feeWhiteList[sender] || _feeWhiteList[recipient])) {
            _basicTransfer(sender, recipient, amount); 
            addHolderAndProcessReward(sender, recipient);
            return;
        }
        if(_initFeeWhiteList[sender] || _initFeeWhiteList[recipient]) {
            _basicTransfer(sender, recipient, amount); 
            addHolderAndProcessReward(sender, recipient);
            return;
        }
        require(tradeStart, "not start trade");
        if(enableKillBlock) {
            require(block.timestamp > kb + startTradeBlock, "block killed");
        }
        if (enableSwapLimit) {
            require(amount <= maxSwapAmount, "Exceeded maximum transaction volume");
        } 
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;
        
        if (overMinimumTokenBalance) {
            swapTokenForFund(contractTokenBalance);    
        }         
        _balances[sender] = _balances[sender] - amount;
        uint256 finalAmount = takeFee(sender, recipient, amount);
        if(enableWalletLimit && _swapPairList[sender]){
            require(balanceOf(recipient) + finalAmount <= maxWalletAmount, "Exceeded maximum wallet balance");
        }
        _balances[recipient] = _balances[recipient] + finalAmount;


        addHolderAndProcessReward(sender, recipient);
        emit Transfer(sender, recipient, finalAmount);
    }

    function addHolderAndProcessReward(address sender, address recipient) private {
        bool isSell = false;  
        if (_swapPairList[recipient]) {
            isSell = true;
        }
         if (sender != address(this)) {
            if (isSell) {
                addHolder(sender);
            }
            processReward(500000);
        }
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        
        uint256 feeAmount = 0;
        uint256 _totalTaxIfBuying = _buyFundFee + _buyRewardFee + _buyLPFee;
        uint256 _totalTaxIfSelling = _sellFundFee + _sellLPFee + _sellRewardFee;
        
        if(_swapPairList[sender]) {
            feeAmount = amount * _totalTaxIfBuying / _FeePercentageBase;
        }
        else if(_swapPairList[recipient]) {
            feeAmount = amount * _totalTaxIfSelling / _FeePercentageBase;
        }
        
        if(feeAmount > 0) {
            _balances[address(this)] = _balances[address(this)]+feeAmount;
            emit Transfer(sender, address(this), feeAmount);
        }

        return amount - feeAmount;
    }

    event Failed_swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 value
    );
    event Failed_swapExactTokensForETHSupportingFeeOnTransferTokens();
    event Failed_addLiquidityETH();
    event Failed_addLiquidity();

    function swapTokenForFund(uint256 tokenAmount)
        private
        lockTheSwap
    {
        uint256 swapFee = _buyFundFee +
                _buyRewardFee +
                _buyLPFee +
                _sellFundFee +
                _sellRewardFee +
                _sellLPFee;
        if (swapFee == 0) {
            return;
        }
        uint256 rewardAmount = (tokenAmount *
            (_buyRewardFee + _sellRewardFee)) / swapFee;
        if (rewardAmount > 0) {
            try
                _swapRouter
                    .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                        rewardAmount,
                        0,
                        rewardPath,
                        address(_rewardTokenDistributor),
                        block.timestamp
                    )
            {} catch {
                emit Failed_swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    0
                );
            }
        }
        swapFee += swapFee;
        uint256 lpFee = _sellLPFee + _buyLPFee;
        uint256 lpAmount = (tokenAmount * lpFee) / swapFee;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = currency;
        if (currencyIsEth) {
            try
                _swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                    tokenAmount - lpAmount - rewardAmount,
                    0,
                    path,
                    address(this),
                    block.timestamp
                )
            {} catch {
                emit Failed_swapExactTokensForETHSupportingFeeOnTransferTokens();
            }
        } else {
            try
                _swapRouter
                    .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                        tokenAmount - lpAmount - rewardAmount,
                        0,
                        path,
                        address(_tokenDistributor),
                        block.timestamp
                    )
            {} catch {
                emit Failed_swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    1
                );
            }
        }

        swapFee -= lpFee;

        IERC20 FIST = IERC20(currency);

        uint256 fistBalance = 0;
        uint256 lpFist = 0;
        uint256 fundAmount = 0;

        if (currencyIsEth) {
            fistBalance = address(this).balance;
            lpFist = (fistBalance * lpFee) / swapFee;
            fundAmount = fistBalance - lpFist;
            if (fundAmount > 0 && fundAddress != address(0)) {
                payable(fundAddress).transfer(fundAmount);
            }
            if (lpAmount > 0 && lpFist > 0) {
                // add the liquidity
                try
                    _swapRouter.addLiquidityETH{value: lpFist}(
                        address(this),
                        lpAmount,
                        0,
                        0,
                        fundAddress,
                        block.timestamp
                    )
                {} catch {
                    emit Failed_addLiquidityETH();
                }
            }
        } else {
            fistBalance = FIST.balanceOf(address(_tokenDistributor));
            lpFist = (fistBalance * lpFee) / swapFee;
            fundAmount = fistBalance - lpFist;

            if (lpFist > 0) {
                FIST.transferFrom(
                    address(_tokenDistributor),
                    address(this),
                    lpFist
                );
            }

            if (fundAmount > 0) {
                FIST.transferFrom(
                    address(_tokenDistributor),
                    fundAddress,
                    fundAmount
                );
            }

            if (lpAmount > 0 && lpFist > 0) {
                try
                    _swapRouter.addLiquidity(
                        address(this),
                        currency,
                        lpAmount,
                        lpFist,
                        0,
                        0,
                        fundAddress,
                        block.timestamp
                    )
                {} catch {
                    emit Failed_addLiquidity();
                }
            }
        }
    }

    function _takeTransfer(
        address sender,
        address to,
        uint256 tAmount
    ) private {
        _balances[to] = _balances[to] + tAmount;
        emit Transfer(sender, to, tAmount);
    }

    function setFundAddress(address addr) external onlyOwner {
        fundAddress = addr;
        _initFeeWhiteList[addr] = true;
    }

    function startTrade() public onlyOwner {
        require(startTradeBlock == 0, "already started");
        tradeStart = true;
        startTradeBlock = block.number;
    }

    function setFeeWhiteList(address[] calldata addr, bool enable)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addr.length; i++) {
            _feeWhiteList[addr[i]] = enable;
            if(enable){
                _feeWhiteListSet.add(addr[i]);
            }else{
                if(_feeWhiteListSet.contains(addr[i])){
                    _feeWhiteListSet.remove(addr[i]);
                }
            }
        }
    }

    function feeWhiteListCount() external view returns (uint256) {
        return _feeWhiteListSet.length();
    }

    function getfeeWhiteList(uint256 start, uint256 end)
        external
        view
        returns (address[] memory)
    {
        if(_feeWhiteListSet.length() == 0){
            return new address[](0);
        }

        if (end >= _feeWhiteListSet.length()) {
            end = _feeWhiteListSet.length() - 1;
        }
        uint256 length = end - start + 1;
        address[] memory arr = new address[](length);
        uint256 index = 0;
        for (uint256 i = start; i <= end; i++) {
            arr[index] = _feeWhiteListSet.at(i);
            index++;
        }
        return arr;
    }

    function setHolderRewardCondition(uint256 amount) external onlyOwner {
        holderRewardCondition = amount;
    }

    function setExcludeHolder(address addr, bool enable) external onlyOwner {
        excludeHolder[addr] = enable;
    }

    function setNumTokensBeforeSwap(uint256 newLimit) external onlyOwner() {
        minimumTokensBeforeSwap = newLimit;
    }

    function completeCustoms(uint256[] calldata customs) external onlyOwner {
        require(enableChangeTax, "tax change disabled");
        _buyFundFee = customs[0];
        _buyRewardFee = customs[1];
        _buyLPFee = customs[2];

        _sellFundFee = customs[3];
        _sellRewardFee = customs[4];
        _sellLPFee = customs[5];

        require(_buyRewardFee + _buyLPFee + _buyFundFee <= 2000, "fee too high");
        require(_sellRewardFee + _sellLPFee + _sellFundFee <= 2000, "fee too high");
        require(_buyFundFee + _buyLPFee + _buyRewardFee + _sellFundFee + _sellRewardFee + _sellLPFee > 0, "fee must > 0");
    }

    function disableSwapLimit() public onlyOwner {
        enableSwapLimit = false;
    }

    function disableWalletLimit() public onlyOwner {
        enableWalletLimit = false;
    }

    function disableChangeTax() public onlyOwner {
        enableChangeTax = false;
    }

    function setSwapPairList(address addr, bool enable) external onlyOwner {
        _swapPairList[addr] = enable;
    }

    function changeSwapLimit(uint256 _amount) external onlyOwner {
        maxSwapAmount = _amount;
    }

    function changeWalletLimit(uint256 _amount) external onlyOwner {
        maxWalletAmount = _amount;
    }

    function disableWhiteList() public onlyOwner {
        enableWhiteList = false;
    }

    function setCurrency(address _currency, address _router) public onlyOwner {
        currency = _currency;
        if (_currency == _swapRouter.WETH()) {
            currencyIsEth = true;
        } else {
            currencyIsEth = false;
        }

        ISwapRouter swapRouter = ISwapRouter(_router);
        IERC20(currency).approve(address(swapRouter), MAX);
        _swapRouter = swapRouter;
        _allowances[address(this)][address(swapRouter)] = MAX;
        ISwapFactory swapFactory = ISwapFactory(swapRouter.factory());
        address swapPair = swapFactory.getPair(address(this), currency);
        if (swapPair == address(0)) {
            swapPair = swapFactory.createPair(address(this), currency);
        }
        _mainPair = swapPair;
        _swapPairList[swapPair] = true;
        _initFeeWhiteList[address(swapRouter)] = true;
    }

    function claimTokens(
        address token,
        uint256 amount,
        address to
    ) public onlyOwner {
        if (token == address(0)) {
            payable(to).transfer(amount);
        } else {
            IERC20(token).transfer(to, amount);
        }
    }

    receive() external payable {}

    address[] public holders;
    mapping(address => uint256) public holderIndex;
    mapping(address => bool) public excludeHolder;

    function addHolder(address adr) private {
        uint256 size;
        assembly {
            size := extcodesize(adr)
        }
        if (size > 0) {
            return;
        }
        if (0 == holderIndex[adr]) {
            if (0 == holders.length || holders[0] != adr) {
                holderIndex[adr] = holders.length;
                holders.push(adr);
            }
        }
    }

    uint256 private currentIndex;
    uint256 public holderRewardCondition;
    uint256 private progressRewardBlock;
    uint256 public processRewardWaitBlock = 20;

    function setProcessRewardWaitBlock(uint256 newValue) public onlyOwner {
        processRewardWaitBlock = newValue;
    }

    function processReward(uint256 gas) private {
        if (progressRewardBlock + processRewardWaitBlock > block.number) {
            return;
        }

        IERC20 FIST = IERC20(rewardToken);

        uint256 balance = FIST.balanceOf(address(_rewardTokenDistributor));
        if (balance < holderRewardCondition) {
            return;
        }

        FIST.transferFrom(
            address(_rewardTokenDistributor),
            address(this),
            balance
        );

        IERC20 holdToken = IERC20(_mainPair);
        uint256 holdTokenTotal = holdToken.totalSupply();

        address shareHolder;
        uint256 tokenBalance;
        uint256 amount;

        uint256 shareholderCount = holders.length;

        uint256 gasUsed = 0;
        uint256 iterations = 0;
        uint256 gasLeft = gasleft();
        balance = FIST.balanceOf(address(this));
        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }
            shareHolder = holders[currentIndex];
            tokenBalance = holdToken.balanceOf(shareHolder);
            if (tokenBalance > 0 && !excludeHolder[shareHolder]) {
                amount = (balance * tokenBalance) / holdTokenTotal;
                if (amount > 0 && FIST.balanceOf(address(this)) > amount) {
                    FIST.transfer(shareHolder, amount);
                }
            }

            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }

        progressRewardBlock = block.number;
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _tTotal = _tTotal + amount;
        _balances[account] = _balances[account] + amount;
        emit Transfer(address(0), account, amount);
    }

    function mint(address account, uint256 amount) public onlyOwner {
        require(canMint, "cannot mint");
        _mint(account, amount);
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _feeWhiteList[account] || _initFeeWhiteList[account];
    }
}