/**
 *Submitted for verification at Arbiscan on 2023-07-02
*/

/*
    ░█████╗░██████╗░██╗░░░██╗██████╗░████████╗░█████╗░███████╗██╗██╗░░██╗███████╗
    ██╔══██╗██╔══██╗╚██╗░██╔╝██╔══██╗╚══██╔══╝██╔══██╗██╔════╝██║╚██╗██╔╝██╔════╝
    ██║░░╚═╝██████╔╝░╚████╔╝░██████╔╝░░░██║░░░██║░░██║█████╗░░██║░╚███╔╝░█████╗░░
    ██║░░██╗██╔══██╗░░╚██╔╝░░██╔═══╝░░░░██║░░░██║░░██║██╔══╝░░██║░██╔██╗░██╔══╝░░
    ╚█████╔╝██║░░██║░░░██║░░░██║░░░░░░░░██║░░░╚█████╔╝██║░░░░░██║██╔╝╚██╗███████╗
    ░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░░░░░░░╚═╝░░░░╚════╝░╚═╝░░░░░╚═╝╚═╝░░╚═╝╚══════╝
                            https://CryptoFixe.com
*/                              
/********************************************************************************
 *              It's a registered trademark of the Nespinker                    *
 *                           https://Nespinker.com                              *
 ********************************************************************************/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

string constant NAME = "CryptoFixe";
string constant SYMBOL = "CoinFixe";

uint16 constant DECIMALS = 18;
uint256 constant MAX_SUPPLY = 1_000_000_000;
uint32 constant DENOMINATOR = 100000;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract AccessControl is Ownable {
    mapping(address => bool) private _admins;
    mapping(address => bool) private _bridges;

    constructor() {
        _admins[_msgSender()] = true;
    }
    
    modifier onlyAdmin() {
        require(_admins[_msgSender()], "AccessControl: caller is not an admin");
        _;
    }
    
    modifier onlyBridge() {
        require(_bridges[_msgSender()], "AccessControl: caller is not a bridge");
        _;
    }
    
    function removeBridge(address account) external onlyOwner {
        _bridges[account] = false;
    }

    function addBridge(address account) external onlyOwner {
        _bridges[account] = true;
    }

    function addAdmin(address account) external onlyOwner {
        _admins[account] = true;
    }

    function _addAdmin(address account) internal {
        _admins[account] = true;
    }

    function removeAdmin(address account) external onlyOwner {
        _admins[account] = false;
    }

    function renounceAdminship() external onlyAdmin {
        _admins[_msgSender()] = false;
    }

    function isAdmin(address account) public view returns (bool) {
        return _admins[account];
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata, AccessControl {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

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

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {

        require(account != address(0), "ERC20: mint to the zero address");
        
        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];

        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");

        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

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

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

abstract contract TradeManagedToken is ERC20 {
    bool private _trading = false;

    function isTrading() external view returns (bool) {
        return _trading;
    }

    function enableTrading() external onlyOwner {
        _trading = true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        require(
            _trading || isAdmin(sender),
            "TradeManagedToken: CryptoFixe has not been released."
        );
        super._transfer(sender, recipient, amount);
    }

    function mint(address account, uint256 amount) external onlyBridge {
        require((totalSupply() + amount) <= (MAX_SUPPLY * 10**DECIMALS) ,"ERC20: Cannot mint more than the maximum supply" );
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyBridge{
        super._burn(account, amount);
    }

}

library Address {

    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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

interface IERC20Permit {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
    function nonces(address owner) external view returns (uint256);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

library SafeERC20 {
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

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(
            nonceAfter == nonceBefore + 1,
            "SafeERC20: permit did not succeed"
        );
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

struct Fees {
    uint64 liquidityBuyFee;
    uint64 marketingBuyFee;
    uint64 rewardsBuyFee;
    uint64 liquiditySellFee;
    uint64 marketingSellFee;
    uint64 rewardsSellFee;
    uint64 transferFee;
}

contract CryptoFixe is TradeManagedToken {
    
    using SafeERC20 for IERC20;

    Fees private _fees = Fees(0,0,0,0,0,0,0);
    Fees private _especialNftFees = Fees(0,0,0,0,0,0,0);

    uint256 public totalBuyFee = 0;
    uint256 public totalSellFee = 0;
    uint256 public totalEspecialNftBuyFee = 0;
    uint256 public totalEspecialNftSellFee = 0;
    bool public especialNftFeesEnable = false;
    address[] private _nftList;

    mapping(address => bool) private _lpPairList;
    mapping(address => bool) private _isExcludedFromFees;

    uint256 public liquidityReserves;
    uint256 public marketingReserves;
    uint256 public rewardsReserves;

    address public marketingWallet;
    address public liquidityWallet;
    address public rewardsWallet;

    uint16 public maxFee = 10000;

    event nftCollectionForFeesChanged(address collection, bool enabled);
    event marketingWalletChanged(address marketingWallet);
    event liquidityWalletChanged(address liquidityWallet);
    event rewardsWalletChanged(address rewardsWallet);
    event excludedFromFeesChanged(address indexed account, bool isExcluded);
    event setLPPairChanged(address indexed pair, bool indexed value);
    event feesChanged(uint64 liqBuyFee, uint64 marketingBuyFee, uint64 rewardsBuyFee, uint64 liqSellFee, 
                    uint64 marketingSellFee, uint64 rewardsSellFee, uint64 transferFee, bool isNftFees);

    constructor(
    ) ERC20(NAME, SYMBOL) {
        _isExcludedFromFees[_msgSender()] = true;
        _isExcludedFromFees[address(this)] = true;
        _addAdmin(address(this));
        _mint(_msgSender(), MAX_SUPPLY * 10**DECIMALS);
    }

    function _verifyNftOwnerForEspecialFees(address account) private view returns(bool) {
        uint256 l = _nftList.length;
        for(uint8 i=0; i < l; i++){
           if(IERC721(_nftList[i]).balanceOf(account) > 0){
               return true;
           }
        }
        return false;
    }

    function claimStuckTokens(address token) external onlyOwner {
        require(token != address(this), "Owner cannot claim native tokens");
        if (token == address(0x0)) {
            payable(msg.sender).transfer(address(this).balance);
            return;
        }
        IERC20 ERC20token = IERC20(token);
        uint256 balance = ERC20token.balanceOf(address(this));
        ERC20token.transfer(msg.sender, balance);
    }
    
    function setLPPair(address _lpPair, bool _enable) external onlyAdmin {
        _lpPairList[_lpPair] = _enable;
        emit setLPPairChanged(_lpPair, _enable);
    }

    function excludedFromFees(address account, bool excluded) external onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "Account is already set to that state");
        _isExcludedFromFees[account] = excluded;
        emit excludedFromFeesChanged(account, excluded);
    }

    function setRewardsWallet(address _rewardsWallet) external onlyOwner{
        require(_rewardsWallet != rewardsWallet, "Rewards wallet is already that address");
        require(_rewardsWallet != address(0), "Rewards wallet cannot be the zero address");
        rewardsWallet = _rewardsWallet;
        _isExcludedFromFees[_rewardsWallet] = true;
        emit rewardsWalletChanged(rewardsWallet);
    }

    function setMarketingWallet(address _newMarketingWallet) external onlyOwner{
        require(_newMarketingWallet != address(0), "Token: Invalid address");
        marketingWallet = _newMarketingWallet;
        _isExcludedFromFees[marketingWallet] = true;
        emit marketingWalletChanged(marketingWallet);
    }

    function setLiquidityWallet(address _newLiquidityWallet) external onlyOwner{
        require(_newLiquidityWallet != address(0), "Token: Invalid address");
        liquidityWallet = _newLiquidityWallet;
        _isExcludedFromFees[_newLiquidityWallet] = true;
        emit liquidityWalletChanged(liquidityWallet);
    }

    function updateMaxFee(uint16 _value) external onlyOwner{
        require(_value < maxFee, "Token: Max fee cannot increase");
        maxFee = _value;
        if(_value == 0){
            _removeFeeForever();
        }
    }

    function _removeFeeForever() private{
        maxFee = 0;
        _fees = Fees(0, 0, 0, 0, 0, 0, 0);
        _especialNftFees = Fees(0, 0, 0, 0, 0, 0, 0);
    }
    
    function enableEspecialNftFees(bool enable) external onlyOwner{
        especialNftFeesEnable = enable;
    }

    function setFees(
        uint64 liqBuyFee,
        uint64 marketingBuyFee,
        uint64 rewardsBuyFee,
        uint64 liqSellFee,
        uint64 marketingSellFee,
        uint64 rewardsSellFee,
        uint64 transferFee,
        bool isNftFees
    ) external onlyOwner {
        require(
            ((liqBuyFee + marketingBuyFee + rewardsBuyFee) <= maxFee ) 
            && ((liqSellFee + marketingSellFee + rewardsSellFee) <= maxFee)
            && (transferFee <= maxFee),"Token: fees are too high");
        if(isNftFees){
            _especialNftFees = Fees(liqBuyFee, marketingBuyFee, rewardsBuyFee, liqSellFee, marketingSellFee, rewardsSellFee, transferFee);
            totalEspecialNftBuyFee = liqBuyFee + marketingBuyFee + rewardsBuyFee;
            totalEspecialNftSellFee = liqSellFee + marketingSellFee + rewardsSellFee;
        }else{
            _fees = Fees(liqBuyFee, marketingBuyFee, rewardsBuyFee, liqSellFee, marketingSellFee, rewardsSellFee, transferFee);
            totalBuyFee = liqBuyFee + marketingBuyFee + rewardsBuyFee;
            totalSellFee = liqSellFee + marketingSellFee + rewardsSellFee;
        }
        emit feesChanged(liqBuyFee, marketingBuyFee, rewardsBuyFee, liqSellFee, marketingSellFee, rewardsSellFee, transferFee, isNftFees);
    }

    function transferFrom(
        address sender, 
        address recipient, 
        uint256 amount) 
        public override returns (bool) {

        _approve(
            sender,
            _msgSender(),
            allowance(sender, _msgSender()) - amount
        );

        if(totalBuyFee > 0 || totalSellFee > 0){
            return _customTransfer(sender, recipient, amount);
        }else{
            super._transfer(sender, recipient, amount);
            return true;
        }
    }

    function transfer(
        address recipient, 
        uint256 amount) 
        public virtual override returns (bool){

        if(totalBuyFee > 0 || totalSellFee > 0){
           return _customTransfer(_msgSender(), recipient, amount);
        }else{
            super._transfer(_msgSender(), recipient, amount);
            return true;
        }
    }

    function _customTransfer(
        address sender, 
        address recipient, 
        uint256 amount) 
        private returns (bool) {
        require(amount > 0, "Token: Cannot transfer zero(0) tokens");
        uint256 ttFees = 0;
        uint256 left = 0;

        bool isBuy = _lpPairList[sender];
        bool isSell = _lpPairList[recipient];

         if (!isBuy && !isSell) {
            if(_fees.transferFee > 0 && !_isExcludedFromFees[recipient] && !_isExcludedFromFees[sender]) {
                bool hasNFT = false;
                if(especialNftFeesEnable){
                    hasNFT = (_verifyNftOwnerForEspecialFees(sender) || _verifyNftOwnerForEspecialFees(recipient));
                }
                if(hasNFT){
                    ttFees = (amount * _especialNftFees.transferFee) / DENOMINATOR;
                }else{
                    ttFees = (amount * _fees.transferFee) / DENOMINATOR;
                }
                marketingReserves += ttFees;
            }
        }else if(isBuy || isSell){
            ttFees = _calculateDexFees(isBuy, amount, (isBuy ? recipient : sender )) ;
        }
        
        left = amount - ttFees;
        super._transfer(sender, recipient, left);

        if(ttFees > 0){
            super._transfer(sender, address(this), ttFees);
        }
        return true;
    }

    function _calculateDexFees(bool isBuy, uint256 amount, address toNftCheck) private returns(uint256) {
        uint256 liquidityFeeAmount = 0;
        uint256 marketingFeeAmount = 0;
        uint256 rewardsFeeAmount = 0;
        uint256 ttFeess = 0;
        bool hasNft = false;

        if (especialNftFeesEnable){
            hasNft = _verifyNftOwnerForEspecialFees(toNftCheck);
        }

        if (isBuy) {
            if(hasNft){
                    if(_especialNftFees.liquidityBuyFee > 0){
                        liquidityFeeAmount = (amount * _especialNftFees.liquidityBuyFee) / DENOMINATOR;
                    }
                    if(_especialNftFees.marketingBuyFee > 0){
                        marketingFeeAmount = (amount * _especialNftFees.marketingBuyFee) / DENOMINATOR;
                    }
                    if(_especialNftFees.rewardsBuyFee > 0){
                        rewardsFeeAmount = (amount * _especialNftFees.rewardsBuyFee) / DENOMINATOR;
                    }
            }else{
                    if(_fees.liquidityBuyFee > 0){
                        liquidityFeeAmount = (amount * _fees.liquidityBuyFee) / DENOMINATOR;
                    }
                    if(_fees.marketingBuyFee > 0){
                        marketingFeeAmount = (amount * _fees.marketingBuyFee) / DENOMINATOR;
                    }
                    if(_fees.rewardsBuyFee > 0){
                        rewardsFeeAmount = (amount * _fees.rewardsBuyFee) / DENOMINATOR;
                    }
            }
        } else{
            if(hasNft){
                if(_especialNftFees.liquiditySellFee > 0){
                    liquidityFeeAmount = (amount * _especialNftFees.liquiditySellFee) / DENOMINATOR;
                }
                if(_especialNftFees.marketingSellFee > 0){
                    marketingFeeAmount = (amount * _especialNftFees.marketingSellFee) / DENOMINATOR;
                }
                if(_fees.rewardsSellFee > 0){
                    rewardsFeeAmount = (amount * _especialNftFees.rewardsSellFee) / DENOMINATOR;
                }
            }else{
                if(_fees.liquiditySellFee > 0){
                    liquidityFeeAmount = (amount * _fees.liquiditySellFee) / DENOMINATOR;
                }
                if(_fees.marketingSellFee > 0){
                    marketingFeeAmount = (amount * _fees.marketingSellFee) / DENOMINATOR;
                }
                if(_fees.rewardsSellFee > 0){
                    rewardsFeeAmount = (amount * _fees.rewardsSellFee) / DENOMINATOR;
                }
            }
        }
        ttFeess = liquidityFeeAmount + marketingFeeAmount + rewardsFeeAmount;
        if(ttFeess > 0){
            liquidityReserves += liquidityFeeAmount;
            marketingReserves += marketingFeeAmount;
            rewardsReserves += rewardsFeeAmount;
        }
        return ttFeess;
    }

    function processFeeReserves() external onlyAdmin {
        if(liquidityReserves > 0){
            super._transfer(address(this), liquidityWallet, liquidityReserves);
            liquidityReserves = 0;
        }
        if(marketingReserves > 0){
            super._transfer(address(this), marketingWallet, marketingReserves);
            marketingReserves = 0;
        }
        if(rewardsReserves > 0){
            super._transfer(address(this), rewardsWallet, rewardsReserves);
            rewardsReserves = 0;
        }
    }

    function setNFTCollectionForFees(address collection, bool enabled) external onlyOwner{
        uint256 l = _nftList.length;
        for (uint256 i = 0; i < l; i++)
        {
            if(_nftList[i] == collection){
                if(enabled){
                    require(_nftList[i] != collection, "Collection is already exist");      
                }

                if(!enabled){
                    delete(_nftList[i]);

                    for (uint i2 = i; i2 < _nftList.length - 1; i2++) {
                        _nftList[i2] = _nftList[i2 + 1];
                    }
                    _nftList.pop();
                    return;
                }
            }
        }
        if(enabled){
            _nftList.push(collection);
        }
        emit nftCollectionForFeesChanged(collection, enabled);
    }
}