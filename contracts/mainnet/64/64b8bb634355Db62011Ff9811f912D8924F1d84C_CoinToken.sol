// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;
import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";


contract CoinToken is ERC20, Ownable {
    using SafeERC20 for IERC20;


    event Trade(address user, address pair, uint256 amount, uint side, uint timestamp);
    event AddLiquidity(uint256 tokenAmount, uint256 ethAmount, uint256 timestamp);


    mapping(address => bool) public isFeeExempt;

    uint256 private fee;
    uint256 public feeDenominator = 100;

    // Buy Fees
    uint256 public feeBuy = 1;
    // Sell Fees
    uint256 public feeSell = 1;
    address taxAddress;

    address[] private _pairs;

    constructor(address taxAddress_, string memory _name, string memory _symbol
    ) ERC20(_name, _symbol) {
        isFeeExempt[msg.sender] = true;
        isFeeExempt[taxAddress] = true;
        taxAddress = taxAddress_;
        _mint(msg.sender, 100000000000 * 1e18);
    }


    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        return _xeelTransfer(_msgSender(), to, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(sender, spender, amount);
        return _xeelTransfer(sender, recipient, amount);
    }

    function _xeelTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        bool shouldTakeFee = !isFeeExempt[sender] && !isFeeExempt[recipient];
        uint side = 0;
        address user_ = sender;
        address pair_ = recipient;
        // Set Fees
        if (isPair(sender)) {
            buyFees();
            side = 1;
            user_ = recipient;
            pair_ = sender;
        } else if (isPair(recipient)) {
            sellFees();
            side = 2;
        } else {
            shouldTakeFee = false;
        }

        uint256 amountReceived = shouldTakeFee ? takeFee(sender, amount) : amount;
        _transfer(sender, recipient, amountReceived);

        if (side > 0) {
            emit Trade(user_, pair_, amount, side, block.timestamp);
        }
        return true;
    }
    function buyFees() internal {
        fee = feeBuy;
    }

    function sellFees() internal {
        fee = feeSell;
    }

    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        if (fee == 0) {
            return amount;
        }
        uint256 feeAmount = (amount * fee) / feeDenominator;
        _transfer(sender, taxAddress, feeAmount);
        return amount - feeAmount;
    }

    function rescueToken(address tokenAddress) external onlyOwner {
        IERC20(tokenAddress).safeTransfer(msg.sender,IERC20(tokenAddress).balanceOf(address(this)));
    }

    function clearStuckEthBalance() external onlyOwner {
        uint256 amountETH = address(this).balance;
        (bool success, ) = payable(_msgSender()).call{value: amountETH}(new bytes(0));
        require(success, 'XEET: ETH_TRANSFER_FAILED');
    }

    function setBuyFees(
        uint256 _feeBuy
    ) external onlyOwner {
        feeBuy = _feeBuy;
    }

    function setSellFees(
        uint256 _feeSell
    ) external onlyOwner {
        feeSell = _feeSell;
    }


    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }


    function isPair(address account) public view returns (bool) {
        for (uint256 i = 0; i < _pairs.length; i++) {
            if (_pairs[i] == account) {
                return true;
            }
        }
        return false;
    }

    function addPair(address pair) public onlyOwner returns (bool) {
        require(pair != address(0), "XEET: pair is the zero address");
        _pairs.push(pair);
        return true;
    }

    function delPair(address pair) public onlyOwner returns (bool) {
        require(pair != address(0), "XEET: pair is the zero address");
        for (uint256 i = 0; i < _pairs.length; i++) {
            if (_pairs[i] == pair) {
                // Remove the pair by swapping with the last element and then reducing the array length
                _pairs[i] = _pairs[_pairs.length - 1];
                _pairs.pop();
                return true;
            }
        }
        return false;
    }

    function getMinterLength() public view returns (uint256) {
        return _pairs.length;
    }

    function getPair(uint256 index) public view returns (address) {
        require(index < _pairs.length, "XEET: index out of bounds");
        return _pairs[index];
    }

}