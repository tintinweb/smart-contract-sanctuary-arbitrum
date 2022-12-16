/**
 *Submitted for verification at Arbiscan on 2022-12-16
*/

contract Contract{
    uint256 public _totalSupply = 10 ** 9 * (10 ** 18); // 0.1..T
    uint256 public maxTxAmount = _totalSupply / 200;
    uint256 public maxWalletToken = _totalSupply / 50;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isTimelockExempt;
    mapping (address => bool) isDividendExempt;
}